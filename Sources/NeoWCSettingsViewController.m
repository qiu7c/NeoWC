#import "NeoWCSettingsViewController.h"
#import "NeoWCAntiRevoke.h"
#import "NeoWCAntiRevokeTemplateEditor.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import "NeoWCCompatibility.h"
#import "NeoWCPluginVisibility.h"
#import "NeoWCPluginShortcuts.h"
#import "NeoWCInterfaceTweaks.h"

static NSString *const NeoWCVersion = @"0.1.1";
static NSString *const NeoWCEnabledKey = @"com.qiu7c.neowc.enabled";
static NSString *const NeoWCExpandedCategoriesKey = @"com.qiu7c.neowc.ui.expanded-categories";
static NSString *const NeoWCCollapsedFeaturesKey = @"com.qiu7c.neowc.ui.collapsed-features";

static long long NeoWCSettingsLongLongDefaultForKey(NSString *key) {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return [value respondsToSelector:@selector(longLongValue)] ? [value longLongValue] : 0;
}

static UIImage *NeoWCSymbol(NSString *name) {
    UIImage *image = [UIImage systemImageNamed:name];
    return image ?: [UIImage systemImageNamed:@"circle.grid.2x2"];
}

typedef NS_ENUM(NSInteger, NeoWCRowKind) {
    NeoWCRowKindSwitch,
    NeoWCRowKindDetail,
    NeoWCRowKindInfo,
};

@interface NeoWCSettingItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy) NSString *defaultsKey;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, assign) NeoWCRowKind kind;
+ (instancetype)itemWithTitle:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol kind:(NeoWCRowKind)kind key:(NSString *)key value:(NSString *)value;
@end

@implementation NeoWCSettingItem
+ (instancetype)itemWithTitle:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol kind:(NeoWCRowKind)kind key:(NSString *)key value:(NSString *)value {
    NeoWCSettingItem *item = [self new];
    item.title = title;
    item.subtitle = subtitle;
    item.symbol = symbol;
    item.kind = kind;
    item.defaultsKey = key;
    item.value = value;
    return item;
}
@end

@interface NeoWCSettingSection : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy) NSString *footer;
@property (nonatomic, copy) NSArray<NeoWCSettingItem *> *items;
@property (nonatomic, assign, getter=isCollapsible) BOOL collapsible;
+ (instancetype)sectionWithIdentifier:(NSString *)identifier title:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol footer:(NSString *)footer collapsible:(BOOL)collapsible items:(NSArray<NeoWCSettingItem *> *)items;
@end

@implementation NeoWCSettingSection
+ (instancetype)sectionWithIdentifier:(NSString *)identifier title:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol footer:(NSString *)footer collapsible:(BOOL)collapsible items:(NSArray<NeoWCSettingItem *> *)items {
    NeoWCSettingSection *section = [self new];
    section.identifier = identifier;
    section.title = title;
    section.subtitle = subtitle;
    section.symbol = symbol;
    section.footer = footer;
    section.collapsible = collapsible;
    section.items = items;
    return section;
}
@end

@interface NeoWCCardBackgroundView : UIView
@property (nonatomic, assign) BOOL roundsTop;
@property (nonatomic, assign) BOOL roundsBottom;
@property (nonatomic, assign) BOOL drawsDivider;
@property (nonatomic, strong) UIColor *fillColor;
@end

@implementation NeoWCCardBackgroundView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        _fillColor = [UIColor secondarySystemBackgroundColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGRect cardRect = CGRectInset(self.bounds, 16.0, 0.0);
    UIRectCorner corners = 0;
    if (self.roundsTop) corners |= UIRectCornerTopLeft | UIRectCornerTopRight;
    if (self.roundsBottom) corners |= UIRectCornerBottomLeft | UIRectCornerBottomRight;
    UIBezierPath *path = corners ? [UIBezierPath bezierPathWithRoundedRect:cardRect byRoundingCorners:corners cornerRadii:CGSizeMake(11.0, 11.0)] : [UIBezierPath bezierPathWithRect:cardRect];
    [self.fillColor setFill];
    [path fill];

    if (self.drawsDivider) {
        CGFloat pixel = 1.0 / UIScreen.mainScreen.scale;
        [[[UIColor separatorColor] colorWithAlphaComponent:0.28] setFill];
        UIRectFill(CGRectMake(CGRectGetMinX(cardRect) + 48.0, 0.0, CGRectGetWidth(cardRect) - 64.0, pixel));
    }
}

@end

@interface NeoWCLogoView : UIView
@end

@implementation NeoWCLogoView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = @"NeoWC 图标";
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGFloat scale = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) / 64.0;
    UIBezierPath *monogram = [UIBezierPath bezierPath];
    [monogram moveToPoint:CGPointMake(16.0 * scale, 44.0 * scale)];
    [monogram addLineToPoint:CGPointMake(16.0 * scale, 20.0 * scale)];
    [monogram addLineToPoint:CGPointMake(48.0 * scale, 44.0 * scale)];
    [monogram addLineToPoint:CGPointMake(48.0 * scale, 20.0 * scale)];
    [monogram moveToPoint:CGPointMake(48.0 * scale, 44.0 * scale)];
    [monogram addLineToPoint:CGPointMake(40.5 * scale, 51.0 * scale)];
    monogram.lineWidth = 4.0 * scale;
    monogram.lineCapStyle = kCGLineCapRound;
    monogram.lineJoinStyle = kCGLineJoinRound;
    [[UIColor labelColor] setStroke];
    [monogram stroke];
}

@end

@interface NeoWCSettingsViewController ()
@property (nonatomic, copy) NSArray<NeoWCSettingSection *> *sections;
@property (nonatomic, strong) NSMutableSet<NSString *> *expandedCategoryIDs;
@property (nonatomic, strong) NSMutableSet<NSString *> *collapsedFeatureKeys;
@end


@implementation NeoWCSettingsViewController

