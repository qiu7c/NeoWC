#import "NeoWCSettingsUI.h"
#import "NeoWCAccount.h"
#import "NeoWCSettingsCatalog.h"
#import <math.h>

static UIImage *NeoWCSettingsSymbol(NSString *name) {
    UIImage *image = [UIImage systemImageNamed:name];
    return image ?: [UIImage systemImageNamed:@"circle.grid.2x2"];
}

static UIImageView *NeoWCSettingsChevron(NSString *name, CGFloat scale) {
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:12.0 * scale
                                                                                                  weight:UIImageSymbolWeightSemibold];
    UIImageView *chevron = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:name] imageWithConfiguration:configuration]];
    chevron.tintColor = UIColor.tertiaryLabelColor;
    chevron.contentMode = UIViewContentModeScaleAspectFit;
    return chevron;
}

static UIView *NeoWCSettingsDetailAccessory(NSString *valueText, CGFloat scale) {
    CGFloat height = 32.0 * scale;
    CGFloat chevronWidth = 9.0 * scale;
    CGFloat spacing = valueText.length > 0 ? 7.0 * scale : 0.0;
    UILabel *value = nil;
    CGFloat valueWidth = 0.0;
    if (valueText.length > 0) {
        value = [UILabel new];
        value.text = valueText;
        value.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleSubheadline]
            scaledFontForFont:[UIFont systemFontOfSize:15.0 * scale]];
        value.adjustsFontForContentSizeCategory = YES;
        value.textColor = UIColor.tertiaryLabelColor;
        value.textAlignment = NSTextAlignmentRight;
        value.adjustsFontSizeToFitWidth = YES;
        value.minimumScaleFactor = 0.75;
        valueWidth = MIN(132.0 * scale, [value sizeThatFits:CGSizeMake(CGFLOAT_MAX, height)].width);
    }
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0,
                                                                 valueWidth + spacing + chevronWidth,
                                                                 height)];
    if (value) {
        value.frame = CGRectMake(0.0, 0.0, valueWidth, height);
        [container addSubview:value];
    }
    UIImageView *chevron = NeoWCSettingsChevron(@"chevron.right", scale);
    chevron.frame = CGRectMake(valueWidth + spacing, 0.0, chevronWidth, height);
    [container addSubview:chevron];
    return container;
}

static UIView *NeoWCSettingsExpandableSwitchAccessory(UISwitch *toggle, BOOL expanded, CGFloat scale) {
    [toggle sizeToFit];
    CGFloat chevronWidth = 10.0 * scale;
    CGFloat spacing = 8.0 * scale;
    CGFloat height = MAX(toggle.bounds.size.height, 32.0 * scale);
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0,
                                                                 chevronWidth + spacing + toggle.bounds.size.width,
                                                                 height)];
    UIImageView *chevron = NeoWCSettingsChevron(expanded ? @"chevron.down" : @"chevron.right", scale);
    chevron.alpha = toggle.isOn ? 1.0 : 0.3;
    chevron.frame = CGRectMake(0.0, 0.0, chevronWidth, height);
    toggle.frame = CGRectMake(chevronWidth + spacing,
                              (height - toggle.bounds.size.height) * 0.5,
                              toggle.bounds.size.width,
                              toggle.bounds.size.height);
    [container addSubview:chevron];
    [container addSubview:toggle];
    return container;
}

@interface NeoWCSettingsCell ()
@property (nonatomic, strong) NeoWCSettingItem *settingItem;
@property (nonatomic, copy) NeoWCSettingsSwitchHandler switchHandler;
@end

@implementation NeoWCSettingsCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.settingItem = nil;
    self.switchHandler = nil;
    self.accessoryView = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessibilityHint = nil;
}

- (void)toggleChanged:(UISwitch *)sender {
    if (self.switchHandler && self.settingItem) self.switchHandler(self.settingItem, sender.isOn);
}

