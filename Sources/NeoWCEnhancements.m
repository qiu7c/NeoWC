#import "NeoWCEnhancements.h"

NSString *const NeoWCAutoDeviceLoginKey = @"com.qiu7c.neowc.enhance.auto-device-login";
NSString *const NeoWCAutoGameAuthorizeKey = @"com.qiu7c.neowc.enhance.auto-game-authorize";
NSString *const NeoWCMomentsDoubleTapLikeKey = @"com.qiu7c.neowc.moments.double-tap-like";
NSString *const NeoWCMomentsQuickCommentKey = @"com.qiu7c.neowc.moments.quick-comment";

BOOL NeoWCEnhancementEnabled(NSString *key) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id masterValue = [defaults objectForKey:@"com.qiu7c.neowc.enabled"];
    BOOL masterEnabled = masterValue ? [masterValue boolValue] : YES;
    return masterEnabled && [defaults boolForKey:key];
}
