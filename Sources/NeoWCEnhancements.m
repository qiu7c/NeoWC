#import "NeoWCEnhancements.h"
#import <math.h>

NSString *const NeoWCAutoDeviceLoginKey = @"com.qiu7c.neowc.enhance.auto-device-login";
NSString *const NeoWCAutoGameAuthorizeKey = @"com.qiu7c.neowc.enhance.auto-game-authorize";
NSString *const NeoWCMomentsDoubleTapLikeKey = @"com.qiu7c.neowc.moments.double-tap-like";
NSString *const NeoWCMomentsLikeHapticEnabledKey = @"com.qiu7c.neowc.moments.like-haptic";
NSString *const NeoWCMomentsLikeHapticIntensityKey = @"com.qiu7c.neowc.moments.like-haptic-intensity";
NSString *const NeoWCMomentsQuickCommentKey = @"com.qiu7c.neowc.moments.quick-comment";
NSString *const NeoWCMomentsForwardEnabledKey = @"com.qiu7c.neowc.moments.forward";
NSString *const NeoWCMomentsQuickPermissionsKey = @"com.qiu7c.neowc.moments.quick-permissions";
NSString *const NeoWCMomentsPreciseTimeKey = @"com.qiu7c.neowc.moments.precise-time";
NSString *const NeoWCMomentsPreciseTimeFormatKey = @"com.qiu7c.neowc.moments.precise-time-format";
NSString *const NeoWCMomentsPreciseTimeDefaultFormat = @"yyyy-MM-dd HH:mm:ss";
NSString *const NeoWCGameSelectorKey = @"com.qiu7c.neowc.enhance.game-selector";
NSString *const NeoWCChatJokerEnabledKey = @"com.qiu7c.neowc.enhance.chat-joker";
NSString *const NeoWCEmoticonToSelfieEnabledKey = @"com.qiu7c.neowc.enhance.emoticon-to-selfie";
NSString *const NeoWCReplySwipeEnabledKey = @"com.qiu7c.neowc.chat.reply-swipe";
NSString *const NeoWCQuoteJumpEnabledKey = @"com.qiu7c.neowc.chat.quote-jump";
NSString *const NeoWCQuoteJumpImageEnabledKey = @"com.qiu7c.neowc.chat.quote-jump.image";
NSString *const NeoWCQuoteJumpVideoEnabledKey = @"com.qiu7c.neowc.chat.quote-jump.video";
NSString *const NeoWCChatSearchButtonEnabledKey = @"com.qiu7c.neowc.chat.search-button";
NSString *const NeoWCChatTopBarCapsuleEnabledKey = @"com.qiu7c.neowc.chat.top-bar-capsule";
NSString *const NeoWCGroupAtTipsEnabledKey = @"com.qiu7c.neowc.chat.group-at-tips";
NSString *const NeoWCMessageBlockEnabledKey = @"com.qiu7c.neowc.message.block";
NSString *const NeoWCMessageBlockUsersKey = @"com.qiu7c.neowc.message.block.users";
NSString *const NeoWCMessageBlockKeywordsKey = @"com.qiu7c.neowc.message.block.keywords";
NSString *const NeoWCLongPressMenuEnabledKey = @"com.qiu7c.neowc.chat.long-press-menu";
NSString *const NeoWCLongPressMenuHiddenTitlesKey = @"com.qiu7c.neowc.chat.long-press-menu.hidden";
NSString *const NeoWCLongPressMenuPreferredOrderKey = @"com.qiu7c.neowc.chat.long-press-menu.order";
NSString *const NeoWCLongPressMenuTitleMapKey = @"com.qiu7c.neowc.chat.long-press-menu.rename";
NSString *const NeoWCLongPressMenuKnownTitlesKey = @"com.qiu7c.neowc.chat.long-press-menu.known";
NSString *const NeoWCLongPressMenuManualTitlesKey = @"com.qiu7c.neowc.chat.long-press-menu.manual";
NSString *const NeoWCHideSeparatorLinesKey = @"com.qiu7c.neowc.interface.hide-separator-lines";
NSString *const NeoWCGroupMemberReminderEnabledKey = @"com.qiu7c.neowc.message.group-member-reminder";
NSString *const NeoWCKeywordReminderEnabledKey = @"com.qiu7c.neowc.message.keyword-reminder";
NSString *const NeoWCKeywordReminderKeywordsKey = @"com.qiu7c.neowc.message.keyword-reminder.keywords";
NSString *const NeoWCRedEnvelopeDetailEnabledKey = @"com.qiu7c.neowc.chat.red-envelope-detail";
NSString *const NeoWCRedEnvelopeDetailCenterKey = @"com.qiu7c.neowc.chat.red-envelope-detail.center";
NSString *const NeoWCRedEnvelopeDetailFontSizeKey = @"com.qiu7c.neowc.chat.red-envelope-detail.font-size";
NSString *const NeoWCCallConfirmEnabledKey = @"com.qiu7c.neowc.chat.call-confirm";
NSString *const NeoWCQRCodeCameraSourceEnabledKey = @"com.qiu7c.neowc.enhance.qrcode-camera-source";
NSString *const NeoWCAutoOriginalImageEnabledKey = @"com.qiu7c.neowc.enhance.auto-original-image";
NSString *const NeoWCNotificationDirectChatEnabledKey = @"com.qiu7c.neowc.enhance.notification-direct-chat";
NSString *const NeoWCWalletBalanceEnabledKey = @"com.qiu7c.neowc.enhance.wallet-balance";
NSString *const NeoWCWalletBalanceFenKey = @"com.qiu7c.neowc.enhance.wallet-balance-fen";
NSString *const NeoWCContactsCountEnabledKey = @"com.qiu7c.neowc.enhance.contacts-count";
NSString *const NeoWCContactsCountKey = @"com.qiu7c.neowc.enhance.contacts-count-value";
NSString *const NeoWCStepOverrideEnabledKey = @"com.qiu7c.neowc.enhance.step-override";
NSString *const NeoWCStepCountKey = @"com.qiu7c.neowc.enhance.step-count";
NSString *const NeoWCStepCountDateKey = @"com.qiu7c.neowc.enhance.step-count-date";
NSString *const NeoWCStepModeKey = @"com.qiu7c.neowc.enhance.step-mode";
NSString *const NeoWCStepRandomMinimumKey = @"com.qiu7c.neowc.enhance.step-random-minimum";
NSString *const NeoWCStepRandomMaximumKey = @"com.qiu7c.neowc.enhance.step-random-maximum";
NSString *const NeoWCStepGradualEnabledKey = @"com.qiu7c.neowc.enhance.step-gradual";
NSString *const NeoWCStepDailyTargetKey = @"com.qiu7c.neowc.enhance.step-daily-target";
NSString *const NeoWCMeMenuKnownTitlesKey = @"com.qiu7c.neowc.interface.me-menu-known";
NSString *const NeoWCMeMenuHiddenTitlesKey = @"com.qiu7c.neowc.interface.me-menu-hidden";
NSString *const NeoWCAutoVoiceTranscriptionEnabledKey = @"com.qiu7c.neowc.chat.auto-voice-transcription";
NSString *const NeoWCAutoVoiceTranscriptionIgnoreGroupKey = @"com.qiu7c.neowc.chat.auto-voice-transcription.ignore-group";
NSString *const NeoWCAutoVoiceTranscriptionIgnorePrivateKey = @"com.qiu7c.neowc.chat.auto-voice-transcription.ignore-private";
NSString *const NeoWCAutoVoiceTranscriptionIgnoreSelfKey = @"com.qiu7c.neowc.chat.auto-voice-transcription.ignore-self";
NSString *const NeoWCHideScreenshotForwardKey = @"com.qiu7c.neowc.interface.hide-screenshot-forward";
NSString *const NeoWCPageScaleEnabledKey = @"com.qiu7c.neowc.interface.page-scale";
NSString *const NeoWCPageScaleGlobalPercentKey = @"com.qiu7c.neowc.interface.page-scale.global-percent";
NSString *const NeoWCSettingsPageScalePercentKey = @"com.qiu7c.neowc.interface.page-scale.settings-percent";
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
NSString *const NeoWCInputSwipeActionsEnabledKey = @"com.qiu7c.neowc.chat.input-swipe-actions";
NSString *const NeoWCMultiSelectExportEnabledKey = @"com.qiu7c.neowc.enhance.multi-select-export";
NSString *const NeoWCMultiSelectExportTextKey = @"com.qiu7c.neowc.enhance.multi-select-export.text";
NSString *const NeoWCMultiSelectSaveImagesKey = @"com.qiu7c.neowc.enhance.multi-select-export.images";
NSString *const NeoWCMultiSelectShareCardKey = @"com.qiu7c.neowc.enhance.multi-select-export.share-card";
NSString *const NeoWCEnhancementDidChangeNotification = @"NeoWCEnhancementDidChangeNotification";

