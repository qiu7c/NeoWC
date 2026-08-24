#import "NeoWCMediaGroupViewController.h"
#import "NeoWCSendConfirmation.h"
#import "NeoWCSendConfirmationViewController.h"

@interface NeoWCMediaGroupViewController ()
@property (nonatomic, copy) NSString *pageTitle;
@property (nonatomic, copy) NSString *defaultsKey;
@property (nonatomic, copy) NSArray<NSString *> *groups;
@end

@implementation NeoWCMediaGroupViewController

- (instancetype)initWithTitle:(NSString *)title defaultsKey:(NSString *)defaultsKey {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _pageTitle = [title copy];
        _defaultsKey = [defaultsKey copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.pageTitle;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.rowHeight = 60.0;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addGroup)];
    [self reloadGroups];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadGroups];
}

- (void)reloadGroups {
    NSArray *stored = [NSUserDefaults.standardUserDefaults arrayForKey:self.defaultsKey];
    NSMutableOrderedSet<NSString *> *values = [NSMutableOrderedSet orderedSet];
    for (id value in stored) {
        if ([value isKindOfClass:NSString.class] && [value hasSuffix:@"@chatroom"]) [values addObject:value];
    }
    self.groups = [values.array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [self.tableView reloadData];
}

- (void)setGroup:(NSString *)username enabled:(BOOL)enabled {
    if (![username hasSuffix:@"@chatroom"]) return;
    NSMutableOrderedSet *values = [NSMutableOrderedSet orderedSetWithArray:self.groups ?: @[]];
    if (enabled) [values addObject:username]; else [values removeObject:username];
    [NSUserDefaults.standardUserDefaults setObject:values.array forKey:self.defaultsKey];
    [self reloadGroups];
}

- (void)addGroup {
    __weak typeof(self) weakSelf = self;
    UIViewController *picker = NeoWCCreateGroupPicker(self.pageTitle,
                                                       @"只在勾选的群聊中识别新收到的消息；再次点击可取消。",
                                                       ^BOOL(NSString *username) {
        return [weakSelf.groups containsObject:username];
    }, ^(NSString *username) {
        [weakSelf setGroup:username enabled:![weakSelf.groups containsObject:username]];
    });
    [self.navigationController pushViewController:picker animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.groups.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.groups.count > 0
        ? @"只保存群聊 username；显示名称在运行时读取。左滑可移除。"
        : @"尚未启用群聊。点击右上角添加。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MediaRecognitionGroup"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MediaRecognitionGroup"];
    NSString *username = indexPath.row < (NSInteger)self.groups.count ? self.groups[indexPath.row] : @"";
    cell.textLabel.text = NeoWCSendConfirmationDisplayName(username);
    cell.detailTextLabel.text = username;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSString *username = indexPath.row < (NSInteger)self.groups.count ? self.groups[indexPath.row] : nil;
    __weak typeof(self) weakSelf = self;
    UIContextualAction *remove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                          title:@"移除"
                                                                        handler:^(__unused UIContextualAction *action, __unused UIView *view, void (^completion)(BOOL)) {
        [weakSelf setGroup:username enabled:NO];
        completion(YES);
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[remove]];
}

@end
