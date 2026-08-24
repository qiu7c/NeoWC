#import "NeoWCDebug.h"
#import "NeoWCInterfaceTweaks.h"
#import "NeoWCCardTableViewController.h"
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <stdint.h>
#import <stdlib.h>

NSString *const NeoWCDebugFloatingEnabledKey = @"com.qiu7c.neowc.debug.floating-enabled";
NSString *const NeoWCDebugLoggingEnabledKey = @"com.qiu7c.neowc.debug.logging-enabled";
NSString *const NeoWCPaymentLinkDiagnosticsEnabledKey = @"com.qiu7c.neowc.debug.payment-link-diagnostics-enabled";
static NSString *const NeoWCDebugFloatingSideKey = @"com.qiu7c.neowc.debug.floating-side";
static NSString *const NeoWCDebugFloatingVerticalPositionKey = @"com.qiu7c.neowc.debug.floating-vertical-position";

static NSString *const NeoWCDebugLogDidChangeNotification = @"NeoWCDebugLogDidChangeNotification";

@interface NeoWCDebugLogStore : NSObject
@property (nonatomic, strong) NSMutableArray<NSString *> *entries;
+ (instancetype)sharedStore;
- (void)appendMessage:(NSString *)message;
- (NSArray<NSString *> *)snapshot;
- (void)clear;
@end

@implementation NeoWCDebugLogStore

+ (instancetype)sharedStore {
    static NeoWCDebugLogStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [NeoWCDebugLogStore new];
        store.entries = [NSMutableArray array];
    });
    return store;
}

- (void)appendMessage:(NSString *)message {
    if (!message) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        static NSDateFormatter *formatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            formatter = [NSDateFormatter new];
            formatter.dateFormat = @"HH:mm:ss.SSS";
        });
        NSString *line = [NSString stringWithFormat:@"[%@] %@", [formatter stringFromDate:[NSDate date]], message];
        [self.entries addObject:line];
        if (self.entries.count > 500) {
            [self.entries removeObjectsInRange:NSMakeRange(0, self.entries.count - 500)];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCDebugLogDidChangeNotification object:nil];
    });
}

- (NSArray<NSString *> *)snapshot {
    return [self.entries copy];
}

- (void)clear {
    [self.entries removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCDebugLogDidChangeNotification object:nil];
}

@end

void NeoWCLog(NSString *format, ...) {
    if (!format) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:NeoWCDebugLoggingEnabledKey] &&
        ![defaults boolForKey:NeoWCDebugLoggingEnabledKey]) return;
    va_list arguments;
    va_start(arguments, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    [[NeoWCDebugLogStore sharedStore] appendMessage:message];
}

void NeoWCLogAlways(NSString *format, ...) {
    if (!format) return;
    va_list arguments;
    va_start(arguments, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    [[NeoWCDebugLogStore sharedStore] appendMessage:message];
}

static NSTimeInterval NeoWCPaymentLinkDiagnosticsCorrelationDeadline = 0;

static BOOL NeoWCPaymentLinkDiagnosticsEnabled(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCPaymentLinkDiagnosticsEnabledKey];
}

static NSString *NeoWCDiagnosticFingerprintForData(NSData *data) {
    if (![data isKindOfClass:NSData.class]) return @"-";
    static uint64_t processSalt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        processSalt = ((uint64_t)arc4random() << 32) | arc4random();
    });
    const uint8_t *bytes = data.bytes;
    uint64_t value = UINT64_C(1469598103934665603) ^ processSalt;
    for (NSUInteger index = 0; index < data.length; index++) {
        value ^= bytes[index];
        value *= UINT64_C(1099511628211);
    }
    return [NSString stringWithFormat:@"%016llx", (unsigned long long)value];
}

static NSString *NeoWCDiagnosticFingerprintForString(NSString *string) {
    if (![string isKindOfClass:NSString.class]) return @"-";
    return NeoWCDiagnosticFingerprintForData([string dataUsingEncoding:NSUTF8StringEncoding]);
}

static NSString *NeoWCDiagnosticStringSummary(id value);

