#import "WCAtlasHomeCategories.h"
#import "WCAtlasEnhancements.h"
#import "WCAtlasPrivateAPI.h"
#import "WCAtlasSendConfirmationViewController.h"
#import <objc/message.h>
#import <objc/runtime.h>

NSString *const WCAtlasHomeCategoriesEnabledKey = @"com.qiu7c.wcatlas.home.categories.enabled";
NSString *const WCAtlasHomeCategoriesDataKey = @"com.qiu7c.wcatlas.home.categories.data";

static NSString *const WCAtlasHomeCategorySessionPrefix = @"wcatlas_home_category_";
static NSString *const WCAtlasHomeCategoryAvatarFileKey = @"avatarFile";
static NSString *const WCAtlasHomeCategoryAvatarDirectoryName = @"WCAtlas/HomeCategoryAvatars";
static const CGFloat WCAtlasHomeCategoryRowHeight = 64.0;

#pragma mark - Persistent Model

static NSString *WCAtlasHomeCategoryIdentifier(void) {
    return NSUUID.UUID.UUIDString.lowercaseString;
}

static NSArray<NSString *> *WCAtlasHomeStringArray(id value) {
    if (![value isKindOfClass:NSArray.class]) return @[];
    NSMutableOrderedSet<NSString *> *items = [NSMutableOrderedSet orderedSet];
    for (id item in value) if ([item isKindOfClass:NSString.class] && [item length] > 0) [items addObject:item];
    return items.array;
}

static NSDictionary *WCAtlasHomeFolder(id raw) {
    if (![raw isKindOfClass:NSDictionary.class]) return nil;
    NSString *identifier = [raw[@"id"] isKindOfClass:NSString.class] ? raw[@"id"] : WCAtlasHomeCategoryIdentifier();
    NSString *title = [raw[@"title"] isKindOfClass:NSString.class] ? raw[@"title"] : @"文件夹";
    return @{@"id": identifier, @"title": title, @"sessions": WCAtlasHomeStringArray(raw[@"sessions"])};
}

static NSDictionary *WCAtlasHomeCategory(id raw) {
    if (![raw isKindOfClass:NSDictionary.class]) return nil;
    NSString *identifier = [raw[@"id"] isKindOfClass:NSString.class] ? raw[@"id"] : WCAtlasHomeCategoryIdentifier();
    NSString *title = [raw[@"title"] isKindOfClass:NSString.class] ? raw[@"title"] : @"分类";
    NSMutableArray *folders = [NSMutableArray array];
    for (id value in [raw[@"folders"] isKindOfClass:NSArray.class] ? raw[@"folders"] : @[]) {
        NSDictionary *folder = WCAtlasHomeFolder(value);
        if (folder) [folders addObject:folder];
    }
    NSMutableDictionary *category = [@{@"id": identifier, @"title": title,
        @"sessions": WCAtlasHomeStringArray(raw[@"sessions"]), @"folders": folders} mutableCopy];
    NSString *avatarFile = [raw[WCAtlasHomeCategoryAvatarFileKey] isKindOfClass:NSString.class]
        ? [raw[WCAtlasHomeCategoryAvatarFileKey] lastPathComponent] : nil;
    if (avatarFile.length > 0) category[WCAtlasHomeCategoryAvatarFileKey] = avatarFile;
    return category;
}

static NSArray<NSDictionary *> *WCAtlasHomeCategories(void) {
    NSArray *raw = [NSUserDefaults.standardUserDefaults arrayForKey:WCAtlasHomeCategoriesDataKey];
    NSMutableArray *categories = [NSMutableArray array];
    for (id value in raw ?: @[]) {
        NSDictionary *category = WCAtlasHomeCategory(value);
        if (category) [categories addObject:category];
    }
    return categories;
}

static NSCache<NSString *, UIImage *> *WCAtlasHomeCategoryAvatarCache(void) {
    static NSCache<NSString *, UIImage *> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ cache = [NSCache new]; });
    return cache;
}

static NSURL *WCAtlasHomeCategoryAvatarDirectory(void) {
    NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory
                                                          inDomains:NSUserDomainMask].firstObject;
    NSURL *directory = [support URLByAppendingPathComponent:WCAtlasHomeCategoryAvatarDirectoryName
                                                isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:directory
                           withIntermediateDirectories:YES attributes:nil error:nil];
    return directory;
}

