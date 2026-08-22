#import "NeoWCCardTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WCPluginModel : NSObject
@property (nonatomic, assign) BOOL isController;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *controller;
@property (nonatomic, copy) NSString *key;
@end

@interface WCPluginsMgr : NSObject
@property (nonatomic, strong) NSMutableArray<WCPluginModel *> *plugins;
+ (instancetype)sharedInstance;
- (void)registerControllerWithTitle:(NSString *)title version:(nullable NSString *)version controller:(NSString *)controller;
- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key;
- (void)removeSwitchWithKey:(NSString *)key;
@end

@interface WCPluginsViewController : UITableViewController
@end

@interface WCPPluginOrderEditorController : NeoWCCardTableViewController
- (instancetype)initWithOwner:(WCPluginsViewController *)owner;
@end

FOUNDATION_EXPORT void NeoWCInstallPluginManagerEntry(id moreViewController);
FOUNDATION_EXPORT void NeoWCPushPluginManager(id sender);
FOUNDATION_EXPORT BOOL NeoWCPluginManagerIsQuickSwitchRegistered(NSString *key);
FOUNDATION_EXPORT void NeoWCPluginManagerSetQuickSwitchRegistered(NSString *key, NSString *title, BOOL registered);
FOUNDATION_EXPORT void NeoWCPluginManagerRegisterSavedQuickSwitches(void);

NS_ASSUME_NONNULL_END
