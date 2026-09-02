#import "NeoWCPrivateAPI.h"
#import "NeoWCAccount.h"
#import "NeoWCLogging.h"
#import <objc/message.h>
#import <objc/runtime.h>
#include <string.h>

#pragma mark - Runtime ABI Helpers

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

static BOOL NeoWCPrivateTypeIsVoid(const char *type) {
    return NeoWCPrivateUnqualifiedType(type)[0] == 'v';
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

#pragma mark - Service Center

id NeoWCPrivateService(NSString *className) {
    Class serviceClass = className.length > 0 ? NSClassFromString(className) : Nil;
    return serviceClass ? NeoWCServiceForClass(serviceClass) : nil;
}

#pragma mark - Current Chat

static id NeoWCPrivateNoArgumentObject(id receiver, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = NeoWCPrivateSignature(receiver, selector, 2);
    if (!signature || !NeoWCPrivateTypeIsObject(signature.methodReturnType)) return nil;
    @try { return ((id (*)(id, SEL))objc_msgSend)(receiver, selector); }
    @catch (__unused NSException *exception) { return nil; }
}

static id NeoWCPrivateObjectField(id object, NSArray<NSString *> *names) {
    if (!object) return nil;
    for (NSString *name in names) {
        id value = NeoWCPrivateNoArgumentObject(object, name);
        if (value && value != NSNull.null) return value;
        @try {
            value = [object valueForKey:name];
            if (value && value != NSNull.null) return value;
        } @catch (__unused NSException *exception) {}
    }
    return nil;
}

static NSString *NeoWCPrivateNonemptyString(id value) {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSString *string = [(NSString *)value stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return string.length > 0 ? string : nil;
}

static UIViewController *NeoWCPrivateChatControllerInTree(UIViewController *controller,
                                                           Class chatControllerClass) {
    if (!controller || !chatControllerClass) return nil;
    UIViewController *found = NeoWCPrivateChatControllerInTree(controller.presentedViewController,
                                                               chatControllerClass);
    if (found) return found;
    if ([controller isKindOfClass:UINavigationController.class]) {
        found = NeoWCPrivateChatControllerInTree(
            ((UINavigationController *)controller).visibleViewController, chatControllerClass);
        if (found) return found;
    }
    if ([controller isKindOfClass:UITabBarController.class]) {
        found = NeoWCPrivateChatControllerInTree(
            ((UITabBarController *)controller).selectedViewController, chatControllerClass);
        if (found) return found;
    }
    if ([controller isKindOfClass:chatControllerClass] && controller.isViewLoaded &&
        controller.view.window &&
        (!controller.navigationController || controller.navigationController.topViewController == controller)) {
        return controller;
    }
    for (UIViewController *child in controller.childViewControllers.reverseObjectEnumerator) {
        found = NeoWCPrivateChatControllerInTree(child, chatControllerClass);
        if (found) return found;
    }
    return nil;
}

UIViewController *NeoWCPrivateCurrentChatController(void) {
    NSCAssert(NSThread.isMainThread, @"Current chat resolution must run on the main thread");
    Class chatControllerClass = NSClassFromString(@"BaseMsgContentViewController");
    if (!chatControllerClass) return nil;
    NSMutableOrderedSet<UIWindow *> *windows = [NSMutableOrderedSet orderedSet];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive ||
                ![scene isKindOfClass:UIWindowScene.class]) continue;
            [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
        }
    }
    [windows addObjectsFromArray:UIApplication.sharedApplication.windows ?: @[]];
    for (UIWindow *window in windows.reverseObjectEnumerator) {
        if (window.hidden || window.alpha <= 0.0 ||
            [NSStringFromClass(window.class) containsString:@"iConsole"]) continue;
        UIViewController *controller = NeoWCPrivateChatControllerInTree(
            window.rootViewController, chatControllerClass);
        if (controller) return controller;
    }
    return nil;
}

id NeoWCPrivateChatContact(id chatController) {
    if (!chatController) chatController = NeoWCPrivateCurrentChatController();
    for (NSString *selectorName in @[@"GetContact", @"GetCContact"]) {
        id contact = NeoWCPrivateNoArgumentObject(chatController, selectorName);
        if (contact) return contact;
    }
    return NeoWCPrivateObjectField(chatController, @[@"m_contact", @"chatContact", @"contact"]);
}

NSString *NeoWCPrivateChatUserName(id chatController) {
    if (!chatController) chatController = NeoWCPrivateCurrentChatController();
    for (NSString *selectorName in @[@"getCurrentChatName", @"getChatUserName"]) {
        NSString *userName = NeoWCPrivateNonemptyString(
            NeoWCPrivateNoArgumentObject(chatController, selectorName));
        if (userName.length > 0) return userName;
    }
    id contact = NeoWCPrivateChatContact(chatController);
    NSString *userName = NeoWCPrivateNonemptyString(NeoWCPrivateObjectField(
        contact, @[@"m_nsUsrName", @"m_nsUserName", @"getUsrName", @"userName", @"username"]));
    if (userName.length > 0) return userName;
    return NeoWCPrivateNonemptyString(NeoWCPrivateObjectField(
        chatController, @[@"m_nsUsrName", @"m_nsUserName", @"sessionUserName"]));
}

#pragma mark - Contacts

