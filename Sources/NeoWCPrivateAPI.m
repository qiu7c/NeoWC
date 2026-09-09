#import "NeoWCPrivateAPI.h"
#import "NeoWCAccount.h"
#import "NeoWCLogging.h"
#import <AVFoundation/AVFoundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <string.h>
#include <stdatomic.h>

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

static BOOL NeoWCPrivateTypeIsSelector(const char *type) {
    return NeoWCPrivateUnqualifiedType(type)[0] == ':';
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
    id fallbackContact = nil;
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
            if (!contact) continue;
            if (!fallbackContact) fallbackContact = contact;
            NSString *remark = NeoWCPrivateNonemptyString(NeoWCPrivateObjectField(
                contact, @[@"m_nsRemark", @"getRemark", @"remark", @"remarkName"]));
            if (remark.length > 0) return contact;
        } @catch (NSException *exception) {
            NeoWCLog(@"联系人适配 %@ 调用失败：%@", selectorName,
                     exception.reason ?: exception.name);
        }
    }
    return fallbackContact;
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
    NSString *displayName = NeoWCPrivateContactRemark(contact);
    if (displayName.length > 0) return displayName;
    displayName = NeoWCPrivateContactString(contact,
        @[@"getContactDisplayName", @"getDisplayName"]);
    if (displayName.length > 0) return displayName;
    displayName = NeoWCPrivateContactNickname(contact);
    if (displayName.length > 0) return displayName;
    return NeoWCPrivateNonemptyString(fallback);
}

