#import "NeoWCSendConfirmationViewController.h"
#import "NeoWCSendConfirmation.h"
#import "NeoWCAccount.h"
#import "NeoWCInterfaceTweaks.h"
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

static UIView *NeoWCSendConfirmationAvatarView(NSString *username, BOOL group) {
    id manager = NeoWCSendConfirmationService(NSClassFromString(@"CContactMgr"));
    id contact = NeoWCSendConfirmationContactForName(manager, username);
    NSString *headURL = NeoWCSendConfirmationContactString(contact, @[@"m_nsHeadImgUrl"]);
    Class helperClass = NSClassFromString(@"MMHeadImageHelper");
    SEL selector = NSSelectorFromString(@"getContactHeadImageViewWithUsrName:headImgUrl:bAutoUpdate:bRoundCorner:");
    if (helperClass && [helperClass respondsToSelector:selector]) {
        id view = ((id (*)(id, SEL, id, id, BOOL, BOOL))objc_msgSend)(helperClass, selector,
                                                                      username, headURL ?: @"", YES, YES);
        if ([view isKindOfClass:UIView.class]) return view;
    }
    id image = NeoWCSendConfirmationObjectValue(contact, @"getContactHeadImage");
    UIImage *fallbackImage = [image isKindOfClass:UIImage.class] ? image :
        [UIImage systemImageNamed:group ? @"person.3.fill" : @"person.crop.circle.fill"];
    UIImageView *fallback = [[UIImageView alloc] initWithImage:fallbackImage];
    fallback.tintColor = UIColor.tertiaryLabelColor;
    fallback.contentMode = UIViewContentModeScaleAspectFill;
    return fallback;
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

@interface NeoWCSendConfirmationConversationCell : UITableViewCell
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *usernameLabel;
- (void)configureWithUsername:(NSString *)username name:(NSString *)name group:(BOOL)group;
@end

@implementation NeoWCSendConfirmationConversationCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _avatarContainer = [UIView new];
        _avatarContainer.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarContainer.clipsToBounds = YES;
        _avatarContainer.layer.cornerRadius = 22.0;
        _nameLabel = [UILabel new];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _usernameLabel = [UILabel new];
        _usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _usernameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        _usernameLabel.textColor = UIColor.secondaryLabelColor;
        [self.contentView addSubview:_avatarContainer];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_usernameLabel];
        [NSLayoutConstraint activateConstraints:@[
            [_avatarContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
            [_avatarContainer.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_avatarContainer.widthAnchor constraintEqualToConstant:44.0],
            [_avatarContainer.heightAnchor constraintEqualToConstant:44.0],
            [_nameLabel.leadingAnchor constraintEqualToAnchor:_avatarContainer.trailingAnchor constant:12.0],
            [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-12.0],
            [_nameLabel.bottomAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:-1.0],
            [_usernameLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
            [_usernameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-12.0],
            [_usernameLabel.topAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:2.0],
        ]];
    }
    return self;
}

- (void)configureWithUsername:(NSString *)username name:(NSString *)name group:(BOOL)group {
    for (UIView *view in self.avatarContainer.subviews) [view removeFromSuperview];
    UIView *avatar = NeoWCSendConfirmationAvatarView(username, group);
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.avatarContainer addSubview:avatar];
    [NSLayoutConstraint activateConstraints:@[
        [avatar.topAnchor constraintEqualToAnchor:self.avatarContainer.topAnchor],
        [avatar.bottomAnchor constraintEqualToAnchor:self.avatarContainer.bottomAnchor],
        [avatar.leadingAnchor constraintEqualToAnchor:self.avatarContainer.leadingAnchor],
        [avatar.trailingAnchor constraintEqualToAnchor:self.avatarContainer.trailingAnchor],
    ]];
    self.nameLabel.text = name;
    self.usernameLabel.text = username;
}

@end

@interface NeoWCSendConfirmationConversationPicker : NeoWCCardTableViewController <UISearchResultsUpdating>
@property (nonatomic, copy) NSArray<NSDictionary *> *allItems;
@property (nonatomic, copy) NSArray<NSDictionary *> *visibleFriends;
@property (nonatomic, copy) NSArray<NSDictionary *> *visibleGroups;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, copy) NSString *pickerTitle;
@property (nonatomic, copy) NSString *pickerFooter;
@property (nonatomic, copy) NeoWCConversationPickerSelectedBlock selectedBlock;
@property (nonatomic, copy) NeoWCConversationPickerToggleBlock toggleBlock;
- (instancetype)initWithTitle:(NSString *)title
                       footer:(NSString *)footer
                     selected:(NeoWCConversationPickerSelectedBlock)selected
                       toggle:(NeoWCConversationPickerToggleBlock)toggle;
@end

@implementation NeoWCSendConfirmationConversationPicker

