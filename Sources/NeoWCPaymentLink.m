#import "NeoWCPaymentLink.h"
#import "NeoWCAccount.h"
#import "NeoWCEnhancements.h"
#import <objc/message.h>
#import <objc/runtime.h>

NSString *const NeoWCPaymentLinkEnabledKey = @"com.qiu7c.neowc.chat.payment-link";

static NSString *const NeoWCPaymentCachePrefix = @"com.qiu7c.neowc.payment-link.sjt.";
static NSString *const NeoWCPaymentErrorDomain = @"com.qiu7c.neowc.payment-link";
static NSString *const NeoWCPaymentCardTitleKey = @"com.qiu7c.neowc.payment-link.card-title";

static NSMutableSet<NSString *> *NeoWCPaymentInFlightCommands(void) {
    static NSMutableSet<NSString *> *commands;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ commands = [NSMutableSet set]; });
    return commands;
}

static NSString *NeoWCPaymentTrimmedString(id value) {
    if (![value isKindOfClass:NSString.class]) {
        if ([value respondsToSelector:@selector(stringValue)]) value = [value stringValue];
        else return nil;
    }
    NSString *trimmed = [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return trimmed.length > 0 ? trimmed : nil;
}

BOOL NeoWCPaymentLinkMatchesRequest(NSURLRequest *request) {
    if (![request isKindOfClass:NSURLRequest.class]) return NO;
    NSURL *URL = request.URL;
    return [[URL.host lowercaseString] isEqualToString:@"sjtmgr.wxpapp.weixin.qq.com"] &&
           [URL.path hasPrefix:@"/sjt/linkqrcode/"];
}

static NSDictionary *NeoWCPaymentJSONDictionary(NSData *data) {
    if (![data isKindOfClass:NSData.class] || data.length == 0) return nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [object isKindOfClass:NSDictionary.class] ? object : nil;
}

static NSString *NeoWCPaymentCurrentAccount(void) {
    Class settingUtilClass = objc_getClass("SettingUtil");
    SEL selector = sel_registerName("getLocalUsrName:");
    if ([settingUtilClass respondsToSelector:selector]) {
        id value = ((id (*)(id, SEL, BOOL))objc_msgSend)(settingUtilClass, selector, NO);
        NSString *username = NeoWCPaymentTrimmedString(value);
        if (username) return username;
    }
    return NeoWCPaymentTrimmedString(NeoWCCurrentUserWXID());
}

static NSString *NeoWCPaymentCacheKey(NSString *field) {
    NSString *account = NeoWCPaymentCurrentAccount();
    if (!account || field.length == 0) return nil;
    return [NSString stringWithFormat:@"%@%@.%@", NeoWCPaymentCachePrefix, account, field];
}

static void NeoWCPaymentStoreValue(NSUserDefaults *defaults, NSString *field, id value) {
    if (!value || value == NSNull.null) return;
    NSString *key = NeoWCPaymentCacheKey(field);
    if (!key) return;
    NSString *string = NeoWCPaymentTrimmedString(value) ?: @"";
    [defaults setObject:string forKey:key];
}

void NeoWCPaymentLinkLearnFromRequest(NSURLRequest *request, NSData *uploadData) {
    if (!NeoWCPaymentLinkMatchesRequest(request)) return;
    NSDictionary *body = NeoWCPaymentJSONDictionary(uploadData ?: request.HTTPBody);
    if (!body) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    for (NSString *field in @[@"sid", @"v", @"receipt_id", @"account_type",
                              @"operator_role", @"merchant_identifier", @"shop_name", @"remark",
                              @"link_number", @"number"]) {
        NeoWCPaymentStoreValue(defaults, field, body[field]);
    }
    NSDictionary *nested = [body[@"modify_link_qrcode"] isKindOfClass:NSDictionary.class]
        ? body[@"modify_link_qrcode"] : nil;
    for (NSString *field in @[@"receipt_id", @"account_type", @"operator_role",
                              @"merchant_identifier", @"shop_name", @"remark"]) {
        if (nested[field]) NeoWCPaymentStoreValue(defaults, field, nested[field]);
    }
}

static id NeoWCPaymentDecodedResponseObject(NSData *data) {
    if (![data isKindOfClass:NSData.class] || data.length == 0) return nil;
    id outer = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![outer isKindOfClass:NSDictionary.class]) return outer;
    NSDictionary *outerDictionary = outer;
    id encoded = outerDictionary[@"data"];
    if (![encoded isKindOfClass:NSString.class] || [encoded length] == 0) return outer;
    NSData *innerData = [encoded dataUsingEncoding:NSUTF8StringEncoding];
    id inner = innerData.length ? [NSJSONSerialization JSONObjectWithData:innerData options:0 error:nil] : nil;
    if (![inner isKindOfClass:NSDictionary.class]) return outer;
    NSMutableDictionary *merged = [inner mutableCopy];
    for (NSString *field in @[@"sid", @"v", @"errcode", @"errmsg"]) {
        if (!merged[field] && outerDictionary[field]) merged[field] = outerDictionary[field];
    }
    return merged;
}

