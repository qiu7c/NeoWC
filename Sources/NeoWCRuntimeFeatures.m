#import "NeoWCRuntimeFeatures.h"
#import "NeoWCMessageBlock.h"

#import "NeoWCAccount.h"
#import "NeoWCCompatibility.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"

#import <objc/message.h>
#import <objc/runtime.h>
#import <string.h>

static char NeoWCMenuOriginalTitleKey;

static id NeoWCRuntimeSafeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static void NeoWCRuntimeSetValue(id object, NSString *key, id value) {
    if (!object || key.length == 0) return;
    @try {
        [object setValue:value forKey:key];
    } @catch (__unused NSException *exception) {
    }
}

static NSString *NeoWCRuntimeStringValue(id object, NSString *key) {
    id value = NeoWCRuntimeSafeValue(object, key);
    if (![value isKindOfClass:[NSString class]]) return nil;
    NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return text.length > 0 ? text : nil;
}

static NSArray<NSString *> *NeoWCRuntimeStringList(NSString *key) {
    NSArray *stored = [[NSUserDefaults standardUserDefaults] arrayForKey:key];
    if (![stored isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:stored.count];
    for (id item in stored) {
        if (![item isKindOfClass:[NSString class]]) continue;
        NSString *value = [(NSString *)item stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (value.length > 0) [values addObject:value];
    }
    return values;
}

static BOOL NeoWCRuntimeStringMatchesAny(NSString *value, NSArray<NSString *> *candidates) {
    if (value.length == 0) return NO;
    for (NSString *candidate in candidates) {
        if ([value caseInsensitiveCompare:candidate] == NSOrderedSame) return YES;
    }
    return NO;
}

static NSString *NeoWCRuntimeMatchedTerm(NSString *text, NSString *defaultsKey) {
    if (text.length == 0) return nil;
    for (NSString *term in NeoWCRuntimeStringList(defaultsKey)) {
        if ([text rangeOfString:term options:NSCaseInsensitiveSearch].location != NSNotFound) return term;
    }
    return nil;
}

static NSString *NeoWCMenuSourceTitle(id item) {
    NSString *stored = objc_getAssociatedObject(item, &NeoWCMenuOriginalTitleKey);
    if (stored.length > 0) return stored;
    SEL titleSelector = sel_registerName("title");
    id value = nil;
    if ([item respondsToSelector:titleSelector]) {
        value = ((id (*)(id, SEL))objc_msgSend)(item, titleSelector);
    } else {
        value = NeoWCRuntimeSafeValue(item, @"title");
    }
    if (![value isKindOfClass:[NSString class]] || [value length] == 0) return nil;
    stored = [value copy];
    objc_setAssociatedObject(item, &NeoWCMenuOriginalTitleKey, stored, OBJC_ASSOCIATION_COPY_NONATOMIC);
    return stored;
}

static void NeoWCSetMenuTitle(id item, NSString *title) {
    if (!item || title.length == 0) return;
    SEL selector = sel_registerName("setTitle:");
    if ([item respondsToSelector:selector]) {
        ((void (*)(id, SEL, NSString *))objc_msgSend)(item, selector, title);
    } else {
        NeoWCRuntimeSetValue(item, @"title", title);
    }
}

NSArray *NeoWCManagedLongPressMenuItems(NSArray *items) {
    if (![items isKindOfClass:[NSArray class]]) return items;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray<NSString *> *knownTitles = [[defaults arrayForKey:NeoWCLongPressMenuKnownTitlesKey] mutableCopy] ?: [NSMutableArray array];
    BOOL discoveredNewTitle = NO;
    for (id item in items) {
        NSString *sourceTitle = NeoWCMenuSourceTitle(item);
        if (sourceTitle.length > 0 && ![knownTitles containsObject:sourceTitle]) {
            [knownTitles addObject:sourceTitle];
            discoveredNewTitle = YES;
        }
    }
    if (discoveredNewTitle) {
        [defaults setObject:knownTitles forKey:NeoWCLongPressMenuKnownTitlesKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCEnhancementDidChangeNotification
                                                            object:NeoWCLongPressMenuKnownTitlesKey];
    }
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCLongPressMenuEnabledKey);
    for (id item in items) {
        NSString *sourceTitle = NeoWCMenuSourceTitle(item);
        if (!enabled && sourceTitle.length > 0) NeoWCSetMenuTitle(item, sourceTitle);
    }
    if (!enabled) return items;

    NSSet *hiddenTitles = [NSSet setWithArray:NeoWCRuntimeStringList(NeoWCLongPressMenuHiddenTitlesKey)];
    NSMutableArray *remaining = [NSMutableArray array];
    for (id item in items) {
        NSString *sourceTitle = NeoWCMenuSourceTitle(item);
        if (sourceTitle.length == 0 || ![hiddenTitles containsObject:sourceTitle]) [remaining addObject:item];
    }

    NSMutableArray *ordered = [NSMutableArray arrayWithCapacity:remaining.count];
    for (NSString *preferredTitle in NeoWCRuntimeStringList(NeoWCLongPressMenuPreferredOrderKey)) {
        for (id item in [remaining copy]) {
            if ([NeoWCMenuSourceTitle(item) isEqualToString:preferredTitle]) {
                [ordered addObject:item];
                [remaining removeObjectIdenticalTo:item];
            }
        }
    }
    [ordered addObjectsFromArray:remaining];

    NSDictionary *mapping = [defaults dictionaryForKey:NeoWCLongPressMenuTitleMapKey];
    for (id item in ordered) {
        NSString *sourceTitle = NeoWCMenuSourceTitle(item);
        id renamedTitle = sourceTitle.length > 0 ? mapping[sourceTitle] : nil;
        NeoWCSetMenuTitle(item,
                          [renamedTitle isKindOfClass:[NSString class]] && [renamedTitle length] > 0
                              ? renamedTitle
                              : sourceTitle);
    }
    return ordered;
}

static NSUInteger NeoWCMessageType(id message) {
    id value = NeoWCRuntimeSafeValue(message, @"m_uiMessageType");
    return [value respondsToSelector:@selector(unsignedIntegerValue)] ? [value unsignedIntegerValue] : 0;
}

static BOOL NeoWCMessageIsIncoming(id message) {
    NSString *selfUserName = NeoWCCurrentUserWXID();
    if (selfUserName.length == 0) return NO;
    NSString *fromUserName = NeoWCRuntimeStringValue(message, @"m_nsFromUsr");
    NSString *realUserName = NeoWCRuntimeStringValue(message, @"m_nsRealChatUsr");
    if ([fromUserName caseInsensitiveCompare:selfUserName] == NSOrderedSame) return NO;
    if (realUserName.length > 0 && [realUserName caseInsensitiveCompare:selfUserName] == NSOrderedSame) return NO;
    return fromUserName.length > 0;
}

static NSString *NeoWCMessageSession(NSString *sessionUserName, id message) {
    if (sessionUserName.length > 0) return sessionUserName;
    NSString *selfUserName = NeoWCCurrentUserWXID();
    NSString *fromUserName = NeoWCRuntimeStringValue(message, @"m_nsFromUsr");
    NSString *toUserName = NeoWCRuntimeStringValue(message, @"m_nsToUsr");
    return [fromUserName caseInsensitiveCompare:selfUserName] == NSOrderedSame ? toUserName : fromUserName;
}

static NSString *NeoWCMessageDisplayContent(id message, NSString *sessionUserName) {
    NSString *content = NeoWCRuntimeStringValue(message, @"m_nsContent") ?: @"";
    if ([sessionUserName hasSuffix:@"@chatroom"]) {
        NSRange prefix = [content rangeOfString:@":\n"];
        if (prefix.location != NSNotFound && prefix.location < 128) {
            content = [content substringFromIndex:NSMaxRange(prefix)];
        }
    }
    return content;
}

static id NeoWCContactForUserNameWithManager(id manager, NSString *userName) {
    SEL selector = sel_registerName("getContactByName:");
    if (!manager || userName.length == 0 || ![manager respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL, id))objc_msgSend)(manager, selector, userName);
}

