#import "NeoWCAccount.h"
#import <objc/message.h>
#import <objc/runtime.h>

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
    NeoWCInstallServiceCenterCompatibility();
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

static id NeoWCCurrentUserContact(void) {
    Class contactManagerClass = objc_getClass("CContactMgr");
    if (!contactManagerClass) return nil;
    SEL selfContactSelector = sel_registerName("getSelfContact");
    id manager = NeoWCServiceForClass(contactManagerClass);
    if (!manager || ![manager respondsToSelector:selfContactSelector]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(manager, selfContactSelector);
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

NSString *NeoWCCurrentUserWXID(void) {
    return NeoWCContactString(NeoWCCurrentUserContact(), "m_nsUsrName");
}

NSString *NeoWCCurrentUserNickname(void) {
    return NeoWCContactString(NeoWCCurrentUserContact(), "m_nsNickName");
}

NSString *NeoWCCurrentUserHeadImageURL(void) {
    return NeoWCContactString(NeoWCCurrentUserContact(), "m_nsHeadImgUrl");
}
