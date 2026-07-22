#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const NeoWCChatInputRoundingEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputInnerRoundingKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputOuterRoundingKey;

/// Applies or restores NeoWC's chat input rounding according to current defaults.
FOUNDATION_EXPORT void NeoWCApplyChatInputRounding(UIViewController *controller);
