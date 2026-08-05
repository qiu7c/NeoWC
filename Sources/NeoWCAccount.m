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

NSString *NeoWCCurrentUserWXID(void) {
    Class contactManagerClass = objc_getClass("CContactMgr");
    if (!contactManagerClass) return nil;
    SEL selfContactSelector = sel_registerName("getSelfContact");
    id manager = NeoWCServiceForClass(contactManagerClass);
    if (!manager || ![manager respondsToSelector:selfContactSelector]) return nil;
    id contact = ((id (*)(id, SEL))objc_msgSend)(manager, selfContactSelector);
    if (!contact) return nil;

    SEL userNameSelector = sel_registerName("m_nsUsrName");
    id value = nil;
    if ([contact respondsToSelector:userNameSelector]) {
        value = ((id (*)(id, SEL))objc_msgSend)(contact, userNameSelector);
    } else {
        @try { value = [contact valueForKey:@"m_nsUsrName"]; }
        @catch (__unused NSException *exception) { return nil; }
    }
    if (![value isKindOfClass:[NSString class]]) return nil;
    NSString *wxid = [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return wxid.length > 0 ? wxid : nil;
}
