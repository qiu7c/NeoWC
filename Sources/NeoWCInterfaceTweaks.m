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

static NSHashTable<UIView *> *NeoWCTrackedGlobalAvatarViews(void) {
    static NSHashTable<UIView *> *views;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ views = [NSHashTable weakObjectsHashTable]; });
    return views;
}

static NSHashTable<UIView *> *NeoWCTrackedGlobalAvatarTargets(void) {
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

static UIView *NeoWCGlobalAvatarImageTarget(UIView *headView) {
    UIView *imageView = NeoWCInterfaceViewValue(headView, @[@"headImageView", @"_headImageView"]);
    return imageView ?: headView;
}

static CGFloat NeoWCGlobalAvatarCornerRatio(void) {
    NeoWCRegisterGlobalAvatarDefaults();
    CGFloat percent = [NSUserDefaults.standardUserDefaults doubleForKey:NeoWCGlobalAvatarCornerPercentKey];
    return MIN(100.0, MAX(0.0, percent)) / 100.0;
}

void NeoWCApplyGlobalAvatarRoundingToHeadView(UIView *headView) {
    if (!headView) return;
    [NeoWCTrackedGlobalAvatarViews() addObject:headView];
    UIView *target = NeoWCGlobalAvatarImageTarget(headView);
    if (!target) return;
    [NeoWCTrackedGlobalAvatarTargets() addObject:target];

    NeoWCRegisterGlobalAvatarDefaults();
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCGlobalAvatarRoundingEnabledKey);
    NSNumber *saved = objc_getAssociatedObject(target, &NeoWCGlobalAvatarStateSavedKey);
    if (!enabled) {
        if (!saved.boolValue) return;
        target.layer.cornerRadius = [objc_getAssociatedObject(target, &NeoWCGlobalAvatarOriginalCornerRadiusKey) doubleValue];
        target.layer.masksToBounds = [objc_getAssociatedObject(target, &NeoWCGlobalAvatarOriginalMasksToBoundsKey) boolValue];
        NSString *curve = objc_getAssociatedObject(target, &NeoWCGlobalAvatarOriginalCornerCurveKey);
        if (curve.length > 0) target.layer.cornerCurve = curve;
        objc_setAssociatedObject(target, &NeoWCGlobalAvatarStateSavedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(target, &NeoWCGlobalAvatarOriginalCornerRadiusKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(target, &NeoWCGlobalAvatarOriginalMasksToBoundsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(target, &NeoWCGlobalAvatarOriginalCornerCurveKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    if (!saved.boolValue) {
        objc_setAssociatedObject(target, &NeoWCGlobalAvatarOriginalCornerRadiusKey, @(target.layer.cornerRadius), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(target, &NeoWCGlobalAvatarOriginalMasksToBoundsKey, @(target.layer.masksToBounds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(target, &NeoWCGlobalAvatarOriginalCornerCurveKey,
                                 target.layer.cornerCurve ?: kCACornerCurveCircular,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(target, &NeoWCGlobalAvatarStateSavedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat width = CGRectGetWidth(target.bounds);
    CGFloat height = CGRectGetHeight(target.bounds);
    if (width <= 0.0 || height <= 0.0) return;
    CGFloat radius = MIN(width, height) * 0.5 * NeoWCGlobalAvatarCornerRatio();
    if (fabs(target.layer.cornerRadius - radius) > 0.01) target.layer.cornerRadius = radius;
    if (![target.layer.cornerCurve isEqualToString:kCACornerCurveContinuous]) target.layer.cornerCurve = kCACornerCurveContinuous;
    if (!target.layer.masksToBounds) target.layer.masksToBounds = YES;
}

void NeoWCRefreshTrackedGlobalAvatarViews(void) {
    for (UIView *headView in NeoWCTrackedGlobalAvatarViews().allObjects) {
        NeoWCApplyGlobalAvatarRoundingToHeadView(headView);
    }
    // An MMHeadImageView can replace its inner image view after an asynchronous
    // avatar download. Keep the old target weakly tracked so disabling the
    // feature restores every layer NeoWC actually changed.
    for (UIView *target in NeoWCTrackedGlobalAvatarTargets().allObjects) {
        NeoWCApplyGlobalAvatarRoundingToHeadView(target);
    }
}

unsigned int NeoWCGlobalAvatarScaledCornerSize(unsigned int originalSize) {
    NeoWCRegisterGlobalAvatarDefaults();
    if (!NeoWCEnhancementEnabled(NeoWCGlobalAvatarRoundingEnabledKey)) return originalSize;
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
