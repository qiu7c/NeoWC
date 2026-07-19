#import "NeoWCAntiRevoke.h"

#import <objc/message.h>
#import <objc/runtime.h>

#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"

NSString *const NeoWCAntiRevokePromptDidChangeNotification = @"NeoWCAntiRevokePromptDidChangeNotification";
static NSString *const NeoWCAntiRevokeSidePromptRecordsKey = @"com.qiu7c.neowc.message.anti-revoke.side-records";

static NSString *const NeoWCDefaultLocalRevokeTemplate =
    @"拦截到一条{用户名}撤回的消息\n发送时间：{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}\n内容：{内容}";

static NSString *const NeoWCDefaultRevokeReplyTemplate =
    @"【捕捉到一条撤回消息】\n操作用户：{用户名}\n发送时间：{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}\n"
    @"撤回内容：{内容}\n\n撤回无效，消息已保存";

static id NeoWCSafeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static void NeoWCSafeSetValue(id object, NSString *key, id value) {
    if (!object || key.length == 0) return;
    @try {
        [object setValue:value forKey:key];
    } @catch (__unused NSException *exception) {}
}

static NSString *NeoWCStringValue(id object, NSString *key) {
    id value = NeoWCSafeValue(object, key);
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

static NSUInteger NeoWCUIntegerValue(id object, NSString *key) {
    id value = NeoWCSafeValue(object, key);
    return [value respondsToSelector:@selector(unsignedIntegerValue)] ? [value unsignedIntegerValue] : 0;
}

static NSString *NeoWCSidePromptRecordKey(id message) {
    unsigned long long serverID = [NeoWCSafeValue(message, @"m_n64MesSvrID") unsignedLongLongValue];
    if (serverID == 0) serverID = [NeoWCSafeValue(message, @"m_uiMesLocalID") unsignedLongLongValue];
    return serverID == 0 ? nil : [NSString stringWithFormat:@"%llu", serverID];
}

NSString *NeoWCAntiRevokeSidePromptForMessage(id message) {
    NSString *recordKey = NeoWCSidePromptRecordKey(message);
    if (recordKey.length == 0) return nil;
    NSDictionary *records = [[NSUserDefaults standardUserDefaults] dictionaryForKey:NeoWCAntiRevokeSidePromptRecordsKey];
    id text = records[recordKey];
    return [text isKindOfClass:[NSString class]] ? text : nil;
}

static void NeoWCRememberSidePrompt(id message, NSString *text) {
    NSString *recordKey = NeoWCSidePromptRecordKey(message);
    if (recordKey.length == 0 || text.length == 0) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    @synchronized (defaults) {
        NSMutableDictionary *records = [[defaults dictionaryForKey:NeoWCAntiRevokeSidePromptRecordsKey] mutableCopy] ?: [NSMutableDictionary dictionary];
        if (records.count >= 400 && !records[recordKey]) [records removeObjectForKey:records.allKeys.firstObject];
        records[recordKey] = text;
        [defaults setObject:records forKey:NeoWCAntiRevokeSidePromptRecordsKey];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    });
}

static NSString *NeoWCTextBetween(NSString *text, NSString *opening, NSString *closing) {
    if (text.length == 0 || opening.length == 0 || closing.length == 0) return nil;
    NSRange first = [text rangeOfString:opening];
    if (first.location == NSNotFound) return nil;
    NSUInteger contentStart = NSMaxRange(first);
    if (contentStart > text.length) return nil;
    NSRange searchRange = NSMakeRange(contentStart, text.length - contentStart);
    NSRange last = [text rangeOfString:closing options:0 range:searchRange];
    if (last.location == NSNotFound) return nil;
    return [text substringWithRange:NSMakeRange(contentStart, last.location - contentStart)];
}

static NSDictionary<NSString *, NSString *> *NeoWCDateFields(NSDate *date) {
    NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
                           NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *parts = [[NSCalendar currentCalendar] components:units fromDate:date];
    return @{
        @"yyyy": [NSString stringWithFormat:@"%ld", (long)parts.year],
        @"MM": [NSString stringWithFormat:@"%02ld", (long)parts.month],
        @"dd": [NSString stringWithFormat:@"%02ld", (long)parts.day],
        @"HH": [NSString stringWithFormat:@"%02ld", (long)parts.hour],
        @"mm": [NSString stringWithFormat:@"%02ld", (long)parts.minute],
        @"ss": [NSString stringWithFormat:@"%02ld", (long)parts.second],
    };
}

