#import <Foundation/Foundation.h>

/// Returns YES when the incoming revoke command was handled and must be swallowed.
FOUNDATION_EXPORT BOOL NeoWCHandleRevokeMessage(id messageManager, id incomingMessage);

/// Returns the compact side prompt associated with an intercepted message.
FOUNDATION_EXPORT NSString *NeoWCAntiRevokeSidePromptForMessage(id message);
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokePromptDidChangeNotification;
