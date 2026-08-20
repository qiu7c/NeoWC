#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * _Nullable NeoWCCurrentUserWXID(void);
FOUNDATION_EXPORT NSString * _Nullable NeoWCCurrentUserNickname(void);
FOUNDATION_EXPORT NSString * _Nullable NeoWCCurrentUserHeadImageURL(void);
FOUNDATION_EXPORT BOOL NeoWCUpdateCachedCurrentUserContact(id _Nullable contact);
/// Refreshes the persisted profile only when NeoWC's settings UI explicitly
/// requests it. This must not run from WeChat's startup/contact-sync hot path.
FOUNDATION_EXPORT BOOL NeoWCRefreshCachedCurrentUserContact(void);
FOUNDATION_EXPORT void NeoWCInstallServiceCenterCompatibility(void);
FOUNDATION_EXPORT id _Nullable NeoWCDefaultServiceCenter(void);
FOUNDATION_EXPORT id _Nullable NeoWCServiceForClass(Class serviceClass);

NS_ASSUME_NONNULL_END