static NSURL *WCAtlasHomeCategoryAvatarURL(NSString *fileName) {
    NSString *safeName = [fileName isKindOfClass:NSString.class] ? fileName.lastPathComponent : nil;
    return safeName.length > 0
        ? [WCAtlasHomeCategoryAvatarDirectory() URLByAppendingPathComponent:safeName isDirectory:NO] : nil;
}

static void WCAtlasSetHomeCategories(NSArray<NSDictionary *> *categories) {
    [NSUserDefaults.standardUserDefaults setObject:categories ?: @[] forKey:WCAtlasHomeCategoriesDataKey];
    [WCAtlasHomeCategoryAvatarCache() removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^{ WCAtlasPrivateRefreshHomeSessionList(); });
}

static NSArray<NSString *> *WCAtlasOrderedSessionsInCategory(NSDictionary *category) {
    NSMutableOrderedSet<NSString *> *sessions = [NSMutableOrderedSet orderedSetWithArray:
        WCAtlasHomeStringArray(category[@"sessions"])];
    for (NSDictionary *folder in [category[@"folders"] isKindOfClass:NSArray.class] ? category[@"folders"] : @[]) {
        [sessions addObjectsFromArray:WCAtlasHomeStringArray(folder[@"sessions"])];
    }
    return sessions.array;
}

static NSString *WCAtlasHomeConversationTitle(NSString *userName) {
    id contact = WCAtlasPrivateContact(userName);
    return WCAtlasPrivateContactDisplayName(contact, userName) ?: userName;
}

#pragma mark - Native Homepage Sessions

@interface WCAtlasHomeCategoryBrowserController : UITableViewController
@property (nonatomic, copy) NSString *categoryID;
@property (nonatomic, copy, nullable) NSString *folderID;
@end

BOOL WCAtlasHomeCategoriesIsSyntheticUserName(NSString *userName) {
    return [userName hasPrefix:WCAtlasHomeCategorySessionPrefix];
}

static NSDictionary *WCAtlasHomeCategoryForSyntheticUserName(NSString *userName) {
    if (!WCAtlasHomeCategoriesIsSyntheticUserName(userName)) return nil;
    NSString *identifier = [userName substringFromIndex:WCAtlasHomeCategorySessionPrefix.length];
    for (NSDictionary *category in WCAtlasHomeCategories()) {
        if ([category[@"id"] isEqualToString:identifier]) return category;
    }
    return nil;
}

void WCAtlasHomeCategoriesApplyToSessionManager(id sessionManager) {
    NSCAssert(NSThread.isMainThread, @"Homepage categories must be applied on the main thread");
    NSArray<NSDictionary *> *categories = WCAtlasHomeCategories();
    BOOL enabled = WCAtlasEnhancementEnabled(WCAtlasHomeCategoriesEnabledKey) && categories.count > 0;
    NSMutableSet<NSString *> *hidden = [NSMutableSet set];
    NSMutableArray<NSDictionary *> *entries = [NSMutableArray array];
    if (enabled) {
        for (NSDictionary *category in categories) {
            NSArray<NSString *> *orderedSessions = WCAtlasOrderedSessionsInCategory(category);
            NSSet<NSString *> *sessions = [NSSet setWithArray:orderedSessions];
            for (NSString *userName in sessions) if ([userName hasSuffix:@"@chatroom"]) [hidden addObject:userName];
            NSString *identifier = category[@"id"];
            NSString *title = category[@"title"];
            if (identifier.length == 0 || title.length == 0) continue;
            [entries addObject:@{
                @"userName": [WCAtlasHomeCategorySessionPrefix stringByAppendingString:identifier],
                @"title": title,
                @"subtitle": @"",
                @"sessionUserNames": orderedSessions
            }];
        }
    }
    WCAtlasPrivateReplaceHomeCategorySessions(sessionManager, hidden, entries);
}

BOOL WCAtlasHomeCategoriesHandleSelection(id controller, UITableView *tableView, NSIndexPath *indexPath) {
    if (![controller isKindOfClass:UIViewController.class] || !indexPath) return NO;
    id session = WCAtlasPrivateHomeSessionData(controller, tableView, indexPath);
    NSString *userName = WCAtlasPrivateHomeSessionUserName(session);
    NSDictionary *category = WCAtlasHomeCategoryForSyntheticUserName(userName);
    if (!category) return NO;
    WCAtlasHomeCategoryBrowserController *browser = [WCAtlasHomeCategoryBrowserController new];
    browser.categoryID = category[@"id"];
    browser.hidesBottomBarWhenPushed = YES;
    UINavigationController *navigation = [(UIViewController *)controller navigationController];
    if (!navigation) return NO;
    [navigation pushViewController:browser animated:YES];
    return YES;
}