static NSString *NeoWCDiagnosticJSONShape(id object, NSUInteger depth) {
    if (!object || object == NSNull.null) return @"null";
    if (depth >= 4) return @"…";
    if ([object isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictionary = object;
        NSArray *keys = [[dictionary allKeys] sortedArrayUsingComparator:^NSComparisonResult(id left, id right) {
            return [[left description] compare:[right description]];
        }];
        NSMutableArray *parts = [NSMutableArray arrayWithCapacity:keys.count];
        for (id key in keys) {
            [parts addObject:[NSString stringWithFormat:@"%@:%@", [key description],
                              NeoWCDiagnosticJSONShape(dictionary[key], depth + 1)]];
        }
        return [NSString stringWithFormat:@"{%@}", [parts componentsJoinedByString:@","]];
    }
    if ([object isKindOfClass:NSArray.class]) {
        NSArray *array = object;
        NSString *first = array.count ? NeoWCDiagnosticJSONShape(array.firstObject, depth + 1) : @"";
        return [NSString stringWithFormat:@"array(%lu)[%@]", (unsigned long)array.count, first];
    }
    if ([object isKindOfClass:NSString.class]) {
        NSString *string = object;
        NSData *nestedData = [string dataUsingEncoding:NSUTF8StringEncoding];
        id nested = nestedData.length ? [NSJSONSerialization JSONObjectWithData:nestedData options:0 error:nil] : nil;
        if (nested) return [NSString stringWithFormat:@"json-string(%lu)%@", (unsigned long)string.length,
                            NeoWCDiagnosticJSONShape(nested, depth + 1)];
        return [NSString stringWithFormat:@"string(%lu,#%@)", (unsigned long)string.length,
                NeoWCDiagnosticFingerprintForString(string)];
    }
    if ([object isKindOfClass:NSNumber.class]) {
        if (CFGetTypeID((__bridge CFTypeRef)object) == CFBooleanGetTypeID()) return @"bool";
        return [NSString stringWithFormat:@"number(#%@)",
                NeoWCDiagnosticFingerprintForString([(NSNumber *)object stringValue])];
    }
    return NSStringFromClass([object class]) ?: @"object";
}

static NSString *NeoWCDiagnosticBodyShape(NSData *data) {
    if (![data isKindOfClass:NSData.class] || data.length == 0) return @"none";
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *shape = object ? NeoWCDiagnosticJSONShape(object, 0) : @"non-json";
    return [NSString stringWithFormat:@"len=%lu hash=%@ shape=%@", (unsigned long)data.length,
            NeoWCDiagnosticFingerprintForData(data), shape];
}

static id NeoWCDiagnosticSafeValue(id object, NSString *key) {
    if (!object || !key.length) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

BOOL NeoWCPaymentLinkDiagnosticsMatchesRequest(NSURLRequest *request) {
    if (!NeoWCPaymentLinkDiagnosticsEnabled() || ![request isKindOfClass:NSURLRequest.class]) return NO;
    NSURL *URL = request.URL;
    return [[URL.host lowercaseString] isEqualToString:@"sjtmgr.wxpapp.weixin.qq.com"] &&
           [URL.path hasPrefix:@"/sjt/linkqrcode/"];
}

void NeoWCPaymentLinkDiagnosticsRecordCommandText(NSString *text) {
    if (!NeoWCPaymentLinkDiagnosticsEnabled() || ![text isKindOfClass:NSString.class]) return;
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *delimiter = [trimmed hasPrefix:@"#付款:"] ? @":" :
                          ([trimmed hasPrefix:@"#付款："] ? @"：" : nil);
    if (!delimiter) return;
    NSArray<NSString *> *parts = [trimmed componentsSeparatedByString:@"/"];
    if (parts.count < 3) return;
    NSRange delimiterRange = [parts.firstObject rangeOfString:delimiter];
    if (delimiterRange.location == NSNotFound) return;
    NSString *identity = [parts.firstObject substringFromIndex:NSMaxRange(delimiterRange)];
    NSString *displayName = identity;
    NSString *wechatID = nil;
    NSRange opening = [identity rangeOfString:@"(" options:NSBackwardsSearch];
    if (opening.location != NSNotFound && [identity hasSuffix:@")"] && opening.location + 1 < identity.length) {
        displayName = [identity substringToIndex:opening.location];
        wechatID = [identity substringWithRange:NSMakeRange(NSMaxRange(opening), identity.length - NSMaxRange(opening) - 1)];
    }
    NSString *fingerprint = NeoWCDiagnosticFingerprintForString(trimmed);
    static NSString *lastFingerprint;
    @synchronized (NSUserDefaults.class) {
        if ([lastFingerprint isEqualToString:fingerprint]) return;
        lastFingerprint = fingerprint;
    }
    NeoWCLogAlways(@"[收款诊断] command parts=%lu name(%@) wechatID(%@) title(%@) number(%@)",
                   (unsigned long)parts.count, NeoWCDiagnosticStringSummary(displayName),
                   NeoWCDiagnosticStringSummary(wechatID), NeoWCDiagnosticStringSummary(parts[1]),
                   NeoWCDiagnosticStringSummary(parts[2]));
}

void NeoWCPaymentLinkDiagnosticsRecordRequest(NSURLRequest *request, NSData *uploadData) {
    if (!NeoWCPaymentLinkDiagnosticsMatchesRequest(request)) return;
    NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    NSMutableArray *queryNames = [NSMutableArray array];
    for (NSURLQueryItem *item in components.queryItems ?: @[]) {
        if (item.name.length) [queryNames addObject:item.name];
    }
    NSArray *headerNames = [[request.allHTTPHeaderFields allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSData *body = uploadData ?: request.HTTPBody;
    @synchronized (NSUserDefaults.class) {
        NeoWCPaymentLinkDiagnosticsCorrelationDeadline = [NSDate timeIntervalSinceReferenceDate] + 60.0;
    }
    NeoWCLogAlways(@"[收款诊断] request method=%@ path=%@ queryKeys=%@ headerKeys=%@ body(%@)",
                   request.HTTPMethod ?: @"-", request.URL.path ?: @"-", queryNames, headerNames,
                   NeoWCDiagnosticBodyShape(body));
}

void NeoWCPaymentLinkDiagnosticsRecordResponse(NSURLRequest *request, NSData *data,
                                                NSURLResponse *response, NSError *error) {
    if (!NeoWCPaymentLinkDiagnosticsMatchesRequest(request)) return;
    NSInteger statusCode = [response isKindOfClass:NSHTTPURLResponse.class] ?
        ((NSHTTPURLResponse *)response).statusCode : 0;
    NeoWCLogAlways(@"[收款诊断] response status=%ld errorDomain=%@ errorCode=%ld data(%@)",
                   (long)statusCode, error.domain ?: @"-", (long)error.code,
                   NeoWCDiagnosticBodyShape(data));
}

BOOL NeoWCPaymentLinkDiagnosticsCorrelationActive(void) {
    if (!NeoWCPaymentLinkDiagnosticsEnabled()) return NO;
    @synchronized (NSUserDefaults.class) {
        return NeoWCPaymentLinkDiagnosticsCorrelationDeadline > [NSDate timeIntervalSinceReferenceDate];
    }
}

static NSString *NeoWCDiagnosticStringSummary(id value) {
    if (![value isKindOfClass:NSString.class]) return @"-";
    NSString *string = value;
    return [NSString stringWithFormat:@"len=%lu,#%@", (unsigned long)string.length,
            NeoWCDiagnosticFingerprintForString(string)];
}

static NSString *NeoWCDiagnosticXMLShape(NSString *XML) {
    if (![XML isKindOfClass:NSString.class] || XML.length == 0) return @"[]";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"<\\s*([A-Za-z][A-Za-z0-9_]*)[^>]*>\\s*(?:<!\\[CDATA\\[)?([^<]*?)(?:\\]\\]>)?\\s*</\\s*\\1\\s*>" options:0 error:nil];
    NSMutableArray *fields = [NSMutableArray array];
    for (NSTextCheckingResult *match in [expression matchesInString:XML options:0 range:NSMakeRange(0, XML.length)]) {
        if (match.numberOfRanges <= 2) continue;
        NSString *tag = [XML substringWithRange:[match rangeAtIndex:1]];
        NSString *value = [XML substringWithRange:[match rangeAtIndex:2]];
        [fields addObject:[NSString stringWithFormat:@"%@(%@)", tag, NeoWCDiagnosticStringSummary(value)]];
    }
    return [fields description];
}

void NeoWCPaymentLinkDiagnosticsRecordAppMessage(NSString *entryPoint, id target, id wrap,
                                                  id dataOrPath, unsigned int scene) {
    if (!NeoWCPaymentLinkDiagnosticsCorrelationActive() || !wrap) return;
    id messageType = NeoWCDiagnosticSafeValue(wrap, @"m_uiMessageType");
    id innerType = NeoWCDiagnosticSafeValue(wrap, @"m_uiAppMsgInnerType");
    NSString *content = NeoWCDiagnosticSafeValue(wrap, @"m_nsContent");
    NSString *title = NeoWCDiagnosticSafeValue(wrap, @"m_nsTitle");
    NSString *desc = NeoWCDiagnosticSafeValue(wrap, @"m_nsDesc");
    NSString *appID = NeoWCDiagnosticSafeValue(wrap, @"m_nsAppID");
    NSString *appName = NeoWCDiagnosticSafeValue(wrap, @"m_nsAppName");
    NSString *msgSource = NeoWCDiagnosticSafeValue(wrap, @"m_nsMsgSource");
    id extension = NeoWCDiagnosticSafeValue(wrap, @"m_extendInfoWithMsgType");
    id extensionInnerType = NeoWCDiagnosticSafeValue(extension, @"m_uiAppMsgInnerType");
    NSString *extensionTitle = NeoWCDiagnosticSafeValue(extension, @"m_nsTitle");
    NSString *extensionDesc = NeoWCDiagnosticSafeValue(extension, @"m_nsDesc");
    NSString *extensionAppID = NeoWCDiagnosticSafeValue(extension, @"m_nsAppID");
    NSString *extensionAppName = NeoWCDiagnosticSafeValue(extension, @"m_nsAppName");
    NSString *extensionContent = NeoWCDiagnosticSafeValue(extension, @"m_nsContent");
    NSDictionary *flags = @{
        @"status": NeoWCDiagnosticSafeValue(wrap, @"m_uiStatus") ?: @"-",
        @"msgFlag": NeoWCDiagnosticSafeValue(wrap, @"m_uiMsgFlag") ?: @"-",
        @"new": NeoWCDiagnosticSafeValue(wrap, @"m_bNew") ?: @"-",
        @"imgStatus": NeoWCDiagnosticSafeValue(wrap, @"m_uiImgStatus") ?: @"-",
        @"forward": NeoWCDiagnosticSafeValue(wrap, @"m_bForward") ?: @"-",
        @"senderStatus": NeoWCDiagnosticSafeValue(wrap, @"m_uiIsSenderStatus") ?: @"-",
    };
    NSString *targetString = [target isKindOfClass:NSString.class] ? target : [target description];
    NSString *payloadClass = dataOrPath ? NSStringFromClass([dataOrPath class]) : @"nil";
    NSUInteger payloadLength = [dataOrPath respondsToSelector:@selector(length)] ?
        (NSUInteger)[dataOrPath length] : 0;
    NeoWCLogAlways(@"[收款诊断] appmsg entry=%@ scene=%u msgType=%@ innerType=%@ flags=%@ target(%@) title(%@) desc(%@) appID(%@) appName(%@) source(%@ fields=%@) extension=%@ extInnerType=%@ extTitle(%@) extDesc(%@) extAppID(%@) extAppName(%@) extContent(%@ fields=%@) xml(%@ fields=%@) payload=%@/%lu",
                   entryPoint ?: @"-", scene, messageType ?: @"-", innerType ?: @"-", flags,
                   NeoWCDiagnosticStringSummary(targetString), NeoWCDiagnosticStringSummary(title),
                   NeoWCDiagnosticStringSummary(desc), NeoWCDiagnosticStringSummary(appID),
                   NeoWCDiagnosticStringSummary(appName), NeoWCDiagnosticStringSummary(msgSource),
                   NeoWCDiagnosticXMLShape(msgSource),
                   extension ? NSStringFromClass([extension class]) : @"nil", extensionInnerType ?: @"-",
                   NeoWCDiagnosticStringSummary(extensionTitle), NeoWCDiagnosticStringSummary(extensionDesc),
                   NeoWCDiagnosticStringSummary(extensionAppID), NeoWCDiagnosticStringSummary(extensionAppName),
                   NeoWCDiagnosticStringSummary(extensionContent),
                   NeoWCDiagnosticXMLShape(extensionContent), NeoWCDiagnosticStringSummary(content),
                   NeoWCDiagnosticXMLShape(content), payloadClass,
                   (unsigned long)payloadLength);
}

@interface NeoWCDebugWindow : UIWindow
@property (nonatomic, assign) BOOL passesThroughBackgroundTouches;
@end
@implementation NeoWCDebugWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (self.passesThroughBackgroundTouches &&
        (hitView == self || hitView == self.rootViewController.view)) {
        return nil;
    }
    return hitView;
}
@end

@interface NeoWCPassthroughView : UIView
@end
@implementation NeoWCPassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    return hitView == self ? nil : hitView;
}
@end

static UIWindowScene *NeoWCActiveWindowScene(void) {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                return (UIWindowScene *)scene;
            }
        }
    }
    return nil;
}

