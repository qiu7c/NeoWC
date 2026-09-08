#import "NeoWCAutomation.h"
#import "NeoWCBackgroundKeeper.h"
#import "NeoWCLogging.h"
#import "NeoWCPrivateAPI.h"
#import "NeoWCQuickReplyStore.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <UIKit/UIKit.h>

static NSString *const NeoWCAutomationTasksKey = @"com.qiu7c.neowc.automation.tasks.v1";
static NSString *const NeoWCAutomationSeedVersionKey = @"com.qiu7c.neowc.automation.seed-version";
static const NSUInteger NeoWCAutomationMaximumResponseBytes = 1024 * 1024;

@implementation NeoWCAutomationTask

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    _identifier = NSUUID.UUID.UUIDString.lowercaseString;
    _name = @"定时消息";
    _targetUserName = @"";
    _enabled = YES;
    _sourceType = NeoWCAutomationSourceTypeFixedText;
    _fixedText = @"";
    _script = @"function main(input) {\n  return \"定时消息\";\n}";
    _nextFireDate = [NSDate dateWithTimeIntervalSinceNow:300.0];
    _repeatMode = NeoWCAutomationRepeatModeOnce;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    NeoWCAutomationTask *task = [[[self class] allocWithZone:zone] init];
    task.identifier = self.identifier;
    task.name = self.name;
    task.targetUserName = self.targetUserName;
    task.enabled = self.enabled;
    task.sourceType = self.sourceType;
    task.fixedText = self.fixedText;
    task.libraryItemIdentifier = self.libraryItemIdentifier;
    task.script = self.script;
    task.nextFireDate = self.nextFireDate;
    task.repeatMode = self.repeatMode;
    task.lastRunDate = self.lastRunDate;
    task.lastResult = self.lastResult;
    return task;
}

@end

@interface NeoWCAutomationManager ()
@property (nonatomic, strong) NSMutableArray<NeoWCAutomationTask *> *mutableTasks;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) dispatch_queue_t scriptQueue;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) NSUInteger activeExecutions;
@end

@implementation NeoWCAutomationManager

+ (instancetype)sharedManager {
    static NeoWCAutomationManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    _scriptQueue = dispatch_queue_create("com.qiu7c.neowc.automation-scripts", DISPATCH_QUEUE_SERIAL);
    _mutableTasks = [NSMutableArray array];
    [self loadTasks];
    return self;
}

static NSString *NeoWCAutomationString(id value) {
    if (![value isKindOfClass:NSString.class]) return @"";
    return [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

- (NeoWCAutomationTask *)taskFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:NSDictionary.class]) return nil;
    NSString *identifier = NeoWCAutomationString(dictionary[@"id"]);
    if (identifier.length == 0) return nil;
    NeoWCAutomationTask *task = [NeoWCAutomationTask new];
    task.identifier = identifier;
    task.name = NeoWCAutomationString(dictionary[@"name"]);
    task.targetUserName = NeoWCAutomationString(dictionary[@"target"]);
    task.enabled = [dictionary[@"enabled"] boolValue];
    task.sourceType = MAX(NeoWCAutomationSourceTypeFixedText,
                          MIN(NeoWCAutomationSourceTypeJavaScript, [dictionary[@"source"] integerValue]));
    task.fixedText = [dictionary[@"text"] isKindOfClass:NSString.class] ? dictionary[@"text"] : @"";
    task.libraryItemIdentifier = NeoWCAutomationString(dictionary[@"library"]);
    task.script = [dictionary[@"script"] isKindOfClass:NSString.class] ? dictionary[@"script"] : @"";
    NSTimeInterval fire = [dictionary[@"nextFire"] doubleValue];
    task.nextFireDate = fire > 0 ? [NSDate dateWithTimeIntervalSince1970:fire] : NSDate.date;
    task.repeatMode = [dictionary[@"repeat"] integerValue] == NeoWCAutomationRepeatModeDaily
        ? NeoWCAutomationRepeatModeDaily : NeoWCAutomationRepeatModeOnce;
    NSTimeInterval lastRun = [dictionary[@"lastRun"] doubleValue];
    task.lastRunDate = lastRun > 0 ? [NSDate dateWithTimeIntervalSince1970:lastRun] : nil;
    task.lastResult = [dictionary[@"lastResult"] isKindOfClass:NSString.class]
        ? dictionary[@"lastResult"] : nil;
    return task;
}

