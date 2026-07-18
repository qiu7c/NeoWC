#import "NeoWCSettingsViewController.h"

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
    return [self initWithStyle:UITableViewStyleInsetGrouped];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) [self buildSections];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        NeoWCEnabledKey: @YES,
        @"com.qiu7c.neowc.message.anti-revoke": @YES,
        @"com.qiu7c.neowc.privacy.typing": @YES,
        NeoWCExpandedCategoriesKey: @[@"messages"],
    }];
    NSArray *savedCategories = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCExpandedCategoriesKey];
    self.expandedCategoryIDs = [NSMutableSet setWithArray:savedCategories ?: @[]];

    self.title = @"NeoWC";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 62.0;
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.tableView.tableHeaderView = [self makeHeaderView];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"NeoWCSettingCell"];
}

- (void)buildSections {
    NeoWCSettingItem *(^item)(NSString *, NSString *, NSString *, NeoWCRowKind, NSString *, NSString *) =
    ^NeoWCSettingItem *(NSString *title, NSString *subtitle, NSString *symbol, NeoWCRowKind kind, NSString *key, NSString *value) {
        return [NeoWCSettingItem itemWithTitle:title subtitle:subtitle symbol:symbol kind:kind key:key value:value];
    };

    self.sections = @[
        [NeoWCSettingSection sectionWithIdentifier:@"general" title:@"总开关" subtitle:nil symbol:nil footer:@"关闭后仅保留设置入口，所有增强功能停止生效。" collapsible:NO items:@[
            item(@"启用 NeoWC", @"插件功能总开关", @"power", NeoWCRowKindSwitch, NeoWCEnabledKey, nil),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"messages" title:@"消息增强" subtitle:@"撤回、时间与消息显示" symbol:@"bubble.left.and.bubble.right" footer:@"" collapsible:YES items:@[
            item(@"防撤回", @"保留好友撤回的消息提示", @"arrow.uturn.backward.circle", NeoWCRowKindSwitch, @"com.qiu7c.neowc.message.anti-revoke", nil),
            item(@"消息时间", @"在气泡旁显示精确发送时间", @"clock", NeoWCRowKindSwitch, @"com.qiu7c.neowc.message.timestamp", nil),
            item(@"消息增强设置", @"更多消息相关选项", @"slider.horizontal.3", NeoWCRowKindDetail, nil, @"规划中"),
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
        [NeoWCSettingSection sectionWithIdentifier:@"laboratory" title:@"实验工具" subtitle:@"测试功能与运行诊断" symbol:@"flask.fill" footer:@"实验功能可能随版本调整。" collapsible:YES items:@[
            item(@"调试日志", @"记录插件运行状态", @"doc.text.magnifyingglass", NeoWCRowKindSwitch, @"com.qiu7c.neowc.labs.logging", nil),
            item(@"运行诊断", @"查看环境与兼容状态", @"stethoscope", NeoWCRowKindDetail, nil, @"规划中"),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"about" title:@"关于" subtitle:nil symbol:nil footer:@"NeoWC · Designed for WeChat" collapsible:NO items:@[
            item(@"版本", @"NeoWC", @"shippingbox", NeoWCRowKindInfo, nil, NeoWCVersion),
        ]],
    ];
}

- (UIView *)makeHeaderView {
    CGFloat width = MAX(CGRectGetWidth(self.view.bounds), CGRectGetWidth([UIScreen mainScreen].bounds));
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 156.0)];
    UIView *card = [UIView new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    card.layer.cornerRadius = 18.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.shadowOpacity = 0.0;
    [container addSubview:card];

    NeoWCLogoView *logo = [NeoWCLogoView new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.layer.shadowOpacity = 0.0;
    [card addSubview:logo];

    UILabel *name = [UILabel new];
    name.translatesAutoresizingMaskIntoConstraints = NO;
    name.text = @"NeoWC";
    name.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    name.adjustsFontForContentSizeCategory = YES;
    [card addSubview:name];

    UILabel *version = [UILabel new];
    version.translatesAutoresizingMaskIntoConstraints = NO;
    version.text = [NSString stringWithFormat:@"v%@ · UI PREVIEW", NeoWCVersion];
    version.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    version.adjustsFontForContentSizeCategory = YES;
    version.textColor = [UIColor secondaryLabelColor];
    [card addSubview:version];

    UILabel *tagline = [UILabel new];
    tagline.translatesAutoresizingMaskIntoConstraints = NO;
    tagline.text = @"轻量、清晰、原生的微信增强体验";
    tagline.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    tagline.adjustsFontForContentSizeCategory = YES;
    tagline.textColor = [UIColor secondaryLabelColor];
    [card addSubview:tagline];

    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:20.0],
        [card.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-20.0],
        [card.topAnchor constraintEqualToAnchor:container.topAnchor constant:12.0],
        [card.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-12.0],
        [logo.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [logo.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [logo.widthAnchor constraintEqualToConstant:58.0],
        [logo.heightAnchor constraintEqualToConstant:58.0],
        [name.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:14.0],
        [name.trailingAnchor constraintLessThanOrEqualToAnchor:card.trailingAnchor constant:-16.0],
        [name.topAnchor constraintEqualToAnchor:logo.topAnchor constant:3.0],
        [version.leadingAnchor constraintEqualToAnchor:name.leadingAnchor],
        [version.topAnchor constraintEqualToAnchor:name.bottomAnchor constant:4.0],
        [tagline.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [tagline.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [tagline.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-17.0],
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
    return model.isCollapsible ? nil : model.title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NeoWCSettingSection *model = self.sections[section];
    if (model.isCollapsible && ![self isSectionExpanded:model]) return nil;
    return model.footer.length > 0 ? model.footer : nil;
}

- (NeoWCSettingItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCSettingSection *section = self.sections[indexPath.section];
    NSInteger itemIndex = section.isCollapsible ? indexPath.row - 1 : indexPath.row;
    if (itemIndex < 0 || itemIndex >= section.items.count) return nil;
    return section.items[itemIndex];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCSettingSection *section = self.sections[indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NeoWCSettingCell" forIndexPath:indexPath];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    if (section.isCollapsible && indexPath.row == 0) {
        UIListContentConfiguration *categoryContent = [UIListContentConfiguration subtitleCellConfiguration];
        categoryContent.text = section.title;
        categoryContent.secondaryText = section.subtitle;
        categoryContent.image = NeoWCSymbol(section.symbol);
        categoryContent.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        categoryContent.secondaryTextProperties.color = [UIColor secondaryLabelColor];
        categoryContent.imageProperties.tintColor = [UIColor colorWithRed:0.06 green:0.68 blue:0.35 alpha:1.0];
        categoryContent.imageProperties.maximumSize = CGSizeMake(25.0, 25.0);
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
    content.imageProperties.tintColor = [UIColor colorWithRed:0.06 green:0.68 blue:0.35 alpha:1.0];
    content.imageProperties.maximumSize = CGSizeMake(23.0, 23.0);
    if (section.isCollapsible) content.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0, 16.0, 0, 0);
    cell.contentConfiguration = content;

    if (item.kind == NeoWCRowKindSwitch) {
        UISwitch *toggle = [UISwitch new];
        toggle.onTintColor = [UIColor colorWithRed:0.06 green:0.72 blue:0.38 alpha:1.0];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NeoWCSettingSection *section = self.sections[indexPath.section];
    if (section.isCollapsible && indexPath.row == 0) {
        [self toggleSection:indexPath.section];
        return;
    }

    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    if (item.kind != NeoWCRowKindDetail) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:item.title
                                                                   message:@"当前为 UI 预览阶段，功能将在界面确认后接入。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
