#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const NeoWCDebugFloatingEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCDebugLoggingEnabledKey;

FOUNDATION_EXPORT void NeoWCLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

@interface NeoWCDebugManager : NSObject
+ (instancetype)sharedManager;
- (void)applySavedState;
- (void)setFloatingEnabled:(BOOL)enabled;
- (void)presentDashboardFromViewController:(UIViewController *)viewController;
@end
