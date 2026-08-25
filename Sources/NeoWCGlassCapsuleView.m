#import "NeoWCGlassCapsuleView.h"
#import <QuartzCore/QuartzCore.h>

@interface NeoWCGlassCapsuleView ()
@property (nonatomic, strong, readwrite) UIVisualEffectView *effectView;
@property (nonatomic, strong) UIView *tintView;
@property (nonatomic, strong) UIView *whiteWashView;
@property (nonatomic, strong) CAGradientLayer *edgeHighlightLayer;
@property (nonatomic, strong) CAGradientLayer *depthLayer;
@property (nonatomic, strong) CAShapeLayer *rimLayer;
@property (nonatomic, assign) BOOL fauxLiquidEnabled;
@property (nonatomic, assign) BOOL capsuleShadowEnabled;
@end

@implementation NeoWCGlassCapsuleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = NO;

    _effectView = [[UIVisualEffectView alloc] initWithEffect:nil];
    _effectView.userInteractionEnabled = YES;
    _effectView.clipsToBounds = YES;
    [self addSubview:_effectView];

    _tintView = [UIView new];
    _tintView.userInteractionEnabled = NO;
    [_effectView.contentView addSubview:_tintView];

    _whiteWashView = [UIView new];
    _whiteWashView.userInteractionEnabled = NO;
    _whiteWashView.backgroundColor = UIColor.whiteColor;
    [_effectView.contentView addSubview:_whiteWashView];

    _depthLayer = [CAGradientLayer layer];
    _depthLayer.startPoint = CGPointMake(0.5, 0.0);
    _depthLayer.endPoint = CGPointMake(0.5, 1.0);
    [_effectView.contentView.layer addSublayer:_depthLayer];

    _edgeHighlightLayer = [CAGradientLayer layer];
    _edgeHighlightLayer.startPoint = CGPointMake(0.0, 0.0);
    _edgeHighlightLayer.endPoint = CGPointMake(1.0, 1.0);
    [_effectView.contentView.layer addSublayer:_edgeHighlightLayer];

    _rimLayer = [CAShapeLayer layer];
    _rimLayer.fillColor = UIColor.clearColor.CGColor;
    _rimLayer.lineWidth = 1.0 / UIScreen.mainScreen.scale;
    [_effectView.layer addSublayer:_rimLayer];
    return self;
}

- (void)configureShadowEnabled:(BOOL)enabled {
    self.capsuleShadowEnabled = enabled;
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowOpacity = enabled ? 0.075 : 0.0;
    self.layer.shadowRadius = enabled ? 7.0 : 0.0;
    self.layer.shadowOffset = enabled ? CGSizeMake(0.0, 2.0) : CGSizeZero;
    [self updateCapsuleGeometry];
}

- (void)configureFauxLiquidEnabled:(BOOL)enabled
                         tintColor:(UIColor *)tintColor
                       tintOpacity:(CGFloat)tintOpacity
                     whiteStrength:(CGFloat)whiteStrength {
    self.fauxLiquidEnabled = enabled;
    self.tintView.backgroundColor = tintColor ?: UIColor.systemBackgroundColor;
    self.tintView.alpha = MIN(1.0, MAX(0.0, tintOpacity));
    self.whiteWashView.alpha = MIN(1.0, MAX(0.0, whiteStrength));
    self.edgeHighlightLayer.hidden = !enabled;
    self.depthLayer.hidden = !enabled;
    self.rimLayer.hidden = !enabled;
    [self applyTraitColors];
}

- (void)applyTraitColors {
    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    CGFloat topAlpha = self.fauxLiquidEnabled ? (dark ? 0.30 : 0.52) : 0.0;
    CGFloat edgeAlpha = self.fauxLiquidEnabled ? (dark ? 0.18 : 0.34) : 0.0;
    self.edgeHighlightLayer.colors = @[
        (id)[UIColor.whiteColor colorWithAlphaComponent:topAlpha].CGColor,
        (id)[UIColor.whiteColor colorWithAlphaComponent:0.02].CGColor,
        (id)[UIColor.whiteColor colorWithAlphaComponent:edgeAlpha].CGColor,
    ];
    self.edgeHighlightLayer.locations = @[@0.0, @0.52, @1.0];
    self.depthLayer.colors = @[
        (id)[UIColor.whiteColor colorWithAlphaComponent:dark ? 0.08 : 0.18].CGColor,
        (id)[UIColor.blackColor colorWithAlphaComponent:dark ? 0.10 : 0.035].CGColor,
    ];
    self.rimLayer.strokeColor = [UIColor.whiteColor colorWithAlphaComponent:dark ? 0.32 : 0.58].CGColor;
}

- (void)updateCapsuleGeometry {
    CGRect bounds = self.bounds;
    CGFloat radius = self.capsuleCornerRadius > 0.0 ? self.capsuleCornerRadius : CGRectGetHeight(bounds) * 0.5;
    self.effectView.frame = bounds;
    self.effectView.layer.cornerRadius = radius;
    self.effectView.layer.cornerCurve = kCACornerCurveContinuous;
    self.tintView.frame = self.effectView.contentView.bounds;
    self.whiteWashView.frame = self.effectView.contentView.bounds;
    self.edgeHighlightLayer.frame = self.effectView.contentView.bounds;
    self.depthLayer.frame = self.effectView.contentView.bounds;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:radius];
    self.rimLayer.frame = bounds;
    self.rimLayer.path = path.CGPath;
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
