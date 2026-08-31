#import "NeoWCFriendRelationCheckViewController.h"
#import "NeoWCFriendRelationChecker.h"
#import "NeoWCSendConfirmationViewController.h"
#import <objc/message.h>

static UIColor *NeoWCFriendRelationSecondaryColor(void) {
    if (@available(iOS 13.0, *)) return UIColor.secondaryLabelColor;
    return UIColor.grayColor;
}

static id NeoWCFriendRelationUIServiceForClass(Class serviceClass) {
    Class centerClass = NSClassFromString(@"MMServiceCenter");
    SEL centerSelector = NSSelectorFromString(@"defaultCenter");
    SEL serviceSelector = NSSelectorFromString(@"getService:");
    if (!centerClass || !serviceClass || ![centerClass respondsToSelector:centerSelector]) return nil;
    id center = ((id (*)(id, SEL))objc_msgSend)(centerClass, centerSelector);
    return [center respondsToSelector:serviceSelector]
        ? ((id (*)(id, SEL, Class))objc_msgSend)(center, serviceSelector, serviceClass) : nil;
}

static void NeoWCFriendRelationOpenProfile(UIViewController *source, NSString *userName) {
    if (!source || userName.length == 0) return;
    id manager = NeoWCFriendRelationUIServiceForClass(NSClassFromString(@"CContactMgr"));
    id contact = nil;
    for (NSString *name in @[@"getContactByName:", @"getContactByNameFromCache:"]) {
        SEL selector = NSSelectorFromString(name);
        if (![manager respondsToSelector:selector]) continue;
        contact = ((id (*)(id, SEL, id))objc_msgSend)(manager, selector, userName);
        if (contact) break;
    }
    Class handlerClass = NSClassFromString(@"MMURLHandler");
    SEL sharedSelector = NSSelectorFromString(@"sharedInstance");
    SEL constructSelector = NSSelectorFromString(@"constructContactInfoView:withUserName:");
    id handler = [handlerClass respondsToSelector:sharedSelector]
        ? ((id (*)(id, SEL))objc_msgSend)(handlerClass, sharedSelector) : nil;
    if (contact && [handler respondsToSelector:constructSelector]) {
        id controller = ((id (*)(id, SEL, id, id))objc_msgSend)(handler,
                                                                constructSelector,
                                                                contact,
                                                                userName);
        if ([controller isKindOfClass:UIViewController.class]) {
            [source.navigationController pushViewController:controller animated:YES];
        }
    }
}

@interface NeoWCFriendRelationResultViewController : UITableViewController
@property(nonatomic, copy) NSString *verdict;
@property(nonatomic, copy) NSString *pageTitle;
@property(nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *items;
@end

@implementation NeoWCFriendRelationResultViewController

- (instancetype)initWithVerdict:(NSString *)verdict title:(NSString *)title {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _verdict = [verdict copy];
        _pageTitle = [title copy];
        _items = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.pageTitle;
    self.tableView.rowHeight = 62.0;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"全部复检" style:UIBarButtonItemStylePlain
        target:self action:@selector(recheckAll)];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reloadItems)
                                               name:NeoWCFriendRelationCheckDidUpdateNotification object:nil];
    [self reloadItems];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)reloadItems {
    self.items = [[NeoWCFriendRelationChecker sharedChecker] itemsWithVerdict:self.verdict];
    self.navigationItem.rightBarButtonItem.enabled = self.items.count > 0;
    [self.tableView reloadData];
}

- (void)recheckAll {
    NSArray *userNames = [self.items valueForKey:@"userName"];
    if (userNames.count == 0) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重新检测"
        message:[NSString stringWithFormat:@"将再次通过微信支付前置接口逐个检测 %lu 位好友。",
                 (unsigned long)userNames.count]
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始复检" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            [[NeoWCFriendRelationChecker sharedChecker] startRecheckWithUserNames:userNames];
            [self.navigationController popViewControllerAnimated:YES];
        }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"NeoWCFriendRelationResultCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    NSDictionary *item = self.items[indexPath.row];
    cell.textLabel.text = item[@"displayName"] ?: item[@"userName"];
    NSString *message = item[@"retmsg"];
    cell.detailTextLabel.text = message.length > 0 ? message : item[@"userName"];
    cell.detailTextLabel.textColor = NeoWCFriendRelationSecondaryColor();
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UISwipeActionsConfiguration *)tableView:(__unused UITableView *)tableView
       trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.items[indexPath.row];
    NSString *userName = item[@"userName"];
    UIContextualAction *remove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
        title:@"移出结果" handler:^(__unused UIContextualAction *action, __unused UIView *view,
                                    void (^completionHandler)(BOOL)) {
            [[NeoWCFriendRelationChecker sharedChecker] removeResultUserNames:userName ? @[userName] : @[]];
            completionHandler(YES);
        }];
    return [UISwipeActionsConfiguration configurationWithActions:@[remove]];
}

- (void)tableView:(__unused UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NeoWCFriendRelationOpenProfile(self, self.items[indexPath.row][@"userName"]);
}

@end

