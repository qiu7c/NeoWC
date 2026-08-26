#import "NeoWCInterfaceTweaks.h"

#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "NeoWCCompatibility.h"
#import "NeoWCEnhancements.h"

NSString *const NeoWCChatInputRoundingEnabledKey = @"com.qiu7c.neowc.interface.chat-input-rounding";
NSString *const NeoWCChatInputInnerRoundingKey = @"com.qiu7c.neowc.interface.chat-input-rounding.inner";
NSString *const NeoWCChatInputOuterRoundingKey = @"com.qiu7c.neowc.interface.chat-input-rounding.outer";
NSString *const NeoWCChatInputInnerRadiusKey = @"com.qiu7c.neowc.interface.chat-input-rounding.inner-radius";
NSString *const NeoWCChatInputOuterRadiusKey = @"com.qiu7c.neowc.interface.chat-input-rounding.outer-radius";
NSString *const NeoWCHideChatMuteIconKey = @"com.qiu7c.neowc.interface.hide-chat-mute-icon";
NSString *const NeoWCGlobalAvatarRoundingEnabledKey = @"com.qiu7c.neowc.interface.global-avatar-rounding";
NSString *const NeoWCGlobalAvatarCornerPercentKey = @"com.qiu7c.neowc.interface.global-avatar-corner-percent";

static UIColor *NeoWCEffectiveBackgroundColorForView(UIView *view) {
    for (UIView *candidate = view; candidate; candidate = candidate.superview) {
        UIColor *color = candidate.backgroundColor;
        if (color && CGColorGetAlpha(color.CGColor) > 0.01) return color;
    }
    return UIColor.systemGroupedBackgroundColor;
}

static void NeoWCMatchSearchBarChrome(UIView *view, UITextField *textField, UIColor *backgroundColor) {
    for (UIView *subview in view.subviews) {
        NSString *className = NSStringFromClass(subview.class);
        if ([className containsString:@"UISearchBarBackground"] ||
            [className isEqualToString:@"_UISearchBarBackground"]) {
            subview.hidden = NO;
            subview.alpha = 1.0;
            subview.backgroundColor = backgroundColor;
            subview.layer.backgroundColor = backgroundColor.CGColor;
            if ([subview isKindOfClass:UIImageView.class]) {
                ((UIImageView *)subview).image = nil;
            }
        }
        if (subview != textField && ![subview isDescendantOfView:textField]) {
            NeoWCMatchSearchBarChrome(subview, textField, backgroundColor);
        }
    }
}

static UIImage *NeoWCTransparentSearchBackgroundImage(void) {
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(1.0, 1.0), NO, 0.0);
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return image;
}

@interface NeoWCSearchTableHeaderView : UIView
@property (nonatomic, weak) UISearchBar *searchBar;
@end

@implementation NeoWCSearchTableHeaderView

- (void)layoutSubviews {
    [super layoutSubviews];
    UISearchBar *searchBar = self.searchBar;
    if (!searchBar) return;
    searchBar.frame = CGRectMake(0.0, 4.0, CGRectGetWidth(self.bounds),
                                 MAX(0.0, CGRectGetHeight(self.bounds) - 8.0));
    UIColor *backgroundColor = NeoWCEffectiveBackgroundColorForView(self);
    searchBar.backgroundColor = backgroundColor;
    searchBar.layer.backgroundColor = backgroundColor.CGColor;
    NeoWCMatchSearchBarChrome(searchBar, searchBar.searchTextField, backgroundColor);
}

@end

void NeoWCStyleSearchBar(UISearchBar *searchBar) {
    if (!searchBar) return;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    UIImage *transparentImage = NeoWCTransparentSearchBackgroundImage();
    searchBar.backgroundImage = transparentImage;
    searchBar.scopeBarBackgroundImage = transparentImage;
    UIColor *backgroundColor = NeoWCEffectiveBackgroundColorForView(searchBar.superview);
    searchBar.backgroundColor = backgroundColor;
    searchBar.barTintColor = backgroundColor;
    searchBar.translucent = NO;
    searchBar.opaque = NO;
    searchBar.layer.backgroundColor = backgroundColor.CGColor;
    UITextField *textField = searchBar.searchTextField;
    NeoWCMatchSearchBarChrome(searchBar, textField, backgroundColor);
    textField.backgroundColor = UIColor.secondarySystemFillColor;
    textField.layer.backgroundColor = UIColor.secondarySystemFillColor.CGColor;
    textField.borderStyle = UITextBorderStyleNone;
    textField.layer.cornerRadius = 14.0;
    textField.layer.cornerCurve = kCACornerCurveContinuous;
    textField.layer.masksToBounds = YES;
}

