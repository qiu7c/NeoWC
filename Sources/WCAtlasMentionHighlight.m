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

static NSString *const WCAtlasMentionURLScheme = @"wcatlas-mention";
static void (*WCAtlasOriginalSetMentionStyles)(id, SEL, id, id);
static void (*WCAtlasOriginalClickMentionLinkEvent)(id, SEL, id);
static void (*WCAtlasOriginalClickMentionTextEvent)(id, SEL, id);
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

#pragma mark - Link Styles

static NSString *WCAtlasMentionURLString(NSString *userName) {
    NSString *encoded = [userName stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
    return encoded.length > 0 ? [NSString stringWithFormat:@"%@://%@", WCAtlasMentionURLScheme, encoded] : nil;
}

static NSString *WCAtlasMentionStringFromEvent(id event) {
    return WCAtlasPrivateMentionLinkURLString(event);
}

static id WCAtlasMentionLinkStyle(NSRange range, NSString *userName) {
    NSString *URLString = WCAtlasMentionURLString(userName);
    UIColor *normalColor = [UIColor colorWithRed:0.12 green:0.47 blue:0.95 alpha:1.0];
    UIColor *highlightedColor = [normalColor colorWithAlphaComponent:0.55];
    return WCAtlasPrivateMentionLinkStyle(range, URLString, normalColor, highlightedColor);
}

static BOOL WCAtlasMentionStylesContainURL(NSArray *styles) {
    for (id style in styles) {
        NSString *URLString = WCAtlasMentionStringFromEvent(style);
        if ([URLString hasPrefix:[WCAtlasMentionURLScheme stringByAppendingString:@"://"]]) return YES;
    }
    return NO;
}

static void WCAtlasSetMentionStyles(id self, SEL _cmd, id styles, id contentObject) {
    NSArray *originalStyles = [styles isKindOfClass:NSArray.class] ? styles : @[];
    NSString *content = [contentObject isKindOfClass:NSString.class] ? contentObject : nil;
    if (!WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey) || content.length == 0 ||
        [content rangeOfString:@"@"].location == NSNotFound || WCAtlasMentionStylesContainURL(originalStyles)) {
        WCAtlasOriginalSetMentionStyles(self, _cmd, styles, contentObject);
        return;
    }
    NSArray<NSString *> *userNames = WCAtlasPrivateMentionUserNames(self);
    if (userNames.count == 0) {
        WCAtlasOriginalSetMentionStyles(self, _cmd, styles, contentObject);
        return;
    }
    NSString *chatUserName = WCAtlasPrivateChatUserName(nil);
    id groupContact = [chatUserName hasSuffix:@"@chatroom"] ? WCAtlasPrivateContact(chatUserName) : nil;
    if (!groupContact) {
        WCAtlasOriginalSetMentionStyles(self, _cmd, styles, contentObject);
        return;
    }
    NSMutableArray *merged = [originalStyles mutableCopy];
    NSMutableIndexSet *claimed = [NSMutableIndexSet indexSet];
    NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *ownersByDisplayName = [NSMutableDictionary dictionary];
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
        NSRange range = WCAtlasMentionRange(content, candidates, claimed);
        if (range.location == NSNotFound || NSMaxRange(range) > content.length) continue;
        id style = WCAtlasMentionLinkStyle(range, WCAtlasMentionIsAllUserName(userName) ? @"notify@all" : userName);
        if (style) [merged addObject:style];
    }
    WCAtlasOriginalSetMentionStyles(self, _cmd, merged.count > originalStyles.count ? merged : styles, contentObject);
}

static void WCAtlasHandleMentionClick(id event) {
    if (!WCAtlasEnhancementEnabled(WCAtlasMentionHighlightEnabledKey)) return;
    NSString *URLString = WCAtlasMentionStringFromEvent(event);
    NSString *prefix = [WCAtlasMentionURLScheme stringByAppendingString:@"://"];
    if (![URLString hasPrefix:prefix]) return;
    NSString *encoded = [URLString substringFromIndex:prefix.length];
    NSString *userName = encoded.stringByRemovingPercentEncoding ?: encoded;
    if (userName.length == 0 || WCAtlasMentionIsAllUserName(userName)) return;
    NSTimeInterval now = NSDate.timeIntervalSinceReferenceDate;
    if ([WCAtlasLastOpenedMentionUserName isEqualToString:userName] &&
        now - WCAtlasLastOpenedMentionTime < 0.5) return;
    WCAtlasLastOpenedMentionUserName = [userName copy];
    WCAtlasLastOpenedMentionTime = now;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *source = WCAtlasPrivateCurrentChatController();
        if (source && !WCAtlasPushPrivateContactProfile(source, userName)) {
            WCAtlasLog(@"@ 资料页适配失败：%@", userName);
        }
    });
}

static void WCAtlasClickMentionLinkEvent(id self, SEL _cmd, id event) {
    if (WCAtlasOriginalClickMentionLinkEvent) WCAtlasOriginalClickMentionLinkEvent(self, _cmd, event);
    WCAtlasHandleMentionClick(event);
}

static void WCAtlasClickMentionTextEvent(id self, SEL _cmd, id event) {
    if (WCAtlasOriginalClickMentionTextEvent) WCAtlasOriginalClickMentionTextEvent(self, _cmd, event);
    WCAtlasHandleMentionClick(event);
}

#pragma mark - Hook Installation

void WCAtlasMentionHighlightInstallHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class richTextClass = NSClassFromString(@"RichTextView");
        SEL styleSelector = NSSelectorFromString(@"setArrStyles:withContent:");
        Method styleMethod = richTextClass ? class_getInstanceMethod(richTextClass, styleSelector) : NULL;
        if (!WCAtlasMentionMethodHasObjectArguments(styleMethod, 2)) {
            WCAtlasLog(@"@ 高亮未安装：RichTextView 样式 ABI 不支持");
            return;
        }
        IMP original = NULL;
        MSHookMessageEx(richTextClass, styleSelector, (IMP)WCAtlasSetMentionStyles, &original);
        WCAtlasOriginalSetMentionStyles = (void (*)(id, SEL, id, id))original;

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
    });
}