static id NeoWCPaymentValueForAliases(NSDictionary *dictionary, NSArray<NSString *> *aliases) {
    for (NSString *alias in aliases) {
        id value = dictionary[alias];
        if (value && value != NSNull.null) return value;
    }
    return nil;
}

static NSInteger NeoWCPaymentSubjectScore(NSDictionary *dictionary) {
    NSInteger score = 0;
    if (NeoWCPaymentValueForAliases(dictionary, @[@"receipt_id"])) score += 4;
    if (NeoWCPaymentValueForAliases(dictionary, @[@"account_type"])) score += 3;
    if (NeoWCPaymentValueForAliases(dictionary, @[@"operator_role"])) score += 3;
    if (NeoWCPaymentValueForAliases(dictionary, @[@"merchant_identifier", @"merchant_id", @"merchantId"])) score += 1;
    if (NeoWCPaymentValueForAliases(dictionary, @[@"shop_name", @"shopname", @"shopName"])) score += 1;
    return score;
}

static NSDictionary *NeoWCPaymentBestSubjectInObject(id object, NSUInteger depth) {
    if (!object || depth > 5) return nil;
    NSDictionary *best = nil;
    if ([object isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictionary = object;
        if (NeoWCPaymentSubjectScore(dictionary) > 0) best = dictionary;
        NSArray *preferredKeys = @[@"current_shop", @"shop_info", @"shop_data", @"shop", @"data", @"list"];
        NSMutableArray *values = [NSMutableArray array];
        for (NSString *key in preferredKeys) if (dictionary[key]) [values addObject:dictionary[key]];
        for (id key in dictionary) {
            id value = dictionary[key];
            if (![values containsObject:value]) [values addObject:value];
        }
        for (id value in values) {
            NSDictionary *candidate = NeoWCPaymentBestSubjectInObject(value, depth + 1);
            if (NeoWCPaymentSubjectScore(candidate) > NeoWCPaymentSubjectScore(best)) best = candidate;
        }
    } else if ([object isKindOfClass:NSArray.class]) {
        for (id value in (NSArray *)object) {
            NSDictionary *candidate = NeoWCPaymentBestSubjectInObject(value, depth + 1);
            if (NeoWCPaymentSubjectScore(candidate) > NeoWCPaymentSubjectScore(best)) best = candidate;
        }
    }
    return best;
}

void NeoWCPaymentLinkLearnFromResponse(NSData *data) {
    id object = NeoWCPaymentDecodedResponseObject(data);
    if (!object) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSDictionary *root = [object isKindOfClass:NSDictionary.class] ? object : nil;
    for (NSString *field in @[@"sid", @"v"]) NeoWCPaymentStoreValue(defaults, field, root[field]);
    NSDictionary *subject = NeoWCPaymentBestSubjectInObject(object, 0);
    if (!subject) return;
    NSDictionary<NSString *, NSArray<NSString *> *> *aliases = @{
        @"receipt_id": @[@"receipt_id"],
        @"account_type": @[@"account_type"],
        @"operator_role": @[@"operator_role"],
        @"merchant_identifier": @[@"merchant_identifier", @"merchant_id", @"merchantId"],
        @"shop_name": @[@"shop_name", @"shopname", @"shopName"],
        @"remark": @[@"remark"],
    };
    for (NSString *field in aliases) {
        NeoWCPaymentStoreValue(defaults, field, NeoWCPaymentValueForAliases(subject, aliases[field]));
    }
}

static NSString *NeoWCPaymentCachedValue(NSString *field) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *cacheKey = NeoWCPaymentCacheKey(field);
    if (!cacheKey) return nil;
    id cachedObject = [defaults objectForKey:cacheKey];
    return cachedObject != nil ? (NeoWCPaymentTrimmedString(cachedObject) ?: @"") : nil;
}

static NSDictionary *NeoWCPaymentConfiguration(void) {
    NSMutableDictionary *configuration = [NSMutableDictionary dictionary];
    for (NSString *field in @[@"sid", @"v", @"receipt_id", @"account_type", @"operator_role",
                              @"merchant_identifier", @"shop_name", @"remark", @"link_number", @"number"]) {
        NSString *value = NeoWCPaymentCachedValue(field);
        if (value) configuration[field] = value;
    }
    return configuration;
}

static void NeoWCPaymentClearLearnedSubject(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    for (NSString *field in @[@"sid", @"v", @"receipt_id", @"account_type", @"operator_role",
                              @"merchant_identifier", @"shop_name", @"remark"]) {
        NSString *key = NeoWCPaymentCacheKey(field);
        if (key) [defaults removeObjectForKey:key];
    }
}