id NeoWCPrivateContact(NSString *userName) {
    if (userName.length == 0) return nil;
    id manager = NeoWCPrivateService(@"CContactMgr");
    for (NSString *selectorName in @[
        @"getContactByName:", @"getContactForSearchByName:",
        @"getContactByNameFromCache:", @"getContact:"
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

static NSString *NeoWCPrivateContactString(id contact, NSArray<NSString *> *names) {
    return NeoWCPrivateNonemptyString(NeoWCPrivateObjectField(contact, names));
}

NSString *NeoWCPrivateContactUserName(id contact) {
    return NeoWCPrivateContactString(contact,
        @[@"m_nsUsrName", @"m_nsUserName", @"getUsrName", @"userName", @"username"]);
}

NSString *NeoWCPrivateContactNickname(id contact) {
    return NeoWCPrivateContactString(contact,
        @[@"m_nsNickName", @"getNickName", @"nickName", @"nickname"]);
}

NSString *NeoWCPrivateContactRemark(id contact) {
    return NeoWCPrivateContactString(contact,
        @[@"m_nsRemark", @"getRemark", @"remark", @"remarkName"]);
}

NSString *NeoWCPrivateContactAlias(id contact) {
    return NeoWCPrivateContactString(contact,
        @[@"m_nsAliasName", @"m_nsAlias", @"getAlias", @"alias", @"aliasName"]);
}

NSString *NeoWCPrivateContactDisplayName(id contact, NSString *fallback) {
    NSString *displayName = NeoWCPrivateContactString(contact,
        @[@"getContactDisplayName", @"getDisplayName"]);
    if (displayName.length > 0) return displayName;
    displayName = NeoWCPrivateContactRemark(contact);
    if (displayName.length > 0) return displayName;
    displayName = NeoWCPrivateContactNickname(contact);
    if (displayName.length > 0) return displayName;
    return NeoWCPrivateNonemptyString(fallback);
}

NSString *NeoWCPrivateContactHeadImageURL(id contact) {
    return NeoWCPrivateContactString(contact, @[
        @"m_nsHeadHDImgUrl", @"m_nsHeadImgUrlHD", @"m_nsHeadImgUrl",
        @"headImgUrl", @"headImageURL"
    ]);
}

UIImage *NeoWCPrivateContactAvatarImage(id contact) {
    NSCAssert(NSThread.isMainThread, @"Contact avatar images must be read on the main thread");
    for (NSString *selectorName in @[@"getContactHeadImage", @"contactHeadImage", @"headImage"]) {
        id image = NeoWCPrivateNoArgumentObject(contact, selectorName);
        if ([image isKindOfClass:UIImage.class]) return image;
    }
    return nil;
}

static BOOL NeoWCPrivateAvatarHelperSignature(NSMethodSignature *signature) {
    return signature && NeoWCPrivateTypeIsObject(signature.methodReturnType) &&
        NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 2)) &&
        NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:4]) &&
        NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:5]);
}

UIView *NeoWCPrivateContactAvatarView(id contact, NSString *userName, BOOL roundCorner) {
    NSCAssert(NSThread.isMainThread, @"Contact avatar views must be built on the main thread");
    NSString *resolvedUserName = NeoWCPrivateContactUserName(contact) ?:
        NeoWCPrivateNonemptyString(userName);
    NSString *headImageURL = NeoWCPrivateContactHeadImageURL(contact) ?: @"";
    Class helperClass = NSClassFromString(@"MMHeadImageHelper");
    if (helperClass && resolvedUserName.length > 0) {
        for (NSString *selectorName in @[
            @"getContactHeadImageViewWithUsrName:headImgUrl:bAutoUpdate:bRoundCorner:",
            @"getMainFrameHeadImageViewWithUsrName:headImgUrl:bAutoUpdate:bRoundCorner:",
            @"getProfileHeadImageViewWithUsrName:headImgUrl:bAutoUpdate:bRoundCorner:"
        ]) {
            SEL selector = NSSelectorFromString(selectorName);
            NSMethodSignature *signature = NeoWCPrivateSignature(helperClass, selector, 6);
            if (!NeoWCPrivateAvatarHelperSignature(signature)) continue;
            @try {
                id view = ((id (*)(id, SEL, id, id, BOOL, BOOL))objc_msgSend)(
                    helperClass, selector, resolvedUserName, headImageURL, YES, roundCorner);
                if ([view isKindOfClass:UIView.class]) return view;
            } @catch (NSException *exception) {
                NeoWCLog(@"头像适配 %@ 调用失败：%@", selectorName,
                         exception.reason ?: exception.name);
            }
        }
    }
    UIImage *image = NeoWCPrivateContactAvatarImage(contact);
    if (!image) return nil;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    return imageView;
}

#pragma mark - Contact and Group Lists

static NSArray *NeoWCPrivateEnumerableSnapshot(id value) {
    if (!value || [value isKindOfClass:NSString.class] ||
        ![value conformsToProtocol:@protocol(NSFastEnumeration)]) return @[];
    NSMutableArray *items = [NSMutableArray array];
    @try {
        for (id item in value) if (item) [items addObject:item];
    } @catch (__unused NSException *exception) {
        return @[];
    }
    return items;
}

NSArray *NeoWCPrivateContactList(void) {
    NSCAssert(NSThread.isMainThread, @"Contact lists must be read on the main thread");
    id manager = NeoWCPrivateService(@"CContactMgr");
    SEL selector = NSSelectorFromString(@"getContactList:contactType:");
    NSMethodSignature *signature = NeoWCPrivateSignature(manager, selector, 4);
    if (!signature || !NeoWCPrivateTypeIsObject(signature.methodReturnType) ||
        !NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:2]) ||
        !NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:3])) return @[];
    @try {
        id value = ((id (*)(id, SEL, NSInteger, NSInteger))objc_msgSend)(
            manager, selector, 1, 0);
        return NeoWCPrivateEnumerableSnapshot(value);
    } @catch (NSException *exception) {
        NeoWCLog(@"联系人列表适配调用失败：%@", exception.reason ?: exception.name);
        return @[];
    }
}

static BOOL NeoWCPrivateContactIsGroup(id contact, NSString *userName) {
    if ([userName hasSuffix:@"@chatroom"]) return YES;
    SEL selector = NSSelectorFromString(@"isChatroom");
    NSMethodSignature *signature = NeoWCPrivateSignature(contact, selector, 2);
    if (!signature || !NeoWCPrivateTypeIsInteger(signature.methodReturnType)) return NO;
    @try { return ((BOOL (*)(id, SEL))objc_msgSend)(contact, selector); }
    @catch (__unused NSException *exception) { return NO; }
}