void NeoWCInstallSearchBarInTableView(UISearchBar *searchBar, UITableView *tableView) {
    if (!searchBar || !tableView) return;
    CGFloat width = CGRectGetWidth(tableView.bounds);
    NeoWCSearchTableHeaderView *header = [[NeoWCSearchTableHeaderView alloc]
        initWithFrame:CGRectMake(0.0, 0.0, width, 60.0)];
    UIColor *backgroundColor = NeoWCEffectiveBackgroundColorForView(tableView);
    header.backgroundColor = backgroundColor;
    header.layer.backgroundColor = backgroundColor.CGColor;
    header.opaque = YES;
    header.searchBar = searchBar;
    searchBar.frame = CGRectMake(0.0, 4.0, width, 52.0);
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:searchBar];
    NeoWCStyleSearchBar(searchBar);
    tableView.tableHeaderView = header;
}

static char NeoWCOriginalCornerRadiusKey;
static char NeoWCOriginalMasksToBoundsKey;
static char NeoWCOriginalCornerCurveKey;
static char NeoWCRoundingStateSavedKey;
static char NeoWCRoundingAppliedToToolViewKey;
static char NeoWCRoundingConfigurationKey;
static char NeoWCOriginalMuteIconHiddenKey;
static char NeoWCOriginalMuteMemberLabelHiddenKey;
static char NeoWCGlobalAvatarOriginalCornerRadiusKey;
static char NeoWCGlobalAvatarOriginalMasksToBoundsKey;
static char NeoWCGlobalAvatarOriginalCornerCurveKey;
static char NeoWCGlobalAvatarStateSavedKey;
static char NeoWCGlobalAvatarTargetViewKey;
static char NeoWCGlobalAvatarExcludedKey;
static BOOL NeoWCGlobalAvatarConfigurationEnabled = NO;
static CGFloat NeoWCGlobalAvatarConfigurationRatio = 1.0;

static NSHashTable<UIView *> *NeoWCTrackedGlobalAvatarViews(void) {
    static NSHashTable<UIView *> *views;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ views = [NSHashTable weakObjectsHashTable]; });
    return views;
}

static void NeoWCRegisterGlobalAvatarDefaults(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSUserDefaults.standardUserDefaults registerDefaults:@{
            NeoWCGlobalAvatarRoundingEnabledKey: @NO,
            NeoWCGlobalAvatarCornerPercentKey: @100.0,
        }];
    });
}

static void NeoWCReloadGlobalAvatarConfiguration(void) {
    NeoWCRegisterGlobalAvatarDefaults();
    NeoWCGlobalAvatarConfigurationEnabled = NeoWCEnhancementEnabled(NeoWCGlobalAvatarRoundingEnabledKey);
    CGFloat percent = [NSUserDefaults.standardUserDefaults doubleForKey:NeoWCGlobalAvatarCornerPercentKey];
    NeoWCGlobalAvatarConfigurationRatio = MIN(100.0, MAX(0.0, percent)) / 100.0;
}

static void NeoWCEnsureGlobalAvatarConfiguration(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ NeoWCReloadGlobalAvatarConfiguration(); });
}

static NSHashTable<UIImageView *> *NeoWCHiddenMuteImageViews(void) {
    static NSHashTable<UIImageView *> *imageViews;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageViews = [NSHashTable weakObjectsHashTable];
    });
    return imageViews;
}

static NSHashTable<UILabel *> *NeoWCHiddenMuteMemberLabels(void) {
    static NSHashTable<UILabel *> *labels;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        labels = [NSHashTable weakObjectsHashTable];
    });
    return labels;
}

static void NeoWCRegisterChatInputRoundingDefaults(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{
            NeoWCChatInputRoundingEnabledKey: @NO,
            NeoWCChatInputInnerRoundingKey: @YES,
            NeoWCChatInputOuterRoundingKey: @YES,
            NeoWCChatInputInnerRadiusKey: @18.0,
            NeoWCChatInputOuterRadiusKey: @22.0,
        }];
    });
}

static id NeoWCInterfaceSafeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static UIView *NeoWCInterfaceViewValue(id object, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = NeoWCInterfaceSafeValue(object, key);
        if ([value isKindOfClass:[UIView class]]) return value;
    }
    return nil;
}

