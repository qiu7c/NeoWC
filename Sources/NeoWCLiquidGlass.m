#import "NeoWCLiquidGlass.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char NeoWCLiquidGlassOverlayKey;

@interface NeoWCLiquidGlassOverlayView : UIView
@property (nonatomic, strong) CAGradientLayer *surfaceLayer;
@property (nonatomic, strong) CAGradientLayer *edgeLayer;
@property (nonatomic, strong) CAShapeLayer *edgeMaskLayer;
@property (nonatomic, strong) CAGradientLayer *glareLayer;
@property (nonatomic, strong) CAGradientLayer *depthLayer;
@property (nonatomic, strong) CAGradientLayer *coolFringeLayer;
@property (nonatomic, strong) CAShapeLayer *coolFringeMaskLayer;
@property (nonatomic, strong) CAGradientLayer *warmFringeLayer;
@property (nonatomic, strong) CAShapeLayer *warmFringeMaskLayer;
@end

@implementation NeoWCLiquidGlassOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.userInteractionEnabled = NO;
    self.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = YES;
    self.layer.allowsEdgeAntialiasing = YES;

    _surfaceLayer = [CAGradientLayer layer];
    _surfaceLayer.startPoint = CGPointMake(0.08, 0.0);
    _surfaceLayer.endPoint = CGPointMake(0.92, 1.0);
    [self.layer addSublayer:_surfaceLayer];

    _depthLayer = [CAGradientLayer layer];
    _depthLayer.startPoint = CGPointMake(0.5, 0.0);
    _depthLayer.endPoint = CGPointMake(0.5, 1.0);
    _depthLayer.locations = @[@0.0, @0.72, @1.0];
    [self.layer addSublayer:_depthLayer];

    _glareLayer = [CAGradientLayer layer];
    _glareLayer.type = kCAGradientLayerRadial;
    _glareLayer.startPoint = CGPointMake(0.10, 0.0);
    _glareLayer.endPoint = CGPointMake(0.70, 0.88);
    _glareLayer.locations = @[@0.0, @0.18, @0.48, @1.0];
    [self.layer addSublayer:_glareLayer];

    _edgeLayer = [CAGradientLayer layer];
    _edgeLayer.startPoint = CGPointMake(0.0, 0.0);
    _edgeLayer.endPoint = CGPointMake(1.0, 1.0);
    _edgeMaskLayer = [CAShapeLayer layer];
    _edgeMaskLayer.fillColor = UIColor.clearColor.CGColor;
    _edgeMaskLayer.strokeColor = UIColor.whiteColor.CGColor;
    _edgeMaskLayer.lineWidth = 0.8;
    _edgeLayer.mask = _edgeMaskLayer;
    [self.layer addSublayer:_edgeLayer];

    _coolFringeLayer = [CAGradientLayer layer];
    _coolFringeLayer.startPoint = CGPointMake(0.0, 0.0);
    _coolFringeLayer.endPoint = CGPointMake(0.0, 1.0);
    _coolFringeMaskLayer = [CAShapeLayer layer];
    _coolFringeMaskLayer.fillColor = UIColor.clearColor.CGColor;
    _coolFringeMaskLayer.strokeColor = UIColor.whiteColor.CGColor;
    _coolFringeMaskLayer.lineWidth = 0.55;
    _coolFringeLayer.mask = _coolFringeMaskLayer;
    [self.layer addSublayer:_coolFringeLayer];

    _warmFringeLayer = [CAGradientLayer layer];
    _warmFringeLayer.startPoint = CGPointMake(0.0, 0.0);
    _warmFringeLayer.endPoint = CGPointMake(0.0, 1.0);
    _warmFringeMaskLayer = [CAShapeLayer layer];
    _warmFringeMaskLayer.fillColor = UIColor.clearColor.CGColor;
    _warmFringeMaskLayer.strokeColor = UIColor.whiteColor.CGColor;
    _warmFringeMaskLayer.lineWidth = 0.55;
    _warmFringeLayer.mask = _warmFringeMaskLayer;
    [self.layer addSublayer:_warmFringeLayer];

    [self updatePalette];
    return self;
}

