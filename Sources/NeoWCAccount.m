#import "NeoWCAccount.h"
#import <objc/message.h>
#import <objc/runtime.h>

static NSString *const NeoWCCachedWXIDKey = @"com.qiu7c.neowc.authorization.cached-wxid";
static NSString *const NeoWCCachedNicknameKey = @"com.qiu7c.neowc.authorization.cached-nickname";
static NSString *const NeoWCCachedHeadImageURLKey = @"com.qiu7c.neowc.authorization.cached-head-image-url";

static id NeoWCServiceCenterFromCurrentContext(id self, SEL command) {
    (void)self;
    (void)command;
    Class contextClass = objc_getClass("MMContext");
    SEL currentContextSelector = sel_registerName("currentContext");
    SEL serviceCenterSelector = sel_registerName("serviceCenter");
    if (!contextClass || ![contextClass respondsToSelector:currentContextSelector]) return nil;
    id context = ((id (*)(id, SEL))objc_msgSend)(contextClass, currentContextSelector);
    if (!context || ![context respondsToSelector:serviceCenterSelector]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(context, serviceCenterSelector);
}

void NeoWCInstallServiceCenterCompatibility(void) {
    Class centerClass = objc_getClass("MMServiceCenter");
    if (!centerClass) return;
    SEL selector = sel_registerName("defaultCenter");
    if ([centerClass respondsToSelector:selector]) return;
    Class metaclass = object_getClass(centerClass);
    if (metaclass) class_addMethod(metaclass, selector, (IMP)NeoWCServiceCenterFromCurrentContext, "@@:");
}

id NeoWCDefaultServiceCenter(void) {
    id contextCenter = NeoWCServiceCenterFromCurrentContext(nil, NULL);
    if (contextCenter) return contextCenter;
    Class centerClass = objc_getClass("MMServiceCenter");
    SEL selector = sel_registerName("defaultCenter");
    if (!centerClass || ![centerClass respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(centerClass, selector);
}

id NeoWCServiceForClass(Class serviceClass) {
    id center = NeoWCDefaultServiceCenter();
    SEL selector = sel_registerName("getService:");
    if (!center || !serviceClass || ![center respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL, Class))objc_msgSend)(center, selector, serviceClass);
}

static NSString *NeoWCContactString(id contact, const char *selectorName) {
    if (!contact || !selectorName) return nil;
    SEL selector = sel_registerName(selectorName);
    id value = nil;
    if ([contact respondsToSelector:selector]) {
        value = ((id (*)(id, SEL))objc_msgSend)(contact, selector);
    } else {
        NSString *key = [NSString stringWithUTF8String:selectorName];
        @try { value = [contact valueForKey:key]; }
        @catch (__unused NSException *exception) { return nil; }
    }
    if (![value isKindOfClass:[NSString class]]) return nil;
    NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return text.length > 0 ? text : nil;
}

BOOL NeoWCUpdateCachedCurrentUserContact(id contact) {
    NSString *wxid = NeoWCContactString(contact, "m_nsUsrName");
    if (wxid.length == 0) return NO;
    NSString *nickname = NeoWCContactString(contact, "m_nsNickName");
    NSString *headImageURL = NeoWCContactString(contact, "m_nsHeadImgUrl");
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *cachedWXID = [defaults stringForKey:NeoWCCachedWXIDKey];
    NSString *cachedNickname = [defaults stringForKey:NeoWCCachedNicknameKey];
    NSString *cachedHeadImageURL = [defaults stringForKey:NeoWCCachedHeadImageURLKey];
    BOOL wxidChanged = ![(cachedWXID ?: @"") isEqualToString:wxid];
    BOOL nicknameChanged = ![(cachedNickname ?: @"") isEqualToString:(nickname ?: @"")];
    BOOL headImageChanged = ![(cachedHeadImageURL ?: @"") isEqualToString:(headImageURL ?: @"")];
    if (!wxidChanged && !nicknameChanged && !headImageChanged) return NO;

    if (wxidChanged) [defaults setObject:wxid forKey:NeoWCCachedWXIDKey];
    if (nicknameChanged) {
        if (nickname.length > 0) [defaults setObject:nickname forKey:NeoWCCachedNicknameKey];
        else [defaults removeObjectForKey:NeoWCCachedNicknameKey];
    }
    if (headImageChanged) {
        if (headImageURL.length > 0) [defaults setObject:headImageURL forKey:NeoWCCachedHeadImageURLKey];
        else [defaults removeObjectForKey:NeoWCCachedHeadImageURLKey];
    }
    return YES;
}

BOOL NeoWCRefreshCachedCurrentUserContact(void) {
    Class contactManagerClass = objc_getClass("CContactMgr");
    id manager = NeoWCServiceForClass(contactManagerClass);
    SEL selector = sel_registerName("getSelfContact");
    if (!manager || ![manager respondsToSelector:selector]) return NO;
    id contact = ((id (*)(id, SEL))objc_msgSend)(manager, selector);
    return NeoWCUpdateCachedCurrentUserContact(contact);
}

NSString *NeoWCCurrentUserWXID(void) {
    return [NSUserDefaults.standardUserDefaults stringForKey:NeoWCCachedWXIDKey];
}

NSString *NeoWCCurrentUserNickname(void) {
    return [NSUserDefaults.standardUserDefaults stringForKey:NeoWCCachedNicknameKey];
}

NSString *NeoWCCurrentUserHeadImageURL(void) {
    return [NSUserDefaults.standardUserDefaults stringForKey:NeoWCCachedHeadImageURLKey];
}
