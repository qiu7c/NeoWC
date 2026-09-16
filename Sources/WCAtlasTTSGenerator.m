#import "WCAtlasTTSGenerator.h"
#import <Security/Security.h>

static NSString *const WCAtlasTTSErrorDomain = @"com.qiu7c.wcatlas.tts";
static NSString *const WCAtlasFishAudioKeychainService = @"com.qiu7c.wcatlas.fish-audio";
static NSString *const WCAtlasFishAudioKeychainAccount = @"api-key";
static NSString *const WCAtlasFishAudioModelKey = @"com.qiu7c.wcatlas.tts.fish.model";
static NSString *const WCAtlasFishAudioReferenceIDKey = @"com.qiu7c.wcatlas.tts.fish.reference-id";
static NSString *const WCAtlasFishAudioVoicePresetsKey = @"com.qiu7c.wcatlas.tts.fish.voice-presets";
static NSString *const WCAtlasFishAudioVoicePresetsSeededKey = @"com.qiu7c.wcatlas.tts.fish.voice-presets-seeded";
static NSString *const WCAtlasFishAudioDefaultModel = @"s2.1-pro-free";

static NSError *WCAtlasTTSError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:WCAtlasTTSErrorDomain code:code
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"语音生成失败"}];
}

static NSString *WCAtlasTTSTrimmedString(id value) {
    if (![value isKindOfClass:NSString.class]) return @"";
    return [(NSString *)value stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

static NSDictionary *WCAtlasFishAudioKeychainQuery(void) {
    return @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: WCAtlasFishAudioKeychainService,
        (__bridge id)kSecAttrAccount: WCAtlasFishAudioKeychainAccount
    };
}

NSURL *WCAtlasFishAudioAPIKeysURL(void) {
    return [NSURL URLWithString:@"https://fish.audio/app/api-keys/"];
}

NSString *WCAtlasFishAudioAPIKey(void) {
    NSMutableDictionary *query = [WCAtlasFishAudioKeychainQuery() mutableCopy];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess || !result) return nil;
    NSData *data = CFBridgingRelease(result);
    NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    value = WCAtlasTTSTrimmedString(value);
    return value.length > 0 ? value : nil;
}

BOOL WCAtlasSetFishAudioAPIKey(NSString *APIKey, NSError **error) {
    NSString *trimmed = WCAtlasTTSTrimmedString(APIKey);
    NSDictionary *query = WCAtlasFishAudioKeychainQuery();
    OSStatus status = errSecSuccess;
    if (trimmed.length == 0) {
        status = SecItemDelete((__bridge CFDictionaryRef)query);
        if (status == errSecItemNotFound) status = errSecSuccess;
    } else {
        NSData *data = [trimmed dataUsingEncoding:NSUTF8StringEncoding];
        status = SecItemUpdate((__bridge CFDictionaryRef)query,
            (__bridge CFDictionaryRef)@{(__bridge id)kSecValueData: data});
        if (status == errSecItemNotFound) {
            NSMutableDictionary *attributes = [query mutableCopy];
            attributes[(__bridge id)kSecValueData] = data;
            attributes[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
            status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
        }
    }
    if (status == errSecSuccess) return YES;
    if (error) {
        NSString *message = CFBridgingRelease(SecCopyErrorMessageString(status, NULL));
        *error = WCAtlasTTSError(20, message.length > 0 ? message : @"无法保存 Fish Audio API Key");
    }
    return NO;
}

static NSSet<NSString *> *WCAtlasFishAudioSupportedModels(void) {
    static NSSet<NSString *> *models;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        models = [NSSet setWithArray:@[@"s2.1-pro-free", @"s2.1-pro", @"s2-pro"]];
    });
    return models;
}

NSString *WCAtlasFishAudioModel(void) {
    NSString *model = WCAtlasTTSTrimmedString(
        [NSUserDefaults.standardUserDefaults stringForKey:WCAtlasFishAudioModelKey]);
    return [WCAtlasFishAudioSupportedModels() containsObject:model]
        ? model : WCAtlasFishAudioDefaultModel;
}

void WCAtlasSetFishAudioModel(NSString *model) {
    NSString *value = WCAtlasTTSTrimmedString(model);
    if (![WCAtlasFishAudioSupportedModels() containsObject:value]) value = WCAtlasFishAudioDefaultModel;
    [NSUserDefaults.standardUserDefaults setObject:value forKey:WCAtlasFishAudioModelKey];
}

