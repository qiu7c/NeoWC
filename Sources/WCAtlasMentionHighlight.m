#import "WCAtlasMentionHighlight.h"
#import "WCAtlasEnhancements.h"
#import "WCAtlasLogging.h"
#import "WCAtlasPrivateAPI.h"
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <string.h>

extern void MSHookMessageEx(Class _class, SEL message, IMP hook, IMP *old);

NSString *const WCAtlasMentionHighlightEnabledKey = @"com.qiu7c.wcatlas.chat.mention-highlight";

static NSString *const WCAtlasMentionURLPrefix = @"https://wcatlas.invalid/profile/";
static BOOL (*WCAtlasOriginalSetMentionStylesInteger)(id, SEL, id, id);
static id (*WCAtlasOriginalSetMentionStylesObject)(id, SEL, id, id);
static void (*WCAtlasOriginalSetMentionStylesVoid)(id, SEL, id, id);
static void (*WCAtlasOriginalClickMentionLinkEvent)(id, SEL, id);
static void (*WCAtlasOriginalClickMentionTextEvent)(id, SEL, id);
static void (*WCAtlasOriginalMentionCellOnLinkClicked)(id, SEL, id, CGRect);
static void (*WCAtlasOriginalSetMentionViewModel)(id, SEL, id);
static void (*WCAtlasOriginalLayoutMentionCell)(id, SEL);
static void (*WCAtlasOriginalLayoutMentionCellSubviews)(id, SEL);
static id (*WCAtlasOriginalGetMentionRichTextViewForDelegate)(id, SEL);
static id (*WCAtlasOriginalMentionLinkTextColor)(id, SEL);
static id (*WCAtlasOriginalMentionRichTextConfig)(id, SEL);
static id (*WCAtlasOriginalMentionContentTextStyles)(id, SEL);
static id (*WCAtlasOriginalMentionOriginContentTextStyles)(id, SEL);
static CGSize (*WCAtlasOriginalMentionSizeForContent)(id, SEL, id, id, BOOL, id __autoreleasing *);
static NSString *WCAtlasLastOpenedMentionUserName;
static NSTimeInterval WCAtlasLastOpenedMentionTime;

#pragma mark - Runtime Safety

static const char *WCAtlasMentionSkipTypeQualifiers(const char *type) {
    while (type && strchr("rnNoORV", *type)) type++;
    return type;
}

static BOOL WCAtlasMentionTypeIsObject(const char *type) {
    type = WCAtlasMentionSkipTypeQualifiers(type);
    return type && (*type == '@' || *type == '#');
}

static BOOL WCAtlasMentionTypeIsVoid(const char *type) {
    type = WCAtlasMentionSkipTypeQualifiers(type);
    return type && *type == 'v';
}

static BOOL WCAtlasMentionTypeIsInteger(const char *type) {
    type = WCAtlasMentionSkipTypeQualifiers(type);
    return type && *type && strchr("cCsSiIlLqQB", *type) != NULL;
}

static BOOL WCAtlasMentionMethodHasObjectArguments(Method method, unsigned int count) {
    if (!method || method_getNumberOfArguments(method) != count + 2) return NO;
    char returnType[32] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    if (!WCAtlasMentionTypeIsVoid(returnType)) return NO;
    for (unsigned int index = 0; index < count; index++) {
        char argumentType[32] = {0};
        method_getArgumentType(method, index + 2, argumentType, sizeof(argumentType));
        if (!WCAtlasMentionTypeIsObject(argumentType)) return NO;
    }
    return YES;
}

static BOOL WCAtlasMentionMethodReturnsObject(Method method, unsigned int argumentCount) {
    if (!method || method_getNumberOfArguments(method) != argumentCount + 2) return NO;
    char returnType[32] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    if (!WCAtlasMentionTypeIsObject(returnType)) return NO;
    for (unsigned int index = 0; index < argumentCount; index++) {
        char argumentType[32] = {0};
        method_getArgumentType(method, index + 2, argumentType, sizeof(argumentType));
        if (!WCAtlasMentionTypeIsObject(argumentType)) return NO;
    }
    return YES;
}