- (NSDictionary *)dictionaryForTask:(NeoWCAutomationTask *)task {
    NSMutableDictionary *dictionary = [@{
        @"id": task.identifier ?: @"",
        @"name": task.name ?: @"",
        @"target": task.targetUserName ?: @"",
        @"enabled": @(task.isEnabled),
        @"source": @(task.sourceType),
        @"text": task.fixedText ?: @"",
        @"script": task.script ?: @"",
        @"nextFire": @((task.nextFireDate ?: NSDate.date).timeIntervalSince1970),
        @"repeat": @(task.repeatMode),
    } mutableCopy];
    if (task.libraryItemIdentifier.length) dictionary[@"library"] = task.libraryItemIdentifier;
    if (task.lastRunDate) dictionary[@"lastRun"] = @(task.lastRunDate.timeIntervalSince1970);
    if (task.lastResult.length) dictionary[@"lastResult"] = task.lastResult;
    return dictionary;
}

- (void)loadTasks {
    NSArray *saved = [NSUserDefaults.standardUserDefaults arrayForKey:NeoWCAutomationTasksKey];
    for (NSDictionary *dictionary in saved ?: @[]) {
        NeoWCAutomationTask *task = [self taskFromDictionary:dictionary];
        if (task) [self.mutableTasks addObject:task];
    }
    if ([NSUserDefaults.standardUserDefaults integerForKey:NeoWCAutomationSeedVersionKey] < 1) {
        NeoWCAutomationTask *sample = [NeoWCAutomationTask new];
        sample.name = @"示例：三角洲每日密码";
        sample.enabled = NO;
        sample.sourceType = NeoWCAutomationSourceTypeJavaScript;
        sample.repeatMode = NeoWCAutomationRepeatModeDaily;
        sample.script = @"function main(input) {\n"
            @"  var raw = httpGet('https://ovoy.cc/1.php');\n"
            @"  var data = JSON.parse(raw);\n"
            @"  if (!data.success || !data.passwords) throw new Error('接口未返回有效密码');\n"
            @"  var lines = ['三角洲每日密码 ' + (data.date || '')];\n"
            @"  Object.keys(data.passwords).forEach(function(name) {\n"
            @"    lines.push(name + '：' + data.passwords[name]);\n"
            @"  });\n"
            @"  return lines.join('\\n');\n"
            @"}";
        [self.mutableTasks addObject:sample];
        [NSUserDefaults.standardUserDefaults setInteger:1 forKey:NeoWCAutomationSeedVersionKey];
        [self persistTasks];
    }
}

- (void)updateBackgroundRequirement {
    BOOL required = self.activeExecutions > 0;
    for (NeoWCAutomationTask *task in self.mutableTasks) {
        if (task.isEnabled) {
            required = YES;
            break;
        }
    }
    NeoWCBackgroundKeeperSetAutomationRequired(required);
}

- (void)persistTasks {
    NSMutableArray *records = [NSMutableArray arrayWithCapacity:self.mutableTasks.count];
    for (NeoWCAutomationTask *task in self.mutableTasks) [records addObject:[self dictionaryForTask:task]];
    [NSUserDefaults.standardUserDefaults setObject:records forKey:NeoWCAutomationTasksKey];
}

- (NSArray<NeoWCAutomationTask *> *)tasks {
    NSMutableArray *copies = [NSMutableArray arrayWithCapacity:self.mutableTasks.count];
    for (NeoWCAutomationTask *task in self.mutableTasks) [copies addObject:task.copy];
    return copies;
}

- (void)start {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self start]; });
        return;
    }
    if (self.started) return;
    self.started = YES;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification object:nil];
    self.timer = [NSTimer timerWithTimeInterval:10.0 target:self
                                      selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
    [self updateBackgroundRequirement];
    [self runDueTasks];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    (void)notification;
    [self runDueTasks];
}

- (void)timerFired:(NSTimer *)timer {
    (void)timer;
    [self runDueTasks];
}

- (void)saveTask:(NeoWCAutomationTask *)task {
    if (!task.identifier.length) task.identifier = NSUUID.UUID.UUIDString.lowercaseString;
    NSUInteger index = [self.mutableTasks indexOfObjectPassingTest:^BOOL(NeoWCAutomationTask *candidate,
                                                                         NSUInteger idx,
                                                                         BOOL *stop) {
        (void)idx;
        (void)stop;
        return [candidate.identifier isEqualToString:task.identifier];
    }];
    if (index == NSNotFound) [self.mutableTasks addObject:task.copy];
    else self.mutableTasks[index] = task.copy;
    [self persistTasks];
    [self updateBackgroundRequirement];
    [self runDueTasks];
}

- (void)deleteTaskWithIdentifier:(NSString *)identifier {
    NSIndexSet *indexes = [self.mutableTasks indexesOfObjectsPassingTest:^BOOL(NeoWCAutomationTask *task,
                                                                               NSUInteger idx,
                                                                               BOOL *stop) {
        (void)idx;
        (void)stop;
        return [task.identifier isEqualToString:identifier];
    }];
    if (indexes.count) {
        [self.mutableTasks removeObjectsAtIndexes:indexes];
        [self persistTasks];
        [self updateBackgroundRequirement];
    }
}

