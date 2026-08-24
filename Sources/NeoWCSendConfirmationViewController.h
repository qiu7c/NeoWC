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
