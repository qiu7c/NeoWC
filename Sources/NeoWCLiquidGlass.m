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
    _surfaceLayer.startPoint = CGPointMake(0.0, 0.0);
    _surfaceLayer.endPoint = CGPointMake(1.0, 1.0);
    [self.layer addSublayer:_surfaceLayer];

    _depthLayer = [CAGradientLayer layer];
    _depthLayer.startPoint = CGPointMake(0.5, 0.0);
    _depthLayer.endPoint = CGPointMake(0.5, 1.0);
    _depthLayer.locations = @[@0.0, @0.52, @1.0];
    [self.layer addSublayer:_depthLayer];

    _glareLayer = [CAGradientLayer layer];
    _glareLayer.type = kCAGradientLayerRadial;
    _glareLayer.startPoint = CGPointMake(0.16, 0.04);
    _glareLayer.endPoint = CGPointMake(0.82, 0.96);
    _glareLayer.locations = @[@0.0, @0.28, @1.0];
    [self.layer addSublayer:_glareLayer];

    _edgeLayer = [CAGradientLayer layer];
    _edgeLayer.startPoint = CGPointMake(0.0, 0.0);
    _edgeLayer.endPoint = CGPointMake(1.0, 1.0);
    _edgeMaskLayer = [CAShapeLayer layer];
    _edgeMaskLayer.fillColor = UIColor.clearColor.CGColor;
    _edgeMaskLayer.strokeColor = UIColor.whiteColor.CGColor;
    _edgeMaskLayer.lineWidth = 1.1;
    _edgeLayer.mask = _edgeMaskLayer;
    [self.layer addSublayer:_edgeLayer];

    [self updatePalette];
    return self;
}

- (void)updatePalette {
    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    _surfaceLayer.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.10 : 0.18].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:0.02].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:dark ? 0.08 : 0.025].CGColor,
    ];
    _surfaceLayer.locations = @[@0.0, @0.46, @1.0];
    _depthLayer.colors = @[
        (id)UIColor.clearColor.CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:dark ? 0.025 : 0.012].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:dark ? 0.16 : 0.09].CGColor,
    ];
    _glareLayer.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.28 : 0.46].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.07 : 0.12].CGColor,
        (id)UIColor.clearColor.CGColor,
    ];
    _edgeLayer.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.58 : 0.82].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.12 : 0.24].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:dark ? 0.24 : 0.10].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:dark ? 0.30 : 0.52].CGColor,
    ];
    _edgeLayer.locations = @[@0.0, @0.34, @0.72, @1.0];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.layer.cornerCurve = kCACornerCurveContinuous;
    _surfaceLayer.frame = self.bounds;
    _depthLayer.frame = self.bounds;
    _glareLayer.frame = CGRectInset(self.bounds,
                                    -CGRectGetWidth(self.bounds) * 0.12,
                                    -CGRectGetHeight(self.bounds) * 0.32);
    _edgeLayer.frame = self.bounds;
    _edgeMaskLayer.frame = self.bounds;
    CGFloat inset = 0.65;
    CGFloat radius = MAX(0.0, self.layer.cornerRadius - inset);
    _edgeMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, inset, inset)
                                                     cornerRadius:radius].CGPath;
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
