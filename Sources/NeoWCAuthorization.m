#import "NeoWCAuthorization.h"
#import "NeoWCAccount.h"

#import <CommonCrypto/CommonDigest.h>
#import <stdlib.h>

static NSString *const NeoWCAuthorizationBaseURL = @"https://api.ovoy.cc/api";
static NSString *const NeoWCAdministratorWXIDHash = @"93773e983ed1f93c28c5e98e712049bf50ec0caddc367e3cfbd9548e19f82346";
static NSString *const NeoWCAuthorizationCachedStateKey = @"com.qiu7c.neowc.authorization.cached-state";
static NSString *const NeoWCAuthorizationCachedMessageKey = @"com.qiu7c.neowc.authorization.cached-message";
static NSString *const NeoWCAuthorizationCachedIdentityHashKey = @"com.qiu7c.neowc.authorization.cached-identity-hash";
static NSString *const NeoWCAuthorizationPermanentBlacklistKey = @"com.qiu7c.neowc.authorization.permanent-blacklist";
static __weak UIAlertController *NeoWCPermanentBlacklistAlert;
static BOOL NeoWCPermanentBlacklistAlertPresenting = NO;
static void NeoWCDismissPermanentBlacklistBlocker(void);
NSNotificationName const NeoWCAuthorizationStateDidChangeNotification = @"NeoWCAuthorizationStateDidChangeNotification";

static NSString *NeoWCTrimmedAuthorizationID(NSString *value) {
    if (![value isKindOfClass:NSString.class]) return @"";
    return [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

static NSString *NeoWCSHA256Hex(NSString *value) {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return @"";
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
        [hex appendFormat:@"%02x", digest[index]];
    }
    return hex;
}

BOOL NeoWCAuthorizationIsCurrentUserAdministrator(void) {
    NSString *wxid = NeoWCTrimmedAuthorizationID(NeoWCCurrentUserWXID());
    if (wxid.length == 0) return NO;
    return [[NeoWCSHA256Hex(wxid) lowercaseString] isEqualToString:NeoWCAdministratorWXIDHash];
}

static BOOL NeoWCAuthorizationHasCachedGrantForCurrentUser(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults integerForKey:NeoWCAuthorizationCachedStateKey] != NeoWCAuthorizationStateAuthorized) return NO;
    NSString *wxid = NeoWCTrimmedAuthorizationID(NeoWCCurrentUserWXID());
    NSString *cachedHash = [defaults stringForKey:NeoWCAuthorizationCachedIdentityHashKey];
    return wxid.length > 0 && cachedHash.length > 0 && [[NeoWCSHA256Hex(wxid) lowercaseString] isEqualToString:cachedHash.lowercaseString];
}

BOOL NeoWCAuthorizationHasCompletedInitialCheckForCurrentUser(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    id cachedStateValue = [defaults objectForKey:NeoWCAuthorizationCachedStateKey];
    if (![cachedStateValue isKindOfClass:NSNumber.class]) return NO;
    NeoWCAuthorizationState cachedState = (NeoWCAuthorizationState)[cachedStateValue integerValue];
    if (cachedState == NeoWCAuthorizationStateUnknown || cachedState == NeoWCAuthorizationStateLoading) return NO;
    NSString *wxid = NeoWCTrimmedAuthorizationID(NeoWCCurrentUserWXID());
    NSString *cachedHash = [defaults stringForKey:NeoWCAuthorizationCachedIdentityHashKey];
    return wxid.length > 0 && cachedHash.length > 0 &&
           [[NeoWCSHA256Hex(wxid) lowercaseString] isEqualToString:cachedHash.lowercaseString];
}

static NSURLSession *NeoWCAuthorizationSession(void) {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
        configuration.timeoutIntervalForRequest = 15.0;
        configuration.timeoutIntervalForResource = 20.0;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        configuration.URLCache = nil;
        session = [NSURLSession sessionWithConfiguration:configuration];
    });
    return session;
}

static NSDictionary *NeoWCJSONObjectDictionary(NSData *data) {
    if (data.length == 0) return nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [object isKindOfClass:NSDictionary.class] ? object : nil;
}

@interface NeoWCAuthorizationService : NSObject
@property (atomic, assign) NeoWCAuthorizationState state;
@property (atomic, copy) NSString *checkedWXID;
@property (atomic, copy) NSString *message;
@property (atomic, assign) BOOL retainsCachedGrantDuringRefresh;
@property (atomic, assign) BOOL recoveryCheckInFlight;
@property (atomic, strong) NSDate *lastRecoveryCheckDate;
- (void)updateState:(NeoWCAuthorizationState)state message:(NSString *)message;
@end

@implementation NeoWCAuthorizationService

