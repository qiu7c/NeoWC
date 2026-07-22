#import <UIKit/UIKit.h>

/// Returns YES when the incoming revoke command was handled and must be swallowed.
FOUNDATION_EXPORT BOOL NeoWCHandleRevokeMessage(id messageManager, id incomingMessage);

/// Returns the compact side prompt associated with an intercepted message.
FOUNDATION_EXPORT NSString *NeoWCAntiRevokeSidePromptForMessage(id message);
FOUNDATION_EXPORT BOOL NeoWCAntiRevokeIsLocalPromptMessage(id message);
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokePromptDidChangeNotification;
FOUNDATION_EXPORT void NeoWCAntiRevokeSetPersistenceEnabled(BOOL enabled);

@interface NeoWCAntiRevokeRecordsViewController : UITableViewController
@end

@interface NeoWCAntiRevokeAppearanceViewController : UIViewController
@end