NSArray *NeoWCPrivateGroupContactList(void) {
    NSCAssert(NSThread.isMainThread, @"Group lists must be read on the main thread");
    NSMutableArray *groups = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    void (^appendContact)(id) = ^(id contact) {
        NSString *userName = NeoWCPrivateContactUserName(contact);
        if (userName.length == 0 || [seen containsObject:userName] ||
            !NeoWCPrivateContactIsGroup(contact, userName)) return;
        [seen addObject:userName];
        [groups addObject:contact];
    };

    id sessionManager = NeoWCPrivateService(@"MMNewSessionMgr");
    id sessions = NeoWCPrivateNoArgumentObject(sessionManager, @"SessionNewArray");
    for (id session in NeoWCPrivateEnumerableSnapshot(sessions)) {
        NSString *userName = NeoWCPrivateContactUserName(session);
        if (userName.length == 0 || [seen containsObject:userName]) continue;
        appendContact(NeoWCPrivateContact(userName));
    }
    for (id contact in NeoWCPrivateContactList()) appendContact(contact);

    id dataLogic = NeoWCPrivateService(@"ContactsDataLogic");
    id cachedGroups = NeoWCPrivateNoArgumentObject(dataLogic, @"getChatRoomContacts");
    for (id contact in NeoWCPrivateEnumerableSnapshot(cachedGroups)) appendContact(contact);
    return groups;
}

#pragma mark - Native Navigation

static UIViewController *NeoWCPrivateProfileController(id contact,
                                                        NSString *userName) {
    Class controllerClass = NSClassFromString(@"ContactInfoViewController");
    if (!controllerClass) return nil;
    UIViewController *controller = [[controllerClass alloc] init];
    if (!controller) return nil;

    SEL setter = NSSelectorFromString(@"setM_contact:");
    NSMethodSignature *setterSignature = NeoWCPrivateSignature(controller, setter, 3);
    if (setterSignature && NeoWCPrivateTypeIsVoid(setterSignature.methodReturnType) &&
        NeoWCPrivateObjectArguments(setterSignature, NSMakeRange(2, 1))) {
        @try {
            ((void (*)(id, SEL, id))objc_msgSend)(controller, setter, contact);
            return controller;
        } @catch (__unused NSException *exception) {}
    }
    @try {
        [controller setValue:contact forKey:@"m_contact"];
        return controller;
    } @catch (NSException *exception) {
        NeoWCLog(@"资料页联系人注入失败 %@：%@", userName,
                 exception.reason ?: exception.name);
        return nil;
    }
}

BOOL NeoWCPushPrivateContactProfile(UIViewController *source, NSString *userName) {
    NSCAssert(NSThread.isMainThread, @"Native profile navigation must run on the main thread");
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

static UINavigationController *NeoWCPrivateNavigationController(UIViewController *source) {
    if ([source isKindOfClass:UINavigationController.class]) {
        return (UINavigationController *)source;
    }
    if (source.navigationController) return source.navigationController;
    Class managerClass = NSClassFromString(@"CAppViewControllerManager");
    SEL selector = NSSelectorFromString(@"getCurrentNavigationController");
    NSMethodSignature *signature = NeoWCPrivateSignature(managerClass, selector, 2);
    if (!signature || !NeoWCPrivateTypeIsObject(signature.methodReturnType)) return nil;
    @try {
        id navigationController = ((id (*)(id, SEL))objc_msgSend)(managerClass, selector);
        return [navigationController isKindOfClass:UINavigationController.class]
            ? navigationController : nil;
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

BOOL NeoWCPushPrivateGroupProfile(UIViewController *source, NSString *groupUserName) {
    NSCAssert(NSThread.isMainThread, @"Native group navigation must run on the main thread");
    if (!source || ![groupUserName hasSuffix:@"@chatroom"]) return NO;
    id contact = NeoWCPrivateContact(groupUserName);
    Class controllerClass = NSClassFromString(@"ChatRoomInfoViewController");
    UIViewController *controller = contact && controllerClass ? [[controllerClass alloc] init] : nil;
    if (!controller) return NO;

    BOOL injected = NO;
    SEL setter = NSSelectorFromString(@"setM_chatRoomContact:");
    NSMethodSignature *signature = NeoWCPrivateSignature(controller, setter, 3);
    if (signature && NeoWCPrivateTypeIsVoid(signature.methodReturnType) &&
        NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 1))) {
        @try {
            ((void (*)(id, SEL, id))objc_msgSend)(controller, setter, contact);
            injected = YES;
        } @catch (__unused NSException *exception) {}
    }
    if (!injected) {
        @try {
            [controller setValue:contact forKey:@"m_chatRoomContact"];
            injected = YES;
        } @catch (__unused NSException *exception) {}
    }
    UINavigationController *navigationController = NeoWCPrivateNavigationController(source);
    if (!injected || !navigationController) return NO;
    [navigationController pushViewController:controller animated:YES];
    return YES;
}

static BOOL NeoWCPrivatePushChatSelector(id messageLogic,
                                         NSString *selectorName,
                                         id target,
                                         UINavigationController *navigationController,
                                         BOOL animated) {
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = NeoWCPrivateSignature(messageLogic, selector, 5);
    if (!signature || !NeoWCPrivateTypeIsVoid(signature.methodReturnType) ||
        !NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 2)) ||
        !NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:4])) return NO;
    @try {
        ((void (*)(id, SEL, id, id, BOOL))objc_msgSend)(
            messageLogic, selector, target, navigationController, animated);
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"聊天页适配 %@ 调用失败：%@", selectorName,
                 exception.reason ?: exception.name);
        return NO;
    }
}