- (instancetype)init {
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) [self buildSections];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        NeoWCEnabledKey: @YES,
        NeoWCAntiRevokeKey: @YES,
        NeoWCAntiRevokeNotifySenderKey: @NO,
        NeoWCAntiRevokeTimeFilterKey: @300.0,
        NeoWCAntiRevokePromptStyleKey: @0,
        NeoWCAntiRevokeSideTextKey: @"已拦截撤回",
        NeoWCAntiRevokeSideOffsetXKey: @0.0,
        NeoWCAntiRevokeSideOffsetYKey: @10.0,
        NeoWCAntiRevokePersistRecordsKey: @NO,
        NeoWCImageEditQuickSendEnabledKey: @NO,
        NeoWCChatJokerEnabledKey: @NO,
        NeoWCWalletBalanceEnabledKey: @NO,
        NeoWCWalletBalanceFenKey: @0,
        NeoWCContactsCountEnabledKey: @NO,
        NeoWCContactsCountKey: @0,
        NeoWCInputSwipeActionsEnabledKey: @NO,
        NeoWCMomentsLikeHapticEnabledKey: @NO,
        NeoWCMomentsLikeHapticIntensityKey: @0.65,
        NeoWCMultiSelectExportEnabledKey: @NO,
        NeoWCMultiSelectExportTextKey: @YES,
        NeoWCMultiSelectSaveImagesKey: @YES,
        NeoWCMultiSelectShareCardKey: @YES,
        NeoWCDebugLoggingEnabledKey: @YES,
        NeoWCPluginShortcutsEnabledKey: @NO,
        NeoWCPluginShortcutLoggingKey: @YES,
        NeoWCPluginShortcutFloatingDebugKey: @NO,
        NeoWCPluginShortcutDebugCenterKey: @YES,
        NeoWCPluginShortcutRevokeRecordsKey: @NO,
        NeoWCPluginShortcutCustomPageKey: @NO,
        NeoWCPluginShortcutCustomTitleKey: @"快捷页面",
        NeoWCPluginShortcutCustomClassKey: @"",
        NeoWCChatInputRoundingEnabledKey: @NO,
        NeoWCChatInputInnerRoundingKey: @YES,
        NeoWCChatInputOuterRoundingKey: @YES,
        NeoWCChatInputInnerRadiusKey: @18.0,
        NeoWCChatInputOuterRadiusKey: @22.0,
        NeoWCHideChatMuteIconKey: @NO,
        NeoWCGlobalTextReplaceEnabledKey: @NO,
        NeoWCGlobalTextReplaceSourceKey: @"",
        NeoWCGlobalTextReplaceTargetKey: @"",
        NeoWCExpandedCategoriesKey: @[@"messages"],
        NeoWCCollapsedFeaturesKey: @[],
    }];
    NSArray *savedCategories = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCExpandedCategoriesKey];
    self.expandedCategoryIDs = [NSMutableSet setWithArray:savedCategories ?: @[]];
    NSArray *collapsedFeatures = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCCollapsedFeaturesKey];
    self.collapsedFeatureKeys = [NSMutableSet setWithArray:collapsedFeatures ?: @[]];
    [self buildSections];

    self.title = @"NeoWC";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.rowHeight = 60.0;
    self.tableView.estimatedRowHeight = 60.0;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 58.0;
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 44.0;
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    self.tableView.tableHeaderView = [self makeHeaderView];
    if (@available(iOS 15.0, *)) self.tableView.sectionHeaderTopPadding = 0.0;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"NeoWCSettingCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self buildSections];
    [self.tableView reloadData];
}

- (BOOL)featureHasChildrenForKey:(NSString *)key {
    if (key.length == 0) return NO;
    static NSSet<NSString *> *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = [NSSet setWithArray:@[
            NeoWCAntiRevokeKey,
            NeoWCAntiRevokeNotifySenderKey,
            NeoWCMomentsDoubleTapLikeKey,
            NeoWCMomentsLikeHapticEnabledKey,
            NeoWCStepOverrideEnabledKey,
            NeoWCContactsCountEnabledKey,
            NeoWCMultiSelectExportEnabledKey,
            NeoWCPluginShortcutsEnabledKey,
            NeoWCPluginShortcutCustomPageKey,
            NeoWCChatInputRoundingEnabledKey,
            NeoWCGlobalTextReplaceEnabledKey,
        ]];
    });
    return [keys containsObject:key];
}

- (BOOL)isFeatureExpandedForKey:(NSString *)key {
    return ![self.collapsedFeatureKeys containsObject:key];
}

- (void)saveCollapsedFeatureKeys {
    [[NSUserDefaults standardUserDefaults] setObject:self.collapsedFeatureKeys.allObjects forKey:NeoWCCollapsedFeaturesKey];
}

