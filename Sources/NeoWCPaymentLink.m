#import "NeoWCPaymentLink.h"
#import "NeoWCEnhancements.h"

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

static NSString *NeoWCPaymentCacheKey(NSString *field) {
    return [NeoWCPaymentCachePrefix stringByAppendingString:field ?: @""];
}

static void NeoWCPaymentStoreValue(NSUserDefaults *defaults, NSString *field, id value) {
    if (!value || value == NSNull.null) return;
    NSString *string = NeoWCPaymentTrimmedString(value) ?: @"";
    [defaults setObject:string forKey:NeoWCPaymentCacheKey(field)];
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

static NSString *NeoWCPaymentCachedValue(NSString *field, NSString *legacyKey) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *cacheKey = NeoWCPaymentCacheKey(field);
    id cachedObject = [defaults objectForKey:cacheKey];
    if (cachedObject != nil) return NeoWCPaymentTrimmedString(cachedObject) ?: @"";
    NSString *value = nil;
    if (legacyKey.length > 0) {
        id legacyObject = [defaults objectForKey:legacyKey];
        if (legacyObject != nil) {
            value = NeoWCPaymentTrimmedString(legacyObject) ?: @"";
            [defaults setObject:value forKey:cacheKey];
        }
    }
    return value;
}

static NSDictionary *NeoWCPaymentConfiguration(void) {
    NSDictionary *legacy = @{
        @"sid": @"wcr.payment-link.sjt.sid",
        @"v": @"wcr.payment-link.sjt.version",
        @"receipt_id": @"wcr.payment-link.sjt.receipt-id",
        @"account_type": @"wcr.payment-link.sjt.account-type",
        @"operator_role": @"wcr.payment-link.sjt.operator-role",
        @"merchant_identifier": @"wcr.payment-link.sjt.merchant-id",
        @"shop_name": @"wcr.payment-link.sjt.shop-name",
        @"remark": @"wcr.payment-link.sjt.link-remark",
        @"link_number": @"wcr.payment-link.sjt.link-number",
        @"number": @"",
    };
    NSMutableDictionary *configuration = [NSMutableDictionary dictionary];
    for (NSString *field in legacy) {
        NSString *value = NeoWCPaymentCachedValue(field, legacy[field]);
        if (value) configuration[field] = value;
    }
    return configuration;
}

static NSDictionary *NeoWCPaymentParseTemplate(NSString *text) {
    NSString *trimmed = NeoWCPaymentTrimmedString(text);
    NSString *prefix = [trimmed hasPrefix:@"#付款:"] ? @"#付款:" :
                       ([trimmed hasPrefix:@"#付款："] ? @"#付款：" : nil);
    if (!trimmed) return nil;
    NSString *suffix = prefix ? [trimmed substringFromIndex:prefix.length] : trimmed;
    NSArray<NSString *> *rawParts = [suffix componentsSeparatedByString:@"/"];
    if (rawParts.count != 3) return @{ @"error": @"格式应为 #付款:名称(微信号)/标题/编号" };
    NSString *identity = NeoWCPaymentTrimmedString(rawParts[0]);
    NSString *cardTitle = NeoWCPaymentTrimmedString(rawParts[1]);
    NSString *number = NeoWCPaymentTrimmedString(rawParts[2]);
    if (!identity || !cardTitle || !number) return @{ @"error": @"名称、标题和编号都不能为空" };
    NSRange opening = [identity rangeOfString:@"(" options:NSBackwardsSearch];
    if (opening.location == NSNotFound || ![identity hasSuffix:@")"] || opening.location == 0) {
        return @{ @"error": @"名称后需要填写括号内微信号" };
    }
    NSString *displayName = NeoWCPaymentTrimmedString([identity substringToIndex:opening.location]);
    NSString *wechatID = NeoWCPaymentTrimmedString([identity substringWithRange:
        NSMakeRange(NSMaxRange(opening), identity.length - NSMaxRange(opening) - 1)]);
    NSCharacterSet *invalidNumber = [NSCharacterSet.decimalDigitCharacterSet invertedSet];
    if (!displayName || !wechatID || [number rangeOfCharacterFromSet:invalidNumber].location != NSNotFound) {
        return @{ @"error": @"微信号不能为空，编号只能包含数字" };
    }
    return @{ @"title": suffix, @"displayName": displayName, @"wechatID": wechatID,
              @"cardTitle": cardTitle, @"number": number };
}

BOOL NeoWCPaymentLinkIsTriggerText(NSString *text) {
    NSString *trimmed = NeoWCPaymentTrimmedString(text);
    return trimmed && [trimmed caseInsensitiveCompare:@"#fk"] == NSOrderedSame;
}

NSString *NeoWCPaymentLinkSuggestedCardTitle(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *stored = NeoWCPaymentTrimmedString([defaults objectForKey:NeoWCPaymentCardTitleKey]);
    if (stored) return stored;
    for (NSString *legacyKey in @[@"paymentLinkTemplate", @"wcr.payment-link.template"]) {
        NSDictionary *template = NeoWCPaymentParseTemplate([defaults objectForKey:legacyKey]);
        NSString *legacyTitle = template[@"cardTitle"];
        if (legacyTitle.length > 0) return legacyTitle;
    }
    return @"快捷付款";
}

NSString *NeoWCPaymentLinkDisplayNumber(void) {
    NSDictionary *configuration = NeoWCPaymentConfiguration();
    NSString *number = NeoWCPaymentTrimmedString(configuration[@"link_number"]);
    if (!number) number = NeoWCPaymentTrimmedString(configuration[@"number"]);
    if (!number) {
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        for (NSString *legacyKey in @[@"paymentLinkNumber", @"wcr.payment-link.number"]) {
            number = NeoWCPaymentTrimmedString([defaults objectForKey:legacyKey]);
            if (number) break;
        }
    }
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
    if (sid.length == 0 || version.length == 0 || receiptID.length == 0 ||
        accountType.length == 0 || operatorRole.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            finish(nil, NeoWCPaymentError(3, @"尚未取得小账本请求参数，请先在微信收款小账本中打开一次收款链接"));
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
