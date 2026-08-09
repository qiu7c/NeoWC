#import "NeoWCSettingsUI.h"
#import "NeoWCAccount.h"
#import "NeoWCSettingsCatalog.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <math.h>

static UIImage *NeoWCSettingsSymbol(NSString *name) {
    UIImage *image = [UIImage systemImageNamed:name];
    return image ?: [UIImage systemImageNamed:@"circle.grid.2x2"];
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
            UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down"]];
            chevron.tintColor = UIColor.tertiaryLabelColor;
            chevron.alpha = toggle.isOn ? 1.0 : 0.0;
            chevron.transform = expanded ? CGAffineTransformIdentity : CGAffineTransformMakeRotation((CGFloat)-M_PI_2);
            [chevron.widthAnchor constraintEqualToConstant:11.0].active = YES;
            [chevron.heightAnchor constraintEqualToConstant:15.0].active = YES;
            UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[chevron, toggle]];
            stack.axis = UILayoutConstraintAxisHorizontal;
            stack.alignment = UIStackViewAlignmentCenter;
            stack.spacing = 8.0;
            stack.frame = CGRectMake(0.0, 0.0, 72.0, 32.0);
            self.accessoryView = stack;
            self.selectionStyle = toggle.isOn ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            self.accessibilityHint = toggle.isOn ? (expanded ? @"轻点收起子选项" : @"轻点展开子选项") : nil;
        } else {
            self.accessoryView = toggle;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    } else if (item.kind == NeoWCSettingRowKindDetail) {
        UILabel *value = [UILabel new];
        value.text = item.value ?: @"";
        value.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleSubheadline] scaledFontForFont:[UIFont systemFontOfSize:15.0 * scale]];
        value.adjustsFontForContentSizeCategory = YES;
        value.textColor = UIColor.tertiaryLabelColor;
        value.adjustsFontSizeToFitWidth = YES;
        value.minimumScaleFactor = 0.8;
        UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        chevron.tintColor = UIColor.quaternaryLabelColor;
        [chevron.widthAnchor constraintEqualToConstant:8.0].active = YES;
        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[value, chevron]];
        stack.axis = UILayoutConstraintAxisHorizontal;
        stack.alignment = UIStackViewAlignmentCenter;
        stack.spacing = 6.0;
        self.accessoryView = stack;
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
        scaledFontForFont:[UIFont systemFontOfSize:22.0 weight:UIFontWeightRegular]];
    _nicknameLabel.adjustsFontForContentSizeCategory = YES;
    _nicknameLabel.numberOfLines = 2;
    [self addSubview:_nicknameLabel];

    _wxidLabel = [UILabel new];
    _wxidLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _wxidLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody]
        scaledFontForFont:[UIFont systemFontOfSize:17.0 weight:UIFontWeightRegular]];
    _wxidLabel.adjustsFontForContentSizeCategory = YES;
    _wxidLabel.textColor = UIColor.secondaryLabelColor;
    _wxidLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self addSubview:_wxidLabel];
    [self refreshProfile];
    return self;
}

- (UIView *)makeAvatarViewWithWXID:(NSString *)wxid headURL:(NSString *)headURL {
    Class helperClass = objc_getClass("MMHeadImageHelper");
    SEL selector = sel_registerName("getContactHeadImageViewWithUsrName:headImgUrl:bAutoUpdate:bRoundCorner:");
    if (helperClass && [helperClass respondsToSelector:selector] && wxid.length > 0) {
        id view = ((id (*)(id, SEL, id, id, BOOL, BOOL))objc_msgSend)(helperClass, selector, wxid, headURL ?: @"", YES, YES);
        if ([view isKindOfClass:UIView.class]) return view;
    }
    UIImageView *fallback = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"person.crop.circle.fill"]];
    fallback.tintColor = UIColor.tertiaryLabelColor;
    fallback.contentMode = UIViewContentModeScaleAspectFit;
    return fallback;
}

- (void)refreshProfile {
    self.wxid = NeoWCCurrentUserWXID();
    NSString *nickname = NeoWCCurrentUserNickname();
    NSString *headURL = NeoWCCurrentUserHeadImageURL();
    self.nicknameLabel.text = nickname.length > 0 ? nickname : @"微信用户";
    self.wxidLabel.text = self.wxid.length > 0 ? self.wxid : @"wxid 未获取";
    self.accessibilityLabel = [NSString stringWithFormat:@"%@，%@", self.nicknameLabel.text, self.wxidLabel.text];
    self.accessibilityHint = self.wxid.length > 0 ? @"轻点复制 wxid" : nil;

    [NSLayoutConstraint deactivateConstraints:self.avatarConstraints ?: @[]];
    [self.avatarView removeFromSuperview];
    UIView *avatarContent = [self makeAvatarViewWithWXID:self.wxid headURL:headURL];
    avatarContent.translatesAutoresizingMaskIntoConstraints = NO;
    avatarContent.clipsToBounds = YES;
    avatarContent.layer.cornerRadius = 20.0;
    avatarContent.layer.cornerCurve = kCACornerCurveContinuous;

    self.avatarView = [UIView new];
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.layer.cornerRadius = 20.0;
    self.avatarView.layer.cornerCurve = kCACornerCurveContinuous;
    [self.avatarView addSubview:avatarContent];
    [self addSubview:self.avatarView];
    self.avatarConstraints = @[
        [self.avatarView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20.0],
        [self.avatarView.topAnchor constraintEqualToAnchor:self.topAnchor constant:20.0],
        [self.avatarView.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-20.0],
        [self.avatarView.widthAnchor constraintEqualToConstant:96.0],
        [self.avatarView.heightAnchor constraintEqualToConstant:96.0],
        [avatarContent.leadingAnchor constraintEqualToAnchor:self.avatarView.leadingAnchor],
        [avatarContent.trailingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor],
        [avatarContent.topAnchor constraintEqualToAnchor:self.avatarView.topAnchor],
        [avatarContent.bottomAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor],
        [self.nicknameLabel.leadingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor constant:18.0],
        [self.nicknameLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20.0],
        [self.nicknameLabel.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor constant:12.0],
        [self.wxidLabel.leadingAnchor constraintEqualToAnchor:self.nicknameLabel.leadingAnchor],
        [self.wxidLabel.trailingAnchor constraintEqualToAnchor:self.nicknameLabel.trailingAnchor],
        [self.wxidLabel.topAnchor constraintEqualToAnchor:self.nicknameLabel.bottomAnchor constant:4.0],
        [self.wxidLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-12.0],
        [self.nicknameLabel.centerYAnchor constraintEqualToAnchor:self.avatarView.centerYAnchor constant:-14.0],
    ];
    [NSLayoutConstraint activateConstraints:self.avatarConstraints];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width scale:(CGFloat)scale {
    CGFloat textWidth = MAX(120.0, width - 154.0);
    CGFloat nicknameHeight = [self.nicknameLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height;
    CGFloat wxidHeight = [self.wxidLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height;
    CGFloat textHeight = 20.0 + nicknameHeight + 6.0 + wxidHeight + 20.0;
    return MAX(MAX(136.0, 140.0 * scale), textHeight);
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
