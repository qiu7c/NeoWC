#import <Foundation/Foundation.h>

/// Returns YES when the incoming revoke command was handled and must be swallowed.
FOUNDATION_EXPORT BOOL NeoWCHandleRevokeMessage(id messageManager, id incomingMessage);