- (NeoWCAutomationTask *)storedTaskWithIdentifier:(NSString *)identifier {
    for (NeoWCAutomationTask *task in self.mutableTasks) {
        if ([task.identifier isEqualToString:identifier]) return task;
    }
    return nil;
}

- (NSString *)libraryTextForTask:(NeoWCAutomationTask *)task {
    for (NeoWCQuickReplyItem *item in NeoWCQuickReplyStore.sharedStore.items) {
        if ([item.identifier isEqualToString:task.libraryItemIdentifier] &&
            item.type == NeoWCQuickReplyTypeText) return item.text;
    }
    return nil;
}

static NSString *NeoWCAutomationHTTPRequest(NSString *method,
                                             NSString *URLString,
                                             NSString *body,
                                             NSString *contentType,
                                             NSInteger *statusCode,
                                             NSString **failureReason) {
    NSURL *URL = [NSURL URLWithString:NeoWCAutomationString(URLString)];
    NSString *scheme = URL.scheme.lowercaseString;
    if (!URL || (![@"http" isEqualToString:scheme] && ![@"https" isEqualToString:scheme])) {
        if (failureReason) *failureReason = @"HTTP 地址无效";
        return nil;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:20.0];
    request.HTTPMethod = method;
    if (body) {
        request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
        [request setValue:contentType.length ? contentType : @"application/json; charset=utf-8"
       forHTTPHeaderField:@"Content-Type"];
    }
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *responseData = nil;
    __block NSURLResponse *response = nil;
    __block NSError *responseError = nil;
    NSURLSessionDataTask *dataTask = [NSURLSession.sharedSession
        dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *URLResponse, NSError *error) {
        responseData = data;
        response = URLResponse;
        responseError = error;
        dispatch_semaphore_signal(semaphore);
    }];
    [dataTask resume];
    if (dispatch_semaphore_wait(semaphore,
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(22.0 * NSEC_PER_SEC))) != 0) {
        [dataTask cancel];
        if (failureReason) *failureReason = @"HTTP 请求超时";
        return nil;
    }
    if (responseError) {
        if (failureReason) *failureReason = responseError.localizedDescription;
        return nil;
    }
    if (responseData.length > NeoWCAutomationMaximumResponseBytes) {
        if (failureReason) *failureReason = @"HTTP 响应超过 1 MB";
        return nil;
    }
    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (statusCode) *statusCode = code;
        if (code < 200 || code >= 300) {
            if (failureReason) *failureReason = [NSString stringWithFormat:@"HTTP 状态码 %ld", (long)code];
            return nil;
        }
    }
    NSString *text = [[NSString alloc] initWithData:responseData ?: NSData.data
                                           encoding:NSUTF8StringEncoding];
    if (!text && failureReason) *failureReason = @"HTTP 响应不是 UTF-8 文本";
    return text;
}

- (NSString *)executeScript:(NSString *)script target:(NSString *)target error:(NSString **)error {
    if (script.length == 0) {
        if (error) *error = @"JS 脚本为空";
        return nil;
    }
    JSContext *context = [[JSContext alloc] init];
    __block NSString *HTTPFailure = nil;
    context.exceptionHandler = ^(JSContext *ctx, JSValue *exception) {
        HTTPFailure = exception.toString ?: @"JavaScript 执行异常";
        ctx.exception = exception;
    };
    context[@"httpGet"] = ^NSString *(id URLValue) {
        NSInteger status = 0;
        NSString *failure = nil;
        NSString *value = NeoWCAutomationHTTPRequest(@"GET", NeoWCAutomationString(URLValue),
                                                      nil, nil, &status, &failure);
        HTTPFailure = failure;
        return value ?: @"";
    };
    context[@"httpPost"] = ^NSString *(id URLValue, id bodyValue, id contentTypeValue) {
        NSInteger status = 0;
        NSString *failure = nil;
        NSString *body = [bodyValue isKindOfClass:NSString.class] ? bodyValue : @"";
        NSString *contentType = [contentTypeValue isKindOfClass:NSString.class] ? contentTypeValue : nil;
        NSString *value = NeoWCAutomationHTTPRequest(@"POST", NeoWCAutomationString(URLValue),
                                                      body, contentType, &status, &failure);
        HTTPFailure = failure;
        return value ?: @"";
    };
    JSValue *evaluation = [context evaluateScript:script withSourceURL:
        [NSURL URLWithString:@"neowc-automation://task.js"]];
    if (context.exception) {
        if (error) *error = context.exception.toString ?: @"JavaScript 执行失败";
        return nil;
    }
    JSValue *main = context[@"main"];
    JSValue *result = main.isObject
        ? [main callWithArguments:@[@{ @"target": target ?: @"",
                                      @"timestamp": @((long long)NSDate.date.timeIntervalSince1970) }]]
        : evaluation;
    if (context.exception) {
        if (error) *error = context.exception.toString ?: @"JavaScript main 执行失败";
        return nil;
    }
    NSString *text = result.isString ? result.toString : nil;
    text = NeoWCAutomationString(text);
    if (text.length == 0) {
        if (error) *error = HTTPFailure ?: @"JS 必须返回非空字符串";
        return nil;
    }
    return text;
}

