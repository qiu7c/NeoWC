#import "NeoWCMomentsCommentAntiDelete.h"

#import "NeoWCLogging.h"
#import "NeoWCEnhancements.h"

#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <stdlib.h>
#import <string.h>

extern void MSHookMessageEx(Class cls, SEL selector, IMP replacement, IMP *original);

static char NeoWCMomentsDeletedCommentMarkerKey;

static void (*NeoWCOriginalMergeDeletedComment)(id, SEL, id, BOOL);
static void (*NeoWCOriginalMergeCommentList)(id, SEL, id);
static void (*NeoWCOriginalMergeMessage)(id, SEL, id, BOOL);
static void (*NeoWCOriginalTimelineCellUpdate)(id, SEL, id, id);
static void (*NeoWCOriginalDetailSetDataItem)(id, SEL, id);
static void (*NeoWCOriginalDetailUpdateFinished)(id, SEL, NSInteger, id, id);
static void (*NeoWCOriginalCommentListConfig)(id, SEL, id, id, CGFloat);
static id (*NeoWCOriginalListDisplayContent)(id, SEL, id, id, id);
static id (*NeoWCOriginalFBDisplayComment)(id, SEL, id, id, id);
static id (*NeoWCOriginalFBTotalDisplayComment)(id, SEL, id, id, id);
static id (*NeoWCOriginalDisplayComment)(id, SEL, id, id, id);

static BOOL NeoWCMomentsCommentAntiDeleteEnabled(void) {
    return NeoWCEnhancementEnabled(NeoWCMomentsCommentAntiDeleteEnabledKey);
}

static NSMutableDictionary *NeoWCMomentsDeletedCommentCache(void) {
    static NSMutableDictionary *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ cache = [NSMutableDictionary dictionary]; });
    return cache;
}

static BOOL NeoWCMethodReturns(Method method, char expected) {
    char *type = method ? method_copyReturnType(method) : NULL;
    BOOL matches = type && type[0] == expected;
    if (type) free(type);
    return matches;
}

static BOOL NeoWCMethodArgumentIs(Method method, unsigned int index, const char *accepted) {
    char *type = method ? method_copyArgumentType(method, index) : NULL;
    BOOL matches = type && accepted && strchr(accepted, type[0]) != NULL;
    if (type) free(type);
    return matches;
}

static id NeoWCObjectGetter(id object, const char *name) {
    if (!object || !name) return nil;
    SEL selector = sel_registerName(name);
    Method method = class_getInstanceMethod(object_getClass(object), selector);
    if (!method || method_getNumberOfArguments(method) != 2 || !NeoWCMethodReturns(method, '@')) return nil;
    @try { return ((id (*)(id, SEL))objc_msgSend)(object, selector); }
    @catch (__unused NSException *exception) { return nil; }
}

static id NeoWCObjectOrIntegerGetter(id object, const char *name) {
    if (!object || !name) return nil;
    SEL selector = sel_registerName(name);
    Method method = class_getInstanceMethod(object_getClass(object), selector);
    if (!method || method_getNumberOfArguments(method) != 2) return nil;
    char *type = method_copyReturnType(method);
    char code = type ? type[0] : '\0';
    if (type) free(type);
    @try {
        switch (code) {
            case '@': return ((id (*)(id, SEL))objc_msgSend)(object, selector);
            case 'c': return @(((signed char (*)(id, SEL))objc_msgSend)(object, selector));
            case 'B': return @(((BOOL (*)(id, SEL))objc_msgSend)(object, selector));
            case 's': return @(((short (*)(id, SEL))objc_msgSend)(object, selector));
            case 'i': return @(((int (*)(id, SEL))objc_msgSend)(object, selector));
            case 'l': return @(((long (*)(id, SEL))objc_msgSend)(object, selector));
            case 'q': return @(((long long (*)(id, SEL))objc_msgSend)(object, selector));
            case 'C': return @(((unsigned char (*)(id, SEL))objc_msgSend)(object, selector));
            case 'S': return @(((unsigned short (*)(id, SEL))objc_msgSend)(object, selector));
            case 'I': return @(((unsigned int (*)(id, SEL))objc_msgSend)(object, selector));
            case 'L': return @(((unsigned long (*)(id, SEL))objc_msgSend)(object, selector));
            case 'Q': return @(((unsigned long long (*)(id, SEL))objc_msgSend)(object, selector));
            default: return nil;
        }
    } @catch (__unused NSException *exception) { return nil; }
}

