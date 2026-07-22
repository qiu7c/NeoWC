#import "NeoWCSettingsViewController.h"
#import "NeoWCAntiRevoke.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import "NeoWCChatCapture.h"
#import "NeoWCCompatibility.h"
#import "NeoWCPluginVisibility.h"

static NSString *const NeoWCVersion = @"0.1.1";
static NSString *const NeoWCEnabledKey = @"com.qiu7c.neowc.enabled";
static NSString *const NeoWCExpandedCategoriesKey = @"com.qiu7c.neowc.ui.expanded-categories";

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
        NeoWCChatCaptureEnabledKey: @NO,
        NeoWCImageEditQuickSendEnabledKey: @NO,
        NeoWCImageEditReturnToChatKey: @YES,
        NeoWCMomentsLikeHapticEnabledKey: @NO,
        NeoWCMomentsLikeHapticIntensityKey: @0.65,
        NeoWCMultiSelectExportEnabledKey: @NO,
        NeoWCMultiSelectExportTextKey: @YES,
        NeoWCMultiSelectSaveImagesKey: @YES,
        NeoWCMultiSelectShareCardKey: @YES,
        NeoWCChatCapturePresetKey: @0,
        NeoWCChatCaptureIncludeStatusBarKey: @NO,
        NeoWCChatCaptureAutoSplitKey: @YES,
        NeoWCChatCaptureIncludeChromeKey: @YES,
        NeoWCChatCaptureHideMemberNamesKey: @NO,
        NeoWCChatCaptureShowBackgroundKey: @YES,
        NeoWCChatCaptureCloseAfterShareKey: @NO,
        NeoWCChatCaptureCropTopPointsKey: @0.0,
        NeoWCChatCaptureShowChatNameKey: @NO,
        NeoWCChatCaptureShowTimestampKey: @NO,
        NeoWCChatCaptureWatermarkStyleKey: @0,
        NeoWCChatCaptureWatermarkOpacityKey: @0.18,
        NeoWCDebugLoggingEnabledKey: @YES,
        NeoWCExpandedCategoriesKey: @[@"messages"],
    }];
    NSArray *savedCategories = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCExpandedCategoriesKey];
    self.expandedCategoryIDs = [NSMutableSet setWithArray:savedCategories ?: @[]];
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