BOOL NeoWCPushPrivateChat(UIViewController *source, NSString *userName, BOOL animated) {
    NSCAssert(NSThread.isMainThread, @"Native chat navigation must run on the main thread");
    NSString *resolvedUserName = [userName isKindOfClass:NSString.class] && userName.length > 0
        ? userName : nil;
    if (resolvedUserName.length == 0) return NO;
    UINavigationController *navigationController = NeoWCPrivateNavigationController(source);
    if (!navigationController) return NO;
    UIViewController *visibleController = navigationController.visibleViewController;
    NSString *visibleUserName = NeoWCPrivateChatUserName(visibleController) ?: @"";
    if ([visibleUserName isEqualToString:resolvedUserName]) {
        return YES;
    }

    id messageLogic = NeoWCPrivateService(@"MMMsgLogicManager");
    id contact = NeoWCPrivateContact(resolvedUserName);
    if (contact && NeoWCPrivatePushChatSelector(messageLogic,
            @"PushOtherBaseMsgControllerByContact:navigationController:animated:",
            contact, navigationController, animated)) return YES;
    return NeoWCPrivatePushChatSelector(messageLogic,
        @"PushOtherBaseMsgControllerByUserName:navigationController:animated:",
        resolvedUserName, navigationController, animated);
}

#pragma mark - Entertainment Red Envelope

static BOOL NeoWCPrivateSetObject(id receiver, NSString *selectorName, id value) {
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = NeoWCPrivateSignature(receiver, selector, 3);
    if (!signature || !NeoWCPrivateTypeIsVoid(signature.methodReturnType) ||
        !NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 1))) return NO;
    @try {
        ((void (*)(id, SEL, id))objc_msgSend)(receiver, selector, value);
        return YES;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

static BOOL NeoWCPrivateSetInteger(id receiver, NSString *selectorName, NSInteger value) {
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = NeoWCPrivateSignature(receiver, selector, 3);
    if (!signature || !NeoWCPrivateTypeIsVoid(signature.methodReturnType) ||
        !NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:2])) return NO;
    @try {
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(receiver, selector, value);
        return YES;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

BOOL NeoWCPrivateIsEntertainmentRedEnvelopeContact(id contact) {
    NSString *userName = NeoWCPrivateContactUserName(contact);
    return [userName hasSuffix:@"@chatroom@"] || [userName hasSuffix:@"@@chatroom"];
}

NSString *NeoWCPrivateEntertainmentRedEnvelopeUserName(NSString *groupUserName) {
    NSString *userName = NeoWCPrivateNonemptyString(groupUserName);
    if ([userName hasSuffix:@"@chatroom@"]) return userName;
    if (![userName hasSuffix:@"@chatroom"]) return nil;
    return [userName stringByAppendingString:@"@"];
}

static UIViewController *NeoWCPrivateOwningChatController(id logicController) {
    id controller = NeoWCPrivateNoArgumentObject(logicController, @"getViewController");
    if ([controller isKindOfClass:UIViewController.class]) return controller;
    return NeoWCPrivateCurrentChatController();
}

static BOOL NeoWCPrivateActionSheetAdd(id sheet,
                                       NSString *selectorName,
                                       NSString *title,
                                       dispatch_block_t handler) {
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = NeoWCPrivateSignature(sheet, selector, 4);
    if (!signature || !NeoWCPrivateTypeIsObject(signature.methodReturnType) ||
        !NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 2))) return NO;
    @try {
        (void)((id (*)(id, SEL, id, id))objc_msgSend)(sheet, selector, title, [handler copy]);
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"娱乐红包菜单 %@ 调用失败：%@", selectorName,
                 exception.reason ?: exception.name);
        return NO;
    }
}

BOOL NeoWCPrivatePresentEntertainmentRedEnvelopeMenu(id logicController,
                                                      dispatch_block_t normalHandler,
                                                      dispatch_block_t entertainmentHandler) {
    NSCAssert(NSThread.isMainThread, @"Entertainment red-envelope menu must run on the main thread");
    if (!logicController || !normalHandler || !entertainmentHandler) return NO;
    Class sheetClass = NSClassFromString(@"WCUIActionSheet");
    SEL initializer = NSSelectorFromString(@"initWithTitle:");
    NSMethodSignature *initSignature = sheetClass
        ? [sheetClass instanceMethodSignatureForSelector:initializer] : nil;
    if (!initSignature || initSignature.numberOfArguments != 3 ||
        !NeoWCPrivateTypeIsObject(initSignature.methodReturnType) ||
        !NeoWCPrivateTypeIsObject([initSignature getArgumentTypeAtIndex:2])) return NO;

    id sheet = nil;
    @try {
        sheet = ((id (*)(id, SEL, id))objc_msgSend)([sheetClass alloc], initializer, @"发送红包");
    } @catch (NSException *exception) {
        NeoWCLog(@"娱乐红包菜单构造失败：%@", exception.reason ?: exception.name);
        return NO;
    }
    if (!sheet ||
        !NeoWCPrivateActionSheetAdd(sheet, @"addBtnTitle:handler:", @"发送正常红包", normalHandler)) return NO;
    NSString *chatUserName = NeoWCPrivateChatUserName(logicController);
    BOOL ordinaryGroup = [chatUserName hasSuffix:@"@chatroom"] &&
        ![chatUserName hasSuffix:@"@chatroom@"] && ![chatUserName hasSuffix:@"@@chatroom"];
    if (ordinaryGroup && !NeoWCPrivateActionSheetAdd(
            sheet, @"addBtnTitle:handler:", @"发送娱乐红包", entertainmentHandler)) return NO;
    if (!NeoWCPrivateActionSheetAdd(sheet, @"addCancelBtnTitle:handler:", @"取消", ^{})) return NO;

    UIViewController *controller = NeoWCPrivateOwningChatController(logicController);
    UIView *view = controller.isViewLoaded ? controller.view : nil;
    SEL showSelector = NSSelectorFromString(@"showInView:");
    NSMethodSignature *showSignature = NeoWCPrivateSignature(sheet, showSelector, 3);
    if (!view.window || !showSignature || !NeoWCPrivateTypeIsObject(showSignature.methodReturnType) ||
        !NeoWCPrivateObjectArguments(showSignature, NSMakeRange(2, 1))) return NO;
    @try {
        (void)((id (*)(id, SEL, id))objc_msgSend)(sheet, showSelector, view);
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"娱乐红包菜单显示失败：%@", exception.reason ?: exception.name);
        return NO;
    }
}

