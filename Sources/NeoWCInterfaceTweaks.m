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
NSString *const NeoWCChatInputCapsuleEnabledKey = @"com.qiu7c.neowc.interface.chat-input-capsule";
NSString *const NeoWCHideChatMuteIconKey = @"com.qiu7c.neowc.interface.hide-chat-mute-icon";

static char NeoWCOriginalCornerRadiusKey;
static char NeoWCOriginalMasksToBoundsKey;
static char NeoWCOriginalCornerCurveKey;
static char NeoWCRoundingStateSavedKey;
static char NeoWCRoundingAppliedToToolViewKey;
static char NeoWCRoundingConfigurationKey;
static char NeoWCInputCapsuleLeftViewKey;
static char NeoWCInputCapsuleRightViewKey;
static char NeoWCInputCapsuleConfigurationKey;
static char NeoWCInputCapsuleOriginalOuterBackgroundKey;
static char NeoWCInputCapsuleOriginalBarBackgroundKey;
static char NeoWCInputCapsuleOriginalGrowBackgroundKey;
static char NeoWCInputCapsuleOriginalBackdropAlphaKey;
static char NeoWCInputCapsuleOriginalInputBackgroundAlphaKey;
static char NeoWCOriginalMuteIconHiddenKey;
static char NeoWCOriginalMuteMemberLabelHiddenKey;

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
            NeoWCChatInputCapsuleEnabledKey: @NO,
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

static id NeoWCNullableObject(id value) {
    return value ?: NSNull.null;
}

static UIColor *NeoWCStoredColor(id owner, const void *key) {
    id value = objc_getAssociatedObject(owner, key);
    return value == NSNull.null ? nil : value;
}

static UIVisualEffectView *NeoWCInputOriginalBackdrop(UIView *outerBar) {
    for (UIView *subview in outerBar.subviews) {
        if ([subview isKindOfClass:UIVisualEffectView.class]) return (UIVisualEffectView *)subview;
    }
    return nil;
}

static UIImageView *NeoWCInputOriginalTextBackground(UIView *growTextView) {
    for (UIView *subview in growTextView.subviews) {
        if (![subview isKindOfClass:UIImageView.class]) continue;
        if (CGRectGetWidth(subview.bounds) + 2.0 >= CGRectGetWidth(growTextView.bounds) &&
            CGRectGetHeight(subview.bounds) + 2.0 >= CGRectGetHeight(growTextView.bounds)) {
            return (UIImageView *)subview;
        }
    }
    return nil;
}

static UIVisualEffect *NeoWCInputCapsuleEffect(void) {
    NSInteger style = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCChatTopBarEffectStyleKey];
    if (style == NeoWCChatTopBarEffectStyleLiquid && NeoWCSystemSupportsNativeLiquidGlass()) {
        Class glassEffectClass = NSClassFromString(@"UIGlassEffect");
        SEL factory = NSSelectorFromString(@"effectWithStyle:");
        if (glassEffectClass && [glassEffectClass respondsToSelector:factory]) {
            UIVisualEffect *effect = ((id (*)(id, SEL, NSInteger))objc_msgSend)(glassEffectClass,
                                                                                factory,
                                                                                0);
            SEL interactiveSelector = NSSelectorFromString(@"setInteractive:");
            if ([effect respondsToSelector:interactiveSelector]) {
                ((void (*)(id, SEL, BOOL))objc_msgSend)(effect, interactiveSelector, NO);
            }
            if (effect) return effect;
        }
    }
    return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
}