- (void)configureWithItem:(NeoWCSettingItem *)item
            masterEnabled:(BOOL)masterEnabled
                 expanded:(BOOL)expanded
                     scale:(CGFloat)scale
            switchHandler:(NeoWCSettingsSwitchHandler)switchHandler {
    self.settingItem = item;
    self.switchHandler = switchHandler;
    self.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.accessoryView = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessibilityHint = nil;

    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = item.title;
    content.secondaryText = item.subtitle;
    UIFontMetrics *bodyMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleBody];
    UIFontMetrics *footnoteMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleFootnote];
    content.textProperties.font = [bodyMetrics scaledFontForFont:[UIFont systemFontOfSize:17.0 * scale]];
    content.textProperties.adjustsFontForContentSizeCategory = YES;
    content.textProperties.numberOfLines = 0;
    content.secondaryTextProperties.font = [footnoteMetrics scaledFontForFont:[UIFont systemFontOfSize:13.0 * scale]];
    content.secondaryTextProperties.adjustsFontForContentSizeCategory = YES;
    content.secondaryTextProperties.color = UIColor.secondaryLabelColor;
    content.secondaryTextProperties.numberOfLines = 0;
    content.image = NeoWCSettingsSymbol(item.symbol);
    content.imageProperties.tintColor = UIColor.secondaryLabelColor;
    content.imageProperties.maximumSize = CGSizeMake(20.0 * scale, 20.0 * scale);
    CGFloat leading = (item.child ? 28.0 : 12.0) * scale;
    content.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(6.0 * scale, leading, 6.0 * scale, 12.0 * scale);
    self.contentConfiguration = content;

    if (item.kind == NeoWCSettingRowKindSwitch) {
        UISwitch *toggle = [UISwitch new];
        toggle.onTintColor = UIColor.systemBlueColor;
        toggle.on = [NSUserDefaults.standardUserDefaults boolForKey:item.defaultsKey];
        toggle.enabled = [item.defaultsKey isEqualToString:NeoWCEnabledKey] || masterEnabled;
        toggle.accessibilityLabel = item.title;
        [toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
        if (item.hasChildren) {
            self.accessoryView = NeoWCSettingsExpandableSwitchAccessory(toggle, expanded, scale);
            self.selectionStyle = toggle.isOn ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            self.accessibilityHint = toggle.isOn ? (expanded ? @"轻点收起子选项" : @"轻点展开子选项") : nil;
        } else {
            self.accessoryView = toggle;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    } else if (item.kind == NeoWCSettingRowKindDetail) {
        self.accessoryView = NeoWCSettingsDetailAccessory(item.value, scale);
    } else if (item.value.length > 0) {
        UILabel *value = [UILabel new];
        value.text = item.value;
        value.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleSubheadline] scaledFontForFont:[UIFont systemFontOfSize:15.0 * scale]];
        value.adjustsFontForContentSizeCategory = YES;
        value.textColor = UIColor.secondaryLabelColor;
        self.accessoryView = value;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

@end

@interface NeoWCSettingsProfileHeaderView ()
@property (nonatomic, copy, readwrite) NSString *wxid;
@property (nonatomic, strong) UIView *avatarView;
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UILabel *wxidLabel;
@property (nonatomic, copy) NSArray<NSLayoutConstraint *> *avatarConstraints;
@property (nonatomic, copy) NSString *appliedAvatarWXID;
@property (nonatomic, copy) NSString *appliedHeadURL;
- (void)applyProfileWithWXID:(nullable NSString *)wxid
                    nickname:(nullable NSString *)nickname
                     headURL:(nullable NSString *)headURL;
@end

@implementation NeoWCSettingsProfileHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.accessibilityTraits = UIAccessibilityTraitButton;

    _nicknameLabel = [UILabel new];
    _nicknameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nicknameLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle2]
        scaledFontForFont:[UIFont systemFontOfSize:20.0 weight:UIFontWeightRegular]];
    _nicknameLabel.adjustsFontForContentSizeCategory = YES;
    _nicknameLabel.numberOfLines = 1;
    _nicknameLabel.textAlignment = NSTextAlignmentCenter;
    _nicknameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self addSubview:_nicknameLabel];

    _wxidLabel = [UILabel new];
    _wxidLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _wxidLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody]
        scaledFontForFont:[UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular]];
    _wxidLabel.adjustsFontForContentSizeCategory = YES;
    _wxidLabel.textColor = UIColor.secondaryLabelColor;
    _wxidLabel.textAlignment = NSTextAlignmentCenter;
    _wxidLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self addSubview:_wxidLabel];

    // Account values are persisted. Apply them before the header first appears
    // so it never renders an empty placeholder frame.
    [self refreshProfile];
    return self;
}

- (UIView *)makeAvatarViewWithWXID:(NSString *)wxid headURL:(NSString *)headURL {
    (void)wxid;
    UIImageView *fallback = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"person.crop.circle.fill"]];
    fallback.tintColor = UIColor.tertiaryLabelColor;
    fallback.contentMode = UIViewContentModeScaleAspectFill;
    fallback.clipsToBounds = YES;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *cachedURL = [defaults stringForKey:@"com.qiu7c.neowc.ui.cached-avatar-url"];
    NSData *cachedImageData = [defaults dataForKey:@"com.qiu7c.neowc.ui.cached-avatar-data"];
    if (headURL.length > 0 && [cachedURL isEqualToString:headURL] && cachedImageData.length > 0) {
        UIImage *cachedImage = [UIImage imageWithData:cachedImageData];
        if (cachedImage) fallback.image = cachedImage;
    }
    NSURL *URL = headURL.length > 0 ? [NSURL URLWithString:headURL] : nil;
    if (URL) {
        __weak UIImageView *weakImageView = fallback;
        [[[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData *data, __unused NSURLResponse *response, __unused NSError *error) {
            UIImage *image = data.length > 0 ? [UIImage imageWithData:data] : nil;
            if (!image) return;
            [NSUserDefaults.standardUserDefaults setObject:headURL forKey:@"com.qiu7c.neowc.ui.cached-avatar-url"];
            [NSUserDefaults.standardUserDefaults setObject:data forKey:@"com.qiu7c.neowc.ui.cached-avatar-data"];
            dispatch_async(dispatch_get_main_queue(), ^{ weakImageView.image = image; });
        }] resume];
    }
    return fallback;
}

