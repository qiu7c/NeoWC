#import "NeoWCSettingsUI.h"
#import "NeoWCAccount.h"
#import "NeoWCAuthorization.h"
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
@property (nonatomic, strong) UILabel *authorizationLabel;
@property (nonatomic, strong) UIStackView *metadataStack;
@property (nonatomic, copy) NSArray<NSLayoutConstraint *> *avatarConstraints;
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

    _authorizationLabel = [UILabel new];
    _authorizationLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleFootnote]
        scaledFontForFont:[UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium]];
    _authorizationLabel.adjustsFontForContentSizeCategory = YES;
    _authorizationLabel.textColor = UIColor.systemGreenColor;

    _metadataStack = [[UIStackView alloc] initWithArrangedSubviews:@[_authorizationLabel]];
    _metadataStack.translatesAutoresizingMaskIntoConstraints = NO;
    _metadataStack.axis = UILayoutConstraintAxisHorizontal;
    _metadataStack.alignment = UIStackViewAlignmentCenter;
    _metadataStack.spacing = 14.0;
    [self addSubview:_metadataStack];
    [self applyProfileWithWXID:nil nickname:nil headURL:nil];
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
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *wxid = NeoWCCurrentUserWXID();
        NSString *nickname = NeoWCCurrentUserNickname();
        NSString *headURL = NeoWCCurrentUserHeadImageURL();
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf applyProfileWithWXID:wxid nickname:nickname headURL:headURL];
        });
    });
}

- (void)applyProfileWithWXID:(NSString *)wxid
                    nickname:(NSString *)nickname
                     headURL:(NSString *)headURL {
    self.wxid = wxid;
    NSString *displayNickname = nickname.length > 0 ? nickname : @"微信用户";
    BOOL isAuthor = NeoWCAuthorizationIsCurrentUserAdministrator();
    if (isAuthor) {
        NSString *authorTitle = [NSString stringWithFormat:@"%@  作者", displayNickname];
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:authorTitle];
        [attributedTitle addAttribute:NSForegroundColorAttributeName
                                value:UIColor.systemYellowColor
                                range:NSMakeRange(0, displayNickname.length)];
        [attributedTitle addAttribute:NSForegroundColorAttributeName
                                value:UIColor.secondaryLabelColor
                                range:NSMakeRange(displayNickname.length + 2, 2)];
        self.nicknameLabel.attributedText = attributedTitle;
    } else {
        self.nicknameLabel.attributedText = nil;
        self.nicknameLabel.textColor = UIColor.labelColor;
        self.nicknameLabel.text = displayNickname;
    }
    self.wxidLabel.text = self.wxid.length > 0 ? self.wxid : @"wxid 未获取";
    self.authorizationLabel.text = NeoWCAuthorizationAllowsCoreFeatures() ? @"✓ 已授权" : @"未授权";
    self.authorizationLabel.textColor = NeoWCAuthorizationAllowsCoreFeatures() ? UIColor.systemGreenColor : UIColor.systemRedColor;
    self.accessibilityLabel = [NSString stringWithFormat:@"%@%@，%@，%@",
                               displayNickname, isAuthor ? @"，作者" : @"",
                               self.wxidLabel.text, self.authorizationLabel.text];
    self.accessibilityHint = self.wxid.length > 0 ? @"轻点复制 wxid" : nil;

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
        [self.metadataStack.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.metadataStack.topAnchor constraintEqualToAnchor:self.wxidLabel.bottomAnchor constant:9.0],
        [self.metadataStack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:20.0],
        [self.metadataStack.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-20.0],
        [self.metadataStack.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-16.0],
    ];
    [NSLayoutConstraint activateConstraints:self.avatarConstraints];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width scale:(CGFloat)scale {
    CGFloat textWidth = MAX(120.0, width - 48.0);
    CGFloat nicknameHeight = [self.nicknameLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height;
    CGFloat wxidHeight = [self.wxidLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height;
    CGFloat metadataHeight = [self.metadataStack systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    CGFloat contentHeight = 18.0 + 92.0 + 10.0 + nicknameHeight + 4.0 + wxidHeight + 9.0 + metadataHeight + 16.0;
    return MAX(contentHeight, 212.0 * scale);
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
