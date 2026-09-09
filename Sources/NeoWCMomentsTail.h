#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Installs the verified WCUploadTask/WCNewCommitViewController hooks.
FOUNDATION_EXPORT void NeoWCMomentsTailInstallHooks(void);

/// Creates the tail picker used by settings and by one Moments post.
/// In post-session mode, choosing “none” affects only the current composer.
FOUNDATION_EXPORT UIViewController *NeoWCMomentsTailPicker(BOOL postSession,
                                                           void (^ _Nullable completion)(void));

NS_ASSUME_NONNULL_END
