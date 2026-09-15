#import "WCAtlasHomeCategories.h"
#import "WCAtlasEnhancements.h"
#import "WCAtlasPrivateAPI.h"
#import "WCAtlasSendConfirmationViewController.h"
#import <objc/message.h>
#import <objc/runtime.h>

NSString *const WCAtlasHomeCategoriesEnabledKey = @"com.qiu7c.wcatlas.home.categories.enabled";
NSString *const WCAtlasHomeCategoriesDataKey = @"com.qiu7c.wcatlas.home.categories.data";
NSString *const WCAtlasHomeCategoriesSelectedKey = @"com.qiu7c.wcatlas.home.categories.selected";

static NSString *const WCAtlasHomeCategoriesDidChangeNotification = @"WCAtlasHomeCategoriesDidChangeNotification";
static char WCAtlasHomeCategoryBarKey;
static char WCAtlasHomeCategoryOriginalInsetKey;
static char WCAtlasHomeCategoryControllerKey;

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
    [NSNotificationCenter.defaultCenter postNotificationName:WCAtlasHomeCategoriesDidChangeNotification object:nil];
}

static NSSet<NSString *> *WCAtlasSessionsInCategory(NSDictionary *category) {
    NSMutableSet *sessions = [NSMutableSet setWithArray:WCAtlasHomeStringArray(category[@"sessions"])];
    for (NSDictionary *folder in [category[@"folders"] isKindOfClass:NSArray.class] ? category[@"folders"] : @[]) {
        [sessions addObjectsFromArray:WCAtlasHomeStringArray(folder[@"sessions"])];
    }
    return sessions;
}

static NSDictionary *WCAtlasSelectedHomeCategory(void) {
    NSString *selected = [NSUserDefaults.standardUserDefaults stringForKey:WCAtlasHomeCategoriesSelectedKey];
    for (NSDictionary *category in WCAtlasHomeCategories()) {
        if ([category[@"id"] isEqualToString:selected]) return category;
    }
    return nil;
}

static NSString *WCAtlasHomeConversationTitle(NSString *userName) {
    id contact = WCAtlasPrivateContact(userName);
    return WCAtlasPrivateContactDisplayName(contact, userName) ?: userName;
}

#pragma mark - Native Homepage Projection

typedef CGFloat (*WCAtlasHomeHeightIMP)(id, SEL, UITableView *, NSIndexPath *);

static NSMutableDictionary<NSString *, NSValue *> *WCAtlasHomeHeightOriginals(void) {
    static NSMutableDictionary *values;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ values = [NSMutableDictionary dictionary]; });
    return values;
}

static WCAtlasHomeHeightIMP WCAtlasHomeOriginalHeight(id owner) {
    for (Class cls = [owner class]; cls; cls = class_getSuperclass(cls)) {
        NSValue *value = WCAtlasHomeHeightOriginals()[NSStringFromClass(cls)];
        if (value) return (WCAtlasHomeHeightIMP)value.pointerValue;
    }
    return NULL;
}

static CGFloat WCAtlasProjectedHomeHeight(id owner, SEL selector, UITableView *tableView,
                                          NSIndexPath *indexPath) {
    WCAtlasHomeHeightIMP original = WCAtlasHomeOriginalHeight(owner);
    CGFloat nativeHeight = original ? original(owner, selector, tableView, indexPath) : UITableViewAutomaticDimension;
    if (!WCAtlasEnhancementEnabled(WCAtlasHomeCategoriesEnabledKey)) return nativeHeight;
    NSDictionary *category = WCAtlasSelectedHomeCategory();
    if (!category) return nativeHeight;
    id session = WCAtlasPrivateHomeSessionData(owner, nil, indexPath);
    id controller = objc_getAssociatedObject(owner, &WCAtlasHomeCategoryControllerKey);
    if (!session && controller != owner) session = WCAtlasPrivateHomeSessionData(controller, nil, indexPath);
    NSString *userName = WCAtlasPrivateHomeSessionUserName(session);
    if (userName.length == 0) return nativeHeight;
    return [WCAtlasSessionsInCategory(category) containsObject:userName] ? nativeHeight : 0.0;
}