static id NeoWCPrivateEntertainmentRedEnvelopeContact(NSString *syntheticUserName) {
    Class contactClass = NSClassFromString(@"CContact");
    id contact = contactClass ? [[contactClass alloc] init] : nil;
    if (!contact) return nil;

    if (!NeoWCPrivateSetObject(contact, @"setM_nsUsrName:", syntheticUserName)) {
        @try { [contact setValue:syntheticUserName forKey:@"m_nsUsrName"]; }
        @catch (__unused NSException *exception) { return nil; }
    }
    if (!NeoWCPrivateSetObject(contact, @"setM_nsAliasName:", syntheticUserName)) {
        @try { [contact setValue:syntheticUserName forKey:@"m_nsAliasName"]; }
        @catch (__unused NSException *exception) { return nil; }
    }
    if (!NeoWCPrivateSetObject(contact, @"setM_nsNickName:", syntheticUserName)) {
        @try { [contact setValue:syntheticUserName forKey:@"m_nsNickName"]; }
        @catch (__unused NSException *exception) { return nil; }
    }
    return contact;
}

static void NeoWCPrivateDeleteStaleEntertainmentContact(NSString *syntheticUserName) {
    id manager = NeoWCPrivateService(@"CContactMgr");
    id staleContact = nil;
    for (NSString *selectorName in @[@"getContactByName:", @"getContactForSearchByName:"]) {
        SEL selector = NSSelectorFromString(selectorName);
        NSMethodSignature *signature = NeoWCPrivateSignature(manager, selector, 3);
        if (!signature || !NeoWCPrivateTypeIsObject(signature.methodReturnType) ||
            !NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 1))) continue;
        @try {
            staleContact = ((id (*)(id, SEL, id))objc_msgSend)(manager, selector, syntheticUserName);
        } @catch (__unused NSException *exception) {}
        if (staleContact) break;
    }
    if (!staleContact) return;
    SEL selector = NSSelectorFromString(@"deleteContactLocal:listType:");
    NSMethodSignature *signature = NeoWCPrivateSignature(manager, selector, 4);
    if (!signature || !NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 1)) ||
        !NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:3])) return;
    @try {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = manager;
        invocation.selector = selector;
        id argument = staleContact;
        NSInteger listType = 1;
        [invocation setArgument:&argument atIndex:2];
        [invocation setArgument:&listType atIndex:3];
        [invocation invoke];
    } @catch (NSException *exception) {
        NeoWCLog(@"清理娱乐红包临时联系人失败：%@", exception.reason ?: exception.name);
    }
}

static BOOL NeoWCPrivateInvokeNavigation(id receiver,
                                         NSString *selectorName,
                                         NSArray *arguments,
                                         NSArray<NSNumber *> *integerIndexes) {
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = NeoWCPrivateSignature(receiver, selector, arguments.count + 2);
    if (!signature || (!NeoWCPrivateTypeIsObject(signature.methodReturnType) &&
        !NeoWCPrivateTypeIsVoid(signature.methodReturnType) &&
        !NeoWCPrivateTypeIsInteger(signature.methodReturnType))) return NO;
    NSSet<NSNumber *> *integers = [NSSet setWithArray:integerIndexes ?: @[]];
    for (NSUInteger index = 0; index < arguments.count; index++) {
        const char *type = [signature getArgumentTypeAtIndex:index + 2];
        if ([integers containsObject:@(index)]) {
            if (!NeoWCPrivateTypeIsInteger(type)) return NO;
        } else if (!NeoWCPrivateTypeIsObject(type)) {
            return NO;
        }
    }
    @try {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = receiver;
        invocation.selector = selector;
        for (NSUInteger index = 0; index < arguments.count; index++) {
            id value = arguments[index] == NSNull.null ? nil : arguments[index];
            if ([integers containsObject:@(index)]) {
                NSInteger integer = [value integerValue];
                [invocation setArgument:&integer atIndex:index + 2];
            } else {
                [invocation setArgument:&value atIndex:index + 2];
            }
        }
        [invocation retainArguments];
        [invocation invoke];
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"娱乐红包导航 %@ 调用失败：%@", selectorName,
                 exception.reason ?: exception.name);
        return NO;
    }
}

static BOOL NeoWCPrivateNavigateEntertainmentContact(UIViewController *source,
                                                       id contact,
                                                       dispatch_block_t completion) {
    Class managerClass = NSClassFromString(@"CAppViewControllerManager");
    id appManager = NeoWCPrivateNoArgumentObject(managerClass, @"getAppViewControllerManager");
    if (appManager) {
        NSString *completionSelector = @"newMessageByContact:msgWrapToAdd:showMainView:animated:reuse:extraInfo:completion:";
        if (NeoWCPrivateInvokeNavigation(appManager, completionSelector,
                @[contact, NSNull.null, @YES, @YES, NSNull.null, NSNull.null, [completion copy]],
                @[@2, @3])) return YES;
        if (NeoWCPrivateInvokeNavigation(appManager,
                @"newMessageByContact:msgWrapToAdd:showMainView:animated:extraInfo:",
                @[contact, NSNull.null, @YES, @YES, NSNull.null], @[@2, @3])) {
            completion();
            return YES;
        }
        if (NeoWCPrivateInvokeNavigation(appManager,
                @"newMessageByContact:msgWrapToAdd:showMainView:",
                @[contact, NSNull.null, @YES], @[@2])) {
            completion();
            return YES;
        }
        if (NeoWCPrivateInvokeNavigation(appManager, @"jumpToChat:msgToLocate:",
                @[contact, NSNull.null], @[])) {
            completion();
            return YES;
        }
    }

    UINavigationController *navigationController = NeoWCPrivateNavigationController(source);
    id messageLogic = NeoWCPrivateService(@"MMMsgLogicManager");
    if (navigationController && NeoWCPrivateInvokeNavigation(messageLogic,
            @"PushLogicControllerByContact:navigationController:animated:jumpToLocationNode:",
            @[contact, navigationController, @YES, NSNull.null], @[@2])) {
        completion();
        return YES;
    }
    if (navigationController && NeoWCPrivateInvokeNavigation(messageLogic,
            @"PushOtherBaseMsgControllerByContact:navigationController:animated:",
            @[contact, navigationController, @YES], @[@2])) {
        completion();
        return YES;
    }
    return NO;
}

