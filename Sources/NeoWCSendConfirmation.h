#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^NeoWCSendConfirmationValidator)(void);

FOUNDATION_EXPORT NSArray<NSString *> *NeoWCSendConfirmationProtectedConversations(void);
FOUNDATION_EXPORT BOOL NeoWCSendConfirmationIsProtectedConversation(NSString *username);
FOUNDATION_EXPORT void NeoWCSendConfirmationSetProtected(NSString *username, BOOL protectedConversation);
FOUNDATION_EXPORT NSString *NeoWCSendConfirmationDisplayName(NSString *username);

/// Returns YES when the original action is being held for confirmation. The
/// caller must return without invoking the original method in that case.
FOUNDATION_EXPORT BOOL NeoWCPresentSendConfirmationIfNeeded(UIViewController *presenter,
                                                             NSString *username,
                                                             NSString *summary,
                                                             NeoWCSendConfirmationValidator _Nullable validator,
                                                             dispatch_block_t confirmedAction);
FOUNDATION_EXPORT void NeoWCCancelPendingSendConfirmations(void);

NS_ASSUME_NONNULL_END