static NSString *NeoWCContactDisplayName(id contact, NSString *fallback) {
    for (NSString *key in @[@"m_nsRemark", @"m_nsNickName", @"m_nsUsrName"]) {
        NSString *value = NeoWCRuntimeStringValue(contact, key);
        if (value.length > 0) return value;
    }
    return fallback ?: @"未知用户";
}

BOOL NeoWCShouldBlockIncomingMessage(NSString *sessionUserName, id message) {
    if (!NeoWCEnhancementEnabled(NeoWCMessageBlockEnabledKey) ||
        !NeoWCMessageIsIncoming(message)) return NO;

    NSString *session = NeoWCMessageSession(sessionUserName, message);
    NSString *fromUserName = NeoWCRuntimeStringValue(message, @"m_nsFromUsr");
    NSString *realUserName = NeoWCRuntimeStringValue(message, @"m_nsRealChatUsr");
    NSArray *blockedUsers = NeoWCRuntimeStringList(NeoWCMessageBlockUsersKey);
    NSUInteger messageType = NeoWCMessageType(message);
    BOOL blockedUser = NeoWCRuntimeStringMatchesAny(session, blockedUsers) &&
                       NeoWCMessageBlockConversationMatchesType(session, messageType);
    // Group messages carry the actual sender in m_nsRealChatUsr. Match it
    // before falling back to m_nsFromUsr, following WeChat's native field use.
    if (!blockedUser && realUserName.length > 0) {
        blockedUser = NeoWCRuntimeStringMatchesAny(realUserName, blockedUsers) &&
                      NeoWCMessageBlockConversationMatchesType(realUserName, messageType);
    }
    if (!blockedUser && fromUserName.length > 0) {
        blockedUser = NeoWCRuntimeStringMatchesAny(fromUserName, blockedUsers) &&
                      NeoWCMessageBlockConversationMatchesType(fromUserName, messageType);
    }
    NSString *blockedKeyword = nil;
    if (NeoWCMessageType(message) == 1) {
        NSString *content = NeoWCMessageDisplayContent(message, session);
        blockedKeyword = NeoWCRuntimeMatchedTerm(content, NeoWCMessageBlockKeywordsKey);
    }
    if (!blockedUser && blockedKeyword.length == 0) return NO;
    NeoWCLog(@"已屏蔽一条新收到的消息（会话：%@，类型：%ld）",
             session ?: @"未知", (long)messageType);
    return YES;
}