static NSString *NeoWCMessageTypeName(NSUInteger type) {
    switch (type) {
        case 1:  return @"文本";
        case 3:  return @"图片";
        case 34: return @"语音";
        case 42: return @"名片";
        case 43: return @"视频";
        case 47: return @"表情";
        case 48: return @"位置";
        case 49: return @"分享";
        default: return [NSString stringWithFormat:@"类型(%lu)", (unsigned long)type];
    }
}

static NSString *NeoWCContentSummary(id message) {
    NSUInteger type = NeoWCUIntegerValue(message, @"m_uiMessageType");
    NSString *content = NeoWCStringValue(message, @"m_nsContent");
    if (type == 1 && content.length > 0) return content;
    return [NSString stringWithFormat:@"[%@]", NeoWCMessageTypeName(type)];
}

static NSString *NeoWCApplyRevokeTemplate(NSString *templateText,
                                          NSString *operatorName,
                                          NSString *contentSummary,
                                          NSDate *messageDate) {
    NSString *result = [templateText stringByReplacingOccurrencesOfString:@"{用户名}"
                                                                withString:operatorName ?: @"用户"];
    result = [result stringByReplacingOccurrencesOfString:@"{内容}"
                                                withString:contentSummary ?: @""];
    NSDictionary<NSString *, NSString *> *fields = NeoWCDateFields(messageDate ?: [NSDate date]);
    for (NSString *key in fields) {
        result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%@}", key]
                                                    withString:fields[key]];
    }
    return result;
}

static NSString *NeoWCRevokeOperatorName(NSString *replaceMessage) {
    NSRange phrase = [replaceMessage rangeOfString:@"撤回了一条消息"];
    NSString *name = phrase.location == NSNotFound ? @"用户" : [replaceMessage substringToIndex:phrase.location];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length >= 2 && [name hasPrefix:@"\""] && [name hasSuffix:@"\""]) {
        name = [name substringWithRange:NSMakeRange(1, name.length - 2)];
    }
    return name.length > 0 ? name : @"用户";
}

static id NeoWCNewMessageWrap(NSUInteger type) {
    Class wrapClass = objc_getClass("CMessageWrap");
    SEL initSelector = sel_registerName("initWithMsgType:");
    if (!wrapClass || ![wrapClass instancesRespondToSelector:initSelector]) return nil;
    id allocated = [wrapClass alloc];
    return ((id (*)(id, SEL, NSUInteger))objc_msgSend)(allocated, initSelector, type);
}

static id NeoWCSelfContact(void) {
    Class centerClass = objc_getClass("MMServiceCenter");
    Class contactManagerClass = objc_getClass("CContactMgr");
    if (!centerClass || !contactManagerClass) return nil;
    id center = ((id (*)(id, SEL))objc_msgSend)(centerClass, sel_registerName("defaultCenter"));
    if (!center) return nil;
    id contactManager = ((id (*)(id, SEL, Class))objc_msgSend)(center, sel_registerName("getService:"), contactManagerClass);
    if (!contactManager || ![contactManager respondsToSelector:sel_registerName("getSelfContact")]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(contactManager, sel_registerName("getSelfContact"));
}

static id NeoWCOriginalMessage(id manager, NSString *session, long long serverID) {
    SEL selector = sel_registerName("GetMsg:n64SvrID:");
    if (!manager || ![manager respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL, NSString *, long long))objc_msgSend)(manager, selector, session, serverID);
}

static BOOL NeoWCInsertLocalMessage(id manager, NSString *session, id message) {
    SEL selector = sel_registerName("AddLocalMsg:MsgWrap:fixTime:NewMsgArriveNotify:");
    if (![manager respondsToSelector:selector]) return NO;
    ((void (*)(id, SEL, NSString *, id, BOOL, BOOL))objc_msgSend)(manager, selector, session, message, YES, NO);
    return YES;
}

static void NeoWCSendMessage(id manager, NSString *session, id message) {
    SEL selector = sel_registerName("AddMsg:MsgWrap:");
    if (![manager respondsToSelector:selector]) return;
    ((void (*)(id, SEL, NSString *, id))objc_msgSend)(manager, selector, session, message);
}