static UIWindow *NeoWCMainWindow(void) {
    NSArray<UIWindow *> *windows = nil;
    UIWindowScene *scene = NeoWCActiveWindowScene();
    if (@available(iOS 13.0, *)) {
        windows = scene.windows;
    }
    if (windows.count == 0) windows = UIApplication.sharedApplication.windows;

    UIWindow *fallback = nil;
    for (UIWindow *window in [windows reverseObjectEnumerator]) {
        if ([window isKindOfClass:[NeoWCDebugWindow class]] || window.hidden || window.alpha <= 0.01) continue;
        if (window.windowLevel == UIWindowLevelNormal && window.rootViewController) {
            if (window.isKeyWindow) return window;
            fallback = window;
        }
    }
    return fallback;
}

static UIViewController *NeoWCTopViewController(UIViewController *controller) {
    if (!controller) return nil;
    if (controller.presentedViewController) return NeoWCTopViewController(controller.presentedViewController);
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return NeoWCTopViewController(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return NeoWCTopViewController(((UITabBarController *)controller).selectedViewController);
    }
    return controller;
}

static UIViewController *NeoWCVisibleContainerController(UIViewController *controller) {
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return NeoWCVisibleContainerController(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return NeoWCVisibleContainerController(((UITabBarController *)controller).selectedViewController);
    }
    return controller;
}