static CGFloat NeoWCGlobalAvatarCornerRatio(void) {
    NeoWCEnsureGlobalAvatarConfiguration();
    return NeoWCGlobalAvatarConfigurationRatio;
}

static UIView *NeoWCGlobalAvatarTargetView(UIView *headView) {
    SEL selector = NSSelectorFromString(@"headImageView");
    if ([headView respondsToSelector:selector]) {
        id target = ((id (*)(id, SEL))objc_msgSend)(headView, selector);
        if ([target isKindOfClass:UIView.class]) return target;
    }
    return headView;
}

static void NeoWCRestoreGlobalAvatarRounding(UIView *headView) {
    UIView *target = objc_getAssociatedObject(headView, &NeoWCGlobalAvatarTargetViewKey);
    if (!target) target = headView;
    if (![objc_getAssociatedObject(headView, &NeoWCGlobalAvatarStateSavedKey) boolValue]) return;
    target.layer.cornerRadius = [objc_getAssociatedObject(headView, &NeoWCGlobalAvatarOriginalCornerRadiusKey) doubleValue];
    target.layer.masksToBounds = [objc_getAssociatedObject(headView, &NeoWCGlobalAvatarOriginalMasksToBoundsKey) boolValue];
    NSString *curve = objc_getAssociatedObject(headView, &NeoWCGlobalAvatarOriginalCornerCurveKey);
    if (curve.length > 0) target.layer.cornerCurve = curve;
    objc_setAssociatedObject(headView, &NeoWCGlobalAvatarStateSavedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(headView, &NeoWCGlobalAvatarTargetViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(headView, &NeoWCGlobalAvatarOriginalCornerRadiusKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(headView, &NeoWCGlobalAvatarOriginalMasksToBoundsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(headView, &NeoWCGlobalAvatarOriginalCornerCurveKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

BOOL NeoWCHeadViewIsExcludedFromGlobalAvatarRounding(UIView *headView) {
    return [objc_getAssociatedObject(headView, &NeoWCGlobalAvatarExcludedKey) boolValue];
}

void NeoWCExcludeHeadViewFromGlobalAvatarRounding(UIView *headView) {
    if (!headView) return;
    objc_setAssociatedObject(headView, &NeoWCGlobalAvatarExcludedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCRestoreGlobalAvatarRounding(headView);
    [NeoWCTrackedGlobalAvatarViews() removeObject:headView];
}

void NeoWCApplyGlobalAvatarRoundingToHeadView(UIView *headView) {
    if (!headView) return;
    NeoWCEnsureGlobalAvatarConfiguration();
    if (NeoWCHeadViewIsExcludedFromGlobalAvatarRounding(headView)) {
        NeoWCRestoreGlobalAvatarRounding(headView);
        [NeoWCTrackedGlobalAvatarViews() removeObject:headView];
        return;
    }
    [NeoWCTrackedGlobalAvatarViews() addObject:headView];
    NSNumber *saved = objc_getAssociatedObject(headView, &NeoWCGlobalAvatarStateSavedKey);
    if (!NeoWCGlobalAvatarConfigurationEnabled) {
        if (!saved.boolValue) return;
        NeoWCRestoreGlobalAvatarRounding(headView);
        return;
    }
    UIView *target = NeoWCGlobalAvatarTargetView(headView);
    UIView *savedTarget = objc_getAssociatedObject(headView, &NeoWCGlobalAvatarTargetViewKey);
    if (saved.boolValue && savedTarget != target) {
        NeoWCRestoreGlobalAvatarRounding(headView);
        saved = nil;
    }
    if (!saved.boolValue) {
        objc_setAssociatedObject(headView, &NeoWCGlobalAvatarTargetViewKey,
                                 target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(headView, &NeoWCGlobalAvatarOriginalCornerRadiusKey,
                                 @(target.layer.cornerRadius), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(headView, &NeoWCGlobalAvatarOriginalMasksToBoundsKey,
                                 @(target.layer.masksToBounds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(headView, &NeoWCGlobalAvatarOriginalCornerCurveKey,
                                 target.layer.cornerCurve ?: kCACornerCurveCircular,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(headView, &NeoWCGlobalAvatarStateSavedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CGFloat width = CGRectGetWidth(target.bounds);
    CGFloat height = CGRectGetHeight(target.bounds);
    if (width <= 0.0 || height <= 0.0) return;
    CGFloat radius = MIN(width, height) * 0.5 * NeoWCGlobalAvatarCornerRatio();
    if (fabs(target.layer.cornerRadius - radius) > 0.01) target.layer.cornerRadius = radius;
    if (![target.layer.cornerCurve isEqualToString:kCACornerCurveContinuous]) {
        target.layer.cornerCurve = kCACornerCurveContinuous;
    }
    if (!target.layer.masksToBounds) target.layer.masksToBounds = YES;
}

void NeoWCRefreshTrackedGlobalAvatarViews(void) {
    NeoWCReloadGlobalAvatarConfiguration();
    for (UIView *headView in NeoWCTrackedGlobalAvatarViews().allObjects) {
        NeoWCApplyGlobalAvatarRoundingToHeadView(headView);
    }
}

unsigned int NeoWCGlobalAvatarScaledCornerSize(unsigned int originalSize) {
    NeoWCEnsureGlobalAvatarConfiguration();
    if (!NeoWCGlobalAvatarConfigurationEnabled) return originalSize;
    return (unsigned int)lrint((double)originalSize * NeoWCGlobalAvatarCornerRatio());
}

static UIView *NeoWCFindSubviewOfClassName(UIView *view, NSString *className) {
    if (!view) return nil;
    if ([NSStringFromClass(view.class) isEqualToString:className]) return view;
    for (UIView *subview in view.subviews) {
        UIView *match = NeoWCFindSubviewOfClassName(subview, className);
        if (match) return match;
    }
    return nil;
}

static void NeoWCSetRoundedState(UIView *view, BOOL enabled, CGFloat maximumRadius) {
    if (!view) return;
    if (enabled) {
        if (![objc_getAssociatedObject(view, &NeoWCRoundingStateSavedKey) boolValue]) {
            objc_setAssociatedObject(view, &NeoWCOriginalCornerRadiusKey, @(view.layer.cornerRadius), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(view, &NeoWCOriginalMasksToBoundsKey, @(view.layer.masksToBounds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(view, &NeoWCOriginalCornerCurveKey, view.layer.cornerCurve ?: kCACornerCurveCircular, OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(view, &NeoWCRoundingStateSavedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        CGFloat height = CGRectGetHeight(view.bounds);
        CGFloat radius = height > 0.0 ? MIN(maximumRadius, height * 0.5) : maximumRadius;
        if (ABS(view.layer.cornerRadius - radius) > 0.01) view.layer.cornerRadius = radius;
        if (![view.layer.cornerCurve isEqualToString:kCACornerCurveContinuous]) view.layer.cornerCurve = kCACornerCurveContinuous;
        if (!view.layer.masksToBounds) view.layer.masksToBounds = YES;
        return;
    }
    if (![objc_getAssociatedObject(view, &NeoWCRoundingStateSavedKey) boolValue]) return;
    view.layer.cornerRadius = [objc_getAssociatedObject(view, &NeoWCOriginalCornerRadiusKey) doubleValue];
    view.layer.masksToBounds = [objc_getAssociatedObject(view, &NeoWCOriginalMasksToBoundsKey) boolValue];
    NSString *cornerCurve = objc_getAssociatedObject(view, &NeoWCOriginalCornerCurveKey);
    if (cornerCurve.length > 0) view.layer.cornerCurve = cornerCurve;
    objc_setAssociatedObject(view, &NeoWCRoundingStateSavedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(view, &NeoWCOriginalCornerRadiusKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(view, &NeoWCOriginalMasksToBoundsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(view, &NeoWCOriginalCornerCurveKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void NeoWCApplyChatInputRoundingToToolView(UIView *inputToolView) {
    if (!inputToolView) return;
    // Register fallback values on the chat path itself. The settings controller may
    // never have been opened in this process, especially immediately after launch.
    NeoWCRegisterChatInputRoundingDefaults();
    static dispatch_once_t compatibilityOnce;
    dispatch_once(&compatibilityOnce, ^{ NeoWCCompatibilityMarkTriggered(@"input-rounding"); });

    BOOL masterEnabled = NeoWCEnhancementEnabled(NeoWCChatInputRoundingEnabledKey);
    BOOL wasApplied = [objc_getAssociatedObject(inputToolView, &NeoWCRoundingAppliedToToolViewKey) boolValue];
    // The common disabled path must not walk WeChat's input hierarchy during a
    // chat transition. Only revisit the hierarchy when there is state to restore.
    if (!masterEnabled && !wasApplied) return;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL innerEnabled = masterEnabled && [defaults boolForKey:NeoWCChatInputInnerRoundingKey];
    BOOL outerEnabled = masterEnabled && [defaults boolForKey:NeoWCChatInputOuterRoundingKey];
    CGFloat innerRadius = [defaults objectForKey:NeoWCChatInputInnerRadiusKey] ? [defaults doubleForKey:NeoWCChatInputInnerRadiusKey] : 18.0;
    CGFloat outerRadius = [defaults objectForKey:NeoWCChatInputOuterRadiusKey] ? [defaults doubleForKey:NeoWCChatInputOuterRadiusKey] : 22.0;
    NSString *configuration = masterEnabled
        ? [NSString stringWithFormat:@"%d:%d:%.2f:%.2f", innerEnabled, outerEnabled, innerRadius, outerRadius]
        : nil;
    if (wasApplied && [configuration isEqualToString:objc_getAssociatedObject(inputToolView, &NeoWCRoundingConfigurationKey)]) return;

    // Verified on the current WeChat build: the first UIView under MMInputToolView
    // is the visible outer toolbar background.
    UIView *outerBar = inputToolView.subviews.firstObject;
    UIView *growTextView = NeoWCInterfaceViewValue(inputToolView, @[@"textView", @"_textView"]);
    if (![NSStringFromClass(growTextView.class) containsString:@"MMGrowTextView"]) {
        growTextView = NeoWCFindSubviewOfClassName(inputToolView, @"MMGrowTextView");
    }

    NeoWCSetRoundedState(growTextView, innerEnabled, MIN(40.0, MAX(0.0, innerRadius)));
    if (outerBar != growTextView) NeoWCSetRoundedState(outerBar, outerEnabled, MIN(40.0, MAX(0.0, outerRadius)));
    objc_setAssociatedObject(inputToolView, &NeoWCRoundingAppliedToToolViewKey,
                             masterEnabled ? @YES : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(inputToolView, &NeoWCRoundingConfigurationKey,
                             configuration, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

void NeoWCRestoreChatInputRoundingFromToolView(UIView *inputToolView) {
    if (!inputToolView) return;
    UIView *outerBar = inputToolView.subviews.firstObject;
    UIView *growTextView = NeoWCInterfaceViewValue(inputToolView, @[@"textView", @"_textView"]);
    if (![NSStringFromClass(growTextView.class) containsString:@"MMGrowTextView"]) {
        growTextView = NeoWCFindSubviewOfClassName(inputToolView, @"MMGrowTextView");
    }
    NeoWCSetRoundedState(growTextView, NO, 0.0);
    if (outerBar != growTextView) NeoWCSetRoundedState(outerBar, NO, 0.0);
}

BOOL NeoWCShouldForceHideChatMuteImageView(UIImageView *imageView) {
    if (![imageView.accessibilityLabel isEqualToString:@"免打扰"]) return NO;
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ NeoWCHideChatMuteIconKey: @NO }];
    return NeoWCEnhancementEnabled(NeoWCHideChatMuteIconKey);
}

BOOL NeoWCShouldKeepManagedChatMuteImageViewHidden(UIImageView *imageView) {
    if (!objc_getAssociatedObject(imageView, &NeoWCOriginalMuteIconHiddenKey)) return NO;
    return NeoWCEnhancementEnabled(NeoWCHideChatMuteIconKey);
}

static UIImageView *NeoWCChatMuteImageViewBesideLabel(UILabel *label) {
    UIView *container = label.superview;
    if (!container || ![NSStringFromClass(label.class) isEqualToString:@"MMUILabel"]) return nil;
    NSString *text = label.text;
    if (text.length < 3 || ![text hasPrefix:@"("] || ![text hasSuffix:@")"]) return nil;
    NSString *memberCount = [text substringWithRange:NSMakeRange(1, text.length - 2)];
    NSCharacterSet *nonDigits = [NSCharacterSet decimalDigitCharacterSet].invertedSet;
    if (memberCount.length == 0 ||
        [memberCount rangeOfCharacterFromSet:nonDigits].location != NSNotFound) return nil;
    CGRect labelFrame = label.frame;
    for (UIView *subview in container.subviews) {
        if (![subview isKindOfClass:[UIImageView class]]) continue;
        UIImageView *imageView = (UIImageView *)subview;
        if (![imageView.accessibilityLabel isEqualToString:@"免打扰"]) continue;
        CGRect imageFrame = imageView.frame;
        BOOL immediatelyBeforeIcon = CGRectGetMaxX(labelFrame) <= CGRectGetMinX(imageFrame) + 2.0 &&
                                     CGRectGetMinX(imageFrame) - CGRectGetMaxX(labelFrame) <= 8.0;
        BOOL verticallyAligned = CGRectGetMaxY(labelFrame) > CGRectGetMinY(imageFrame) &&
                                 CGRectGetMinY(labelFrame) < CGRectGetMaxY(imageFrame);
        if (immediatelyBeforeIcon && verticallyAligned) return imageView;
    }
    return nil;
}

BOOL NeoWCShouldKeepManagedChatMuteMemberLabelHidden(UILabel *label) {
    if (!objc_getAssociatedObject(label, &NeoWCOriginalMuteMemberLabelHiddenKey)) return NO;
    return NeoWCEnhancementEnabled(NeoWCHideChatMuteIconKey);
}

void NeoWCUpdateChatMuteMemberLabel(UILabel *label) {
    if (!label) return;
    NSNumber *savedHidden = objc_getAssociatedObject(label, &NeoWCOriginalMuteMemberLabelHiddenKey);
    BOOL shouldHide = NeoWCEnhancementEnabled(NeoWCHideChatMuteIconKey) &&
                      NeoWCChatMuteImageViewBesideLabel(label) != nil;
    if (shouldHide) {
        if (!savedHidden) {
            objc_setAssociatedObject(label, &NeoWCOriginalMuteMemberLabelHiddenKey,
                                     @(label.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [NeoWCHiddenMuteMemberLabels() addObject:label];
        label.hidden = YES;
    } else if (savedHidden) {
        label.hidden = savedHidden.boolValue;
        [NeoWCHiddenMuteMemberLabels() removeObject:label];
        objc_setAssociatedObject(label, &NeoWCOriginalMuteMemberLabelHiddenKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

void NeoWCUpdateChatMuteImageView(UIImageView *imageView) {
    if (!imageView) return;
    NSNumber *savedHidden = objc_getAssociatedObject(imageView, &NeoWCOriginalMuteIconHiddenKey);
    if (NeoWCShouldForceHideChatMuteImageView(imageView)) {
        static dispatch_once_t compatibilityOnce;
        dispatch_once(&compatibilityOnce, ^{ NeoWCCompatibilityMarkTriggered(@"hide-chat-mute-icon"); });
        if (!savedHidden) {
            objc_setAssociatedObject(imageView, &NeoWCOriginalMuteIconHiddenKey, @(imageView.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [NeoWCHiddenMuteImageViews() addObject:imageView];
        imageView.hidden = YES;
    } else if (savedHidden) {
        imageView.hidden = savedHidden.boolValue;
        [NeoWCHiddenMuteImageViews() removeObject:imageView];
        objc_setAssociatedObject(imageView, &NeoWCOriginalMuteIconHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    for (UIView *subview in imageView.superview.subviews) {
        if ([NSStringFromClass(subview.class) isEqualToString:@"MMUILabel"]) {
            NeoWCUpdateChatMuteMemberLabel((UILabel *)subview);
        }
    }
}

static void NeoWCUpdateMuteIconInView(UIView *view) {
    if (!view) return;
    if ([view isKindOfClass:[UIImageView class]]) NeoWCUpdateChatMuteImageView((UIImageView *)view);
    for (UIView *subview in view.subviews) NeoWCUpdateMuteIconInView(subview);
}

void NeoWCUpdateChatMuteIconVisibility(UIViewController *controller) {
    if (!controller.isViewLoaded) return;
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ NeoWCHideChatMuteIconKey: @NO }];
    BOOL hideIcon = NeoWCEnhancementEnabled(NeoWCHideChatMuteIconKey);
    if (!hideIcon) {
        // Restore only views that NeoWC actually changed. Do not recursively scan
        // the full chat hierarchy while the feature is disabled.
        for (UIImageView *imageView in NeoWCHiddenMuteImageViews().allObjects) {
            NeoWCUpdateChatMuteImageView(imageView);
        }
        for (UILabel *label in NeoWCHiddenMuteMemberLabels().allObjects) {
            NeoWCUpdateChatMuteMemberLabel(label);
        }
        return;
    }
    NeoWCUpdateMuteIconInView(controller.view);
    NeoWCUpdateMuteIconInView(controller.navigationController.navigationBar);
    if (hideIcon) NeoWCCompatibilityMarkTriggered(@"hide-chat-mute-icon");
}
