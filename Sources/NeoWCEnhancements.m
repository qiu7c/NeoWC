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
NSString *const NeoWCEnhancementDidChangeNotification = @"NeoWCEnhancementDidChangeNotification";

BOOL NeoWCEnhancementEnabled(NSString *key) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id masterValue = [defaults objectForKey:@"com.qiu7c.neowc.enabled"];
    BOOL masterEnabled = masterValue ? [masterValue boolValue] : YES;
    return masterEnabled && [defaults boolForKey:key];
}
