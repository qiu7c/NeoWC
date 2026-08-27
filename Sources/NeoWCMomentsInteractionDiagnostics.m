#import "NeoWCMomentsInteractionDiagnostics.h"
#import "NeoWCDebug.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <stdint.h>
#import <stdlib.h>
#import <string.h>

extern void MSHookMessageEx(Class cls, SEL selector, IMP replacement, IMP *original);

static void (*NeoWCOriginalTimelineCheckNewMessage)(id, SEL);
static void (*NeoWCOriginalTimelineViewDidAppear)(id, SEL, BOOL);
static NSUInteger (*NeoWCOriginalNotificationUnreadCount)(id, SEL);
static NSUInteger (*NeoWCOriginalNotificationRelatedUnreadCount)(id, SEL);
static id (*NeoWCOriginalNotificationLastUnreadMessage)(id, SEL);
static id (*NeoWCOriginalNotificationLatestReadMessage)(id, SEL);
static id (*NeoWCOriginalCommentMessagesWithDataArray)(id, SEL, id);
static void (*NeoWCOriginalCommentRefreshFooter)(id, SEL, id);
static void (*NeoWCOriginalCommentUpdateSections)(id, SEL);
static void (*NeoWCOriginalCommentUpdateTitle)(id, SEL);
static void (*NeoWCOriginalCommentClearLists)(id, SEL);
static __weak id NeoWCLastTimelineController;
static void (*NeoWCOriginalCommentViewDidAppear)(id, SEL, BOOL);
static __weak id NeoWCLastCommentListController;

typedef NS_ENUM(NSUInteger, NeoWCDiagnosticSignature) {
    NeoWCDiagnosticSignatureVoidNoArguments,
    NeoWCDiagnosticSignatureIntegerNoArguments,
    NeoWCDiagnosticSignatureObjectNoArguments,
    NeoWCDiagnosticSignatureObjectOneObject,
    NeoWCDiagnosticSignatureVoidOneObject,
    NeoWCDiagnosticSignatureVoidOneBool,
};

@interface NeoWCMomentsInteractionDiagnosticManager : NSObject
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, assign) NSUInteger sequence;
@property (nonatomic, strong) NSMutableArray<NSString *> *events;
@property (nonatomic, strong) NSMutableSet<NSString *> *installedHooks;
@property (nonatomic, strong, nullable) NSURL *latestReportURL;
+ (instancetype)sharedManager;
- (void)startRecording;
- (void)stopRecording;
- (void)clearRecording;
- (void)recordEvent:(NSString *)event object:(nullable id)object;
- (void)installAvailableHooks;
- (NSURL * _Nullable)writeReportWithReason:(NSString *)reason error:(NSError **)error;
- (BOOL)triggerTimelineCheck;
@end

static const char *NeoWCSkipTypeQualifiers(const char *type) {
    while (type && strchr("rnNoORV", *type)) type++;
    return type ?: "";
}

static BOOL NeoWCTypeIsInteger(const char *type) {
    type = NeoWCSkipTypeQualifiers(type);
    return type[0] && strchr("cCsSiIlLqQB", type[0]) != NULL;
}

static BOOL NeoWCMethodMatchesSignature(Method method, NeoWCDiagnosticSignature signature) {
    if (!method) return NO;
    unsigned int expectedArguments = (signature == NeoWCDiagnosticSignatureObjectOneObject ||
                                      signature == NeoWCDiagnosticSignatureVoidOneObject ||
                                      signature == NeoWCDiagnosticSignatureVoidOneBool) ? 3 : 2;
    if (method_getNumberOfArguments(method) != expectedArguments) return NO;

    char *returnType = method_copyReturnType(method);
    const char *normalizedReturn = NeoWCSkipTypeQualifiers(returnType);
    BOOL validReturn = NO;
    switch (signature) {
        case NeoWCDiagnosticSignatureVoidNoArguments:
        case NeoWCDiagnosticSignatureVoidOneObject:
        case NeoWCDiagnosticSignatureVoidOneBool:
            validReturn = normalizedReturn[0] == 'v';
            break;
        case NeoWCDiagnosticSignatureIntegerNoArguments:
            validReturn = NeoWCTypeIsInteger(normalizedReturn);
            break;
        case NeoWCDiagnosticSignatureObjectNoArguments:
        case NeoWCDiagnosticSignatureObjectOneObject:
            validReturn = normalizedReturn[0] == '@';
            break;
    }
    free(returnType);
    if (!validReturn || expectedArguments != 3) return validReturn;

    char *argumentType = method_copyArgumentType(method, 2);
    const char argumentCode = NeoWCSkipTypeQualifiers(argumentType)[0];
    BOOL validArgument = signature == NeoWCDiagnosticSignatureVoidOneBool
        ? (argumentCode == 'B' || argumentCode == 'c') : argumentCode == '@';
    free(argumentType);
    return validArgument;
}