void WCAtlasHomeCategoriesConfigureCellData(id cellData) {
    NSString *userName = WCAtlasPrivateHomeSessionUserName(cellData);
    NSDictionary *category = WCAtlasHomeCategoryForSyntheticUserName(userName);
    if (!category) return;
    NSString *avatarUserName = [WCAtlasHomeCategorySessionPrefix stringByAppendingString:category[@"id"] ?: @""];
    WCAtlasPrivateConfigureHomeCategoryCellData(cellData, category[@"title"], @"", avatarUserName);
}

#pragma mark - Management UI

@interface WCAtlasHomeCategoryDetailController : UITableViewController
@property (nonatomic, copy) NSString *categoryID;
@property (nonatomic, copy, nullable) NSString *folderID;
@end

static NSUInteger WCAtlasCategoryIndex(NSString *identifier, NSArray *categories) {
    return [categories indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        (void)idx; (void)stop; return [item[@"id"] isEqualToString:identifier];
    }];
}

static NSArray<NSDictionary *> *WCAtlasHomeCombinedItems(NSDictionary *category, NSDictionary *folder) {
    NSMutableArray<NSDictionary *> *items = [NSMutableArray array];
    if (!folder) {
        for (NSDictionary *child in [category[@"folders"] isKindOfClass:NSArray.class] ? category[@"folders"] : @[]) {
            [items addObject:@{@"kind": @"folder", @"value": child}];
        }
    }
    for (NSString *userName in WCAtlasHomeStringArray((folder ?: category)[@"sessions"])) {
        [items addObject:@{@"kind": @"session", @"value": userName}];
    }
    return items;
}

static const NSInteger WCAtlasHomeAvatarViewTag = 0x57434156;

static UIImage *WCAtlasHomeAvatarPlaceholder(NSString *symbolName, UIColor *color) {
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:22.0
                                                                                                  weight:UIImageSymbolWeightRegular];
    UIImage *symbol = [[UIImage systemImageNamed:symbolName withConfiguration:configuration]
        imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40.0, 40.0), NO, UIScreen.mainScreen.scale);
    CGSize size = symbol.size;
    [symbol drawInRect:CGRectMake((40.0 - size.width) * 0.5, (40.0 - size.height) * 0.5,
                                  size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

UIImage *WCAtlasHomeCategoryIconImage(void) {
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = WCAtlasHomeAvatarPlaceholder(@"folder.fill",
            [UIColor colorWithRed:0.20 green:0.48 blue:0.92 alpha:1.0]);
    });
    return image;
}

UIImage *WCAtlasHomeCategoryIconImageForUserName(NSString *userName) {
    NSDictionary *category = WCAtlasHomeCategoryForSyntheticUserName(userName);
    NSString *identifier = category[@"id"];
    NSString *avatarFile = category[WCAtlasHomeCategoryAvatarFileKey];
    if (identifier.length == 0 || avatarFile.length == 0) return WCAtlasHomeCategoryIconImage();
    UIImage *cached = [WCAtlasHomeCategoryAvatarCache() objectForKey:identifier];
    if (cached) return cached;
    UIImage *image = [UIImage imageWithContentsOfFile:WCAtlasHomeCategoryAvatarURL(avatarFile).path];
    if (!image) return WCAtlasHomeCategoryIconImage();
    [WCAtlasHomeCategoryAvatarCache() setObject:image forKey:identifier];
    return image;
}

static void WCAtlasHomeConfigureFolderImage(UITableViewCell *cell) {
    [[cell.imageView viewWithTag:WCAtlasHomeAvatarViewTag] removeFromSuperview];
    cell.imageView.image = WCAtlasHomeCategoryIconImage();
    cell.imageView.layer.cornerRadius = 0.0;
}