- (void)refreshProfile {
    [self applyProfileWithWXID:NeoWCCurrentUserWXID()
                      nickname:NeoWCCurrentUserNickname()
                       headURL:NeoWCCurrentUserHeadImageURL()];
}

- (void)applyProfileWithWXID:(NSString *)wxid
                    nickname:(NSString *)nickname
                     headURL:(NSString *)headURL {
    self.wxid = wxid;
    NSString *displayNickname = nickname.length > 0 ? nickname : @"微信用户";
    self.nicknameLabel.attributedText = nil;
    self.nicknameLabel.textColor = UIColor.labelColor;
    self.nicknameLabel.text = displayNickname;
    self.wxidLabel.text = self.wxid.length > 0 ? self.wxid : @"wxid 未获取";
    self.accessibilityLabel = [NSString stringWithFormat:@"%@，%@", displayNickname, self.wxidLabel.text];
    self.accessibilityHint = self.wxid.length > 0 ? @"轻点复制 wxid" : nil;

    BOOL avatarNeedsUpdate = !self.avatarView ||
        ![(self.appliedAvatarWXID ?: @"") isEqualToString:(self.wxid ?: @"")] ||
        ![(self.appliedHeadURL ?: @"") isEqualToString:(headURL ?: @"")];
    if (!avatarNeedsUpdate) return;
    self.appliedAvatarWXID = self.wxid ?: @"";
    self.appliedHeadURL = headURL ?: @"";
    [NSLayoutConstraint deactivateConstraints:self.avatarConstraints ?: @[]];
    [self.avatarView removeFromSuperview];
    UIView *avatarContent = [self makeAvatarViewWithWXID:self.wxid headURL:headURL];
    avatarContent.translatesAutoresizingMaskIntoConstraints = NO;
    avatarContent.clipsToBounds = YES;
    avatarContent.layer.cornerRadius = 22.0;
    avatarContent.layer.cornerCurve = kCACornerCurveContinuous;

    self.avatarView = [UIView new];
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.layer.cornerRadius = 22.0;
    self.avatarView.layer.cornerCurve = kCACornerCurveContinuous;
    [self.avatarView addSubview:avatarContent];
    [self addSubview:self.avatarView];
    self.avatarConstraints = @[
        [self.avatarView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.avatarView.topAnchor constraintEqualToAnchor:self.topAnchor constant:18.0],
        [self.avatarView.widthAnchor constraintEqualToConstant:92.0],
        [self.avatarView.heightAnchor constraintEqualToConstant:92.0],
        [avatarContent.leadingAnchor constraintEqualToAnchor:self.avatarView.leadingAnchor],
        [avatarContent.trailingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor],
        [avatarContent.topAnchor constraintEqualToAnchor:self.avatarView.topAnchor],
        [avatarContent.bottomAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor],
        [self.nicknameLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:24.0],
        [self.nicknameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-24.0],
        [self.nicknameLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.nicknameLabel.topAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor constant:10.0],
        [self.wxidLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:24.0],
        [self.wxidLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-24.0],
        [self.wxidLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.wxidLabel.topAnchor constraintEqualToAnchor:self.nicknameLabel.bottomAnchor constant:4.0],
        [self.wxidLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-16.0],
    ];
    [NSLayoutConstraint activateConstraints:self.avatarConstraints];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width scale:(CGFloat)scale {
    CGFloat textWidth = MAX(120.0, width - 48.0);
    CGFloat nicknameHeight = [self.nicknameLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height;
    CGFloat wxidHeight = [self.wxidLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height;
    CGFloat contentHeight = 18.0 + 92.0 + 10.0 + nicknameHeight + 4.0 + wxidHeight + 16.0;
    return MAX(contentHeight, 188.0 * scale);
}

- (void)showCopyConfirmation {
    self.wxidLabel.text = @"wxid 已复制";
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NeoWCSettingsProfileHeaderView *strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.wxidLabel.text = strongSelf.wxid.length > 0 ? strongSelf.wxid : @"wxid 未获取";
    });
}

@end
