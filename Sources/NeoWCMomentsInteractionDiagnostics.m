#import "NeoWCMomentsInteractionDiagnostics.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import "NeoWCMomentsReminder.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <stdint.h>
#import <stdlib.h>
#import <string.h>

extern void MSHookMessageEx(Class cls, SEL selector, IMP replacement, IMP *original);

static void (*NeoWCOriginalTimelineCheckNewMessage)(id, SEL);
static void (*NeoWCOriginalTimelineViewDidAppear)(id, SEL, BOOL);
static unsigned int (*NeoWCOriginalNotificationUnreadCount)(id, SEL);
static unsigned int (*NeoWCOriginalNotificationRelatedUnreadCount)(id, SEL);
static id (*NeoWCOriginalNotificationLastUnreadMessage)(id, SEL);
static id (*NeoWCOriginalNotificationLatestReadMessage)(id, SEL);
static id (*NeoWCOriginalNotificationUnreadMessages)(id, SEL);
static BOOL (*NeoWCOriginalNotificationAddRawMessage)(id, SEL, id, BOOL);
static id (*NeoWCOriginalCommentMessagesWithDataArray)(id, SEL, id);
static void (*NeoWCOriginalCommentRefreshFooter)(id, SEL, id);
static void (*NeoWCOriginalCommentUpdateSections)(id, SEL);
static void (*NeoWCOriginalCommentUpdateTitle)(id, SEL);
static void (*NeoWCOriginalCommentClearLists)(id, SEL);
static __weak id NeoWCLastTimelineController;
static void (*NeoWCOriginalCommentViewDidAppear)(id, SEL, BOOL);
static __weak id NeoWCLastCommentListController;
static void (*NeoWCOriginalMomentsListInitData)(id, SEL, unsigned int);
static void (*NeoWCOriginalMomentsListHomepageUpdate)(id, SEL, id, unsigned int, id, id, id, id, id);
static __weak id NeoWCLastMomentsListController;

typedef NS_ENUM(NSUInteger, NeoWCDiagnosticSignature) {
    NeoWCDiagnosticSignatureVoidNoArguments,
    NeoWCDiagnosticSignatureIntegerNoArguments,
    NeoWCDiagnosticSignatureObjectNoArguments,
    NeoWCDiagnosticSignatureObjectOneObject,
    NeoWCDiagnosticSignatureVoidOneObject,
    NeoWCDiagnosticSignatureVoidOneBool,
    NeoWCDiagnosticSignatureBoolObjectBool,
    NeoWCDiagnosticSignatureVoidOneUnsignedInteger,
    NeoWCDiagnosticSignatureVoidHomepageUpdate,
};

