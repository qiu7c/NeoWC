#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NeoWCGlassCapsuleView : UIView
@property (nonatomic, strong, readonly) UIVisualEffectView *effectView;
@property (nonatomic, assign) CGFloat capsuleCornerRadius;
- (void)configureShadowEnabled:(BOOL)enabled;
- (void)configureFauxLiquidEnabled:(BOOL)enabled
                         tintColor:(UIColor *)tintColor
                       tintOpacity:(CGFloat)tintOpacity
                      whiteStrength:(CGFloat)whiteStrength;
@end

NS_ASSUME_NONNULL_END