- (void)finishTaskIdentifier:(NSString *)identifier
                      target:(NSString *)target
                        text:(NSString *)text
                       error:(NSString *)error {
    NeoWCAutomationTask *stored = [self storedTaskWithIdentifier:identifier];
    if (!stored) {
        if (self.activeExecutions > 0) self.activeExecutions--;
        [self updateBackgroundRequirement];
        return;
    }
    stored.lastRunDate = NSDate.date;
    stored.lastResult = error.length ? [@"失败：" stringByAppendingString:error] : @"正在提交";
    [self persistTasks];
    if (error.length) {
        NeoWCLog(@"自动任务 %@ 失败：%@", identifier, error);
        if (self.activeExecutions > 0) self.activeExecutions--;
        [self updateBackgroundRequirement];
        return;
    }
    BOOL submitted = NeoWCPrivateSendTextMessage(target, text);
    NSString *result = submitted ? @"已提交发送" : @"失败：微信发送接口不可用";
    stored.lastResult = result;
    [self persistTasks];
    NeoWCLog(@"自动任务 %@ %@", identifier, result);
    if (self.activeExecutions > 0) self.activeExecutions--;
    [self updateBackgroundRequirement];
}

- (void)executeTask:(NeoWCAutomationTask *)task {
    NSString *target = NeoWCAutomationString(task.targetUserName);
    if (target.length == 0) {
        [self finishTaskIdentifier:task.identifier target:target text:nil error:@"目标用户为空"];
        return;
    }
    if (task.sourceType == NeoWCAutomationSourceTypeFixedText) {
        NSString *text = NeoWCAutomationString(task.fixedText);
        [self finishTaskIdentifier:task.identifier target:target text:text
                             error:text.length ? nil : @"固定文本为空"];
        return;
    }
    if (task.sourceType == NeoWCAutomationSourceTypeLibraryText) {
        NSString *text = NeoWCAutomationString([self libraryTextForTask:task]);
        [self finishTaskIdentifier:task.identifier target:target text:text
                             error:text.length ? nil : @"消息库文字素材不存在"];
        return;
    }
    NSString *identifier = task.identifier;
    NSString *script = task.script;
    dispatch_async(self.scriptQueue, ^{
        NSString *scriptError = nil;
        NSString *text = [self executeScript:script target:target error:&scriptError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishTaskIdentifier:identifier target:target text:text error:scriptError];
        });
    });
}

- (NSDate *)nextDailyDateAfterDate:(NSDate *)date now:(NSDate *)now {
    NSDate *candidate = date ?: now;
    NSCalendar *calendar = NSCalendar.currentCalendar;
    do {
        candidate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:candidate options:0];
    } while ([candidate compare:now] != NSOrderedDescending);
    return candidate;
}

- (void)runDueTasks {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self runDueTasks]; });
        return;
    }
    NSDate *now = NSDate.date;
    NSMutableArray<NeoWCAutomationTask *> *due = [NSMutableArray array];
    for (NeoWCAutomationTask *task in self.mutableTasks) {
        if (!task.isEnabled || [task.nextFireDate compare:now] == NSOrderedDescending) continue;
        [due addObject:task.copy];
        if (task.repeatMode == NeoWCAutomationRepeatModeDaily) {
            task.nextFireDate = [self nextDailyDateAfterDate:task.nextFireDate now:now];
        } else {
            task.enabled = NO;
        }
    }
    if (due.count) {
        self.activeExecutions += due.count;
        [self persistTasks];
        [self updateBackgroundRequirement];
    }
    for (NeoWCAutomationTask *task in due) {
        [self executeTask:task];
    }
}

- (void)runTaskNow:(NeoWCAutomationTask *)task {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self runTaskNow:task]; });
        return;
    }
    self.activeExecutions++;
    [self updateBackgroundRequirement];
    [self executeTask:task.copy];
}

@end

void NeoWCAutomationStart(void) {
    [NeoWCAutomationManager.sharedManager start];
}
