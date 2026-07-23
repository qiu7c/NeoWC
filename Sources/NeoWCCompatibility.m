#import "NeoWCCompatibility.h"

#import <objc/runtime.h>

static NSMutableSet<NSString *> *NeoWCTriggeredCompatibilityItems(void) {
    static NSMutableSet<NSString *> *items;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ items = [NSMutableSet set]; });
    return items;
}

void NeoWCCompatibilityMarkTriggered(NSString *identifier) {
    if (identifier.length == 0) return;
    @synchronized (NeoWCTriggeredCompatibilityItems()) {
        [NeoWCTriggeredCompatibilityItems() addObject:identifier];
    }
}

static NSArray<NSDictionary *> *NeoWCCompatibilityDefinitions(void) {
    return @[
        @{ @"id": @"anti-revoke", @"title": @"防撤回", @"class": @"CMessageMgr", @"selector": @"onNewSyncNotAddDBMessage:" },
        @{ @"id": @"multi-select-export", @"title": @"多选消息导出", @"class": @"BaseMsgContentViewController", @"selector": @"ShowMultiSelectMoreOperation:" },
        @{ @"id": @"image-edit", @"title": @"图片编辑快捷发送", @"class": @"EditImageForwardAndEditLogicController", @"selector": @"OnClickEditImageDoneBarButton" },
        @{ @"id": @"device-login", @"title": @"设备扫码自动登录", @"class": @"MultiDeviceCardLoginContentView", @"selector": @"onTapConfirmButton" },
        @{ @"id": @"game-login", @"title": @"游戏扫码授权", @"class": @"MMAuthorizeUserInfoViewController", @"selector": @"viewDidAppear:" },
        @{ @"id": @"moments-like", @"title": @"朋友圈双击点赞", @"class": @"WCTimeLineCellView", @"selector": @"onAccessibilityLike" },
        @{ @"id": @"game-selector", @"title": @"小游戏结果选择", @"class": @"CMessageMgr", @"selector": @"AddEmoticonMsg:MsgWrap:" },
        @{ @"id": @"chat-joker", @"title": @"聊天记录小丑", @"class": @"TextMessageCellView", @"selector": @"operationMenuItems" },
        @{ @"id": @"wallet-balance", @"title": @"钱包余额本地显示", @"class": @"TimeoutNumber", @"selector": @"updateNumber:" },
        @{ @"id": @"contacts-count", @"title": @"好友数量本地显示", @"class": @"MMUILabel", @"selector": @"setText:" },
        @{ @"id": @"global-text-replace", @"title": @"全局文字替换", @"class": @"MMUILabel", @"selector": @"setText:" },
        @{ @"id": @"steps", @"title": @"微信运动步数", @"class": @"WCDeviceStepObject", @"selector": @"m7StepCount" },
        @{ @"id": @"ad-block", @"title": @"广告净化", @"class": @"WCDataItem", @"selector": @"isAd" },
        @{ @"id": @"plugin-visibility", @"title": @"插件显示管理", @"class": @"WCPluginsMgr", @"selector": @"registerControllerWithTitle:version:controller:" },
        @{ @"id": @"input-rounding", @"title": @"聊天输入栏圆角", @"class": @"MMInputToolView", @"selector": @"didMoveToWindow" },
        @{ @"id": @"input-swipe", @"title": @"输入框滑动操作", @"class": @"MMGrowTextView", @"selector": @"didMoveToWindow" },
        @{ @"id": @"hide-chat-mute-icon", @"title": @"隐藏免打扰图标", @"class": @"UIImageView", @"selector": @"didMoveToWindow" },
    ];
}

static NSDictionary *NeoWCCompatibilityStatus(NSDictionary *definition) {
    Class cls = objc_getClass([definition[@"class"] UTF8String]);
    if (!cls) return @{ @"text": @"类不存在", @"color": UIColor.systemRedColor };
    SEL selector = NSSelectorFromString(definition[@"selector"]);
    if (![cls instancesRespondToSelector:selector] && ![cls respondsToSelector:selector]) {
        return @{ @"text": @"Selector 变化", @"color": UIColor.systemOrangeColor };
    }
    BOOL triggered = NO;
    @synchronized (NeoWCTriggeredCompatibilityItems()) {
        triggered = [NeoWCTriggeredCompatibilityItems() containsObject:definition[@"id"]];
    }
    return triggered
        ? @{ @"text": @"可用", @"color": UIColor.systemGreenColor }
        : @{ @"text": @"尚未触发", @"color": UIColor.secondaryLabelColor };
}

@implementation NeoWCCompatibilityViewController

- (instancetype)init {
    return [self initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"功能兼容性";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(refreshCompatibility)];
}

- (void)refreshCompatibility {
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView { return 2; }

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : NeoWCCompatibilityDefinitions().count;
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"运行环境" : @"功能检查";
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == 1 ? @"仅检查运行时类与方法，不会主动执行任何增强功能。“尚未触发”表示入口存在，但本次启动尚未经过该代码路径。" : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"compatibility"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"compatibility"];
    cell.accessoryView = nil;
    if (indexPath.section == 0) {
        NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"未知";
        NSString *build = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"未知";
        cell.textLabel.text = @"当前微信版本";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@（%@）", version, build];
        cell.imageView.image = [UIImage systemImageNamed:@"app.badge.checkmark"];
    } else {
        NSDictionary *definition = NeoWCCompatibilityDefinitions()[indexPath.row];
        NSDictionary *status = NeoWCCompatibilityStatus(definition);
        cell.textLabel.text = definition[@"title"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", definition[@"class"], definition[@"selector"]];
        UILabel *label = [UILabel new];
        label.text = status[@"text"];
        label.textColor = status[@"color"];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        [label sizeToFit];
        cell.accessoryView = label;
        cell.imageView.image = [UIImage systemImageNamed:@"checklist"];
    }
    cell.imageView.tintColor = UIColor.secondaryLabelColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

@end