BOOL NeoWCDeleteBlockedIncomingMessage(id messageManager,
                                       NSString *sessionUserName,
                                       id message) {
    if (!NeoWCShouldBlockIncomingMessage(sessionUserName, message)) return NO;

    NSString *session = NeoWCMessageSession(sessionUserName, message);
    SEL selector = sel_registerName("DelMsg:MsgWrap:");
    if (!messageManager || session.length == 0 || !message ||
        ![messageManager respondsToSelector:selector]) return NO;

    ((void (*)(id, SEL, id, id))objc_msgSend)(messageManager, selector, session, message);
    return YES;
}

static NSMutableDictionary<NSString *, NSString *> *NeoWCGroupMemberListCache(void) {
    static NSMutableDictionary *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ cache = [NSMutableDictionary dictionary]; });
    return cache;
}

static NSSet<NSString *> *NeoWCMemberSetFromList(NSString *memberList) {
    NSMutableSet *members = [NSMutableSet set];
    for (NSString *component in [memberList componentsSeparatedByString:@";"]) {
        NSString *member = [component stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (member.length > 0) [members addObject:member];
    }
    return members;
}

@interface NeoWCGroupMemberChangeSnapshot : NSObject
@property (nonatomic, copy) NSString *sessionUserName;
@property (nonatomic, copy) NSSet<NSString *> *beforeMembers;
@end

@implementation NeoWCGroupMemberChangeSnapshot
@end

id NeoWCCaptureGroupMemberChange(id newContact, id oldContact) {
    if (!NeoWCEnhancementEnabled(NeoWCGroupMemberReminderEnabledKey)) return nil;
    NSString *session = NeoWCRuntimeStringValue(newContact, @"m_nsUsrName");
    if (![session hasSuffix:@"@chatroom"]) return nil;

    NSString *beforeList = NeoWCRuntimeStringValue(oldContact, @"m_nsChatRoomMemList");
    if (beforeList.length == 0) {
        NSMutableDictionary *cache = NeoWCGroupMemberListCache();
        @synchronized (cache) {
            beforeList = cache[session];
        }
    }
    NeoWCGroupMemberChangeSnapshot *snapshot = [NeoWCGroupMemberChangeSnapshot new];
    snapshot.sessionUserName = session;
    snapshot.beforeMembers = NeoWCMemberSetFromList(beforeList ?: @"");
    return snapshot;
}

static NSString *NeoWCGroupMemberDisplayName(id groupContact, id contactManager, NSString *memberUserName) {
    (void)groupContact;
    return NeoWCContactDisplayName(NeoWCContactForUserNameWithManager(contactManager, memberUserName), memberUserName);
}

static NSString *NeoWCGroupMemberNames(NSSet<NSString *> *members, id groupContact, id contactManager) {
    NSMutableArray *names = [NSMutableArray array];
    for (NSString *member in members) {
        [names addObject:NeoWCGroupMemberDisplayName(groupContact, contactManager, member)];
    }
    [names sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSUInteger visibleCount = MIN((NSUInteger)4, names.count);
    NSString *joined = [[names subarrayWithRange:NSMakeRange(0, visibleCount)] componentsJoinedByString:@"、"];
    if (names.count > visibleCount) {
        joined = [joined stringByAppendingFormat:@"等 %lu 人", (unsigned long)names.count];
    }
    return joined;
}

static BOOL NeoWCInsertGroupMemberSystemMessage(NSString *sessionUserName, NSString *content) {
    if (sessionUserName.length == 0 || content.length == 0) return NO;

    Class wrapClass = objc_getClass("CMessageWrap");
    SEL initSelector = sel_registerName("initWithMsgType:");
    if (!wrapClass || ![wrapClass instancesRespondToSelector:initSelector]) return NO;

    id messageManager = NeoWCServiceForClass(objc_getClass("CMessageMgr"));
    SEL addSelector = sel_registerName("AddLocalMsg:MsgWrap:fixTime:NewMsgArriveNotify:");
    if (!messageManager || ![messageManager respondsToSelector:addSelector]) return NO;

    id message = ((id (*)(id, SEL, NSUInteger))objc_msgSend)([wrapClass alloc], initSelector, 10000);
    if (!message) return NO;
    NeoWCRuntimeSetValue(message, @"m_nsFromUsr", sessionUserName);
    NeoWCRuntimeSetValue(message, @"m_nsToUsr", NeoWCCurrentUserWXID() ?: @"");
    NeoWCRuntimeSetValue(message, @"m_uiStatus", @4);
    NeoWCRuntimeSetValue(message, @"m_nsContent", content);
    NeoWCRuntimeSetValue(message, @"m_uiCreateTime", @((NSUInteger)NSDate.date.timeIntervalSince1970));
    ((void (*)(id, SEL, NSString *, id, BOOL, BOOL))objc_msgSend)(messageManager,
                                                                 addSelector,
                                                                 sessionUserName,
                                                                 message,
                                                                 YES,
                                                                 NO);
    return YES;
}

void NeoWCCompleteGroupMemberChange(id value, id contactManager, id newContact) {
    if (![value isKindOfClass:[NeoWCGroupMemberChangeSnapshot class]]) return;
    NeoWCGroupMemberChangeSnapshot *snapshot = value;
    NSString *afterList = NeoWCRuntimeStringValue(newContact, @"m_nsChatRoomMemList");
    id groupContact = newContact;
    if (afterList.length == 0) {
        groupContact = NeoWCContactForUserNameWithManager(contactManager, snapshot.sessionUserName);
        afterList = NeoWCRuntimeStringValue(groupContact, @"m_nsChatRoomMemList");
    }
    if (afterList.length == 0) return;

    NSMutableDictionary *cache = NeoWCGroupMemberListCache();
    @synchronized (cache) {
        cache[snapshot.sessionUserName] = afterList;
    }
    if (snapshot.beforeMembers.count == 0) return;

    NSSet *afterMembers = NeoWCMemberSetFromList(afterList);
    NSMutableSet *joined = [afterMembers mutableCopy];
    [joined minusSet:snapshot.beforeMembers];
    NSMutableSet *left = [snapshot.beforeMembers mutableCopy];
    [left minusSet:afterMembers];
    if (joined.count == 0 && left.count == 0) return;

    NSMutableArray *changes = [NSMutableArray array];
    if (joined.count > 0) {
        [changes addObject:[NSString stringWithFormat:@"「%@」加入了群聊",
                            NeoWCGroupMemberNames(joined, groupContact, contactManager)]];
    }
    if (left.count > 0) {
        [changes addObject:[NSString stringWithFormat:@"「%@」退出了群聊",
                            NeoWCGroupMemberNames(left, groupContact, contactManager)]];
    }
    NSString *content = [changes componentsJoinedByString:@"；"];
    if (!NeoWCInsertGroupMemberSystemMessage(snapshot.sessionUserName, content)) {
        NeoWCLog(@"群成员变动提示写入失败：%@", snapshot.sessionUserName);
    }
}

static UINavigationController *NeoWCCurrentNavigationController(void) {
    Class managerClass = objc_getClass("CAppViewControllerManager");
    SEL selector = sel_registerName("getCurrentNavigationController");
    if (!managerClass || ![managerClass respondsToSelector:selector]) return nil;
    id controller = ((id (*)(id, SEL))objc_msgSend)(managerClass, selector);
    return [controller isKindOfClass:[UINavigationController class]] ? controller : nil;
}

static id NeoWCServiceFromCurrentContext(Class serviceClass) {
    Class contextClass = objc_getClass("MMContext");
    SEL currentSelector = sel_registerName("currentContext");
    SEL serviceSelector = sel_registerName("getService:");
    if (!contextClass || !serviceClass || ![contextClass respondsToSelector:currentSelector]) return nil;
    id context = ((id (*)(id, SEL))objc_msgSend)(contextClass, currentSelector);
    if (!context || ![context respondsToSelector:serviceSelector]) return nil;
    return ((id (*)(id, SEL, Class))objc_msgSend)(context, serviceSelector, serviceClass);
}

void NeoWCOpenChatForUserName(NSString *userName) {
    if (userName.length == 0) return;
    UINavigationController *navigationController = NeoWCCurrentNavigationController();
    if (!navigationController) return;

    UIViewController *visibleController = navigationController.visibleViewController;
    Class chatControllerClass = objc_getClass("BaseMsgContentViewController");
    SEL getContactSelector = sel_registerName("GetCContact");
    if (chatControllerClass && [visibleController isKindOfClass:chatControllerClass] &&
        [visibleController respondsToSelector:getContactSelector]) {
        id currentContact = ((id (*)(id, SEL))objc_msgSend)(visibleController, getContactSelector);
        NSString *currentUserName = NeoWCRuntimeStringValue(currentContact, @"m_nsUsrName");
        if ([currentUserName isEqualToString:userName]) return;
    }

    Class contactManagerClass = objc_getClass("CContactMgr");
    Class messageLogicClass = objc_getClass("MMMsgLogicManager");
    id contactManager = NeoWCServiceFromCurrentContext(contactManagerClass);
    id contact = NeoWCContactForUserNameWithManager(contactManager, userName);
    id messageLogic = NeoWCServiceFromCurrentContext(messageLogicClass);
    SEL pushSelector = sel_registerName("PushOtherBaseMsgControllerByContact:navigationController:animated:");
    if (!contact || !messageLogic || ![messageLogic respondsToSelector:pushSelector]) return;
    ((void (*)(id, SEL, id, id, BOOL))objc_msgSend)(messageLogic,
                                                    pushSelector,
                                                    contact,
                                                    navigationController,
                                                    YES);
}

static UIViewController *NeoWCFindControllerOfClass(UIViewController *controller, Class targetClass) {
    if (!controller || !targetClass) return nil;
    if ([controller isKindOfClass:targetClass]) return controller;
    UIViewController *found = NeoWCFindControllerOfClass(controller.presentedViewController, targetClass);
    if (found) return found;
    for (UIViewController *child in controller.childViewControllers) {
        found = NeoWCFindControllerOfClass(child, targetClass);
        if (found) return found;
    }
    return nil;
}

static void NeoWCOpenMomentsTimelineAttempt(NSUInteger remainingAttempts) {
    Class entryClass = objc_getClass("FindFriendEntryViewController");
    SEL openSelector = sel_registerName("openAlbum");
    Method method = entryClass ? class_getInstanceMethod(entryClass, openSelector) : NULL;
    const char *typeEncoding = method ? method_getTypeEncoding(method) : NULL;
    if (!typeEncoding || strcmp(typeEncoding, "v16@0:8") != 0) {
        NeoWCLog(@"打开朋友圈失败：当前版本入口 ABI 不匹配");
        return;
    }

    UIWindow *window = nil;
    for (UIWindow *candidate in UIApplication.sharedApplication.windows.reverseObjectEnumerator) {
        if (!candidate.hidden && candidate.alpha > 0.0 && candidate.windowLevel == UIWindowLevelNormal) {
            window = candidate;
            if (candidate.isKeyWindow) break;
        }
    }
    UIViewController *entry = NeoWCFindControllerOfClass(window.rootViewController, entryClass);
    if (!entry) {
        if (remainingAttempts > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.50 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                NeoWCOpenMomentsTimelineAttempt(remainingAttempts - 1);
            });
        } else {
            NeoWCLog(@"打开朋友圈失败：未找到发现页控制器");
        }
        return;
    }
    UITabBarController *tabBarController = entry.tabBarController;
    UIViewController *tabRoot = entry.navigationController ?: entry;
    if (tabBarController && tabBarController.selectedViewController != tabRoot) {
        tabBarController.selectedViewController = tabRoot;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        @try { ((void (*)(id, SEL))objc_msgSend)(entry, openSelector); }
        @catch (NSException *exception) {
            NeoWCLog(@"打开朋友圈失败：%@", exception.reason ?: @"未知异常");
        }
    });
}

