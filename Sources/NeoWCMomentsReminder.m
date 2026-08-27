#import "NeoWCMomentsReminder.h"
#import "NeoWCAccount.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

static NSString *const NeoWCMomentsReminderSeenItemsKey = @"com.qiu7c.neowc.moments.reminder.seen-items";

NSArray<NSString *> *NeoWCMomentsReminderUsers(void) {
    NSMutableOrderedSet<NSString *> *users = [NSMutableOrderedSet orderedSet];
    for (id value in [NSUserDefaults.standardUserDefaults arrayForKey:NeoWCMomentsReminderUsersKey] ?: @[]) {
        if ([value isKindOfClass:NSString.class] && [value length] > 0 && ![value hasSuffix:@"@chatroom"]) {
            [users addObject:value];
        }
    }
    return users.array;
}

void NeoWCMomentsReminderSetUserSelected(NSString *username, BOOL selected) {
    if (username.length == 0 || [username hasSuffix:@"@chatroom"]) return;
    NSMutableOrderedSet<NSString *> *users = [NSMutableOrderedSet orderedSetWithArray:NeoWCMomentsReminderUsers()];
    if (selected) [users addObject:username]; else [users removeObject:username];
    [NSUserDefaults.standardUserDefaults setObject:users.array forKey:NeoWCMomentsReminderUsersKey];
    [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification
                                                       object:NeoWCMomentsReminderUsersKey];
}

static id NeoWCMomentsReminderObjectValue(id object, const char *selectorName) {
    if (!object || !selectorName) return nil;
    SEL selector = sel_registerName(selectorName);
    Method method = class_getInstanceMethod([object class], selector);
    if (!method || method_getNumberOfArguments(method) != 2) return nil;
    char returnType[8] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    if (returnType[0] != '@') return nil;
    @try { return ((id (*)(id, SEL))objc_msgSend)(object, selector); }
    @catch (__unused NSException *exception) { return nil; }
}

static uint64_t NeoWCMomentsReminderIntegerValue(id object, const char *selectorName) {
    if (!object || !selectorName) return 0;
    SEL selector = sel_registerName(selectorName);
    Method method = class_getInstanceMethod([object class], selector);
    if (!method || method_getNumberOfArguments(method) != 2) return 0;
    char returnType[8] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    if (returnType[0] == '@') {
        id value = NeoWCMomentsReminderObjectValue(object, selectorName);
        return [value respondsToSelector:@selector(unsignedLongLongValue)] ? [value unsignedLongLongValue] : 0;
    }
    @try { return ((uint64_t (*)(id, SEL))objc_msgSend)(object, selector); }
    @catch (__unused NSException *exception) { return 0; }
}

static NSString *NeoWCMomentsReminderString(id value) {
    if ([value isKindOfClass:NSString.class]) {
        NSString *text = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        return text.length > 0 ? text : nil;
    }
    return [value respondsToSelector:@selector(stringValue)] ? [value stringValue] : nil;
}

static id NeoWCMomentsReminderContact(NSString *username) {
    Class contextClass = objc_getClass("MMContext");
    SEL activeSelector = sel_registerName("activeUserContext");
    SEL serviceSelector = sel_registerName("getService:");
    Class managerClass = objc_getClass("CContactMgr");
    if (!contextClass || !managerClass || ![contextClass respondsToSelector:activeSelector]) return nil;
    id context = ((id (*)(id, SEL))objc_msgSend)(contextClass, activeSelector);
    if (!context || ![context respondsToSelector:serviceSelector]) return nil;
    id manager = ((id (*)(id, SEL, Class))objc_msgSend)(context, serviceSelector, managerClass);
    SEL contactSelector = sel_registerName("getContactByName:");
    if (!manager || ![manager respondsToSelector:contactSelector]) return nil;
    return ((id (*)(id, SEL, id))objc_msgSend)(manager, contactSelector, username);
}

