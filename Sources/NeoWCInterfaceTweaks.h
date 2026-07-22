#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const NeoWCChatInputRoundingEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputInnerRoundingKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputOuterRoundingKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputInnerRadiusKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputOuterRadiusKey;

/// Applies or restores NeoWC's chat input rounding on an existing MMInputToolView.
FOUNDATION_EXPORT void NeoWCApplyChatInputRoundingToToolView(UIView *inputToolView);
FOUNDATION_EXPORT void NeoWCRestoreChatInputRoundingFromToolView(UIView *inputToolView);
