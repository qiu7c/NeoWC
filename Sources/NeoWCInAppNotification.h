#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const NeoWCInAppNotificationSymbolKey;
FOUNDATION_EXPORT NSString *const NeoWCInAppNotificationHeightKey;
FOUNDATION_EXPORT NSString *const NeoWCInAppNotificationBlurIntensityKey;
FOUNDATION_EXPORT CGFloat const NeoWCInAppNotificationMinimumHeight;
FOUNDATION_EXPORT CGFloat const NeoWCInAppNotificationMaximumHeight;

FOUNDATION_EXPORT NSString *NeoWCInAppNotificationResolvedSymbolName(NSString *requestedSymbolName);
FOUNDATION_EXPORT CGFloat NeoWCInAppNotificationPreferredHeight(void);
FOUNDATION_EXPORT CGFloat NeoWCInAppNotificationBlurIntensity(void);

FOUNDATION_EXPORT void NeoWCShowInAppNotification(NSString *title,
                                                   NSString *body,
                                                   NSString *identifier,
                                                   NSString *symbolName,
                                                   dispatch_block_t _Nullable action);
FOUNDATION_EXPORT void NeoWCShowTransientHUD(NSString *message,
                                             NSString *symbolName);
FOUNDATION_EXPORT void NeoWCShowProgressCapsule(NSString *message,
                                                float progress,
                                                NSString *symbolName);
FOUNDATION_EXPORT void NeoWCCompleteProgressCapsule(NSString *message,
                                                    BOOL success);
FOUNDATION_EXPORT void NeoWCDismissProgressCapsule(void);
FOUNDATION_EXPORT void NeoWCDismissInAppNotifications(void);

NS_ASSUME_NONNULL_END
