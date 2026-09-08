#import "NeoWCAutomationViewController.h"
#import "NeoWCAutomation.h"
#import "NeoWCQuickReplyStore.h"

static NSString *NeoWCAutomationSourceName(NeoWCAutomationSourceType type) {
    switch (type) {
        case NeoWCAutomationSourceTypeLibraryText: return @"消息库文字";
        case NeoWCAutomationSourceTypeJavaScript: return @"JavaScript";
        default: return @"固定文字";
    }
}

@interface NeoWCAutomationLibraryPicker : UITableViewController
@property (nonatomic, copy) NSArray<NeoWCQuickReplyItem *> *items;
@property (nonatomic, copy) void (^selectionHandler)(NeoWCQuickReplyItem *item);
- (instancetype)initWithSelectionHandler:(void (^)(NeoWCQuickReplyItem *item))handler;
@end

@implementation NeoWCAutomationLibraryPicker

- (instancetype)initWithSelectionHandler:(void (^)(NeoWCQuickReplyItem *))handler {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (!self) return nil;
    _selectionHandler = [handler copy];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择文字素材";
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NeoWCQuickReplyItem *item,
                                                                     NSDictionary *bindings) {
        (void)bindings;
        return item.type == NeoWCQuickReplyTypeText;
    }];
    self.items = [[NeoWCQuickReplyStore.sharedStore.items filteredArrayUsingPredicate:predicate]
        sortedArrayUsingComparator:^NSComparisonResult(NeoWCQuickReplyItem *first,
                                                         NeoWCQuickReplyItem *second) {
        return [first.title localizedStandardCompare:second.title];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return MAX((NSInteger)self.items.count, 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.items.count ? @"仅显示消息库中的文字素材。" : @"消息库中暂无文字素材。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"automation-library"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:@"automation-library"];
    if (self.items.count == 0) {
        cell.textLabel.text = @"暂无文字素材";
        cell.detailTextLabel.text = @"请先在消息库添加文字";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    NeoWCQuickReplyItem *item = self.items[indexPath.row];
    cell.textLabel.text = item.title.length ? item.title : @"未命名文字";
    cell.detailTextLabel.text = item.text;
    cell.detailTextLabel.numberOfLines = 2;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= self.items.count) return;
    if (self.selectionHandler) self.selectionHandler(self.items[indexPath.row]);
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@interface NeoWCAutomationEditorViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) NeoWCAutomationTask *task;
@property (nonatomic, strong) UISwitch *enabledSwitch;
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UITextField *targetField;
@property (nonatomic, strong) UISegmentedControl *sourceControl;
@property (nonatomic, strong) UITextView *contentView;
@property (nonatomic, strong) UISegmentedControl *repeatControl;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, assign) NeoWCAutomationSourceType displayedSource;
@property (nonatomic, copy) void (^saveHandler)(NeoWCAutomationTask *task);
- (instancetype)initWithTask:(NeoWCAutomationTask *)task
                  saveHandler:(void (^)(NeoWCAutomationTask *task))saveHandler;
@end

@implementation NeoWCAutomationEditorViewController

- (instancetype)initWithTask:(NeoWCAutomationTask *)task
                  saveHandler:(void (^)(NeoWCAutomationTask *))saveHandler {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (!self) return nil;
    _task = task.copy;
    _saveHandler = [saveHandler copy];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"定时任务";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveTask)];

    self.enabledSwitch = [UISwitch new];
    self.enabledSwitch.on = self.task.isEnabled;
    self.nameField = [self fieldWithPlaceholder:@"任务名称" text:self.task.name];
    self.targetField = [self fieldWithPlaceholder:@"wxid 或 123@chatroom" text:self.task.targetUserName];
    self.targetField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.targetField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.sourceControl = [[UISegmentedControl alloc] initWithItems:@[@"固定文字", @"消息库", @"JS"]];
    self.sourceControl.selectedSegmentIndex = self.task.sourceType;
    self.displayedSource = self.task.sourceType;
    [self.sourceControl addTarget:self action:@selector(sourceChanged:) forControlEvents:UIControlEventValueChanged];
    self.contentView = [UITextView new];
    self.contentView.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    self.contentView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.contentView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.contentView.delegate = self;
    self.repeatControl = [[UISegmentedControl alloc] initWithItems:@[@"仅一次", @"每天"]];
    self.repeatControl.selectedSegmentIndex = self.task.repeatMode;
    self.datePicker = [UIDatePicker new];
    self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    if (@available(iOS 13.4, *)) self.datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    self.datePicker.date = self.task.nextFireDate ?: [NSDate dateWithTimeIntervalSinceNow:300];
    [self updateContentForSource];
}

