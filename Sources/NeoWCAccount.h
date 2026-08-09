#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * _Nullable NeoWCCurrentUserWXID(void);
FOUNDATION_EXPORT NSString * _Nullable NeoWCCurrentUserNickname(void);
FOUNDATION_EXPORT NSString * _Nullable NeoWCCurrentUserHeadImageURL(void);
FOUNDATION_EXPORT void NeoWCInstallServiceCenterCompatibility(void);
FOUNDATION_EXPORT id _Nullable NeoWCDefaultServiceCenter(void);
FOUNDATION_EXPORT id _Nullable NeoWCServiceForClass(Class serviceClass);

NS_ASSUME_NONNULL_END