- (void)buildSections {
    NeoWCSettingItem *(^item)(NSString *, NSString *, NSString *, NeoWCRowKind, NSString *, NSString *) =
    ^NeoWCSettingItem *(NSString *title, NSString *subtitle, NSString *symbol, NeoWCRowKind kind, NSString *key, NSString *value) {
        return [NeoWCSettingItem itemWithTitle:title subtitle:subtitle symbol:symbol kind:kind key:key value:value];
    };
    NSInteger configuredStepCount = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCStepCountKey];
    NSString *stepValue = configuredStepCount > 0 ? [NSString stringWithFormat:@"%ld 步", (long)configuredStepCount] : @"设置";
    NSInteger contactsCount = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCContactsCountKey];
    NSString *contactsValue = contactsCount > 0 ? [NSString stringWithFormat:@"%ld 个", (long)contactsCount] : @"设置";
    NSTimeInterval revokeFilter = [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCAntiRevokeTimeFilterKey];
    NSString *revokeFilterValue = @"不限制";
    if (revokeFilter >= 86400.0) revokeFilterValue = @"24 小时";
    else if (revokeFilter >= 3600.0) revokeFilterValue = @"1 小时";
    else if (revokeFilter >= 1800.0) revokeFilterValue = @"30 分钟";
    else if (revokeFilter >= 300.0) revokeFilterValue = @"5 分钟";
    else if (revokeFilter >= 60.0) revokeFilterValue = @"1 分钟";
    NSInteger revokePromptStyleValue = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCAntiRevokePromptStyleKey];
    id antiRevokeValue = [[NSUserDefaults standardUserDefaults] objectForKey:NeoWCAntiRevokeKey];
    BOOL antiRevokeEnabled = antiRevokeValue ? [antiRevokeValue boolValue] : YES;
    BOOL notifySenderEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCAntiRevokeNotifySenderKey];
    BOOL stepOverrideEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCStepOverrideEnabledKey];
    BOOL momentsLikeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCMomentsDoubleTapLikeKey];
    BOOL momentsHapticEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCMomentsLikeHapticEnabledKey];
    BOOL multiSelectExportEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCMultiSelectExportEnabledKey];
    BOOL contactsCountEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCContactsCountEnabledKey];
    BOOL pluginShortcutsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCPluginShortcutsEnabledKey];
    BOOL inputRoundingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCChatInputRoundingEnabledKey];
    BOOL globalTextReplaceEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCGlobalTextReplaceEnabledKey];
    NSString *globalReplaceSource = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCGlobalTextReplaceSourceKey] ?: @"";
    NSString *globalReplaceTarget = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCGlobalTextReplaceTargetKey] ?: @"";
    NSString *revokePromptStyle = revokePromptStyleValue == 1 ? @"气泡旁" : @"消息下方";
    NSString *sidePromptText = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCAntiRevokeSideTextKey] ?: @"已拦截撤回";
    id storedSideOffsetX = [[NSUserDefaults standardUserDefaults] objectForKey:NeoWCAntiRevokeSideOffsetXKey];
    id storedSideOffsetY = [[NSUserDefaults standardUserDefaults] objectForKey:NeoWCAntiRevokeSideOffsetYKey];
    NSString *sideOffsetX = [NSString stringWithFormat:@"%.0f", storedSideOffsetX ? [storedSideOffsetX doubleValue] : 0.0];
    NSString *sideOffsetY = [NSString stringWithFormat:@"%.0f", storedSideOffsetY ? [storedSideOffsetY doubleValue] : 10.0];

    NSMutableArray<NeoWCSettingItem *> *messageItems = [NSMutableArray array];
    [messageItems addObject:item(@"防撤回", @"保留好友撤回的消息并显示提示", @"arrow.uturn.backward.circle", NeoWCRowKindSwitch, NeoWCAntiRevokeKey, nil)];
    if (antiRevokeEnabled && [self isFeatureExpandedForKey:NeoWCAntiRevokeKey]) {
        [messageItems addObject:item(@"防撤回提示方案", [NSString stringWithFormat:@"当前方案：%@", revokePromptStyle], @"text.bubble.fill", NeoWCRowKindDetail, nil, revokePromptStyle)];
        if (revokePromptStyleValue == 1) {
            NSString *appearanceValue = [NSString stringWithFormat:@"%@ · X %@ / Y %@", sidePromptText, sideOffsetX, sideOffsetY];
            [messageItems addObject:item(@"提示外观预览", @"调整文字、颜色，并拖动或输入 X / Y", @"cursorarrow.motionlines", NeoWCRowKindDetail, nil, appearanceValue)];
        } else {
            [messageItems addObject:item(@"本地提示模板", @"编辑完整提示内容与文字颜色", @"text.bubble", NeoWCRowKindDetail, nil, @"编辑")];
        }
        [messageItems addObject:item(@"回复撤回者", @"自动发送提示，默认关闭", @"paperplane", NeoWCRowKindSwitch, NeoWCAntiRevokeNotifySenderKey, nil)];
        if (notifySenderEnabled && [self isFeatureExpandedForKey:NeoWCAntiRevokeNotifySenderKey]) {
            [messageItems addObject:item(@"回复时间限制", @"避免响应很久以前的撤回事件", @"timer", NeoWCRowKindDetail, nil, revokeFilterValue)];
            [messageItems addObject:item(@"回复消息模板", @"设置发送给撤回者的提示", @"text.quote", NeoWCRowKindDetail, nil, @"编辑")];
        }
        [messageItems addObject:item(@"防撤回记录中心", @"搜索本次运行期间拦截的撤回消息", @"tray.full", NeoWCRowKindDetail, nil, @"查看")];
        [messageItems addObject:item(@"本地保存撤回记录", @"默认关闭；仅保存摘要和分类", @"internaldrive", NeoWCRowKindSwitch, NeoWCAntiRevokePersistRecordsKey, nil)];
    }
    [messageItems addObject:item(@"小游戏结果选择", @"支持骰子与猜拳跨类型彩蛋", @"die.face.5", NeoWCRowKindSwitch, NeoWCGameSelectorKey, nil)];
    [messageItems addObject:item(@"聊天记录小丑", @"长按文字、应用或转账消息，本地修改当前页面显示", @"face.smiling", NeoWCRowKindSwitch, NeoWCChatJokerEnabledKey, nil)];
    [messageItems addObject:item(@"输入框滑动操作", @"左滑清空，右滑从剪贴板粘贴", @"hand.draw", NeoWCRowKindSwitch, NeoWCInputSwipeActionsEnabledKey, nil)];
    [messageItems addObject:item(@"图片编辑快捷发送", @"在官方图片编辑完成菜单中增加发送到当前会话", @"photo.badge.arrow.down", NeoWCRowKindSwitch, NeoWCImageEditQuickSendEnabledKey, nil)];
    [messageItems addObject:item(@"多选消息导出", @"控制多选菜单中的复制、保存和分享功能", @"square.and.arrow.up.on.square", NeoWCRowKindSwitch, NeoWCMultiSelectExportEnabledKey, nil)];
    if (multiSelectExportEnabled && [self isFeatureExpandedForKey:NeoWCMultiSelectExportEnabledKey]) {
        [messageItems addObject:item(@"复制纯文本", @"只复制消息正文到剪贴板", @"doc.on.clipboard", NeoWCRowKindSwitch, NeoWCMultiSelectExportTextKey, nil)];
        [messageItems addObject:item(@"批量保存图片", @"保存所选且已下载到本机的图片", @"photo.on.rectangle.angled", NeoWCRowKindSwitch, NeoWCMultiSelectSaveImagesKey, nil)];
        [messageItems addObject:item(@"生成分享卡片", @"可选择极简、对话或深色样式", @"rectangle.on.rectangle", NeoWCRowKindSwitch, NeoWCMultiSelectShareCardKey, nil)];
    }

    NSMutableArray<NeoWCSettingItem *> *enhancementItems = [NSMutableArray arrayWithArray:@[
        item(@"设备扫码自动登录", @"自动确认电脑、平板等设备登录", @"desktopcomputer", NeoWCRowKindSwitch, NeoWCAutoDeviceLoginKey, nil),
        item(@"游戏授权自动允许", @"自动点击游戏扫码授权页面的允许按钮", @"gamecontroller", NeoWCRowKindSwitch, NeoWCAutoGameAuthorizeKey, nil),
        item(@"朋友圈双击点赞", @"双击好友朋友圈内容直接点赞", @"hand.thumbsup", NeoWCRowKindSwitch, NeoWCMomentsDoubleTapLikeKey, nil),
        item(@"朋友圈操作按钮替换为评论", @"点击后直接进入评论，不再展开操作菜单", @"bubble.middle.bottom", NeoWCRowKindSwitch, NeoWCMomentsQuickCommentKey, nil),
        item(@"自定义微信运动步数", @"每天启动微信时自动使用设定步数", @"figure.walk", NeoWCRowKindSwitch, NeoWCStepOverrideEnabledKey, nil),
        item(@"钱包余额本地显示", @"开启后长按钱包入口或余额数字设置，仅修改本机文字", @"creditcard", NeoWCRowKindSwitch, NeoWCWalletBalanceEnabledKey, nil),
        item(@"好友数量本地显示", @"替换“个朋友”等好友数量文案", @"person.2", NeoWCRowKindSwitch, NeoWCContactsCountEnabledKey, nil),
    ]];
    if (momentsLikeEnabled && [self isFeatureExpandedForKey:NeoWCMomentsDoubleTapLikeKey]) {
        NSUInteger hapticIndex = MIN((NSUInteger)3, enhancementItems.count);
        [enhancementItems insertObject:item(@"点赞震动", @"双击点赞成功时提供触感反馈", @"waveform", NeoWCRowKindSwitch, NeoWCMomentsLikeHapticEnabledKey, nil) atIndex:hapticIndex];
        if (momentsHapticEnabled && [self isFeatureExpandedForKey:NeoWCMomentsLikeHapticEnabledKey]) {
            CGFloat intensity = [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCMomentsLikeHapticIntensityKey];
            NSString *intensityText = intensity < 0.34 ? @"轻" : (intensity < 0.75 ? @"中" : @"强");
            [enhancementItems insertObject:item(@"点赞震动力度", @"调整双击点赞时的震动反馈", @"slider.horizontal.3", NeoWCRowKindDetail, nil, intensityText) atIndex:MIN(hapticIndex + 1, enhancementItems.count)];
        }
    }
    if (stepOverrideEnabled && [self isFeatureExpandedForKey:NeoWCStepOverrideEnabledKey]) [enhancementItems addObject:item(@"设置运动步数", @"设定值会在每天首次启动或回到微信时刷新", @"number", NeoWCRowKindDetail, nil, stepValue)];
    if (contactsCountEnabled && [self isFeatureExpandedForKey:NeoWCContactsCountEnabledKey]) [enhancementItems addObject:item(@"设置好友数量", @"输入本机显示的好友数量", @"number", NeoWCRowKindDetail, nil, contactsValue)];
    [enhancementItems addObject:item(@"广告净化", @"隐藏朋友圈广告与小程序启动广告", @"rectangle.badge.xmark", NeoWCRowKindSwitch, NeoWCAdBlockerKey, nil)];

    NSMutableArray<NeoWCSettingItem *> *interfaceItems = [NSMutableArray arrayWithArray:@[
        item(@"聊天输入栏圆角", @"分别控制输入框内部与外部工具栏", @"rectangle.roundedtop", NeoWCRowKindSwitch, NeoWCChatInputRoundingEnabledKey, nil),
    ]];
    if (inputRoundingEnabled && [self isFeatureExpandedForKey:NeoWCChatInputRoundingEnabledKey]) {
        [interfaceItems addObject:item(@"输入框内部圆角", @"调整文字输入区域的圆角", @"text.cursor", NeoWCRowKindSwitch, NeoWCChatInputInnerRoundingKey, nil)];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:NeoWCChatInputInnerRoundingKey]) {
            CGFloat innerRadius = [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCChatInputInnerRadiusKey];
            [interfaceItems addObject:item(@"内部圆角程度", @"输入 0 到 40，数值越大越圆", @"slider.horizontal.3", NeoWCRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", innerRadius])];
        }
        [interfaceItems addObject:item(@"外部工具栏圆角", @"调整聊天底部工具栏的圆角", @"rectangle.bottomhalf.filled", NeoWCRowKindSwitch, NeoWCChatInputOuterRoundingKey, nil)];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:NeoWCChatInputOuterRoundingKey]) {
            CGFloat outerRadius = [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCChatInputOuterRadiusKey];
            [interfaceItems addObject:item(@"外部圆角程度", @"输入 0 到 40，数值越大越圆", @"slider.horizontal.3", NeoWCRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", outerRadius])];
        }
    }
    [interfaceItems addObject:item(@"隐藏免打扰图标", @"隐藏聊天标题旁的免打扰标记", @"bell.slash", NeoWCRowKindSwitch, NeoWCHideChatMuteIconKey, nil)];
    [interfaceItems addObject:item(@"全局文字替换", @"风险开关：替换所有 MMUILabel 命中的文字", @"textformat.alt", NeoWCRowKindSwitch, NeoWCGlobalTextReplaceEnabledKey, nil)];
    if (globalTextReplaceEnabled && [self isFeatureExpandedForKey:NeoWCGlobalTextReplaceEnabledKey]) {
        [interfaceItems addObject:item(@"替换原文字", @"完全匹配后替换；留空则不生效", @"text.magnifyingglass", NeoWCRowKindDetail, nil, globalReplaceSource.length > 0 ? globalReplaceSource : @"输入")];
        [interfaceItems addObject:item(@"替换为文字", @"替换后的显示文字", @"text.append", NeoWCRowKindDetail, nil, globalReplaceTarget.length > 0 ? globalReplaceTarget : @"输入")];
    }
    [interfaceItems addObject:item(@"插件显示管理", @"隐藏其他插件入口并检测加载状态", @"square.stack.3d.up", NeoWCRowKindDetail, nil, @"管理")];

    self.sections = @[
        [NeoWCSettingSection sectionWithIdentifier:@"general" title:@"总开关" subtitle:nil symbol:@"switch.2" footer:@"关闭后仅保留设置入口，所有增强功能停止生效。" collapsible:NO items:@[
            item(@"启用 NeoWC", @"插件功能总开关", @"power", NeoWCRowKindSwitch, NeoWCEnabledKey, nil),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"messages" title:@"聊天增强" subtitle:@"消息、编辑与多选工具" symbol:@"bubble.left.and.bubble.right" footer:@"" collapsible:YES items:messageItems],
        [NeoWCSettingSection sectionWithIdentifier:@"enhancements" title:@"常用增强" subtitle:@"快捷操作与自动授权" symbol:@"bolt" footer:@"自动登录和授权会跳过手动确认，请只在可信设备和可信游戏中开启。" collapsible:YES items:enhancementItems],
        [NeoWCSettingSection sectionWithIdentifier:@"interface" title:@"界面优化" subtitle:@"聊天页面与插件入口外观" symbol:@"paintbrush" footer:@"界面调整只作用于聊天页面，关闭后恢复微信原始样式。" collapsible:YES items:interfaceItems],
        [NeoWCSettingSection sectionWithIdentifier:@"developer" title:@"开发者功能" subtitle:@"界面检查与运行诊断" symbol:@"hammer" footer:@"快捷入口启用后会立即尝试注册；关闭或移除入口后，重启微信即可从插件管理页面彻底消失。" collapsible:YES items:({
            NSMutableArray<NeoWCSettingItem *> *items = [NSMutableArray arrayWithArray:@[
                item(@"调试悬浮按钮", @"仅由此开关控制，不监听全局手势", @"wrench.and.screwdriver", NeoWCRowKindSwitch, NeoWCDebugFloatingEnabledKey, nil),
                item(@"记录调试日志", @"记录 NeoWC 运行事件，关闭后停止新增", @"text.alignleft", NeoWCRowKindSwitch, NeoWCDebugLoggingEnabledKey, nil),
                item(@"调试中心", @"视图检查、Runtime 搜索与日志", @"ladybug", NeoWCRowKindDetail, nil, @"打开"),
                item(@"功能兼容性", @"检查类、Selector 与本次运行触发状态", @"checklist", NeoWCRowKindDetail, nil, @"检查"),
                item(@"插件管理快捷入口", @"把常用开关或页面注册到插件管理页", @"bolt.badge.clock", NeoWCRowKindSwitch, NeoWCPluginShortcutsEnabledKey, nil),
            ]];
            if (pluginShortcutsEnabled && [self isFeatureExpandedForKey:NeoWCPluginShortcutsEnabledKey]) {
                [items addObject:item(@"快捷日志开关", @"在插件管理页直接开关 NeoWC 日志", @"text.alignleft", NeoWCRowKindSwitch, NeoWCPluginShortcutLoggingKey, nil)];
                [items addObject:item(@"快捷悬浮窗开关", @"在插件管理页直接开关调试悬浮窗", @"wrench.and.screwdriver", NeoWCRowKindSwitch, NeoWCPluginShortcutFloatingDebugKey, nil)];
                [items addObject:item(@"直达调试中心", @"在插件管理页增加独立页面入口", @"ladybug", NeoWCRowKindSwitch, NeoWCPluginShortcutDebugCenterKey, nil)];
                [items addObject:item(@"直达防撤回记录", @"在插件管理页增加撤回记录入口", @"tray.full", NeoWCRowKindSwitch, NeoWCPluginShortcutRevokeRecordsKey, nil)];
                [items addObject:item(@"自定义页面入口", @"输入 Controller 或 View 类名快速跳转", @"rectangle.and.hand.point.up.left", NeoWCRowKindSwitch, NeoWCPluginShortcutCustomPageKey, nil)];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:NeoWCPluginShortcutCustomPageKey] &&
                    [self isFeatureExpandedForKey:NeoWCPluginShortcutCustomPageKey]) {
                    NSString *customTitle = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCPluginShortcutCustomTitleKey] ?: @"快捷页面";
                    NSString *customClass = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCPluginShortcutCustomClassKey] ?: @"";
                    [items addObject:item(@"自定义入口名称", @"显示在插件管理页面中的名称", @"textformat", NeoWCRowKindDetail, nil, customTitle)];
                    [items addObject:item(@"页面 Runtime 类名", @"支持 UIViewController 或 UIView 子类", @"chevron.left.forwardslash.chevron.right", NeoWCRowKindDetail, nil, customClass.length > 0 ? customClass : @"输入")];
                }
            }
            items;
        })],
        [NeoWCSettingSection sectionWithIdentifier:@"about" title:@"关于" subtitle:nil symbol:@"info.circle" footer:@"NeoWC · Designed for WeChat" collapsible:NO items:@[
            item(@"版本", @"NeoWC", @"shippingbox", NeoWCRowKindInfo, nil, NeoWCVersion),
        ]],
    ];
}

