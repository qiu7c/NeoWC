#import <UIKit/UIKit.h>

@interface NeoWCSendConfirmationViewController : UITableViewController
@end

typedef BOOL (^NeoWCConversationPickerSelectedBlock)(NSString *username);
typedef void (^NeoWCConversationPickerToggleBlock)(NSString *username);

FOUNDATION_EXPORT UIViewController *NeoWCCreateConversationPicker(NSString *title,
                                                                  NSString *footer,
                                                                  NeoWCConversationPickerSelectedBlock selected,
                                                                  NeoWCConversationPickerToggleBlock toggle);