+ (instancetype)sharedService {
    static NeoWCAuthorizationService *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [NeoWCAuthorizationService new];
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        if ([defaults boolForKey:NeoWCAuthorizationPermanentBlacklistKey]) {
            service.state = NeoWCAuthorizationStateBlacklisted;
        } else {
            NSInteger cachedState = [defaults integerForKey:NeoWCAuthorizationCachedStateKey];
            BOOL cachedStateIsValid = cachedState >= NeoWCAuthorizationStateUnknown && cachedState <= NeoWCAuthorizationStateFailed;
            service.state = cachedStateIsValid && (cachedState != NeoWCAuthorizationStateAuthorized || NeoWCAuthorizationHasCachedGrantForCurrentUser())
                ? (NeoWCAuthorizationState)cachedState : NeoWCAuthorizationStateUnknown;
        }
        service.checkedWXID = @"";
        service.message = [defaults stringForKey:NeoWCAuthorizationCachedMessageKey] ?: (service.state == NeoWCAuthorizationStateBlacklisted ? @"当前账号已被限制使用" : @"尚未验证授权");
    });
    return service;
}

- (void)updateState:(NeoWCAuthorizationState)state message:(NSString *)message {
    if (NeoWCAuthorizationIsPermanentlyBlacklisted()) {
        state = NeoWCAuthorizationStateBlacklisted;
        message = @"当前账号已被限制使用";
    }
    self.state = state;
    self.message = message ?: @"";
    if (state != NeoWCAuthorizationStateLoading) self.retainsCachedGrantDuringRefresh = NO;
    if (state != NeoWCAuthorizationStateLoading) {
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        [defaults setInteger:state forKey:NeoWCAuthorizationCachedStateKey];
        [defaults setObject:self.message forKey:NeoWCAuthorizationCachedMessageKey];
        if (self.checkedWXID.length > 0) [defaults setObject:NeoWCSHA256Hex(self.checkedWXID) forKey:NeoWCAuthorizationCachedIdentityHashKey];
        if (state == NeoWCAuthorizationStateBlacklisted) [defaults setBool:YES forKey:NeoWCAuthorizationPermanentBlacklistKey];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:NeoWCAuthorizationStateDidChangeNotification object:nil];
        if (state == NeoWCAuthorizationStateBlacklisted) NeoWCPresentPermanentBlacklistBlockerIfNeeded();
    });
}

- (void)refresh {
    BOOL recoveringFromBlacklist = NeoWCAuthorizationIsPermanentlyBlacklisted();
    NSString *wxid = NeoWCTrimmedAuthorizationID(NeoWCCurrentUserWXID());
    if (wxid.length == 0) {
        self.checkedWXID = @"";
        [self updateState:NeoWCAuthorizationStateFailed message:@"无法获取当前账号 wxid"];
        return;
    }
    if (recoveringFromBlacklist) {
        if (self.recoveryCheckInFlight && [self.checkedWXID isEqualToString:wxid]) return;
        if (self.lastRecoveryCheckDate &&
            [[NSDate date] timeIntervalSinceDate:self.lastRecoveryCheckDate] < 300.0) return;
        self.recoveryCheckInFlight = YES;
        self.lastRecoveryCheckDate = NSDate.date;
    } else if (self.state == NeoWCAuthorizationStateLoading && [self.checkedWXID isEqualToString:wxid]) {
        return;
    }
    self.checkedWXID = wxid;
    self.retainsCachedGrantDuringRefresh = recoveringFromBlacklist ? NO : NeoWCAuthorizationHasCachedGrantForCurrentUser();
    if (!recoveringFromBlacklist) [self updateState:NeoWCAuthorizationStateLoading message:@"正在验证授权…"];

    NSURLComponents *components = [NSURLComponents componentsWithString:[NeoWCAuthorizationBaseURL stringByAppendingString:@"/auth.php"]];
    components.queryItems = @[[NSURLQueryItem queryItemWithName:@"id" value:wxid]];
    NSURL *URL = components.URL;
    if (!URL) {
        self.recoveryCheckInFlight = NO;
        [self updateState:NeoWCAuthorizationStateFailed message:@"授权接口地址无效"];
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    __weak typeof(self) weakSelf = self;
    [[NeoWCAuthorizationSession() dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NeoWCAuthorizationService *strongSelf = weakSelf;
        if (!strongSelf || ![strongSelf.checkedWXID isEqualToString:wxid]) return;
        strongSelf.recoveryCheckInFlight = NO;
        if (error) {
            NSString *message = error.code == NSURLErrorTimedOut ? @"授权验证超时" : @"授权验证网络错误";
            [strongSelf updateState:NeoWCAuthorizationStateFailed message:message];
            return;
        }
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        NSDictionary *JSON = NeoWCJSONObjectDictionary(data);
        id authorized = JSON[@"authorized"];
        id blacklisted = JSON[@"blacklisted"];
        NSString *serverMessage = [JSON[@"message"] isKindOfClass:NSString.class] ? JSON[@"message"] : @"";
        BOOL hasAuthorized = [authorized isKindOfClass:NSNumber.class];
        BOOL hasBlacklisted = [blacklisted isKindOfClass:NSNumber.class];
        id responseCode = JSON[@"code"];
        NSInteger semanticCode = [responseCode isKindOfClass:NSNumber.class] ? [responseCode integerValue] : statusCode;
        BOOL validAuthorizationStatus = (statusCode >= 200 && statusCode < 300) || statusCode == 403;
        BOOL validSemanticCode = ![responseCode isKindOfClass:NSNumber.class] ||
                                 semanticCode == 200 || semanticCode == 403;
        BOOL explicitlyRemovedFromBlacklist = recoveringFromBlacklist && hasAuthorized && hasBlacklisted &&
                                              ![blacklisted boolValue] && validAuthorizationStatus && validSemanticCode;
        if (explicitlyRemovedFromBlacklist) {
            [NSUserDefaults.standardUserDefaults removeObjectForKey:NeoWCAuthorizationPermanentBlacklistKey];
            NeoWCDismissPermanentBlacklistBlocker();
        }
        if (!JSON || !hasAuthorized || !hasBlacklisted) {
            [strongSelf updateState:NeoWCAuthorizationStateFailed message:@"授权响应格式异常"];
        } else if ([blacklisted boolValue]) {
            [strongSelf updateState:NeoWCAuthorizationStateBlacklisted message:@"当前账号已被限制使用"];
        } else if (statusCode >= 200 && statusCode < 300 && [authorized boolValue]) {
            [strongSelf updateState:NeoWCAuthorizationStateAuthorized message:serverMessage.length ? serverMessage : @"该 ID 已授权"];
        } else if (![authorized boolValue]) {
            [strongSelf updateState:NeoWCAuthorizationStateUnauthorized message:serverMessage.length ? serverMessage : @"该 ID 未授权"];
        } else {
            [strongSelf updateState:NeoWCAuthorizationStateFailed message:@"授权响应状态异常"];
        }
    }] resume];
}