- (UIView *)makeHeaderView {
    CGFloat width = MAX(CGRectGetWidth(self.view.bounds), CGRectGetWidth([UIScreen mainScreen].bounds));
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 132.0)];
    container.backgroundColor = [UIColor systemBackgroundColor];

    NeoWCLogoView *logo = [NeoWCLogoView new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.layer.shadowOpacity = 0.0;
    [container addSubview:logo];

    UILabel *name = [UILabel new];
    name.translatesAutoresizingMaskIntoConstraints = NO;
    name.text = @"NeoWC";
    name.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    name.adjustsFontForContentSizeCategory = YES;
    [container addSubview:name];

    UILabel *version = [UILabel new];
    version.translatesAutoresizingMaskIntoConstraints = NO;
    version.text = [NSString stringWithFormat:@"v%@ · DEVELOPMENT", NeoWCVersion];
    version.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    version.adjustsFontForContentSizeCategory = YES;
    version.textColor = [UIColor secondaryLabelColor];
    [container addSubview:version];

    UILabel *tagline = [UILabel new];
    tagline.translatesAutoresizingMaskIntoConstraints = NO;
    tagline.text = @"轻量、清晰、原生的微信增强体验";
    tagline.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    tagline.adjustsFontForContentSizeCategory = YES;
    tagline.textColor = [UIColor secondaryLabelColor];
    [container addSubview:tagline];

    [NSLayoutConstraint activateConstraints:@[
        [logo.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:24.0],
        [logo.topAnchor constraintEqualToAnchor:container.topAnchor constant:12.0],
        [logo.widthAnchor constraintEqualToConstant:62.0],
        [logo.heightAnchor constraintEqualToConstant:62.0],
        [name.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:12.0],
        [name.trailingAnchor constraintLessThanOrEqualToAnchor:container.trailingAnchor constant:-24.0],
        [name.topAnchor constraintEqualToAnchor:logo.topAnchor constant:3.0],
        [version.leadingAnchor constraintEqualToAnchor:name.leadingAnchor],
        [version.topAnchor constraintEqualToAnchor:name.bottomAnchor constant:4.0],
        [tagline.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:24.0],
        [tagline.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-24.0],
        [tagline.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-18.0],
    ]];
    return container;
}