@interface NeoWCFriendRelationCheckViewController ()
@property(nonatomic, strong) UIView *progressHeader;
@property(nonatomic, strong) UILabel *progressNameLabel;
@property(nonatomic, strong) UIProgressView *progressBar;
@property(nonatomic, strong) UILabel *progressCountLabel;
@end

@implementation NeoWCFriendRelationCheckViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"检测单删好友";
    self.tableView.rowHeight = 52.0;
    [self buildProgressHeader];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(checkerDidUpdate)
                                               name:NeoWCFriendRelationCheckDidUpdateNotification object:nil];
    [self updateProgressHeader];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateProgressHeader];
    [self.tableView reloadData];
}

- (void)buildProgressHeader {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 126.0)];
    UILabel *nameLabel = [UILabel new];
    nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    nameLabel.numberOfLines = 2;
    UIProgressView *bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    bar.progressTintColor = [UIColor colorWithRed:0.10 green:0.72 blue:0.32 alpha:1.0];
    UILabel *countLabel = [UILabel new];
    countLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    countLabel.textColor = NeoWCFriendRelationSecondaryColor();
    for (UIView *view in @[nameLabel, bar, countLabel]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [header addSubview:view];
    }
    [NSLayoutConstraint activateConstraints:@[
        [nameLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20.0],
        [nameLabel.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20.0],
        [nameLabel.topAnchor constraintEqualToAnchor:header.topAnchor constant:24.0],
        [bar.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [bar.trailingAnchor constraintEqualToAnchor:nameLabel.trailingAnchor],
        [bar.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:18.0],
        [countLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [countLabel.trailingAnchor constraintEqualToAnchor:nameLabel.trailingAnchor],
        [countLabel.topAnchor constraintEqualToAnchor:bar.bottomAnchor constant:12.0],
    ]];
    self.progressHeader = header;
    self.progressNameLabel = nameLabel;
    self.progressBar = bar;
    self.progressCountLabel = countLabel;
    self.tableView.tableHeaderView = header;
}

- (void)checkerDidUpdate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateProgressHeader];
        [self.tableView reloadData];
    });
}

- (void)updateProgressHeader {
    NeoWCFriendRelationChecker *checker = NeoWCFriendRelationChecker.sharedChecker;
    self.progressNameLabel.text = checker.progressTitle;
    [self.progressBar setProgress:checker.progress animated:YES];
    self.progressCountLabel.text = [NSString stringWithFormat:@"正常 %lu · 疑似 %lu · 待复查 %lu",
        (unsigned long)checker.normalCount, (unsigned long)checker.suspectedCount,
        (unsigned long)checker.uncertainCount];
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView { return 4; }

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 2;
    if (section == 1) return 1;
    if (section == 2) return 3;
    return 1;
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"检测范围";
    if (section == 1) return @"运行";
    if (section == 2) return @"检测结果";
    return @"说明";
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) return @"检测开始后范围会固定；暂停后可继续未完成部分。";
    if (section == 2) return @"“疑似单删”来自支付接口的明确非好友响应；网络和解析异常只进入待复查。";
    return nil;
}

- (UITableViewCell *)cellWithTitle:(NSString *)title detail:(NSString *)detail accessory:(BOOL)accessory {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = detail;
    cell.accessoryType = accessory ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    return cell;
}