void NeoWCOpenMomentsTimeline(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ NeoWCOpenMomentsTimelineAttempt(8); });
}

BOOL NeoWCHandleNotificationResponse(id response, void (^completionHandler)(void)) {
    id notification = NeoWCRuntimeSafeValue(response, @"notification");
    id request = NeoWCRuntimeSafeValue(notification, @"request");
    id content = NeoWCRuntimeSafeValue(request, @"content");
    NSDictionary *userInfo = NeoWCRuntimeSafeValue(content, @"userInfo");
    id rawNeoWCType = [userInfo isKindOfClass:[NSDictionary class]] ? userInfo[@"neowc"] : nil;
    NSString *neoWCType = [rawNeoWCType isKindOfClass:[NSString class]] ? rawNeoWCType : nil;
    if ([neoWCType isEqualToString:@"moments-reminder"] ||
        [neoWCType isEqualToString:@"moments-interaction"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ NeoWCOpenMomentsTimeline(); });
        if (completionHandler) completionHandler();
        return YES;
    }

    if (!NeoWCEnhancementEnabled(NeoWCNotificationDirectChatEnabledKey)) return NO;
    id rawUserName = [userInfo isKindOfClass:[NSDictionary class]] ? userInfo[@"u"] : nil;
    NSString *userName = [rawUserName isKindOfClass:[NSString class]]
        ? [rawUserName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
        : nil;
    if (userName.length == 0) return NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.30 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NeoWCOpenChatForUserName(userName);
    });
    NeoWCCompatibilityMarkTriggered(@"notification-direct-chat");
    if (completionHandler) completionHandler();
    return YES;
}