- (BOOL)isSectionExpanded:(NeoWCSettingSection *)section {
    return !section.isCollapsible || [self.expandedCategoryIDs containsObject:section.identifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    NeoWCSettingSection *section = self.sections[sectionIndex];
    return [self isSectionExpanded:section] ? section.items.count : 0;
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForHeaderInSection:(__unused NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NeoWCSettingSection *model = self.sections[section];
    return model.subtitle.length > 0 ? 62.0 : 46.0;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex {
    NeoWCSettingSection *section = self.sections[sectionIndex];
    UIControl *header = [UIControl new];
    header.tag = sectionIndex;
    header.backgroundColor = UIColor.clearColor;
    if (section.isCollapsible) [header addTarget:self action:@selector(sectionHeaderTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *icon = [[UIImageView alloc] initWithImage:section.symbol.length > 0 ? NeoWCSymbol(section.symbol) : nil];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = [UIColor secondaryLabelColor];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [header addSubview:icon];

    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = section.title;
    title.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    title.textColor = [UIColor labelColor];
    [header addSubview:title];

    UILabel *subtitle = [UILabel new];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.text = section.subtitle;
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    subtitle.textColor = [UIColor tertiaryLabelColor];
    subtitle.hidden = section.subtitle.length == 0;
    [header addSubview:subtitle];

    UIImageView *chevron = [[UIImageView alloc] initWithImage:section.isCollapsible ? [UIImage systemImageNamed:@"chevron.down"] : nil];
    chevron.translatesAutoresizingMaskIntoConstraints = NO;
    chevron.tintColor = [UIColor tertiaryLabelColor];
    chevron.contentMode = UIViewContentModeScaleAspectFit;
    chevron.tag = 7401;
    chevron.transform = [self isSectionExpanded:section] ? CGAffineTransformIdentity : CGAffineTransformMakeRotation((CGFloat)-M_PI_2);
    [header addSubview:chevron];

    CGFloat titleLeading = section.symbol.length > 0 ? 46.0 : 18.0;
    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:18.0],
        [icon.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:18.0],
        [icon.heightAnchor constraintEqualToConstant:18.0],
        [title.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:titleLeading],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:chevron.leadingAnchor constant:-10.0],
        [title.topAnchor constraintEqualToAnchor:header.topAnchor constant:section.subtitle.length > 0 ? 12.0 : 17.0],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [subtitle.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor constant:-36.0],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2.0],
        [chevron.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20.0],
        [chevron.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [chevron.widthAnchor constraintEqualToConstant:12.0],
        [chevron.heightAnchor constraintEqualToConstant:16.0],
    ]];
    header.isAccessibilityElement = YES;
    header.accessibilityLabel = section.subtitle.length > 0 ? [NSString stringWithFormat:@"%@，%@", section.title, section.subtitle] : section.title;
    if (section.isCollapsible) header.accessibilityHint = [self isSectionExpanded:section] ? @"轻点折叠" : @"轻点展开";
    return header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NeoWCSettingSection *model = self.sections[section];
    if (model.isCollapsible && ![self isSectionExpanded:model]) return nil;
    return model.footer.length > 0 ? model.footer : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    NSString *footer = [self tableView:tableView titleForFooterInSection:section];
    return footer.length > 0 ? UITableViewAutomaticDimension : 10.0;
}

- (NeoWCSettingItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCSettingSection *section = self.sections[indexPath.section];
    NSInteger itemIndex = indexPath.row;
    if (itemIndex < 0 || itemIndex >= section.items.count) return nil;
    return section.items[itemIndex];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCSettingSection *section = self.sections[indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NeoWCSettingCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.layer.shadowOpacity = 0.0;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    NSInteger visibleRows = [tableView numberOfRowsInSection:indexPath.section];
    BOOL firstRow = indexPath.row == 0;
    BOOL lastRow = indexPath.row == visibleRows - 1;
    if (section.isCollapsible) {
        NeoWCCardBackgroundView *background = [NeoWCCardBackgroundView new];
        background.roundsTop = firstRow;
        background.roundsBottom = lastRow;
        background.drawsDivider = NO;
        cell.backgroundView = background;
        NeoWCCardBackgroundView *selectedBackground = [NeoWCCardBackgroundView new];
        selectedBackground.roundsTop = firstRow;
        selectedBackground.roundsBottom = lastRow;
        selectedBackground.drawsDivider = NO;
        selectedBackground.fillColor = [UIColor tertiarySystemFillColor];
        cell.selectedBackgroundView = selectedBackground;
    } else {
        UIView *plainBackground = [UIView new];
        plainBackground.backgroundColor = UIColor.clearColor;
        cell.backgroundView = plainBackground;
        UIView *plainSelectedBackground = [UIView new];
        plainSelectedBackground.backgroundColor = [UIColor tertiarySystemFillColor];
        cell.selectedBackgroundView = plainSelectedBackground;
    }
    cell.layoutMargins = UIEdgeInsetsMake(0.0, 22.0, 0.0, 22.0);

    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = item.title;
    content.secondaryText = item.subtitle;
    content.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    content.secondaryTextProperties.color = [UIColor secondaryLabelColor];
    content.image = NeoWCSymbol(item.symbol);
    content.imageProperties.tintColor = [UIColor secondaryLabelColor];
    content.imageProperties.maximumSize = CGSizeMake(20.0, 20.0);
    content.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0.0, 22.0, 0.0, 22.0);
    cell.contentConfiguration = content;

    if (item.kind == NeoWCRowKindSwitch) {
        UISwitch *toggle = [UISwitch new];
        toggle.onTintColor = [UIColor systemBlueColor];
        toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:item.defaultsKey];
        toggle.accessibilityLabel = item.title;
        toggle.tag = indexPath.section * 1000 + indexPath.row;
        [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        BOOL masterEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCEnabledKey];
        toggle.enabled = [item.defaultsKey isEqualToString:NeoWCEnabledKey] || masterEnabled;
        if ([self featureHasChildrenForKey:item.defaultsKey]) {
            UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down"]];
            chevron.tintColor = [UIColor tertiaryLabelColor];
            chevron.contentMode = UIViewContentModeScaleAspectFit;
            chevron.hidden = NO;
            chevron.alpha = toggle.isOn ? 1.0 : 0.0;
            chevron.transform = [self isFeatureExpandedForKey:item.defaultsKey] ? CGAffineTransformIdentity : CGAffineTransformMakeRotation((CGFloat)-M_PI_2);
            [chevron.widthAnchor constraintEqualToConstant:11.0].active = YES;
            [chevron.heightAnchor constraintEqualToConstant:15.0].active = YES;
            UIStackView *accessory = [[UIStackView alloc] initWithArrangedSubviews:@[chevron, toggle]];
            accessory.axis = UILayoutConstraintAxisHorizontal;
            accessory.alignment = UIStackViewAlignmentCenter;
            accessory.spacing = 10.0;
            accessory.frame = CGRectMake(0.0, 0.0, 72.0, 32.0);
            cell.accessoryView = accessory;
            cell.selectionStyle = toggle.isOn ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.accessibilityHint = toggle.isOn ? ([self isFeatureExpandedForKey:item.defaultsKey] ? @"轻点卡片收起子选项" : @"轻点卡片展开子选项") : nil;
        } else {
            cell.accessoryView = toggle;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    } else if (item.kind == NeoWCRowKindDetail) {
        UILabel *valueLabel = [UILabel new];
        valueLabel.text = item.value ?: @"";
        valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        valueLabel.textColor = [UIColor tertiaryLabelColor];
        UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        chevron.tintColor = [UIColor quaternaryLabelColor];
        chevron.contentMode = UIViewContentModeScaleAspectFit;
        [chevron.widthAnchor constraintEqualToConstant:8.0].active = YES;
        UIStackView *accessory = [[UIStackView alloc] initWithArrangedSubviews:@[valueLabel, chevron]];
        accessory.axis = UILayoutConstraintAxisHorizontal;
        accessory.alignment = UIStackViewAlignmentCenter;
        accessory.spacing = 7.0;
        cell.accessoryView = accessory;
    } else if (item.value.length > 0) {
        UILabel *valueLabel = [UILabel new];
        valueLabel.text = item.value;
        valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        valueLabel.textColor = [UIColor secondaryLabelColor];
        cell.accessoryView = valueLabel;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void)switchChanged:(UISwitch *)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag % 1000 inSection:sender.tag / 1000];
    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    if (item.defaultsKey.length == 0) return;
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:item.defaultsKey];
    if (sender.isOn && [self featureHasChildrenForKey:item.defaultsKey]) {
        [self.collapsedFeatureKeys removeObject:item.defaultsKey];
        [self saveCollapsedFeatureKeys];
    }
    if ([item.defaultsKey isEqualToString:NeoWCStepOverrideEnabledKey] && sender.isOn && [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCStepCountKey] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NeoWCStepCountDateKey];
    }
    if ([item.defaultsKey isEqualToString:NeoWCAntiRevokePersistRecordsKey]) NeoWCAntiRevokeSetPersistenceEnabled(sender.isOn);
    if ([item.defaultsKey isEqualToString:NeoWCEnabledKey] ||
        [item.defaultsKey isEqualToString:NeoWCMomentsDoubleTapLikeKey] ||
        [item.defaultsKey isEqualToString:NeoWCMomentsQuickCommentKey]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCEnhancementDidChangeNotification object:item.defaultsKey];
    }
    if ([item.defaultsKey isEqualToString:NeoWCDebugFloatingEnabledKey]) {
        [[NeoWCDebugManager sharedManager] setFloatingEnabled:sender.isOn];
    }
    if ([item.defaultsKey hasPrefix:@"com.qiu7c.neowc.plugin-shortcuts."]) {
        NeoWCRegisterPluginShortcutsIfAvailable();
    }
    if ([item.defaultsKey isEqualToString:NeoWCAntiRevokeKey]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    }
    BOOL changesVisibleRows = [item.defaultsKey isEqualToString:NeoWCAntiRevokeKey] ||
                              [item.defaultsKey isEqualToString:NeoWCAntiRevokeNotifySenderKey] ||
                              [item.defaultsKey isEqualToString:NeoWCStepOverrideEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCContactsCountEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMomentsDoubleTapLikeKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMomentsLikeHapticEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMultiSelectExportEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCPluginShortcutsEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCPluginShortcutCustomPageKey] ||
                              [item.defaultsKey isEqualToString:NeoWCChatInputRoundingEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCChatInputInnerRoundingKey] ||
                              [item.defaultsKey isEqualToString:NeoWCChatInputOuterRoundingKey] ||
                              [item.defaultsKey isEqualToString:NeoWCGlobalTextReplaceEnabledKey];
    if (changesVisibleRows) [self buildSections];
    if ([item.defaultsKey isEqualToString:NeoWCEnabledKey] || changesVisibleRows) [self.tableView reloadData];
}