static UIView *NeoWCInputCapsuleView(CGRect frame) {
    UIView *container = [[UIView alloc] initWithFrame:frame];
    container.userInteractionEnabled = NO;
    container.backgroundColor = UIColor.clearColor;
    BOOL shadowEnabled = [NSUserDefaults.standardUserDefaults boolForKey:NeoWCChatTopBarShadowEnabledKey];
    container.layer.shadowColor = UIColor.blackColor.CGColor;
    container.layer.shadowOpacity = shadowEnabled ? 0.04 : 0.0;
    container.layer.shadowRadius = shadowEnabled ? 2.5 : 0.0;
    container.layer.shadowOffset = CGSizeZero;

    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:NeoWCInputCapsuleEffect()];
    effectView.frame = container.bounds;
    effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    effectView.userInteractionEnabled = NO;
    effectView.clipsToBounds = YES;
    effectView.layer.cornerRadius = CGRectGetHeight(frame) * 0.5;
    effectView.layer.cornerCurve = kCACornerCurveContinuous;
    effectView.layer.borderWidth = 0.0;
    effectView.layer.borderColor = UIColor.clearColor.CGColor;
    [container addSubview:effectView];
    return container;
}

void NeoWCRestoreChatInputCapsulesFromToolView(UIView *inputToolView) {
    if (!inputToolView) return;
    UIView *outerBar = inputToolView.subviews.firstObject;
    UIView *bar = NeoWCFindSubviewOfClassName(inputToolView, @"InputToolViewBar");
    UIView *growTextView = NeoWCFindSubviewOfClassName(inputToolView, @"MMGrowTextView");
    UIVisualEffectView *backdrop = NeoWCInputOriginalBackdrop(outerBar);
    UIImageView *inputBackground = NeoWCInputOriginalTextBackground(growTextView);

    [objc_getAssociatedObject(inputToolView, &NeoWCInputCapsuleLeftViewKey) removeFromSuperview];
    [objc_getAssociatedObject(inputToolView, &NeoWCInputCapsuleRightViewKey) removeFromSuperview];
    id outerBackground = objc_getAssociatedObject(inputToolView, &NeoWCInputCapsuleOriginalOuterBackgroundKey);
    id barBackground = objc_getAssociatedObject(inputToolView, &NeoWCInputCapsuleOriginalBarBackgroundKey);
    id growBackground = objc_getAssociatedObject(inputToolView, &NeoWCInputCapsuleOriginalGrowBackgroundKey);
    NSNumber *backdropAlpha = objc_getAssociatedObject(inputToolView, &NeoWCInputCapsuleOriginalBackdropAlphaKey);
    NSNumber *inputBackgroundAlpha = objc_getAssociatedObject(inputToolView, &NeoWCInputCapsuleOriginalInputBackgroundAlphaKey);
    if (outerBackground) outerBar.backgroundColor = NeoWCStoredColor(inputToolView, &NeoWCInputCapsuleOriginalOuterBackgroundKey);
    if (barBackground) bar.backgroundColor = NeoWCStoredColor(inputToolView, &NeoWCInputCapsuleOriginalBarBackgroundKey);
    if (growBackground) growTextView.backgroundColor = NeoWCStoredColor(inputToolView, &NeoWCInputCapsuleOriginalGrowBackgroundKey);
    if (backdropAlpha) backdrop.alpha = backdropAlpha.doubleValue;
    if (inputBackgroundAlpha) inputBackground.alpha = inputBackgroundAlpha.doubleValue;

    const void *keys[] = {&NeoWCInputCapsuleLeftViewKey, &NeoWCInputCapsuleRightViewKey,
                          &NeoWCInputCapsuleConfigurationKey,
                          &NeoWCInputCapsuleOriginalOuterBackgroundKey,
                          &NeoWCInputCapsuleOriginalBarBackgroundKey,
                          &NeoWCInputCapsuleOriginalGrowBackgroundKey,
                          &NeoWCInputCapsuleOriginalBackdropAlphaKey,
                          &NeoWCInputCapsuleOriginalInputBackgroundAlphaKey};
    for (NSUInteger index = 0; index < sizeof(keys) / sizeof(keys[0]); index++) {
        objc_setAssociatedObject(inputToolView, keys[index], nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

void NeoWCApplyChatInputCapsulesToToolView(UIView *inputToolView) {
    if (!inputToolView) return;
    NeoWCRegisterChatInputRoundingDefaults();
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCChatInputCapsuleEnabledKey);
    UIView *existingLeft = objc_getAssociatedObject(inputToolView, &NeoWCInputCapsuleLeftViewKey);
    if (!enabled) {
        if (existingLeft) NeoWCRestoreChatInputCapsulesFromToolView(inputToolView);
        return;
    }

    UIView *outerBar = inputToolView.subviews.firstObject;
    UIView *bar = NeoWCFindSubviewOfClassName(inputToolView, @"InputToolViewBar");
    UIView *growTextView = NeoWCFindSubviewOfClassName(inputToolView, @"MMGrowTextView");
    if (!outerBar || !bar || CGRectGetWidth(bar.bounds) < 160.0) return;
    UIVisualEffectView *backdrop = NeoWCInputOriginalBackdrop(outerBar);
    UIImageView *inputBackground = NeoWCInputOriginalTextBackground(growTextView);
    NSInteger effectStyle = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCChatTopBarEffectStyleKey];
    BOOL shadowEnabled = [NSUserDefaults.standardUserDefaults boolForKey:NeoWCChatTopBarShadowEnabledKey];
    NSString *configuration = [NSString stringWithFormat:@"%ld:%d", (long)effectStyle, shadowEnabled];
    if (existingLeft && [configuration isEqualToString:objc_getAssociatedObject(inputToolView, &NeoWCInputCapsuleConfigurationKey)]) return;
    if (existingLeft) NeoWCRestoreChatInputCapsulesFromToolView(inputToolView);

    objc_setAssociatedObject(inputToolView, &NeoWCInputCapsuleOriginalOuterBackgroundKey,
                             NeoWCNullableObject(outerBar.backgroundColor), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(inputToolView, &NeoWCInputCapsuleOriginalBarBackgroundKey,
                             NeoWCNullableObject(bar.backgroundColor), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(inputToolView, &NeoWCInputCapsuleOriginalGrowBackgroundKey,
                             NeoWCNullableObject(growTextView.backgroundColor), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (backdrop) objc_setAssociatedObject(inputToolView, &NeoWCInputCapsuleOriginalBackdropAlphaKey,
                                           @(backdrop.alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (inputBackground) objc_setAssociatedObject(inputToolView, &NeoWCInputCapsuleOriginalInputBackgroundAlphaKey,
                                                  @(inputBackground.alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    outerBar.backgroundColor = UIColor.clearColor;
    bar.backgroundColor = UIColor.clearColor;
    growTextView.backgroundColor = UIColor.clearColor;
    backdrop.alpha = 0.0;
    inputBackground.alpha = 0.0;

    CGFloat width = CGRectGetWidth(bar.bounds);
    CGFloat height = MAX(32.0, CGRectGetHeight(bar.bounds) - 6.0);
    CGFloat rightWidth = 80.0;
    CGFloat rightX = width - rightWidth - 4.0;
    CGFloat leftX = 4.0;
    CGFloat leftWidth = MAX(80.0, rightX - 4.0 - leftX);
    UIView *left = NeoWCInputCapsuleView(CGRectMake(leftX, 3.0, leftWidth, height));
    UIView *right = NeoWCInputCapsuleView(CGRectMake(rightX, 3.0, rightWidth, height));
    left.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    right.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    [bar insertSubview:left atIndex:0];
    [bar insertSubview:right aboveSubview:left];
    objc_setAssociatedObject(inputToolView, &NeoWCInputCapsuleLeftViewKey, left, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(inputToolView, &NeoWCInputCapsuleRightViewKey, right, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(inputToolView, &NeoWCInputCapsuleConfigurationKey,
                             configuration, OBJC_ASSOCIATION_COPY_NONATOMIC);
    NeoWCCompatibilityMarkTriggered(@"input-capsule");
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