CGFloat NeoWCScalePercentForDefaultsKey(NSString *key, CGFloat defaultValue) {
    id stored = key.length > 0 ? [[NSUserDefaults standardUserDefaults] objectForKey:key] : nil;
    CGFloat value = [stored respondsToSelector:@selector(doubleValue)] ? [stored doubleValue] : defaultValue;
    if (!isfinite(value)) value = defaultValue;
    return MIN(100.0, MAX(70.0, value));
}

NSString *NeoWCNormalizedMomentsDateFormat(NSString *format) {
    if (![format isKindOfClass:[NSString class]]) return nil;
    NSString *normalized = [format stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\\n"];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"\r" withString:@"\\n"];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    if (normalized.length == 0 || normalized.length > 64) return nil;

    static NSArray<NSString *> *tokens;
    static NSCharacterSet *letters;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tokens = @[@"yyyy", @"MM", @"dd", @"E", @"HH", @"mm", @"ss"];
        letters = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"];
    });

    NSUInteger index = 0;
    while (index < normalized.length) {
        if ([normalized characterAtIndex:index] == '\\' &&
            index + 1 < normalized.length &&
            [normalized characterAtIndex:index + 1] == 'n') {
            index += 2;
            continue;
        }
        NSRange characterRange = [normalized rangeOfComposedCharacterSequenceAtIndex:index];
        NSString *character = [normalized substringWithRange:characterRange];
        if ([character rangeOfCharacterFromSet:letters].location == NSNotFound) {
            index = NSMaxRange(characterRange);
            continue;
        }
        BOOL matched = NO;
        for (NSString *token in tokens) {
            if (index + token.length <= normalized.length &&
                [[normalized substringWithRange:NSMakeRange(index, token.length)] isEqualToString:token]) {
                index += token.length;
                matched = YES;
                break;
            }
        }
        if (!matched) return nil;
    }
    return normalized;
}

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
    id featureValue = [defaults objectForKey:key];
    BOOL featureEnabled = featureValue ? [featureValue boolValue] : [key isEqualToString:NeoWCAntiRevokeKey];
    return masterEnabled && featureEnabled;
}
