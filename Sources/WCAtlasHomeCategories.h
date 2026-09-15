#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const WCAtlasHomeCategoriesEnabledKey;
FOUNDATION_EXPORT NSString *const WCAtlasHomeCategoriesDataKey;

/// Rebuilds WCAtlas category entries inside WeChat's native homepage session array.
/// @param sessionManager The live `MainSessionMgr` instance currently rebuilding its sessions.
/// @discussion Main-thread only. Each first-level category becomes one synthetic native session;
/// assigned group sessions are removed from the root list. Unsupported native models are ignored.
FOUNDATION_EXPORT void WCAtlasHomeCategoriesApplyToSessionManager(id _Nullable sessionManager);

/// Handles a tap on a WCAtlas synthetic category session.
/// @param controller Native homepage controller used for navigation.
/// @param tableView Native homepage table used as a session lookup fallback.
/// @param indexPath Selected native index path.
/// @return YES when the row is a WCAtlas category and the category page was pushed.
FOUNDATION_EXPORT BOOL WCAtlasHomeCategoriesHandleSelection(id _Nullable controller,
                                                            UITableView * _Nullable tableView,
                                                            NSIndexPath * _Nullable indexPath);

/// Returns whether a username belongs to a WCAtlas synthetic category session.
/// @param userName Candidate native session username.
/// @return YES only for WCAtlas's reserved category prefix; nil and native usernames return NO.
/// @discussion Thread-safe and pure. This performs no native call and has no version fallback.
FOUNDATION_EXPORT BOOL WCAtlasHomeCategoriesIsSyntheticUserName(NSString * _Nullable userName);

/// Restores the configured title and subtitle after WeChat formats a synthetic category cell.
/// @param cellData Native `MainFrameCellData` after an original formatting method returns.
/// @discussion Main-thread only. Non-category and unsupported models are left unchanged; native
/// field access is delegated to `WCAtlasPrivateAPI` and failure preserves WeChat's original text.
FOUNDATION_EXPORT void WCAtlasHomeCategoriesConfigureCellData(id _Nullable cellData);

/// Settings controller for first-level categories, nested folders, and group-chat assignments.
@interface WCAtlasHomeCategoriesViewController : UITableViewController
@end

NS_ASSUME_NONNULL_END
