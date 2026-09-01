#import "NeoWCCardTableViewController.h"

@interface NeoWCSendConfirmationViewController : NeoWCCardTableViewController
@end

typedef BOOL (^NeoWCConversationPickerSelectedBlock)(NSString *username);
typedef void (^NeoWCConversationPickerToggleBlock)(NSString *username);

FOUNDATION_EXPORT UIViewController *NeoWCCreateConversationPicker(NSString *title,
                                                                  NSString *footer,
                                                                  NeoWCConversationPickerSelectedBlock selected,
                                                                  NeoWCConversationPickerToggleBlock toggle);
FOUNDATION_EXPORT UIViewController *NeoWCCreateGroupPicker(NSString *title,
                                                           NSString *footer,
                                                           NeoWCConversationPickerSelectedBlock selected,
                                                           NeoWCConversationPickerToggleBlock toggle);
FOUNDATION_EXPORT UIViewController *NeoWCCreateFriendPicker(NSString *title,
                                                            NSString *footer,
                                                            NeoWCConversationPickerSelectedBlock selected,
                                                            NeoWCConversationPickerToggleBlock toggle);
FOUNDATION_EXPORT void NeoWCConfigureConversationPickerBulkActions(UIViewController *picker,
                                                                   dispatch_block_t selectAll,
                                                                   dispatch_block_t invertSelection);
FOUNDATION_EXPORT void NeoWCConfigureConversationPickerCompletion(UIViewController *picker,
                                                                  dispatch_block_t completion);