- (void)updatePalette {
    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    _surfaceLayer.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.045 : 0.055].CGColor,
        (id)UIColor.clearColor.CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:dark ? 0.025 : 0.010].CGColor,
    ];
    _surfaceLayer.locations = @[@0.0, @0.42, @1.0];
    _depthLayer.colors = @[
        (id)UIColor.clearColor.CGColor,
        (id)UIColor.clearColor.CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:dark ? 0.055 : 0.032].CGColor,
    ];
    _glareLayer.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.14 : 0.18].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.045 : 0.065].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:0.012].CGColor,
        (id)UIColor.clearColor.CGColor,
    ];
    _edgeLayer.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.24 : 0.30].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.04 : 0.07].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:dark ? 0.10 : 0.045].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.13 : 0.18].CGColor,
    ];
    _edgeLayer.locations = @[@0.0, @0.34, @0.72, @1.0];
    _coolFringeLayer.colors = @[
        (id)[UIColor colorWithRed:0.35 green:0.82 blue:1.0 alpha:dark ? 0.07 : 0.10].CGColor,
        (id)UIColor.clearColor.CGColor,
        (id)UIColor.clearColor.CGColor,
    ];
    _coolFringeLayer.locations = @[@0.0, @0.34, @1.0];
    _warmFringeLayer.colors = @[
        (id)UIColor.clearColor.CGColor,
        (id)UIColor.clearColor.CGColor,
        (id)[UIColor colorWithRed:1.0 green:0.58 blue:0.74 alpha:dark ? 0.045 : 0.065].CGColor,
    ];
    _warmFringeLayer.locations = @[@0.0, @0.62, @1.0];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.layer.cornerCurve = kCACornerCurveContinuous;
    _surfaceLayer.frame = self.bounds;
    _depthLayer.frame = self.bounds;
    _glareLayer.frame = CGRectInset(self.bounds,
                                    -CGRectGetWidth(self.bounds) * 0.08,
                                    -CGRectGetHeight(self.bounds) * 0.22);
    _edgeLayer.frame = self.bounds;
    _edgeMaskLayer.frame = self.bounds;
    _coolFringeLayer.frame = CGRectOffset(self.bounds, -0.45, 0.0);
    _coolFringeMaskLayer.frame = self.bounds;
    _warmFringeLayer.frame = CGRectOffset(self.bounds, 0.45, 0.0);
    _warmFringeMaskLayer.frame = self.bounds;
    CGFloat inset = 0.65;
    CGFloat radius = MAX(0.0, self.layer.cornerRadius - inset);
    CGPathRef edgePath = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, inset, inset)
                                                     cornerRadius:radius].CGPath;
    _edgeMaskLayer.path = edgePath;
    _coolFringeMaskLayer.path = edgePath;
    _warmFringeMaskLayer.path = edgePath;
    [CATransaction commit];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
        [self updatePalette];
    }
}

@end

void NeoWCConfigureLiquidGlassOverlay(UIVisualEffectView *effectView, BOOL enabled) {
    if (!effectView) return;
    NeoWCLiquidGlassOverlayView *overlay = objc_getAssociatedObject(effectView,
                                                                    &NeoWCLiquidGlassOverlayKey);
    if (!enabled) {
        [overlay removeFromSuperview];
        objc_setAssociatedObject(effectView, &NeoWCLiquidGlassOverlayKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    if (!overlay) {
        overlay = [NeoWCLiquidGlassOverlayView new];
        overlay.translatesAutoresizingMaskIntoConstraints = NO;
        [effectView.contentView insertSubview:overlay atIndex:0];
        [NSLayoutConstraint activateConstraints:@[
            [overlay.leadingAnchor constraintEqualToAnchor:effectView.contentView.leadingAnchor],
            [overlay.trailingAnchor constraintEqualToAnchor:effectView.contentView.trailingAnchor],
            [overlay.topAnchor constraintEqualToAnchor:effectView.contentView.topAnchor],
            [overlay.bottomAnchor constraintEqualToAnchor:effectView.contentView.bottomAnchor],
        ]];
        objc_setAssociatedObject(effectView, &NeoWCLiquidGlassOverlayKey,
                                 overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    overlay.layer.cornerRadius = effectView.layer.cornerRadius;
    overlay.hidden = NO;
}
