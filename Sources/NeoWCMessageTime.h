#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Refreshes both optional per-message time labels without forcing a layout pass.
FOUNDATION_EXPORT void NeoWCScheduleMessageTimeRefresh(UIView *cell);
FOUNDATION_EXPORT void NeoWCHideMessageTimeLabels(UIView *cell);
/// Shared lightweight message anchor used by message-time and anti-revoke
/// side labels. It never scans the complete private view hierarchy.
FOUNDATION_EXPORT UIView * _Nullable NeoWCMessageSideAnchorView(UIView *cell);

NS_ASSUME_NONNULL_END