static UIViewController *NeoWCViewControllerForView(UIView *view) {
    UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) return (UIViewController *)responder;
        responder = responder.nextResponder;
    }
    return nil;
}

static void NeoWCAppendViewTree(NSMutableString *report, UIView *view, NSUInteger depth, NSUInteger *count) {
    if (!view || !count || *count >= 400 || depth > 30) return;
    (*count)++;
    NSMutableString *details = [NSMutableString string];
    if (view.accessibilityIdentifier.length > 0) [details appendFormat:@" id=%@", view.accessibilityIdentifier];
    NSString *text = nil;
    if ([view isKindOfClass:[UILabel class]]) text = ((UILabel *)view).text;
    else if ([view isKindOfClass:[UIButton class]]) text = ((UIButton *)view).currentTitle;
    else if ([view isKindOfClass:[UITextField class]]) text = ((UITextField *)view).text;
    else if ([view isKindOfClass:[UITextView class]]) text = ((UITextView *)view).text;
    if (text.length > 80) text = [[text substringToIndex:80] stringByAppendingString:@"…"];
    if (text.length > 0) [details appendFormat:@" text=%@", text];
    [report appendFormat:@"%@%@ frame=%@ hidden=%@ alpha=%.2f%@\n",
     [@"" stringByPaddingToLength:depth * 2 withString:@" " startingAtIndex:0],
     NSStringFromClass(view.class), NSStringFromCGRect(view.frame), view.hidden ? @"YES" : @"NO", view.alpha, details];
    for (UIView *subview in view.subviews) NeoWCAppendViewTree(report, subview, depth + 1, count);
}

@interface NeoWCObjectInspectorViewController : UIViewController
- (instancetype)initWithObject:(id)object inspectedClass:(Class)inspectedClass;
@end