- (UITextField *)fieldWithPlaceholder:(NSString *)placeholder text:(NSString *)text {
    UITextField *field = [UITextField new];
    field.placeholder = placeholder;
    field.text = text;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.returnKeyType = UIReturnKeyDone;
    field.delegate = self;
    return field;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView; return 5; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    if (section == 1) return 2;
    if (section == 2) return 2;
    if (section == 3) return 2;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return @[@"状态", @"目标", @"内容来源", @"执行时间", @"说明"][section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if (section == 1) return @"目标固定由任务配置，脚本不能更改发送对象。";
    if (section == 2 && self.sourceControl.selectedSegmentIndex == NeoWCAutomationSourceTypeJavaScript)
        return @"实现 function main(input)，返回要发送的非空字符串。可用 httpGet(url) 和 httpPost(url, body, contentType)，建议仅请求 HTTPS。";
    if (section == 3) return @"微信被系统挂起或结束后无法保证整点执行；恢复运行时会补跑逾期任务。";
    if (section == 4) return @"启用任务后会自动复用“保持后台运行”。单次任务完成后自动关闭。";
    return nil;
}

- (UITableViewCell *)controlCell:(UIView *)control identifier:(NSString *)identifier {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:identifier];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:control];
    [NSLayoutConstraint activateConstraints:@[
        [control.leadingAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.leadingAnchor],
        [control.trailingAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.trailingAnchor],
        [control.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:8],
        [control.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-8],
    ]];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"enabled"];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"enabled"];
        cell.textLabel.text = @"启用任务";
        cell.accessoryView = self.enabledSwitch;
        return cell;
    }
    if (indexPath.section == 1) return [self controlCell:indexPath.row ? self.targetField : self.nameField
                                               identifier:indexPath.row ? @"target" : @"name"];
    if (indexPath.section == 2 && indexPath.row == 0)
        return [self controlCell:self.sourceControl identifier:@"source"];
    if (indexPath.section == 2) {
        if (self.sourceControl.selectedSegmentIndex == NeoWCAutomationSourceTypeLibraryText) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"library"];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"library"];
            cell.textLabel.text = @"选择文字素材";
            cell.detailTextLabel.text = [self selectedLibraryTitle];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
        return [self controlCell:self.contentView identifier:@"content"];
    }
    if (indexPath.section == 3)
        return [self controlCell:indexPath.row ? self.datePicker : self.repeatControl
                       identifier:indexPath.row ? @"date" : @"repeat"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notice"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"notice"];
    cell.textLabel.text = @"进程内定时调度";
    cell.detailTextLabel.text = @"不会建立系统级定时任务，也不会绕过 iOS 后台限制。";
    cell.detailTextLabel.numberOfLines = 0;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (indexPath.section == 2 && indexPath.row == 1 &&
        self.sourceControl.selectedSegmentIndex != NeoWCAutomationSourceTypeLibraryText) return 190;
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 2 || indexPath.row != 1 ||
        self.sourceControl.selectedSegmentIndex != NeoWCAutomationSourceTypeLibraryText) return;
    __weak typeof(self) weakSelf = self;
    NeoWCAutomationLibraryPicker *picker = [[NeoWCAutomationLibraryPicker alloc]
        initWithSelectionHandler:^(NeoWCQuickReplyItem *item) {
        weakSelf.task.libraryItemIdentifier = item.identifier;
        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:2]
                          withRowAnimation:UITableViewRowAnimationNone];
    }];
    [self.navigationController pushViewController:picker animated:YES];
}

- (NSString *)selectedLibraryTitle {
    for (NeoWCQuickReplyItem *item in NeoWCQuickReplyStore.sharedStore.items) {
        if ([item.identifier isEqualToString:self.task.libraryItemIdentifier])
            return item.title.length ? item.title : @"未命名文字";
    }
    return @"未选择";
}

- (void)sourceChanged:(UISegmentedControl *)sender {
    if (self.displayedSource == NeoWCAutomationSourceTypeFixedText)
        self.task.fixedText = self.contentView.text ?: @"";
    else if (self.displayedSource == NeoWCAutomationSourceTypeJavaScript)
        self.task.script = self.contentView.text ?: @"";
    self.displayedSource = sender.selectedSegmentIndex;
    [self updateContentForSource];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2]
                  withRowAnimation:UITableViewRowAnimationFade];
}

