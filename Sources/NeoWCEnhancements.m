#import "NeoWCEnhancements.h"
#import <math.h>

NSString *const NeoWCAutoDeviceLoginKey = @"com.qiu7c.neowc.enhance.auto-device-login";
NSString *const NeoWCAutoGameAuthorizeKey = @"com.qiu7c.neowc.enhance.auto-game-authorize";
NSString *const NeoWCMomentsDoubleTapLikeKey = @"com.qiu7c.neowc.moments.double-tap-like";
NSString *const NeoWCMomentsLikeHapticEnabledKey = @"com.qiu7c.neowc.moments.like-haptic";
NSString *const NeoWCMomentsLikeHapticIntensityKey = @"com.qiu7c.neowc.moments.like-haptic-intensity";
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
NSString *const NeoWCAntiRevokePromptStyleKey = @"com.qiu7c.neowc.message.anti-revoke.prompt-style";
NSString *const NeoWCAntiRevokeSideTextKey = @"com.qiu7c.neowc.message.anti-revoke.side-text";
NSString *const NeoWCAntiRevokeSideOffsetXKey = @"com.qiu7c.neowc.message.anti-revoke.side-offset-x";
NSString *const NeoWCAntiRevokeSideOffsetYKey = @"com.qiu7c.neowc.message.anti-revoke.side-offset-y";
NSString *const NeoWCAntiRevokeLocalTextColorKey = @"com.qiu7c.neowc.message.anti-revoke.local-text-color";
NSString *const NeoWCAntiRevokeSideTextColorKey = @"com.qiu7c.neowc.message.anti-revoke.side-text-color";
NSString *const NeoWCAntiRevokePersistRecordsKey = @"com.qiu7c.neowc.message.anti-revoke.persist-records";
NSString *const NeoWCImageEditQuickSendEnabledKey = @"com.qiu7c.neowc.enhance.image-edit-quick-send";
NSString *const NeoWCImageEditReturnToChatKey = @"com.qiu7c.neowc.enhance.image-edit-return-to-chat";
NSString *const NeoWCInputSwipeActionsEnabledKey = @"com.qiu7c.neowc.chat.input-swipe-actions";
NSString *const NeoWCMultiSelectExportEnabledKey = @"com.qiu7c.neowc.enhance.multi-select-export";
NSString *const NeoWCMultiSelectExportTextKey = @"com.qiu7c.neowc.enhance.multi-select-export.text";
NSString *const NeoWCMultiSelectSaveImagesKey = @"com.qiu7c.neowc.enhance.multi-select-export.images";
NSString *const NeoWCMultiSelectShareCardKey = @"com.qiu7c.neowc.enhance.multi-select-export.share-card";
NSString *const NeoWCEnhancementDidChangeNotification = @"NeoWCEnhancementDidChangeNotification";

UIColor *NeoWCColorForDefaultsKey(NSString *key, UIColor *fallbackColor) {
    NSString *hex = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    if (![hex isKindOfClass:[NSString class]]) return fallbackColor;
    NSString *value = [[hex stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    if (value.length != 6 && value.length != 8) return fallbackColor;
    unsigned long long rgba = 0;
    if (![[NSScanner scannerWithString:value] scanHexLongLong:&rgba]) return fallbackColor;
    CGFloat red = ((rgba >> (value.length == 8 ? 24 : 16)) & 0xFF) / 255.0;
    CGFloat green = ((rgba >> (value.length == 8 ? 16 : 8)) & 0xFF) / 255.0;
    CGFloat blue = ((rgba >> (value.length == 8 ? 8 : 0)) & 0xFF) / 255.0;
    CGFloat alpha = value.length == 8 ? (rgba & 0xFF) / 255.0 : 1.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

NSString *NeoWCHexStringFromColor(UIColor *color) {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0;
    if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) return @"#8E8E93FF";
    return [NSString stringWithFormat:@"#%02X%02X%02X%02X",
            (int)lround(red * 255.0), (int)lround(green * 255.0),
            (int)lround(blue * 255.0), (int)lround(alpha * 255.0)];
}

BOOL NeoWCEnhancementEnabled(NSString *key) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id masterValue = [defaults objectForKey:@"com.qiu7c.neowc.enabled"];
    BOOL masterEnabled = masterValue ? [masterValue boolValue] : YES;
    return masterEnabled && [defaults boolForKey:key];
}
