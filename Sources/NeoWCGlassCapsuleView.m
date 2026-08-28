#import "NeoWCGlassCapsuleView.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface NeoWCGlassCapsuleView ()
@property (nonatomic, strong, readwrite) UIVisualEffectView *effectView;
@property (nonatomic, strong) UIView *tintView;
@property (nonatomic, strong) UIView *whiteWashView;
@property (nonatomic, strong, nullable) UIViewPropertyAnimator *blurAnimator;
@property (nonatomic, assign) BOOL capsuleShadowEnabled;
@property (nonatomic, assign) CGFloat appliedBlurIntensity;
@property (nonatomic, strong, nullable) UIColor *appliedTintColor;
@property (nonatomic, assign) CGFloat appliedTintOpacity;
@property (nonatomic, assign) CGFloat appliedWhiteStrength;
@end

@implementation NeoWCGlassCapsuleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = NO;
    _appliedBlurIntensity = -1.0;

    _effectView = [[UIVisualEffectView alloc] initWithEffect:nil];
    _effectView.userInteractionEnabled = YES;
    _effectView.clipsToBounds = YES;
    _effectView.layer.borderWidth = 0.5;
    [self addSubview:_effectView];

    _tintView = [UIView new];
    _tintView.userInteractionEnabled = NO;
    [_effectView.contentView addSubview:_tintView];

    _whiteWashView = [UIView new];
    _whiteWashView.userInteractionEnabled = NO;
    _whiteWashView.backgroundColor = UIColor.whiteColor;
    [_effectView.contentView addSubview:_whiteWashView];

    [self applyTraitColors];
    return self;
}

- (void)dealloc {
    [self.blurAnimator stopAnimation:YES];
}

- (void)configureShadowEnabled:(BOOL)enabled {
    self.capsuleShadowEnabled = enabled;
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowOpacity = enabled ? 0.075 : 0.0;
    self.layer.shadowRadius = enabled ? 7.0 : 0.0;
    self.layer.shadowOffset = enabled ? CGSizeMake(0.0, 2.0) : CGSizeZero;
    [self updateCapsuleGeometry];
}

- (void)configureFrostedGlassWithBlurIntensity:(CGFloat)blurIntensity
                                      tintColor:(UIColor *)tintColor
                                    tintOpacity:(CGFloat)tintOpacity
                                  whiteStrength:(CGFloat)whiteStrength {
    CGFloat intensity = MIN(1.0, MAX(0.20, blurIntensity));
    CGFloat resolvedTintOpacity = MIN(1.0, MAX(0.0, tintOpacity));
    CGFloat resolvedWhiteStrength = MIN(1.0, MAX(0.0, whiteStrength));
    UIColor *resolvedTintColor = tintColor ?: UIColor.systemBackgroundColor;
    if (fabs(self.appliedBlurIntensity - intensity) < 0.001 &&
        fabs(self.appliedTintOpacity - resolvedTintOpacity) < 0.001 &&
        fabs(self.appliedWhiteStrength - resolvedWhiteStrength) < 0.001 &&
        [self.appliedTintColor isEqual:resolvedTintColor]) return;

    self.appliedBlurIntensity = intensity;
    self.appliedTintColor = resolvedTintColor;
    self.appliedTintOpacity = resolvedTintOpacity;
    self.appliedWhiteStrength = resolvedWhiteStrength;
    [self.blurAnimator stopAnimation:YES];
    self.blurAnimator = nil;
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    if (intensity >= 0.999) {
        self.effectView.effect = effect;
    } else {
        self.effectView.effect = nil;
        __weak UIVisualEffectView *weakEffectView = self.effectView;
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc]
            initWithDuration:1.0 curve:UIViewAnimationCurveLinear animations:^{
                weakEffectView.effect = effect;
            }];
        [animator startAnimation];
        [animator pauseAnimation];
        animator.fractionComplete = intensity;
        self.blurAnimator = animator;
    }
    self.tintView.backgroundColor = resolvedTintColor;
    self.tintView.alpha = resolvedTintOpacity;
    self.whiteWashView.alpha = resolvedWhiteStrength;
    [self applyTraitColors];
}

- (void)applyTraitColors {
    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    self.effectView.layer.borderColor = (dark
        ? [UIColor.whiteColor colorWithAlphaComponent:0.14]
        : [UIColor.blackColor colorWithAlphaComponent:0.10]).CGColor;
}

- (void)updateCapsuleGeometry {
    CGRect bounds = self.bounds;
    CGFloat radius = self.capsuleCornerRadius > 0.0 ? self.capsuleCornerRadius : CGRectGetHeight(bounds) * 0.5;
    self.effectView.frame = bounds;
    self.effectView.layer.cornerRadius = radius;
    self.effectView.layer.cornerCurve = kCACornerCurveContinuous;
    self.tintView.frame = self.effectView.contentView.bounds;
    self.whiteWashView.frame = self.effectView.contentView.bounds;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:radius];
    self.layer.shadowPath = self.capsuleShadowEnabled ? path.CGPath : nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateCapsuleGeometry];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
        [self applyTraitColors];
    }
}

@end