@end

NeoWCAuthorizationState NeoWCCurrentAuthorizationState(void) {
    return [NeoWCAuthorizationService sharedService].state;
}

BOOL NeoWCAuthorizationAllowsCoreFeatures(void) {
    NeoWCAuthorizationService *service = [NeoWCAuthorizationService sharedService];
    NeoWCAuthorizationState state = service.state;
    return state == NeoWCAuthorizationStateAuthorized ||
           (state == NeoWCAuthorizationStateLoading && service.retainsCachedGrantDuringRefresh);
}

BOOL NeoWCAuthorizationIsPermanentlyBlacklisted(void) {
    return [NSUserDefaults.standardUserDefaults boolForKey:NeoWCAuthorizationPermanentBlacklistKey];
}

NSString *NeoWCCurrentAuthorizationMessage(void) {
    return [NeoWCAuthorizationService sharedService].message ?: @"";
}

void NeoWCRefreshCurrentAuthorization(void) {
    [[NeoWCAuthorizationService sharedService] refresh];
}

static UIViewController *NeoWCAuthorizationTopViewController(UIViewController *controller) {
    if (!controller) return nil;
    if (controller.presentedViewController) return NeoWCAuthorizationTopViewController(controller.presentedViewController);
    if ([controller isKindOfClass:UINavigationController.class]) return NeoWCAuthorizationTopViewController(((UINavigationController *)controller).visibleViewController);
    if ([controller isKindOfClass:UITabBarController.class]) return NeoWCAuthorizationTopViewController(((UITabBarController *)controller).selectedViewController);
    return controller;
}

static void NeoWCDismissPermanentBlacklistBlocker(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = NeoWCPermanentBlacklistAlert;
        NeoWCPermanentBlacklistAlert = nil;
        NeoWCPermanentBlacklistAlertPresenting = NO;
        if (alert.presentingViewController) [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

void NeoWCPresentPermanentBlacklistBlockerIfNeeded(void) {
    if (!NeoWCAuthorizationIsPermanentlyBlacklisted()) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (NeoWCPermanentBlacklistAlertPresenting) return;
        UIWindow *targetWindow = nil;
        for (UIWindow *window in UIApplication.sharedApplication.windows.reverseObjectEnumerator) {
            if (!window.hidden && window.alpha > 0.0 && window.windowLevel == UIWindowLevelNormal && window.rootViewController) {
                targetWindow = window;
                break;
            }
        }
        UIViewController *presenter = NeoWCAuthorizationTopViewController(targetWindow.rootViewController);
        if (!presenter || !presenter.view.window) return;
        NeoWCPermanentBlacklistAlertPresenting = YES;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NeoWC 已停用"
                                                                       message:@"当前账号已被限制使用"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
            exit(EXIT_SUCCESS);
        }]];
        NeoWCPermanentBlacklistAlert = alert;
        [presenter presentViewController:alert animated:YES completion:nil];
    });
}