UIView *NeoWCWalletHeaderForView(UIView *view) {
    Class headerClass = objc_getClass("WCPayWalletEntryHeaderView");
    if (!headerClass || ![view isKindOfClass:[UIView class]]) return nil;
    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        if ([ancestor isKindOfClass:headerClass]) return ancestor;
    }
    return nil;
}

BOOL NeoWCViewIsInsideWalletHeader(UIView *view) {
    return NeoWCWalletHeaderForView(view) != nil;
}

void NeoWCRefreshWalletHeaderBalance(id headerView) {
    if (!headerView) return;
    if (!NeoWCEnhancementEnabled(NeoWCWalletBalanceEnabledKey)) return;
    id stored = [[NSUserDefaults standardUserDefaults] objectForKey:NeoWCWalletBalanceFenKey];
    unsigned long long balanceFen = [stored respondsToSelector:@selector(unsignedLongLongValue)]
        ? [stored unsignedLongLongValue]
        : 0;
    if (balanceFen == 0) return;
    Ivar timeoutNumberIvar = class_getInstanceVariable([headerView class], "_timeoutNumber");
    id timeoutNumber = timeoutNumberIvar ? object_getIvar(headerView, timeoutNumberIvar) : nil;
    SEL selector = sel_registerName("updateNumber:");
    if (timeoutNumber && [timeoutNumber respondsToSelector:selector]) {
        ((void (*)(id, SEL, unsigned long long))objc_msgSend)(timeoutNumber, selector, balanceFen);
    }
}