BOOL NeoWCPaymentLinkIsTriggerText(NSString *text) {
    NSString *trimmed = NeoWCPaymentTrimmedString(text);
    return trimmed && [trimmed caseInsensitiveCompare:@"#fk"] == NSOrderedSame;
}

NSString *NeoWCPaymentLinkSuggestedCardTitle(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *stored = NeoWCPaymentTrimmedString([defaults objectForKey:NeoWCPaymentCardTitleKey]);
    return stored ?: @"快捷付款";
}

NSString *NeoWCPaymentLinkDisplayNumber(void) {
    NSDictionary *configuration = NeoWCPaymentConfiguration();
    NSString *number = NeoWCPaymentTrimmedString(configuration[@"link_number"]);
    if (!number) number = NeoWCPaymentTrimmedString(configuration[@"number"]);
    return number;
}

BOOL NeoWCPaymentLinkSetDisplayNumber(NSString *number) {
    NSString *normalized = NeoWCPaymentTrimmedString(number);
    if (!normalized) return NO;
    NSCharacterSet *invalid = NSCharacterSet.decimalDigitCharacterSet.invertedSet;
    if ([normalized rangeOfCharacterFromSet:invalid].location != NSNotFound) return NO;
    [NSUserDefaults.standardUserDefaults setObject:normalized
                                            forKey:NeoWCPaymentCacheKey(@"link_number")];
    return YES;
}

static NSError *NeoWCPaymentError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:NeoWCPaymentErrorDomain code:code
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"收款链接发送失败"}];
}

static NSMutableURLRequest *NeoWCPaymentRequest(NSString *path, NSDictionary *payload,
                                                NSString *sid, NSString *version) {
    NSURLComponents *components = [NSURLComponents componentsWithString:
        [@"https://sjtmgr.wxpapp.weixin.qq.com/sjt/linkqrcode/" stringByAppendingString:path]];
    components.queryItems = @[[NSURLQueryItem queryItemWithName:@"sid" value:sid],
                              [NSURLQueryItem queryItemWithName:@"v" value:version]];
    NSMutableDictionary *body = [payload mutableCopy];
    body[@"sid"] = sid;
    body[@"v"] = version;
    NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    if (!components.URL || !data) return nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"wx9291fe7dadf5a574" forHTTPHeaderField:@"X-Appid"];
    [request setValue:@"mmpaysjtaccountmp" forHTTPHeaderField:@"X-Module-Name"];
    [request setValue:@"pages/link-qr-code/index/index" forHTTPHeaderField:@"X-Page"];
    return request;
}

static void NeoWCPaymentPerform(NSURLRequest *request, void (^completion)(NSDictionary *, NSError *)) {
    if (!request) {
        completion(nil, NeoWCPaymentError(4, @"无法构造小账本请求"));
        return;
    }
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *HTTPResponse = [response isKindOfClass:NSHTTPURLResponse.class]
            ? (NSHTTPURLResponse *)response : nil;
        NSDictionary *JSON = NeoWCPaymentJSONDictionary(data);
        NSInteger errorCode = [JSON[@"errcode"] respondsToSelector:@selector(integerValue)]
            ? [JSON[@"errcode"] integerValue] : NSIntegerMin;
        if (error || HTTPResponse.statusCode != 200 || !JSON || errorCode != 0) {
            NSString *serverMessage = NeoWCPaymentTrimmedString(JSON[@"errmsg"]);
            if (!serverMessage) serverMessage = NeoWCPaymentTrimmedString(JSON[@"msg"]);
            NSString *serverHint = NeoWCPaymentTrimmedString(JSON[@"hint"]);
            if (serverHint.length > 0 && ![serverHint isEqualToString:serverMessage]) {
                serverMessage = serverMessage.length > 0
                    ? [NSString stringWithFormat:@"%@（%@）", serverMessage, serverHint]
                    : serverHint;
            }
            if (errorCode == 268564837) {
                NeoWCPaymentClearLearnedSubject();
                NSString *refresh = @"已清除当前账号的旧主体配置，请打开微信官方收款小账本后重试";
                serverMessage = serverMessage.length > 0
                    ? [NSString stringWithFormat:@"%@（%@）", serverMessage, refresh]
                    : refresh;
            }
            NSString *message = serverMessage ?: @"小账本登记失败，请先打开微信收款小账本刷新链接";
            completion(nil, error ?: NeoWCPaymentError(5, message));
            return;
        }
        completion(JSON, nil);
    }] resume];
}