static BOOL WCAtlasHomeReturnIsCGFloat(Method method) {
    if (!method || method_getNumberOfArguments(method) != 4) return NO;
    char returnType[16] = {0};
    char tableType[16] = {0};
    char indexPathType[16] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    method_getArgumentType(method, 2, tableType, sizeof(tableType));
    method_getArgumentType(method, 3, indexPathType, sizeof(indexPathType));
    if (tableType[0] != '@' || indexPathType[0] != '@') return NO;
#if CGFLOAT_IS_DOUBLE
    return returnType[0] == 'd';
#else
    return returnType[0] == 'f';
#endif
}

void WCAtlasHomeCategoriesInstallProjectionOnClass(Class ownerClass) {
    if (!ownerClass) return;
    SEL selector = @selector(tableView:heightForRowAtIndexPath:);
    Method method = class_getInstanceMethod(ownerClass, selector);
    if (!WCAtlasHomeReturnIsCGFloat(method)) return;
    IMP current = method_getImplementation(method);
    if (current == (IMP)WCAtlasProjectedHomeHeight) return;
    NSString *className = NSStringFromClass(ownerClass);
    WCAtlasHomeHeightOriginals()[className] = [NSValue valueWithPointer:current];
    const char *types = method_getTypeEncoding(method);
    if (!class_addMethod(ownerClass, selector, (IMP)WCAtlasProjectedHomeHeight, types)) {
        class_replaceMethod(ownerClass, selector, (IMP)WCAtlasProjectedHomeHeight, types);
    }
}

@interface WCAtlasHomeCategoryBar : UIScrollView
@property (nonatomic, weak) UITableView *tableView;
- (void)reloadButtons;
@end

@interface WCAtlasHomeCategoryBrowserController : UITableViewController
@property (nonatomic, copy) NSString *categoryID;
@property (nonatomic, copy, nullable) NSString *folderID;
@end

@implementation WCAtlasHomeCategoryBar

- (instancetype)initWithTableView:(UITableView *)tableView {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
    _tableView = tableView;
    self.showsHorizontalScrollIndicator = NO;
    self.backgroundColor = UIColor.systemBackgroundColor;
    [self reloadButtons];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(modelChanged:)
                                               name:WCAtlasHomeCategoriesDidChangeNotification object:nil];
    return self;
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)modelChanged:(NSNotification *)note { (void)note; [self reloadButtons]; [self.tableView reloadData]; }

- (void)reloadButtons {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSArray *categories = WCAtlasHomeCategories();
    NSString *selected = [NSUserDefaults.standardUserDefaults stringForKey:WCAtlasHomeCategoriesSelectedKey];
    CGFloat x = 12.0;
    NSArray *entries = [@[@{@"id": @"", @"title": @"全部"}] arrayByAddingObjectsFromArray:categories];
    for (NSDictionary *entry in entries) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        NSString *identifier = entry[@"id"] ?: @"";
        BOOL active = identifier.length == 0 ? selected.length == 0 : [selected isEqualToString:identifier];
        [button setTitle:entry[@"title"] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14 weight:active ? UIFontWeightSemibold : UIFontWeightRegular];
        button.backgroundColor = active ? [UIColor.systemBlueColor colorWithAlphaComponent:0.14] : UIColor.secondarySystemBackgroundColor;
        button.layer.cornerRadius = 15.0;
        button.tag = [entries indexOfObject:entry];
        [button addTarget:self action:@selector(selectCategory:) forControlEvents:UIControlEventTouchUpInside];
        CGSize size = [button sizeThatFits:CGSizeMake(CGFLOAT_MAX, 30.0)];
        button.frame = CGRectMake(x, 7.0, MAX(58.0, size.width + 24.0), 30.0);
        [self addSubview:button];
        x = CGRectGetMaxX(button.frame) + 8.0;
    }
    self.contentSize = CGSizeMake(x + 4.0, 44.0);
}

