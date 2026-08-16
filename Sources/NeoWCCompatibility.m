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
    NSMutableSet<NSString *> *items = NeoWCTriggeredCompatibilityItems();
    @synchronized (items) {
        [items addObject:identifier];
    }
}

static NSArray<NSDictionary *> *NeoWCCompatibilityDefinitions(void) {
    static NSArray<NSDictionary *> *definitions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        definitions = @[
            @{ @"id": @"anti-revoke", @"title": @"防撤回", @"class": @"CMessageMgr", @"selector": @"onNewSyncNotAddDBMessage:" },
            @{ @"id": @"multi-select-export", @"title": @"多选消息导出", @"class": @"BaseMsgContentViewController", @"selector": @"ShowMultiSelectMoreOperation:" },
            @{ @"id": @"image-edit", @"title": @"图片编辑快捷发送", @"class": @"EditImageForwardAndEditLogicController", @"selector": @"OnClickEditImageDoneBarButton" },
            @{ @"id": @"device-login", @"title": @"设备扫码自动登录", @"class": @"MultiDeviceCardLoginContentView", @"selector": @"onTapConfirmButton" },
            @{ @"id": @"game-login", @"title": @"游戏扫码授权", @"class": @"MMAuthorizeUserInfoViewController", @"selector": @"viewDidAppear:" },
            @{ @"id": @"moments-like", @"title": @"朋友圈双击点赞", @"class": @"WCTimeLineCellView", @"selector": @"onAccessibilityLike" },
            @{ @"id": @"moments-forward", @"title": @"朋友圈转发", @"class": @"WCTimeLineCellView", @"selector": @"m_dataItem" },
            @{ @"id": @"moments-quick-permissions", @"title": @"朋友圈头像快捷权限", @"class": @"WCTimeLineCellView", @"selector": @"editBlackList" },
            @{ @"id": @"moments-precise-time", @"title": @"朋友圈精确发布时间", @"class": @"WCTimeLineCellView", @"selector": @"updateWithDataItem:actionAreaVM:" },
            @{ @"id": @"game-selector", @"title": @"小游戏结果选择", @"class": @"CMessageMgr", @"selector": @"AddEmoticonMsg:MsgWrap:" },
            @{ @"id": @"chat-joker", @"title": @"聊天记录小丑", @"class": @"TextMessageCellView", @"selector": @"operationMenuItems" },
            @{ @"id": @"image-joker", @"title": @"图片记录伪装", @"class": @"ImageMessageCellView", @"selector": @"operationMenuItems" },
            @{ @"id": @"emoticon-to-selfie", @"title": @"表情存入自拍", @"class": @"EmoticonMessageCellView", @"selector": @"filteredMenuItems:" },
            @{ @"id": @"reply-swipe", @"title": @"消息手势", @"class": @"CommonMessageCellView", @"selector": @"onShowMsgReplyMenuItem:" },
            @{ @"id": @"chat-message-time", @"title": @"消息时间显示", @"class": @"CommonMessageCellView", @"selector": @"updateNodeStatus" },
            @{ @"id": @"message-block", @"title": @"消息屏蔽", @"class": @"CMessageMgr", @"selector": @"AsyncOnAddMsg:MsgWrap:" },
            @{ @"id": @"long-press-menu", @"title": @"长按菜单管理", @"class": @"BaseMessageCellView", @"selector": @"filteredMenuItems:" },
            @{ @"id": @"group-member-reminder", @"title": @"群成员进退群提醒", @"class": @"CContactMgr", @"selector": @"printContactImportantChangeData:oldContact:" },
            @{ @"id": @"auto-original-image", @"title": @"自动选择原图", @"class": @"MMAssetPickerController", @"selector": @"viewDidLoad" },
            @{ @"id": @"notification-direct-chat", @"title": @"通知直达聊天", @"class": @"NotificationActionsMgr", @"selector": @"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:" },
            @{ @"id": @"wallet-balance", @"title": @"钱包余额本地显示", @"class": @"TimeoutNumber", @"selector": @"updateNumber:" },
            @{ @"id": @"contacts-count", @"title": @"好友数量本地显示", @"class": @"MMUILabel", @"selector": @"setText:" },
            @{ @"id": @"steps", @"title": @"微信运动步数", @"class": @"WCDeviceStepObject", @"selector": @"m7StepCount" },
            @{ @"id": @"steps-upload", @"title": @"微信运动上传步数", @"class": @"UploadDeviceStepReq", @"selector": @"stepCount" },
            @{ @"id": @"page-scale", @"title": @"页面缩放", @"class": @"MMThemeManager", @"selector": @"getValueOfProperty:inRuleSet:" },
            @{ @"id": @"ad-block", @"title": @"广告精简", @"class": @"WCDataItem", @"selector": @"isAd" },
            @{ @"id": @"plugin-manager", @"title": @"插件管理", @"class": @"WCPluginsMgr", @"selector": @"registerControllerWithTitle:version:controller:" },
            @{ @"id": @"input-rounding", @"title": @"聊天输入栏圆角", @"class": @"MMInputToolView", @"selector": @"didMoveToWindow" },
            @{ @"id": @"input-swipe", @"title": @"输入框滑动操作", @"class": @"MMGrowTextView", @"selector": @"didMoveToWindow" },
            @{ @"id": @"hide-chat-mute-icon", @"title": @"隐藏群标题尾部信息", @"class": @"RoomContentLogicController", @"selector": @"getDefaultTitleTailSubViews" },
            @{ @"id": @"me-menu-visibility", @"title": @"我的页面入口管理", @"class": @"MoreViewController", @"selector": @"addCardsIfNeededToSection:" },
            @{ @"id": @"auto-voice-transcription", @"title": @"语音自动转文字", @"class": @"VoiceMessageCellView", @"selector": @"onVoiceTrans:" },
            @{ @"id": @"hide-screenshot-forward", @"title": @"隐藏截屏分享按钮", @"class": @"MMScreenShotViewController", @"selector": @"show" },
            @{ @"id": @"quote-jump", @"title": @"引用消息定位", @"class": @"CommonMessageCellView", @"selector": @"handleTapReferMessage" },
            @{ @"id": @"red-envelope-detail", @"title": @"红包详情显示", @"class": @"WCRedEnvelopesRedEnvelopesDetailViewController", @"selector": @"viewWillAppear:" },
            @{ @"id": @"call-confirm", @"title": @"通话二次确认", @"class": @"VoIPBubbleMessageCellView", @"selector": @"startVoiceVoip" },
            @{ @"id": @"qr-camera-source", @"title": @"伪装扫码来源", @"class": @"ScanQRCodeLogicController", @"selector": @"onDetectCodesWithMarkDotInfoList:isCameraScan:" },
        ];
    });
    return definitions;
}

static NSDictionary *NeoWCCompatibilityStatus(NSDictionary *definition) {
    Class cls = objc_getClass([definition[@"class"] UTF8String]);
    if (!cls) return @{ @"text": @"类不存在", @"color": UIColor.systemRedColor };
    SEL selector = NSSelectorFromString(definition[@"selector"]);
    if (![cls instancesRespondToSelector:selector] && ![cls respondsToSelector:selector]) {
        return @{ @"text": @"Selector 变化", @"color": UIColor.systemOrangeColor };
    }
    BOOL triggered = NO;
    NSMutableSet<NSString *> *items = NeoWCTriggeredCompatibilityItems();
    @synchronized (items) {
        triggered = [items containsObject:definition[@"id"]];
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