@interface NeoWCMomentsInteractionDiagnosticManager : NSObject
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, assign) NSUInteger sequence;
@property (nonatomic, strong) NSMutableArray<NSString *> *events;
@property (nonatomic, strong) NSMutableSet<NSString *> *installedHooks;
@property (nonatomic, strong, nullable) id capturedNotificationManager;
@property (nonatomic, strong) NSMutableArray *capturedMessages;
@property (nonatomic, strong, nullable) NSURL *latestReportURL;
+ (instancetype)sharedManager;
- (void)startRecording;
- (void)stopRecording;
- (void)clearRecording;
- (void)recordEvent:(NSString *)event object:(nullable id)object;
- (void)captureNotificationManager:(nullable id)manager message:(nullable id)message;
- (NSUInteger)eventCount;
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
    unsigned int expectedArguments = 2;
    if (signature == NeoWCDiagnosticSignatureBoolObjectBool) expectedArguments = 4;
    else if (signature == NeoWCDiagnosticSignatureVoidHomepageUpdate) expectedArguments = 9;
    else if (signature == NeoWCDiagnosticSignatureObjectOneObject ||
             signature == NeoWCDiagnosticSignatureVoidOneObject ||
             signature == NeoWCDiagnosticSignatureVoidOneBool ||
             signature == NeoWCDiagnosticSignatureVoidOneUnsignedInteger) expectedArguments = 3;
    if (method_getNumberOfArguments(method) != expectedArguments) return NO;

    char *returnType = method_copyReturnType(method);
    const char *normalizedReturn = NeoWCSkipTypeQualifiers(returnType);
    BOOL validReturn = NO;
    switch (signature) {
        case NeoWCDiagnosticSignatureVoidNoArguments:
        case NeoWCDiagnosticSignatureVoidOneObject:
        case NeoWCDiagnosticSignatureVoidOneBool:
        case NeoWCDiagnosticSignatureVoidOneUnsignedInteger:
        case NeoWCDiagnosticSignatureVoidHomepageUpdate:
            validReturn = normalizedReturn[0] == 'v';
            break;
        case NeoWCDiagnosticSignatureIntegerNoArguments:
            validReturn = NeoWCTypeIsInteger(normalizedReturn);
            break;
        case NeoWCDiagnosticSignatureObjectNoArguments:
        case NeoWCDiagnosticSignatureObjectOneObject:
            validReturn = normalizedReturn[0] == '@';
            break;
        case NeoWCDiagnosticSignatureBoolObjectBool:
            validReturn = normalizedReturn[0] == 'B' || normalizedReturn[0] == 'c';
            break;
    }
    free(returnType);
    if (!validReturn || expectedArguments == 2) return validReturn;

    char *argumentType = method_copyArgumentType(method, 2);
    const char argumentCode = NeoWCSkipTypeQualifiers(argumentType)[0];
    BOOL validArgument = NO;
    if (signature == NeoWCDiagnosticSignatureVoidOneBool) {
        validArgument = argumentCode == 'B' || argumentCode == 'c';
    } else if (signature == NeoWCDiagnosticSignatureVoidOneUnsignedInteger) {
        validArgument = argumentCode == 'I';
    } else {
        validArgument = argumentCode == '@';
    }
    free(argumentType);
    if (validArgument && signature == NeoWCDiagnosticSignatureBoolObjectBool) {
        argumentType = method_copyArgumentType(method, 3);
        const char boolCode = NeoWCSkipTypeQualifiers(argumentType)[0];
        validArgument = boolCode == 'B' || boolCode == 'c';
        free(argumentType);
    }
    if (validArgument && signature == NeoWCDiagnosticSignatureVoidHomepageUpdate) {
        argumentType = method_copyArgumentType(method, 3);
        validArgument = NeoWCSkipTypeQualifiers(argumentType)[0] == 'I';
        free(argumentType);
        for (unsigned int index = 4; validArgument && index < 9; index++) {
            argumentType = method_copyArgumentType(method, index);
            validArgument = NeoWCSkipTypeQualifiers(argumentType)[0] == '@';
            free(argumentType);
        }
    }
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

static NSString *NeoWCDiagnosticApplicationState(void) {
    __block UIApplicationState state = UIApplicationStateInactive;
    if (NSThread.isMainThread) {
        state = UIApplication.sharedApplication.applicationState;
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            state = UIApplication.sharedApplication.applicationState;
        });
    }
    switch (state) {
        case UIApplicationStateActive: return @"active";
        case UIApplicationStateInactive: return @"inactive";
        case UIApplicationStateBackground: return @"background";
    }
    return @"unknown";
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

