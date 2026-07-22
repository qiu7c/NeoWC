#import "NeoWCInterfaceTweaks.h"

#import <QuartzCore/QuartzCore.h>
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

static char NeoWCOriginalCornerRadiusKey;
static char NeoWCOriginalMasksToBoundsKey;
static char NeoWCOriginalCornerCurveKey;
static char NeoWCRoundingStateSavedKey;
static char NeoWCRoundingAppliedToToolViewKey;
static char NeoWCRoundingConfigurationKey;
static char NeoWCOriginalMuteIconHiddenKey;

static NSHashTable<UIImageView *> *NeoWCHiddenMuteImageViews(void) {
    static NSHashTable<UIImageView *> *imageViews;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageViews = [NSHashTable weakObjectsHashTable];
    });
    return imageViews;
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
        return;
    }
    NeoWCUpdateMuteIconInView(controller.view);
    NeoWCUpdateMuteIconInView(controller.navigationController.navigationBar);
    if (hideIcon) NeoWCCompatibilityMarkTriggered(@"hide-chat-mute-icon");
}