NSString *NeoWCPrivateNotificationDisplayName(NSString *userName, NSString *eventFallback) {
    NSCAssert(NSThread.isMainThread, @"Notification contact names must be resolved on the main thread");
    NSString *normalizedUserName = NeoWCPrivateNonemptyString(userName);
    id contact = normalizedUserName.length > 0 ? NeoWCPrivateContact(normalizedUserName) : nil;
    NSString *name = NeoWCPrivateContactRemark(contact);
    if (name.length > 0) return name;
    id listContact = nil;
    if (normalizedUserName.length > 0) {
        for (id candidate in NeoWCPrivateContactList()) {
            NSString *candidateUserName = NeoWCPrivateContactUserName(candidate);
            NSString *candidateAlias = NeoWCPrivateContactAlias(candidate);
            if ([candidateUserName isEqualToString:normalizedUserName] ||
                [candidateAlias isEqualToString:normalizedUserName]) {
                listContact = candidate;
                break;
            }
        }
    }
    name = NeoWCPrivateContactRemark(listContact);
    if (name.length > 0) return name;
    name = NeoWCPrivateContactDisplayName(contact, nil);
    if (name.length > 0) return name;
    name = NeoWCPrivateContactDisplayName(listContact, nil);
    if (name.length > 0) return name;
    name = NeoWCPrivateNonemptyString(eventFallback);
    if (name.length > 0) return name;
    return normalizedUserName;
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

#pragma mark - Moments Upload Metadata

id NeoWCPrivateCreateMomentsAppInfo(NSString *appID, NSString *appName) {
    NSString *resolvedID = NeoWCPrivateNonemptyString(appID);
    NSString *resolvedName = NeoWCPrivateNonemptyString(appName);
    Class appInfoClass = NSClassFromString(@"WCAppInfo");
    if (!appInfoClass || resolvedID.length == 0 || resolvedName.length == 0) return nil;

    SEL initSelector = @selector(init);
    SEL appIDSelector = NSSelectorFromString(@"setAppID:");
    SEL appNameSelector = NSSelectorFromString(@"setAppName:");
    NSMethodSignature *initSignature = [appInfoClass instanceMethodSignatureForSelector:initSelector];
    NSMethodSignature *appIDSignature = [appInfoClass instanceMethodSignatureForSelector:appIDSelector];
    NSMethodSignature *appNameSignature = [appInfoClass instanceMethodSignatureForSelector:appNameSelector];
    if (!initSignature || initSignature.numberOfArguments != 2 ||
        !NeoWCPrivateTypeIsObject(initSignature.methodReturnType) ||
        !appIDSignature || appIDSignature.numberOfArguments != 3 ||
        !NeoWCPrivateTypeIsVoid(appIDSignature.methodReturnType) ||
        !NeoWCPrivateTypeIsObject([appIDSignature getArgumentTypeAtIndex:2]) ||
        !appNameSignature || appNameSignature.numberOfArguments != 3 ||
        !NeoWCPrivateTypeIsVoid(appNameSignature.methodReturnType) ||
        !NeoWCPrivateTypeIsObject([appNameSignature getArgumentTypeAtIndex:2])) return nil;

    @try {
        id info = [[appInfoClass alloc] init];
        if (!info) return nil;
        ((void (*)(id, SEL, id))objc_msgSend)(info, appIDSelector, resolvedID);
        ((void (*)(id, SEL, id))objc_msgSend)(info, appNameSelector, resolvedName);
        return info;
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static char NeoWCPrivateMomentsTailCellKey;
static char NeoWCPrivateMomentsTailManagerKey;

static id NeoWCPrivateMomentsTableManager(id composer) {
    if (!composer) return nil;
    @try { return [composer valueForKey:@"m_tableViewManager"]; }
    @catch (__unused NSException *exception) { return nil; }
}

static id NeoWCPrivateCreateMomentsTailCell(id composer, SEL action, NSString *rightValue) {
    Class cellClass = NSClassFromString(@"WCTableViewCellManager");
    if (!cellClass || !action || rightValue.length == 0) return nil;
    SEL selector = NSSelectorFromString(@"normalCellForSel:target:leftImage:title:titleColor:badge:rightValue:rightImage:withRightRedDot:selected:");
    NSMethodSignature *signature = [cellClass methodSignatureForSelector:selector];
    if (signature.numberOfArguments == 12 && NeoWCPrivateTypeIsObject(signature.methodReturnType) &&
        NeoWCPrivateTypeIsSelector([signature getArgumentTypeAtIndex:2]) &&
        NeoWCPrivateObjectArguments(signature, NSMakeRange(3, 7)) &&
        NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:10]) &&
        NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:11])) {
        return ((id (*)(id, SEL, SEL, id, id, id, id, id, id, id, BOOL, BOOL))objc_msgSend)(
            cellClass, selector, action, composer, nil, @"发圈尾巴", nil, nil, rightValue, nil, NO, NO);
    }
    selector = NSSelectorFromString(@"normalCellForSel:target:title:rightValue:canRightValueCopy:");
    signature = [cellClass methodSignatureForSelector:selector];
    if (signature.numberOfArguments == 7 && NeoWCPrivateTypeIsObject(signature.methodReturnType) &&
        NeoWCPrivateTypeIsSelector([signature getArgumentTypeAtIndex:2]) &&
        NeoWCPrivateObjectArguments(signature, NSMakeRange(3, 3)) &&
        NeoWCPrivateTypeIsInteger([signature getArgumentTypeAtIndex:6])) {
        return ((id (*)(id, SEL, SEL, id, id, id, BOOL))objc_msgSend)(
            cellClass, selector, action, composer, @"发圈尾巴", rightValue, NO);
    }
    return nil;
}