typedef NS_ENUM(NSInteger, NeoWCAdminRequestKind) {
    NeoWCAdminRequestKindAuthorizationList,
    NeoWCAdminRequestKindBlacklistList,
    NeoWCAdminRequestKindAdd,
    NeoWCAdminRequestKindDelete,
    NeoWCAdminRequestKindBlacklist,
    NeoWCAdminRequestKindUnblacklist,
};

typedef void (^NeoWCAdminRequestCompletion)(NSArray<NSString *> * _Nullable identifiers,
                                             NSString * _Nullable message,
                                             NSInteger statusCode,
                                             NSError * _Nullable error);

static NSArray<NSString *> *NeoWCAuthorizationIDsFromObject(id object) {
    if ([object isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictionary = object;
        for (NSString *key in @[@"ids", @"list", @"items", @"authorized_ids", @"blacklisted_ids", @"authorized", @"blacklisted", @"blacklist", @"data"]) {
            NSArray *values = NeoWCAuthorizationIDsFromObject(dictionary[key]);
            if (values) return values;
        }
        NSString *identifier = NeoWCTrimmedAuthorizationID(dictionary[@"id"] ?: dictionary[@"wxid"]);
        return identifier.length ? @[identifier] : nil;
    }
    if (![object isKindOfClass:NSArray.class]) return nil;
    NSMutableOrderedSet<NSString *> *identifiers = [NSMutableOrderedSet orderedSet];
    for (id value in (NSArray *)object) {
        if ([value isKindOfClass:NSString.class]) {
            NSString *identifier = NeoWCTrimmedAuthorizationID(value);
            if (identifier.length) [identifiers addObject:identifier];
        } else {
            NSArray *nested = NeoWCAuthorizationIDsFromObject(value);
            if (nested.count) [identifiers addObjectsFromArray:nested];
        }
    }
    return identifiers.array;
}

static NSString *NeoWCAdminResponseMessage(NSDictionary *JSON, NSInteger statusCode, NSError *error) {
    if (error.code == NSURLErrorTimedOut) return @"请求超时，请检查网络后重试。";
    if (error) return [NSString stringWithFormat:@"网络请求失败：%@", error.localizedDescription ?: @"未知错误"];
    NSString *serverMessage = [JSON[@"message"] isKindOfClass:NSString.class] ? JSON[@"message"] : nil;
    if (statusCode == 401) return serverMessage.length ? serverMessage : @"管理员密钥无效，请重新输入。";
    if (statusCode == 403) return serverMessage.length ? serverMessage : @"管理员密钥没有执行此操作的权限。";
    if (statusCode == 404) return serverMessage.length ? serverMessage : @"授权接口不存在或暂不可用。";
    if (statusCode == 405) return serverMessage.length ? serverMessage : @"请求方式不被授权接口允许。";
    if (statusCode == 409) return serverMessage.length ? serverMessage : @"该 ID 已在黑名单中。";
    if (statusCode == 500) return serverMessage.length ? serverMessage : @"服务器内部错误，请稍后重试。";
    if (statusCode < 200 || statusCode >= 300) return serverMessage.length ? serverMessage : [NSString stringWithFormat:@"服务器返回错误（%ld）。", (long)statusCode];
    return serverMessage;
}

static void NeoWCPerformAdminRequest(NeoWCAdminRequestKind kind,
                                     NSString *secret,
                                     NSString *identifier,
                                     NeoWCAdminRequestCompletion completion) {
    NSString *path = @"/auth-list.php";
    BOOL listRequest = kind == NeoWCAdminRequestKindAuthorizationList || kind == NeoWCAdminRequestKindBlacklistList;
    if (kind == NeoWCAdminRequestKindBlacklistList) path = @"/auth-blacklist-list.php";
    if (kind == NeoWCAdminRequestKindAdd) path = @"/auth-add.php";
    else if (kind == NeoWCAdminRequestKindDelete) path = @"/auth-delete.php";
    else if (kind == NeoWCAdminRequestKindBlacklist) path = @"/auth-blacklist.php";
    else if (kind == NeoWCAdminRequestKindUnblacklist) path = @"/auth-unblacklist.php";
    NSURL *URL = [NSURL URLWithString:[NeoWCAuthorizationBaseURL stringByAppendingString:path]];
    if (!URL) { if (completion) completion(nil, @"授权接口地址无效。", 0, nil); return; }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = listRequest ? @"GET" : @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[@"Bearer " stringByAppendingString:secret] forHTTPHeaderField:@"Authorization"];
    if (!listRequest) {
        [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{ @"id": identifier ?: @"" } options:0 error:nil];
    }
    [[NeoWCAuthorizationSession() dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        NSDictionary *JSON = NeoWCJSONObjectDictionary(data);
        NSInteger effectiveStatusCode = statusCode;
        id responseCode = JSON[@"code"];
        if (statusCode >= 200 && statusCode < 300 && [responseCode isKindOfClass:NSNumber.class] &&
            ([responseCode integerValue] < 200 || [responseCode integerValue] >= 300)) {
            effectiveStatusCode = [responseCode integerValue];
        }
        id success = JSON[@"success"];
        if (effectiveStatusCode >= 200 && effectiveStatusCode < 300 && [success isKindOfClass:NSNumber.class] && ![success boolValue]) {
            effectiveStatusCode = 400;
        }
        NSArray *identifiers = listRequest && effectiveStatusCode >= 200 && effectiveStatusCode < 300
            ? NeoWCAuthorizationIDsFromObject(JSON) : nil;
        NSString *message = NeoWCAdminResponseMessage(JSON, effectiveStatusCode, error);
        dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(identifiers, message, effectiveStatusCode, error); });
    }] resume];
}