BOOL NeoWCPaymentLinkSend(NSString *cardTitle, NSString *identityUsername,
                          NSString *targetUsername, NeoWCPaymentLinkCompletion completion) {
    if (!NeoWCEnhancementEnabled(NeoWCPaymentLinkEnabledKey)) return NO;
    NSString *normalizedTitle = NeoWCPaymentTrimmedString(cardTitle);
    NSString *normalizedIdentity = NeoWCPaymentTrimmedString(identityUsername);
    if (!normalizedTitle || !normalizedIdentity) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(nil, NeoWCPaymentError(1, @"标题或当前微信号为空"));
        });
        return YES;
    }
    if (NeoWCPaymentTrimmedString(targetUsername).length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(nil, NeoWCPaymentError(2, @"无法取得当前会话"));
        });
        return YES;
    }
    NSString *commandToken = [NSString stringWithFormat:@"%@\n%@", targetUsername, normalizedTitle];
    @synchronized (NeoWCPaymentInFlightCommands()) {
        if ([NeoWCPaymentInFlightCommands() containsObject:commandToken]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, NeoWCPaymentError(6, @"这条收款链接正在登记，请稍候"));
            });
            return YES;
        }
        [NeoWCPaymentInFlightCommands() addObject:commandToken];
    }
    void (^finish)(NSString *, NSError *) = ^(NSString *title, NSError *error) {
        @synchronized (NeoWCPaymentInFlightCommands()) {
            [NeoWCPaymentInFlightCommands() removeObject:commandToken];
        }
        if (completion) completion(title, error);
    };
    NSDictionary *configuration = NeoWCPaymentConfiguration();
    NSString *sid = configuration[@"sid"];
    NSString *version = configuration[@"v"];
    NSString *receiptID = configuration[@"receipt_id"];
    NSString *accountType = configuration[@"account_type"];
    NSString *operatorRole = configuration[@"operator_role"];
    NSString *number = NeoWCPaymentLinkDisplayNumber();
    NSMutableArray<NSString *> *missing = [NSMutableArray array];
    if (sid.length == 0) [missing addObject:@"sid"];
    if (version.length == 0) [missing addObject:@"v"];
    if (receiptID.length == 0) [missing addObject:@"receipt_id"];
    if (accountType.length == 0) [missing addObject:@"account_type"];
    if (operatorRole.length == 0) [missing addObject:@"operator_role"];
    if (missing.count > 0) {
        NSString *detail = [missing componentsJoinedByString:@"、"];
        dispatch_async(dispatch_get_main_queue(), ^{
            finish(nil, NeoWCPaymentError(3,
                [NSString stringWithFormat:@"尚未取得当前账号的小账本参数：%@。请打开微信官方收款小账本后重试", detail]));
        });
        return YES;
    }
    if (number.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            finish(nil, NeoWCPaymentError(7, @"尚未设置收款编号，请重新输入 #fk 后填写"));
        });
        return YES;
    }
    NSString *merchantID = configuration[@"merchant_identifier"] ?: @"";
    NSString *shopName = [configuration[@"shop_name"] length] > 0
        ? configuration[@"shop_name"] : normalizedIdentity;
    NSString *remark = configuration[@"remark"] ?: @"";
    NSDictionary *link = @{
        @"account_type": accountType,
        @"check_type": @"E_CHECK_OCCUPATION_CHECK_TYPE_MODIFY",
        @"merchant_identifier": merchantID,
        @"operator_role": operatorRole,
        @"receipt_id": receiptID,
        @"remark": remark,
        @"shop_name": shopName,
    };
    NSMutableURLRequest *checkRequest = NeoWCPaymentRequest(@"payshortlink/checkoccupation", link, sid, version);
    NeoWCPaymentPerform(checkRequest, ^(__unused NSDictionary *checkResponse, NSError *checkError) {
        if (checkError) {
            dispatch_async(dispatch_get_main_queue(), ^{ finish(nil, checkError); });
            return;
        }
        NSString *sequence = [NSString stringWithFormat:@"modify_%.0f", NSDate.date.timeIntervalSince1970 * 1000.0];
        NSDictionary *modify = @{
            @"account_type": accountType,
            @"merchant_identifier": merchantID,
            @"modify_link_qrcode": link,
            @"modify_sequence": sequence,
            @"operator_role": operatorRole,
            @"receipt_id": @([receiptID longLongValue]),
        };
        NSMutableURLRequest *modifyRequest = NeoWCPaymentRequest(@"linkqrcode/modify", modify, sid, version);
        NeoWCPaymentPerform(modifyRequest, ^(__unused NSDictionary *modifyResponse, NSError *modifyError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!modifyError) {
                    [NSUserDefaults.standardUserDefaults setObject:normalizedTitle forKey:NeoWCPaymentCardTitleKey];
                }
                NSString *messageTitle = [NSString stringWithFormat:@"%@(%@)/%@/%@",
                                          shopName, normalizedIdentity, normalizedTitle, number];
                finish(modifyError ? nil : messageTitle, modifyError);
            });
        });
    });
    return YES;
}