static long long NeoWCIntegerGetter(id object, const char *name, BOOL *available) {
    if (available) *available = NO;
    if (!object || !name) return 0;
    SEL selector = sel_registerName(name);
    Method method = class_getInstanceMethod(object_getClass(object), selector);
    if (!method || method_getNumberOfArguments(method) != 2) return 0;
    char *type = method_copyReturnType(method);
    char code = type ? type[0] : '\0';
    if (type) free(type);
    @try {
        switch (code) {
            case '@': {
                id value = ((id (*)(id, SEL))objc_msgSend)(object, selector);
                if (![value respondsToSelector:@selector(longLongValue)]) return 0;
                if (available) *available = YES;
                return [value longLongValue];
            }
            case 'c': if (available) *available = YES; return ((signed char (*)(id, SEL))objc_msgSend)(object, selector);
            case 'B': if (available) *available = YES; return ((BOOL (*)(id, SEL))objc_msgSend)(object, selector);
            case 's': if (available) *available = YES; return ((short (*)(id, SEL))objc_msgSend)(object, selector);
            case 'i': if (available) *available = YES; return ((int (*)(id, SEL))objc_msgSend)(object, selector);
            case 'l': if (available) *available = YES; return ((long (*)(id, SEL))objc_msgSend)(object, selector);
            case 'C': if (available) *available = YES; return ((unsigned char (*)(id, SEL))objc_msgSend)(object, selector);
            case 'S': if (available) *available = YES; return ((unsigned short (*)(id, SEL))objc_msgSend)(object, selector);
            case 'I': if (available) *available = YES; return ((unsigned int (*)(id, SEL))objc_msgSend)(object, selector);
            case 'L': if (available) *available = YES; return (long long)((unsigned long (*)(id, SEL))objc_msgSend)(object, selector);
            case 'q': if (available) *available = YES; return ((long long (*)(id, SEL))objc_msgSend)(object, selector);
            case 'Q': if (available) *available = YES; return (long long)((unsigned long long (*)(id, SEL))objc_msgSend)(object, selector);
            default: return 0;
        }
    } @catch (__unused NSException *exception) { return 0; }
}

static void NeoWCSetInteger(id object, const char *name, long long value) {
    if (!object || !name) return;
    SEL selector = sel_registerName(name);
    Method method = class_getInstanceMethod(object_getClass(object), selector);
    if (!method || method_getNumberOfArguments(method) != 3 || !NeoWCMethodReturns(method, 'v')) return;
    char *type = method_copyArgumentType(method, 2);
    char code = type ? type[0] : '\0';
    if (type) free(type);
    @try {
        switch (code) {
            case '@': ((void (*)(id, SEL, id))objc_msgSend)(object, selector, @(value)); break;
            case 'c': ((void (*)(id, SEL, signed char))objc_msgSend)(object, selector, (signed char)value); break;
            case 'B': ((void (*)(id, SEL, BOOL))objc_msgSend)(object, selector, value != 0); break;
            case 's': ((void (*)(id, SEL, short))objc_msgSend)(object, selector, (short)value); break;
            case 'i': ((void (*)(id, SEL, int))objc_msgSend)(object, selector, (int)value); break;
            case 'l': ((void (*)(id, SEL, long))objc_msgSend)(object, selector, (long)value); break;
            case 'C': ((void (*)(id, SEL, unsigned char))objc_msgSend)(object, selector, (unsigned char)(value > 0 ? value : 0)); break;
            case 'S': ((void (*)(id, SEL, unsigned short))objc_msgSend)(object, selector, (unsigned short)(value > 0 ? value : 0)); break;
            case 'I': ((void (*)(id, SEL, unsigned int))objc_msgSend)(object, selector, (unsigned int)(value > 0 ? value : 0)); break;
            case 'L': ((void (*)(id, SEL, unsigned long))objc_msgSend)(object, selector, (unsigned long)(value > 0 ? value : 0)); break;
            case 'q': ((void (*)(id, SEL, long long))objc_msgSend)(object, selector, value); break;
            case 'Q': ((void (*)(id, SEL, unsigned long long))objc_msgSend)(object, selector, (unsigned long long)(value > 0 ? value : 0)); break;
            default: break;
        }
    } @catch (__unused NSException *exception) {}
}