@interface NeoWCAuthorizationManagerViewController () <UISearchResultsUpdating>
@property (nonatomic, copy) NSString *administratorSecret;
@property (nonatomic, copy) NSArray<NSString *> *authorizationIDs;
@property (nonatomic, copy) NSArray<NSString *> *filteredIDs;
@property (nonatomic, copy) NSArray<NSString *> *blacklistIDs;
@property (nonatomic, copy) NSArray<NSString *> *filteredBlacklistIDs;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UISegmentedControl *listSelector;
@property (nonatomic, strong) UIActivityIndicatorView *statusSpinner;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL promptingForSecret;
- (void)promptForAdministratorSecret;
- (void)refreshAuthorizationList;
- (void)presentAddAuthorization;
- (void)confirmDeleteIdentifier:(NSString *)identifier;
- (void)confirmBlacklistIdentifier:(NSString *)identifier;
- (void)confirmUnblacklistIdentifier:(NSString *)identifier;
- (void)blacklistButtonTapped:(UIButton *)sender;
- (void)unblacklistButtonTapped:(UIButton *)sender;
- (void)listSelectionChanged:(UISegmentedControl *)sender;
- (void)performMutation:(NeoWCAdminRequestKind)kind identifier:(NSString *)identifier;
- (void)buildStatusView;
- (void)showStatus:(NSString *)message spinning:(BOOL)spinning;
- (void)showTransientSuccess:(NSString *)message;
- (void)applySearchText:(NSString *)searchText;
- (void)showFailureWithTitle:(NSString *)title message:(NSString *)message statusCode:(NSInteger)statusCode;
@end

@implementation NeoWCAuthorizationManagerViewController

- (instancetype)init { return [self initWithStyle:UITableViewStyleInsetGrouped]; }
- (instancetype)initWithStyle:(UITableViewStyle)style { return [super initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"授权管理";
    self.authorizationIDs = @[];
    self.filteredIDs = @[];
    self.blacklistIDs = @[];
    self.filteredBlacklistIDs = @[];
    self.tableView.rowHeight = 52.0;
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(presentAddAuthorization)],
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshAuthorizationList)],
    ];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.placeholder = @"搜索授权 ID";
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;

    self.listSelector = [[UISegmentedControl alloc] initWithItems:@[@"已授权", @"黑名单"]];
    self.listSelector.selectedSegmentIndex = 0;
    [self.listSelector addTarget:self action:@selector(listSelectionChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.listSelector;

    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshAuthorizationList) forControlEvents:UIControlEventValueChanged];
    [self buildStatusView];
    [self showStatus:@"请输入管理员密钥后加载授权列表。" spinning:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!NeoWCAuthorizationIsCurrentUserAdministrator()) {
        [self showFailureWithTitle:@"无权访问" message:@"当前账号不是授权管理员。" statusCode:403];
        return;
    }
    if (self.administratorSecret.length == 0) [self promptForAdministratorSecret];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isMovingFromParentViewController || self.navigationController.isBeingDismissed) self.administratorSecret = nil;
}

- (void)buildStatusView {
    UIView *container = [[UIView alloc] initWithFrame:self.tableView.bounds];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:spinner];
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.secondaryLabelColor;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.adjustsFontForContentSizeCategory = YES;
    [container addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [spinner.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [spinner.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:-22.0],
        [label.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:28.0],
        [label.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-28.0],
        [label.topAnchor constraintEqualToAnchor:spinner.bottomAnchor constant:12.0],
    ]];
    self.statusSpinner = spinner;
    self.statusLabel = label;
    self.tableView.backgroundView = container;
}