- (void)selectCategory:(UIButton *)sender {
    NSArray *categories = WCAtlasHomeCategories();
    if (sender.tag > (NSInteger)categories.count) return;
    NSString *identifier = sender.tag == 0 ? nil : categories[(NSUInteger)sender.tag - 1][@"id"];
    NSString *current = [NSUserDefaults.standardUserDefaults stringForKey:WCAtlasHomeCategoriesSelectedKey];
    if (identifier.length > 0 && [current isEqualToString:identifier]) {
        UIViewController *controller = objc_getAssociatedObject(self.tableView, &WCAtlasHomeCategoryControllerKey);
        WCAtlasHomeCategoryBrowserController *browser = [WCAtlasHomeCategoryBrowserController new];
        browser.categoryID = identifier;
        if (controller.navigationController) [controller.navigationController pushViewController:browser animated:YES];
        return;
    }
    if (identifier.length) [NSUserDefaults.standardUserDefaults setObject:identifier forKey:WCAtlasHomeCategoriesSelectedKey];
    else [NSUserDefaults.standardUserDefaults removeObjectForKey:WCAtlasHomeCategoriesSelectedKey];
    [self reloadButtons];
    [self.tableView reloadData];
}

@end

void WCAtlasHomeCategoriesAttach(UIViewController *controller, UITableView *tableView) {
    if (!controller || !tableView) return;
    WCAtlasHomeCategoriesInstallProjectionOnClass([controller class]);
    WCAtlasHomeCategoriesInstallProjectionOnClass([tableView.delegate class]);
    objc_setAssociatedObject(tableView, &WCAtlasHomeCategoryControllerKey, controller, OBJC_ASSOCIATION_ASSIGN);
    if (tableView.delegate) objc_setAssociatedObject(tableView.delegate, &WCAtlasHomeCategoryControllerKey,
                                                     controller, OBJC_ASSOCIATION_ASSIGN);
    WCAtlasHomeCategoryBar *bar = objc_getAssociatedObject(controller, &WCAtlasHomeCategoryBarKey);
    BOOL enabled = WCAtlasEnhancementEnabled(WCAtlasHomeCategoriesEnabledKey) && WCAtlasHomeCategories().count > 0;
    if (!enabled) {
        if (bar) {
            NSValue *original = objc_getAssociatedObject(tableView, &WCAtlasHomeCategoryOriginalInsetKey);
            if (original) tableView.contentInset = original.UIEdgeInsetsValue;
            [bar removeFromSuperview];
            objc_setAssociatedObject(controller, &WCAtlasHomeCategoryBarKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [tableView reloadData];
        }
        return;
    }
    if (!bar) {
        objc_setAssociatedObject(tableView, &WCAtlasHomeCategoryOriginalInsetKey,
                                 [NSValue valueWithUIEdgeInsets:tableView.contentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UIEdgeInsets inset = tableView.contentInset;
        inset.top += 44.0;
        tableView.contentInset = inset;
        bar = [[WCAtlasHomeCategoryBar alloc] initWithTableView:tableView];
        bar.translatesAutoresizingMaskIntoConstraints = NO;
        [controller.view addSubview:bar];
        [NSLayoutConstraint activateConstraints:@[
            [bar.leadingAnchor constraintEqualToAnchor:tableView.leadingAnchor],
            [bar.trailingAnchor constraintEqualToAnchor:tableView.trailingAnchor],
            [bar.topAnchor constraintEqualToAnchor:tableView.topAnchor],
            [bar.heightAnchor constraintEqualToConstant:44.0],
        ]];
        objc_setAssociatedObject(controller, &WCAtlasHomeCategoryBarKey, bar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        bar.tableView = tableView;
        [bar reloadButtons];
    }
    [controller.view bringSubviewToFront:bar];
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
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { (void)tableView; return !self.folderID && section == 0 ? @"文件夹" : @"会话"; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    return section == [self numberOfSectionsInTableView:tableView] - 1 ? @"再次点击首页当前分类可进入此页面；会话仍由微信原生聊天页打开。" : nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"browser"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"browser"];
    if (!self.folderID && indexPath.section == 0) {
        NSDictionary *folder = self.category[@"folders"][indexPath.row];
        cell.textLabel.text = folder[@"title"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu 个会话", (unsigned long)[folder[@"sessions"] count]];
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
    self.title = @"首页会话归类";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCategory)];
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self.tableView reloadData]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { (void)tableView; (void)section; return MAX(1, (NSInteger)WCAtlasHomeCategories().count); }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section { (void)tableView; (void)section; return @"分类显示在微信首页；每个分类可直接收录会话，也可继续创建文件夹。未归类会话仍可在“全部”查看。"; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"category"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"category"];
    NSArray *categories = WCAtlasHomeCategories();
    if (categories.count == 0) { cell.textLabel.text = @"暂无分类"; cell.detailTextLabel.text = @"点击右上角 + 新建"; cell.accessoryType = UITableViewCellAccessoryNone; return cell; }
    NSDictionary *category = categories[indexPath.row];
    cell.textLabel.text = category[@"title"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu 个会话 · %lu 个文件夹", (unsigned long)WCAtlasSessionsInCategory(category).count, (unsigned long)[category[@"folders"] count]];
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
    NSString *identifier = categories[indexPath.row][@"id"]; [categories removeObjectAtIndex:indexPath.row];
    if ([[NSUserDefaults.standardUserDefaults stringForKey:WCAtlasHomeCategoriesSelectedKey] isEqualToString:identifier]) [NSUserDefaults.standardUserDefaults removeObjectForKey:WCAtlasHomeCategoriesSelectedKey];
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
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { (void)tableView; return section == 0 ? @"会话" : @"文件夹"; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detail"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"detail"];
    if (indexPath.section == 0) {
        NSArray *sessions = self.sessions; if (sessions.count == 0) { cell.textLabel.text = @"暂无会话"; cell.detailTextLabel.text = @"点击右上角 + 选择"; cell.accessoryType = UITableViewCellAccessoryNone; return cell; }
        NSString *userName = sessions[indexPath.row]; cell.textLabel.text = WCAtlasHomeConversationTitle(userName); cell.detailTextLabel.text = userName; cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        NSArray *folders = self.category[@"folders"]; if (folders.count == 0) { cell.textLabel.text = @"暂无文件夹"; cell.detailTextLabel.text = @"点击右上角 + 创建"; cell.accessoryType = UITableViewCellAccessoryNone; return cell; }
        NSDictionary *folder = folders[indexPath.row]; cell.textLabel.text = folder[@"title"]; cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu 个会话", (unsigned long)[folder[@"sessions"] count]]; cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
    [sheet addAction:[UIAlertAction actionWithTitle:@"选择会话" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) { [self chooseSessions]; }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"新建文件夹" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) { [self addFolder]; }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController; if (popover) { popover.barButtonItem = self.navigationItem.rightBarButtonItem; }
    [self presentViewController:sheet animated:YES completion:nil];
}
- (void)chooseSessions {
    NSMutableOrderedSet *selected = [NSMutableOrderedSet orderedSetWithArray:self.sessions]; __weak typeof(self) weakSelf = self;
    __block UIViewController *picker = WCAtlasCreateConversationPicker(@"选择归类会话", @"好友和群聊均可选择；同一会话可存在于多个分类或文件夹。", ^BOOL(NSString *userName) { return [selected containsObject:userName]; }, ^(NSString *userName) { if ([selected containsObject:userName]) [selected removeObject:userName]; else if (userName.length) [selected addObject:userName]; });
    WCAtlasConfigureConversationPickerCompletion(picker, ^{ [weakSelf saveSessions:selected.array]; [picker.navigationController popViewControllerAnimated:YES]; });
    [self.navigationController pushViewController:picker animated:YES];
}
- (void)saveSessions:(NSArray *)sessions {
    NSMutableArray *categories = [WCAtlasHomeCategories() mutableCopy]; NSUInteger index = WCAtlasCategoryIndex(self.categoryID, categories); if (index == NSNotFound) return;
    NSMutableDictionary *category = [categories[index] mutableCopy];
    if (!self.folderID) category[@"sessions"] = WCAtlasHomeStringArray(sessions);
    else { NSMutableArray *folders = [category[@"folders"] mutableCopy]; NSUInteger folderIndex = [folders indexOfObjectPassingTest:^BOOL(NSDictionary *folder, NSUInteger idx, BOOL *stop) { (void)idx; (void)stop; return [folder[@"id"] isEqualToString:self.folderID]; }]; if (folderIndex != NSNotFound) { NSMutableDictionary *folder = [folders[folderIndex] mutableCopy]; folder[@"sessions"] = WCAtlasHomeStringArray(sessions); folders[folderIndex] = folder; category[@"folders"] = folders; } }
    categories[index] = category; WCAtlasSetHomeCategories(categories); [self.tableView reloadData];
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