static BOOL NeoWCPrivateStartRedEnvelopeCurrentABI(id manager,
                                                    UIViewController *source,
                                                    id data,
                                                    id contact) {
    NSString *selectorName =
        @"startSendRedEnvelopesLogic:Data:WithSelectContact:Scene:RedEnvelopesType:";
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = NeoWCPrivateSignature(manager, selector, 7);
    BOOL typeIsObject = signature &&
        NeoWCPrivateTypeIsObject([signature getArgumentTypeAtIndex:6]);
    BOOL typeIsInteger = signature &&
        NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:6]);
    const char *returnType = signature
        ? NeoWCPrivateUnqualifiedType(signature.methodReturnType) : "";
    BOOL returnIsObject = NeoWCPrivateTypeIsObject(returnType);
    BOOL returnIsVoid = NeoWCPrivateTypeIsVoid(returnType);
    BOOL returnIsInteger = NeoWCPrivateTypeIsInteger(returnType);
    if (!signature || !NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 3)) ||
        !NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:5]) ||
        (!typeIsObject && !typeIsInteger) ||
        (!returnIsObject && !returnIsVoid && !returnIsInteger)) {
        NeoWCLog(@"娱乐红包适配 %@ ABI 不匹配", selectorName);
        return NO;
    }
    @try {
        if (typeIsObject) {
            if (returnIsObject) {
                (void)((id (*)(id, SEL, id, id, id, NSInteger, id))objc_msgSend)(
                    manager, selector, source, data, contact, 2, nil);
            } else if (returnIsVoid) {
                ((void (*)(id, SEL, id, id, id, NSInteger, id))objc_msgSend)(
                    manager, selector, source, data, contact, 2, nil);
            } else {
                (void)((NSInteger (*)(id, SEL, id, id, id, NSInteger, id))objc_msgSend)(
                    manager, selector, source, data, contact, 2, nil);
            }
        } else if (returnIsObject) {
            (void)((id (*)(id, SEL, id, id, id, NSInteger, NSInteger))objc_msgSend)(
                manager, selector, source, data, contact, 2, 0);
        } else if (returnIsVoid) {
            ((void (*)(id, SEL, id, id, id, NSInteger, NSInteger))objc_msgSend)(
                manager, selector, source, data, contact, 2, 0);
        } else {
            (void)((NSInteger (*)(id, SEL, id, id, id, NSInteger, NSInteger))objc_msgSend)(
                manager, selector, source, data, contact, 2, 0);
        }
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"娱乐红包适配 %@ 调用失败：%@", selectorName,
                 exception.reason ?: exception.name);
        return NO;
    }
}

static BOOL NeoWCPrivateStartRedEnvelopeLegacyABI(id manager,
                                                   UIViewController *source,
                                                   id contact) {
    NSString *selectorName =
        @"startSendRedEnvelopesLogic:WithSelectContact:Scene:RedEnvelopesType:";
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = NeoWCPrivateSignature(manager, selector, 6);
    BOOL typeIsObject = signature &&
        NeoWCPrivateTypeIsObject([signature getArgumentTypeAtIndex:5]);
    BOOL typeIsInteger = signature &&
        NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:5]);
    const char *returnType = signature
        ? NeoWCPrivateUnqualifiedType(signature.methodReturnType) : "";
    BOOL returnIsObject = NeoWCPrivateTypeIsObject(returnType);
    BOOL returnIsVoid = NeoWCPrivateTypeIsVoid(returnType);
    BOOL returnIsInteger = NeoWCPrivateTypeIsInteger(returnType);
    if (!signature || !NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 2)) ||
        !NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:4]) ||
        (!typeIsObject && !typeIsInteger) ||
        (!returnIsObject && !returnIsVoid && !returnIsInteger)) {
        NeoWCLog(@"娱乐红包适配 %@ ABI 不匹配", selectorName);
        return NO;
    }
    @try {
        if (typeIsObject) {
            if (returnIsObject) {
                (void)((id (*)(id, SEL, id, id, NSInteger, id))objc_msgSend)(
                    manager, selector, source, contact, 2, nil);
            } else if (returnIsVoid) {
                ((void (*)(id, SEL, id, id, NSInteger, id))objc_msgSend)(
                    manager, selector, source, contact, 2, nil);
            } else {
                (void)((NSInteger (*)(id, SEL, id, id, NSInteger, id))objc_msgSend)(
                    manager, selector, source, contact, 2, nil);
            }
        } else if (returnIsObject) {
            (void)((id (*)(id, SEL, id, id, NSInteger, NSInteger))objc_msgSend)(
                manager, selector, source, contact, 2, 0);
        } else if (returnIsVoid) {
            ((void (*)(id, SEL, id, id, NSInteger, NSInteger))objc_msgSend)(
                manager, selector, source, contact, 2, 0);
        } else {
            (void)((NSInteger (*)(id, SEL, id, id, NSInteger, NSInteger))objc_msgSend)(
                manager, selector, source, contact, 2, 0);
        }
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"娱乐红包适配 %@ 调用失败：%@", selectorName,
                 exception.reason ?: exception.name);
        return NO;
    }
}

