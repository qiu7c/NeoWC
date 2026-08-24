#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const NeoWCDebugFloatingEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCDebugLoggingEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCPaymentLinkDiagnosticsEnabledKey;

FOUNDATION_EXPORT void NeoWCLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXPORT void NeoWCLogAlways(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

FOUNDATION_EXPORT BOOL NeoWCPaymentLinkDiagnosticsMatchesRequest(NSURLRequest *request);
FOUNDATION_EXPORT void NeoWCPaymentLinkDiagnosticsRecordCommandText(NSString *text);
FOUNDATION_EXPORT void NeoWCPaymentLinkDiagnosticsRecordRequest(NSURLRequest *request,
                                                                 NSData *uploadData);
FOUNDATION_EXPORT void NeoWCPaymentLinkDiagnosticsRecordResponse(NSURLRequest *request,
                                                                  NSData *data,
                                                                  NSURLResponse *response,
                                                                  NSError *error);
FOUNDATION_EXPORT BOOL NeoWCPaymentLinkDiagnosticsCorrelationActive(void);
FOUNDATION_EXPORT void NeoWCPaymentLinkDiagnosticsRecordAppMessage(NSString *entryPoint,
                                                                    id target,
                                                                    id wrap,
                                                                    id dataOrPath,
                                                                    unsigned int scene);

@interface NeoWCDebugManager : NSObject
+ (instancetype)sharedManager;
- (void)applySavedState;
- (void)setFloatingEnabled:(BOOL)enabled;
- (void)presentDashboardFromViewController:(UIViewController *)viewController;
@end