static void NeoWCMomentsReminderShowForegroundToast(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        for (UIWindow *candidate in UIApplication.sharedApplication.windows.reverseObjectEnumerator) {
            if (!candidate.hidden && candidate.alpha > 0.0 && candidate.windowLevel == UIWindowLevelNormal) {
                window = candidate;
                if (candidate.isKeyWindow) break;
            }
        }
        if (!window || message.length == 0) return;
        const NSInteger toastTag = 0x4E574D52;
        [[window viewWithTag:toastTag] removeFromSuperview];
        UILabel *toast = [UILabel new];
        toast.tag = toastTag;
        toast.text = message;
        toast.textColor = UIColor.whiteColor;
        toast.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.9];
        toast.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        toast.numberOfLines = 3;
        toast.textAlignment = NSTextAlignmentCenter;
        toast.layer.cornerRadius = 13.0;
        toast.layer.cornerCurve = kCACornerCurveContinuous;
        toast.layer.masksToBounds = YES;
        toast.translatesAutoresizingMaskIntoConstraints = NO;
        [window addSubview:toast];
        [NSLayoutConstraint activateConstraints:@[
            [toast.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
            [toast.topAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.topAnchor constant:12.0],
            [toast.leadingAnchor constraintGreaterThanOrEqualToAnchor:window.leadingAnchor constant:28.0],
            [toast.trailingAnchor constraintLessThanOrEqualToAnchor:window.trailingAnchor constant:-28.0],
            [toast.heightAnchor constraintGreaterThanOrEqualToConstant:42.0],
        ]];
        toast.alpha = 0.0;
        [UIView animateWithDuration:0.2 animations:^{ toast.alpha = 1.0; } completion:^(__unused BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2 animations:^{ toast.alpha = 0.0; }
                                 completion:^(__unused BOOL hidden) { [toast removeFromSuperview]; }];
            });
        }];
    });
}

static void NeoWCMomentsReminderNotify(NSString *username, NSString *nickname, NSString *content, uint64_t createdAt, NSString *tid) {
    NSString *name = nickname.length > 0 ? nickname : username;
    NSString *body = content.length > 0 ? [NSString stringWithFormat:@"%@：%@", name, content] :
                                          [NSString stringWithFormat:@"%@ 发布了新朋友圈", name];
    if (body.length > 180) body = [[body substringToIndex:177] stringByAppendingString:@"…"];
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        NeoWCMomentsReminderShowForegroundToast(body);
        return;
    }

    UNMutableNotificationContent *notification = [UNMutableNotificationContent new];
    notification.title = @"朋友圈提醒";
    notification.body = body;
    notification.sound = UNNotificationSound.defaultSound;
    notification.userInfo = @{ @"neowc": @"moments-reminder", @"username": username ?: @"", @"tid": tid ?: @"" };
    NSString *identifier = [NSString stringWithFormat:@"neowc.moments.%@.%@.%llu", username ?: @"unknown", tid ?: @"unknown", createdAt];
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:notification trigger:trigger];
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *error) {
        if (error) NeoWCLog(@"发送朋友圈提醒失败：%@", error.localizedDescription ?: @"未知错误");
    }];
}

@interface NeoWCMomentsReminderManager : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *controllers;
@property (nonatomic, assign) NSTimeInterval lastCheckTime;
@property (nonatomic, assign) BOOL checking;
+ (instancetype)sharedManager;
- (void)tick;
- (void)performCheck;
- (void)settingsDidChange;
@end

@implementation NeoWCMomentsReminderManager

+ (instancetype)sharedManager {
    static NeoWCMomentsReminderManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [NeoWCMomentsReminderManager new];
        manager.controllers = [NSMutableDictionary dictionary];
    });
    return manager;
}

- (NSTimeInterval)checkInterval {
    NSTimeInterval interval = [NSUserDefaults.standardUserDefaults doubleForKey:NeoWCMomentsReminderIntervalKey];
    return MIN(3600.0, MAX(30.0, interval > 0.0 ? interval : 60.0));
}

- (id)controllerForUsername:(NSString *)username {
    id controller = self.controllers[username];
    if (controller) return controller;
    Class controllerClass = objc_getClass("WCListViewController");
    id contact = NeoWCMomentsReminderContact(username);
    if (!controllerClass || !contact) return nil;
    controller = [[controllerClass alloc] init];
    SEL setContactSelector = sel_registerName("setM_contact:");
    if (![controller respondsToSelector:setContactSelector]) return nil;
    ((void (*)(id, SEL, id))objc_msgSend)(controller, setContactSelector, contact);
    self.controllers[username] = controller;
    return controller;
}

- (NSArray *)loadItemsForUsername:(NSString *)username success:(BOOL *)success {
    if (success) *success = NO;
    id controller = [self controllerForUsername:username];
    SEL initDataSelector = sel_registerName("initData:");
    if (!controller || ![controller respondsToSelector:initDataSelector]) return @[];
    @try {
        ((void (*)(id, SEL, unsigned int))objc_msgSend)(controller, initDataSelector, 1);
        id value = [controller valueForKey:@"m_arrPhotoDatas"];
        if (![value isKindOfClass:NSArray.class]) return @[];
        if (success) *success = YES;
        return [value copy];
    } @catch (NSException *exception) {
        NeoWCLog(@"读取 %@ 的朋友圈数据失败：%@", username, exception.reason ?: @"未知异常");
        return @[];
    }
}