- (void)toggleFeatureAtIndexPath:(NSIndexPath *)indexPath item:(NeoWCSettingItem *)item {
    if (![self featureHasChildrenForKey:item.defaultsKey] ||
        ![[NSUserDefaults standardUserDefaults] boolForKey:item.defaultsKey]) return;
    if ([self.collapsedFeatureKeys containsObject:item.defaultsKey]) {
        [self.collapsedFeatureKeys removeObject:item.defaultsKey];
    } else {
        [self.collapsedFeatureKeys addObject:item.defaultsKey];
    }
    [self saveCollapsedFeatureKeys];
    [self buildSections];
    CGPoint offset = self.tableView.contentOffset;
    [UIView performWithoutAnimation:^{
        [self.tableView reloadData];
        [self.tableView setContentOffset:offset animated:NO];
    }];
}

- (void)toggleSection:(NSInteger)sectionIndex {
    NeoWCSettingSection *section = self.sections[sectionIndex];
    if (!section.isCollapsible) return;
    BOOL wasExpanded = [self.expandedCategoryIDs containsObject:section.identifier];
    if (wasExpanded) {
        [self.expandedCategoryIDs removeObject:section.identifier];
    } else {
        [self.expandedCategoryIDs addObject:section.identifier];
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.expandedCategoryIDs.allObjects forKey:NeoWCExpandedCategoriesKey];
    CGPoint offset = self.tableView.contentOffset;
    [UIView performWithoutAnimation:^{
        [self.tableView reloadData];
        [self.tableView setContentOffset:offset animated:NO];
    }];
}

