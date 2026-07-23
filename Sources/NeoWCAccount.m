#import "NeoWCAccount.h"
#import <objc/message.h>
#import <objc/runtime.h>

NSString *NeoWCCurrentUserWXID(void) {
    Class centerClass = objc_getClass("MMServiceCenter");
    Class contactManagerClass = objc_getClass("CContactMgr");
    if (!centerClass || !contactManagerClass) return nil;

    SEL defaultCenterSelector = sel_registerName("defaultCenter");
    SEL getServiceSelector = sel_registerName("getService:");
    SEL selfContactSelector = sel_registerName("getSelfContact");
    SEL userNameSelector = sel_registerName("userName");
    if (![centerClass respondsToSelector:defaultCenterSelector]) return nil;

    id center = ((id (*)(id, SEL))objc_msgSend)(centerClass, defaultCenterSelector);
    if (!center || ![center respondsToSelector:getServiceSelector]) return nil;
    id manager = ((id (*)(id, SEL, Class))objc_msgSend)(center, getServiceSelector, contactManagerClass);
    if (!manager || ![manager respondsToSelector:selfContactSelector]) return nil;
    id contact = ((id (*)(id, SEL))objc_msgSend)(manager, selfContactSelector);
    if (!contact || ![contact respondsToSelector:userNameSelector]) return nil;

    id value = ((id (*)(id, SEL))objc_msgSend)(contact, userNameSelector);
    if (![value isKindOfClass:[NSString class]]) return nil;
    NSString *wxid = [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return wxid.length > 0 ? wxid : nil;
}