@interface NeoWCRuntimeSearchViewController : NeoWCCardTableViewController <UISearchBarDelegate>
@end

@interface NeoWCLogViewController : NeoWCCardTableViewController
@end

@interface NeoWCDebugDashboardViewController : NeoWCCardTableViewController
@property (nonatomic, copy) void (^closeHandler)(void);
@property (nonatomic, weak) UIViewController *sourceViewController;
@end

@interface NeoWCViewPickerController : UIViewController
@end

@interface NeoWCDebugManager ()
@property (nonatomic, strong) NeoWCDebugWindow *floatingWindow;
@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) NeoWCDebugWindow *pickerWindow;
@end

@implementation NeoWCDebugManager

+ (instancetype)sharedManager {
    static NeoWCDebugManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [NeoWCDebugManager new]; });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceOrientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:[UIDevice currentDevice]];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)deviceOrientationDidChange:(__unused NSNotification *)notification {
    [self repositionFloatingButton];
}

- (void)applySavedState {
    BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCDebugFloatingEnabledKey];
    [self setFloatingEnabled:enabled];
}

- (NeoWCDebugWindow *)newDebugWindowAtLevel:(UIWindowLevel)level {
    NeoWCDebugWindow *window = nil;
    UIWindowScene *scene = NeoWCActiveWindowScene();
    if (@available(iOS 13.0, *)) {
        if (scene) window = [[NeoWCDebugWindow alloc] initWithWindowScene:scene];
    }
    if (!window) window = [[NeoWCDebugWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    window.frame = UIScreen.mainScreen.bounds;
    window.windowLevel = level;
    window.backgroundColor = UIColor.clearColor;
    return window;
}

- (void)setFloatingEnabled:(BOOL)enabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:NeoWCDebugFloatingEnabledKey];
        if (!enabled) {
            self.floatingWindow.hidden = YES;
            self.floatingWindow = nil;
            self.floatingButton = nil;
            NeoWCLog(@"调试悬浮入口已关闭");
            return;
        }
        if (self.floatingWindow) {
            self.floatingWindow.hidden = NO;
            return;
        }

        NeoWCDebugWindow *window = [self newDebugWindowAtLevel:UIWindowLevelAlert + 8.0];
        window.passesThroughBackgroundTouches = YES;
        UIViewController *root = [UIViewController new];
        NeoWCPassthroughView *passthroughView = [[NeoWCPassthroughView alloc] initWithFrame:window.bounds];
        passthroughView.backgroundColor = UIColor.clearColor;
        root.view = passthroughView;
        window.rootViewController = root;

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(0.0, 0.0, 48.0, 48.0);
        button.backgroundColor = [UIColor secondarySystemBackgroundColor];
        button.tintColor = [UIColor labelColor];
        button.layer.cornerRadius = 24.0;
        button.layer.cornerCurve = kCACornerCurveContinuous;
        button.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
        button.layer.borderColor = UIColor.separatorColor.CGColor;
        button.accessibilityLabel = @"打开 NeoWC 调试中心";
        UIImage *image = [UIImage systemImageNamed:@"wrench.and.screwdriver"] ?: [UIImage systemImageNamed:@"wrench"];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(floatingButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [button addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(floatingButtonPanned:)]];
        [passthroughView addSubview:button];

        self.floatingWindow = window;
        self.floatingButton = button;
        window.hidden = NO;
        [self repositionFloatingButton];
        NeoWCLog(@"调试悬浮入口已开启（无全局手势）");
    });
}

- (CGRect)floatingButtonMovementBounds {
    UIView *container = self.floatingButton.superview;
    if (!container) return CGRectZero;
    UIEdgeInsets safeInsets = container.safeAreaInsets;
    CGFloat radius = CGRectGetWidth(self.floatingButton.bounds) * 0.5;
    CGFloat edgeSpacing = 12.0;
    CGFloat minX = safeInsets.left + radius + edgeSpacing;
    CGFloat maxX = CGRectGetWidth(container.bounds) - safeInsets.right - radius - edgeSpacing;
    CGFloat minY = safeInsets.top + radius + edgeSpacing;
    CGFloat maxY = CGRectGetHeight(container.bounds) - safeInsets.bottom - radius - edgeSpacing;
    return CGRectMake(minX, minY, MAX(0.0, maxX - minX), MAX(0.0, maxY - minY));
}

- (void)repositionFloatingButton {
    if (!self.floatingButton.superview) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect movementBounds = [self floatingButtonMovementBounds];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL leftSide = [[defaults objectForKey:NeoWCDebugFloatingSideKey] boolValue];
        NSNumber *savedVerticalPosition = [defaults objectForKey:NeoWCDebugFloatingVerticalPositionKey];
        CGFloat verticalPosition = savedVerticalPosition ? MIN(1.0, MAX(0.0, savedVerticalPosition.doubleValue)) : 0.78;
        self.floatingButton.center = CGPointMake(leftSide ? CGRectGetMinX(movementBounds) : CGRectGetMaxX(movementBounds),
                                                 CGRectGetMinY(movementBounds) + CGRectGetHeight(movementBounds) * verticalPosition);
    });
}