BOOL NeoWCPrivateInstallMomentsTailCell(id composer, SEL action, NSString *rightValue) {
    if (!NSThread.isMainThread || !composer || objc_getAssociatedObject(composer, &NeoWCPrivateMomentsTailCellKey)) return NO;
    @try {
        id manager = NeoWCPrivateMomentsTableManager(composer);
        SEL countSelector = NSSelectorFromString(@"getSectionCount");
        SEL sectionSelector = NSSelectorFromString(@"getSectionAt:");
        NSMethodSignature *countSignature = NeoWCPrivateSignature(manager, countSelector, 2);
        NSMethodSignature *sectionSignature = NeoWCPrivateSignature(manager, sectionSelector, 3);
        if (!NeoWCPrivateTypeIsInteger(countSignature.methodReturnType) ||
            !NeoWCPrivateTypeIsObject(sectionSignature.methodReturnType) ||
            !NeoWCPrivateTypeIsInteger([sectionSignature getArgumentTypeAtIndex:2])) return NO;
        NSUInteger count = ((NSUInteger (*)(id, SEL))objc_msgSend)(manager, countSelector);
        if (count == 0) return NO;
        id section = ((id (*)(id, SEL, NSUInteger))objc_msgSend)(manager, sectionSelector, 0);
        id cell = NeoWCPrivateCreateMomentsTailCell(composer, action, rightValue);
        SEL addSelector = NSSelectorFromString(@"addCell:");
        NSMethodSignature *addSignature = NeoWCPrivateSignature(section, addSelector, 3);
        if (!cell || !NeoWCPrivateTypeIsObject(addSignature.methodReturnType) ||
            !NeoWCPrivateTypeIsObject([addSignature getArgumentTypeAtIndex:2])) return NO;
        ((void (*)(id, SEL, id))objc_msgSend)(section, addSelector, cell);
        objc_setAssociatedObject(composer, &NeoWCPrivateMomentsTailCellKey, cell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(composer, &NeoWCPrivateMomentsTailManagerKey, manager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NeoWCPrivateReloadMomentsTailCell(composer, rightValue);
        return YES;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

void NeoWCPrivateReloadMomentsTailCell(id composer, NSString *rightValue) {
    if (!NSThread.isMainThread || !composer || rightValue.length == 0) return;
    id cell = objc_getAssociatedObject(composer, &NeoWCPrivateMomentsTailCellKey);
    id manager = objc_getAssociatedObject(composer, &NeoWCPrivateMomentsTailManagerKey);
    if (!cell || !manager) return;
    @try {
        for (NSString *keyPath in @[@"cellConfig.rightConfig.title", @"m_rightValue", @"rightValue"]) {
            @try { [cell setValue:rightValue forKeyPath:keyPath]; break; }
            @catch (__unused NSException *exception) {}
        }
        id tableView = NeoWCPrivateNoArgumentObject(manager, @"tableView");
        if ([tableView respondsToSelector:@selector(reloadData)]) [tableView reloadData];
    } @catch (__unused NSException *exception) {}
}

void NeoWCPrivateResignMomentsComposerInput(id composer) {
    if (!NSThread.isMainThread || !composer) return;
    SEL selector = NSSelectorFromString(@"resignInput");
    NSMethodSignature *signature = NeoWCPrivateSignature(composer, selector, 2);
    if (!signature || !NeoWCPrivateTypeIsVoid(signature.methodReturnType)) return;
    @try { ((void (*)(id, SEL))objc_msgSend)(composer, selector); }
    @catch (__unused NSException *exception) {}
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

#pragma mark - Message Submission

static BOOL NeoWCPrivateSetValue(id object, NSString *key, id value) {
    if (!object || key.length == 0 || !value) return NO;
    NSString *capitalized = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                          withString:[[key substringToIndex:1] uppercaseString]];
    SEL setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", capitalized]);
    NSMethodSignature *signature = NeoWCPrivateSignature(object, setter, 3);
    if (signature && NeoWCPrivateTypeIsVoid(signature.methodReturnType)) {
        const char *argumentType = [signature getArgumentTypeAtIndex:2];
        @try {
            if (NeoWCPrivateTypeIsObject(argumentType)) {
                ((void (*)(id, SEL, id))objc_msgSend)(object, setter, value);
                return YES;
            }
        } @catch (__unused NSException *exception) {}
    }
    @try {
        [object setValue:value forKey:key];
        return YES;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

static id NeoWCPrivateInitializeMessageWrap(Class wrapClass,
                                             SEL initializer,
                                             char argumentCode) {
    id allocated = [wrapClass alloc];
    switch (argumentCode) {
        case 'c': return ((id (*)(id, SEL, signed char))objc_msgSend)(allocated, initializer, 1);
        case 'C': return ((id (*)(id, SEL, unsigned char))objc_msgSend)(allocated, initializer, 1);
        case 's': return ((id (*)(id, SEL, short))objc_msgSend)(allocated, initializer, 1);
        case 'S': return ((id (*)(id, SEL, unsigned short))objc_msgSend)(allocated, initializer, 1);
        case 'i': return ((id (*)(id, SEL, int))objc_msgSend)(allocated, initializer, 1);
        case 'I': return ((id (*)(id, SEL, unsigned int))objc_msgSend)(allocated, initializer, 1);
        case 'l': return ((id (*)(id, SEL, long))objc_msgSend)(allocated, initializer, 1);
        case 'L': return ((id (*)(id, SEL, unsigned long))objc_msgSend)(allocated, initializer, 1);
        case 'q': return ((id (*)(id, SEL, long long))objc_msgSend)(allocated, initializer, 1);
        case 'Q': return ((id (*)(id, SEL, unsigned long long))objc_msgSend)(allocated, initializer, 1);
        case 'B': return ((id (*)(id, SEL, BOOL))objc_msgSend)(allocated, initializer, YES);
        default: return nil;
    }
}

static void NeoWCPrivateSubmitMessage(id manager,
                                      SEL selector,
                                      id target,
                                      id wrap,
                                      const char *returnType) {
    switch (NeoWCPrivateUnqualifiedType(returnType)[0]) {
        case 'v': ((void (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 'c': (void)((signed char (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 'C': (void)((unsigned char (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 's': (void)((short (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 'S': (void)((unsigned short (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 'i': (void)((int (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 'I': (void)((unsigned int (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 'l': (void)((long (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 'L': (void)((unsigned long (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 'q': (void)((long long (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 'Q': (void)((unsigned long long (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        case 'B': (void)((BOOL (*)(id, SEL, id, id))objc_msgSend)(manager, selector, target, wrap); break;
        default: break;
    }
}

BOOL NeoWCPrivateSendTextMessage(NSString *userName, NSString *text) {
    NSCAssert(NSThread.isMainThread, @"Message submission must run on the main thread");
    NSString *target = NeoWCPrivateNonemptyString(userName);
    NSString *content = NeoWCPrivateNonemptyString(text);
    NSString *currentUser = NeoWCPrivateNonemptyString(NeoWCCurrentUserWXID());
    if (target.length == 0 || content.length == 0 || currentUser.length == 0) return NO;

    Class wrapClass = NSClassFromString(@"CMessageWrap");
    SEL initializer = NSSelectorFromString(@"initWithMsgType:");
    Method initializerMethod = wrapClass ? class_getInstanceMethod(wrapClass, initializer) : NULL;
    if (!initializerMethod || method_getNumberOfArguments(initializerMethod) != 3) return NO;
    char *returnType = method_copyReturnType(initializerMethod);
    BOOL objectReturn = NeoWCPrivateTypeIsObject(returnType);
    if (returnType) free(returnType);
    if (!objectReturn) return NO;
    char *argumentType = method_copyArgumentType(initializerMethod, 2);
    BOOL integerArgument = NeoWCPrivateTypeIsInteger(argumentType);
    char argumentCode = NeoWCPrivateUnqualifiedType(argumentType)[0];
    if (argumentType) free(argumentType);
    if (!integerArgument) return NO;

    id wrap = nil;
    @try {
        wrap = NeoWCPrivateInitializeMessageWrap(wrapClass, initializer, argumentCode);
    } @catch (__unused NSException *exception) {
        return NO;
    }
    if (!wrap || !NeoWCPrivateSetValue(wrap, @"m_nsFromUsr", currentUser) ||
        !NeoWCPrivateSetValue(wrap, @"m_nsToUsr", target) ||
        !NeoWCPrivateSetValue(wrap, @"m_nsContent", content)) return NO;
    NeoWCPrivateSetValue(wrap, @"m_uiMessageType", @1);
    NeoWCPrivateSetValue(wrap, @"m_uiStatus", @1);
    NeoWCPrivateSetValue(wrap, @"m_uiCreateTime",
                         @((NSUInteger)NSDate.date.timeIntervalSince1970));

    id manager = NeoWCPrivateService(@"CMessageMgr");
    SEL sendSelector = NSSelectorFromString(@"AddMsg:MsgWrap:");
    NSMethodSignature *sendSignature = NeoWCPrivateSignature(manager, sendSelector, 4);
    if (!sendSignature ||
        !NeoWCPrivateObjectArguments(sendSignature, NSMakeRange(2, 2)) ||
        (!NeoWCPrivateTypeIsVoid(sendSignature.methodReturnType) &&
         !NeoWCPrivateTypeIsInteger(sendSignature.methodReturnType))) return NO;
    @try {
        NeoWCPrivateSubmitMessage(manager, sendSelector, target, wrap,
                                  sendSignature.methodReturnType);
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"文本消息适配发送失败：%@", exception.reason ?: exception.name);
        return NO;
    }
}

@interface NeoWCPrivateMediaSendSession : NSObject
@property (nonatomic, strong) id logic;
@property (nonatomic, strong) id message;
@property (nonatomic, strong) id contact;
@end
@implementation NeoWCPrivateMediaSendSession
@end

static _Atomic(double) NeoWCPrivateVoiceUploadDeadline;

BOOL NeoWCPrivateVoiceUploadCompatibilityActive(void) {
    return atomic_load(&NeoWCPrivateVoiceUploadDeadline) > NSDate.date.timeIntervalSince1970;
}

static NSMutableSet<NeoWCPrivateMediaSendSession *> *NeoWCPrivateMediaSessions(void) {
    static NSMutableSet *sessions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sessions = [NSMutableSet set]; });
    return sessions;
}

BOOL NeoWCPrivateSendImageMessage(NSString *userName, NSString *imagePath) {
    NSCAssert(NSThread.isMainThread, @"Image submission must run on the main thread");
    NSString *target = NeoWCPrivateNonemptyString(userName);
    NSString *path = NeoWCPrivateNonemptyString(imagePath);
    UIImage *image = path.length ? [UIImage imageWithContentsOfFile:path] : nil;
    id contact = target.length ? NeoWCPrivateContact(target) : nil;
    Class providerClass = NSClassFromString(@"PasteboardMsgProvider");
    Class logicClass = NSClassFromString(@"ForwardMessageLogicController");
    SEL makeSelector = NSSelectorFromString(@"GetMessageFromImage:contact:");
    SEL sendSelector = NSSelectorFromString(@"forwardNoConfirmForMsgList:toContacts:");
    Method makeMethod = providerClass ? class_getClassMethod(providerClass, makeSelector) : NULL;
    Method sendMethod = logicClass ? class_getInstanceMethod(logicClass, sendSelector) : NULL;
    char *makeReturnType = makeMethod ? method_copyReturnType(makeMethod) : NULL;
    BOOL makeReturnsObject = NeoWCPrivateTypeIsObject(makeReturnType);
    if (makeReturnType) free(makeReturnType);
    char *makeFirstType = makeMethod ? method_copyArgumentType(makeMethod, 2) : NULL;
    char *makeSecondType = makeMethod ? method_copyArgumentType(makeMethod, 3) : NULL;
    BOOL makeArgumentsAreObjects = NeoWCPrivateTypeIsObject(makeFirstType) && NeoWCPrivateTypeIsObject(makeSecondType);
    if (makeFirstType) free(makeFirstType);
    if (makeSecondType) free(makeSecondType);
    char *sendReturnType = sendMethod ? method_copyReturnType(sendMethod) : NULL;
    char sendReturnEncoding[2] = { NeoWCPrivateUnqualifiedType(sendReturnType)[0], '\0' };
    char *sendFirstType = sendMethod ? method_copyArgumentType(sendMethod, 2) : NULL;
    char *sendSecondType = sendMethod ? method_copyArgumentType(sendMethod, 3) : NULL;
    BOOL sendABIValid = (NeoWCPrivateTypeIsVoid(sendReturnType) || NeoWCPrivateTypeIsInteger(sendReturnType)) &&
        NeoWCPrivateTypeIsObject(sendFirstType) && NeoWCPrivateTypeIsObject(sendSecondType);
    if (sendReturnType) free(sendReturnType);
    if (sendFirstType) free(sendFirstType);
    if (sendSecondType) free(sendSecondType);
    if (!image || !contact || !makeMethod || method_getNumberOfArguments(makeMethod) != 4 ||
        !makeReturnsObject || !makeArgumentsAreObjects ||
        !sendMethod || method_getNumberOfArguments(sendMethod) != 4 || !sendABIValid) return NO;
    id message = nil;
    id logic = nil;
    NeoWCPrivateMediaSendSession *session = nil;
    @try {
        message = ((id (*)(id, SEL, id, id))objc_msgSend)(providerClass, makeSelector, image, contact);
        logic = message ? [logicClass new] : nil;
        if (!logic) return NO;
        session = [NeoWCPrivateMediaSendSession new];
        session.logic = logic; session.message = message; session.contact = contact;
        [NeoWCPrivateMediaSessions() addObject:session];
        NeoWCPrivateSubmitMessage(logic, sendSelector, @[message], @[contact], sendReturnEncoding);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ [NeoWCPrivateMediaSessions() removeObject:session]; });
        return YES;
    } @catch (NSException *exception) {
        if (session) [NeoWCPrivateMediaSessions() removeObject:session];
        NeoWCLog(@"图片消息适配发送失败：%@", exception.reason ?: exception.name);
        return NO;
    }
}

static BOOL NeoWCPrivateInvokeThreeObjects(id receiver, SEL selector, id first, id second, id third,
                                            const char *returnType) {
    switch (NeoWCPrivateUnqualifiedType(returnType)[0]) {
        case 'v': ((void (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case '@': (void)((id (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 'c': (void)((signed char (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 'C': (void)((unsigned char (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 's': (void)((short (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 'S': (void)((unsigned short (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 'i': (void)((int (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 'I': (void)((unsigned int (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 'l': (void)((long (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 'L': (void)((unsigned long (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 'q': (void)((long long (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 'Q': (void)((unsigned long long (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        case 'B': (void)((BOOL (*)(id, SEL, id, id, id))objc_msgSend)(receiver, selector, first, second, third); return YES;
        default: return NO;
    }
}

BOOL NeoWCPrivateSendVideoMessage(NSString *userName, NSString *videoPath) {
    NSCAssert(NSThread.isMainThread, @"Video submission must run on the main thread");
    NSString *target = NeoWCPrivateNonemptyString(userName);
    NSString *path = NeoWCPrivateNonemptyString(videoPath);
    NSString *currentUser = NeoWCPrivateNonemptyString(NeoWCCurrentUserWXID());
    if (!target || !currentUser || ![NSFileManager.defaultManager fileExistsAtPath:path]) return NO;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    if (!track) return NO;
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    CGImageRef frame = [generator copyCGImageAtTime:CMTimeMakeWithSeconds(0.1, 600) actualTime:NULL error:nil];
    UIImage *thumbnail = frame ? [UIImage imageWithCGImage:frame] : nil;
    if (frame) CGImageRelease(frame);
    NSString *thumbnailPath = nil;
    NSData *thumbnailData = thumbnail ? UIImageJPEGRepresentation(thumbnail, 0.85) : nil;
    if (thumbnailData.length) {
        thumbnailPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
            [NSString stringWithFormat:@"neowc-video-%@.jpg", NSUUID.UUID.UUIDString]];
        if (![thumbnailData writeToFile:thumbnailPath atomically:YES]) thumbnailPath = nil;
    }
    @try {
        id videoInfo = nil;
        Class highClass = NSClassFromString(@"OpenApiMgrHelper");
        SEL highSelector = NSSelectorFromString(@"genCaptureVideoInfoWithVideoData:mediaMessage:param:");
        NSMethodSignature *highSignature = NeoWCPrivateSignature(highClass, highSelector, 5);
        if (track.estimatedDataRate >= 5000000.0 && highSignature &&
            NeoWCPrivateTypeIsObject(highSignature.methodReturnType) &&
            NeoWCPrivateObjectArguments(highSignature, NSMakeRange(2, 3))) {
            NSData *videoData = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
            if (videoData.length) videoInfo = ((id (*)(id, SEL, id, id, id))objc_msgSend)(highClass, highSelector, videoData, nil, nil);
        }
        if (!videoInfo) {
            Class infoClass = NSClassFromString(@"CaptureVideoInfo");
            SEL infoSelector = NSSelectorFromString(@"genVideoInfoWithVideoUrl:thumb:");
            NSMethodSignature *infoSignature = NeoWCPrivateSignature(infoClass, infoSelector, 4);
            if (!infoSignature || !NeoWCPrivateTypeIsObject(infoSignature.methodReturnType) ||
                !NeoWCPrivateObjectArguments(infoSignature, NSMakeRange(2, 2))) return NO;
            videoInfo = ((id (*)(id, SEL, id, id))objc_msgSend)(infoClass, infoSelector,
                [NSURL fileURLWithPath:path], thumbnail);
        }
        if (!videoInfo) return NO;
        if (thumbnailPath.length) NeoWCPrivateSetValue(videoInfo, @"thumb_path", thumbnailPath);
        id manager = NeoWCPrivateService(@"CMessageMgr");
        SEL addSelector = NSSelectorFromString(@"AddVideoMsg:ToUsr:VideoInfo:");
        NSMethodSignature *signature = NeoWCPrivateSignature(manager, addSelector, 5);
        if (!signature || !NeoWCPrivateObjectArguments(signature, NSMakeRange(2, 3))) return NO;
        BOOL submitted = NeoWCPrivateInvokeThreeObjects(manager, addSelector, currentUser, target,
                                                         videoInfo, signature.methodReturnType);
        return submitted;
    } @catch (NSException *exception) {
        NeoWCLog(@"视频消息适配发送失败：%@", exception.reason ?: exception.name);
        return NO;
    } @finally {
        if (thumbnailPath.length) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{ [NSFileManager.defaultManager removeItemAtPath:thumbnailPath error:nil]; });
    }
}

BOOL NeoWCPrivateSendVoiceMessage(NSString *userName, NSString *voicePath,
                                  NSUInteger durationMilliseconds, NSUInteger voiceFormat) {
    NSCAssert(NSThread.isMainThread, @"Voice submission must run on the main thread");
    NSString *target = NeoWCPrivateNonemptyString(userName);
    NSString *path = NeoWCPrivateNonemptyString(voicePath);
    NSString *currentUser = NeoWCPrivateNonemptyString(NeoWCCurrentUserWXID());
    if (!target || !currentUser || ![NSFileManager.defaultManager fileExistsAtPath:path]) return NO;
    Class wrapClass = NSClassFromString(@"CMessageWrap");
    SEL initializer = NSSelectorFromString(@"initWithMsgType:");
    Method initializerMethod = wrapClass ? class_getInstanceMethod(wrapClass, initializer) : NULL;
    if (!initializerMethod || method_getNumberOfArguments(initializerMethod) != 3) return NO;
    char *argumentType = method_copyArgumentType(initializerMethod, 2);
    char argumentCode = NeoWCPrivateUnqualifiedType(argumentType)[0];
    BOOL integerArgument = NeoWCPrivateTypeIsInteger(argumentType);
    if (argumentType) free(argumentType);
    if (!integerArgument) return NO;
    id manager = NeoWCPrivateService(@"CMessageMgr");
    id sender = NeoWCPrivateService(@"AudioSender");
    SEL addSelector = NSSelectorFromString(@"AddLocalMsg:MsgWrap:");
    SEL pathSelector = NSSelectorFromString(@"getPathOfAudio:");
    SEL uploaderSelector = NSSelectorFromString(@"uploaderForMsgWrap:");
    SEL resendSelector = NSSelectorFromString(@"ResendVoiceMsg:MsgWrap:");
    NSMethodSignature *addSignature = NeoWCPrivateSignature(manager, addSelector, 4);
    NSMethodSignature *pathSignature = NeoWCPrivateSignature(wrapClass, pathSelector, 3);
    if (!addSignature || !NeoWCPrivateObjectArguments(addSignature, NSMakeRange(2, 2)) ||
        (!NeoWCPrivateTypeIsVoid(addSignature.methodReturnType) &&
         !NeoWCPrivateTypeIsInteger(addSignature.methodReturnType)) ||
        !pathSignature || !NeoWCPrivateTypeIsObject(pathSignature.methodReturnType) ||
        !NeoWCPrivateTypeIsObject([pathSignature getArgumentTypeAtIndex:2])) return NO;
    @try {
        id wrap = NeoWCPrivateInitializeMessageWrap(wrapClass, initializer, argumentCode);
        if (!wrap) return NO;
        NeoWCPrivateSetValue(wrap, @"m_uiMessageType", @34);
        NeoWCPrivateSetValue(wrap, @"m_nsFromUsr", currentUser);
        NeoWCPrivateSetValue(wrap, @"m_nsRealChatUsr", currentUser);
        NeoWCPrivateSetValue(wrap, @"m_nsToUsr", target);
        NeoWCPrivateSetValue(wrap, @"m_uiStatus", @1);
        NSUInteger now = (NSUInteger)NSDate.date.timeIntervalSince1970;
        NeoWCPrivateSetValue(wrap, @"m_uiCreateTime", @(now));
        NeoWCPrivateSetValue(wrap, @"m_uiSendTime", @(now));
        id extendInfo = NeoWCPrivateObjectField(wrap, @[@"m_extendInfoWithMsgType"]);
        if (durationMilliseconds) NeoWCPrivateSetValue(extendInfo, @"m_uiVoiceTime", @(durationMilliseconds));
        NeoWCPrivateSetValue(extendInfo, @"m_uiVoiceFormat", @(voiceFormat));
        NeoWCPrivateSetValue(extendInfo, @"m_uiVoiceForwardFlag", @1);
        NeoWCPrivateSubmitMessage(manager, addSelector, target, wrap, addSignature.methodReturnType);
        NSString *destination = ((id (*)(id, SEL, id))objc_msgSend)(wrapClass, pathSelector, wrap);
        if (![destination isKindOfClass:NSString.class] || destination.length == 0) return NO;
        [NSFileManager.defaultManager createDirectoryAtPath:destination.stringByDeletingLastPathComponent
                                withIntermediateDirectories:YES attributes:nil error:nil];
        [NSFileManager.defaultManager removeItemAtPath:destination error:nil];
        if (![NSFileManager.defaultManager copyItemAtPath:path toPath:destination error:nil]) return NO;
        id resendTarget = sender;
        if (![resendTarget respondsToSelector:resendSelector] && [sender respondsToSelector:uploaderSelector])
            resendTarget = ((id (*)(id, SEL, id))objc_msgSend)(sender, uploaderSelector, wrap);
        NSMethodSignature *resendSignature = NeoWCPrivateSignature(resendTarget, resendSelector, 4);
        if (!resendSignature || !NeoWCPrivateObjectArguments(resendSignature, NSMakeRange(2, 2)) ||
            (!NeoWCPrivateTypeIsVoid(resendSignature.methodReturnType) &&
             !NeoWCPrivateTypeIsInteger(resendSignature.methodReturnType))) return NO;
        atomic_store(&NeoWCPrivateVoiceUploadDeadline, NSDate.date.timeIntervalSince1970 + 12.0);
        NeoWCPrivateSubmitMessage(resendTarget, resendSelector, target, wrap, resendSignature.methodReturnType);
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"语音消息适配发送失败：%@", exception.reason ?: exception.name);
        return NO;
    }
}

NSDictionary<NSString *, id> *NeoWCPrivateIncomingTextMessageInfo(id message) {
    if (!message) return nil;
    id (^KVCValue)(NSString *) = ^id(NSString *key) {
        @try { return [message valueForKey:key]; }
        @catch (__unused NSException *exception) { return nil; }
    };
    NSNumber *type = KVCValue(@"m_uiMessageType");
    if (![type respondsToSelector:@selector(integerValue)] || type.integerValue != 1) return nil;
    NSString *from = NeoWCPrivateNonemptyString(KVCValue(@"m_nsFromUsr"));
    NSString *to = NeoWCPrivateNonemptyString(KVCValue(@"m_nsToUsr"));
    NSString *content = NeoWCPrivateNonemptyString(KVCValue(@"m_nsContent"));
    NSString *realSender = NeoWCPrivateNonemptyString(KVCValue(@"m_nsRealChatUsr"));
    NSString *currentUser = NeoWCPrivateNonemptyString(NeoWCCurrentUserWXID());
    if (!content.length || (!from.length && !to.length)) return nil;
    BOOL fromSelf = currentUser.length && [from isEqualToString:currentUser];
    NSString *session = [from hasSuffix:@"@chatroom"] ? from :
        ([to hasSuffix:@"@chatroom"] ? to : (fromSelf ? to : from));
    if (!session.length) return nil;
    id createTime = KVCValue(@"m_uiCreateTime");
    NSString *identifier = [NSString stringWithFormat:@"%@:%@:%llu:%lu", session,
        realSender ?: from ?: @"",
        [createTime respondsToSelector:@selector(unsignedLongLongValue)] ? [createTime unsignedLongLongValue] : 0,
        (unsigned long)content.hash];
    return @{ @"session": session, @"sender": realSender ?: from ?: @"", @"content": content,
              @"identifier": identifier, @"fromSelf": @(fromSelf) };
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