static NSArray *NeoWCCommentUsers(id dataItem) {
    id comments = NeoWCObjectGetter(dataItem, "commentUsers");
    return [comments isKindOfClass:NSArray.class] ? comments : nil;
}

static id<NSCopying> NeoWCDataItemKey(id dataItem) {
    id tid = NeoWCObjectOrIntegerGetter(dataItem, "tid");
    if ([tid conformsToProtocol:@protocol(NSCopying)]) return tid;
    NSString *description = [tid description];
    return description.length > 0 ? description : nil;
}

static NSSet *NeoWCCommentIdentityKeys(id comment) {
    NSMutableSet *keys = [NSMutableSet set];
    const char *selectors[] = { "comment64ID", "commentID", "cpKeyForComment", "springClientId" };
    for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(selectors[0]); index++) {
        id value = NeoWCObjectOrIntegerGetter(comment, selectors[index]);
        if (!value || value == NSNull.null) continue;
        if ([value isKindOfClass:NSString.class] && [(NSString *)value length] == 0) continue;
        [keys addObject:value];
    }
    return keys;
}

static BOOL NeoWCCommentsMatch(id first, id second, id dataItem) {
    if (!first || !second) return NO;
    if (first == second) return YES;
    NSSet *firstKeys = NeoWCCommentIdentityKeys(first);
    NSSet *secondKeys = NeoWCCommentIdentityKeys(second);
    if (firstKeys.count > 0 && secondKeys.count > 0 && [firstKeys intersectsSet:secondKeys]) return YES;

    Class utilityClass = objc_getClass("WCCommentUIUtil");
    SEL selector = sel_registerName("isSameComment:andComment:isAd:");
    Method method = utilityClass ? class_getClassMethod(utilityClass, selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != 5 ||
        (!NeoWCMethodReturns(method, 'B') && !NeoWCMethodReturns(method, 'c')) || !NeoWCMethodArgumentIs(method, 2, "@") ||
        !NeoWCMethodArgumentIs(method, 3, "@") || !NeoWCMethodArgumentIs(method, 4, "Bc")) return NO;
    BOOL isAd = NeoWCIntegerGetter(dataItem, "isAd", NULL) != 0;
    @try { return ((BOOL (*)(id, SEL, id, id, BOOL))objc_msgSend)(utilityClass, selector, first, second, isAd); }
    @catch (__unused NSException *exception) { return NO; }
}

static BOOL NeoWCCommentListContains(NSArray *comments, id candidate, id dataItem, id __autoreleasing *matched) {
    for (id comment in comments) {
        if (NeoWCCommentsMatch(comment, candidate, dataItem)) {
            if (matched) *matched = comment;
            return YES;
        }
    }
    return NO;
}

