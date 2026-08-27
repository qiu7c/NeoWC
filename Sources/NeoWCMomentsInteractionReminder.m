#import "NeoWCMomentsInteractionReminder.h"
#import "NeoWCAccount.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <stdlib.h>
#import <string.h>

static NSString *const NeoWCMomentsInteractionStateKey = @"com.qiu7c.neowc.moments.interaction-reminder.state";

static const char *NeoWCMomentsInteractionSkipQualifiers(const char *type) {
    while (type && strchr("rnNoORV", *type)) type++;
    return type ?: "";
}

static BOOL NeoWCMomentsInteractionMethodMatches(id object, SEL selector, char returnType) {
    Method method = object ? class_getInstanceMethod([object class], selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != 2) return NO;
    char *type = method_copyReturnType(method);
    BOOL matches = NeoWCMomentsInteractionSkipQualifiers(type)[0] == returnType;
    free(type);
    return matches;
}

static NSString *NeoWCMomentsInteractionStringGetter(id object, const char *selectorName) {
    SEL selector = sel_registerName(selectorName);
    if (!NeoWCMomentsInteractionMethodMatches(object, selector, '@')) return nil;
    id value = nil;
    @try { value = ((id (*)(id, SEL))objc_msgSend)(object, selector); }
    @catch (__unused NSException *exception) { return nil; }
    if (![value isKindOfClass:NSString.class]) return nil;
    NSString *string = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return string.length > 0 ? string : nil;
}

static NSString *NeoWCMomentsInteractionMessageKey(id message) {
    if (!message) return nil;
    NSString *msgID = NeoWCMomentsInteractionStringGetter(message, "msgID");
    if (msgID.length > 0) return [@"msg:" stringByAppendingString:msgID];
    NSString *clientID = NeoWCMomentsInteractionStringGetter(message, "clientId");
    if (clientID.length > 0) return [@"client:" stringByAppendingString:clientID];
    NSString *objectID = NeoWCMomentsInteractionStringGetter(message, "objID");
    NSString *parentID = NeoWCMomentsInteractionStringGetter(message, "parentObjID");
    if (objectID.length > 0 || parentID.length > 0) {
        return [NSString stringWithFormat:@"object:%@:%@", objectID ?: @"", parentID ?: @""];
    }
    return [NSString stringWithFormat:@"pointer:%p", (__bridge void *)message];
}

static long long NeoWCMomentsInteractionMessageType(id message) {
    SEL selector = sel_registerName("msgTypeFromClientId");
    Method method = message ? class_getInstanceMethod([message class], selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != 2) return 0;
    char *returnType = method_copyReturnType(method);
    BOOL matches = NeoWCMomentsInteractionSkipQualifiers(returnType)[0] == 'q';
    free(returnType);
    if (!matches) return 0;
    @try { return ((long long (*)(id, SEL))objc_msgSend)(message, selector); }
    @catch (__unused NSException *exception) { return 0; }
}

static void NeoWCMomentsInteractionShowForegroundToast(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        for (UIWindow *candidate in UIApplication.sharedApplication.windows.reverseObjectEnumerator) {
            if (!candidate.hidden && candidate.alpha > 0.0 && candidate.windowLevel == UIWindowLevelNormal) {
                window = candidate;
                if (candidate.isKeyWindow) break;
            }
        }
        if (!window || message.length == 0) return;
        const NSInteger toastTag = 0x4E574D49;
        [[window viewWithTag:toastTag] removeFromSuperview];
        UILabel *toast = [UILabel new];
        toast.tag = toastTag;
        toast.text = message;
        toast.textColor = UIColor.whiteColor;
        toast.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.9];
        toast.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        toast.numberOfLines = 2;
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

static void NeoWCMomentsInteractionNotify(NSUInteger count, NSString *messageKey, long long messageType) {
    NSString *typeName = messageType == 1 ? @"点赞" : (messageType == 2 ? @"评论" : @"互动");
    NSString *body = count > 1
        ? [NSString stringWithFormat:@"收到 %lu 条新的朋友圈互动，最新一条是%@", (unsigned long)count, typeName]
        : [NSString stringWithFormat:@"收到新的朋友圈%@", typeName];
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        NeoWCMomentsInteractionShowForegroundToast(body);
        return;
    }
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = [NSString stringWithFormat:@"朋友圈%@提醒", typeName];
    content.body = body;
    content.sound = UNNotificationSound.defaultSound;
    content.userInfo = @{ @"neowc": @"moments-interaction" };
    NSString *identifier = [NSString stringWithFormat:@"neowc.moments.interaction.%lu.%lu",
                              (unsigned long)messageKey.hash, (unsigned long)count];
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *error) {
        if (error) NeoWCLog(@"发送朋友圈互动提醒失败：%@", error.localizedDescription ?: @"未知错误");
    }];
}

@interface NeoWCMomentsInteractionReminderManager : NSObject
@property (nonatomic, weak) id notificationManager;
@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *lastMessageKey;
@property (nonatomic, assign) unsigned int lastUnreadCount;
@property (nonatomic, assign) NSUInteger pendingIncrease;
@property (nonatomic, assign) BOOL baselineReady;
@property (nonatomic, assign) BOOL lastMessageReadScheduled;
+ (instancetype)sharedManager;
- (void)observeManager:(id)manager unreadCount:(unsigned int)count;
- (void)observeManager:(id)manager lastUnreadMessage:(id)message;
- (void)tick;
- (void)settingsDidChange;
@end

@implementation NeoWCMomentsInteractionReminderManager

+ (instancetype)sharedManager {
    static NeoWCMomentsInteractionReminderManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [NeoWCMomentsInteractionReminderManager new]; });
    return manager;
}

