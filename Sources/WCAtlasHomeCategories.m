#import "WCAtlasHomeCategories.h"
#import "WCAtlasEnhancements.h"
#import "WCAtlasPrivateAPI.h"
#import "WCAtlasSendConfirmationViewController.h"
#import <objc/message.h>
#import <objc/runtime.h>

NSString *const WCAtlasHomeCategoriesEnabledKey = @"com.qiu7c.wcatlas.home.categories.enabled";
NSString *const WCAtlasHomeCategoriesDataKey = @"com.qiu7c.wcatlas.home.categories.data";

static NSString *const WCAtlasHomeCategorySessionPrefix = @"wcatlas_home_category_";

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
    return @{@"id": identifier, @"title": title,
             @"sessions": WCAtlasHomeStringArray(raw[@"sessions"]), @"folders": folders};
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

static void WCAtlasSetHomeCategories(NSArray<NSDictionary *> *categories) {
    [NSUserDefaults.standardUserDefaults setObject:categories ?: @[] forKey:WCAtlasHomeCategoriesDataKey];
    dispatch_async(dispatch_get_main_queue(), ^{ WCAtlasPrivateRefreshHomeSessionList(); });
}

static NSSet<NSString *> *WCAtlasSessionsInCategory(NSDictionary *category) {
    NSMutableSet *sessions = [NSMutableSet setWithArray:WCAtlasHomeStringArray(category[@"sessions"])];
    for (NSDictionary *folder in [category[@"folders"] isKindOfClass:NSArray.class] ? category[@"folders"] : @[]) {
        [sessions addObjectsFromArray:WCAtlasHomeStringArray(folder[@"sessions"])];
    }
    return sessions;
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
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *entries = [NSMutableArray array];
    if (enabled) {
        for (NSDictionary *category in categories) {
            NSSet<NSString *> *sessions = WCAtlasSessionsInCategory(category);
            for (NSString *userName in sessions) if ([userName hasSuffix:@"@chatroom"]) [hidden addObject:userName];
            NSString *identifier = category[@"id"];
            NSString *title = category[@"title"];
            if (identifier.length == 0 || title.length == 0) continue;
            [entries addObject:@{
                @"userName": [WCAtlasHomeCategorySessionPrefix stringByAppendingString:identifier],
                @"title": title,
                @"subtitle": [NSString stringWithFormat:@"%lu 个群聊 · %lu 个文件夹",
                              (unsigned long)sessions.count,
                              (unsigned long)[category[@"folders"] count]]
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
    UINavigationController *navigation = [(UIViewController *)controller navigationController];
    if (!navigation) return NO;
    [navigation pushViewController:browser animated:YES];
    return YES;
}

void WCAtlasHomeCategoriesConfigureCellData(id cellData) {
    NSString *userName = WCAtlasPrivateHomeSessionUserName(cellData);
    NSDictionary *category = WCAtlasHomeCategoryForSyntheticUserName(userName);
    if (!category) return;
    NSSet<NSString *> *sessions = WCAtlasSessionsInCategory(category);
    NSString *subtitle = [NSString stringWithFormat:@"%lu 个群聊 · %lu 个文件夹",
                          (unsigned long)sessions.count,
                          (unsigned long)[category[@"folders"] count]];
    WCAtlasPrivateConfigureHomeCategoryCellData(cellData, category[@"title"], subtitle);
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

@implementation WCAtlasHomeCategoryBrowserController

- (NSDictionary *)category {
    for (NSDictionary *category in WCAtlasHomeCategories()) if ([category[@"id"] isEqualToString:self.categoryID]) return category;
    return nil;
}
- (NSDictionary *)folder {
    for (NSDictionary *folder in [self.category[@"folders"] isKindOfClass:NSArray.class] ? self.category[@"folders"] : @[]) if ([folder[@"id"] isEqualToString:self.folderID]) return folder;
    return nil;
}
- (void)viewDidLoad { [super viewDidLoad]; self.title = (self.folder ?: self.category)[@"title"] ?: @"分类"; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView; return self.folderID ? 1 : 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    if (!self.folderID && section == 0) return [(NSArray *)self.category[@"folders"] count];
    return [WCAtlasHomeStringArray((self.folder ?: self.category)[@"sessions"]) count];
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { (void)tableView; return !self.folderID && section == 0 ? @"文件夹" : @"群聊"; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    return section == [self numberOfSectionsInTableView:tableView] - 1 ? @"点击首页分类 Cell 进入此页面；群聊仍由微信原生聊天页打开。" : nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"browser"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"browser"];
    if (!self.folderID && indexPath.section == 0) {
        NSDictionary *folder = self.category[@"folders"][indexPath.row];
        cell.textLabel.text = folder[@"title"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu 个群聊", (unsigned long)[folder[@"sessions"] count]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        NSString *userName = WCAtlasHomeStringArray((self.folder ?: self.category)[@"sessions"])[indexPath.row];
        cell.textLabel.text = WCAtlasHomeConversationTitle(userName);
        cell.detailTextLabel.text = userName;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (!self.folderID && indexPath.section == 0) {
        WCAtlasHomeCategoryBrowserController *browser = [WCAtlasHomeCategoryBrowserController new];
        browser.categoryID = self.categoryID;
        browser.folderID = self.category[@"folders"][indexPath.row][@"id"];
        [self.navigationController pushViewController:browser animated:YES];
        return;
    }
    NSString *userName = WCAtlasHomeStringArray((self.folder ?: self.category)[@"sessions"])[indexPath.row];
    WCAtlasPushPrivateChat(self, userName, YES);
}

@end

@implementation WCAtlasHomeCategoriesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页群聊归类";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCategory)];
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self.tableView reloadData]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { (void)tableView; (void)section; return MAX(1, (NSInteger)WCAtlasHomeCategories().count); }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section { (void)tableView; (void)section; return @"每个一级分类都会作为一个原生会话 Cell 显示在微信首页；已归类群聊从首页收起，进入分类后仍可继续使用文件夹整理。"; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"category"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"category"];
    NSArray *categories = WCAtlasHomeCategories();
    if (categories.count == 0) { cell.textLabel.text = @"暂无分类"; cell.detailTextLabel.text = @"点击右上角 + 新建"; cell.accessoryType = UITableViewCellAccessoryNone; return cell; }
    NSDictionary *category = categories[indexPath.row];
    cell.textLabel.text = category[@"title"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu 个群聊 · %lu 个文件夹", (unsigned long)WCAtlasSessionsInCategory(category).count, (unsigned long)[category[@"folders"] count]];
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
    [categories removeObjectAtIndex:indexPath.row];
    WCAtlasSetHomeCategories(categories); [self.tableView reloadData];
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItem)];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView; return self.folderID ? 1 : 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { (void)tableView; return section == 0 ? MAX(1, (NSInteger)self.sessions.count) : MAX(1, (NSInteger)[self.category[@"folders"] count]); }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { (void)tableView; return section == 0 ? @"群聊" : @"文件夹"; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detail"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"detail"];
    if (indexPath.section == 0) {
        NSArray *sessions = self.sessions; if (sessions.count == 0) { cell.textLabel.text = @"暂无群聊"; cell.detailTextLabel.text = @"点击右上角 + 选择"; cell.accessoryType = UITableViewCellAccessoryNone; return cell; }
        NSString *userName = sessions[indexPath.row]; cell.textLabel.text = WCAtlasHomeConversationTitle(userName); cell.detailTextLabel.text = userName; cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        NSArray *folders = self.category[@"folders"]; if (folders.count == 0) { cell.textLabel.text = @"暂无文件夹"; cell.detailTextLabel.text = @"点击右上角 + 创建"; cell.accessoryType = UITableViewCellAccessoryNone; return cell; }
        NSDictionary *folder = folders[indexPath.row]; cell.textLabel.text = folder[@"title"]; cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu 个群聊", (unsigned long)[folder[@"sessions"] count]]; cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; if (indexPath.section == 0 || self.folderID) return;
    NSArray *folders = self.category[@"folders"]; if (indexPath.row >= folders.count) return;
    WCAtlasHomeCategoryDetailController *detail = [WCAtlasHomeCategoryDetailController new]; detail.categoryID = self.categoryID; detail.folderID = folders[indexPath.row][@"id"];
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
    if (indexPath.section == 0) { NSMutableArray *sessions = [self.sessions mutableCopy]; if (indexPath.row < sessions.count) { [sessions removeObjectAtIndex:indexPath.row]; [self saveSessions:sessions]; } return; }
    NSMutableArray *categories = [WCAtlasHomeCategories() mutableCopy]; NSUInteger index = WCAtlasCategoryIndex(self.categoryID, categories); if (index == NSNotFound) return; NSMutableDictionary *category = [categories[index] mutableCopy]; NSMutableArray *folders = [category[@"folders"] mutableCopy]; if (indexPath.row < folders.count) { [folders removeObjectAtIndex:indexPath.row]; category[@"folders"] = folders; categories[index] = category; WCAtlasSetHomeCategories(categories); [self.tableView reloadData]; }
}
@end