NSString *WCAtlasFishAudioReferenceID(void) {
    return WCAtlasTTSTrimmedString(
        [NSUserDefaults.standardUserDefaults stringForKey:WCAtlasFishAudioReferenceIDKey]);
}

void WCAtlasSetFishAudioReferenceID(NSString *referenceID) {
    NSString *value = WCAtlasTTSTrimmedString(referenceID);
    if (value.length > 0) {
        [NSUserDefaults.standardUserDefaults setObject:value forKey:WCAtlasFishAudioReferenceIDKey];
    } else {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:WCAtlasFishAudioReferenceIDKey];
    }
}

static NSArray<NSDictionary<NSString *, NSString *> *> *WCAtlasFishAudioBundledVoicePresets(void) {
    return @[
        @{@"name": @"三角洲蜂医", @"referenceID": @"5c0256430d8345d4a9e2d619f50d1b1a"},
        @{@"name": @"御姐音", @"referenceID": @"c028181136d145a5b335c3c5c8f6d61f"},
        @{@"name": @"杨幂", @"referenceID": @"fc46c64b5e274c97b7d207724f2020cf"}
    ];
}

static NSArray<NSDictionary<NSString *, NSString *> *> *WCAtlasFishAudioNormalizedVoicePresets(id value) {
    if (![value isKindOfClass:NSArray.class]) return @[];
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *presets = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    for (id item in (NSArray *)value) {
        if (![item isKindOfClass:NSDictionary.class]) continue;
        NSString *name = WCAtlasTTSTrimmedString(item[@"name"]);
        NSString *referenceID = WCAtlasTTSTrimmedString(item[@"referenceID"]);
        if (name.length == 0 || referenceID.length == 0 || [seen containsObject:referenceID]) continue;
        [seen addObject:referenceID];
        [presets addObject:@{@"name": name, @"referenceID": referenceID}];
    }
    return presets;
}

NSArray<NSDictionary<NSString *, NSString *> *> *WCAtlasFishAudioVoicePresets(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (![defaults boolForKey:WCAtlasFishAudioVoicePresetsSeededKey]) {
        [defaults setObject:WCAtlasFishAudioBundledVoicePresets() forKey:WCAtlasFishAudioVoicePresetsKey];
        [defaults setBool:YES forKey:WCAtlasFishAudioVoicePresetsSeededKey];
    }
    NSArray *presets = WCAtlasFishAudioNormalizedVoicePresets(
        [defaults arrayForKey:WCAtlasFishAudioVoicePresetsKey]);
    return presets ?: @[];
}

BOOL WCAtlasAddFishAudioVoicePreset(NSString *name, NSString *referenceID) {
    NSString *normalizedName = WCAtlasTTSTrimmedString(name);
    NSString *normalizedID = WCAtlasTTSTrimmedString(referenceID);
    if (normalizedName.length == 0 || normalizedID.length == 0) return NO;
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *presets =
        [WCAtlasFishAudioVoicePresets() mutableCopy];
    NSIndexSet *duplicates = [presets indexesOfObjectsPassingTest:
        ^BOOL(NSDictionary<NSString *, NSString *> *item, NSUInteger index, BOOL *stop) {
            (void)index; (void)stop;
            return [item[@"referenceID"] isEqualToString:normalizedID];
        }];
    [presets removeObjectsAtIndexes:duplicates];
    [presets addObject:@{@"name": normalizedName, @"referenceID": normalizedID}];
    [NSUserDefaults.standardUserDefaults setObject:presets forKey:WCAtlasFishAudioVoicePresetsKey];
    return YES;
}

void WCAtlasRemoveFishAudioVoicePreset(NSString *referenceID) {
    NSString *normalizedID = WCAtlasTTSTrimmedString(referenceID);
    if (normalizedID.length == 0) return;
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *presets =
        [WCAtlasFishAudioVoicePresets() mutableCopy];
    NSIndexSet *matches = [presets indexesOfObjectsPassingTest:
        ^BOOL(NSDictionary<NSString *, NSString *> *item, NSUInteger index, BOOL *stop) {
            (void)index; (void)stop;
            return [item[@"referenceID"] isEqualToString:normalizedID];
        }];
    [presets removeObjectsAtIndexes:matches];
    [NSUserDefaults.standardUserDefaults setObject:presets forKey:WCAtlasFishAudioVoicePresetsKey];
    if ([WCAtlasFishAudioReferenceID() isEqualToString:normalizedID]) {
        WCAtlasSetFishAudioReferenceID(nil);
    }
}