static NSString *NeoWCDiagnosticTimestamp(void) {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    });
    @synchronized (formatter) {
        return [formatter stringFromDate:NSDate.date];
    }
}

static NSString *NeoWCDiagnosticOneLine(id value) {
    if (!value) return @"nil";
    if ([value isKindOfClass:NSString.class]) {
        NSString *string = [(NSString *)value stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
        if (string.length > 300) string = [[string substringToIndex:300] stringByAppendingString:@"…"];
        return [NSString stringWithFormat:@"%@(%@)", NSStringFromClass([value class]), string];
    }
    if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSDate.class]) {
        return [NSString stringWithFormat:@"%@(%@)", NSStringFromClass([value class]), value];
    }
    if ([value isKindOfClass:NSData.class]) {
        return [NSString stringWithFormat:@"%@(%lu bytes)", NSStringFromClass([value class]),
                (unsigned long)[(NSData *)value length]];
    }
    if ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSSet.class] ||
        [value isKindOfClass:NSDictionary.class]) {
        return [NSString stringWithFormat:@"%@(%lu items)", NSStringFromClass([value class]),
                (unsigned long)[value count]];
    }
    return [NSString stringWithFormat:@"%@<%p>", NSStringFromClass([value class]), (__bridge void *)value];
}

static NSString *NeoWCPrimitiveIvarValue(id object, Ivar ivar) {
    const char *type = NeoWCSkipTypeQualifiers(ivar_getTypeEncoding(ivar));
    if (!type[0]) return @"<unknown>";
    uint8_t *bytes = (__bridge void *)object;
    bytes += ivar_getOffset(ivar);
    switch (type[0]) {
        case 'B': { BOOL value; memcpy(&value, bytes, sizeof(value)); return value ? @"YES" : @"NO"; }
        case 'c': { char value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%d", value]; }
        case 'C': { unsigned char value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%u", value]; }
        case 's': { short value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%d", value]; }
        case 'S': { unsigned short value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%u", value]; }
        case 'i': { int value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%d", value]; }
        case 'I': { unsigned int value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%u", value]; }
        case 'l': { long value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%ld", value]; }
        case 'L': { unsigned long value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%lu", value]; }
        case 'q': { long long value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%lld", value]; }
        case 'Q': { unsigned long long value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%llu", value]; }
        case 'f': { float value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%g", value]; }
        case 'd': { double value; memcpy(&value, bytes, sizeof(value)); return [NSString stringWithFormat:@"%g", value]; }
        case ':': { SEL value; memcpy(&value, bytes, sizeof(value)); return value ? NSStringFromSelector(value) : @"nil"; }
        case '#': { Class value; memcpy(&value, bytes, sizeof(value)); return value ? NSStringFromClass(value) : @"nil"; }
        default: return [NSString stringWithFormat:@"<type %s>", type];
    }
}

static void NeoWCAppendObjectReport(NSMutableString *report, NSString *title, id object) {
    [report appendFormat:@"\nOBJECT %@\n%@\n", title, NeoWCDiagnosticOneLine(object)];
    if (!object) return;
    NSUInteger totalIvars = 0;
    for (Class cls = [object class]; cls && totalIvars < 300; cls = class_getSuperclass(cls)) {
        [report appendFormat:@"\n[%@]\n", NSStringFromClass(cls)];
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList(cls, &count);
        for (unsigned int index = 0; index < count && totalIvars < 300; index++, totalIvars++) {
            Ivar ivar = ivars[index];
            const char *name = ivar_getName(ivar) ?: "?";
            const char *type = NeoWCSkipTypeQualifiers(ivar_getTypeEncoding(ivar));
            NSString *value = nil;
            @try {
                value = type[0] == '@' ? NeoWCDiagnosticOneLine(object_getIvar(object, ivar))
                                      : NeoWCPrimitiveIvarValue(object, ivar);
            } @catch (NSException *exception) {
                value = [NSString stringWithFormat:@"<exception %@>", exception.name];
            }
            [report appendFormat:@"%s %s = %@\n", type, name, value ?: @"nil"];
        }
        free(ivars);
    }
}

static void NeoWCAppendClassReport(NSMutableString *report, NSString *className) {
    Class cls = NSClassFromString(className);
    [report appendFormat:@"\n\nCLASS %@ %@\n", className, cls ? @"AVAILABLE" : @"MISSING"];
    if (!cls) return;
    [report appendString:@"HIERARCHY\n"];
    for (Class cursor = cls; cursor; cursor = class_getSuperclass(cursor)) {
        [report appendFormat:@"%@\n", NSStringFromClass(cursor)];
    }
    [report appendString:@"\nIVARS\n"];
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(cls, &ivarCount);
    for (unsigned int index = 0; index < ivarCount; index++) {
        [report appendFormat:@"%s %s offset=%td\n", ivar_getTypeEncoding(ivars[index]) ?: "?",
         ivar_getName(ivars[index]) ?: "?", ivar_getOffset(ivars[index])];
    }
    free(ivars);
    [report appendString:@"\nPROPERTIES\n"];
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    for (unsigned int index = 0; index < propertyCount; index++) {
        [report appendFormat:@"%s attributes=%s\n", property_getName(properties[index]) ?: "?",
         property_getAttributes(properties[index]) ?: "?"];
    }
    free(properties);
    [report appendString:@"\nINSTANCE METHODS\n"];
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    for (unsigned int index = 0; index < methodCount; index++) {
        [report appendFormat:@"- %@ encoding=%s imp=0x%llx\n", NSStringFromSelector(method_getName(methods[index])),
         method_getTypeEncoding(methods[index]) ?: "?", (unsigned long long)(uintptr_t)method_getImplementation(methods[index])];
    }
    free(methods);
    [report appendString:@"\nCLASS METHODS\n"];
    Class meta = object_getClass(cls);
    methods = class_copyMethodList(meta, &methodCount);
    for (unsigned int index = 0; index < methodCount; index++) {
        [report appendFormat:@"+ %@ encoding=%s imp=0x%llx\n", NSStringFromSelector(method_getName(methods[index])),
         method_getTypeEncoding(methods[index]) ?: "?", (unsigned long long)(uintptr_t)method_getImplementation(methods[index])];
    }
    free(methods);
}

static id NeoWCMomentsNotificationManager(void) {
    Class contextClass = NSClassFromString(@"MMContext");
    Class managerClass = NSClassFromString(@"WCNotificationCenterMgr");
    SEL activeSelector = NSSelectorFromString(@"activeUserContext");
    SEL serviceSelector = NSSelectorFromString(@"getService:");
    if (!contextClass || !managerClass || ![contextClass respondsToSelector:activeSelector]) return nil;
    id context = ((id (*)(id, SEL))objc_msgSend)(contextClass, activeSelector);
    if (!context || ![context respondsToSelector:serviceSelector]) return nil;
    return ((id (*)(id, SEL, Class))objc_msgSend)(context, serviceSelector, managerClass);
}

static NSString *NeoWCInvokeNoArgumentSelector(id target, NSString *selectorName, id __strong *objectResult) {
    if (objectResult) *objectResult = nil;
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = target ? [target methodSignatureForSelector:selector] : nil;
    if (!signature || signature.numberOfArguments != 2) return @"UNAVAILABLE";
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = selector;
    @try { [invocation invoke]; }
    @catch (NSException *exception) { return [NSString stringWithFormat:@"EXCEPTION %@: %@", exception.name, exception.reason ?: @""]; }

    const char *type = NeoWCSkipTypeQualifiers(signature.methodReturnType);
    if (type[0] == 'v') return @"void";
    if (type[0] == '@') {
        __unsafe_unretained id value = nil;
        [invocation getReturnValue:&value];
        if (objectResult) *objectResult = value;
        return NeoWCDiagnosticOneLine(value);
    }
    NSUInteger length = signature.methodReturnLength;
    void *buffer = calloc(1, MAX((NSUInteger)1, length));
    [invocation getReturnValue:buffer];
    NSString *result = nil;
    if (NeoWCTypeIsInteger(type)) {
        unsigned long long value = 0;
        memcpy(&value, buffer, MIN(sizeof(value), length));
        result = [NSString stringWithFormat:@"%llu (type %s)", value, type];
    } else if (type[0] == 'f') {
        float value = 0; memcpy(&value, buffer, MIN(sizeof(value), length)); result = [NSString stringWithFormat:@"%g", value];
    } else if (type[0] == 'd') {
        double value = 0; memcpy(&value, buffer, MIN(sizeof(value), length)); result = [NSString stringWithFormat:@"%g", value];
    } else {
        result = [NSString stringWithFormat:@"<type %s length %lu>", type, (unsigned long)length];
    }
    free(buffer);
    return result;
}

static void NeoWCRecordMomentEvent(NSString *event, id object) {
    [[NeoWCMomentsInteractionDiagnosticManager sharedManager] recordEvent:event object:object];
}

static void NeoWCHookTimelineCheckNewMessage(id self, SEL _cmd) {
    NeoWCLastTimelineController = self;
    NeoWCRecordMomentEvent(@"WCTimeLineViewController checkNewMessage BEFORE", self);
    if (NeoWCOriginalTimelineCheckNewMessage) NeoWCOriginalTimelineCheckNewMessage(self, _cmd);
    NeoWCRecordMomentEvent(@"WCTimeLineViewController checkNewMessage AFTER", self);
}

static void NeoWCHookTimelineViewDidAppear(id self, SEL _cmd, BOOL animated) {
    NeoWCLastTimelineController = self;
    NeoWCRecordMomentEvent([NSString stringWithFormat:@"WCTimeLineViewController viewDidAppear: animated=%@",
                            animated ? @"YES" : @"NO"], self);
    if (NeoWCOriginalTimelineViewDidAppear) NeoWCOriginalTimelineViewDidAppear(self, _cmd, animated);
}

static NSUInteger NeoWCHookNotificationUnreadCount(id self, SEL _cmd) {
    NSUInteger value = NeoWCOriginalNotificationUnreadCount ? NeoWCOriginalNotificationUnreadCount(self, _cmd) : 0;
    NeoWCRecordMomentEvent([NSString stringWithFormat:@"WCNotificationCenterMgr getUnReadMessageCount => %lu", (unsigned long)value], self);
    return value;
}

static NSUInteger NeoWCHookNotificationRelatedUnreadCount(id self, SEL _cmd) {
    NSUInteger value = NeoWCOriginalNotificationRelatedUnreadCount ? NeoWCOriginalNotificationRelatedUnreadCount(self, _cmd) : 0;
    NeoWCRecordMomentEvent([NSString stringWithFormat:@"WCNotificationCenterMgr getUnReadMessageCountReleatedToMe => %lu", (unsigned long)value], self);
    return value;
}

static id NeoWCHookNotificationLastUnreadMessage(id self, SEL _cmd) {
    id value = NeoWCOriginalNotificationLastUnreadMessage ? NeoWCOriginalNotificationLastUnreadMessage(self, _cmd) : nil;
    NeoWCRecordMomentEvent(@"WCNotificationCenterMgr getLastUnReadMessage RETURN", value);
    return value;
}

static id NeoWCHookNotificationLatestReadMessage(id self, SEL _cmd) {
    id value = NeoWCOriginalNotificationLatestReadMessage ? NeoWCOriginalNotificationLatestReadMessage(self, _cmd) : nil;
    NeoWCRecordMomentEvent(@"WCNotificationCenterMgr getLatestReadMessage RETURN", value);
    return value;
}

static id NeoWCHookCommentMessagesWithDataArray(id self, SEL _cmd, id dataArray) {
    NeoWCRecordMomentEvent(@"WCNewCommentListViewController getWCMessagesWithDataArray: ARG", dataArray);
    id value = NeoWCOriginalCommentMessagesWithDataArray ? NeoWCOriginalCommentMessagesWithDataArray(self, _cmd, dataArray) : nil;
    NeoWCRecordMomentEvent(@"WCNewCommentListViewController getWCMessagesWithDataArray: RETURN", value);
    return value;
}

static void NeoWCHookCommentRefreshFooter(id self, SEL _cmd, id footer) {
    NeoWCRecordMomentEvent(@"WCNewCommentListViewController MMRefreshTableFooterDidTriggerRefresh:", footer);
    if (NeoWCOriginalCommentRefreshFooter) NeoWCOriginalCommentRefreshFooter(self, _cmd, footer);
}

static void NeoWCHookCommentUpdateSections(id self, SEL _cmd) {
    NeoWCRecordMomentEvent(@"WCNewCommentListViewController updateArrSectionTitleType", self);
    if (NeoWCOriginalCommentUpdateSections) NeoWCOriginalCommentUpdateSections(self, _cmd);
}

static void NeoWCHookCommentUpdateTitle(id self, SEL _cmd) {
    NeoWCRecordMomentEvent(@"WCNewCommentListViewController updateCommentListTitle", self);
    if (NeoWCOriginalCommentUpdateTitle) NeoWCOriginalCommentUpdateTitle(self, _cmd);
}

static void NeoWCHookCommentClearLists(id self, SEL _cmd) {
    NeoWCRecordMomentEvent(@"WCNewCommentListViewController clearCommentLists", self);
    if (NeoWCOriginalCommentClearLists) NeoWCOriginalCommentClearLists(self, _cmd);
}

static void NeoWCHookCommentViewDidAppear(id self, SEL _cmd, BOOL animated) {
    NeoWCLastCommentListController = self;
    NeoWCRecordMomentEvent([NSString stringWithFormat:@"WCNewCommentListViewController viewDidAppear: animated=%@",
                            animated ? @"YES" : @"NO"], self);
    if (NeoWCOriginalCommentViewDidAppear) NeoWCOriginalCommentViewDidAppear(self, _cmd, animated);
}

@implementation NeoWCMomentsInteractionDiagnosticManager

+ (instancetype)sharedManager {
    static NeoWCMomentsInteractionDiagnosticManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [NeoWCMomentsInteractionDiagnosticManager new];
        manager.events = [NSMutableArray array];
        manager.installedHooks = [NSMutableSet set];
    });
    return manager;
}

- (void)recordEvent:(NSString *)event object:(id)object {
    if (!self.isRecording || event.length == 0) return;
    @synchronized (self) {
        self.sequence++;
        NSString *objectText = object ? [NSString stringWithFormat:@" | %@", NeoWCDiagnosticOneLine(object)] : @"";
        [self.events addObject:[NSString stringWithFormat:@"%05lu %@ [%@] %@%@",
                                (unsigned long)self.sequence, NeoWCDiagnosticTimestamp(),
                                NSThread.isMainThread ? @"main" : [NSString stringWithFormat:@"thread-%p", (__bridge void *)NSThread.currentThread],
                                event, objectText]];
        while (self.events.count > 3000) [self.events removeObjectAtIndex:0];
    }
}

- (void)installHookForClass:(NSString *)className selector:(NSString *)selectorName
                  signature:(NeoWCDiagnosticSignature)signature replacement:(IMP)replacement original:(IMP *)original {
    NSString *key = [NSString stringWithFormat:@"%@/%@", className, selectorName];
    NSString *result = nil;
    @synchronized (self) {
        if ([self.installedHooks containsObject:key]) return;
        Class cls = NSClassFromString(className);
        Method method = cls ? class_getInstanceMethod(cls, NSSelectorFromString(selectorName)) : NULL;
        if (!method) {
            result = [NSString stringWithFormat:@"HOOK SKIP %@：类或方法不存在", key];
        } else if (!NeoWCMethodMatchesSignature(method, signature)) {
            result = [NSString stringWithFormat:@"HOOK SKIP %@：签名不匹配 encoding=%s", key,
                      method_getTypeEncoding(method) ?: "?"];
        } else {
            MSHookMessageEx(cls, NSSelectorFromString(selectorName), replacement, original);
            [self.installedHooks addObject:key];
            result = [NSString stringWithFormat:@"HOOK INSTALLED %@ encoding=%s", key,
                      method_getTypeEncoding(method) ?: "?"];
        }
    }
    [self recordEvent:result object:nil];
}

- (void)installAvailableHooks {
    [self installHookForClass:@"WCTimeLineViewController" selector:@"checkNewMessage"
                        signature:NeoWCDiagnosticSignatureVoidNoArguments
                      replacement:(IMP)NeoWCHookTimelineCheckNewMessage original:(IMP *)&NeoWCOriginalTimelineCheckNewMessage];
        [self installHookForClass:@"WCTimeLineViewController" selector:@"viewDidAppear:"
                        signature:NeoWCDiagnosticSignatureVoidOneBool
                      replacement:(IMP)NeoWCHookTimelineViewDidAppear original:(IMP *)&NeoWCOriginalTimelineViewDidAppear];
        [self installHookForClass:@"WCNotificationCenterMgr" selector:@"getUnReadMessageCount"
                        signature:NeoWCDiagnosticSignatureIntegerNoArguments
                      replacement:(IMP)NeoWCHookNotificationUnreadCount original:(IMP *)&NeoWCOriginalNotificationUnreadCount];
        [self installHookForClass:@"WCNotificationCenterMgr" selector:@"getUnReadMessageCountReleatedToMe"
                        signature:NeoWCDiagnosticSignatureIntegerNoArguments
                      replacement:(IMP)NeoWCHookNotificationRelatedUnreadCount original:(IMP *)&NeoWCOriginalNotificationRelatedUnreadCount];
        [self installHookForClass:@"WCNotificationCenterMgr" selector:@"getLastUnReadMessage"
                        signature:NeoWCDiagnosticSignatureObjectNoArguments
                      replacement:(IMP)NeoWCHookNotificationLastUnreadMessage original:(IMP *)&NeoWCOriginalNotificationLastUnreadMessage];
        [self installHookForClass:@"WCNotificationCenterMgr" selector:@"getLatestReadMessage"
                        signature:NeoWCDiagnosticSignatureObjectNoArguments
                      replacement:(IMP)NeoWCHookNotificationLatestReadMessage original:(IMP *)&NeoWCOriginalNotificationLatestReadMessage];
        [self installHookForClass:@"WCNewCommentListViewController" selector:@"getWCMessagesWithDataArray:"
                        signature:NeoWCDiagnosticSignatureObjectOneObject
                      replacement:(IMP)NeoWCHookCommentMessagesWithDataArray original:(IMP *)&NeoWCOriginalCommentMessagesWithDataArray];
        [self installHookForClass:@"WCNewCommentListViewController" selector:@"MMRefreshTableFooterDidTriggerRefresh:"
                        signature:NeoWCDiagnosticSignatureVoidOneObject
                      replacement:(IMP)NeoWCHookCommentRefreshFooter original:(IMP *)&NeoWCOriginalCommentRefreshFooter];
        [self installHookForClass:@"WCNewCommentListViewController" selector:@"updateArrSectionTitleType"
                        signature:NeoWCDiagnosticSignatureVoidNoArguments
                      replacement:(IMP)NeoWCHookCommentUpdateSections original:(IMP *)&NeoWCOriginalCommentUpdateSections];
        [self installHookForClass:@"WCNewCommentListViewController" selector:@"updateCommentListTitle"
                        signature:NeoWCDiagnosticSignatureVoidNoArguments
                      replacement:(IMP)NeoWCHookCommentUpdateTitle original:(IMP *)&NeoWCOriginalCommentUpdateTitle];
        [self installHookForClass:@"WCNewCommentListViewController" selector:@"clearCommentLists"
                        signature:NeoWCDiagnosticSignatureVoidNoArguments
                      replacement:(IMP)NeoWCHookCommentClearLists original:(IMP *)&NeoWCOriginalCommentClearLists];
        [self installHookForClass:@"WCNewCommentListViewController" selector:@"viewDidAppear:"
                        signature:NeoWCDiagnosticSignatureVoidOneBool
                      replacement:(IMP)NeoWCHookCommentViewDidAppear original:(IMP *)&NeoWCOriginalCommentViewDidAppear];
}

- (void)startRecording {
    @synchronized (self) {
        [self.events removeAllObjects];
        self.sequence = 0;
        self.recording = YES;
    }
    [self recordEvent:@"朋友圈互动诊断开始" object:nil];
    [self installAvailableHooks];
}

- (void)stopRecording {
    [self recordEvent:@"朋友圈互动诊断停止" object:nil];
    self.recording = NO;
}

- (void)clearRecording {
    @synchronized (self) {
        self.recording = NO;
        [self.events removeAllObjects];
        self.sequence = 0;
        self.latestReportURL = nil;
    }
}

- (BOOL)triggerTimelineCheck {
    [self installAvailableHooks];
    id controller = NeoWCLastTimelineController;
    SEL selector = NSSelectorFromString(@"checkNewMessage");
    Method method = controller ? class_getInstanceMethod([controller class], selector) : NULL;
    if (!controller || !NeoWCMethodMatchesSignature(method, NeoWCDiagnosticSignatureVoidNoArguments)) return NO;
    ((void (*)(id, SEL))objc_msgSend)(controller, selector);
    return YES;
}

- (NSURL *)writeReportWithReason:(NSString *)reason error:(NSError **)error {
    [self installAvailableHooks];
    NSMutableString *report = [NSMutableString string];
    [report appendString:@"NeoWC 朋友圈互动运行时诊断\n"];
    [report appendFormat:@"生成时间：%@\n原因：%@\n记录状态：%@\n应用：%@ %@\n系统：%@\n\n",
     NeoWCDiagnosticTimestamp(), reason ?: @"手动", self.isRecording ? @"记录中" : @"已停止",
     NSBundle.mainBundle.bundleIdentifier ?: @"-",
     [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"-",
     UIDevice.currentDevice.systemVersion ?: @"-"];
    NSArray<NSString *> *installed = nil;
    @synchronized (self) { installed = [self.installedHooks.allObjects sortedArrayUsingSelector:@selector(compare:)]; }
    [report appendFormat:@"已安装追踪 Hook：\n%@\n", installed.count > 0 ? [installed componentsJoinedByString:@"\n"] : @"<none>"];

    NSArray<NSString *> *classNames = @[@"WCNotificationCenterMgr", @"WCTimeLineViewController",
                                         @"WCCommentListViewController", @"WCNewCommentListViewController",
                                         @"FindFriendEntryViewController"];
    for (NSString *className in classNames) NeoWCAppendClassReport(report, className);

    id manager = NeoWCMomentsNotificationManager();
    NeoWCAppendObjectReport(report, @"WCNotificationCenterMgr service", manager);
    [report appendString:@"\n\nKNOWN GETTERS\n"];
    id lastUnread = nil;
    id latestRead = nil;
    for (NSString *selectorName in @[@"getUnReadMessageCount", @"getUnReadMessageCountReleatedToMe",
                                      @"getLastUnReadMessage", @"getLatestReadMessage"]) {
        id object = nil;
        NSString *value = NeoWCInvokeNoArgumentSelector(manager, selectorName, &object);
        [report appendFormat:@"%@ => %@\n", selectorName, value];
        if ([selectorName isEqualToString:@"getLastUnReadMessage"]) lastUnread = object;
        if ([selectorName isEqualToString:@"getLatestReadMessage"]) latestRead = object;
    }
    NeoWCAppendObjectReport(report, @"getLastUnReadMessage", lastUnread);
    if (latestRead != lastUnread) NeoWCAppendObjectReport(report, @"getLatestReadMessage", latestRead);

    id timeline = NeoWCLastTimelineController;
    NeoWCAppendObjectReport(report, @"last WCTimeLineViewController", timeline);
    NeoWCAppendObjectReport(report, @"last WCNewCommentListViewController", NeoWCLastCommentListController);

    [report appendString:@"\n\nTRACE EVENTS\n"];
    NSArray<NSString *> *eventSnapshot = nil;
    @synchronized (self) { eventSnapshot = [self.events copy]; }
    if (eventSnapshot.count == 0) [report appendString:@"<empty>\n"];
    else [report appendFormat:@"%@\n", [eventSnapshot componentsJoinedByString:@"\n"]];

    NSString *applicationSupport = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
    NSURL *directory = [[[NSURL fileURLWithPath:applicationSupport isDirectory:YES]
                         URLByAppendingPathComponent:@"NeoWC" isDirectory:YES]
                        URLByAppendingPathComponent:@"Diagnostics" isDirectory:YES];
    if (![NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:error]) return nil;
    NSString *fileName = [NSString stringWithFormat:@"moments-interaction-%@.txt",
                          [[NeoWCDiagnosticTimestamp() stringByReplacingOccurrencesOfString:@":" withString:@"-"]
                           stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    NSURL *URL = [directory URLByAppendingPathComponent:fileName];
    if (![report writeToURL:URL atomically:YES encoding:NSUTF8StringEncoding error:error]) return nil;
    self.latestReportURL = URL;
    return URL;
}

@end

@implementation NeoWCMomentsInteractionDiagnosticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"朋友圈互动诊断";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"导出"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(exportReport)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return 5;
    return 3;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"状态" : (section == 1 ? @"操作" : @"采集步骤");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MomentsDiagnosticCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MomentsDiagnosticCell"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = indexPath.section == 2 ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;
    NeoWCMomentsInteractionDiagnosticManager *manager = [NeoWCMomentsInteractionDiagnosticManager sharedManager];
    if (indexPath.section == 0) {
        cell.textLabel.text = manager.isRecording ? @"正在记录" : @"未记录";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"已记录 %lu 个事件", (unsigned long)manager.events.count];
        cell.imageView.image = [UIImage systemImageNamed:manager.isRecording ? @"record.circle.fill" : @"record.circle"];
    } else if (indexPath.section == 1) {
        NSArray *titles = @[@"开始记录", @"停止并保存", @"触发朋友圈原生检查", @"保存当前快照", @"清空记录"];
        NSArray *details = @[@"安装签名校验后的只读 Hook，并清空上次记录",
                             @"停止新增事件并写入微信沙盒",
                             @"需要先进入一次朋友圈主界面",
                             @"导出类、方法、服务对象和当前互动对象",
                             @"只清理本工具本次内存记录，不删除朋友圈数据"];
        NSArray *symbols = @[@"record.circle", @"stop.circle", @"arrow.clockwise", @"doc.badge.plus", @"trash"];
        cell.textLabel.text = titles[indexPath.row];
        cell.detailTextLabel.text = details[indexPath.row];
        cell.imageView.image = [UIImage systemImageNamed:symbols[indexPath.row]];
    } else {
        NSArray *steps = @[@"1. 点击“开始记录”，然后关闭调试中心。",
                           @"2. 停留在朋友圈主界面，让另一个账号点赞或评论；再打开新消息页并下拉刷新。",
                           @"3. 回到这里点击“停止并保存”，再点右上角“导出”发送诊断文件。"];
        cell.textLabel.text = steps[indexPath.row];
        cell.detailTextLabel.text = nil;
        cell.imageView.image = nil;
    }
    return cell;
}

- (void)showMessage:(NSString *)title detail:(NSString *)detail {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:detail preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 1) return;
    NeoWCMomentsInteractionDiagnosticManager *manager = [NeoWCMomentsInteractionDiagnosticManager sharedManager];
    if (indexPath.row == 0) {
        [manager startRecording];
        [self showMessage:@"已经开始记录" detail:@"现在关闭调试中心，进入朋友圈主界面等待一次点赞或评论，然后打开新消息页并下拉刷新。"];
    } else if (indexPath.row == 1) {
        [manager stopRecording];
        NSError *error = nil;
        NSURL *URL = [manager writeReportWithReason:@"停止记录" error:&error];
        [self showMessage:URL ? @"诊断报告已保存" : @"保存失败"
                    detail:URL.path ?: error.localizedDescription ?: @"无法写入诊断报告"];
    } else if (indexPath.row == 2) {
        BOOL triggered = [manager triggerTimelineCheck];
        [self showMessage:triggered ? @"已触发原生检查" : @"尚未找到朋友圈主界面"
                    detail:triggered ? @"请等待刷新完成后再保存快照。" : @"请先关闭调试中心并进入一次朋友圈主界面，再回来重试。"];
    } else if (indexPath.row == 3) {
        NSError *error = nil;
        NSURL *URL = [manager writeReportWithReason:@"手动快照" error:&error];
        [self showMessage:URL ? @"快照已保存" : @"保存失败"
                    detail:URL.path ?: error.localizedDescription ?: @"无法写入诊断报告"];
    } else {
        [manager clearRecording];
    }
    [self.tableView reloadData];
}

- (void)exportReport {
    NeoWCMomentsInteractionDiagnosticManager *manager = [NeoWCMomentsInteractionDiagnosticManager sharedManager];
    NSError *error = nil;
    NSURL *URL = [manager writeReportWithReason:@"导出" error:&error];
    if (!URL) {
        [self showMessage:@"导出失败" detail:error.localizedDescription ?: @"无法生成诊断报告"];
        return;
    }
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:nil];
    activity.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:activity animated:YES completion:nil];
}

@end