static void NeoWCMarkDeletedComment(id comment) {
    if (comment) objc_setAssociatedObject(comment, &NeoWCMomentsDeletedCommentMarkerKey, @YES,
                                          OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void NeoWCCacheDeletedComment(id dataItem, id comment, NSUInteger index) {
    id<NSCopying> itemKey = NeoWCDataItemKey(dataItem);
    if (!itemKey || !comment) return;
    NSDictionary *entry = @{ @"comment": comment,
                             @"index": @(index),
                             @"keys": NeoWCCommentIdentityKeys(comment) };
    NSMutableDictionary *cache = NeoWCMomentsDeletedCommentCache();
    @synchronized (cache) {
        NSMutableArray *entries = cache[itemKey];
        if (!entries) {
            entries = [NSMutableArray array];
            cache[itemKey] = entries;
        }
        for (NSDictionary *existing in entries) {
            if (NeoWCCommentsMatch(existing[@"comment"], comment, dataItem)) return;
        }
        [entries addObject:entry];
    }
}

static void NeoWCRestoreDeletedComments(id dataItem) {
    if (!NeoWCMomentsCommentAntiDeleteEnabled() || !dataItem) return;
    id<NSCopying> itemKey = NeoWCDataItemKey(dataItem);
    NSMutableArray *comments = (NSMutableArray *)NeoWCCommentUsers(dataItem);
    if (!itemKey || ![comments respondsToSelector:@selector(insertObject:atIndex:)]) return;

    NSMutableDictionary *cache = NeoWCMomentsDeletedCommentCache();
    @synchronized (cache) {
        NSArray *entries = [cache[itemKey] copy];
        if (entries.count == 0) return;
        BOOL countAvailable = NO;
        long long originalCount = NeoWCIntegerGetter(dataItem, "commentCount", &countAvailable);
        for (NSDictionary *entry in entries) {
            id cachedComment = entry[@"comment"];
            id matched = nil;
            if (NeoWCCommentListContains(comments, cachedComment, dataItem, &matched)) {
                NeoWCMarkDeletedComment(matched);
                continue;
            }
            NSUInteger index = MIN([entry[@"index"] unsignedIntegerValue], comments.count);
            NeoWCMarkDeletedComment(cachedComment);
            @try { [comments insertObject:cachedComment atIndex:index]; }
            @catch (__unused NSException *exception) {}
        }
        if (countAvailable && (long long)comments.count > originalCount) {
            NeoWCSetInteger(dataItem, "setCommentCount:", (long long)comments.count);
            NeoWCSetInteger(dataItem, "setRealCommentCount:", (long long)comments.count);
        }
    }
}

static id NeoWCDeletedCommentDisplayContent(id original, id comment) {
    if (!NeoWCMomentsCommentAntiDeleteEnabled() || !original ||
        ![objc_getAssociatedObject(comment, &NeoWCMomentsDeletedCommentMarkerKey) boolValue]) return original;
    NSString *suffix = [[NSUserDefaults.standardUserDefaults stringForKey:NeoWCMomentsCommentAntiDeleteTextKey]
        stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (suffix.length == 0) suffix = @"←该评论已删除";
    unichar first = [suffix characterAtIndex:0];
    if (![NSCharacterSet.whitespaceAndNewlineCharacterSet characterIsMember:first]) {
        suffix = [@" " stringByAppendingString:suffix];
    }

    NSString *plain = [original isKindOfClass:NSAttributedString.class]
        ? [(NSAttributedString *)original string]
        : ([original isKindOfClass:NSString.class] ? original : nil);
    if (!plain || [plain hasSuffix:suffix]) return original;
    if (![original isKindOfClass:NSAttributedString.class]) return [plain stringByAppendingString:suffix];

    NSMutableAttributedString *result = [(NSAttributedString *)original mutableCopy];
    NSRange suffixRange = NSMakeRange(result.length, suffix.length);
    [result appendAttributedString:[[NSAttributedString alloc] initWithString:suffix]];
    CGFloat size = [NSUserDefaults.standardUserDefaults doubleForKey:NeoWCMomentsCommentAntiDeleteFontSizeKey];
    size = MIN(24.0, MAX(6.0, size > 0.0 ? size : 12.0));
    UIFont *font = nil;
    if (suffixRange.location > 0) {
        font = [result attribute:NSFontAttributeName atIndex:suffixRange.location - 1 effectiveRange:NULL];
    }
    font = [font isKindOfClass:UIFont.class] ? [font fontWithSize:size] : [UIFont systemFontOfSize:size];
    UIColor *color = NeoWCColorForDefaultsKey(NeoWCMomentsCommentAntiDeleteColorKey,
                                               [UIColor colorWithWhite:0.56 alpha:1.0]);
    [result addAttributes:@{ NSFontAttributeName: font, NSForegroundColorAttributeName: color }
                    range:suffixRange];
    return result;
}

static void NeoWCMergeDeletedComment(id self, SEL _cmd, id comment, BOOL deletedByOwner) {
    if (!NeoWCMomentsCommentAntiDeleteEnabled()) {
        NeoWCOriginalMergeDeletedComment(self, _cmd, comment, deletedByOwner);
        return;
    }
    NSArray *oldComments = [NeoWCCommentUsers(self) copy] ?: @[];
    NeoWCOriginalMergeDeletedComment(self, _cmd, comment, deletedByOwner);
    NSArray *currentComments = NeoWCCommentUsers(self) ?: @[];
    [oldComments enumerateObjectsUsingBlock:^(id oldComment, NSUInteger index, __unused BOOL *stop) {
        if (!NeoWCCommentListContains(currentComments, oldComment, self, NULL)) {
            NeoWCCacheDeletedComment(self, oldComment, index);
        }
    }];
    NeoWCRestoreDeletedComments(self);
}

static void NeoWCMergeCommentList(id self, SEL _cmd, id localFeed) {
    NeoWCOriginalMergeCommentList(self, _cmd, localFeed);
    NeoWCRestoreDeletedComments(self);
}

static void NeoWCMergeMessage(id self, SEL _cmd, id message, BOOL parseContent) {
    NeoWCOriginalMergeMessage(self, _cmd, message, parseContent);
    NeoWCRestoreDeletedComments(self);
}

static void NeoWCTimelineCellUpdate(id self, SEL _cmd, id dataItem, id actionAreaVM) {
    NeoWCRestoreDeletedComments(dataItem);
    NeoWCOriginalTimelineCellUpdate(self, _cmd, dataItem, actionAreaVM);
}

static void NeoWCDetailSetDataItem(id self, SEL _cmd, id dataItem) {
    NeoWCRestoreDeletedComments(dataItem);
    NeoWCOriginalDetailSetDataItem(self, _cmd, dataItem);
}

static void NeoWCDetailUpdateFinished(id self, SEL _cmd, NSInteger result, id itemID, id dataItem) {
    NeoWCRestoreDeletedComments(dataItem);
    NeoWCOriginalDetailUpdateFinished(self, _cmd, result, itemID, dataItem);
}

static void NeoWCCommentListConfig(id self, SEL _cmd, id comment, id dataItem, CGFloat width) {
    if (NeoWCMomentsCommentAntiDeleteEnabled()) {
        BOOL available = NO;
        long long status = NeoWCIntegerGetter(comment, "delStatus", &available);
        NSString *content = NeoWCObjectGetter(comment, "content");
        if (available && status == 1 && [content isKindOfClass:NSString.class] && content.length > 0) {
            NSUInteger index = [NeoWCCommentUsers(dataItem) indexOfObjectIdenticalTo:comment];
            NeoWCCacheDeletedComment(dataItem, comment, index == NSNotFound ? NeoWCCommentUsers(dataItem).count : index);
            NeoWCMarkDeletedComment(comment);
            NeoWCSetInteger(comment, "setDelStatus:", 0);
        }
        NeoWCRestoreDeletedComments(dataItem);
    }
    NeoWCOriginalCommentListConfig(self, _cmd, comment, dataItem, width);
}

static id NeoWCListDisplayContent(id self, SEL _cmd, id comment, id dataItem, id pageContext) {
    return NeoWCDeletedCommentDisplayContent(
        NeoWCOriginalListDisplayContent(self, _cmd, comment, dataItem, pageContext), comment);
}

static id NeoWCFBDisplayComment(id self, SEL _cmd, id comment, id dataItem, id pageContext) {
    return NeoWCDeletedCommentDisplayContent(
        NeoWCOriginalFBDisplayComment(self, _cmd, comment, dataItem, pageContext), comment);
}

static id NeoWCFBTotalDisplayComment(id self, SEL _cmd, id comment, id dataItem, id pageContext) {
    return NeoWCDeletedCommentDisplayContent(
        NeoWCOriginalFBTotalDisplayComment(self, _cmd, comment, dataItem, pageContext), comment);
}

static id NeoWCDisplayComment(id self, SEL _cmd, id comment, id dataItem, id pageContext) {
    return NeoWCDeletedCommentDisplayContent(
        NeoWCOriginalDisplayComment(self, _cmd, comment, dataItem, pageContext), comment);
}

static BOOL NeoWCInstallInstanceHook(NSString *className, NSString *selectorName, NSUInteger argumentCount,
                                     char returnType, const char *argumentTypes, IMP replacement, IMP *original) {
    Class cls = NSClassFromString(className);
    SEL selector = NSSelectorFromString(selectorName);
    Method method = cls ? class_getInstanceMethod(cls, selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != argumentCount || !NeoWCMethodReturns(method, returnType)) return NO;
    for (unsigned int index = 2; index < argumentCount; index++) {
        if (!NeoWCMethodArgumentIs(method, index, (char[]){ argumentTypes[index - 2], '\0' })) return NO;
    }
    MSHookMessageEx(cls, selector, replacement, original);
    return *original != NULL;
}

static BOOL NeoWCInstallClassHook(NSString *className, NSString *selectorName, NSUInteger argumentCount,
                                  IMP replacement, IMP *original) {
    Class cls = NSClassFromString(className);
    SEL selector = NSSelectorFromString(selectorName);
    Method method = cls ? class_getClassMethod(cls, selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != argumentCount || !NeoWCMethodReturns(method, '@')) return NO;
    for (unsigned int index = 2; index < argumentCount; index++) {
        if (!NeoWCMethodArgumentIs(method, index, "@")) return NO;
    }
    MSHookMessageEx(object_getClass(cls), selector, replacement, original);
    return *original != NULL;
}

void NeoWCMomentsCommentAntiDeleteInstallHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUInteger installed = 0;
        installed += NeoWCInstallInstanceHook(@"WCDataItem", @"mergeWithDeletedComment:isDeletedByFeedOwner:", 4, 'v', "@B",
                                               (IMP)NeoWCMergeDeletedComment, (IMP *)&NeoWCOriginalMergeDeletedComment);
        installed += NeoWCInstallInstanceHook(@"WCDataItem", @"mergeCommentListWithLocalFeed:", 3, 'v', "@",
                                               (IMP)NeoWCMergeCommentList, (IMP *)&NeoWCOriginalMergeCommentList);
        installed += NeoWCInstallInstanceHook(@"WCDataItem", @"mergeMessage:needParseContent:", 4, 'v', "@B",
                                               (IMP)NeoWCMergeMessage, (IMP *)&NeoWCOriginalMergeMessage);
        installed += NeoWCInstallInstanceHook(@"WCTimeLineCellView", @"updateWithDataItem:actionAreaVM:", 4, 'v', "@@",
                                               (IMP)NeoWCTimelineCellUpdate, (IMP *)&NeoWCOriginalTimelineCellUpdate);
        installed += NeoWCInstallInstanceHook(@"WCCommentDetailViewControllerFB", @"setDataItem:", 3, 'v', "@",
                                               (IMP)NeoWCDetailSetDataItem, (IMP *)&NeoWCOriginalDetailSetDataItem);
        installed += NeoWCInstallInstanceHook(@"WCCommentDetailViewControllerFB", @"onUpdateDataItemDetailFinished:itemId:dataItem:", 5, 'v', "q@@",
                                               (IMP)NeoWCDetailUpdateFinished, (IMP *)&NeoWCOriginalDetailUpdateFinished);
        installed += NeoWCInstallInstanceHook(@"WCCommentListContentView", @"config:dataItem:width:", 5, 'v', "@@d",
                                               (IMP)NeoWCCommentListConfig, (IMP *)&NeoWCOriginalCommentListConfig);
        installed += NeoWCInstallClassHook(@"WCCommentListContentView", @"getDisplayContent:dataItem:pageContext:", 5,
                                            (IMP)NeoWCListDisplayContent, (IMP *)&NeoWCOriginalListDisplayContent);
        installed += NeoWCInstallClassHook(@"WCCommentViewFB", @"getDisplayCommentContent:dataItem:pageContext:", 5,
                                            (IMP)NeoWCFBDisplayComment, (IMP *)&NeoWCOriginalFBDisplayComment);
        installed += NeoWCInstallClassHook(@"WCCommentViewFB", @"totalDisplayContentWithComment:inDataItem:pageContext:", 5,
                                            (IMP)NeoWCFBTotalDisplayComment, (IMP *)&NeoWCOriginalFBTotalDisplayComment);
        installed += NeoWCInstallClassHook(@"WCCommentView", @"getDisplayCommentContent:dataItem:pageContext:", 5,
                                            (IMP)NeoWCDisplayComment, (IMP *)&NeoWCOriginalDisplayComment);
        NeoWCLog(@"朋友圈评论防删除 Hook：%lu/11", (unsigned long)installed);
    });
}