static BOOL WCAtlasMentionMethodHasObjectAndCGRectArguments(Method method) {
    if (!method || method_getNumberOfArguments(method) != 4) return NO;
    char returnType[32] = {0};
    char objectType[32] = {0};
    char rectType[128] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    method_getArgumentType(method, 2, objectType, sizeof(objectType));
    method_getArgumentType(method, 3, rectType, sizeof(rectType));
    return WCAtlasMentionTypeIsVoid(returnType) && WCAtlasMentionTypeIsObject(objectType) &&
           strcmp(WCAtlasMentionSkipTypeQualifiers(rectType), @encode(CGRect)) == 0;
}

static BOOL WCAtlasMentionMethodHasSizeOutputStylesABI(Method method) {
    if (!method || method_getNumberOfArguments(method) != 6) return NO;
    char returnType[128] = {0};
    char contentType[32] = {0};
    char delegateType[32] = {0};
    char spacingType[32] = {0};
    char outputType[32] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    method_getArgumentType(method, 2, contentType, sizeof(contentType));
    method_getArgumentType(method, 3, delegateType, sizeof(delegateType));
    method_getArgumentType(method, 4, spacingType, sizeof(spacingType));
    method_getArgumentType(method, 5, outputType, sizeof(outputType));
    const char *output = WCAtlasMentionSkipTypeQualifiers(outputType);
    return strcmp(WCAtlasMentionSkipTypeQualifiers(returnType), @encode(CGSize)) == 0 &&
           WCAtlasMentionTypeIsObject(contentType) && WCAtlasMentionTypeIsObject(delegateType) &&
           WCAtlasMentionTypeIsInteger(spacingType) && output && output[0] == '^';
}

static BOOL WCAtlasMentionIsAllUserName(NSString *userName) {
    NSString *lowercase = userName.lowercaseString;
    return [lowercase isEqualToString:@"notify@all"] || [lowercase isEqualToString:@"@all"] ||
           [lowercase isEqualToString:@"all"] || [lowercase isEqualToString:@"everyone"];
}

static NSArray<NSString *> *WCAtlasMentionDisplayCandidates(NSString *userName, id groupContact) {
    if (WCAtlasMentionIsAllUserName(userName)) return @[@"所有人", @"all", @"everyone"];
    id contact = WCAtlasPrivateContact(userName);
    NSMutableOrderedSet<NSString *> *names = [NSMutableOrderedSet orderedSet];
    NSString *roomName = WCAtlasPrivateGroupMemberDisplayName(groupContact, contact);
    if (roomName.length > 0) [names addObject:roomName];
    for (NSString *name in @[WCAtlasPrivateContactRemark(contact) ?: @"",
                             WCAtlasPrivateContactNickname(contact) ?: @"",
                             WCAtlasPrivateContactDisplayName(contact, nil) ?: @""]) {
        if (name.length > 0) [names addObject:name];
    }
    return names.array;
}

static NSRange WCAtlasMentionRange(NSString *content, NSArray<NSString *> *names,
                                   NSMutableIndexSet *claimedIndexes) {
    for (NSString *name in names) {
        for (NSString *token in @[[@"@" stringByAppendingString:name]]) {
            NSRange searchRange = NSMakeRange(0, content.length);
            while (searchRange.length > 0) {
                NSRange range = [content rangeOfString:token options:0 range:searchRange];
                if (range.location == NSNotFound) break;
                if (![claimedIndexes intersectsIndexesInRange:range]) {
                    [claimedIndexes addIndexesInRange:range];
                    return range;
                }
                NSUInteger next = NSMaxRange(range);
                if (next >= content.length) break;
                searchRange = NSMakeRange(next, content.length - next);
            }
        }
    }
    return NSMakeRange(NSNotFound, 0);
}

