#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const NeoWCChatInputRoundingEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputInnerRoundingKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputOuterRoundingKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputInnerRadiusKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputOuterRadiusKey;
FOUNDATION_EXPORT NSString *const NeoWCHideChatMuteIconKey;

/// Applies or restores NeoWC's chat input rounding on an existing MMInputToolView.
FOUNDATION_EXPORT void NeoWCApplyChatInputRoundingToToolView(UIView *inputToolView);
FOUNDATION_EXPORT void NeoWCRestoreChatInputRoundingFromToolView(UIView *inputToolView);
FOUNDATION_EXPORT void NeoWCUpdateChatMuteIconVisibility(UIViewController *controller);
FOUNDATION_EXPORT void NeoWCUpdateChatMuteImageView(UIImageView *imageView);
FOUNDATION_EXPORT BOOL NeoWCShouldForceHideChatMuteImageView(UIImageView *imageView);
/// Fast path for the global UIImageView hook. Returns YES only after NeoWC has
/// positively identified and taken ownership of the mute icon's hidden state.
FOUNDATION_EXPORT BOOL NeoWCShouldKeepManagedChatMuteImageViewHidden(UIImageView *imageView);