- (instancetype)initWithTitle:(NSString *)title
                       footer:(NSString *)footer
                     selected:(NeoWCConversationPickerSelectedBlock)selected
                       toggle:(NeoWCConversationPickerToggleBlock)toggle {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _pickerTitle = [title copy];
        _pickerFooter = [footer copy];
        _selectedBlock = [selected copy];
        _toggleBlock = [toggle copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.pickerTitle.length > 0 ? self.pickerTitle : @"选择好友或群聊";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.rowHeight = 60.0;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.placeholder = @"搜索好友、群聊或 username";
    NeoWCStyleSearchBar(self.searchController.searchBar);
    NeoWCStyleSearchNavigationItem(self.navigationItem);
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
    NSArray *matches = trimmed.length == 0 ? self.allItems : [self.allItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *item, NSDictionary *bindings) {
        (void)bindings;
        return [item[@"name"] localizedCaseInsensitiveContainsString:trimmed] ||
               [item[@"username"] localizedCaseInsensitiveContainsString:trimmed];
    }]];
    self.visibleFriends = [matches filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *item, __unused NSDictionary *bindings) {
        return ![item[@"group"] boolValue];
    }]];
    self.visibleGroups = [matches filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *item, __unused NSDictionary *bindings) {
        return [item[@"group"] boolValue];
    }]];
    [self.tableView reloadData];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController { [self applyQuery:searchController.searchBar.text]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView; return 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return section == 0 ? self.visibleFriends.count : self.visibleGroups.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) return nil;
    return section == 0 ? @"好友" : @"群聊";
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self tableView:tableView numberOfRowsInSection:section] == 0 ? 0.01 : UITableViewAutomaticDimension;
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if (section != 1) return nil;
    return self.allItems.count > 0 ? (self.pickerFooter ?: @"点击选择或取消会话。") : @"微信尚未返回可用的好友或群聊列表。";
}
- (NSDictionary *)itemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *items = indexPath.section == 0 ? self.visibleFriends : self.visibleGroups;
    return indexPath.row < (NSInteger)items.count ? items[indexPath.row] : nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCSendConfirmationConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConversationPicker"];
    if (!cell) cell = [[NeoWCSendConfirmationConversationCell alloc] initWithReuseIdentifier:@"ConversationPicker"];
    NSDictionary *item = [self itemAtIndexPath:indexPath];
    NSString *username = item[@"username"];
    [cell configureWithUsername:username name:item[@"name"] group:[item[@"group"] boolValue]];
    cell.accessoryType = self.selectedBlock && self.selectedBlock(username) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *username = [self itemAtIndexPath:indexPath][@"username"];
    if (self.toggleBlock) self.toggleBlock(username);
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end

UIViewController *NeoWCCreateConversationPicker(NSString *title,
                                                NSString *footer,
                                                NeoWCConversationPickerSelectedBlock selected,
                                                NeoWCConversationPickerToggleBlock toggle) {
    return [[NeoWCSendConfirmationConversationPicker alloc] initWithTitle:title
                                                                   footer:footer
                                                                 selected:selected
                                                                   toggle:toggle];
}

@interface NeoWCSendConfirmationViewController ()
@property (nonatomic, copy) NSArray<NSString *> *usernames;
@property (nonatomic, copy) NSArray<NSString *> *friendUsernames;
@property (nonatomic, copy) NSArray<NSString *> *groupUsernames;
@end

@implementation NeoWCSendConfirmationViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"发送前确认";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.rowHeight = 60.0;
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
    self.friendUsernames = [self.usernames filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *username, __unused NSDictionary *bindings) {
        return ![username hasSuffix:@"@chatroom"];
    }]];
    self.groupUsernames = [self.usernames filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *username, __unused NSDictionary *bindings) {
        return [username hasSuffix:@"@chatroom"];
    }]];
    [self.tableView reloadData];
}

- (void)addConversation {
    if (NeoWCCurrentUserWXID().length == 0) {
        [self showMessage:@"尚未识别当前微信账号，请返回 NeoWC 设置后重试。" title:@"无法添加"];
        return;
    }
    UIViewController *picker = NeoWCCreateConversationPicker(@"选择好友或群聊",
                                                              @"勾选的会话会立即开启发送前确认；再次点击可取消。",
                                                              ^BOOL(NSString *username) {
        return [NeoWCSendConfirmationProtectedConversations() containsObject:username];
    }, ^(NSString *username) {
        BOOL protectedConversation = [NeoWCSendConfirmationProtectedConversations() containsObject:username];
        NeoWCSendConfirmationSetProtected(username, !protectedConversation);
    });
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)showMessage:(NSString *)message title:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return section == 0 ? self.friendUsernames.count : self.groupUsernames.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) return nil;
    return section == 0 ? @"好友" : @"群聊";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self tableView:tableView numberOfRowsInSection:section] == 0 ? 0.01 : UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if (section != 1) return nil;
    return self.usernames.count > 0
        ? @"只保存会话 username；显示名称在运行时读取。点击右上角可继续勾选，左滑可移除。"
        : @"尚未设置受保护会话。点击右上角，从好友和群聊列表中勾选。";
}

- (NSString *)usernameAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *usernames = indexPath.section == 0 ? self.friendUsernames : self.groupUsernames;
    return indexPath.row < (NSInteger)usernames.count ? usernames[indexPath.row] : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"SendConfirmationConversation";
    NeoWCSendConfirmationConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) cell = [[NeoWCSendConfirmationConversationCell alloc] initWithReuseIdentifier:reuseIdentifier];
    NSString *username = [self usernameAtIndexPath:indexPath];
    [cell configureWithUsername:username name:NeoWCSendConfirmationDisplayName(username) group:[username hasSuffix:@"@chatroom"]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSString *username = [self usernameAtIndexPath:indexPath];
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
