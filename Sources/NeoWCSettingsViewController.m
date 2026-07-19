#import "NeoWCSettingsViewController.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import "NeoWCChatCapture.h"
#import "NeoWCPluginVisibility.h"

static NSString *const NeoWCVersion = @"0.1.0";
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
        _fillColor = [UIColor secondarySystemFillColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGRect cardRect = CGRectInset(self.bounds, 14.0, 0.0);
    UIRectCorner corners = 0;
    if (self.roundsTop) corners |= UIRectCornerTopLeft | UIRectCornerTopRight;
    if (self.roundsBottom) corners |= UIRectCornerBottomLeft | UIRectCornerBottomRight;
    UIBezierPath *path = corners ? [UIBezierPath bezierPathWithRoundedRect:cardRect byRoundingCorners:corners cornerRadii:CGSizeMake(20.0, 20.0)] : [UIBezierPath bezierPathWithRect:cardRect];
    [self.fillColor setFill];
    [path fill];

    if (self.drawsDivider) {
        CGFloat pixel = 1.0 / UIScreen.mainScreen.scale;
        [[UIColor separatorColor] setFill];
        UIRectFill(CGRectMake(CGRectGetMinX(cardRect) + 14.0, 0.0, CGRectGetWidth(cardRect) - 28.0, pixel));
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
        NeoWCChatCaptureEnabledKey: @NO,
        NeoWCChatCaptureIncludeChromeKey: @YES,
        NeoWCChatCaptureHideMemberNamesKey: @NO,
        NeoWCChatCaptureShowBackgroundKey: @YES,
        NeoWCChatCaptureCloseAfterShareKey: @NO,
        NeoWCChatCaptureCropTopPointsKey: @0.0,
        NeoWCChatCaptureShowChatNameKey: @NO,
        NeoWCChatCaptureShowTimestampKey: @NO,
        NeoWCChatCaptureWatermarkStyleKey: @0,
        NeoWCChatCaptureWatermarkOpacityKey: @0.18,
        @"com.qiu7c.neowc.privacy.typing": @YES,
        NeoWCDebugLoggingEnabledKey: @YES,
        NeoWCExpandedCategoriesKey: @[@"messages"],
    }];
    NSArray *savedCategories = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCExpandedCategoriesKey];
    self.expandedCategoryIDs = [NSMutableSet setWithArray:savedCategories ?: @[]];

    self.title = @"NeoWC";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.rowHeight = 54.0;
    self.tableView.estimatedRowHeight = 54.0;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderHeight = 10.0;
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 44.0;
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    self.tableView.tableHeaderView = [self makeHeaderView];
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

    self.sections = @[
        [NeoWCSettingSection sectionWithIdentifier:@"general" title:@"总开关" subtitle:nil symbol:nil footer:@"关闭后仅保留设置入口，所有增强功能停止生效。" collapsible:NO items:@[
            item(@"启用 NeoWC", @"插件功能总开关", @"power", NeoWCRowKindSwitch, NeoWCEnabledKey, nil),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"messages" title:@"消息增强" subtitle:@"撤回、时间与消息显示" symbol:@"bubble.left.and.bubble.right" footer:@"" collapsible:YES items:@[
            item(@"防撤回", @"保留好友撤回的消息并插入本地提示", @"arrow.uturn.backward.circle", NeoWCRowKindSwitch, NeoWCAntiRevokeKey, nil),
            item(@"回复撤回者", @"自动发送提示，默认关闭", @"paperplane", NeoWCRowKindSwitch, NeoWCAntiRevokeNotifySenderKey, nil),
            item(@"回复时间限制", @"避免响应很久以前的撤回事件", @"timer", NeoWCRowKindDetail, nil, revokeFilterValue),
            item(@"本地提示模板", @"设置聊天中显示的防撤回提示", @"text.bubble", NeoWCRowKindDetail, nil, @"编辑"),
            item(@"回复消息模板", @"设置发送给撤回者的提示", @"text.quote", NeoWCRowKindDetail, nil, @"编辑"),
            item(@"消息时间", @"在气泡旁显示精确发送时间", @"clock", NeoWCRowKindSwitch, @"com.qiu7c.neowc.message.timestamp", nil),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"privacy" title:@"隐私保护" subtitle:@"输入状态与可见性" symbol:@"hand.raised.fill" footer:@"" collapsible:YES items:@[
            item(@"隐藏正在输入", @"不向聊天对象发送输入状态", @"ellipsis.bubble", NeoWCRowKindSwitch, @"com.qiu7c.neowc.privacy.typing", nil),
            item(@"隐藏已读状态", @"减少阅读状态暴露", @"eye.slash", NeoWCRowKindSwitch, @"com.qiu7c.neowc.privacy.read-status", nil),
            item(@"隐私设置", @"管理更多可见性选项", @"lock.shield", NeoWCRowKindDetail, nil, @"规划中"),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"appearance" title:@"界面个性化" subtitle:@"聊天与会话列表外观" symbol:@"paintbrush.fill" footer:@"" collapsible:YES items:@[
            item(@"紧凑会话列表", @"在一屏显示更多会话", @"rectangle.grid.1x2", NeoWCRowKindSwitch, @"com.qiu7c.neowc.appearance.compact-list", nil),
            item(@"气泡样式", @"自定义聊天气泡显示", @"message.fill", NeoWCRowKindDetail, nil, @"规划中"),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"enhancements" title:@"增强功能" subtitle:@"快捷操作与自动授权" symbol:@"bolt.fill" footer:@"自动登录和授权会跳过手动确认，请只在可信设备和可信游戏中开启。" collapsible:YES items:@[
            item(@"设备扫码自动登录", @"自动确认电脑、平板等设备登录", @"desktopcomputer", NeoWCRowKindSwitch, NeoWCAutoDeviceLoginKey, nil),
            item(@"游戏授权自动允许", @"自动点击游戏扫码授权页面的允许按钮", @"gamecontroller", NeoWCRowKindSwitch, NeoWCAutoGameAuthorizeKey, nil),
            item(@"朋友圈双击点赞", @"双击好友朋友圈内容直接点赞", @"hand.thumbsup", NeoWCRowKindSwitch, NeoWCMomentsDoubleTapLikeKey, nil),
            item(@"朋友圈操作按钮替换为评论", @"点击后直接进入评论，不再展开操作菜单", @"bubble.middle.bottom", NeoWCRowKindSwitch, NeoWCMomentsQuickCommentKey, nil),
            item(@"小游戏结果选择", @"支持骰子与猜拳跨类型彩蛋", @"die.face.5", NeoWCRowKindSwitch, NeoWCGameSelectorKey, nil),
            item(@"自定义微信运动步数", @"使用设置的当天步数", @"figure.walk", NeoWCRowKindSwitch, NeoWCStepOverrideEnabledKey, nil),
            item(@"设置运动步数", @"自定义数值仅在设置当天生效", @"number", NeoWCRowKindDetail, nil, stepValue),
            item(@"广告净化", @"隐藏朋友圈广告与小程序启动广告", @"rectangle.badge.xmark", NeoWCRowKindSwitch, NeoWCAdBlockerKey, nil),
            item(@"多选消息长截图", @"在聊天多选的“更多”中加入截图", @"rectangle.dashed", NeoWCRowKindSwitch, NeoWCChatCaptureEnabledKey, nil),
            item(@"长截图设置", @"顶栏、昵称、背景与裁切选项", @"slider.horizontal.3", NeoWCRowKindDetail, nil, @"设置"),
            item(@"插件显示管理", @"隐藏其他插件入口并检测加载状态", @"square.stack.3d.up", NeoWCRowKindDetail, nil, @"管理"),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"developer" title:@"开发者功能" subtitle:@"界面检查与运行诊断" symbol:@"hammer.fill" footer:@"开发者功能用于辅助插件开发和问题排查。" collapsible:YES items:@[
            item(@"调试悬浮按钮", @"仅由此开关控制，不监听全局手势", @"wrench.and.screwdriver", NeoWCRowKindSwitch, NeoWCDebugFloatingEnabledKey, nil),
            item(@"记录调试日志", @"记录 NeoWC 运行事件，关闭后停止新增", @"text.alignleft", NeoWCRowKindSwitch, NeoWCDebugLoggingEnabledKey, nil),
            item(@"调试中心", @"视图检查、Runtime 搜索与日志", @"ladybug", NeoWCRowKindDetail, nil, @"打开"),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"about" title:@"关于" subtitle:nil symbol:nil footer:@"NeoWC · Designed for WeChat" collapsible:NO items:@[
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
    if (!section.isCollapsible) return section.items.count;
    return [self isSectionExpanded:section] ? section.items.count + 1 : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NeoWCSettingSection *model = self.sections[section];
    if (!model.isCollapsible) return model.title;
    return section == 1 ? @"插件分类" : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self tableView:tableView titleForHeaderInSection:section].length > 0 ? 30.0 : 10.0;
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
    NSInteger itemIndex = section.isCollapsible ? indexPath.row - 1 : indexPath.row;
    if (itemIndex < 0 || itemIndex >= section.items.count) return nil;
    return section.items[itemIndex];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCSettingSection *section = self.sections[indexPath.section];
    return section.isCollapsible && indexPath.row == 0 ? 58.0 : 54.0;
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
    cell.layoutMargins = UIEdgeInsetsMake(0.0, 26.0, 0.0, 26.0);

    if (section.isCollapsible && indexPath.row == 0) {
        UIListContentConfiguration *categoryContent = [UIListContentConfiguration subtitleCellConfiguration];
        categoryContent.text = section.title;
        categoryContent.secondaryText = section.subtitle;
        categoryContent.image = NeoWCSymbol(section.symbol);
        categoryContent.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        categoryContent.secondaryTextProperties.color = [UIColor secondaryLabelColor];
        categoryContent.imageProperties.tintColor = [UIColor labelColor];
        categoryContent.imageProperties.maximumSize = CGSizeMake(25.0, 25.0);
        categoryContent.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0.0, 26.0, 0.0, 26.0);
        cell.contentConfiguration = categoryContent;

        UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down"]];
        chevron.tintColor = [UIColor tertiaryLabelColor];
        chevron.contentMode = UIViewContentModeCenter;
        chevron.transform = [self isSectionExpanded:section] ? CGAffineTransformIdentity : CGAffineTransformMakeRotation((CGFloat)-M_PI_2);
        cell.accessoryView = chevron;
        cell.accessibilityHint = [self isSectionExpanded:section] ? @"轻点折叠" : @"轻点展开";
        return cell;
    }

    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = item.title;
    content.secondaryText = item.subtitle;
    content.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    content.secondaryTextProperties.color = [UIColor secondaryLabelColor];
    content.image = NeoWCSymbol(item.symbol);
    content.imageProperties.tintColor = [UIColor labelColor];
    content.imageProperties.maximumSize = CGSizeMake(23.0, 23.0);
    content.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0.0, section.isCollapsible ? 42.0 : 26.0, 0.0, 26.0);
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
        cell.accessoryView = valueLabel;
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
    if ([item.defaultsKey isEqualToString:NeoWCEnabledKey] ||
        [item.defaultsKey isEqualToString:NeoWCMomentsDoubleTapLikeKey] ||
        [item.defaultsKey isEqualToString:NeoWCMomentsQuickCommentKey]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCEnhancementDidChangeNotification object:item.defaultsKey];
    }
    if ([item.defaultsKey isEqualToString:NeoWCDebugFloatingEnabledKey]) {
        [[NeoWCDebugManager sharedManager] setFloatingEnabled:sender.isOn];
    }
    if ([item.defaultsKey isEqualToString:NeoWCEnabledKey]) [self.tableView reloadData];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NeoWCSettingSection *section = self.sections[indexPath.section];
    if (section.isCollapsible && indexPath.row == 0) {
        [self toggleSection:indexPath.section];
        return;
    }

    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    if (item.kind != NeoWCRowKindDetail) return;
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
    if ([item.title isEqualToString:@"插件显示管理"]) {
        [self.navigationController pushViewController:[NeoWCPluginVisibilityViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"长截图设置"]) {
        [self.navigationController pushViewController:[NeoWCChatCaptureSettingsViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"设置运动步数"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置当天微信运动步数" message:@"请输入 1–100000 之间的数值" preferredStyle:UIAlertControllerStyleAlert];
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:item.title
                                                                   message:@"当前为 UI 预览阶段，功能将在界面确认后接入。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