static NSArray<NSValue *> *WCAtlasMentionVisibleRanges(NSString *content) {
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
    NSCharacterSet *hardTerminators = [NSCharacterSet characterSetWithCharactersInString:
        @"\u2004\u2005\t\r\n,，。！？!?：:；;（）()[]【】<>"];
    NSUInteger cursor = 0;
    while (cursor < content.length) {
        NSRange at = [content rangeOfString:@"@" options:0 range:NSMakeRange(cursor, content.length - cursor)];
        if (at.location == NSNotFound) break;
        NSUInteger end = at.location + 1;
        while (end < content.length) {
            unichar character = [content characterAtIndex:end];
            if ([hardTerminators characterIsMember:character]) break;
            if (character == ' ' && end > at.location + 1) break;
            end++;
        }
        if (end > at.location + 1) [ranges addObject:[NSValue valueWithRange:NSMakeRange(at.location, end - at.location)]];
        cursor = MAX(end, at.location + 1);
    }
    return ranges;
}

#pragma mark - Link Styles

static NSString *WCAtlasMentionURLString(NSString *userName) {
    NSString *encoded = [userName stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
    return encoded.length > 0 ? [WCAtlasMentionURLPrefix stringByAppendingString:encoded] : nil;
}

static NSString *WCAtlasMentionStringFromEvent(id event) {
    return WCAtlasPrivateMentionLinkURLString(event);
}

static UIColor *WCAtlasMentionNormalColor(void) {
    return [UIColor colorWithRed:0.12 green:0.47 blue:0.95 alpha:1.0];
}

static UIColor *WCAtlasMentionHighlightedColor(void) {
    return [WCAtlasMentionNormalColor() colorWithAlphaComponent:0.55];
}

static id WCAtlasMentionLinkStyle(NSRange range, NSString *userName) {
    NSString *URLString = WCAtlasMentionURLString(userName);
    // Keep the view-model config hook, but also put colors on the style itself.
    // Some WeChat builds copy LinkStyle before applying the config and otherwise
    // leave newly injected mention ranges visually unchanged.
    return WCAtlasPrivateMentionLinkStyle(range, URLString,
        WCAtlasMentionNormalColor(), WCAtlasMentionHighlightedColor());
}

static BOOL WCAtlasMentionStylesContainURL(NSArray *styles) {
    for (id style in styles) {
        NSString *URLString = WCAtlasMentionStringFromEvent(style);
        if ([URLString hasPrefix:WCAtlasMentionURLPrefix]) return YES;
    }
    return NO;
}

static id WCAtlasMentionStylesForContent(id self, id styles, id contentObject) {
    NSArray *originalStyles = [styles isKindOfClass:NSArray.class] ? styles : @[];
    NSString *content = [contentObject isKindOfClass:NSString.class] ? contentObject : nil;
    if (!WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey) || content.length == 0 ||
        [content rangeOfString:@"@"].location == NSNotFound || WCAtlasMentionStylesContainURL(originalStyles)) {
        return styles;
    }
    NSArray<NSString *> *userNames = WCAtlasPrivateMentionUserNames(self);
    if (userNames.count == 0) return styles;
    NSString *chatUserName = WCAtlasPrivateMentionChatUserName(self);
    id groupContact = [chatUserName hasSuffix:@"@chatroom"] ? WCAtlasPrivateContact(chatUserName) : nil;
    NSMutableArray *merged = [originalStyles mutableCopy];
    NSMutableIndexSet *claimed = [NSMutableIndexSet indexSet];
    NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *ownersByDisplayName = [NSMutableDictionary dictionary];
    NSArray<NSValue *> *officialRanges = WCAtlasPrivateMentionRanges(self, content);
    NSUInteger officialRangeIndex = 0;
    NSArray<NSValue *> *visibleRanges = WCAtlasMentionVisibleRanges(content);
    NSUInteger fallbackRangeIndex = 0;
    for (NSString *userName in userNames) {
        for (NSString *name in WCAtlasMentionDisplayCandidates(userName, groupContact)) {
            NSMutableSet *owners = ownersByDisplayName[name];
            if (!owners) ownersByDisplayName[name] = owners = [NSMutableSet set];
            [owners addObject:userName];
        }
    }
    for (NSString *userName in userNames) {
        NSArray<NSString *> *candidates = WCAtlasMentionDisplayCandidates(userName, groupContact);
        if (!WCAtlasMentionIsAllUserName(userName)) {
            candidates = [candidates filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *name, __unused NSDictionary *bindings) {
                return ownersByDisplayName[name].count == 1;
            }]];
        }
        NSRange range = NSMakeRange(NSNotFound, 0);
        while (officialRangeIndex < officialRanges.count) {
            NSRange officialRange = officialRanges[officialRangeIndex++].rangeValue;
            if (![claimed intersectsIndexesInRange:officialRange]) {
                range = officialRange;
                [claimed addIndexesInRange:officialRange];
                break;
            }
        }
        if (range.location == NSNotFound) range = WCAtlasMentionRange(content, candidates, claimed);
        while (range.location == NSNotFound && fallbackRangeIndex < visibleRanges.count) {
            NSRange fallback = visibleRanges[fallbackRangeIndex++].rangeValue;
            if (![claimed intersectsIndexesInRange:fallback]) {
                range = fallback;
                [claimed addIndexesInRange:fallback];
            }
        }
        if (range.location == NSNotFound || NSMaxRange(range) > content.length) continue;
        id style = WCAtlasMentionLinkStyle(range,
            WCAtlasMentionIsAllUserName(userName) ? @"notify@all" : userName);
        if (style) [merged addObject:style];
    }
    if (merged.count > originalStyles.count) {
        WCAtlasPrivateEnableMentionClickHandling(self);
        return merged;
    }
    return styles;
}