- (void)showStatus:(NSString *)message spinning:(BOOL)spinning {
    self.statusLabel.text = message;
    self.statusLabel.hidden = message.length == 0;
    spinning ? [self.statusSpinner startAnimating] : [self.statusSpinner stopAnimating];
    self.tableView.backgroundView.hidden = !spinning && message.length == 0;
}

- (void)showTransientSuccess:(NSString *)message {
    self.navigationItem.prompt = message;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([weakSelf.navigationItem.prompt isEqualToString:message]) weakSelf.navigationItem.prompt = nil;
    });
}

- (void)promptForAdministratorSecret {
    if (self.promptingForSecret || self.presentedViewController) return;
    self.promptingForSecret = YES;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"管理员密钥" message:@"密钥仅保存在当前管理页面的内存中，退出页面后立即清除。" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Bearer 密钥";
        field.secureTextEntry = YES;
        field.textContentType = UITextContentTypePassword;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
        weakSelf.promptingForSecret = NO;
        [weakSelf showStatus:@"未提供管理员密钥，无法加载授权列表。" spinning:NO];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        weakSelf.promptingForSecret = NO;
        NSString *secret = NeoWCTrimmedAuthorizationID(alert.textFields.firstObject.text);
        if (secret.length == 0) { [weakSelf showStatus:@"管理员密钥不能为空。" spinning:NO]; return; }
        weakSelf.administratorSecret = secret;
        [weakSelf refreshAuthorizationList];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)refreshAuthorizationList {
    if (self.loading) return;
    if (self.administratorSecret.length == 0) { [self.refreshControl endRefreshing]; [self promptForAdministratorSecret]; return; }
    self.loading = YES;
    [self showStatus:@"正在加载授权与黑名单…" spinning:YES];
    __weak typeof(self) weakSelf = self;
    dispatch_group_t group = dispatch_group_create();
    __block NSArray<NSString *> *authorizationIDs = nil;
    __block NSArray<NSString *> *blacklistIDs = nil;
    __block NSString *failureMessage = nil;
    __block NSInteger failureStatusCode = 0;
    __block NSError *requestError = nil;

    dispatch_group_enter(group);
    NeoWCPerformAdminRequest(NeoWCAdminRequestKindAuthorizationList, self.administratorSecret, nil, ^(NSArray<NSString *> *identifiers, NSString *message, NSInteger statusCode, NSError *error) {
        if (!error && statusCode >= 200 && statusCode < 300 && identifiers) authorizationIDs = identifiers;
        else {
            failureMessage = message ?: @"授权列表加载失败。";
            failureStatusCode = statusCode;
            requestError = error;
        }
        dispatch_group_leave(group);
    });

    dispatch_group_enter(group);
    NeoWCPerformAdminRequest(NeoWCAdminRequestKindBlacklistList, self.administratorSecret, nil, ^(NSArray<NSString *> *identifiers, NSString *message, NSInteger statusCode, NSError *error) {
        if (!error && statusCode >= 200 && statusCode < 300 && identifiers) blacklistIDs = identifiers;
        else if (!failureMessage) {
            failureMessage = message ?: @"黑名单加载失败。";
            failureStatusCode = statusCode;
            requestError = error;
        }
        dispatch_group_leave(group);
    });

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NeoWCAuthorizationManagerViewController *strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.loading = NO;
        [strongSelf.refreshControl endRefreshing];
        if (requestError || !authorizationIDs || !blacklistIDs) {
            if (failureStatusCode == 401) strongSelf.administratorSecret = nil;
            [strongSelf showStatus:failureMessage ?: @"授权数据加载失败。" spinning:NO];
            [strongSelf showFailureWithTitle:@"加载失败" message:failureMessage statusCode:failureStatusCode];
            return;
        }
        strongSelf.authorizationIDs = [authorizationIDs sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        strongSelf.blacklistIDs = [blacklistIDs sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [strongSelf applySearchText:strongSelf.searchController.searchBar.text];
    });
}

- (void)applySearchText:(NSString *)searchText {
    NSString *query = NeoWCTrimmedAuthorizationID(searchText);
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSString *identifier, NSDictionary *bindings) {
        (void)bindings;
        return [identifier rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound;
    }];
    self.filteredIDs = query.length == 0 ? self.authorizationIDs : [self.authorizationIDs filteredArrayUsingPredicate:predicate];
    self.filteredBlacklistIDs = query.length == 0 ? self.blacklistIDs : [self.blacklistIDs filteredArrayUsingPredicate:predicate];
    [self.tableView reloadData];
    if (self.loading) {
        [self showStatus:@"正在处理授权数据…" spinning:YES];
        return;
    }
    BOOL showingBlacklist = self.listSelector.selectedSegmentIndex == 1;
    NSArray<NSString *> *allIDs = showingBlacklist ? self.blacklistIDs : self.authorizationIDs;
    NSArray<NSString *> *filtered = showingBlacklist ? self.filteredBlacklistIDs : self.filteredIDs;
    if (allIDs.count == 0) [self showStatus:showingBlacklist ? @"黑名单为空。" : @"授权列表为空。" spinning:NO];
    else if (filtered.count == 0) [self showStatus:@"没有匹配的 wxid。" spinning:NO];
    else [self showStatus:nil spinning:NO];
}

