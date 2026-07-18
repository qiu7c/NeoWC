#import <UIKit/UIKit.h>

@interface NeoWCPluginVisibilityManager : NSObject
+ (instancetype)sharedManager;
- (void)recordControllerWithTitle:(NSString *)title version:(NSString *)version controller:(NSString *)controller;
- (void)recordSwitchWithTitle:(NSString *)title key:(NSString *)key;
@end

@interface NeoWCPluginVisibilityViewController : UITableViewController
@end

FOUNDATION_EXPORT void NeoWCFilterPluginListController(id controller);
