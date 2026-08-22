#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const NeoWCChatInputRoundingEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputInnerRoundingKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputOuterRoundingKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputInnerRadiusKey;
FOUNDATION_EXPORT NSString *const NeoWCChatInputOuterRadiusKey;
FOUNDATION_EXPORT NSString *const NeoWCHideChatMuteIconKey;
FOUNDATION_EXPORT NSString *const NeoWCGlobalAvatarRoundingEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCGlobalAvatarCornerPercentKey;

/// Applies rounding to WeChat's real inner avatar image when available, while
/// retaining the head view as the stable lifecycle owner.
FOUNDATION_EXPORT void NeoWCApplyGlobalAvatarRoundingToHeadView(UIView *headView);
/// Keeps a custom avatar out of the global setting while allowing that view to
/// retain its own independently configured corner style.
FOUNDATION_EXPORT void NeoWCExcludeHeadViewFromGlobalAvatarRounding(UIView *headView);
FOUNDATION_EXPORT BOOL NeoWCHeadViewIsExcludedFromGlobalAvatarRounding(UIView *headView);
FOUNDATION_EXPORT void NeoWCRefreshTrackedGlobalAvatarViews(void);
FOUNDATION_EXPORT unsigned int NeoWCGlobalAvatarScaledCornerSize(unsigned int originalSize);

/// Keeps NeoWC search bars visually continuous with their containing page and
/// rounds the actual editable field instead of exposing a second square layer.
FOUNDATION_EXPORT void NeoWCStyleSearchBar(UISearchBar *searchBar);

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