static void WCAtlasHomeConfigureCategoryImage(UITableViewCell *cell, NSDictionary *category) {
    [[cell.imageView viewWithTag:WCAtlasHomeAvatarViewTag] removeFromSuperview];
    NSString *identifier = category[@"id"];
    NSString *userName = identifier.length > 0
        ? [WCAtlasHomeCategorySessionPrefix stringByAppendingString:identifier] : nil;
    NSString *avatarFile = category[WCAtlasHomeCategoryAvatarFileKey];
    BOOL custom = avatarFile.length > 0 &&
                  [NSFileManager.defaultManager fileExistsAtPath:WCAtlasHomeCategoryAvatarURL(avatarFile).path];
    cell.imageView.image = WCAtlasHomeCategoryIconImageForUserName(userName);
    cell.imageView.layer.cornerRadius = custom ? 8.0 : 0.0;
    cell.imageView.clipsToBounds = custom;
    cell.imageView.contentMode = custom ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
}

static void WCAtlasHomeConfigureConversationImage(UITableViewCell *cell, NSString *userName) {
    [[cell.imageView viewWithTag:WCAtlasHomeAvatarViewTag] removeFromSuperview];
    id contact = WCAtlasPrivateContact(userName);
    UIImage *cached = WCAtlasPrivateContactAvatarImage(contact);
    if (cached) {
        cell.imageView.image = cached;
        cell.imageView.layer.cornerRadius = 6.0;
        cell.imageView.clipsToBounds = YES;
        return;
    }
    cell.imageView.image = WCAtlasHomeAvatarPlaceholder(@"person.2.fill", UIColor.secondaryLabelColor);
    UIView *avatar = WCAtlasPrivateContactAvatarView(contact, userName, YES);
    if (!avatar) return;
    avatar.tag = WCAtlasHomeAvatarViewTag;
    avatar.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    avatar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    avatar.userInteractionEnabled = NO;
    cell.imageView.clipsToBounds = YES;
    cell.imageView.layer.cornerRadius = 6.0;
    [cell.imageView addSubview:avatar];
}

#pragma mark - Homepage Category Actions

static char WCAtlasHomeCategoryAvatarPickerDelegateKey;

static BOOL WCAtlasHomeMutateCategory(NSString *identifier,
                                      void (^mutation)(NSMutableDictionary *category)) {
    if (identifier.length == 0 || !mutation) return NO;
    NSMutableArray<NSDictionary *> *categories = [WCAtlasHomeCategories() mutableCopy];
    NSUInteger index = WCAtlasCategoryIndex(identifier, categories);
    if (index == NSNotFound) return NO;
    NSMutableDictionary *category = [categories[index] mutableCopy];
    mutation(category);
    categories[index] = category;
    WCAtlasSetHomeCategories(categories);
    return YES;
}

static UIViewController *WCAtlasHomeCategoryPresenter(id controller, UITableView *tableView) {
    UIViewController *presenter = [controller isKindOfClass:UIViewController.class] ? controller : nil;
    for (UIResponder *responder = tableView; !presenter && responder; responder = responder.nextResponder) {
        if ([responder isKindOfClass:UIViewController.class]) presenter = (UIViewController *)responder;
    }
    while (presenter.presentedViewController) presenter = presenter.presentedViewController;
    return presenter;
}

static void WCAtlasHomeRemoveCategoryAvatarFile(NSString *fileName) {
    NSURL *URL = WCAtlasHomeCategoryAvatarURL(fileName);
    if (URL) [NSFileManager.defaultManager removeItemAtURL:URL error:nil];
}

static NSString *WCAtlasHomeStoreOriginalCategoryAvatar(
    NSDictionary<UIImagePickerControllerInfoKey, id> *info) {
    NSURL *sourceURL = [info[UIImagePickerControllerImageURL] isKindOfClass:NSURL.class]
        ? info[UIImagePickerControllerImageURL] : nil;
    NSData *data = sourceURL ? [NSData dataWithContentsOfURL:sourceURL options:NSDataReadingMappedIfSafe error:nil] : nil;
    NSString *extension = sourceURL.pathExtension.lowercaseString;
    NSCharacterSet *invalid = [NSCharacterSet.alphanumericCharacterSet invertedSet];
    if (extension.length == 0 || extension.length > 8 ||
        [extension rangeOfCharacterFromSet:invalid].location != NSNotFound) extension = @"jpg";
    if (data.length == 0) {
        UIImage *image = [info[UIImagePickerControllerOriginalImage] isKindOfClass:UIImage.class]
            ? info[UIImagePickerControllerOriginalImage] : nil;
        data = image ? UIImageJPEGRepresentation(image, 1.0) : nil;
        extension = @"jpg";
    }
    if (data.length == 0) return nil;
    NSString *fileName = [NSUUID.UUID.UUIDString.lowercaseString stringByAppendingPathExtension:extension];
    NSURL *destination = WCAtlasHomeCategoryAvatarURL(fileName);
    return [data writeToURL:destination options:NSDataWritingAtomic error:nil] ? fileName : nil;
}