static BOOL WCAtlasSetMentionStylesInteger(id self, SEL _cmd, id styles, id contentObject) {
    id merged = WCAtlasMentionStylesForContent(self, styles, contentObject);
    return WCAtlasOriginalSetMentionStylesInteger(self, _cmd, merged, contentObject);
}

static id WCAtlasSetMentionStylesObject(id self, SEL _cmd, id styles, id contentObject) {
    id merged = WCAtlasMentionStylesForContent(self, styles, contentObject);
    return WCAtlasOriginalSetMentionStylesObject(self, _cmd, merged, contentObject);
}

static void WCAtlasSetMentionStylesVoid(id self, SEL _cmd, id styles, id contentObject) {
    id merged = WCAtlasMentionStylesForContent(self, styles, contentObject);
    WCAtlasOriginalSetMentionStylesVoid(self, _cmd, merged, contentObject);
}

static BOOL WCAtlasHandleMentionClick(id richTextView, id event) {
    if (!WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey)) return NO;
    NSString *URLString = WCAtlasMentionStringFromEvent(event);
    if (![URLString hasPrefix:WCAtlasMentionURLPrefix]) return NO;
    NSString *encoded = [URLString substringFromIndex:WCAtlasMentionURLPrefix.length];
    NSString *userName = encoded.stringByRemovingPercentEncoding ?: encoded;
    if (userName.length == 0 || WCAtlasMentionIsAllUserName(userName)) return YES;
    NSTimeInterval now = NSDate.timeIntervalSinceReferenceDate;
    if ([WCAtlasLastOpenedMentionUserName isEqualToString:userName] &&
        now - WCAtlasLastOpenedMentionTime < 0.5) return YES;
    WCAtlasLastOpenedMentionUserName = [userName copy];
    WCAtlasLastOpenedMentionTime = now;
    __weak id weakRichTextView = richTextView;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *source = WCAtlasPrivateChatControllerForView(weakRichTextView);
        if (source && !WCAtlasPushPrivateContactProfile(source, userName)) {
            WCAtlasLog(@"@ 资料页适配失败：%@", userName);
        }
    });
    return YES;
}

