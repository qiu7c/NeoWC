#import "NeoWCSendConfirmationViewController.h"
#import "NeoWCSendConfirmation.h"
#import "NeoWCAccount.h"
#import <objc/message.h>
#import <objc/runtime.h>

static id NeoWCSendConfirmationService(Class serviceClass) {
    Class centerClass = NSClassFromString(@"MMServiceCenter");
    SEL centerSelector = NSSelectorFromString(@"defaultCenter");
    SEL serviceSelector = NSSelectorFromString(@"getService:");
    if (!serviceClass || !centerClass || ![centerClass respondsToSelector:centerSelector]) return nil;
    id center = ((id (*)(id, SEL))objc_msgSend)(centerClass, centerSelector);
    return [center respondsToSelector:serviceSelector]
        ? ((id (*)(id, SEL, Class))objc_msgSend)(center, serviceSelector, serviceClass) : nil;
}

static BOOL NeoWCSendConfirmationObjectReturnMethod(id target, SEL selector, NSUInteger arguments) {
    Method method = target ? class_getInstanceMethod([target class], selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != arguments) return NO;
    char returnType[8] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    return returnType[0] == '@';
}

static id NeoWCSendConfirmationObjectValue(id object, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!NeoWCSendConfirmationObjectReturnMethod(object, selector, 2)) return nil;
    @try { return ((id (*)(id, SEL))objc_msgSend)(object, selector); }
    @catch (__unused NSException *exception) { return nil; }
}

static BOOL NeoWCSendConfirmationBooleanValue(id object, NSString *selectorName, BOOL *available) {
    if (available) *available = NO;
    SEL selector = NSSelectorFromString(selectorName);
    Method method = object ? class_getInstanceMethod([object class], selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != 2) return NO;
    char returnType[8] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    if (returnType[0] != 'B' && returnType[0] != 'c') return NO;
    if (available) *available = YES;
    @try { return ((BOOL (*)(id, SEL))objc_msgSend)(object, selector); }
    @catch (__unused NSException *exception) { if (available) *available = NO; return NO; }
}

static NSString *NeoWCSendConfirmationContactString(id contact, NSArray<NSString *> *selectors) {
    for (NSString *selectorName in selectors) {
        id value = NeoWCSendConfirmationObjectValue(contact, selectorName);
        if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    }
    return nil;
}

static id NeoWCSendConfirmationContactForName(id manager, NSString *username) {
    for (NSString *selectorName in @[@"getContactByName:", @"getContact:"]) {
        SEL selector = NSSelectorFromString(selectorName);
        if (!NeoWCSendConfirmationObjectReturnMethod(manager, selector, 3)) continue;
        @try {
            id contact = ((id (*)(id, SEL, id))objc_msgSend)(manager, selector, username);
            if (contact) return contact;
        } @catch (__unused NSException *exception) {}
    }
    return nil;
}

static NSArray *NeoWCSendConfirmationCollection(id target, NSArray<NSString *> *selectorNames) {
    for (NSString *selectorName in selectorNames) {
        id value = NeoWCSendConfirmationObjectValue(target, selectorName);
        if ([value conformsToProtocol:@protocol(NSFastEnumeration)]) {
            NSMutableArray *items = [NSMutableArray array];
            for (id item in value) if (item) [items addObject:item];
            return items;
        }
    }
    return @[];
}

static NSDictionary *NeoWCSendConfirmationConversation(id candidate, id manager, BOOL groupHint) {
    NSString *username = [candidate isKindOfClass:NSString.class] ? candidate :
        NeoWCSendConfirmationContactString(candidate, @[@"m_nsUserName", @"m_nsUsrName", @"userName"]);
    id contact = [candidate isKindOfClass:NSString.class] ? NeoWCSendConfirmationContactForName(manager, username) : candidate;
    if (username.length == 0) username = NeoWCSendConfirmationContactString(contact, @[@"m_nsUserName", @"m_nsUsrName", @"userName"]);
    if (username.length == 0 || [username isEqualToString:NeoWCCurrentUserWXID()] || [username isEqualToString:@"filehelper"]) return nil;
    BOOL group = groupHint || [username hasSuffix:@"@chatroom"];
    BOOL chatroomCheckAvailable = NO;
    BOOL isChatroom = NeoWCSendConfirmationBooleanValue(contact, @"isChatroom", &chatroomCheckAvailable);
    if (chatroomCheckAvailable) group = group || isChatroom;
    if (!group) {
        BOOL singleCheckAvailable = NO;
        BOOL isSingleContact = NeoWCSendConfirmationBooleanValue(contact, @"isWeixinSingleConatct", &singleCheckAvailable);
        if (singleCheckAvailable && !isSingleContact) return nil;
    }
    NSString *displayName = NeoWCSendConfirmationContactString(contact, @[@"getContactDisplayName", @"m_nsRemark", @"m_nsNickName", @"m_nsUsrName"]);
    if (displayName.length == 0) displayName = username;
    return @{ @"username": username, @"name": displayName, @"group": @(group) };
}

