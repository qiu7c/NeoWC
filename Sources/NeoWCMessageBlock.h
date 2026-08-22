#import "NeoWCCardTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSArray<NSString *> *NeoWCMessageBlockedConversations(void);
FOUNDATION_EXPORT NSArray<NSString *> *NeoWCMessageBlockTypesForConversation(NSString *username);
FOUNDATION_EXPORT BOOL NeoWCMessageBlockConversationMatchesType(NSString *username, NSUInteger messageType);
FOUNDATION_EXPORT void NeoWCMessageBlockSetTypesForConversation(NSString *username, NSArray<NSString *> *types);
FOUNDATION_EXPORT NSString *NeoWCMessageBlockSummaryForConversation(NSString *username);
FOUNDATION_EXPORT UIViewController *NeoWCMessageBlockTypeController(NSString *username);

@interface NeoWCMessageBlockViewController : NeoWCCardTableViewController
@end

NS_ASSUME_NONNULL_END