- (void)sectionHeaderTapped:(UIControl *)sender {
    [self toggleSection:sender.tag];
}

- (void)presentRevokeFilterPicker {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"回复时间限制"
                                                                   message:@"仅影响“回复撤回者”，不会影响本地防撤回"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSDictionary *> *options = @[
        @{@"title": @"不限制", @"value": @0},
        @{@"title": @"1 分钟", @"value": @60},
        @{@"title": @"5 分钟", @"value": @300},
        @{@"title": @"30 分钟", @"value": @1800},
        @{@"title": @"1 小时", @"value": @3600},
        @{@"title": @"24 小时", @"value": @86400},
    ];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        [sheet addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [[NSUserDefaults standardUserDefaults] setDouble:[option[@"value"] doubleValue] forKey:NeoWCAntiRevokeTimeFilterKey];
            [weakSelf buildSections];
            [weakSelf.tableView reloadData];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - 1.0, 1.0, 1.0);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentTemplateEditorWithTitle:(NSString *)title key:(NSString *)key defaultValue:(NSString *)defaultValue {
    NSString *colorKey = [key isEqualToString:NeoWCAntiRevokeLocalTemplateKey] ? NeoWCAntiRevokeLocalTextColorKey : nil;
    NeoWCAntiRevokeTemplateEditorViewController *editor = [[NeoWCAntiRevokeTemplateEditorViewController alloc]
        initWithTitle:title defaultsKey:key defaultValue:defaultValue colorKey:colorKey];
    [self.navigationController pushViewController:editor animated:YES];
}

- (void)presentRevokePromptStylePicker {
    NSInteger currentStyle = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCAntiRevokePromptStyleKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"防撤回提示方案"
                                                                   message:@"“消息下方”显示完整提示；“气泡旁”显示与气泡持平的小字"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSDictionary *> *options = @[
        @{ @"title": currentStyle == 0 ? @"✓  消息下方" : @"消息下方", @"value": @0 },
        @{ @"title": currentStyle == 1 ? @"✓  气泡旁" : @"气泡旁", @"value": @1 },
    ];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        [sheet addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [[NSUserDefaults standardUserDefaults] setInteger:[option[@"value"] integerValue] forKey:NeoWCAntiRevokePromptStyleKey];
            [weakSelf buildSections];
            [weakSelf.tableView reloadData];
            [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - 1.0, 1.0, 1.0);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentSidePromptTextEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"气泡旁提示文字" message:@"建议使用简短文字，避免覆盖消息气泡" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCAntiRevokeSideTextKey] ?: @"已拦截撤回";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (text.length == 0) text = @"已拦截撤回";
        [[NSUserDefaults standardUserDefaults] setObject:text forKey:NeoWCAntiRevokeSideTextKey];
        [weakSelf buildSections];
        [weakSelf.tableView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentSidePromptOffsetEditorForKey:(NSString *)key title:(NSString *)title defaultValue:(CGFloat)defaultValue {
    id storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    CGFloat value = storedValue ? [storedValue doubleValue] : defaultValue;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:@"请输入 -80 到 80 之间的数值" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [NSString stringWithFormat:@"%.0f", value];
        textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        CGFloat newValue = MIN(80.0, MAX(-80.0, alert.textFields.firstObject.text.doubleValue));
        [[NSUserDefaults standardUserDefaults] setDouble:newValue forKey:key];
        [weakSelf buildSections];
        [weakSelf.tableView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentPluginShortcutTextEditorForKey:(NSString *)key
                                        title:(NSString *)title
                                  placeholder:(NSString *)placeholder {
    BOOL editingClass = [key isEqualToString:NeoWCPluginShortcutCustomClassKey];
    NSString *message = editingClass
        ? @"输入 Objective-C Runtime 类名；支持 UIViewController 或 UIView 子类。修改已注册的类名后建议重启微信。"
        : @"此名称会显示在插件管理页面中。";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        textField.placeholder = placeholder;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *value = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (!editingClass && value.length == 0) value = @"快捷页面";
        [[NSUserDefaults standardUserDefaults] setObject:value ?: @"" forKey:key];
        [weakSelf buildSections];
        [weakSelf.tableView reloadData];
        NeoWCRegisterPluginShortcutsIfAvailable();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentCornerRadiusEditorForKey:(NSString *)key title:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:@"请输入 0 到 40 之间的数值；0 表示直角"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [NSString stringWithFormat:@"%.0f", [[NSUserDefaults standardUserDefaults] doubleForKey:key]];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        CGFloat radius = MIN(40.0, MAX(0.0, alert.textFields.firstObject.text.doubleValue));
        [[NSUserDefaults standardUserDefaults] setDouble:radius forKey:key];
        [weakSelf buildSections];
        [weakSelf.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentGlobalTextReplaceEditorForKey:(NSString *)key title:(NSString *)title placeholder:(NSString *)placeholder {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:@"这是风险功能，会影响所有匹配的微信标签文字"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        textField.placeholder = placeholder;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *value = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
        [weakSelf buildSections];
        [weakSelf.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    if (item.kind == NeoWCRowKindSwitch && [self featureHasChildrenForKey:item.defaultsKey]) {
        [self toggleFeatureAtIndexPath:indexPath item:item];
        return;
    }
    if (item.kind != NeoWCRowKindDetail) return;
    if ([item.title isEqualToString:@"防撤回提示方案"]) {
        [self presentRevokePromptStylePicker];
        return;
    }
    if ([item.title isEqualToString:@"提示外观预览"]) {
        [self.navigationController pushViewController:[NeoWCAntiRevokeAppearanceViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"防撤回记录中心"]) {
        [self.navigationController pushViewController:[NeoWCAntiRevokeRecordsViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"气泡旁提示文字"]) {
        [self presentSidePromptTextEditor];
        return;
    }
    if ([item.title isEqualToString:@"气泡旁横向位置"]) {
        [self presentSidePromptOffsetEditorForKey:NeoWCAntiRevokeSideOffsetXKey title:item.title defaultValue:0.0];
        return;
    }
    if ([item.title isEqualToString:@"气泡旁纵向位置"]) {
        [self presentSidePromptOffsetEditorForKey:NeoWCAntiRevokeSideOffsetYKey title:item.title defaultValue:10.0];
        return;
    }
    if ([item.title isEqualToString:@"回复时间限制"]) {
        [self presentRevokeFilterPicker];
        return;
    }
    if ([item.title isEqualToString:@"本地提示模板"]) {
        [self presentTemplateEditorWithTitle:item.title
                                         key:NeoWCAntiRevokeLocalTemplateKey
                                defaultValue:@"拦截到一条{用户名}撤回的消息\n发送时间：{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}\n内容：{内容}"];
        return;
    }
    if ([item.title isEqualToString:@"回复消息模板"]) {
        [self presentTemplateEditorWithTitle:item.title
                                         key:NeoWCAntiRevokeReplyTemplateKey
                                defaultValue:@"【捕捉到一条撤回消息】\n操作用户：{用户名}\n发送时间：{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}\n撤回内容：{内容}\n\n撤回无效，消息已保存"];
        return;
    }
    if ([item.title isEqualToString:@"调试中心"]) {
        [[NeoWCDebugManager sharedManager] presentDashboardFromViewController:self];
        return;
    }
    if ([item.title isEqualToString:@"功能兼容性"]) {
        [self.navigationController pushViewController:[NeoWCCompatibilityViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"自定义入口名称"]) {
        [self presentPluginShortcutTextEditorForKey:NeoWCPluginShortcutCustomTitleKey title:item.title placeholder:@"快捷页面"];
        return;
    }
    if ([item.title isEqualToString:@"页面 Runtime 类名"]) {
        [self presentPluginShortcutTextEditorForKey:NeoWCPluginShortcutCustomClassKey title:item.title placeholder:@"例如 NewSettingViewController"];
        return;
    }
    if ([item.title isEqualToString:@"内部圆角程度"]) {
        [self presentCornerRadiusEditorForKey:NeoWCChatInputInnerRadiusKey title:item.title];
        return;
    }
    if ([item.title isEqualToString:@"外部圆角程度"]) {
        [self presentCornerRadiusEditorForKey:NeoWCChatInputOuterRadiusKey title:item.title];
        return;
    }
    if ([item.title isEqualToString:@"替换原文字"]) {
        [self presentGlobalTextReplaceEditorForKey:NeoWCGlobalTextReplaceSourceKey title:item.title placeholder:@"例如 微信"];
        return;
    }
    if ([item.title isEqualToString:@"替换为文字"]) {
        [self presentGlobalTextReplaceEditorForKey:NeoWCGlobalTextReplaceTargetKey title:item.title placeholder:@"例如 NeoWC"];
        return;
    }
    if ([item.title isEqualToString:@"插件显示管理"]) {
        [self.navigationController pushViewController:[NeoWCPluginVisibilityViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"点赞震动力度"]) {
        UIAlertController *picker = [UIAlertController alertControllerWithTitle:@"点赞震动力度" message:@"选择双击点赞时的触感强度" preferredStyle:UIAlertControllerStyleActionSheet];
        NSArray<NSDictionary *> *options = @[
            @{ @"title": @"轻", @"value": @0.25 },
            @{ @"title": @"中", @"value": @0.65 },
            @{ @"title": @"强", @"value": @1.0 },
        ];
        __weak typeof(self) weakSelf = self;
        for (NSDictionary *option in options) {
            [picker addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
                [[NSUserDefaults standardUserDefaults] setDouble:[option[@"value"] doubleValue] forKey:NeoWCMomentsLikeHapticIntensityKey];
                [weakSelf buildSections];
                [weakSelf.tableView reloadData];
            }]];
        }
        [picker addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        UIPopoverPresentationController *popover = picker.popoverPresentationController;
        if (popover) { popover.sourceView = self.view; popover.sourceRect = self.view.bounds; }
        [self presentViewController:picker animated:YES completion:nil];
        return;
    }
    if ([item.title isEqualToString:@"设置运动步数"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置每日微信运动步数" message:@"请输入 1–100000 之间的数值；每天自动沿用" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCStepCountKey];
            textField.text = value > 0 ? [NSString stringWithFormat:@"%ld", (long)value] : nil;
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = @"步数";
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSInteger value = [alert.textFields.firstObject.text integerValue];
            value = MIN(100000, MAX(1, value));
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setInteger:value forKey:NeoWCStepCountKey];
            [defaults setObject:[NSDate date] forKey:NeoWCStepCountDateKey];
            [defaults setBool:YES forKey:NeoWCStepOverrideEnabledKey];
            [weakSelf buildSections];
            [weakSelf.tableView reloadData];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if ([item.title isEqualToString:@"设置钱包余额"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置钱包余额"
                                                                       message:@"仅修改本机界面显示；留空或输入 0 可恢复真实显示"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            long long fen = NeoWCSettingsLongLongDefaultForKey(NeoWCWalletBalanceFenKey);
            textField.text = fen > 0 ? [NSString stringWithFormat:@"%.2f", fen / 100.0] : nil;
            textField.keyboardType = UIKeyboardTypeDecimalPad;
            textField.placeholder = @"例如 888.88";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSString *text = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            double value = text.length > 0 ? text.doubleValue : 0.0;
            long long fen = value > 0.0 ? (long long)llround(value * 100.0) : 0;
            [[NSUserDefaults standardUserDefaults] setObject:@(MAX(0LL, fen)) forKey:NeoWCWalletBalanceFenKey];
            [[NSUserDefaults standardUserDefaults] setBool:fen > 0 forKey:NeoWCWalletBalanceEnabledKey];
            [weakSelf buildSections];
            [weakSelf.tableView reloadData];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if ([item.title isEqualToString:@"设置好友数量"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置好友数量"
                                                                       message:@"仅替换本机界面中的好友数量文案"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCContactsCountKey];
            textField.text = value > 0 ? [NSString stringWithFormat:@"%ld", (long)value] : nil;
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = @"好友数量";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSInteger value = MAX(0, [alert.textFields.firstObject.text integerValue]);
            [[NSUserDefaults standardUserDefaults] setInteger:value forKey:NeoWCContactsCountKey];
            [[NSUserDefaults standardUserDefaults] setBool:value > 0 forKey:NeoWCContactsCountEnabledKey];
            [weakSelf buildSections];
            [weakSelf.tableView reloadData];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
}

@end