static void WCAtlasClickMentionLinkEvent(id self, SEL _cmd, id event) {
    if (WCAtlasHandleMentionClick(self, event)) return;
    if (WCAtlasOriginalClickMentionLinkEvent) WCAtlasOriginalClickMentionLinkEvent(self, _cmd, event);
}

static void WCAtlasClickMentionTextEvent(id self, SEL _cmd, id event) {
    if (WCAtlasHandleMentionClick(self, event)) return;
    if (WCAtlasOriginalClickMentionTextEvent) WCAtlasOriginalClickMentionTextEvent(self, _cmd, event);
}

static void WCAtlasMentionCellOnLinkClicked(id self, SEL _cmd, id event, CGRect rect) {
    if (WCAtlasHandleMentionClick(self, event)) return;
    if (WCAtlasOriginalMentionCellOnLinkClicked) {
        WCAtlasOriginalMentionCellOnLinkClicked(self, _cmd, event, rect);
    }
}

static void WCAtlasSetMentionViewModel(id self, SEL _cmd, id viewModel) {
    BOOL enabled = WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey);
    if (enabled) WCAtlasPrivateBindMentionContext(self, viewModel, NO);
    WCAtlasOriginalSetMentionViewModel(self, _cmd, viewModel);
    WCAtlasPrivateBindMentionContext(self, viewModel, enabled);
}

static void WCAtlasLayoutMentionCell(id self, SEL _cmd) {
    WCAtlasOriginalLayoutMentionCell(self, _cmd);
    if (WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey)) {
        WCAtlasPrivateBindMentionContext(self, nil, YES);
    }
}

static void WCAtlasLayoutMentionCellSubviews(id self, SEL _cmd) {
    WCAtlasOriginalLayoutMentionCellSubviews(self, _cmd);
    if (WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey)) {
        WCAtlasPrivateBindMentionContext(self, nil, YES);
    }
}

static id WCAtlasGetMentionRichTextViewForDelegate(id self, SEL _cmd) {
    id richTextView = WCAtlasOriginalGetMentionRichTextViewForDelegate
        ? WCAtlasOriginalGetMentionRichTextViewForDelegate(self, _cmd) : nil;
    if (richTextView && WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey)) {
        WCAtlasPrivateBindMentionContext(self, nil, YES);
    }
    return richTextView;
}

static id WCAtlasMentionLinkTextColor(id self, SEL _cmd) {
    id originalColor = WCAtlasOriginalMentionLinkTextColor
        ? WCAtlasOriginalMentionLinkTextColor(self, _cmd) : nil;
    return WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey)
        ? WCAtlasMentionNormalColor() : originalColor;
}

static id WCAtlasMentionRichTextConfig(id self, SEL _cmd) {
    id config = WCAtlasOriginalMentionRichTextConfig
        ? WCAtlasOriginalMentionRichTextConfig(self, _cmd) : nil;
    if (WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey)) {
        WCAtlasPrivateConfigureMentionRichTextConfig(config,
            WCAtlasMentionNormalColor(), WCAtlasMentionHighlightedColor());
    }
    return config;
}

static id WCAtlasMentionContentObject(id viewModel) {
    for (NSString *selectorName in @[@"contentText", @"originContentText"]) {
        SEL selector = NSSelectorFromString(selectorName);
        Method method = class_getInstanceMethod(object_getClass(viewModel), selector);
        if (!WCAtlasMentionMethodReturnsObject(method, 0)) continue;
        @try {
            id value = ((id (*)(id, SEL))objc_msgSend)(viewModel, selector);
            if ([value isKindOfClass:NSString.class]) return value;
        } @catch (__unused NSException *exception) {}
    }
    return nil;
}

static id WCAtlasMentionContentTextStyles(id self, SEL _cmd) {
    id styles = WCAtlasOriginalMentionContentTextStyles
        ? WCAtlasOriginalMentionContentTextStyles(self, _cmd) : nil;
    return WCAtlasMentionStylesForContent(self, styles, WCAtlasMentionContentObject(self));
}