static BOOL NeoWCPrivateInvokeEntertainmentRedEnvelope(id syntheticContact,
                                                        NSString *syntheticUserName) {
    UIViewController *visibleController = NeoWCPrivateCurrentChatController();
    NSString *visibleUserName = NeoWCPrivateChatUserName(visibleController);
    if (!visibleController || ![visibleUserName isEqualToString:syntheticUserName]) {
        NeoWCLog(@"娱乐红包假群会话校验失败，期望 %@，当前 %@",
                 syntheticUserName, visibleUserName ?: @"<nil>");
        return NO;
    }
    id manager = NeoWCPrivateService(@"WCRedEnvelopesControlMgr");
    if (!manager) return NO;
    (void)NeoWCPrivateSetInteger(manager, @"refreshCurrentRedEnvLaunchMode:", 2);

    Class dataClass = NSClassFromString(@"WCRedEnvelopesControlData");
    id data = dataClass ? [[dataClass alloc] init] : nil;
    if (data) {
        (void)NeoWCPrivateSetObject(data, @"setM_oSelectContact:", syntheticContact);
        (void)NeoWCPrivateSetObject(data, @"setSelectedMemberContact:", syntheticContact);
        (void)NeoWCPrivateSetObject(data, @"setM_arrSelectedSendRedEnvelopesUserList:",
                                    @[syntheticUserName]);
        if (NeoWCPrivateStartRedEnvelopeCurrentABI(manager, visibleController,
                                                   data, syntheticContact)) return YES;
    }
    return NeoWCPrivateStartRedEnvelopeLegacyABI(manager, visibleController, syntheticContact);
}

BOOL NeoWCPrivateStartEntertainmentRedEnvelope(UIViewController *source,
                                                NSString *groupUserName,
                                                void (^completion)(BOOL success)) {
    NSCAssert(NSThread.isMainThread, @"Entertainment red-envelope navigation must run on the main thread");
    NSString *syntheticUserName = NeoWCPrivateEntertainmentRedEnvelopeUserName(groupUserName);
    if (!source || syntheticUserName.length == 0 ||
        [groupUserName hasSuffix:@"@chatroom@"]) return NO;
    id syntheticContact = NeoWCPrivateEntertainmentRedEnvelopeContact(syntheticUserName);
    if (!syntheticContact) {
        NeoWCLog(@"娱乐红包适配无法构造临时联系人：%@", groupUserName);
        return NO;
    }
    NeoWCPrivateDeleteStaleEntertainmentContact(syntheticUserName);
    void (^finished)(BOOL) = [completion copy];
    if (!finished) finished = ^(__unused BOOL success) {};
    NSString *expectedUserName = [syntheticUserName copy];
    id retainedContact = syntheticContact;
    __block BOOL completed = NO;
    __block BOOL navigationHandled = NO;
    void (^finishOnce)(BOOL) = ^(BOOL success) {
        if (completed) return;
        completed = YES;
        finished(success);
    };
    dispatch_block_t afterNavigation = ^{
        if (completed || navigationHandled) return;
        navigationHandled = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (completed) return;
            BOOL success = NeoWCPrivateInvokeEntertainmentRedEnvelope(
                retainedContact, expectedUserName);
            finishOnce(success);
        });
    };
    BOOL dispatched = NeoWCPrivateNavigateEntertainmentContact(
        source, syntheticContact, afterNavigation);
    if (dispatched) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            finishOnce(NO);
        });
    }
    return dispatched;
}

#pragma mark - Transfer Verification