@interface WCAtlasHomeCategoryAvatarPickerDelegate : NSObject
    <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, copy) NSString *categoryID;
@end

@implementation WCAtlasHomeCategoryAvatarPickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    NSString *avatarFile = WCAtlasHomeStoreOriginalCategoryAvatar(info);
    if (avatarFile.length > 0) {
        __block NSString *oldAvatarFile = nil;
        BOOL updated = WCAtlasHomeMutateCategory(self.categoryID, ^(NSMutableDictionary *category) {
            oldAvatarFile = category[WCAtlasHomeCategoryAvatarFileKey];
            category[WCAtlasHomeCategoryAvatarFileKey] = avatarFile;
        });
        if (updated) WCAtlasHomeRemoveCategoryAvatarFile(oldAvatarFile);
        else WCAtlasHomeRemoveCategoryAvatarFile(avatarFile);
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end


static void WCAtlasHomePresentCategoryRename(UIViewController *presenter, NSDictionary *category) {
    if (!presenter || !category) return;
    NSString *identifier = category[@"id"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名分类"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = category[@"title"];
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction *action) {
        NSString *title = [alert.textFields.firstObject.text
            stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (title.length == 0) return;
        WCAtlasHomeMutateCategory(identifier, ^(NSMutableDictionary *mutableCategory) {
            mutableCategory[@"title"] = title;
        });
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static void WCAtlasHomePresentCategoryAvatar(UIViewController *presenter, NSDictionary *category) {
    if (!presenter || !category) return;
    NSString *identifier = category[@"id"];
    NSString *currentAvatarFile = category[WCAtlasHomeCategoryAvatarFileKey];
    BOOL hasCustomAvatar = currentAvatarFile.length > 0 &&
        [NSFileManager.defaultManager fileExistsAtPath:WCAtlasHomeCategoryAvatarURL(currentAvatarFile).path];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"分类头像"
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault
                                               handler:^(__unused UIAlertAction *action) {
            UIImagePickerController *picker = [UIImagePickerController new];
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.allowsEditing = NO;
            WCAtlasHomeCategoryAvatarPickerDelegate *delegate = [WCAtlasHomeCategoryAvatarPickerDelegate new];
            delegate.categoryID = identifier;
            picker.delegate = delegate;
            objc_setAssociatedObject(picker, &WCAtlasHomeCategoryAvatarPickerDelegateKey, delegate,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [presenter presentViewController:picker animated:YES completion:nil];
        }]];
    }
    if (hasCustomAvatar) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"恢复默认头像" style:UIAlertActionStyleDestructive
                                               handler:^(__unused UIAlertAction *action) {
            WCAtlasHomeMutateCategory(identifier, ^(NSMutableDictionary *mutableCategory) {
                NSString *avatarFile = mutableCategory[WCAtlasHomeCategoryAvatarFileKey];
                [mutableCategory removeObjectForKey:WCAtlasHomeCategoryAvatarFileKey];
                WCAtlasHomeRemoveCategoryAvatarFile(avatarFile);
            });
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.sourceView = presenter.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds),
                                        CGRectGetMidY(presenter.view.bounds), 1.0, 1.0);
    }
    [presenter presentViewController:sheet animated:YES completion:nil];
}