static id WCAtlasMentionOriginContentTextStyles(id self, SEL _cmd) {
    id styles = WCAtlasOriginalMentionOriginContentTextStyles
        ? WCAtlasOriginalMentionOriginContentTextStyles(self, _cmd) : nil;
    return WCAtlasMentionStylesForContent(self, styles, WCAtlasMentionContentObject(self));
}

static CGSize WCAtlasMentionSizeForContent(id self, SEL _cmd, id content,
                                           id layoutDelegate, BOOL autoLineSpacing,
                                           id __autoreleasing *outStyles) {
    CGSize size = WCAtlasOriginalMentionSizeForContent(
        self, _cmd, content, layoutDelegate, autoLineSpacing, outStyles);
    if (!WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey) || !outStyles) return size;
    id styles = *outStyles;
    id merged = WCAtlasMentionStylesForContent(self, styles, content);
    if (merged != styles) *outStyles = merged;
    return size;
}

#pragma mark - Hook Installation

void WCAtlasMentionHighlightInstallHooks(void) {
    static BOOL installed = NO;
    @synchronized (WCAtlasMentionHighlightEnabledKey) {
        if (installed) return;
        Class richTextClass = NSClassFromString(@"RichTextView");
        Class textCellClass = NSClassFromString(@"TextMessageCellView");
        Class textViewModelClass = NSClassFromString(@"TextMessageViewModel");
        if (!richTextClass || !textCellClass || !textViewModelClass) {
            WCAtlasLog(@"@ 高亮延迟安装：微信聊天类尚未加载");
            return;
        }
        SEL styleSelector = NSSelectorFromString(@"setArrStyles:withContent:");
        Method styleMethod = richTextClass ? class_getInstanceMethod(richTextClass, styleSelector) : NULL;
        if (!styleMethod || method_getNumberOfArguments(styleMethod) != 4) {
            WCAtlasLog(@"@ 高亮未安装：RichTextView 样式 ABI 不支持");
            return;
        }
        for (unsigned int index = 2; index < 4; index++) {
            char argumentType[32] = {0};
            method_getArgumentType(styleMethod, index, argumentType, sizeof(argumentType));
            if (!WCAtlasMentionTypeIsObject(argumentType)) {
                WCAtlasLog(@"@ 高亮未安装：RichTextView 样式参数 ABI 不支持");
                return;
            }
        }
        char styleReturnType[32] = {0};
        method_getReturnType(styleMethod, styleReturnType, sizeof(styleReturnType));
        IMP original = NULL;
        if (WCAtlasMentionTypeIsInteger(styleReturnType)) {
            MSHookMessageEx(richTextClass, styleSelector, (IMP)WCAtlasSetMentionStylesInteger, &original);
            WCAtlasOriginalSetMentionStylesInteger = (BOOL (*)(id, SEL, id, id))original;
        } else if (WCAtlasMentionTypeIsObject(styleReturnType)) {
            MSHookMessageEx(richTextClass, styleSelector, (IMP)WCAtlasSetMentionStylesObject, &original);
            WCAtlasOriginalSetMentionStylesObject = (id (*)(id, SEL, id, id))original;
        } else if (WCAtlasMentionTypeIsVoid(styleReturnType)) {
            MSHookMessageEx(richTextClass, styleSelector, (IMP)WCAtlasSetMentionStylesVoid, &original);
            WCAtlasOriginalSetMentionStylesVoid = (void (*)(id, SEL, id, id))original;
        } else {
            WCAtlasLog(@"@ 高亮未安装：RichTextView 样式返回 ABI 不支持");
            return;
        }

        SEL linkSelector = NSSelectorFromString(@"clickOnLinkEvent:");
        Method linkMethod = class_getInstanceMethod(richTextClass, linkSelector);
        SEL textSelector = NSSelectorFromString(@"clickOnTextEvent:");
        Method textMethod = class_getInstanceMethod(richTextClass, textSelector);
        BOOL installedClickHook = NO;
        if (WCAtlasMentionMethodHasObjectArguments(linkMethod, 1)) {
            original = NULL;
            MSHookMessageEx(richTextClass, linkSelector, (IMP)WCAtlasClickMentionLinkEvent, &original);
            WCAtlasOriginalClickMentionLinkEvent = (void (*)(id, SEL, id))original;
            installedClickHook = YES;
        }
        if (WCAtlasMentionMethodHasObjectArguments(textMethod, 1)) {
            original = NULL;
            MSHookMessageEx(richTextClass, textSelector, (IMP)WCAtlasClickMentionTextEvent, &original);
            WCAtlasOriginalClickMentionTextEvent = (void (*)(id, SEL, id))original;
            installedClickHook = YES;
        }
        if (!installedClickHook) {
            WCAtlasLog(@"@ 高亮只启用显示：点击事件 ABI 不支持");
        }

        SEL cellLinkSelector = NSSelectorFromString(@"onLinkClicked:withRect:");
        Method cellLinkMethod = textCellClass
            ? class_getInstanceMethod(textCellClass, cellLinkSelector) : NULL;
        if (WCAtlasMentionMethodHasObjectAndCGRectArguments(cellLinkMethod)) {
            original = NULL;
            MSHookMessageEx(textCellClass, cellLinkSelector,
                (IMP)WCAtlasMentionCellOnLinkClicked, &original);
            WCAtlasOriginalMentionCellOnLinkClicked =
                (void (*)(id, SEL, id, CGRect))original;
            installedClickHook = YES;
        } else {
            WCAtlasLog(@"@ 高亮 Cell 点击入口未安装：onLinkClicked:withRect: ABI 不支持");
        }
        SEL viewModelSelector = NSSelectorFromString(@"setViewModel:");
        Method viewModelMethod = textCellClass ? class_getInstanceMethod(textCellClass, viewModelSelector) : NULL;
        if (WCAtlasMentionMethodHasObjectArguments(viewModelMethod, 1)) {
            original = NULL;
            MSHookMessageEx(textCellClass, viewModelSelector, (IMP)WCAtlasSetMentionViewModel, &original);
            WCAtlasOriginalSetMentionViewModel = (void (*)(id, SEL, id))original;
        } else {
            WCAtlasLog(@"@ 高亮上下文未安装：TextMessageCellView setViewModel: ABI 不支持");
        }
        SEL layoutSelector = NSSelectorFromString(@"layoutContentView");
        Method layoutMethod = textCellClass ? class_getInstanceMethod(textCellClass, layoutSelector) : NULL;
        if (WCAtlasMentionMethodHasObjectArguments(layoutMethod, 0)) {
            original = NULL;
            MSHookMessageEx(textCellClass, layoutSelector, (IMP)WCAtlasLayoutMentionCell, &original);
            WCAtlasOriginalLayoutMentionCell = (void (*)(id, SEL))original;
        } else {
            WCAtlasLog(@"@ 高亮刷新未安装：TextMessageCellView layoutContentView ABI 不支持");
        }
        SEL layoutSubviewsSelector = @selector(layoutSubviews);
        Method layoutSubviewsMethod = textCellClass
            ? class_getInstanceMethod(textCellClass, layoutSubviewsSelector) : NULL;
        if (WCAtlasMentionMethodHasObjectArguments(layoutSubviewsMethod, 0)) {
            original = NULL;
            MSHookMessageEx(textCellClass, layoutSubviewsSelector,
                (IMP)WCAtlasLayoutMentionCellSubviews, &original);
            WCAtlasOriginalLayoutMentionCellSubviews = (void (*)(id, SEL))original;
        } else {
            WCAtlasLog(@"@ 高亮刷新未安装：TextMessageCellView layoutSubviews ABI 不支持");
        }
        SEL delegateViewSelector = NSSelectorFromString(@"getRichTextViewForDelegate");
        Method delegateViewMethod = textCellClass
            ? class_getInstanceMethod(textCellClass, delegateViewSelector) : NULL;
        if (WCAtlasMentionMethodReturnsObject(delegateViewMethod, 0)) {
            original = NULL;
            MSHookMessageEx(textCellClass, delegateViewSelector,
                (IMP)WCAtlasGetMentionRichTextViewForDelegate, &original);
            WCAtlasOriginalGetMentionRichTextViewForDelegate =
                (id (*)(id, SEL))original;
        } else {
            WCAtlasLog(@"@ 高亮富文本入口未安装：getRichTextViewForDelegate ABI 不支持");
        }

        SEL contentStylesSelector = NSSelectorFromString(@"contentTextStyles");
        Method contentStylesMethod = class_getInstanceMethod(textViewModelClass, contentStylesSelector);
        if (WCAtlasMentionMethodReturnsObject(contentStylesMethod, 0)) {
            original = NULL;
            MSHookMessageEx(textViewModelClass, contentStylesSelector,
                (IMP)WCAtlasMentionContentTextStyles, &original);
            WCAtlasOriginalMentionContentTextStyles = (id (*)(id, SEL))original;
        } else {
            WCAtlasLog(@"@ 高亮样式源未安装：TextMessageViewModel contentTextStyles ABI 不支持");
        }
        SEL originStylesSelector = NSSelectorFromString(@"originContentTextStyles");
        Method originStylesMethod = class_getInstanceMethod(textViewModelClass, originStylesSelector);
        if (WCAtlasMentionMethodReturnsObject(originStylesMethod, 0)) {
            original = NULL;
            MSHookMessageEx(textViewModelClass, originStylesSelector,
                (IMP)WCAtlasMentionOriginContentTextStyles, &original);
            WCAtlasOriginalMentionOriginContentTextStyles = (id (*)(id, SEL))original;
        }
        SEL sizeSelector = NSSelectorFromString(
            @"sizeForContent:layoutDelegate:autoLineSpacing:outArrStyles:");
        Method sizeMethod = class_getInstanceMethod(textViewModelClass, sizeSelector);
        if (WCAtlasMentionMethodHasSizeOutputStylesABI(sizeMethod)) {
            original = NULL;
            MSHookMessageEx(textViewModelClass, sizeSelector,
                (IMP)WCAtlasMentionSizeForContent, &original);
            WCAtlasOriginalMentionSizeForContent =
                (CGSize (*)(id, SEL, id, id, BOOL, id __autoreleasing *))original;
        } else {
            WCAtlasLog(@"@ 高亮样式生产入口未安装：sizeForContent ABI 不支持");
        }
        SEL linkColorSelector = NSSelectorFromString(@"linkTextColor");
        Method linkColorMethod = textViewModelClass
            ? class_getInstanceMethod(textViewModelClass, linkColorSelector) : NULL;
        if (WCAtlasMentionMethodReturnsObject(linkColorMethod, 0)) {
            original = NULL;
            MSHookMessageEx(textViewModelClass, linkColorSelector,
                (IMP)WCAtlasMentionLinkTextColor, &original);
            WCAtlasOriginalMentionLinkTextColor = (id (*)(id, SEL))original;
        } else {
            WCAtlasLog(@"@ 高亮颜色入口未安装：TextMessageViewModel linkTextColor ABI 不支持");
        }
        SEL richConfigSelector = NSSelectorFromString(@"getRichTextViewConfig");
        Method richConfigMethod = textViewModelClass
            ? class_getInstanceMethod(textViewModelClass, richConfigSelector) : NULL;
        if (WCAtlasMentionMethodReturnsObject(richConfigMethod, 0)) {
            original = NULL;
            MSHookMessageEx(textViewModelClass, richConfigSelector,
                (IMP)WCAtlasMentionRichTextConfig, &original);
            WCAtlasOriginalMentionRichTextConfig = (id (*)(id, SEL))original;
        } else {
            WCAtlasLog(@"@ 高亮配置入口未安装：getRichTextViewConfig ABI 不支持");
        }
        installed = YES;
        WCAtlasLog(@"@ 高亮 Hook 已安装");
    }
}