- (void)floatingButtonPanned:(UIPanGestureRecognizer *)recognizer {
    UIButton *button = self.floatingButton;
    UIView *container = button.superview;
    if (!button || !container) return;
    CGPoint translation = [recognizer translationInView:container];
    CGRect movementBounds = [self floatingButtonMovementBounds];
    CGPoint center = CGPointMake(button.center.x + translation.x, button.center.y + translation.y);
    center.x = MIN(CGRectGetMaxX(movementBounds), MAX(CGRectGetMinX(movementBounds), center.x));
    center.y = MIN(CGRectGetMaxY(movementBounds), MAX(CGRectGetMinY(movementBounds), center.y));
    button.center = center;
    [recognizer setTranslation:CGPointZero inView:container];

    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        BOOL leftSide = center.x < CGRectGetMidX(movementBounds);
        center.x = leftSide ? CGRectGetMinX(movementBounds) : CGRectGetMaxX(movementBounds);
        [UIView animateWithDuration:0.24 delay:0.0 usingSpringWithDamping:0.82 initialSpringVelocity:0.2 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            button.center = center;
        } completion:nil];
        CGFloat height = CGRectGetHeight(movementBounds);
        CGFloat verticalPosition = height > 0.0 ? (center.y - CGRectGetMinY(movementBounds)) / height : 0.5;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:leftSide forKey:NeoWCDebugFloatingSideKey];
        [defaults setDouble:verticalPosition forKey:NeoWCDebugFloatingVerticalPositionKey];
        NeoWCLog(@"已保存调试悬浮按钮位置");
    }
}

- (void)floatingButtonTapped {
    UIWindow *mainWindow = NeoWCMainWindow();
    UIViewController *top = NeoWCTopViewController(mainWindow.rootViewController);
    [self presentDashboardFromViewController:top];
}

- (void)presentDashboardFromViewController:(UIViewController *)viewController {
    if (!viewController) return;
    UIViewController *sourceViewController = NeoWCVisibleContainerController(viewController);
    self.floatingWindow.hidden = YES;
    NeoWCDebugDashboardViewController *dashboard = [[NeoWCDebugDashboardViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
    dashboard.sourceViewController = sourceViewController;
    __weak typeof(self) weakSelf = self;
    dashboard.closeHandler = ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:NeoWCDebugFloatingEnabledKey]) {
            weakSelf.floatingWindow.hidden = NO;
        }
    };
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:dashboard];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)beginViewPicking {
    NeoWCDebugWindow *window = [self newDebugWindowAtLevel:UIWindowLevelAlert + 20.0];
    NeoWCViewPickerController *picker = [NeoWCViewPickerController new];
    window.rootViewController = picker;
    self.pickerWindow = window;
    window.hidden = NO;
    NeoWCLog(@"视图选择器已启动");
}

- (void)finishPickingView:(UIView *)view {
    self.pickerWindow.hidden = YES;
    self.pickerWindow = nil;
    if (!view) return;
    NeoWCLog(@"选中视图 %@ (%p)", NSStringFromClass(view.class), view);
    UIViewController *top = NeoWCTopViewController(NeoWCMainWindow().rootViewController);
    NeoWCObjectInspectorViewController *inspector = [[NeoWCObjectInspectorViewController alloc] initWithObject:view inspectedClass:view.class];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:inspector];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [top presentViewController:navigationController animated:YES completion:nil];
}

- (void)cancelPicking {
    self.pickerWindow.hidden = YES;
    self.pickerWindow = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:NeoWCDebugFloatingEnabledKey]) self.floatingWindow.hidden = NO;
    NeoWCLog(@"视图选择器已取消");
}

@end

@implementation NeoWCViewPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;

    UILabel *toast = [UILabel new];
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    toast.text = @"轻点选择视图 · 双指轻点取消";
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    toast.textColor = UIColor.whiteColor;
    toast.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.90];
    toast.layer.cornerRadius = 12.0;
    toast.layer.cornerCurve = kCACornerCurveContinuous;
    toast.layer.masksToBounds = YES;
    toast.userInteractionEnabled = NO;
    [self.view addSubview:toast];

    [NSLayoutConstraint activateConstraints:@[
        [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-28.0],
        [toast.widthAnchor constraintEqualToConstant:238.0],
        [toast.heightAnchor constraintEqualToConstant:40.0],
    ]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.18 animations:^{ toast.alpha = 0.0; } completion:^(__unused BOOL finished) {
            [toast removeFromSuperview];
        }];
    });

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTapped:)];
    tap.cancelsTouchesInView = NO;
    UITapGestureRecognizer *cancelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelTapped)];
    cancelTap.numberOfTouchesRequired = 2;
    cancelTap.cancelsTouchesInView = YES;
    [tap requireGestureRecognizerToFail:cancelTap];
    [self.view addGestureRecognizer:tap];
    [self.view addGestureRecognizer:cancelTap];
}

- (void)cancelTapped {
    [[NeoWCDebugManager sharedManager] cancelPicking];
}

- (void)screenTapped:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    NeoWCDebugManager *manager = [NeoWCDebugManager sharedManager];
    NeoWCDebugWindow *overlay = manager.pickerWindow;
    overlay.hidden = YES;
    UIWindow *targetWindow = NeoWCMainWindow();
    CGPoint targetPoint = [targetWindow convertPoint:point fromWindow:overlay];
    UIView *view = [targetWindow hitTest:targetPoint withEvent:nil];
    [manager finishPickingView:view];
}