- (NSString *)currentAccount {
    return NeoWCCurrentUserWXID() ?: @"default";
}

- (NSMutableDictionary *)stateRoot {
    NSDictionary *saved = [NSUserDefaults.standardUserDefaults dictionaryForKey:NeoWCMomentsInteractionStateKey];
    return saved ? [saved mutableCopy] : [NSMutableDictionary dictionary];
}

- (void)prepareAccountIfNeeded {
    NSString *account = [self currentAccount];
    if ([self.account isEqualToString:account]) return;
    self.account = account;
    NSMutableDictionary *root = [self stateRoot];
    id savedState = root[account];
    NSDictionary *state = [savedState isKindOfClass:NSDictionary.class] ? savedState : nil;
    self.baselineReady = state != nil;
    self.lastUnreadCount = [state[@"count"] unsignedIntValue];
    self.lastMessageKey = [state[@"messageKey"] isKindOfClass:NSString.class] ? state[@"messageKey"] : nil;
    self.pendingIncrease = 0;
    self.lastMessageReadScheduled = NO;
}

- (void)saveState {
    if (self.account.length == 0) return;
    NSMutableDictionary *root = [self stateRoot];
    root[self.account] = @{ @"count": @(self.lastUnreadCount), @"messageKey": self.lastMessageKey ?: @"" };
    [NSUserDefaults.standardUserDefaults setObject:root forKey:NeoWCMomentsInteractionStateKey];
}

- (void)scheduleLastMessageReadFromManager:(id)manager {
    if (self.lastMessageReadScheduled || !manager) return;
    self.lastMessageReadScheduled = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        strongSelf.lastMessageReadScheduled = NO;
        if (!strongSelf || strongSelf.pendingIncrease == 0 ||
            !NeoWCEnhancementEnabled(NeoWCMomentsInteractionReminderEnabledKey)) return;
        SEL selector = sel_registerName("getLastUnReadMessage");
        if (!NeoWCMomentsInteractionMethodMatches(manager, selector, '@')) return;
        @try { ((id (*)(id, SEL))objc_msgSend)(manager, selector); }
        @catch (NSException *exception) { NeoWCLog(@"读取朋友圈最后未读互动失败：%@", exception.reason ?: @"未知异常"); }
    });
}

- (void)observeManager:(id)manager unreadCount:(unsigned int)count {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self observeManager:manager unreadCount:count]; });
        return;
    }
    if (manager) self.notificationManager = manager;
    if (!NeoWCEnhancementEnabled(NeoWCMomentsInteractionReminderEnabledKey)) return;
    [self prepareAccountIfNeeded];
    if (!self.baselineReady) {
        self.baselineReady = YES;
        self.lastUnreadCount = count;
        [self saveState];
        return;
    }
    if (count > self.lastUnreadCount) {
        self.pendingIncrease += count - self.lastUnreadCount;
        self.lastUnreadCount = count;
        [self scheduleLastMessageReadFromManager:manager ?: self.notificationManager];
    } else if (count < self.lastUnreadCount) {
        self.lastUnreadCount = count;
        self.pendingIncrease = 0;
        [self saveState];
    }
}

- (void)observeManager:(id)manager lastUnreadMessage:(id)message {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self observeManager:manager lastUnreadMessage:message]; });
        return;
    }
    if (manager) self.notificationManager = manager;
    if (!NeoWCEnhancementEnabled(NeoWCMomentsInteractionReminderEnabledKey) || self.pendingIncrease == 0 || !message) return;
    [self prepareAccountIfNeeded];
    NSString *messageKey = NeoWCMomentsInteractionMessageKey(message);
    if (messageKey.length == 0) return;
    NSUInteger increase = self.pendingIncrease;
    self.pendingIncrease = 0;
    BOOL duplicate = [self.lastMessageKey isEqualToString:messageKey];
    long long messageType = NeoWCMomentsInteractionMessageType(message);
    self.lastMessageKey = messageKey;
    [self saveState];
    if (!duplicate) NeoWCMomentsInteractionNotify(increase, messageKey, messageType);
}

- (void)tick {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self tick]; });
        return;
    }
    if (!NeoWCEnhancementEnabled(NeoWCMomentsInteractionReminderEnabledKey)) return;
    id manager = self.notificationManager;
    SEL selector = sel_registerName("getUnReadMessageCount");
    if (!NeoWCMomentsInteractionMethodMatches(manager, selector, 'I')) return;
    @try { ((unsigned int (*)(id, SEL))objc_msgSend)(manager, selector); }
    @catch (NSException *exception) { NeoWCLog(@"读取朋友圈互动未读数失败：%@", exception.reason ?: @"未知异常"); }
}

- (void)settingsDidChange {
    self.account = nil;
    self.baselineReady = NO;
    self.pendingIncrease = 0;
    self.lastMessageReadScheduled = NO;
    if (NeoWCEnhancementEnabled(NeoWCMomentsInteractionReminderEnabledKey)) [self tick];
}

@end

void NeoWCMomentsInteractionObserveUnreadCount(id manager, unsigned int count) {
    [[NeoWCMomentsInteractionReminderManager sharedManager] observeManager:manager unreadCount:count];
}

void NeoWCMomentsInteractionObserveLastUnreadMessage(id manager, id message) {
    [[NeoWCMomentsInteractionReminderManager sharedManager] observeManager:manager lastUnreadMessage:message];
}

void NeoWCMomentsInteractionReminderTick(void) {
    [[NeoWCMomentsInteractionReminderManager sharedManager] tick];
}

void NeoWCMomentsInteractionReminderSettingsDidChange(void) {
    [[NeoWCMomentsInteractionReminderManager sharedManager] settingsDidChange];
}
