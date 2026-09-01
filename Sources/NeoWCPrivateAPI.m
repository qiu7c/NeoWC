#import "NeoWCPrivateAPI.h"
#import "NeoWCAccount.h"
#import "NeoWCLogging.h"
#import <objc/message.h>
#import <objc/runtime.h>
#include <string.h>

static const char *NeoWCPrivateUnqualifiedType(const char *type) {
    if (!type) return "";
    while (*type && strchr("rnNoORV", *type)) type++;
    return type;
}

static BOOL NeoWCPrivateTypeIsObject(const char *type) {
    return NeoWCPrivateUnqualifiedType(type)[0] == '@';
}

static BOOL NeoWCPrivateTypeIsInteger(const char *type) {
    const char value = NeoWCPrivateUnqualifiedType(type)[0];
    return value && strchr("cCsSiIlLqQB", value) != NULL;
}

static NSMethodSignature *NeoWCPrivateSignature(id receiver,
                                                SEL selector,
                                                NSUInteger argumentCount) {
    if (!receiver || !selector || ![receiver respondsToSelector:selector]) return nil;
    NSMethodSignature *signature = [receiver methodSignatureForSelector:selector];
    return signature.numberOfArguments == argumentCount ? signature : nil;
}

static BOOL NeoWCPrivateObjectArguments(NSMethodSignature *signature,
                                        NSRange indexes) {
    if (!signature || NSMaxRange(indexes) > signature.numberOfArguments) return NO;
    for (NSUInteger index = indexes.location; index < NSMaxRange(indexes); index++) {
        if (!NeoWCPrivateTypeIsObject([signature getArgumentTypeAtIndex:index])) return NO;
    }
    return YES;
}

id NeoWCPrivateService(NSString *className) {
    Class serviceClass = className.length > 0 ? NSClassFromString(className) : Nil;
    return serviceClass ? NeoWCServiceForClass(serviceClass) : nil;
}

id NeoWCPrivateContact(NSString *userName) {
    if (userName.length == 0) return nil;
    id manager = NeoWCPrivateService(@"CContactMgr");
    for (NSString *selectorName in @[
        @"getContactByName:", @"getContactByNameFromCache:", @"getContact:"
    ]) {
        SEL selector = NSSelectorFromString(selectorName);
        NSMethodSignature *signature = NeoWCPrivateSignature(manager, selector, 3);
        if (!NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 1)) ||
            !NeoWCPrivateTypeIsObject(signature.methodReturnType)) continue;
        @try {
            id contact = ((id (*)(id, SEL, id))objc_msgSend)(manager, selector, userName);
            if (contact) return contact;
        } @catch (NSException *exception) {
            NeoWCLog(@"联系人适配 %@ 调用失败：%@", selectorName,
                     exception.reason ?: exception.name);
        }
    }
    return nil;
}

static UIViewController *NeoWCPrivateProfileController(id contact,
                                                        NSString *userName) {
    Class handlerClass = NSClassFromString(@"MMURLHandler");
    SEL sharedSelector = NSSelectorFromString(@"sharedInstance");
    id handler = nil;
    NSMethodSignature *sharedSignature = NeoWCPrivateSignature(handlerClass, sharedSelector, 2);
    if (sharedSignature && NeoWCPrivateTypeIsObject(sharedSignature.methodReturnType)) {
        @try { handler = ((id (*)(id, SEL))objc_msgSend)(handlerClass, sharedSelector); }
        @catch (__unused NSException *exception) {}
    }

    SEL constructSelector = NSSelectorFromString(@"constructContactInfoView:withUserName:");
    NSMethodSignature *constructSignature = NeoWCPrivateSignature(handler, constructSelector, 4);
    if (NeoWCPrivateObjectArguments(constructSignature, NSMakeRange(2, 2)) &&
        NeoWCPrivateTypeIsObject(constructSignature.methodReturnType)) {
        @try {
            id controller = ((id (*)(id, SEL, id, id))objc_msgSend)(
                handler, constructSelector, contact, userName);
            if ([controller isKindOfClass:UIViewController.class]) return controller;
        } @catch (NSException *exception) {
            NeoWCLog(@"官方资料页构造失败：%@", exception.reason ?: exception.name);
        }
    }

    Class controllerClass = NSClassFromString(@"ContactInfoViewController");
    if (!controllerClass) return nil;
    UIViewController *controller = nil;
    SEL initializer = NSSelectorFromString(@"initWithContact:");
    id allocatedController = [controllerClass alloc];
    NSMethodSignature *initializerSignature = [allocatedController methodSignatureForSelector:initializer];
    if (initializerSignature.numberOfArguments == 3 &&
        NeoWCPrivateObjectArguments(initializerSignature, NSMakeRange(2, 1)) &&
        NeoWCPrivateTypeIsObject(initializerSignature.methodReturnType)) {
        @try {
            controller = ((id (*)(id, SEL, id))objc_msgSend)(
                allocatedController, initializer, contact);
        } @catch (__unused NSException *exception) {}
    }
    if (!controller) controller = [[controllerClass alloc] init];
    if (!controller) return nil;

    SEL setter = NSSelectorFromString(@"setM_contact:");
    NSMethodSignature *setterSignature = NeoWCPrivateSignature(controller, setter, 3);
    if (NeoWCPrivateObjectArguments(setterSignature, NSMakeRange(2, 1))) {
        @try {
            ((void (*)(id, SEL, id))objc_msgSend)(controller, setter, contact);
            return controller;
        } @catch (__unused NSException *exception) {}
    }
    @try {
        [controller setValue:contact forKey:@"m_contact"];
        return controller;
    } @catch (NSException *exception) {
        NeoWCLog(@"资料页联系人注入失败：%@", exception.reason ?: exception.name);
        return nil;
    }
}