- (void)updateContentForSource {
    if (self.sourceControl.selectedSegmentIndex == NeoWCAutomationSourceTypeJavaScript)
        self.contentView.text = self.task.script;
    else if (self.sourceControl.selectedSegmentIndex == NeoWCAutomationSourceTypeFixedText)
        self.contentView.text = self.task.fixedText;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"无法保存" message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)saveTask {
    NSString *(^trim)(NSString *) = ^NSString *(NSString *value) {
        return [value ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    };
    NSString *target = trim(self.targetField.text);
    if (target.length == 0) { [self showError:@"请输入单聊 wxid 或群聊 ID。"] ; return; }
    NeoWCAutomationSourceType source = self.sourceControl.selectedSegmentIndex;
    if (source == NeoWCAutomationSourceTypeLibraryText && self.task.libraryItemIdentifier.length == 0) {
        [self showError:@"请选择消息库文字素材。"]; return;
    }
    if (source != NeoWCAutomationSourceTypeLibraryText && trim(self.contentView.text).length == 0) {
        [self showError:source == NeoWCAutomationSourceTypeJavaScript ? @"JS 脚本不能为空。" : @"发送文字不能为空。"]; return;
    }
    self.task.name = trim(self.nameField.text).length ? trim(self.nameField.text) : @"定时消息";
    self.task.targetUserName = target;
    self.task.enabled = self.enabledSwitch.isOn;
    self.task.sourceType = source;
    if (source == NeoWCAutomationSourceTypeFixedText) self.task.fixedText = self.contentView.text ?: @"";
    if (source == NeoWCAutomationSourceTypeJavaScript) self.task.script = self.contentView.text ?: @"";
    self.task.repeatMode = self.repeatControl.selectedSegmentIndex;
    self.task.nextFireDate = self.datePicker.date;
    if (self.saveHandler) self.saveHandler(self.task);
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@interface NeoWCAutomationViewController ()
@property (nonatomic, copy) NSArray<NeoWCAutomationTask *> *tasks;
@end

@implementation NeoWCAutomationViewController

- (instancetype)init { return [self initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"定时消息与脚本";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTask)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadTasks];
}

- (void)reloadTasks {
    self.tasks = NeoWCAutomationManager.sharedManager.tasks;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return MAX((NSInteger)self.tasks.count, 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return @"启用任务会自动请求微信后台保活。右滑可立即试跑，左滑可删除；示例模板删除后不会恢复。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"automation-task"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:@"automation-task"];
    if (self.tasks.count == 0) {
        cell.textLabel.text = @"暂无任务";
        cell.detailTextLabel.text = @"点按右上角 + 新建";
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    NeoWCAutomationTask *task = self.tasks[indexPath.row];
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.dateFormat = @"MM-dd HH:mm";
    });
    cell.textLabel.text = task.name;
    NSString *schedule = task.repeatMode == NeoWCAutomationRepeatModeDaily
        ? [@"每天 " stringByAppendingString:[[formatter stringFromDate:task.nextFireDate] substringFromIndex:6]]
        : [formatter stringFromDate:task.nextFireDate];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@ · %@%@", task.targetUserName.length ? task.targetUserName : @"未设置目标",
        NeoWCAutomationSourceName(task.sourceType), schedule, task.lastResult.length ? [@" · " stringByAppendingString:task.lastResult] : @""];
    cell.detailTextLabel.numberOfLines = 2;
    UISwitch *toggle = [UISwitch new];
    toggle.on = task.isEnabled;
    toggle.tag = indexPath.row;
    [toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)addTask { [self editTask:[NeoWCAutomationTask new]]; }

- (void)editTask:(NeoWCAutomationTask *)task {
    __weak typeof(self) weakSelf = self;
    NeoWCAutomationEditorViewController *editor = [[NeoWCAutomationEditorViewController alloc]
        initWithTask:task saveHandler:^(NeoWCAutomationTask *saved) {
        [NeoWCAutomationManager.sharedManager saveTask:saved];
        [weakSelf reloadTasks];
    }];
    [self.navigationController pushViewController:editor animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < self.tasks.count) [self editTask:self.tasks[indexPath.row]];
}

- (void)toggleChanged:(UISwitch *)sender {
    if (sender.tag >= self.tasks.count) return;
    NeoWCAutomationTask *task = self.tasks[sender.tag].copy;
    if (sender.isOn && task.targetUserName.length == 0) {
        sender.on = NO;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请先编辑任务"
            message:@"启用前需要填写接收消息的 wxid 或群聊 ID。"
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    task.enabled = sender.isOn;
    [NeoWCAutomationManager.sharedManager saveTask:task];
    [self reloadTasks];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (indexPath.row >= self.tasks.count) return nil;
    NeoWCAutomationTask *task = self.tasks[indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIContextualAction *remove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
        title:@"删除" handler:^(UIContextualAction *action, UIView *sourceView, void (^completion)(BOOL)) {
        (void)action; (void)sourceView;
        [NeoWCAutomationManager.sharedManager deleteTaskWithIdentifier:task.identifier];
        [weakSelf reloadTasks];
        completion(YES);
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[remove]];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (indexPath.row >= self.tasks.count) return nil;
    NeoWCAutomationTask *task = self.tasks[indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIContextualAction *run = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
        title:@"试跑" handler:^(UIContextualAction *action, UIView *sourceView, void (^completion)(BOOL)) {
        (void)action; (void)sourceView;
        [NeoWCAutomationManager.sharedManager runTaskNow:task];
        completion(YES);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ [weakSelf reloadTasks]; });
    }];
    run.backgroundColor = UIColor.systemBlueColor;
    return [UISwipeActionsConfiguration configurationWithActions:@[run]];
}

@end