static void NeoWCAppendCapturedObjectSummaries(NSMutableString *report, NSString *title, NSArray *objects) {
    [report appendFormat:@"\n%@ (%lu)\n", title, (unsigned long)objects.count];
    NSUInteger limit = MIN((NSUInteger)24, objects.count);
    for (NSUInteger index = 0; index < limit; index++) {
        [report appendFormat:@"%02lu %@\n", (unsigned long)index, NeoWCDiagnosticOneLine(objects[index])];
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

static void NeoWCRecordMomentEvent(NSString *event, id object) {
    [[NeoWCMomentsInteractionDiagnosticManager sharedManager] recordEvent:event object:object];
}

static void NeoWCCaptureNotificationObjects(id manager, id message) {
    [[NeoWCMomentsInteractionDiagnosticManager sharedManager] captureNotificationManager:manager message:message];
}

static id NeoWCDiagnosticMessageObjectGetter(id message, const char *selectorName) {
    if (!message || !selectorName) return nil;
    SEL selector = sel_registerName(selectorName);
    Method method = class_getInstanceMethod([message class], selector);
    if (!method || method_getNumberOfArguments(method) != 2) return nil;
    char *returnType = method_copyReturnType(method);
    BOOL matches = NeoWCSkipTypeQualifiers(returnType)[0] == '@';
    free(returnType);
    if (!matches) return nil;
    @try { return ((id (*)(id, SEL))objc_msgSend)(message, selector); }
    @catch (__unused NSException *exception) { return nil; }
}

static BOOL NeoWCDiagnosticMessageType(id message, long long *result) {
    if (result) *result = 0;
    SEL selector = sel_registerName("msgTypeFromClientId");
    Method method = message ? class_getInstanceMethod([message class], selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != 2) return NO;
    char *returnType = method_copyReturnType(method);
    BOOL matches = NeoWCSkipTypeQualifiers(returnType)[0] == 'q';
    free(returnType);
    if (!matches) return NO;
    @try {
        long long value = ((long long (*)(id, SEL))objc_msgSend)(message, selector);
        if (result) *result = value;
        return YES;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

static BOOL NeoWCDiagnosticSignedIntegerGetter(id object, const char *selectorName,
                                               char expectedReturnType, long long *result) {
    if (result) *result = 0;
    if (!object || !selectorName) return NO;
    SEL selector = sel_registerName(selectorName);
    Method method = class_getInstanceMethod([object class], selector);
    if (!method || method_getNumberOfArguments(method) != 2) return NO;
    char *returnType = method_copyReturnType(method);
    BOOL matches = NeoWCSkipTypeQualifiers(returnType)[0] == expectedReturnType;
    free(returnType);
    if (!matches) return NO;
    @try {
        long long value = expectedReturnType == 'q'
            ? ((long long (*)(id, SEL))objc_msgSend)(object, selector)
            : (long long)((int (*)(id, SEL))objc_msgSend)(object, selector);
        if (result) *result = value;
        return YES;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

static void NeoWCRecordDiagnosticUserCommentSnapshot(NSString *source, NSString *role, id userComment) {
    if (!userComment) return;
    id username = NeoWCDiagnosticMessageObjectGetter(userComment, "username");
    id nickname = NeoWCDiagnosticMessageObjectGetter(userComment, "nickname");
    id content = NeoWCDiagnosticMessageObjectGetter(userComment, "content");
    id referenceUsername = NeoWCDiagnosticMessageObjectGetter(userComment, "refUserName");
    id dataItemUsername = NeoWCDiagnosticMessageObjectGetter(userComment, "dataItemUsrName");
    id dataItemNickname = NeoWCDiagnosticMessageObjectGetter(userComment, "dataItemNickName");
    long long type = 0;
    long long sourceValue = 0;
    long long commentType = 0;
    BOOL hasType = NeoWCDiagnosticSignedIntegerGetter(userComment, "type", 'i', &type);
    BOOL hasSource = NeoWCDiagnosticSignedIntegerGetter(userComment, "source", 'i', &sourceValue);
    BOOL hasCommentType = NeoWCDiagnosticSignedIntegerGetter(userComment, "commentType", 'q', &commentType);
    NSString *event = [NSString stringWithFormat:
        @"WCUserComment SNAPSHOT source=%@ role=%@ username=%@ nickname=%@ content=%@ refUserName=%@ dataItemUsrName=%@ dataItemNickName=%@ type=%@ sourceValue=%@ commentType=%@",
        source ?: @"unknown", role ?: @"unknown", NeoWCDiagnosticOneLine(username),
        NeoWCDiagnosticOneLine(nickname), NeoWCDiagnosticOneLine(content),
        NeoWCDiagnosticOneLine(referenceUsername), NeoWCDiagnosticOneLine(dataItemUsername),
        NeoWCDiagnosticOneLine(dataItemNickname), hasType ? [NSString stringWithFormat:@"%lld", type] : @"UNAVAILABLE",
        hasSource ? [NSString stringWithFormat:@"%lld", sourceValue] : @"UNAVAILABLE",
        hasCommentType ? [NSString stringWithFormat:@"%lld", commentType] : @"UNAVAILABLE"];
    NeoWCRecordMomentEvent(event, userComment);
}

static void NeoWCRecordDiagnosticMessageSnapshot(NSString *source, id message) {
    if (!message) return;
    long long messageType = 0;
    BOOL hasMessageType = NeoWCDiagnosticMessageType(message, &messageType);
    id comment = NeoWCDiagnosticMessageObjectGetter(message, "comment");
    id referenceComment = NeoWCDiagnosticMessageObjectGetter(message, "refComment");
    id messageID = NeoWCDiagnosticMessageObjectGetter(message, "msgID");
    id objectID = NeoWCDiagnosticMessageObjectGetter(message, "objID");
    id parentObjectID = NeoWCDiagnosticMessageObjectGetter(message, "parentObjID");
    id clientID = NeoWCDiagnosticMessageObjectGetter(message, "clientId");
    NSString *event = [NSString stringWithFormat:
        @"WCSNSMessage SNAPSHOT source=%@ type=%@ comment=%@ refComment=%@ msgID=%@ objID=%@ parentObjID=%@ clientId=%@",
        source ?: @"unknown", hasMessageType ? [NSString stringWithFormat:@"%lld", messageType] : @"UNAVAILABLE",
        NeoWCDiagnosticOneLine(comment), NeoWCDiagnosticOneLine(referenceComment),
        NeoWCDiagnosticOneLine(messageID), NeoWCDiagnosticOneLine(objectID),
        NeoWCDiagnosticOneLine(parentObjectID), NeoWCDiagnosticOneLine(clientID)];
    NeoWCRecordMomentEvent(event, message);
    if ([source isEqualToString:@"getLastUnReadMessage"]) {
        NeoWCRecordDiagnosticUserCommentSnapshot(source, @"comment", comment);
        NeoWCRecordDiagnosticUserCommentSnapshot(source, @"refComment", referenceComment);
    }
}

static id NeoWCDiagnosticSafeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try { return [object valueForKey:key]; }
    @catch (__unused NSException *exception) { return nil; }
}

static NSString *NeoWCDiagnosticCollectionCount(id value) {
    return [value respondsToSelector:@selector(count)]
        ? [NSString stringWithFormat:@"%lu", (unsigned long)[value count]]
        : @"UNAVAILABLE";
}

static void NeoWCRecordMomentsListSnapshot(NSString *source, id controller) {
    if (!controller) return;
    id items = NeoWCDiagnosticSafeValue(controller, @"m_arrPhotoDatas");
    id contact = NeoWCDiagnosticSafeValue(controller, @"m_contact");
    id username = NeoWCDiagnosticSafeValue(contact, @"m_nsUsrName");
    if (!username) username = NeoWCDiagnosticSafeValue(contact, @"userName");
    id firstItem = [items isKindOfClass:NSArray.class] && [items count] > 0 ? [items firstObject] : nil;
    id firstTID = NeoWCDiagnosticSafeValue(firstItem, @"tid");
    NSString *event = [NSString stringWithFormat:
        @"WCListViewController SNAPSHOT source=%@ username=%@ m_arrPhotoDatas=%@ firstTid=%@",
        source ?: @"unknown", NeoWCDiagnosticOneLine(username),
        NeoWCDiagnosticCollectionCount(items), NeoWCDiagnosticOneLine(firstTID)];
    NeoWCRecordMomentEvent(event, controller);
}

static void NeoWCHookMomentsListInitData(id self, SEL _cmd, unsigned int type) {
    NeoWCLastMomentsListController = self;
    NeoWCRecordMomentsListSnapshot([NSString stringWithFormat:@"initData:%u BEFORE", type], self);
    if (NeoWCOriginalMomentsListInitData) NeoWCOriginalMomentsListInitData(self, _cmd, type);
    NeoWCRecordMomentsListSnapshot([NSString stringWithFormat:@"initData:%u AFTER", type], self);
    __weak id weakController = self;
    NSArray<NSNumber *> *delays = @[@0.25, @1.0, @3.0];
    for (NSNumber *delay in delays) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            id controller = weakController;
            if (controller) {
                NeoWCRecordMomentsListSnapshot(
                    [NSString stringWithFormat:@"initData:%u DELAY %.2fs", type, delay.doubleValue],
                    controller);
            }
        });
    }
}

static void NeoWCHookMomentsListHomepageUpdate(id self, SEL _cmd, id homepage, unsigned int type,
                                                id result, id addedData, id changedData,
                                                id deletedData, id tips) {
    NeoWCLastMomentsListController = self;
    NeoWCRecordMomentEvent([NSString stringWithFormat:
        @"WCListViewController onHomepage CALLBACK BEFORE type=%u homepage=%@ result=%@ added=%@ changed=%@ deleted=%@ tips=%@",
        type, NeoWCDiagnosticOneLine(homepage), NeoWCDiagnosticOneLine(result),
        NeoWCDiagnosticCollectionCount(addedData), NeoWCDiagnosticCollectionCount(changedData),
        NeoWCDiagnosticCollectionCount(deletedData), NeoWCDiagnosticOneLine(tips)], self);
    NeoWCRecordMomentsListSnapshot(@"onHomepage BEFORE ORIGINAL", self);
    if (NeoWCOriginalMomentsListHomepageUpdate) {
        NeoWCOriginalMomentsListHomepageUpdate(self, _cmd, homepage, type, result,
                                               addedData, changedData, deletedData, tips);
    }
    NeoWCRecordMomentsListSnapshot(@"onHomepage AFTER ORIGINAL", self);
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

static unsigned int NeoWCHookNotificationUnreadCount(id self, SEL _cmd) {
    unsigned int value = NeoWCOriginalNotificationUnreadCount ? NeoWCOriginalNotificationUnreadCount(self, _cmd) : 0;
    NeoWCCaptureNotificationObjects(self, nil);
    NeoWCRecordMomentEvent([NSString stringWithFormat:@"WCNotificationCenterMgr getUnReadMessageCount => %u", value], self);
    return value;
}

static unsigned int NeoWCHookNotificationRelatedUnreadCount(id self, SEL _cmd) {
    unsigned int value = NeoWCOriginalNotificationRelatedUnreadCount ? NeoWCOriginalNotificationRelatedUnreadCount(self, _cmd) : 0;
    NeoWCCaptureNotificationObjects(self, nil);
    NeoWCRecordMomentEvent([NSString stringWithFormat:@"WCNotificationCenterMgr getUnReadMessageCountReleatedToMe => %u", value], self);
    return value;
}

static id NeoWCHookNotificationLastUnreadMessage(id self, SEL _cmd) {
    id value = NeoWCOriginalNotificationLastUnreadMessage ? NeoWCOriginalNotificationLastUnreadMessage(self, _cmd) : nil;
    NeoWCCaptureNotificationObjects(self, value);
    NeoWCRecordDiagnosticMessageSnapshot(@"getLastUnReadMessage", value);
    NeoWCRecordMomentEvent(@"WCNotificationCenterMgr getLastUnReadMessage RETURN", value);
    return value;
}

static id NeoWCHookNotificationLatestReadMessage(id self, SEL _cmd) {
    id value = NeoWCOriginalNotificationLatestReadMessage ? NeoWCOriginalNotificationLatestReadMessage(self, _cmd) : nil;
    NeoWCCaptureNotificationObjects(self, value);
    NeoWCRecordDiagnosticMessageSnapshot(@"getLatestReadMessage", value);
    NeoWCRecordMomentEvent(@"WCNotificationCenterMgr getLatestReadMessage RETURN", value);
    return value;
}

static id NeoWCHookNotificationUnreadMessages(id self, SEL _cmd) {
    id value = NeoWCOriginalNotificationUnreadMessages ? NeoWCOriginalNotificationUnreadMessages(self, _cmd) : nil;
    NeoWCCaptureNotificationObjects(self, nil);
    if ([value conformsToProtocol:@protocol(NSFastEnumeration)]) {
        for (id message in value) NeoWCCaptureNotificationObjects(self, message);
    }
    NeoWCRecordMomentEvent(@"WCNotificationCenterMgr getUnReadMessages RETURN", value);
    return value;
}

static BOOL NeoWCHookNotificationAddRawMessage(id self, SEL _cmd, id message, BOOL hasRead) {
    NeoWCCaptureNotificationObjects(self, message);
    NeoWCRecordMomentEvent([NSString stringWithFormat:@"WCNotificationCenterMgr addNewRawMessage:hasRead: BEFORE hasRead=%@",
                            hasRead ? @"YES" : @"NO"], message);
    BOOL result = NeoWCOriginalNotificationAddRawMessage
        ? NeoWCOriginalNotificationAddRawMessage(self, _cmd, message, hasRead) : NO;
    NeoWCRecordMomentEvent([NSString stringWithFormat:@"WCNotificationCenterMgr addNewRawMessage:hasRead: RETURN %@",
                            result ? @"YES" : @"NO"], message);
    return result;
}

static id NeoWCHookCommentMessagesWithDataArray(id self, SEL _cmd, id argument) {
    NeoWCRecordMomentEvent(@"WCNewCommentListViewController getWCMessagesWithDataArray: ARGUMENT", argument);
    id value = NeoWCOriginalCommentMessagesWithDataArray ? NeoWCOriginalCommentMessagesWithDataArray(self, _cmd, argument) : nil;
    NeoWCCaptureNotificationObjects(nil, value);
    NeoWCRecordDiagnosticMessageSnapshot(@"commentList", value);
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
        manager.capturedMessages = [NSMutableArray array];
    });
    return manager;
}

- (void)captureNotificationManager:(id)manager message:(id)message {
    if (!self.isRecording) return;
    @synchronized (self) {
        if (manager) self.capturedNotificationManager = manager;
        if (!message) return;
        for (id existing in self.capturedMessages) {
            if (existing == message) return;
        }
        [self.capturedMessages addObject:message];
        while (self.capturedMessages.count > 24) [self.capturedMessages removeObjectAtIndex:0];
    }
}

- (NSUInteger)eventCount {
    @synchronized (self) { return self.events.count; }
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
        [self installHookForClass:@"WCNotificationCenterMgr" selector:@"getUnReadMessages"
                        signature:NeoWCDiagnosticSignatureObjectNoArguments
                      replacement:(IMP)NeoWCHookNotificationUnreadMessages original:(IMP *)&NeoWCOriginalNotificationUnreadMessages];
        [self installHookForClass:@"WCNotificationCenterMgr" selector:@"addNewRawMessage:hasRead:"
                        signature:NeoWCDiagnosticSignatureBoolObjectBool
                      replacement:(IMP)NeoWCHookNotificationAddRawMessage original:(IMP *)&NeoWCOriginalNotificationAddRawMessage];
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
        [self installHookForClass:@"WCListViewController" selector:@"initData:"
                        signature:NeoWCDiagnosticSignatureVoidOneUnsignedInteger
                      replacement:(IMP)NeoWCHookMomentsListInitData original:(IMP *)&NeoWCOriginalMomentsListInitData];
        [self installHookForClass:@"WCListViewController"
                         selector:@"onHomepage:type:updateWithResult:withAddedData:changedData:deletedData:tips:"
                        signature:NeoWCDiagnosticSignatureVoidHomepageUpdate
                      replacement:(IMP)NeoWCHookMomentsListHomepageUpdate
                         original:(IMP *)&NeoWCOriginalMomentsListHomepageUpdate];
}

- (void)startRecording {
    @synchronized (self) {
        [self.events removeAllObjects];
        [self.capturedMessages removeAllObjects];
        self.capturedNotificationManager = nil;
        self.sequence = 0;
        self.recording = YES;
    }
    [self recordEvent:[NSString stringWithFormat:@"朋友圈提醒诊断开始 applicationState=%@",
                       NeoWCDiagnosticApplicationState()] object:nil];
    [self installAvailableHooks];
}

- (void)stopRecording {
    [self recordEvent:@"朋友圈提醒诊断停止" object:nil];
    self.recording = NO;
}

- (void)clearRecording {
    @synchronized (self) {
        self.recording = NO;
        [self.events removeAllObjects];
        [self.capturedMessages removeAllObjects];
        self.capturedNotificationManager = nil;
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
    NSMutableString *report = [NSMutableString string];
    [report appendString:@"NeoWC 朋友圈提醒运行时诊断\n"];
    [report appendFormat:@"生成时间：%@\n原因：%@\n记录状态：%@\n应用：%@ %@\n系统：%@\n\n",
     NeoWCDiagnosticTimestamp(), reason ?: @"手动", self.isRecording ? @"记录中" : @"已停止",
     NSBundle.mainBundle.bundleIdentifier ?: @"-",
     [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"-",
     UIDevice.currentDevice.systemVersion ?: @"-"];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [report appendFormat:@"APPLICATION STATE\nstate=%@\nbackgroundKeepAlive=%@\nmomentsReminder=%@\ninteractionReminder=%@\ninterval=%.0f\nselectedUsers=%lu\n\n",
                         NeoWCDiagnosticApplicationState(),
                         [defaults boolForKey:NeoWCBackgroundKeepAliveEnabledKey] ? @"YES" : @"NO",
                         [defaults boolForKey:NeoWCMomentsReminderEnabledKey] ? @"YES" : @"NO",
                         [defaults boolForKey:NeoWCMomentsInteractionReminderEnabledKey] ? @"YES" : @"NO",
                         [defaults doubleForKey:NeoWCMomentsReminderIntervalKey],
                         (unsigned long)NeoWCMomentsReminderUsers().count];
    NSArray<NSString *> *installed = nil;
    @synchronized (self) { installed = [self.installedHooks.allObjects sortedArrayUsingSelector:@selector(compare:)]; }
    [report appendFormat:@"已安装追踪 Hook：\n%@\n", installed.count > 0 ? [installed componentsJoinedByString:@"\n"] : @"<none>"];

    NSArray<NSString *> *classNames = @[@"WCNotificationCenterMgr", @"WCSNSMessage", @"WCUserComment", @"WCTimeLineViewController",
                                         @"WCCommentListViewController", @"WCNewCommentListViewController",
                                         @"FindFriendEntryViewController", @"WCListViewController", @"WCDataItem"];
    for (NSString *className in classNames) NeoWCAppendClassReport(report, className);

    id capturedManager = nil;
    NSArray *capturedMessages = nil;
    @synchronized (self) {
        capturedManager = self.capturedNotificationManager;
        capturedMessages = [self.capturedMessages copy];
    }
    [report appendFormat:@"\n\nCAPTURED OBJECTS\nWCNotificationCenterMgr: %@\n",
                         NeoWCDiagnosticOneLine(capturedManager)];
    [report appendString:@"\n\nGETTER SNAPSHOT\n保存阶段不会主动调用微信私有 getter；返回值与调用顺序请查看 TRACE EVENTS。\n"];
    NeoWCAppendCapturedObjectSummaries(report, @"messages captured from Hook", capturedMessages);

    id timeline = NeoWCLastTimelineController;
    [report appendFormat:@"last WCTimeLineViewController: %@\n", NeoWCDiagnosticOneLine(timeline)];
    [report appendFormat:@"last WCNewCommentListViewController: %@\n", NeoWCDiagnosticOneLine(NeoWCLastCommentListController)];
    [report appendFormat:@"last WCListViewController: %@\n", NeoWCDiagnosticOneLine(NeoWCLastMomentsListController)];

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

@interface NeoWCMomentsInteractionDiagnosticsViewController ()
@property (nonatomic, assign) BOOL reportInProgress;
@end

static dispatch_queue_t NeoWCMomentsDiagnosticReportQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.qiu7c.neowc.moments-diagnostic-report", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

@implementation NeoWCMomentsInteractionDiagnosticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"朋友圈提醒诊断";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"导出"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(exportReport)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return 5;
    return 4;
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
        cell.textLabel.text = self.reportInProgress ? @"正在生成报告" : (manager.isRecording ? @"正在记录" : @"未记录");
        cell.detailTextLabel.text = [NSString stringWithFormat:@"已记录 %lu 个事件", (unsigned long)[manager eventCount]];
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
        NSArray *steps = @[@"1. 彻底退出并重新打开微信，不要进入朋友圈；点击“开始记录”。",
                           @"2. 让另一账号点赞、评论，并让一位特别关注好友发布新朋友圈；等待至少一个检测周期。",
                           @"3. 仍不打开朋友圈，回到此页点击“保存当前快照”，保留冷启动阶段报告。",
                           @"4. 再进入朋友圈等待刷新，回来点击“停止并保存”，最后导出报告。"];
        cell.textLabel.text = steps[indexPath.row];
        cell.detailTextLabel.text = nil;
        cell.imageView.image = nil;
    }
    return cell;
}

- (void)showMessage:(NSString *)title detail:(NSString *)detail {
    if (!self.view.window || self.presentedViewController) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:detail preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)setReportBusy:(BOOL)busy {
    self.reportInProgress = busy;
    self.tableView.userInteractionEnabled = !busy;
    self.navigationItem.rightBarButtonItem.enabled = !busy;
    [self.tableView reloadData];
}

- (void)generateReportWithReason:(NSString *)reason stopRecording:(BOOL)stopRecording export:(BOOL)export {
    if (self.reportInProgress) return;
    NeoWCMomentsInteractionDiagnosticManager *manager = [NeoWCMomentsInteractionDiagnosticManager sharedManager];
    [manager installAvailableHooks];
    if (stopRecording) [manager stopRecording];
    [self setReportBusy:YES];
    __weak typeof(self) weakSelf = self;
    dispatch_async(NeoWCMomentsDiagnosticReportQueue(), ^{
        @autoreleasepool {
            NSError *error = nil;
            NSURL *URL = [manager writeReportWithReason:reason error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(self) strongSelf = weakSelf;
                if (!strongSelf) return;
                [strongSelf setReportBusy:NO];
                if (!strongSelf.view.window) return;
                if (!URL) {
                    [strongSelf showMessage:export ? @"导出失败" : @"保存失败"
                                      detail:error.localizedDescription ?: @"无法生成诊断报告"];
                    return;
                }
                if (!export) {
                    [strongSelf showMessage:@"诊断报告已保存" detail:URL.path];
                    return;
                }
                UIActivityViewController *activity = [[UIActivityViewController alloc]
                    initWithActivityItems:@[URL] applicationActivities:nil];
                activity.popoverPresentationController.barButtonItem = strongSelf.navigationItem.rightBarButtonItem;
                [strongSelf presentViewController:activity animated:YES completion:nil];
            });
        }
    });
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 1 || self.reportInProgress) return;
    NeoWCMomentsInteractionDiagnosticManager *manager = [NeoWCMomentsInteractionDiagnosticManager sharedManager];
    if (indexPath.row == 0) {
        [manager startRecording];
        [self showMessage:@"已经开始记录" detail:@"冷启动阶段先不要进入朋友圈。让另一账号点赞、评论，并让特别关注好友发布新动态。"];
    } else if (indexPath.row == 1) {
        [self generateReportWithReason:@"停止记录" stopRecording:YES export:NO];
    } else if (indexPath.row == 2) {
        BOOL triggered = [manager triggerTimelineCheck];
        [self showMessage:triggered ? @"已触发原生检查" : @"尚未找到朋友圈主界面"
                    detail:triggered ? @"请等待刷新完成后再保存快照。" : @"请先关闭调试中心并进入一次朋友圈主界面，再回来重试。"];
    } else if (indexPath.row == 3) {
        [self generateReportWithReason:@"手动快照" stopRecording:NO export:NO];
    } else {
        [manager clearRecording];
    }
    [self.tableView reloadData];
}

- (void)exportReport {
    [self generateReportWithReason:@"导出" stopRecording:NO export:YES];
}

@end