static NSString *NeoWCPrivateTransferString(id value) {
    if ([value isKindOfClass:NSString.class]) {
        return [(NSString *)value stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet];
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        id stringValue = [value stringValue];
        return [stringValue isKindOfClass:NSString.class]
            ? [stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
            : nil;
    }
    return nil;
}

static BOOL NeoWCPrivateTransferNameContainsMask(NSString *value) {
    return [value rangeOfString:@"*"].location != NSNotFound ||
        [value rangeOfString:@"＊"].location != NSNotFound;
}

static NSString *NeoWCPrivateNormalizeMaskedTransferName(id value) {
    NSString *candidate = NeoWCPrivateTransferString(value);
    if (candidate.length == 0 || candidate.length > 80 ||
        !NeoWCPrivateTransferNameContainsMask(candidate)) return nil;

    for (NSArray<NSString *> *pair in @[@[@"（", @"）"], @[@"(", @")"]]) {
        NSRange open = [candidate rangeOfString:pair[0]];
        if (open.location == NSNotFound) continue;
        NSRange searchRange = NSMakeRange(NSMaxRange(open), candidate.length - NSMaxRange(open));
        NSRange close = [candidate rangeOfString:pair[1] options:0 range:searchRange];
        if (close.location == NSNotFound || close.location <= NSMaxRange(open)) continue;
        NSString *inner = [candidate substringWithRange:
            NSMakeRange(NSMaxRange(open), close.location - NSMaxRange(open))];
        inner = [inner stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (NeoWCPrivateTransferNameContainsMask(inner)) {
            candidate = inner;
            break;
        }
    }

    NSCharacterSet *wrappers = [NSCharacterSet characterSetWithCharactersInString:
        @" \t\r\n•·●○◆◇()[]{}（）【】<>《》:："];
    candidate = [candidate stringByTrimmingCharactersInSet:wrappers];
    NSRange asciiMask = [candidate rangeOfString:@"*"];
    NSRange fullwidthMask = [candidate rangeOfString:@"＊"];
    NSUInteger maskLocation = MIN(asciiMask.location, fullwidthMask.location);
    if (maskLocation == NSNotFound) return nil;
    if (maskLocation > 0) candidate = [candidate substringFromIndex:maskLocation];
    NSCharacterSet *hiddenAndWrappers = [NSCharacterSet characterSetWithCharactersInString:
        @"*＊ \t\r\n•·●○◆◇()[]{}（）【】<>《》:："];
    if (candidate.length == 0 || candidate.length > 32 ||
        [candidate rangeOfCharacterFromSet:hiddenAndWrappers.invertedSet].location == NSNotFound) return nil;
    return candidate;
}

static id NeoWCPrivateTransferObjectValue(id object, NSString *name) {
    if (!object || name.length == 0) return nil;
    if ([object isKindOfClass:NSDictionary.class]) {
        id value = ((NSDictionary *)object)[name];
        return value == NSNull.null ? nil : value;
    }
    SEL selector = NSSelectorFromString(name);
    NSMethodSignature *signature = NeoWCPrivateSignature(object, selector, 2);
    if (signature && NeoWCPrivateTypeIsObject(signature.methodReturnType)) {
        @try {
            id value = ((id (*)(id, SEL))objc_msgSend)(object, selector);
            if (value && value != NSNull.null) return value;
        } @catch (__unused NSException *exception) {}
    }
    @try {
        id value = [object valueForKey:name];
        return value == NSNull.null ? nil : value;
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static NSString *NeoWCPrivateMaskedTransferNameAtDepth(id response, NSUInteger depth) {
    if (!response || depth > 3) return nil;
    NSString *directMaskedName = NeoWCPrivateNormalizeMaskedTransferName(response);
    if (directMaskedName.length > 0) return directMaskedName;
    for (NSString *field in @[
        @"maskTruename", @"maskTrueName", @"receiverMaskTrueName",
        @"m_nsTransferReceiverTrueName", @"m_nsF2FMaskTrueName", @"m_nsTruthName",
        @"m_nsReceiverTrueName", @"m_nsSelectedTruthNameFromQRCode", @"maskRealname",
        @"truenameMask", @"realName", @"receiver_true_name", @"receiverTrueName",
        @"true_name", @"trueName", @"truename"
    ]) {
        NSString *maskedName = NeoWCPrivateNormalizeMaskedTransferName(
            NeoWCPrivateTransferObjectValue(response, field));
        if (maskedName.length > 0) return maskedName;
    }
    if (depth == 3) return nil;
    for (NSString *container in @[
        @"data", @"response", @"resp", @"result", @"transferMoneyData",
        @"payControlData", @"lastReqKeyStruct"
    ]) {
        id nested = NeoWCPrivateTransferObjectValue(response, container);
        if (!nested || nested == response) continue;
        NSString *maskedName = NeoWCPrivateMaskedTransferNameAtDepth(nested, depth + 1);
        if (maskedName.length > 0) return maskedName;
    }
    return nil;
}

NSString *NeoWCPrivateMaskedTransferName(id response) {
    return NeoWCPrivateMaskedTransferNameAtDepth(response, 0);
}

NSString *NeoWCPrivateMaskedTransferNameSuffix(NSString *maskedName) {
    NSString *validated = NeoWCPrivateNormalizeMaskedTransferName(maskedName);
    if (validated.length == 0) return nil;
    NSCharacterSet *ignored = [NSCharacterSet characterSetWithCharactersInString:
        @"*＊ \t\r\n•·●○◆◇()[]{}（）【】<>《》:："];
    __block NSString *suffix = nil;
    [validated enumerateSubstringsInRange:NSMakeRange(0, validated.length)
                                  options:NSStringEnumerationByComposedCharacterSequences |
                                          NSStringEnumerationReverse
                               usingBlock:^(NSString *substring, __unused NSRange substringRange,
                                            __unused NSRange enclosingRange, BOOL *stop) {
        if ([substring rangeOfCharacterFromSet:ignored].location == NSNotFound) {
            suffix = substring;
            *stop = YES;
        }
    }];
    return suffix;
}

#pragma mark - Group Invitations

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

static NeoWCPrivateGroupInvitationResult
NeoWCPrivateInvokeExtendedGroupInvitation(id manager,
                                          NSString *groupUserName,
                                          NSArray<NSString *> *memberList) {
    NSString *selectorName = @"InviteGroupMember:withMemberList:withInviterScene:withTicket:withUserData:withMsgHistoryInfo:";
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = NeoWCPrivateSignature(manager, selector, 8);
    if (!signature ||
        !NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 2)) ||
        !NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:4]) ||
        !NeoWCPrivateObjectArguments(signature, NSMakeRange(5, 3))) {
        return NeoWCPrivateGroupInvitationResultUnsupported;
    }
    const char *returnType = NeoWCPrivateUnqualifiedType(signature.methodReturnType);
    @try {
        if (strcmp(returnType, @encode(void)) == 0) {
            ((void (*)(id, SEL, id, id, NSInteger, id, id, id))objc_msgSend)(
                manager, selector, groupUserName, memberList, 0, nil, nil, nil);
            return NeoWCPrivateGroupInvitationResultSubmitted;
        }
        if (NeoWCPrivateTypeIsObject(returnType)) {
            (void)((id (*)(id, SEL, id, id, NSInteger, id, id, id))objc_msgSend)(
                manager, selector, groupUserName, memberList, 0, nil, nil, nil);
            return NeoWCPrivateGroupInvitationResultSubmitted;
        }
        if (NeoWCPrivateTypeIsInteger(returnType)) {
            (void)((NSInteger (*)(id, SEL, id, id, NSInteger, id, id, id))objc_msgSend)(
                manager, selector, groupUserName, memberList, 0, nil, nil, nil);
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
    id manager = NeoWCPrivateService(@"CGroupMgr");
    if (!manager) return NeoWCPrivateGroupInvitationResultUnsupported;
    NSArray<NSString *> *members = @[memberUserName];

    // WeChatX 2.2-2 prefers the current six-argument CGroupMgr API.
    NeoWCPrivateGroupInvitationResult result = NeoWCPrivateInvokeExtendedGroupInvitation(
        manager, groupUserName, members);
    if (result != NeoWCPrivateGroupInvitationResultUnsupported) return result;

    // Older WeChat builds expose the same CGroupMgr operation with two objects.
    result = NeoWCPrivateInvokeGroupInvitation(
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
