#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Refreshes both optional per-message time labels without forcing a layout pass.
FOUNDATION_EXPORT void WCAtlasScheduleMessageTimeRefresh(UIView *cell);
FOUNDATION_EXPORT void WCAtlasHideMessageTimeLabels(UIView *cell);
/// Repositions the labels synchronously after the native message cell has
/// completed its own layout pass.
FOUNDATION_EXPORT void WCAtlasLayoutMessageTimeLabels(UIView *cell);
/// Shared lightweight message anchor used by message-time and anti-revoke
/// side labels. It never scans the complete private view hierarchy.
FOUNDATION_EXPORT UIView * _Nullable WCAtlasMessageSideAnchorView(UIView *cell);

NS_ASSUME_NONNULL_END