@end

@implementation NeoWCDebugDashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"调试中心";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(closeTapped)];
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:self.closeHandler];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 4 : 3; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return section == 0 ? @"工具" : @"环境"; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DebugCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"DebugCell"];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    if (indexPath.section == 0) {
        NSArray *titles = @[@"当前页面层级", @"视图选择器", @"Runtime 类搜索", @"NeoWC 日志"];
        NSArray *symbols = @[@"square.3.layers.3d", @"viewfinder", @"magnifyingglass", @"doc.text"];
        cell.textLabel.text = titles[indexPath.row];
        cell.imageView.image = [UIImage systemImageNamed:symbols[indexPath.row]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (indexPath.row == 0) { cell.textLabel.text = @"系统"; cell.detailTextLabel.text = UIDevice.currentDevice.systemVersion; }
        if (indexPath.row == 1) { cell.textLabel.text = @"应用"; cell.detailTextLabel.text = NSBundle.mainBundle.bundleIdentifier; }
        if (indexPath.row == 2) { cell.textLabel.text = @"架构"; cell.detailTextLabel.text = @"arm64 / arm64e"; }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 0) return;
    if (indexPath.row == 0) {
        UIViewController *page = self.sourceViewController;
        if (page) {
            NeoWCObjectInspectorViewController *inspector = [[NeoWCObjectInspectorViewController alloc] initWithObject:page.view inspectedClass:page.class];
            [self.navigationController pushViewController:inspector animated:YES];
        }
    } else if (indexPath.row == 1) {
        [self dismissViewControllerAnimated:YES completion:^{ [[NeoWCDebugManager sharedManager] beginViewPicking]; }];
    } else if (indexPath.row == 2) {
        [self.navigationController pushViewController:[[NeoWCRuntimeSearchViewController alloc] initWithStyle:UITableViewStylePlain] animated:YES];
    } else {
        [self.navigationController pushViewController:[[NeoWCLogViewController alloc] initWithStyle:UITableViewStylePlain] animated:YES];
    }
}

@end

// WCPluginsMgr needs a concrete controller class name. This subclass reuses the
// dashboard directly instead of presenting a second modal controller.
@interface NeoWCDebugShortcutViewController : NeoWCDebugDashboardViewController
@end

@implementation NeoWCDebugShortcutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
    NSArray<UIViewController *> *controllers = self.navigationController.viewControllers;
    if (controllers.count >= 2) self.sourceViewController = controllers[controllers.count - 2];
}

@end

@interface NeoWCObjectInspectorViewController ()
@property (nonatomic, strong) id inspectedObject;
@property (nonatomic, assign) Class inspectedClass;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation NeoWCObjectInspectorViewController