BOOL NeoWCHandleRevokeMessage(id messageManager, id incomingMessage) {
    if (!NeoWCEnhancementEnabled(NeoWCAntiRevokeKey) || !incomingMessage) return NO;

    NSString *xml = NeoWCStringValue(incomingMessage, @"m_nsContent");
    if (![xml containsString:@"<sysmsg type=\"revokemsg\"><revokemsg>"]) return NO;

    NSString *session = NeoWCTextBetween(xml, @"<session>", @"</session>");
    NSString *serverIDText = NeoWCTextBetween(xml, @"<newmsgid>", @"</newmsgid>");
    NSString *replaceMessage = NeoWCTextBetween(xml, @"<replacemsg><![CDATA[", @"]]></replacemsg>");
    long long serverID = serverIDText.longLongValue;
    if (session.length == 0 || serverID == 0 || replaceMessage.length == 0) return NO;

    // Own-message revoke notifications must keep WeChat's original behavior.
    if ([replaceMessage hasPrefix:@"你"] || [replaceMessage containsString:@"你撤回了一条消息"]) return NO;

    id selfContact = NeoWCSelfContact();
    NSString *selfUsername = NeoWCStringValue(selfContact, @"m_nsUsrName");
    if (selfUsername.length == 0) return NO;
    id original = NeoWCOriginalMessage(messageManager, session, serverID);
    NSString *originalFrom = NeoWCStringValue(original, @"m_nsFromUsr");
    if (!original || (selfUsername.length > 0 && [originalFrom isEqualToString:selfUsername])) return NO;

    NSString *operatorName = NeoWCRevokeOperatorName(replaceMessage);
    if ([operatorName isEqualToString:selfUsername]) return NO;
    NSUInteger createTime = NeoWCUIntegerValue(original, @"m_uiCreateTime");
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:createTime];
    NSString *summary = NeoWCContentSummary(original);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *localTemplate = [defaults stringForKey:NeoWCAntiRevokeLocalTemplateKey];
    if (localTemplate.length == 0) localTemplate = NeoWCDefaultLocalRevokeTemplate;

    NSInteger promptStyle = [defaults integerForKey:NeoWCAntiRevokePromptStyleKey];
    if (promptStyle == 1) {
        NeoWCRememberSidePrompt(original, @"已拦截撤回");
    } else {
        id localMessage = NeoWCNewMessageWrap(10000);
        if (!localMessage) return NO;
        NeoWCSafeSetValue(localMessage, @"m_nsFromUsr", originalFrom);
        NeoWCSafeSetValue(localMessage, @"m_nsToUsr", NeoWCStringValue(original, @"m_nsToUsr"));
        NeoWCSafeSetValue(localMessage, @"m_uiStatus", @4);
        NeoWCSafeSetValue(localMessage, @"m_nsContent", NeoWCApplyRevokeTemplate(localTemplate, operatorName, summary, messageDate));
        NeoWCSafeSetValue(localMessage, @"m_uiCreateTime", @(createTime + 1));
        if (!NeoWCInsertLocalMessage(messageManager, session, localMessage)) return NO;
    }
    NeoWCLog(@"已拦截 %@ 的撤回消息：%@", operatorName, summary);

    if (![defaults boolForKey:NeoWCAntiRevokeNotifySenderKey]) return YES;
    NSTimeInterval filter = [defaults doubleForKey:NeoWCAntiRevokeTimeFilterKey];
    NSTimeInterval age = [NSDate date].timeIntervalSince1970 - createTime;
    if (filter > 0.0 && age > filter) return YES;

    NSString *replyTemplate = [defaults stringForKey:NeoWCAntiRevokeReplyTemplateKey];
    if (replyTemplate.length == 0) replyTemplate = NeoWCDefaultRevokeReplyTemplate;
    NSString *replyText = NeoWCApplyRevokeTemplate(replyTemplate, operatorName, summary, messageDate);
    id reply = NeoWCNewMessageWrap(1);
    if (!reply) return YES;
    NSString *target = [session containsString:@"@chatroom"] ? session : originalFrom;
    NeoWCSafeSetValue(reply, @"m_nsContent", replyText);
    NeoWCSafeSetValue(reply, @"m_nsFromUsr", selfUsername);
    NeoWCSafeSetValue(reply, @"m_nsToUsr", target);
    NeoWCSafeSetValue(reply, @"m_uiStatus", @4);
    NeoWCSafeSetValue(reply, @"m_uiCreateTime", @((NSUInteger)[NSDate date].timeIntervalSince1970));
    NeoWCSendMessage(messageManager, target, reply);
    NeoWCLog(@"已向撤回者发送提示（会话：%@）", target);
    return YES;
}
