#import "NeoWCSendConfirmationViewController.h"
#import "NeoWCSendConfirmation.h"
#import "NeoWCAccount.h"

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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加受保护会话"
                                                                   message:@"填写联系人 wxid 或以 @chatroom 结尾的群聊账号。名称和头像不会写入配置。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"wxid 或群聊账号";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"添加" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *username = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (username.length == 0) return;
        NeoWCSendConfirmationSetProtected(username, YES);
        [weakSelf reloadConversations];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
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
        ? @"只保存会话 username；显示名称在运行时读取。左滑可移除。"
        : @"尚未设置受保护会话。开启功能后，仅列表中的会话会在发送前要求确认。";
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
