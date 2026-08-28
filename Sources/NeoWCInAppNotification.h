#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void NeoWCShowInAppNotification(NSString *title,
                                                   NSString *body,
                                                   NSString *identifier,
                                                   NSString *symbolName,
                                                   dispatch_block_t _Nullable action);
FOUNDATION_EXPORT void NeoWCDismissInAppNotifications(void);

NS_ASSUME_NONNULL_END