- (NSString *)runActionTitle {
    NSString *status = NeoWCFriendRelationChecker.sharedChecker.status;
    if ([status isEqualToString:NeoWCFriendRelationStatusRunning]) return @"暂停检测";
    if ([status isEqualToString:NeoWCFriendRelationStatusPaused]) return @"继续检测";
    if ([status isEqualToString:NeoWCFriendRelationStatusCompleted]) return @"重新检测";
    return @"开始检测";
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCFriendRelationChecker *checker = NeoWCFriendRelationChecker.sharedChecker;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            NSString *detail = checker.pendingUserNames.count > 0
                ? [NSString stringWithFormat:@"%lu 人", (unsigned long)checker.pendingUserNames.count] : @"未选择";
            return [self cellWithTitle:@"选择好友" detail:detail accessory:YES];
        }
        return [self cellWithTitle:@"使用全部好友" detail:nil accessory:NO];
    }
    if (indexPath.section == 1) {
        UITableViewCell *cell = [self cellWithTitle:[self runActionTitle] detail:nil accessory:NO];
        cell.textLabel.textColor = [checker.status isEqualToString:NeoWCFriendRelationStatusRunning]
            ? UIColor.systemOrangeColor : [UIColor colorWithRed:0.10 green:0.70 blue:0.30 alpha:1.0];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        return cell;
    }
    if (indexPath.section == 2) {
        NSArray *titles = @[@"正常好友", @"疑似单删", @"待复查"];
        NSArray *counts = @[@(checker.normalCount), @(checker.suspectedCount), @(checker.uncertainCount)];
        return [self cellWithTitle:titles[indexPath.row]
                            detail:[NSString stringWithFormat:@"%@ 人", counts[indexPath.row]] accessory:YES];
    }
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = @"本功能逐个调用微信支付前置接口进行网络检测，不会发送聊天消息或自动删除联系人。批量请求仍可能存在账号风险，请控制使用频率。";
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    cell.textLabel.textColor = NeoWCFriendRelationSecondaryColor();
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 3 ? 92.0 : 52.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self selectFriends];
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        [self selectAllFriends];
    } else if (indexPath.section == 1) {
        [self toggleRun];
    } else if (indexPath.section == 2) {
        NSArray *verdicts = @[NeoWCFriendRelationVerdictNormal,
                              NeoWCFriendRelationVerdictSuspected,
                              NeoWCFriendRelationVerdictUncertain];
        NSArray *titles = @[@"正常好友", @"疑似单删", @"待复查"];
        NeoWCFriendRelationResultViewController *controller =
            [[NeoWCFriendRelationResultViewController alloc] initWithVerdict:verdicts[indexPath.row]
                                                                        title:titles[indexPath.row]];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)selectFriends {
    NeoWCFriendRelationChecker *checker = NeoWCFriendRelationChecker.sharedChecker;
    if ([checker.status isEqualToString:NeoWCFriendRelationStatusRunning] ||
        [checker.status isEqualToString:NeoWCFriendRelationStatusPaused]) {
        [self showRangeLockedMessage];
        return;
    }
    __weak typeof(self) weakSelf = self;
    UIViewController *picker = NeoWCCreateFriendPicker(@"选择检测好友",
        @"仅选择真实好友；支持全选和反选，每次变更都会立即保存检测范围。",
        ^BOOL(NSString *userName) {
            return [NeoWCFriendRelationChecker.sharedChecker.pendingUserNames containsObject:userName];
        }, ^(NSString *userName) {
            NeoWCFriendRelationChecker *strongChecker = NeoWCFriendRelationChecker.sharedChecker;
            NSMutableOrderedSet *selection = [NSMutableOrderedSet orderedSetWithArray:strongChecker.pendingUserNames];
            if ([selection containsObject:userName]) [selection removeObject:userName];
            else [selection addObject:userName];
            [strongChecker setPendingUserNames:selection.array sourceTitle:@"自选好友"];
            [weakSelf.tableView reloadData];
        });
    NeoWCConfigureConversationPickerBulkActions(picker, ^{
        NeoWCFriendRelationChecker *strongChecker = NeoWCFriendRelationChecker.sharedChecker;
        NSArray *allUserNames = [[strongChecker allFriendCandidates] valueForKey:@"userName"];
        [strongChecker setPendingUserNames:allUserNames sourceTitle:@"全部好友"];
        [weakSelf.tableView reloadData];
    }, ^{
        NeoWCFriendRelationChecker *strongChecker = NeoWCFriendRelationChecker.sharedChecker;
        NSSet<NSString *> *selected = [NSSet setWithArray:strongChecker.pendingUserNames];
        NSMutableArray<NSString *> *inverted = [NSMutableArray array];
        for (NSDictionary *candidate in [strongChecker allFriendCandidates]) {
            NSString *userName = candidate[@"userName"];
            if (userName.length > 0 && ![selected containsObject:userName]) [inverted addObject:userName];
        }
        [strongChecker setPendingUserNames:inverted sourceTitle:@"反选好友"];
        [weakSelf.tableView reloadData];
    });
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)selectAllFriends {
    NeoWCFriendRelationChecker *checker = NeoWCFriendRelationChecker.sharedChecker;
    if ([checker.status isEqualToString:NeoWCFriendRelationStatusRunning] ||
        [checker.status isEqualToString:NeoWCFriendRelationStatusPaused]) {
        [self showRangeLockedMessage];
        return;
    }
    NSArray *candidates = [checker allFriendCandidates];
    if (candidates.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"未获取到好友"
            message:@"当前微信版本的联系人接口不可用，或通讯录尚未加载完成。"
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [checker setPendingUserNames:[candidates valueForKey:@"userName"] sourceTitle:@"全部好友"];
}

- (void)showRangeLockedMessage {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"检测范围已固定"
        message:@"请先完成当前检测；暂停状态可继续未完成部分。重新检测时可以重新选择范围。"
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)toggleRun {
    NeoWCFriendRelationChecker *checker = NeoWCFriendRelationChecker.sharedChecker;
    if ([checker.status isEqualToString:NeoWCFriendRelationStatusRunning]) {
        [checker pause];
        return;
    }
    if ([checker.status isEqualToString:NeoWCFriendRelationStatusPaused]) {
        [checker resume];
        return;
    }
    NSUInteger count = checker.pendingUserNames.count;
    if (count == 0) count = [checker allFriendCandidates].count;
    if (count == 0) {
        [self selectAllFriends];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"开始检测单删好友？"
        message:[NSString stringWithFormat:@"将串行调用微信支付前置接口检测 %lu 位好友，并在每次请求之间随机等待。好友不会收到聊天消息，但请求对微信服务端可见，批量检测可能存在账号风险。",
                 (unsigned long)count]
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确认开始" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) { [checker start]; }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