static NSString *WCAtlasFishAudioErrorMessage(NSHTTPURLResponse *response, NSData *data) {
    NSInteger status = response.statusCode;
    NSString *message = nil;
    if (data.length > 0) {
        id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([JSON isKindOfClass:NSDictionary.class]) {
            id value = JSON[@"message"] ?: JSON[@"detail"] ?: JSON[@"error"];
            if ([value isKindOfClass:NSString.class]) message = WCAtlasTTSTrimmedString(value);
        }
    }
    if (message.length > 0) return message;
    switch (status) {
        case 401: return @"Fish Audio API Key 无效或已失效";
        case 402: return @"Fish Audio 免费额度或账户余额不足";
        case 422: return @"Fish Audio 参数或音色 ID 不受支持";
        case 429: return @"Fish Audio 请求过于频繁，请稍后重试";
        default: return [NSString stringWithFormat:@"Fish Audio 请求失败（HTTP %ld）", (long)status];
    }
}

void WCAtlasGenerateFishAudioSpeech(NSString *text,
                                   void (^completion)(NSURL *outputURL, NSError *error)) {
    NSString *trimmed = WCAtlasTTSTrimmedString(text);
    void (^finish)(NSURL *, NSError *) = ^(NSURL *URL, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(URL, error); });
    };
    if (trimmed.length == 0) {
        finish(nil, WCAtlasTTSError(1, @"请输入需要合成的文字"));
        return;
    }
    if (trimmed.length > 1000) {
        finish(nil, WCAtlasTTSError(2, @"单次 TTS 最多支持 1000 个字符"));
        return;
    }
    NSString *APIKey = WCAtlasFishAudioAPIKey();
    if (APIKey.length == 0) {
        finish(nil, WCAtlasTTSError(3, @"请先设置 Fish Audio API Key"));
        return;
    }
    NSURL *URL = [NSURL URLWithString:@"https://api.fish.audio/v1/tts"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
        cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:90.0];
    request.HTTPMethod = @"POST";
    [request setValue:[@"Bearer " stringByAppendingString:APIKey] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"audio/mpeg" forHTTPHeaderField:@"Accept"];
    [request setValue:WCAtlasFishAudioModel() forHTTPHeaderField:@"model"];
    NSMutableDictionary *body = [@{
        @"text": trimmed,
        @"format": @"mp3",
        @"sample_rate": @44100,
        @"mp3_bitrate": @128,
        @"normalize": @YES,
        @"latency": @"normal",
        @"prosody": @{
            @"speed": @1.0,
            @"volume": @0,
            @"normalize_loudness": @YES
        }
    } mutableCopy];
    NSString *referenceID = WCAtlasFishAudioReferenceID();
    if (referenceID.length > 0) body[@"reference_id"] = referenceID;
    NSError *JSONError = nil;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:&JSONError];
    if (!request.HTTPBody) {
        finish(nil, JSONError ?: WCAtlasTTSError(4, @"无法创建 Fish Audio 请求"));
        return;
    }
    NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    configuration.timeoutIntervalForRequest = 90.0;
    configuration.timeoutIntervalForResource = 120.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
            [session finishTasksAndInvalidate];
            if (networkError) {
                finish(nil, WCAtlasTTSError(5, networkError.localizedDescription ?: @"Fish Audio 网络请求失败"));
                return;
            }
            NSHTTPURLResponse *HTTPResponse = [response isKindOfClass:NSHTTPURLResponse.class]
                ? (NSHTTPURLResponse *)response : nil;
            if (!HTTPResponse || HTTPResponse.statusCode < 200 || HTTPResponse.statusCode >= 300) {
                finish(nil, WCAtlasTTSError(6, WCAtlasFishAudioErrorMessage(HTTPResponse, data)));
                return;
            }
            if (data.length < 128) {
                finish(nil, WCAtlasTTSError(7, @"Fish Audio 没有返回有效音频"));
                return;
            }
            NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"WCAtlasTTS"];
            NSError *fileError = nil;
            if (![NSFileManager.defaultManager createDirectoryAtPath:directory
                                         withIntermediateDirectories:YES attributes:nil error:&fileError]) {
                finish(nil, fileError ?: WCAtlasTTSError(8, @"无法创建 TTS 临时目录"));
                return;
            }
            NSURL *outputURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:
                [NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"mp3"]]];
            if (![data writeToURL:outputURL options:NSDataWritingAtomic error:&fileError]) {
                finish(nil, fileError ?: WCAtlasTTSError(9, @"无法保存 Fish Audio 音频"));
                return;
            }
            finish(outputURL, nil);
        }];
    [task resume];
}