BOOL NeoWCPushPrivateContactProfile(UIViewController *source, NSString *userName) {
    if (!source || userName.length == 0) return NO;
    id contact = NeoWCPrivateContact(userName);
    if (!contact) {
        NeoWCLog(@"资料页适配未找到联系人：%@", userName);
        return NO;
    }
    UIViewController *controller = NeoWCPrivateProfileController(contact, userName);
    if (!controller) {
        NeoWCLog(@"资料页适配无法构造控制器：%@", userName);
        return NO;
    }
    UINavigationController *navigationController = source.navigationController;
    if (!navigationController && [source isKindOfClass:UINavigationController.class]) {
        navigationController = (UINavigationController *)source;
    }
    if (!navigationController) {
        NeoWCLog(@"资料页适配未找到导航控制器：%@", userName);
        return NO;
    }
    [navigationController pushViewController:controller animated:YES];
    return YES;
}

static NeoWCPrivateGroupInvitationResult
NeoWCPrivateInvokeGroupInvitation(id manager,
                                  NSString *selectorName,
                                  NSString *groupUserName,
                                  NSArray<NSString *> *memberList) {
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = NeoWCPrivateSignature(manager, selector, 4);
    if (!NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 2))) {
        return NeoWCPrivateGroupInvitationResultUnsupported;
    }
    const char *returnType = NeoWCPrivateUnqualifiedType(signature.methodReturnType);
    @try {
        if (strcmp(returnType, @encode(void)) == 0) {
            ((void (*)(id, SEL, id, id))objc_msgSend)(manager, selector,
                                                      groupUserName, memberList);
            return NeoWCPrivateGroupInvitationResultSubmitted;
        }
        if (NeoWCPrivateTypeIsObject(returnType)) {
            (void)((id (*)(id, SEL, id, id))objc_msgSend)(manager, selector,
                                                          groupUserName, memberList);
            return NeoWCPrivateGroupInvitationResultSubmitted;
        }
        if (NeoWCPrivateTypeIsInteger(returnType)) {
            (void)((NSInteger (*)(id, SEL, id, id))objc_msgSend)(
                manager, selector, groupUserName, memberList);
            return NeoWCPrivateGroupInvitationResultSubmitted;
        }
    } @catch (NSException *exception) {
        NeoWCLog(@"群邀请适配 %@ 调用失败：%@", selectorName,
                 exception.reason ?: exception.name);
        return NeoWCPrivateGroupInvitationResultRejected;
    }
    return NeoWCPrivateGroupInvitationResultUnsupported;
}

NeoWCPrivateGroupInvitationResult
NeoWCPrivateInviteGroupMember(NSString *groupUserName, NSString *memberUserName) {
    if (![groupUserName hasSuffix:@"@chatroom"] || memberUserName.length == 0 ||
        [memberUserName hasSuffix:@"@chatroom"] ||
        [memberUserName isEqualToString:@"filehelper"] ||
        [memberUserName isEqualToString:NeoWCCurrentUserWXID()]) {
        return NeoWCPrivateGroupInvitationResultRejected;
    }
    id manager = NeoWCPrivateService(@"CContactMgr");
    if (!manager) return NeoWCPrivateGroupInvitationResultUnsupported;
    NSArray<NSString *> *members = @[memberUserName];

    // MiYou/微信助手 3.9-5 uses this exact CContactMgr call and object ABI.
    NeoWCPrivateGroupInvitationResult result = NeoWCPrivateInvokeGroupInvitation(
        manager, @"InviteGroupMember:withMemberList:", groupUserName, members);
    if (result != NeoWCPrivateGroupInvitationResultUnsupported) return result;

    // Older WeChat builds expose the same operation as direct group addition.
    result = NeoWCPrivateInvokeGroupInvitation(
        manager, @"AddGroupMember:withMemberList:", groupUserName, members);
    if (result == NeoWCPrivateGroupInvitationResultUnsupported) {
        NeoWCLog(@"群邀请适配未发现可用接口：%@ -> %@", memberUserName, groupUserName);
    }
    return result;
}