- (instancetype)initWithObject:(id)object inspectedClass:(Class)inspectedClass {
    self = [super init];
    if (self) {
        _inspectedObject = object;
        _inspectedClass = inspectedClass;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSStringFromClass(self.inspectedClass);
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(closeTapped)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"复制报告" style:UIBarButtonItemStylePlain target:self action:@selector(copyReport)];

    UITextView *textView = [UITextView new];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.editable = NO;
    textView.alwaysBounceVertical = YES;
    textView.font = [UIFont monospacedSystemFontOfSize:12.0 weight:UIFontWeightRegular];
    textView.textContainerInset = UIEdgeInsetsMake(16.0, 14.0, 24.0, 14.0);
    [self.view addSubview:textView];
    [NSLayoutConstraint activateConstraints:@[
        [textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [textView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    self.textView = textView;
    textView.text = [self inspectionReport];
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:^{
        [[NeoWCDebugManager sharedManager] applySavedState];
    }];
}

- (void)copyReport {
    UIPasteboard.generalPasteboard.string = self.textView.text ?: @"";
    NeoWCLog(@"已复制 %@ 的检查报告", NSStringFromClass(self.inspectedClass));
    self.navigationItem.prompt = @"检查报告已复制";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ self.navigationItem.prompt = nil; });
}

- (NSString *)inspectionReport {
    NSMutableString *report = [NSMutableString string];
    [report appendFormat:@"CLASS\n%@\n\nADDRESS\n%p\n\n", NSStringFromClass(self.inspectedClass), self.inspectedObject];

    if ([self.inspectedObject isKindOfClass:[UIView class]]) {
        UIView *view = self.inspectedObject;
        UIViewController *controller = NeoWCViewControllerForView(view);
        [report appendFormat:@"VIEW\nframe: %@\nbounds: %@\nalpha: %.3f\nhidden: %@\nwindow: %@\ncontroller: %@\n\n",
         NSStringFromCGRect(view.frame), NSStringFromCGRect(view.bounds), view.alpha, view.hidden ? @"YES" : @"NO",
         NSStringFromClass(view.window.class), NSStringFromClass(controller.class)];
        [report appendString:@"SUPER VIEWS\n"];
        UIView *parent = view;
        NSInteger depth = 0;
        while (parent && depth < 20) {
            [report appendFormat:@"%02ld  %@  %@\n", (long)depth, NSStringFromClass(parent.class), NSStringFromCGRect(parent.frame)];
            parent = parent.superview;
            depth++;
        }
        [report appendString:@"\n"];
        [report appendString:@"VIEW TREE\n"];
        NSUInteger viewCount = 0;
        NeoWCAppendViewTree(report, view, 0, &viewCount);
        if (viewCount >= 400) [report appendString:@"… 已达到 400 个视图的显示上限\n"];
        [report appendString:@"\n"];
    }

    [report appendString:@"CLASS HIERARCHY\n"];
    for (Class cls = self.inspectedClass; cls; cls = class_getSuperclass(cls)) {
        [report appendFormat:@"%@\n", NSStringFromClass(cls)];
    }

    [report appendString:@"\nIVARS\n"];
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(self.inspectedClass, &ivarCount);
    for (unsigned int index = 0; index < ivarCount; index++) {
        [report appendFormat:@"%s  %s\n", ivar_getTypeEncoding(ivars[index]) ?: "?", ivar_getName(ivars[index]) ?: "?"];
    }
    free(ivars);

    [report appendString:@"\nPROPERTIES\n"];
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(self.inspectedClass, &propertyCount);
    for (unsigned int index = 0; index < propertyCount; index++) {
        [report appendFormat:@"%s\n", property_getName(properties[index]) ?: "?"];
    }
    free(properties);

    [report appendString:@"\nMETHODS\n"];
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(self.inspectedClass, &methodCount);
    unsigned int visibleCount = MIN(methodCount, 250);
    for (unsigned int index = 0; index < visibleCount; index++) {
        [report appendFormat:@"- %@\n", NSStringFromSelector(method_getName(methods[index]))];
    }
    if (methodCount > visibleCount) [report appendFormat:@"… 其余 %u 个方法未显示\n", methodCount - visibleCount];
    free(methods);
    return report;
}

@end

@interface NeoWCRuntimeSearchViewController ()
@property (nonatomic, copy) NSArray<NSString *> *allClassNames;
@property (nonatomic, copy) NSArray<NSString *> *results;
@property (nonatomic, strong) UISearchBar *searchBar;
@end

@implementation NeoWCRuntimeSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Runtime 类搜索";
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    int classCount = objc_getClassList(NULL, 0);
    Class *classes = classCount > 0 ? (__unsafe_unretained Class *)malloc(sizeof(Class) * (NSUInteger)classCount) : NULL;
    classCount = classes ? objc_getClassList(classes, classCount) : 0;
    NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:(NSUInteger)classCount];
    for (int index = 0; index < classCount; index++) {
        NSString *name = NSStringFromClass(classes[index]);
        if (name.length > 0) [names addObject:name];
    }
    free(classes);
    self.allClassNames = [names sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    self.results = @[];

    UISearchBar *searchBar = [UISearchBar new];
    searchBar.delegate = self;
    searchBar.placeholder = @"输入微信类名";
    NeoWCInstallSearchBarInTableView(searchBar, self.tableView);
    self.searchBar = searchBar;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    (void)searchBar;
    NSString *query = [searchText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (query.length == 0) {
        self.results = @[];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSString *name, __unused NSDictionary *bindings) {
            return [name rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound;
        }];
        NSArray *matches = [self.allClassNames filteredArrayUsingPredicate:predicate];
        self.results = matches.count > 300 ? [matches subarrayWithRange:NSMakeRange(0, 300)] : matches;
    }
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.results.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ClassCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ClassCell"];
    NSString *name = self.results[indexPath.row];
    Class cls = NSClassFromString(name);
    cell.textLabel.text = name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"super: %@", NSStringFromClass(class_getSuperclass(cls)) ?: @"-"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Class cls = NSClassFromString(self.results[indexPath.row]);
    NeoWCObjectInspectorViewController *inspector = [[NeoWCObjectInspectorViewController alloc] initWithObject:nil inspectedClass:cls];
    [self.navigationController pushViewController:inspector animated:YES];
}

@end

@interface NeoWCLogViewController ()
@property (nonatomic, copy) NSArray<NSString *> *entries;
@end

@implementation NeoWCLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"NeoWC 日志";
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithTitle:@"复制" style:UIBarButtonItemStylePlain target:self action:@selector(copyLogs)],
        [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clearLogs)],
    ];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadLogs) name:NeoWCDebugLogDidChangeNotification object:nil];
    [self reloadLogs];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)reloadLogs { self.entries = [[NeoWCDebugLogStore sharedStore] snapshot]; [self.tableView reloadData]; }
- (void)copyLogs { UIPasteboard.generalPasteboard.string = [self.entries componentsJoinedByString:@"\n"]; }
- (void)clearLogs { [[NeoWCDebugLogStore sharedStore] clear]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return MAX(self.entries.count, 1); }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LogCell"];
    cell.textLabel.font = [UIFont monospacedSystemFontOfSize:11.0 weight:UIFontWeightRegular];
    cell.textLabel.numberOfLines = 0;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = self.entries.count == 0 ? [UIColor secondaryLabelColor] : [UIColor labelColor];
    cell.textLabel.text = self.entries.count == 0 ? @"暂无 NeoWC 日志" : self.entries[indexPath.row];
    return cell;
}

@end
