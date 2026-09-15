#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const WCAtlasHomeCategoriesEnabledKey;
FOUNDATION_EXPORT NSString *const WCAtlasHomeCategoriesDataKey;
FOUNDATION_EXPORT NSString *const WCAtlasHomeCategoriesSelectedKey;

/// Attaches or refreshes WCAtlas's first-level category bar on WeChat's homepage table.
/// @param controller The visible native main-frame controller. Declared as `id` because Logos
/// headers do not consistently expose its `UIViewController` inheritance across WeChat versions.
/// @param tableView The native, unmodified homepage table.
/// @discussion Main-thread only. Session rows are projected by returning zero height for rows
/// outside the selected category; native objects and index paths are never rewritten. Missing
/// accessors or incompatible delegate ABI leave the original homepage unchanged.
FOUNDATION_EXPORT void WCAtlasHomeCategoriesAttach(id controller,
                                                   UITableView * _Nullable tableView);

/// Installs the ABI-checked row-height projection hook on a native homepage owner/delegate class.
/// @param ownerClass Runtime class that owns `tableView:heightForRowAtIndexPath:`.
/// @discussion Main-thread only and idempotent. Unsupported or non-CGFloat return ABI is skipped.
FOUNDATION_EXPORT void WCAtlasHomeCategoriesInstallProjectionOnClass(Class _Nullable ownerClass);

/// Settings controller for first-level categories, nested folders, and conversation assignments.
@interface WCAtlasHomeCategoriesViewController : UITableViewController
@end

NS_ASSUME_NONNULL_END