- (void)buildSections {
    NeoWCSettingItem *(^item)(NSString *, NSString *, NSString *, NeoWCRowKind, NSString *, NSString *) =
    ^NeoWCSettingItem *(NSString *title, NSString *subtitle, NSString *symbol, NeoWCRowKind kind, NSString *key, NSString *value) {
        return [NeoWCSettingItem itemWithTitle:title subtitle:subtitle symbol:symbol kind:kind key:key value:value];
    };
    NSInteger configuredStepCount = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCStepCountKey];
    NSString *stepValue = configuredStepCount > 0 ? [NSString stringWithFormat:@"%ld 步", (long)configuredStepCount] : @"设置";
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
    BOOL chatCaptureEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCChatCaptureEnabledKey];
    BOOL imageEditQuickSendEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCImageEditQuickSendEnabledKey];
    BOOL momentsLikeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCMomentsDoubleTapLikeKey];
    BOOL momentsHapticEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCMomentsLikeHapticEnabledKey];
    BOOL multiSelectExportEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCMultiSelectExportEnabledKey];
    NSString *revokePromptStyle = revokePromptStyleValue == 1 ? @"气泡旁" : @"消息下方";
    NSString *sidePromptText = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCAntiRevokeSideTextKey] ?: @"已拦截撤回";
    id storedSideOffsetX = [[NSUserDefaults standardUserDefaults] objectForKey:NeoWCAntiRevokeSideOffsetXKey];
    id storedSideOffsetY = [[NSUserDefaults standardUserDefaults] objectForKey:NeoWCAntiRevokeSideOffsetYKey];
    NSString *sideOffsetX = [NSString stringWithFormat:@"%.0f", storedSideOffsetX ? [storedSideOffsetX doubleValue] : 0.0];
    NSString *sideOffsetY = [NSString stringWithFormat:@"%.0f", storedSideOffsetY ? [storedSideOffsetY doubleValue] : 10.0];

    NSMutableArray<NeoWCSettingItem *> *messageItems = [NSMutableArray array];
    [messageItems addObject:item(@"防撤回", @"保留好友撤回的消息并显示提示", @"arrow.uturn.backward.circle", NeoWCRowKindSwitch, NeoWCAntiRevokeKey, nil)];
    if (antiRevokeEnabled) {
        [messageItems addObject:item(@"防撤回提示方案", [NSString stringWithFormat:@"当前方案：%@", revokePromptStyle], @"text.bubble.fill", NeoWCRowKindDetail, nil, revokePromptStyle)];
        if (revokePromptStyleValue == 1) {
            NSString *appearanceValue = [NSString stringWithFormat:@"%@ · X %@ / Y %@", sidePromptText, sideOffsetX, sideOffsetY];
            [messageItems addObject:item(@"提示外观预览", @"拖动小字调整位置并实时预览", @"cursorarrow.motionlines", NeoWCRowKindDetail, nil, appearanceValue)];
        } else {
            [messageItems addObject:item(@"本地提示模板", @"设置消息下方显示的完整防撤回提示", @"text.bubble", NeoWCRowKindDetail, nil, @"编辑")];
        }
        [messageItems addObject:item(@"回复撤回者", @"自动发送提示，默认关闭", @"paperplane", NeoWCRowKindSwitch, NeoWCAntiRevokeNotifySenderKey, nil)];
        if (notifySenderEnabled) {
            [messageItems addObject:item(@"回复时间限制", @"避免响应很久以前的撤回事件", @"timer", NeoWCRowKindDetail, nil, revokeFilterValue)];
            [messageItems addObject:item(@"回复消息模板", @"设置发送给撤回者的提示", @"text.quote", NeoWCRowKindDetail, nil, @"编辑")];
        }
        [messageItems addObject:item(@"防撤回记录中心", @"搜索本次运行期间拦截的撤回消息", @"tray.full", NeoWCRowKindDetail, nil, @"查看")];
        [messageItems addObject:item(@"本地保存撤回记录", @"默认关闭；仅保存摘要和分类", @"internaldrive", NeoWCRowKindSwitch, NeoWCAntiRevokePersistRecordsKey, nil)];
    }

    NSMutableArray<NeoWCSettingItem *> *enhancementItems = [NSMutableArray arrayWithArray:@[
        item(@"设备扫码自动登录", @"自动确认电脑、平板等设备登录", @"desktopcomputer", NeoWCRowKindSwitch, NeoWCAutoDeviceLoginKey, nil),
        item(@"游戏授权自动允许", @"自动点击游戏扫码授权页面的允许按钮", @"gamecontroller", NeoWCRowKindSwitch, NeoWCAutoGameAuthorizeKey, nil),
        item(@"朋友圈双击点赞", @"双击好友朋友圈内容直接点赞", @"hand.thumbsup", NeoWCRowKindSwitch, NeoWCMomentsDoubleTapLikeKey, nil),
        item(@"朋友圈操作按钮替换为评论", @"点击后直接进入评论，不再展开操作菜单", @"bubble.middle.bottom", NeoWCRowKindSwitch, NeoWCMomentsQuickCommentKey, nil),
        item(@"小游戏结果选择", @"支持骰子与猜拳跨类型彩蛋", @"die.face.5", NeoWCRowKindSwitch, NeoWCGameSelectorKey, nil),
        item(@"自定义微信运动步数", @"每天启动微信时自动使用设定步数", @"figure.walk", NeoWCRowKindSwitch, NeoWCStepOverrideEnabledKey, nil),
    ]];
    if (momentsLikeEnabled) {
        NSUInteger hapticIndex = MIN((NSUInteger)3, enhancementItems.count);
        [enhancementItems insertObject:item(@"点赞震动", @"双击点赞成功时提供触感反馈", @"waveform", NeoWCRowKindSwitch, NeoWCMomentsLikeHapticEnabledKey, nil) atIndex:hapticIndex];
        if (momentsHapticEnabled) {
            CGFloat intensity = [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCMomentsLikeHapticIntensityKey];
            NSString *intensityText = intensity < 0.34 ? @"轻" : (intensity < 0.75 ? @"中" : @"强");
            [enhancementItems insertObject:item(@"点赞震动力度", @"调整双击点赞时的震动反馈", @"slider.horizontal.3", NeoWCRowKindDetail, nil, intensityText) atIndex:MIN(hapticIndex + 1, enhancementItems.count)];
        }
    }
    if (stepOverrideEnabled) [enhancementItems addObject:item(@"设置运动步数", @"设定值会在每天首次启动或回到微信时刷新", @"number", NeoWCRowKindDetail, nil, stepValue)];
    [enhancementItems addObject:item(@"广告净化", @"隐藏朋友圈广告与小程序启动广告", @"rectangle.badge.xmark", NeoWCRowKindSwitch, NeoWCAdBlockerKey, nil)];
    [enhancementItems addObject:item(@"图片编辑快捷发送", @"在官方图片编辑完成菜单中增加发送到当前会话", @"photo.badge.arrow.down", NeoWCRowKindSwitch, NeoWCImageEditQuickSendEnabledKey, nil)];
    if (imageEditQuickSendEnabled) [enhancementItems addObject:item(@"发送后返回聊天", @"图片发送成功后退出编辑流程", @"arrow.uturn.backward", NeoWCRowKindSwitch, NeoWCImageEditReturnToChatKey, nil)];
    [enhancementItems addObject:item(@"多选消息长截图", @"在聊天多选的“更多”中加入截图", @"rectangle.dashed", NeoWCRowKindSwitch, NeoWCChatCaptureEnabledKey, nil)];
    if (chatCaptureEnabled) [enhancementItems addObject:item(@"长截图设置", @"顶栏、昵称、背景与裁切选项", @"slider.horizontal.3", NeoWCRowKindDetail, nil, @"设置")];
    [enhancementItems addObject:item(@"多选消息导出", @"控制多选菜单中的复制、保存和分享功能", @"square.and.arrow.up.on.square", NeoWCRowKindSwitch, NeoWCMultiSelectExportEnabledKey, nil)];
    if (multiSelectExportEnabled) {
        [enhancementItems addObject:item(@"复制纯文本", @"只复制消息正文到剪贴板", @"doc.on.clipboard", NeoWCRowKindSwitch, NeoWCMultiSelectExportTextKey, nil)];
        [enhancementItems addObject:item(@"批量保存图片", @"保存所选且已下载到本机的图片", @"photo.on.rectangle.angled", NeoWCRowKindSwitch, NeoWCMultiSelectSaveImagesKey, nil)];
        [enhancementItems addObject:item(@"生成分享卡片", @"可选择极简、对话或深色样式", @"rectangle.on.rectangle", NeoWCRowKindSwitch, NeoWCMultiSelectShareCardKey, nil)];
    }
    [enhancementItems addObject:item(@"插件显示管理", @"隐藏其他插件入口并检测加载状态", @"square.stack.3d.up", NeoWCRowKindDetail, nil, @"管理")];

    self.sections = @[
        [NeoWCSettingSection sectionWithIdentifier:@"general" title:@"总开关" subtitle:nil symbol:@"switch.2" footer:@"关闭后仅保留设置入口，所有增强功能停止生效。" collapsible:NO items:@[
            item(@"启用 NeoWC", @"插件功能总开关", @"power", NeoWCRowKindSwitch, NeoWCEnabledKey, nil),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"messages" title:@"消息增强" subtitle:@"撤回拦截与提示" symbol:@"bubble.left.and.bubble.right" footer:@"" collapsible:YES items:messageItems],
        [NeoWCSettingSection sectionWithIdentifier:@"enhancements" title:@"增强功能" subtitle:@"快捷操作与自动授权" symbol:@"bolt" footer:@"自动登录和授权会跳过手动确认，请只在可信设备和可信游戏中开启。" collapsible:YES items:enhancementItems],
        [NeoWCSettingSection sectionWithIdentifier:@"developer" title:@"开发者功能" subtitle:@"界面检查与运行诊断" symbol:@"hammer" footer:@"开发者功能用于辅助插件开发和问题排查。" collapsible:YES items:@[
            item(@"调试悬浮按钮", @"仅由此开关控制，不监听全局手势", @"wrench.and.screwdriver", NeoWCRowKindSwitch, NeoWCDebugFloatingEnabledKey, nil),
            item(@"记录调试日志", @"记录 NeoWC 运行事件，关闭后停止新增", @"text.alignleft", NeoWCRowKindSwitch, NeoWCDebugLoggingEnabledKey, nil),
            item(@"调试中心", @"视图检查、Runtime 搜索与日志", @"ladybug", NeoWCRowKindDetail, nil, @"打开"),
            item(@"功能兼容性", @"检查类、Selector 与本次运行触发状态", @"checklist", NeoWCRowKindDetail, nil, @"检查"),
        ]],
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
        background.drawsDivider = !firstRow;
        cell.backgroundView = background;
        NeoWCCardBackgroundView *selectedBackground = [NeoWCCardBackgroundView new];
        selectedBackground.roundsTop = firstRow;
        selectedBackground.roundsBottom = lastRow;
        selectedBackground.drawsDivider = !firstRow;
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
        cell.accessoryView = toggle;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
    if ([item.defaultsKey isEqualToString:NeoWCAntiRevokeKey]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    }
    BOOL changesVisibleRows = [item.defaultsKey isEqualToString:NeoWCAntiRevokeKey] ||
                              [item.defaultsKey isEqualToString:NeoWCAntiRevokeNotifySenderKey] ||
                              [item.defaultsKey isEqualToString:NeoWCStepOverrideEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMomentsDoubleTapLikeKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMomentsLikeHapticEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMultiSelectExportEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCChatCaptureEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCImageEditQuickSendEnabledKey];
    if (changesVisibleRows) [self buildSections];
    if ([item.defaultsKey isEqualToString:NeoWCEnabledKey] || changesVisibleRows) [self.tableView reloadData];
}

- (void)toggleSection:(NSInteger)sectionIndex {
    NeoWCSettingSection *section = self.sections[sectionIndex];
    if (!section.isCollapsible) return;
    if ([self.expandedCategoryIDs containsObject:section.identifier]) {
        [self.expandedCategoryIDs removeObject:section.identifier];
    } else {
        [self.expandedCategoryIDs addObject:section.identifier];
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.expandedCategoryIDs.allObjects forKey:NeoWCExpandedCategoriesKey];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:@"支持 {用户名}、{内容}、{yyyy}、{MM}、{dd}、{HH}、{mm}、{ss}"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        NSString *savedValue = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        textField.text = savedValue.length > 0 ? savedValue : defaultValue;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"恢复默认" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *value = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (value.length > 0) [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
        else [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
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
    if ([item.title isEqualToString:@"插件显示管理"]) {
        [self.navigationController pushViewController:[NeoWCPluginVisibilityViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"长截图设置"]) {
        [self.navigationController pushViewController:[NeoWCChatCaptureSettingsViewController new] animated:YES];
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
}

@end
