#import "NeoWCEnhancements.h"

NSString *const NeoWCAutoDeviceLoginKey = @"com.qiu7c.neowc.enhance.auto-device-login";
NSString *const NeoWCAutoGameAuthorizeKey = @"com.qiu7c.neowc.enhance.auto-game-authorize";
NSString *const NeoWCMomentsDoubleTapLikeKey = @"com.qiu7c.neowc.moments.double-tap-like";
NSString *const NeoWCMomentsQuickCommentKey = @"com.qiu7c.neowc.moments.quick-comment";
NSString *const NeoWCGameSelectorKey = @"com.qiu7c.neowc.enhance.game-selector";
NSString *const NeoWCStepOverrideEnabledKey = @"com.qiu7c.neowc.enhance.step-override";
NSString *const NeoWCStepCountKey = @"com.qiu7c.neowc.enhance.step-count";
NSString *const NeoWCStepCountDateKey = @"com.qiu7c.neowc.enhance.step-count-date";
NSString *const NeoWCAdBlockerKey = @"com.qiu7c.neowc.enhance.ad-blocker";
NSString *const NeoWCAntiRevokeKey = @"com.qiu7c.neowc.message.anti-revoke";
NSString *const NeoWCAntiRevokeNotifySenderKey = @"com.qiu7c.neowc.message.anti-revoke.notify-sender";
NSString *const NeoWCAntiRevokeLocalTemplateKey = @"com.qiu7c.neowc.message.anti-revoke.local-template";
NSString *const NeoWCAntiRevokeReplyTemplateKey = @"com.qiu7c.neowc.message.anti-revoke.reply-template";
NSString *const NeoWCAntiRevokeTimeFilterKey = @"com.qiu7c.neowc.message.anti-revoke.time-filter";
NSString *const NeoWCChatCaptureEnabledKey = @"com.qiu7c.neowc.enhance.chat-capture";
NSString *const NeoWCChatCaptureIncludeChromeKey = @"com.qiu7c.neowc.chat-capture.include-chrome";
NSString *const NeoWCChatCaptureHideMemberNamesKey = @"com.qiu7c.neowc.chat-capture.hide-member-names";
NSString *const NeoWCChatCaptureShowBackgroundKey = @"com.qiu7c.neowc.chat-capture.show-background";
NSString *const NeoWCChatCaptureCloseAfterShareKey = @"com.qiu7c.neowc.chat-capture.close-after-share";
NSString *const NeoWCChatCaptureCropTopPointsKey = @"com.qiu7c.neowc.chat-capture.crop-top-points";
NSString *const NeoWCChatCaptureShowChatNameKey = @"com.qiu7c.neowc.chat-capture.show-chat-name";
NSString *const NeoWCChatCaptureShowTimestampKey = @"com.qiu7c.neowc.chat-capture.show-timestamp";
NSString *const NeoWCChatCaptureWatermarkTextKey = @"com.qiu7c.neowc.chat-capture.watermark-text";
NSString *const NeoWCChatCaptureWatermarkStyleKey = @"com.qiu7c.neowc.chat-capture.watermark-style";
NSString *const NeoWCChatCaptureWatermarkOpacityKey = @"com.qiu7c.neowc.chat-capture.watermark-opacity";
NSString *const NeoWCEnhancementDidChangeNotification = @"NeoWCEnhancementDidChangeNotification";

BOOL NeoWCEnhancementEnabled(NSString *key) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id masterValue = [defaults objectForKey:@"com.qiu7c.neowc.enabled"];
    BOOL masterEnabled = masterValue ? [masterValue boolValue] : YES;
    return masterEnabled && [defaults boolForKey:key];
}