- (void)processItems:(NSArray *)items username:(NSString *)username seenRoot:(NSMutableDictionary *)seenRoot account:(NSString *)account {
    if (username.length == 0) return;
    NSMutableDictionary *accountSeen = [seenRoot[account] isKindOfClass:NSDictionary.class]
        ? [seenRoot[account] mutableCopy] : [NSMutableDictionary dictionary];
    BOOL hasBaseline = [accountSeen[username] isKindOfClass:NSArray.class];
    NSArray<NSString *> *previouslySeen = hasBaseline ? accountSeen[username] : @[];
    NSSet<NSString *> *previouslySeenSet = [NSSet setWithArray:previouslySeen];
    NSMutableOrderedSet<NSString *> *currentTids = [NSMutableOrderedSet orderedSet];
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSMutableArray<NSDictionary *> *newItems = [NSMutableArray array];

    for (id item in items) {
        NSString *tid = NeoWCMomentsReminderString(NeoWCMomentsReminderObjectValue(item, "tid"));
        if (tid.length == 0) continue;
        BOOL alreadySeen = [previouslySeenSet containsObject:tid];
        [currentTids addObject:tid];
        if (!hasBaseline || alreadySeen) continue;
        uint64_t createdAt = NeoWCMomentsReminderIntegerValue(item, "createtime");
        if (createdAt == 0 || now - (NSTimeInterval)createdAt > 86400.0) continue;
        NSString *nickname = NeoWCMomentsReminderString(NeoWCMomentsReminderObjectValue(item, "nickname"));
        NSString *content = NeoWCMomentsReminderString(NeoWCMomentsReminderObjectValue(item, "contentDesc"));
        [newItems addObject:@{ @"tid": tid,
                               @"createdAt": @(createdAt),
                               @"nickname": nickname ?: @"",
                               @"content": content ?: @"" }];
    }

    NSMutableOrderedSet<NSString *> *mergedSeen = [NSMutableOrderedSet orderedSetWithOrderedSet:currentTids];
    [mergedSeen addObjectsFromArray:previouslySeen];
    while (mergedSeen.count > 200) [mergedSeen removeObjectAtIndex:mergedSeen.count - 1];
    accountSeen[username] = mergedSeen.array;
    seenRoot[account] = accountSeen;
    for (NSDictionary *item in [newItems sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [left[@"createdAt"] compare:right[@"createdAt"]];
    }]) {
        NeoWCMomentsReminderNotify(username, item[@"nickname"], item[@"content"],
                                   [item[@"createdAt"] unsignedLongLongValue], item[@"tid"]);
    }
}

- (void)tick {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self tick]; });
        return;
    }
    if (self.checking || !NeoWCEnhancementEnabled(NeoWCMomentsReminderEnabledKey)) return;
    NSArray<NSString *> *users = NeoWCMomentsReminderUsers();
    if (users.count == 0) return;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    if (self.lastCheckTime > 0.0 && now - self.lastCheckTime < [self checkInterval]) return;
    self.lastCheckTime = now;
    self.checking = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self performCheck];
    });
}

- (void)performCheck {
    if (!NeoWCEnhancementEnabled(NeoWCMomentsReminderEnabledKey)) {
        self.checking = NO;
        return;
    }
    NSArray<NSString *> *users = NeoWCMomentsReminderUsers();
    if (users.count == 0) {
        self.checking = NO;
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSMutableDictionary *seenRoot = [[defaults dictionaryForKey:NeoWCMomentsReminderSeenItemsKey] mutableCopy] ?: [NSMutableDictionary dictionary];
    NSString *account = NeoWCCurrentUserWXID() ?: @"default";
    for (NSString *username in users) {
        BOOL loaded = NO;
        NSArray *items = [self loadItemsForUsername:username success:&loaded];
        if (loaded) {
            [self processItems:items username:username seenRoot:seenRoot account:account];
        }
    }
    [defaults setObject:seenRoot forKey:NeoWCMomentsReminderSeenItemsKey];
    self.checking = NO;
}

- (void)settingsDidChange {
    self.lastCheckTime = 0.0;
    NSSet *selected = [NSSet setWithArray:NeoWCMomentsReminderUsers()];
    for (NSString *username in self.controllers.allKeys.copy) {
        if (![selected containsObject:username]) [self.controllers removeObjectForKey:username];
    }
    if (NeoWCEnhancementEnabled(NeoWCMomentsReminderEnabledKey)) [self tick];
}

@end

void NeoWCMomentsReminderTick(void) {
    [[NeoWCMomentsReminderManager sharedManager] tick];
}

void NeoWCMomentsReminderSettingsDidChange(void) {
    [[NeoWCMomentsReminderManager sharedManager] settingsDidChange];
}
