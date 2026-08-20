#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const NeoWCChatInputRoundingEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputInnerRoundingKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputOuterRoundingKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputInnerRadiusKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputOuterRadiusKey;
FOUNDATION_EXPORT NSString *const NeoWCHideChatMuteIconKey;
FOUNDATION_EXPORT NSString *const NeoWCGlobalAvatarRoundingEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCGlobalAvatarCornerPercentKey;

/// Reloads the cached values used by WeChat's native setConerSize: path.
FOUNDATION_EXPORT void NeoWCRefreshTrackedGlobalAvatarViews(void);
FOUNDATION_EXPORT unsigned int NeoWCGlobalAvatarScaledCornerSize(unsigned int originalSize);

/// Applies or restores NeoWC's chat input rounding on an existing MMInputToolView.
FOUNDATION_EXPORT void NeoWCApplyChatInputRoundingToToolView(UIView *inputToolView);
FOUNDATION_EXPORT void NeoWCRestoreChatInputRoundingFromToolView(UIView *inputToolView);
FOUNDATION_EXPORT void NeoWCUpdateChatMuteIconVisibility(UIViewController *controller);
FOUNDATION_EXPORT void NeoWCUpdateChatMuteImageView(UIImageView *imageView);
FOUNDATION_EXPORT void NeoWCUpdateChatMuteMemberLabel(UILabel *label);
FOUNDATION_EXPORT BOOL NeoWCShouldForceHideChatMuteImageView(UIImageView *imageView);
/// Fast path for the global UIImageView hook. Returns YES only after NeoWC has
/// positively identified and taken ownership of the mute icon's hidden state.
FOUNDATION_EXPORT BOOL NeoWCShouldKeepManagedChatMuteImageViewHidden(UIImageView *imageView);
FOUNDATION_EXPORT BOOL NeoWCShouldKeepManagedChatMuteMemberLabelHidden(UILabel *label);