- (void)listSelectionChanged:(UISegmentedControl *)sender {
    self.searchController.searchBar.placeholder = sender.selectedSegmentIndex == 1 ? @"搜索黑名单" : @"搜索授权 ID";
    [self applySearchText:self.searchController.searchBar.text];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self applySearchText:searchController.searchBar.text];
}

- (void)presentAddAuthorization {
    if (self.administratorSecret.length == 0) { [self promptForAdministratorSecret]; return; }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加授权" message:@"输入需要授权的 wxid" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"wxid"; field.autocorrectionType = UITextAutocorrectionTypeNo; field.autocapitalizationType = UITextAutocapitalizationTypeNone; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"添加" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *identifier = NeoWCTrimmedAuthorizationID(alert.textFields.firstObject.text);
        if (identifier.length == 0) { [weakSelf showStatus:@"授权 ID 不能为空。" spinning:NO]; return; }
        [weakSelf performMutation:NeoWCAdminRequestKindAdd identifier:identifier];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmDeleteIdentifier:(NSString *)identifier {
    if ([NeoWCTrimmedAuthorizationID(identifier) isEqualToString:NeoWCTrimmedAuthorizationID(NeoWCCurrentUserWXID())]) {
        [self showFailureWithTitle:@"无法删除" message:@"不能删除当前管理员账号的授权。" statusCode:0];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除授权" message:[NSString stringWithFormat:@"确定删除 %@ 的授权吗？此操作不可撤销。", identifier] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) { [weakSelf performMutation:NeoWCAdminRequestKindDelete identifier:identifier]; }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmUnblacklistIdentifier:(NSString *)identifier {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"解除黑名单"
                                                                   message:[NSString stringWithFormat:@"确定解除 %@ 的使用限制吗？", identifier]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"解除" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [weakSelf performMutation:NeoWCAdminRequestKindUnblacklist identifier:identifier];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmBlacklistIdentifier:(NSString *)identifier {
    NSString *currentWXID = NeoWCTrimmedAuthorizationID(NeoWCCurrentUserWXID());
    if (identifier.length > 0 && [identifier isEqualToString:currentWXID]) {
        [self showFailureWithTitle:@"无法拉黑" message:@"不能将当前管理员账号加入黑名单。" statusCode:0];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"加入黑名单"
                                                                   message:[NSString stringWithFormat:@"确定限制 %@ 使用 NeoWC 吗？", identifier]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"拉黑" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [weakSelf performMutation:NeoWCAdminRequestKindBlacklist identifier:identifier];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)blacklistButtonTapped:(UIButton *)sender {
    NSString *identifier = NeoWCTrimmedAuthorizationID(sender.accessibilityIdentifier);
    if (identifier.length > 0) [self confirmBlacklistIdentifier:identifier];
}

- (void)unblacklistButtonTapped:(UIButton *)sender {
    NSString *identifier = NeoWCTrimmedAuthorizationID(sender.accessibilityIdentifier);
    if (identifier.length > 0) [self confirmUnblacklistIdentifier:identifier];
}

- (void)performMutation:(NeoWCAdminRequestKind)kind identifier:(NSString *)identifier {
    if (self.loading || self.administratorSecret.length == 0) return;
    if ((kind == NeoWCAdminRequestKindBlacklist || kind == NeoWCAdminRequestKindDelete) &&
        [NeoWCTrimmedAuthorizationID(identifier) isEqualToString:NeoWCTrimmedAuthorizationID(NeoWCCurrentUserWXID())]) {
        BOOL deleting = kind == NeoWCAdminRequestKindDelete;
        [self showFailureWithTitle:deleting ? @"无法删除" : @"无法拉黑"
                           message:deleting ? @"不能删除当前管理员账号的授权。" : @"不能将当前管理员账号加入黑名单。"
                        statusCode:0];
        return;
    }
    self.loading = YES;
    NSString *loadingText = kind == NeoWCAdminRequestKindAdd ? @"正在添加授权…" :
                            (kind == NeoWCAdminRequestKindDelete ? @"正在删除授权…" :
                            (kind == NeoWCAdminRequestKindBlacklist ? @"正在加入黑名单…" : @"正在解除黑名单…"));
    [self showStatus:loadingText spinning:YES];
    __weak typeof(self) weakSelf = self;
    NeoWCPerformAdminRequest(kind, self.administratorSecret, identifier, ^(NSArray<NSString *> *identifiers, NSString *message, NSInteger statusCode, NSError *error) {
        (void)identifiers;
        weakSelf.loading = NO;
        if (error || statusCode < 200 || statusCode >= 300) {
            if (statusCode == 401) weakSelf.administratorSecret = nil;
            [weakSelf showStatus:message ?: @"授权操作失败。" spinning:NO];
            [weakSelf showFailureWithTitle:@"操作失败" message:message statusCode:statusCode];
            return;
        }
        NSString *successText = kind == NeoWCAdminRequestKindAdd ? @"授权添加成功" :
                                (kind == NeoWCAdminRequestKindDelete ? @"授权删除成功" :
                                (kind == NeoWCAdminRequestKindBlacklist ? @"已加入黑名单" : @"已解除黑名单"));
        [weakSelf showTransientSuccess:successText];
        [weakSelf refreshAuthorizationList];
    });
}

- (void)showFailureWithTitle:(NSString *)title message:(NSString *)message statusCode:(NSInteger)statusCode {
    NSString *text = message.length ? message : @"请求失败，请稍后重试。";
    if (statusCode == 401) text = message.length ? message : @"管理员密钥无效，请重新输入。";
    else if (statusCode == 403) text = message.length ? message : @"没有执行此操作的管理员权限。";
    else if (statusCode == 404) text = message.length ? message : @"授权接口不存在或暂不可用。";
    else if (statusCode == 405) text = message.length ? message : @"请求方式不被授权接口允许。";
    else if (statusCode == 409) text = message.length ? message : @"该 ID 已在黑名单中。";
    else if (statusCode == 500) text = message.length ? message : @"服务器内部错误，请稍后重试。";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:text preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    if (statusCode == 401) [alert addAction:[UIAlertAction actionWithTitle:@"重新输入密钥" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf promptForAdministratorSecret]; });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.listSelector.selectedSegmentIndex == 1 ? self.filteredBlacklistIDs.count : self.filteredIDs.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return [NSString stringWithFormat:@"已授权 %lu · 黑名单 %lu",
            (unsigned long)self.authorizationIDs.count,
            (unsigned long)self.blacklistIDs.count];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    BOOL showingBlacklist = self.listSelector.selectedSegmentIndex == 1;
    NSArray<NSString *> *visibleIDs = showingBlacklist ? self.filteredBlacklistIDs : self.filteredIDs;
    if (visibleIDs.count == 0) return nil;
    return showingBlacklist ? @"轻点 wxid 或右侧按钮可解除黑名单。" : @"轻点 wxid 可删除授权，右侧按钮可加入黑名单。";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AuthorizationCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AuthorizationCell"];
    BOOL showingBlacklist = self.listSelector.selectedSegmentIndex == 1;
    NSArray<NSString *> *visibleIDs = showingBlacklist ? self.filteredBlacklistIDs : self.filteredIDs;
    NSString *identifier = visibleIDs[indexPath.row];
    cell.textLabel.text = identifier;
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.textLabel.adjustsFontForContentSizeCategory = YES;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    cell.imageView.image = [UIImage systemImageNamed:showingBlacklist ? @"hand.raised.slash" : @"checkmark.seal"];
    cell.imageView.tintColor = showingBlacklist ? UIColor.systemRedColor : UIColor.systemGreenColor;
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    actionButton.frame = CGRectMake(0.0, 0.0, 62.0, 32.0);
    actionButton.accessibilityIdentifier = identifier;
    actionButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    if (showingBlacklist) {
        actionButton.accessibilityLabel = @"解除黑名单";
        [actionButton setTitle:@"解除" forState:UIControlStateNormal];
        [actionButton addTarget:self action:@selector(unblacklistButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        actionButton.accessibilityLabel = @"加入黑名单";
        [actionButton setTitle:@"拉黑" forState:UIControlStateNormal];
        [actionButton setTitleColor:UIColor.systemRedColor forState:UIControlStateNormal];
        BOOL isCurrentAdministrator = [identifier isEqualToString:NeoWCTrimmedAuthorizationID(NeoWCCurrentUserWXID())];
        actionButton.enabled = !isCurrentAdministrator;
        if (isCurrentAdministrator) {
            [actionButton setTitle:@"当前" forState:UIControlStateDisabled];
            [actionButton setTitleColor:UIColor.tertiaryLabelColor forState:UIControlStateDisabled];
        }
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = actionButton;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    BOOL showingBlacklist = self.listSelector.selectedSegmentIndex == 1;
    NSArray<NSString *> *visibleIDs = showingBlacklist ? self.filteredBlacklistIDs : self.filteredIDs;
    if (indexPath.row >= (NSInteger)visibleIDs.count) return;
    NSString *identifier = visibleIDs[indexPath.row];
    if (showingBlacklist) [self confirmUnblacklistIdentifier:identifier];
    else [self confirmDeleteIdentifier:identifier];
}

@end
