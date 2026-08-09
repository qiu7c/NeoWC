#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const NeoWCAutoDeviceLoginKey;
FOUNDATION_EXPORT NSString *const NeoWCAutoGameAuthorizeKey;
FOUNDATION_EXPORT NSString *const NeoWCMomentsDoubleTapLikeKey;
FOUNDATION_EXPORT NSString *const NeoWCMomentsLikeHapticEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCMomentsLikeHapticIntensityKey;
FOUNDATION_EXPORT NSString *const NeoWCMomentsQuickCommentKey;
FOUNDATION_EXPORT NSString *const NeoWCMomentsForwardEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCMomentsQuickPermissionsKey;
FOUNDATION_EXPORT NSString *const NeoWCMomentsPreciseTimeKey;
FOUNDATION_EXPORT NSString *const NeoWCMomentsPreciseTimeFormatKey;
FOUNDATION_EXPORT NSString *const NeoWCMomentsPreciseTimeDefaultFormat;
FOUNDATION_EXPORT NSString *const NeoWCGameSelectorKey;
FOUNDATION_EXPORT NSString *const NeoWCChatJokerEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCEmoticonToSelfieEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCReplySwipeEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCQuoteJumpEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCQuoteJumpImageEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCQuoteJumpVideoEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCChatSearchButtonEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCChatTopBarCapsuleEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCChatTopBarEffectStyleKey;
FOUNDATION_EXPORT NSString *const NeoWCChatTopBarAvatarSizeKey;
FOUNDATION_EXPORT NSString *const NeoWCChatTopBarNicknameSizeKey;
FOUNDATION_EXPORT NSString *const NeoWCGroupAtTipsEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCMessageBlockEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCMessageBlockUsersKey;
FOUNDATION_EXPORT NSString *const NeoWCMessageBlockKeywordsKey;
FOUNDATION_EXPORT NSString *const NeoWCLongPressMenuEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCLongPressMenuHiddenTitlesKey;
FOUNDATION_EXPORT NSString *const NeoWCLongPressMenuPreferredOrderKey;
FOUNDATION_EXPORT NSString *const NeoWCLongPressMenuTitleMapKey;
FOUNDATION_EXPORT NSString *const NeoWCLongPressMenuKnownTitlesKey;
FOUNDATION_EXPORT NSString *const NeoWCLongPressMenuManualTitlesKey;
FOUNDATION_EXPORT NSString *const NeoWCHideSeparatorLinesKey;
FOUNDATION_EXPORT NSString *const NeoWCGroupMemberReminderEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCKeywordReminderEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCKeywordReminderKeywordsKey;
FOUNDATION_EXPORT NSString *const NeoWCRedEnvelopeDetailEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCRedEnvelopeDetailCenterKey;
FOUNDATION_EXPORT NSString *const NeoWCRedEnvelopeDetailFontSizeKey;
FOUNDATION_EXPORT NSString *const NeoWCCallConfirmEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCQRCodeCameraSourceEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCAutoOriginalImageEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCNotificationDirectChatEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCWalletBalanceEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCWalletBalanceFenKey;
FOUNDATION_EXPORT NSString *const NeoWCContactsCountEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCContactsCountKey;
FOUNDATION_EXPORT NSString *const NeoWCStepOverrideEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCStepCountKey;
FOUNDATION_EXPORT NSString *const NeoWCStepCountDateKey;
FOUNDATION_EXPORT NSString *const NeoWCStepModeKey;
FOUNDATION_EXPORT NSString *const NeoWCStepRandomMinimumKey;
FOUNDATION_EXPORT NSString *const NeoWCStepRandomMaximumKey;
FOUNDATION_EXPORT NSString *const NeoWCStepGradualEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCStepDailyTargetKey;
FOUNDATION_EXPORT NSString *const NeoWCMeMenuKnownTitlesKey;
FOUNDATION_EXPORT NSString *const NeoWCMeMenuHiddenTitlesKey;
FOUNDATION_EXPORT NSString *const NeoWCAutoVoiceTranscriptionEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCAutoVoiceTranscriptionIgnoreGroupKey;
FOUNDATION_EXPORT NSString *const NeoWCAutoVoiceTranscriptionIgnorePrivateKey;
FOUNDATION_EXPORT NSString *const NeoWCAutoVoiceTranscriptionIgnoreSelfKey;
FOUNDATION_EXPORT NSString *const NeoWCHideScreenshotForwardKey;

typedef NS_ENUM(NSInteger, NeoWCStepMode) {
    NeoWCStepModeDailyFixed = 0,
    NeoWCStepModeDailyRandom = 1,
};

typedef NS_ENUM(NSInteger, NeoWCChatTopBarEffectStyle) {
    NeoWCChatTopBarEffectStyleMaterial = 0,
    NeoWCChatTopBarEffectStyleLiquid = 1,
};
FOUNDATION_EXPORT NSString *const NeoWCPageScaleEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCPageScaleGlobalPercentKey;
FOUNDATION_EXPORT NSString *const NeoWCSettingsPageScalePercentKey;
FOUNDATION_EXPORT NSString *const NeoWCAdBlockerKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokeKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokeNotifySenderKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokeLocalTemplateKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokeReplyTemplateKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokeTimeFilterKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokePromptStyleKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokeSideTextKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokeSideOffsetXKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokeSideOffsetYKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokeLocalTextColorKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokeSideTextColorKey;
FOUNDATION_EXPORT NSString *const NeoWCAntiRevokePersistRecordsKey;
FOUNDATION_EXPORT NSString *const NeoWCImageEditQuickSendEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCInputSwipeActionsEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCMultiSelectExportEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCMultiSelectExportTextKey;
FOUNDATION_EXPORT NSString *const NeoWCMultiSelectSaveImagesKey;
FOUNDATION_EXPORT NSString *const NeoWCMultiSelectShareCardKey;
FOUNDATION_EXPORT NSString *const NeoWCEnhancementDidChangeNotification;

FOUNDATION_EXPORT BOOL NeoWCEnhancementEnabled(NSString *key);
FOUNDATION_EXPORT CGFloat NeoWCScalePercentForDefaultsKey(NSString *key, CGFloat defaultValue);
FOUNDATION_EXPORT NSString *NeoWCNormalizedMomentsDateFormat(NSString *format);
FOUNDATION_EXPORT UIColor *NeoWCColorForDefaultsKey(NSString *key, UIColor *fallbackColor);
FOUNDATION_EXPORT NSString *NeoWCHexStringFromColor(UIColor *color);
