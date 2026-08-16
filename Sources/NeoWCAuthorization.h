#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NeoWCAuthorizationState) {
    NeoWCAuthorizationStateUnknown,
    NeoWCAuthorizationStateLoading,
    NeoWCAuthorizationStateAuthorized,
    NeoWCAuthorizationStateUnauthorized,
    NeoWCAuthorizationStateBlacklisted,
    NeoWCAuthorizationStateFailed,
};

FOUNDATION_EXPORT NSNotificationName const NeoWCAuthorizationStateDidChangeNotification;
FOUNDATION_EXPORT BOOL NeoWCAuthorizationIsCurrentUserAdministrator(void);
/// Ordinary authorization is display-only; this returns NO only for the persistent blacklist.
FOUNDATION_EXPORT BOOL NeoWCAuthorizationAllowsCoreFeatures(void);
FOUNDATION_EXPORT BOOL NeoWCAuthorizationHasCompletedInitialCheckForCurrentUser(void);
FOUNDATION_EXPORT BOOL NeoWCAuthorizationIsPermanentlyBlacklisted(void);
FOUNDATION_EXPORT NeoWCAuthorizationState NeoWCCurrentAuthorizationState(void);
FOUNDATION_EXPORT NSString *NeoWCCurrentAuthorizationMessage(void);
FOUNDATION_EXPORT void NeoWCRefreshCurrentAuthorization(void);
/// Uses the persisted state immediately and only performs a silent network
/// refresh when the saved result is stale or belongs to another account.
FOUNDATION_EXPORT void NeoWCRefreshCurrentAuthorizationIfNeeded(void);
FOUNDATION_EXPORT void NeoWCPresentPermanentBlacklistBlockerIfNeeded(void);

@interface NeoWCAuthorizationManagerViewController : UITableViewController
@end

NS_ASSUME_NONNULL_END
