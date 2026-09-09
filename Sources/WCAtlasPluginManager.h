#import "WCAtlasCardTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const WCAtlasPluginManagerEnabledKey;

@interface WCAtlasPluginModel : NSObject
@property (nonatomic, assign) BOOL isController;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *controller;
@property (nonatomic, copy) NSString *key;
@end

@interface WCPluginsMgr : NSObject
+ (instancetype)sharedInstance;
- (void)registerControllerWithTitle:(NSString *)title version:(nullable NSString *)version controller:(NSString *)controller;
- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key;
@end

@interface WCAtlasPluginsMgr : NSObject
@property (nonatomic, strong) NSMutableArray<WCAtlasPluginModel *> *plugins;
+ (instancetype)sharedInstance;
- (void)registerControllerWithTitle:(NSString *)title version:(nullable NSString *)version controller:(NSString *)controller;
- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key;
- (void)removeSwitchWithKey:(NSString *)key;
@end

@interface WCAtlasPluginsViewController : UITableViewController
@end

@interface WCPPluginOrderEditorController : WCAtlasCardTableViewController
- (instancetype)initWithOwner:(WCAtlasPluginsViewController *)owner;
@end

FOUNDATION_EXPORT void WCAtlasInstallPluginManagerEntry(id moreViewController);
FOUNDATION_EXPORT void WCAtlasPushPluginManager(id sender);
/// Returns YES only when the external LazyCat WCPluginsMgr service is available.
FOUNDATION_EXPORT BOOL WCAtlasExternalPluginManagerAvailable(void);
/// Adds a direct WCAtlas row to WeChat's settings page when LazyCat is unavailable.
/// Must be called on the main thread after NewSettingViewController has appeared.
FOUNDATION_EXPORT void WCAtlasInstallSettingsFallbackEntry(id settingsController);
/// Pushes the WCAtlas settings controller from the native WeChat settings page.
/// Must be called on the main thread.
FOUNDATION_EXPORT void WCAtlasPushSettingsController(id sender);
FOUNDATION_EXPORT BOOL WCAtlasPluginManagerIsQuickSwitchRegistered(NSString *key);
FOUNDATION_EXPORT void WCAtlasPluginManagerSetQuickSwitchRegistered(NSString *key, NSString *title, BOOL registered);
FOUNDATION_EXPORT void WCAtlasPluginManagerRegisterSavedQuickSwitches(void);

NS_ASSUME_NONNULL_END