UISwipeActionsConfiguration *WCAtlasHomeCategoriesLeadingSwipeActions(id controller,
                                                                       UITableView *tableView,
                                                                       NSIndexPath *indexPath) {
    NSCAssert(NSThread.isMainThread, @"Homepage category actions require the main thread");
    if (!tableView || !indexPath) return nil;
    id session = WCAtlasPrivateHomeSessionData(controller, tableView, indexPath);
    NSDictionary *category = WCAtlasHomeCategoryForSyntheticUserName(WCAtlasPrivateHomeSessionUserName(session));
    UIViewController *presenter = WCAtlasHomeCategoryPresenter(controller, tableView);
    if (!category || !presenter) return nil;
    UIContextualAction *rename = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                          title:@"重命名"
                                                                        handler:^(__unused UIContextualAction *action,
                                                                                  __unused UIView *sourceView,
                                                                                  void (^completionHandler)(BOOL)) {
        completionHandler(YES);
        dispatch_async(dispatch_get_main_queue(), ^{ WCAtlasHomePresentCategoryRename(presenter, category); });
    }];
    rename.backgroundColor = UIColor.systemBlueColor;
    UIContextualAction *avatar = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                          title:@"更换头像"
                                                                        handler:^(__unused UIContextualAction *action,
                                                                                  __unused UIView *sourceView,
                                                                                  void (^completionHandler)(BOOL)) {
        completionHandler(YES);
        dispatch_async(dispatch_get_main_queue(), ^{ WCAtlasHomePresentCategoryAvatar(presenter, category); });
    }];
    avatar.backgroundColor = UIColor.systemPurpleColor;
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[rename, avatar]];
    configuration.performsFirstActionWithFullSwipe = NO;
    return configuration;
}

@implementation WCAtlasHomeCategoryBrowserController

- (NSDictionary *)category {
    for (NSDictionary *category in WCAtlasHomeCategories()) if ([category[@"id"] isEqualToString:self.categoryID]) return category;
    return nil;
}
- (NSDictionary *)folder {
    for (NSDictionary *folder in [self.category[@"folders"] isKindOfClass:NSArray.class] ? self.category[@"folders"] : @[]) if ([folder[@"id"] isEqualToString:self.folderID]) return folder;
    return nil;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = (self.folder ?: self.category)[@"title"] ?: @"分类";
    self.hidesBottomBarWhenPushed = YES;
    self.tableView.rowHeight = WCAtlasHomeCategoryRowHeight;
    self.tableView.estimatedRowHeight = WCAtlasHomeCategoryRowHeight;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView; return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return WCAtlasHomeCombinedItems(self.category, self.folder).count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"browser"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"browser"];
    NSDictionary *item = WCAtlasHomeCombinedItems(self.category, self.folder)[indexPath.row];
    if ([item[@"kind"] isEqualToString:@"folder"]) {
        NSDictionary *folder = item[@"value"];
        cell.textLabel.text = folder[@"title"];
        WCAtlasHomeConfigureFolderImage(cell);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        NSString *userName = item[@"value"];
        cell.textLabel.text = WCAtlasHomeConversationTitle(userName);
        WCAtlasHomeConfigureConversationImage(cell, userName);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = WCAtlasHomeCombinedItems(self.category, self.folder)[indexPath.row];
    if ([item[@"kind"] isEqualToString:@"folder"]) {
        NSDictionary *folder = item[@"value"];
        WCAtlasHomeCategoryBrowserController *browser = [WCAtlasHomeCategoryBrowserController new];
        browser.categoryID = self.categoryID;
        browser.folderID = folder[@"id"];
        browser.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:browser animated:YES];
        return;
    }
    NSString *userName = item[@"value"];
    WCAtlasPushPrivateChat(self, userName, YES);
}

@end

@implementation WCAtlasHomeCategoriesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页群聊归类";
    self.tableView.rowHeight = WCAtlasHomeCategoryRowHeight;
    self.tableView.estimatedRowHeight = WCAtlasHomeCategoryRowHeight;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCategory)];
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self.tableView reloadData]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { (void)tableView; (void)section; return MAX(1, (NSInteger)WCAtlasHomeCategories().count); }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"category"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"category"];
    NSArray *categories = WCAtlasHomeCategories();
    if (categories.count == 0) { cell.textLabel.text = @"暂无分类，点击右上角 + 新建"; cell.imageView.image = nil; cell.accessoryType = UITableViewCellAccessoryNone; return cell; }
    NSDictionary *category = categories[indexPath.row];
    cell.textLabel.text = category[@"title"];
    WCAtlasHomeConfigureCategoryImage(cell, category);
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *categories = WCAtlasHomeCategories(); if (indexPath.row >= categories.count) return;
    WCAtlasHomeCategoryDetailController *detail = [WCAtlasHomeCategoryDetailController new]; detail.categoryID = categories[indexPath.row][@"id"];
    [self.navigationController pushViewController:detail animated:YES];
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView; if (style != UITableViewCellEditingStyleDelete) return;
    NSMutableArray *categories = [WCAtlasHomeCategories() mutableCopy]; if (indexPath.row >= categories.count) return;
    NSString *avatarFile = categories[indexPath.row][WCAtlasHomeCategoryAvatarFileKey];
    [categories removeObjectAtIndex:indexPath.row];
    WCAtlasSetHomeCategories(categories); WCAtlasHomeRemoveCategoryAvatarFile(avatarFile); [self.tableView reloadData];
}
- (void)addCategory {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建首页分类" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"例如：工作群"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"创建" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *title = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]; if (!title.length) return;
        NSMutableArray *categories = [WCAtlasHomeCategories() mutableCopy];
        [categories addObject:@{@"id": WCAtlasHomeCategoryIdentifier(), @"title": title, @"sessions": @[], @"folders": @[]}];
        WCAtlasSetHomeCategories(categories); [self.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end

@implementation WCAtlasHomeCategoryDetailController

- (NSDictionary *)category {
    for (NSDictionary *category in WCAtlasHomeCategories()) if ([category[@"id"] isEqualToString:self.categoryID]) return category;
    return nil;
}
- (NSDictionary *)folder {
    for (NSDictionary *folder in [self.category[@"folders"] isKindOfClass:NSArray.class] ? self.category[@"folders"] : @[]) if ([folder[@"id"] isEqualToString:self.folderID]) return folder;
    return nil;
}
- (NSArray<NSString *> *)sessions { return WCAtlasHomeStringArray((self.folder ?: self.category)[@"sessions"]); }
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = (self.folder ?: self.category)[@"title"] ?: @"归类";
    self.tableView.rowHeight = WCAtlasHomeCategoryRowHeight;
    self.tableView.estimatedRowHeight = WCAtlasHomeCategoryRowHeight;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItem)];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView; return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { (void)tableView; (void)section; return MAX(1, (NSInteger)WCAtlasHomeCombinedItems(self.category, self.folder).count); }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detail"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"detail"];
    NSArray *items = WCAtlasHomeCombinedItems(self.category, self.folder);
    if (items.count == 0) { cell.textLabel.text = @"暂无内容"; cell.imageView.image = nil; cell.accessoryType = UITableViewCellAccessoryNone; return cell; }
    NSDictionary *item = items[indexPath.row];
    if ([item[@"kind"] isEqualToString:@"session"]) {
        NSString *userName = item[@"value"]; cell.textLabel.text = WCAtlasHomeConversationTitle(userName); WCAtlasHomeConfigureConversationImage(cell, userName); cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        NSDictionary *folder = item[@"value"]; cell.textLabel.text = folder[@"title"]; WCAtlasHomeConfigureFolderImage(cell); cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *items = WCAtlasHomeCombinedItems(self.category, self.folder); if (indexPath.row >= items.count) return;
    NSDictionary *item = items[indexPath.row]; if (![item[@"kind"] isEqualToString:@"folder"]) return;
    NSDictionary *folder = item[@"value"];
    WCAtlasHomeCategoryDetailController *detail = [WCAtlasHomeCategoryDetailController new]; detail.categoryID = self.categoryID; detail.folderID = folder[@"id"];
    [self.navigationController pushViewController:detail animated:YES];
}
- (void)addItem {
    if (self.folderID) { [self chooseSessions]; return; }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"添加内容" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"选择群聊" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) { [self chooseSessions]; }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"新建文件夹" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) { [self addFolder]; }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController; if (popover) { popover.barButtonItem = self.navigationItem.rightBarButtonItem; }
    [self presentViewController:sheet animated:YES completion:nil];
}
- (void)chooseSessions {
    NSMutableOrderedSet *selected = [NSMutableOrderedSet orderedSetWithArray:self.sessions]; __weak typeof(self) weakSelf = self;
    __block UIViewController *picker = WCAtlasCreateGroupPicker(@"选择归类群聊", @"仅显示群聊；每个群聊只保留一个一级分类或文件夹位置。", ^BOOL(NSString *userName) { return [selected containsObject:userName]; }, ^(NSString *userName) { if ([selected containsObject:userName]) [selected removeObject:userName]; else if (userName.length) [selected addObject:userName]; });
    WCAtlasConfigureConversationPickerCompletion(picker, ^{ [weakSelf saveSessions:selected.array]; [picker.navigationController popViewControllerAnimated:YES]; });
    [self.navigationController pushViewController:picker animated:YES];
}
- (void)saveSessions:(NSArray *)sessions {
    NSArray<NSString *> *normalized = WCAtlasHomeStringArray(sessions);
    NSSet<NSString *> *assigned = [NSSet setWithArray:normalized];
    NSMutableArray *categories = [WCAtlasHomeCategories() mutableCopy];
    NSUInteger targetCategoryIndex = WCAtlasCategoryIndex(self.categoryID, categories);
    if (targetCategoryIndex == NSNotFound) return;
    for (NSUInteger categoryIndex = 0; categoryIndex < categories.count; categoryIndex++) {
        NSMutableDictionary *category = [categories[categoryIndex] mutableCopy];
        BOOL targetCategory = categoryIndex == targetCategoryIndex;
        NSArray *directSessions = WCAtlasHomeStringArray(category[@"sessions"]);
        if (targetCategory && self.folderID.length == 0) {
            category[@"sessions"] = normalized;
        } else {
            NSMutableArray *remaining = [NSMutableArray array];
            for (NSString *userName in directSessions) {
                if (![assigned containsObject:userName]) [remaining addObject:userName];
            }
            category[@"sessions"] = remaining;
        }
        NSMutableArray *folders = [NSMutableArray array];
        for (NSDictionary *rawFolder in category[@"folders"] ?: @[]) {
            NSMutableDictionary *folder = [rawFolder mutableCopy];
            BOOL targetFolder = targetCategory && [folder[@"id"] isEqualToString:self.folderID];
            if (targetFolder) {
                folder[@"sessions"] = normalized;
            } else {
                NSMutableArray *remaining = [NSMutableArray array];
                for (NSString *userName in WCAtlasHomeStringArray(folder[@"sessions"])) {
                    if (![assigned containsObject:userName]) [remaining addObject:userName];
                }
                folder[@"sessions"] = remaining;
            }
            [folders addObject:folder];
        }
        category[@"folders"] = folders;
        categories[categoryIndex] = category;
    }
    WCAtlasSetHomeCategories(categories);
    [self.tableView reloadData];
}
- (void)addFolder {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建文件夹" message:nil preferredStyle:UIAlertControllerStyleAlert]; [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"文件夹名称"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"创建" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) { NSString *title = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]; if (!title.length) return; NSMutableArray *categories = [WCAtlasHomeCategories() mutableCopy]; NSUInteger index = WCAtlasCategoryIndex(self.categoryID, categories); if (index == NSNotFound) return; NSMutableDictionary *category = [categories[index] mutableCopy]; NSMutableArray *folders = [category[@"folders"] mutableCopy] ?: [NSMutableArray array]; [folders addObject:@{@"id": WCAtlasHomeCategoryIdentifier(), @"title": title, @"sessions": @[]}]; category[@"folders"] = folders; categories[index] = category; WCAtlasSetHomeCategories(categories); [self.tableView reloadData]; }]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView; if (style != UITableViewCellEditingStyleDelete) return;
    NSArray *items = WCAtlasHomeCombinedItems(self.category, self.folder); if (indexPath.row >= items.count) return;
    NSDictionary *item = items[indexPath.row];
    if ([item[@"kind"] isEqualToString:@"session"]) { NSMutableArray *sessions = [self.sessions mutableCopy]; [sessions removeObject:item[@"value"]]; [self saveSessions:sessions]; return; }
    NSDictionary *targetFolder = item[@"value"];
    NSMutableArray *categories = [WCAtlasHomeCategories() mutableCopy]; NSUInteger index = WCAtlasCategoryIndex(self.categoryID, categories); if (index == NSNotFound) return; NSMutableDictionary *category = [categories[index] mutableCopy]; NSMutableArray *folders = [category[@"folders"] mutableCopy]; NSUInteger folderIndex = [folders indexOfObjectPassingTest:^BOOL(NSDictionary *folder, NSUInteger idx, BOOL *stop) { (void)idx; (void)stop; return [folder[@"id"] isEqualToString:targetFolder[@"id"]]; }]; if (folderIndex != NSNotFound) { [folders removeObjectAtIndex:folderIndex]; category[@"folders"] = folders; categories[index] = category; WCAtlasSetHomeCategories(categories); [self.tableView reloadData]; }
}
@end