@interface NeoWCSendConfirmationConversationPicker : UITableViewController <UISearchResultsUpdating>
@property (nonatomic, copy) NSArray<NSDictionary *> *allItems;
@property (nonatomic, copy) NSArray<NSDictionary *> *visibleItems;
@property (nonatomic, strong) UISearchController *searchController;
@end

@implementation NeoWCSendConfirmationConversationPicker

- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择好友或群聊";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.placeholder = @"搜索好友、群聊或 username";
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
    [self loadConversations];
}

- (void)done { [self.navigationController popViewControllerAnimated:YES]; }

- (void)loadConversations {
    id contactManager = NeoWCSendConfirmationService(NSClassFromString(@"CContactMgr"));
    id dataLogic = NeoWCSendConfirmationService(NSClassFromString(@"ContactsDataLogic"));
    NSArray *friends = NeoWCSendConfirmationCollection(dataLogic, @[@"getAllNormalContact"]);
    if (friends.count == 0) friends = NeoWCSendConfirmationCollection(contactManager, @[@"getAllContactUserNameFromCache", @"getAllContactUserName"]);
    NSArray *groups = NeoWCSendConfirmationCollection(dataLogic, @[@"getChatRoomContacts"]);
    NSMutableDictionary<NSString *, NSDictionary *> *deduplicated = [NSMutableDictionary dictionary];
    for (id candidate in friends) {
        NSDictionary *item = NeoWCSendConfirmationConversation(candidate, contactManager, NO);
        if (item) deduplicated[item[@"username"]] = item;
    }
    for (id candidate in groups) {
        NSDictionary *item = NeoWCSendConfirmationConversation(candidate, contactManager, YES);
        if (item) deduplicated[item[@"username"]] = item;
    }
    self.allItems = [deduplicated.allValues sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        BOOL leftGroup = [left[@"group"] boolValue], rightGroup = [right[@"group"] boolValue];
        if (leftGroup != rightGroup) return leftGroup ? NSOrderedDescending : NSOrderedAscending;
        return [left[@"name"] localizedCaseInsensitiveCompare:right[@"name"]];
    }];
    [self applyQuery:self.searchController.searchBar.text];
}

- (void)applyQuery:(NSString *)query {
    NSString *trimmed = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0) self.visibleItems = self.allItems;
    else self.visibleItems = [self.allItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *item, NSDictionary *bindings) {
        (void)bindings;
        return [item[@"name"] localizedCaseInsensitiveContainsString:trimmed] ||
               [item[@"username"] localizedCaseInsensitiveContainsString:trimmed];
    }]];
    [self.tableView reloadData];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController { [self applyQuery:searchController.searchBar.text]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { (void)tableView; (void)section; return self.visibleItems.count; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.allItems.count > 0 ? @"勾选的会话会立即开启发送前确认；再次点击可取消。" : @"微信尚未返回可用的好友或群聊列表。";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConversationPicker"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ConversationPicker"];
    NSDictionary *item = self.visibleItems[indexPath.row];
    NSString *username = item[@"username"];
    cell.textLabel.text = item[@"name"];
    cell.detailTextLabel.text = username;
    cell.imageView.image = [UIImage systemImageNamed:[item[@"group"] boolValue] ? @"person.3.fill" : @"person.crop.circle.fill"];
    cell.accessoryType = [NeoWCSendConfirmationProtectedConversations() containsObject:username] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *username = self.visibleItems[indexPath.row][@"username"];
    BOOL isProtected = [NeoWCSendConfirmationProtectedConversations() containsObject:username];
    NeoWCSendConfirmationSetProtected(username, !isProtected);
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end

@interface NeoWCSendConfirmationViewController ()
@property (nonatomic, copy) NSArray<NSString *> *usernames;
@end

@implementation NeoWCSendConfirmationViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"发送前确认";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addConversation)];
    [self reloadConversations];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadConversations];
}

- (void)reloadConversations {
    self.usernames = NeoWCSendConfirmationProtectedConversations();
    [self.tableView reloadData];
}

- (void)addConversation {
    if (NeoWCCurrentUserWXID().length == 0) {
        [self showMessage:@"尚未识别当前微信账号，请返回 NeoWC 设置后重试。" title:@"无法添加"];
        return;
    }
    [self.navigationController pushViewController:[NeoWCSendConfirmationConversationPicker new] animated:YES];
}

- (void)showMessage:(NSString *)message title:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.usernames.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.usernames.count > 0
        ? @"只保存会话 username；显示名称在运行时读取。点击右上角可继续勾选，左滑可移除。"
        : @"尚未设置受保护会话。点击右上角，从好友和群聊列表中勾选。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"SendConfirmationConversation";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    NSString *username = self.usernames[indexPath.row];
    cell.textLabel.text = NeoWCSendConfirmationDisplayName(username);
    cell.detailTextLabel.text = username;
    cell.imageView.image = [UIImage systemImageNamed:[username hasSuffix:@"@chatroom"] ? @"person.3.fill" : @"person.crop.circle.fill"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSString *username = self.usernames[indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIContextualAction *remove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                          title:@"移除"
                                                                        handler:^(__unused UIContextualAction *action, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
        NeoWCSendConfirmationSetProtected(username, NO);
        [weakSelf reloadConversations];
        completionHandler(YES);
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[remove]];
}

@end
