#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Refreshes both optional per-message time labels without forcing a layout pass.
FOUNDATION_EXPORT void NeoWCScheduleMessageTimeRefresh(UIView *cell);
FOUNDATION_EXPORT void NeoWCHideMessageTimeLabels(UIView *cell);

NS_ASSUME_NONNULL_END
