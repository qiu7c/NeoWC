#import "NeoWCSendConfirmation.h"
#import "NeoWCAccount.h"
#import "NeoWCEnhancements.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface NeoWCSendConfirmationCoordinator : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIViewController *> *pendingAlerts;
@property (nonatomic, strong) NSMutableArray *pendingPresentations;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDate *> *temporaryAllowances;
@property (nonatomic, copy) NSString *temporaryAllowanceAccount;
+ (instancetype)sharedCoordinator;
@end

@interface NeoWCSendConfirmationAlertController : UIViewController
@property (nonatomic, copy) dispatch_block_t cancelHandler;
@property (nonatomic, copy) dispatch_block_t confirmHandler;
@property (nonatomic, copy) dispatch_block_t pauseHandler;
- (instancetype)initWithUsername:(NSString *)username displayName:(NSString *)displayName summary:(NSString *)summary;
@end

static NSString *NeoWCSendConfirmationTrimmed(NSString *value) {
    if (![value isKindOfClass:NSString.class]) return @"";
    return [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

static NSString *NeoWCSendConfirmationAccountKey(void) {
    NSString *account = NeoWCSendConfirmationTrimmed(NeoWCCurrentUserWXID());
    return account.length > 0 ? account : nil;
}

static NSInteger NeoWCSendConfirmationPauseSeconds(void) {
    NSInteger seconds = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCSendConfirmationPauseSecondsKey];
    return seconds > 0 ? seconds : 60;
}

static NSString *NeoWCSendConfirmationPauseDurationText(void) {
    NSInteger seconds = NeoWCSendConfirmationPauseSeconds();
    return seconds % 60 == 0 ?
        [NSString stringWithFormat:@"%ld 分钟", (long)(seconds / 60)] :
        [NSString stringWithFormat:@"%ld 秒", (long)seconds];
}

static NSString *NeoWCSendConfirmationPauseTitle(void) {
    return [NSString stringWithFormat:@"发送并暂停确认 %@", NeoWCSendConfirmationPauseDurationText()];
}

static NSDictionary<NSString *, NSArray<NSString *> *> *NeoWCSendConfirmationStoredMap(void) {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:NeoWCSendConfirmationUsersKey];
    return [value isKindOfClass:NSDictionary.class] ? value : @{};
}

NSArray<NSString *> *NeoWCSendConfirmationProtectedConversations(void) {
    NSString *account = NeoWCSendConfirmationAccountKey();
    if (account.length == 0) return @[];
    id value = NeoWCSendConfirmationStoredMap()[account];
    if (![value isKindOfClass:NSArray.class]) return @[];
    NSMutableOrderedSet<NSString *> *users = [NSMutableOrderedSet orderedSet];
    for (id candidate in (NSArray *)value) {
        NSString *username = NeoWCSendConfirmationTrimmed(candidate);
        if (username.length > 0) [users addObject:username];
    }
    return users.array;
}

BOOL NeoWCSendConfirmationIsProtectedConversation(NSString *username) {
    if (!NeoWCEnhancementEnabled(NeoWCSendConfirmationEnabledKey)) return NO;
    NSString *normalized = NeoWCSendConfirmationTrimmed(username);
    return normalized.length > 0 && [NeoWCSendConfirmationProtectedConversations() containsObject:normalized];
}

void NeoWCSendConfirmationSetProtected(NSString *username, BOOL protectedConversation) {
    NSString *account = NeoWCSendConfirmationAccountKey();
    NSString *normalized = NeoWCSendConfirmationTrimmed(username);
    if (account.length == 0 || normalized.length == 0) return;
    NSMutableDictionary *map = [NeoWCSendConfirmationStoredMap() mutableCopy];
    NSMutableOrderedSet<NSString *> *users = [NSMutableOrderedSet orderedSetWithArray:NeoWCSendConfirmationProtectedConversations()];
    if (protectedConversation) [users addObject:normalized];
    else [users removeObject:normalized];
    map[account] = users.array;
    [NSUserDefaults.standardUserDefaults setObject:map forKey:NeoWCSendConfirmationUsersKey];
    if (protectedConversation) {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:NeoWCSendConfirmationEnabledKey];
    }
    [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification
                                                       object:NeoWCSendConfirmationUsersKey];
}

static id NeoWCSendConfirmationContact(NSString *username) {
    Class managerClass = objc_getClass("CContactMgr");
    id manager = NeoWCServiceForClass(managerClass);
    SEL selector = sel_registerName("getContactByName:");
    if (!manager || ![manager respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL, id))objc_msgSend)(manager, selector, username);
}

static NSString *NeoWCSendConfirmationStringForSelector(id object, const char *selectorName) {
    SEL selector = sel_registerName(selectorName);
    if (!object) return nil;
    id value = nil;
    if ([object respondsToSelector:selector]) {
        value = ((id (*)(id, SEL))objc_msgSend)(object, selector);
    } else {
        @try { value = [object valueForKey:[NSString stringWithUTF8String:selectorName]]; }
        @catch (__unused NSException *exception) { return nil; }
    }
    return [value isKindOfClass:NSString.class] ? NeoWCSendConfirmationTrimmed(value) : nil;
}

@implementation NeoWCSendConfirmationAlertController {
    NSString *_username;
    NSString *_displayName;
    NSString *_summary;
}

- (instancetype)initWithUsername:(NSString *)username displayName:(NSString *)displayName summary:(NSString *)summary {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _username = [username copy];
        _displayName = [displayName copy];
        _summary = [summary copy];
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (UIView *)avatarView {
    id contact = NeoWCSendConfirmationContact(_username);
    NSString *headURL = NeoWCSendConfirmationStringForSelector(contact, "m_nsHeadImgUrl");
    Class helperClass = NSClassFromString(@"MMHeadImageHelper");
    SEL selector = NSSelectorFromString(@"getContactHeadImageViewWithUsrName:headImgUrl:bAutoUpdate:bRoundCorner:");
    if (helperClass && [helperClass respondsToSelector:selector]) {
        id view = ((id (*)(id, SEL, id, id, BOOL, BOOL))objc_msgSend)(helperClass, selector,
                                                                      _username, headURL ?: @"", YES, YES);
        if ([view isKindOfClass:UIView.class]) return view;
    }
    UIImageView *fallback = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"person.crop.circle.fill"]];
    fallback.tintColor = UIColor.tertiaryLabelColor;
    fallback.contentMode = UIViewContentModeScaleAspectFit;
    return fallback;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.38];
    UIControl *backdrop = [UIControl new];
    backdrop.translatesAutoresizingMaskIntoConstraints = NO;
    [backdrop addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backdrop];

    UIView *card = [UIView new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = UIColor.secondarySystemBackgroundColor;
    card.layer.cornerRadius = 22.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    [self.view addSubview:card];

    UIView *avatar = [self avatarView];
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    avatar.clipsToBounds = YES;
    avatar.layer.cornerRadius = 28.0;
    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = [NSString stringWithFormat:@"发送给 %@？", _displayName];
    title.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold];
    title.textAlignment = NSTextAlignmentCenter;
    title.numberOfLines = 2;
    UILabel *summary = [UILabel new];
    summary.translatesAutoresizingMaskIntoConstraints = NO;
    summary.text = _summary;
    summary.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    summary.textColor = UIColor.secondaryLabelColor;
    summary.textAlignment = NSTextAlignmentCenter;
    summary.numberOfLines = 4;
    UIButton *confirm = [UIButton buttonWithType:UIButtonTypeSystem];
    confirm.translatesAutoresizingMaskIntoConstraints = NO;
    [confirm setTitle:@"仅发送本条" forState:UIControlStateNormal];
    confirm.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    [confirm setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    confirm.backgroundColor = UIColor.systemGreenColor;
    confirm.layer.cornerRadius = 12.0;
    [confirm addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    UIButton *pause = [UIButton buttonWithType:UIButtonTypeSystem];
    pause.translatesAutoresizingMaskIntoConstraints = NO;
    [pause setTitle:NeoWCSendConfirmationPauseTitle() forState:UIControlStateNormal];
    pause.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    pause.titleLabel.adjustsFontSizeToFitWidth = YES;
    pause.titleLabel.minimumScaleFactor = 0.75;
    pause.backgroundColor = UIColor.secondarySystemFillColor;
    pause.layer.cornerRadius = 12.0;
    [pause addTarget:self action:@selector(pauseTapped) forControlEvents:UIControlEventTouchUpInside];
    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    cancel.translatesAutoresizingMaskIntoConstraints = NO;
    [cancel setTitle:@"取消" forState:UIControlStateNormal];
    cancel.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    cancel.backgroundColor = UIColor.tertiarySystemFillColor;
    cancel.layer.cornerRadius = 12.0;
    [cancel addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *buttons = [[UIStackView alloc] initWithArrangedSubviews:@[confirm, pause, cancel]];
    buttons.translatesAutoresizingMaskIntoConstraints = NO;
    buttons.axis = UILayoutConstraintAxisVertical;
    buttons.spacing = 10.0;
    buttons.distribution = UIStackViewDistributionFillEqually;
    [card addSubview:avatar];
    [card addSubview:title];
    [card addSubview:summary];
    [card addSubview:buttons];
    [NSLayoutConstraint activateConstraints:@[
        [backdrop.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [backdrop.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [backdrop.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [backdrop.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [card.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:28.0],
        [card.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-28.0],
        [card.widthAnchor constraintEqualToConstant:MIN(UIScreen.mainScreen.bounds.size.width * 0.80, 360.0)],
        [avatar.topAnchor constraintEqualToAnchor:card.topAnchor constant:24.0],
        [avatar.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [avatar.widthAnchor constraintEqualToConstant:56.0],
        [avatar.heightAnchor constraintEqualToConstant:56.0],
        [title.topAnchor constraintEqualToAnchor:avatar.bottomAnchor constant:13.0],
        [title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22.0],
        [title.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22.0],
        [summary.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8.0],
        [summary.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [summary.trailingAnchor constraintEqualToAnchor:title.trailingAnchor],
        [buttons.topAnchor constraintEqualToAnchor:summary.bottomAnchor constant:22.0],
        [buttons.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.0],
        [buttons.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16.0],
        [buttons.heightAnchor constraintEqualToConstant:164.0],
        [buttons.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16.0],
    ]];
}

- (void)cancelTapped {
    dispatch_block_t handler = self.cancelHandler;
    [self dismissViewControllerAnimated:YES completion:handler];
}

- (void)confirmTapped {
    dispatch_block_t handler = self.confirmHandler;
    [self dismissViewControllerAnimated:YES completion:handler];
}

- (void)pauseTapped {
    dispatch_block_t handler = self.pauseHandler;
    [self dismissViewControllerAnimated:YES completion:handler];
}

@end

NSString *NeoWCSendConfirmationDisplayName(NSString *username) {
    NSString *normalized = NeoWCSendConfirmationTrimmed(username);
    if (normalized.length == 0) return @"未知会话";
    id contact = NeoWCSendConfirmationContact(normalized);
    NSString *name = NeoWCSendConfirmationStringForSelector(contact, "m_nsRemark");
    if (name.length == 0) name = NeoWCSendConfirmationStringForSelector(contact, "m_nsNickName");
    return name.length > 0 ? name : normalized;
}

static void NeoWCShowSendConfirmationToast(UIViewController *presenter, NSString *text) {
    UIWindow *window = presenter.view.window;
    if (!window) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive ||
                ![scene isKindOfClass:UIWindowScene.class]) continue;
            for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
                if (candidate.isKeyWindow) { window = candidate; break; }
                if (!window && !candidate.hidden && candidate.alpha > 0.0 &&
                    candidate.windowLevel == UIWindowLevelNormal) window = candidate;
            }
            if (window.isKeyWindow) break;
        }
    }
    UIView *hostView = presenter.view.window ? presenter.view : window.rootViewController.view;
    if (!hostView) return;
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.92];
    label.layer.cornerRadius = 11.0;
    label.layer.cornerCurve = kCACornerCurveContinuous;
    label.layer.masksToBounds = YES;
    label.alpha = 0.0;
    [hostView addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:hostView.centerXAnchor],
        [label.bottomAnchor constraintEqualToAnchor:hostView.safeAreaLayoutGuide.bottomAnchor constant:-36.0],
        [label.heightAnchor constraintGreaterThanOrEqualToConstant:38.0],
        [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:hostView.leadingAnchor constant:24.0],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:hostView.trailingAnchor constant:-24.0],
    ]];
    [UIView animateWithDuration:0.18 animations:^{ label.alpha = 1.0; }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.2 animations:^{ label.alpha = 0.0; }
                         completion:^(__unused BOOL finished) { [label removeFromSuperview]; }];
    });
}

@implementation NeoWCSendConfirmationCoordinator

+ (instancetype)sharedCoordinator {
    static NeoWCSendConfirmationCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ coordinator = [NeoWCSendConfirmationCoordinator new]; });
    return coordinator;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pendingAlerts = [NSMutableDictionary dictionary];
        _pendingPresentations = [NSMutableArray array];
        _temporaryAllowances = [NSMutableDictionary dictionary];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationDidEnterBackground)
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];
    }
    return self;
}

- (void)applicationDidEnterBackground {
    [self cancelAll];
}

- (void)cancelAll {
    NSArray<UIViewController *> *alerts = self.pendingAlerts.allValues;
    [self.pendingAlerts removeAllObjects];
    [self.pendingPresentations removeAllObjects];
    [self.temporaryAllowances removeAllObjects];
    for (UIViewController *alert in alerts) {
        if (alert.presentingViewController) [alert dismissViewControllerAnimated:NO completion:nil];
    }
}

- (NSString *)temporaryAllowanceKeyForUsername:(NSString *)username {
    NSString *account = NeoWCSendConfirmationAccountKey();
    if (![self.temporaryAllowanceAccount isEqualToString:account]) {
        [self.temporaryAllowances removeAllObjects];
        self.temporaryAllowanceAccount = account;
    }
    return account.length > 0 && username.length > 0 ?
        [NSString stringWithFormat:@"%@\n%@", account, username] : nil;
}

- (BOOL)isTemporarilyAllowedUsername:(NSString *)username {
    NSString *key = [self temporaryAllowanceKeyForUsername:username];
    NSDate *deadline = key ? self.temporaryAllowances[key] : nil;
    if (!deadline) return NO;
    if ([deadline timeIntervalSinceNow] > 0.0) return YES;
    [self.temporaryAllowances removeObjectForKey:key];
    return NO;
}

- (void)allowUsernameTemporarily:(NSString *)username {
    NSString *key = [self temporaryAllowanceKeyForUsername:username];
    if (key) self.temporaryAllowances[key] = [NSDate dateWithTimeIntervalSinceNow:NeoWCSendConfirmationPauseSeconds()];
}

- (void)presentNextIfNeeded {
    if (self.pendingAlerts.count > 0 || self.pendingPresentations.count == 0) return;
    dispatch_block_t next = self.pendingPresentations.firstObject;
    [self.pendingPresentations removeObjectAtIndex:0];
    dispatch_async(dispatch_get_main_queue(), next);
}

- (BOOL)presentFrom:(UIViewController *)presenter
           username:(NSString *)username
            summary:(NSString *)summary
          validator:(NeoWCSendConfirmationValidator)validator
          confirmed:(dispatch_block_t)confirmedAction {
    if (!presenter.view.window || !NeoWCSendConfirmationIsProtectedConversation(username)) return NO;
    if ([self isTemporarilyAllowedUsername:username]) {
        if (!validator || validator()) {
            if (confirmedAction) confirmedAction();
        }
        return YES;
    }
    if (self.pendingAlerts.count > 0) {
        UIViewController *queuedPresenter = presenter;
        while ([queuedPresenter isKindOfClass:NeoWCSendConfirmationAlertController.class] &&
               queuedPresenter.presentingViewController) {
            queuedPresenter = queuedPresenter.presentingViewController;
        }
        NSString *retainedUsername = [username copy];
        NSString *retainedSummary = [summary copy];
        NeoWCSendConfirmationValidator retainedValidator = [validator copy];
        dispatch_block_t retainedAction = [confirmedAction copy];
        __weak typeof(self) weakSelf = self;
        [self.pendingPresentations addObject:^{
            NeoWCSendConfirmationCoordinator *strongSelf = weakSelf;
            if (!strongSelf || !queuedPresenter.view.window ||
                (retainedValidator && !retainedValidator())) {
                [strongSelf presentNextIfNeeded];
                return;
            }
            BOOL presented = [strongSelf presentFrom:queuedPresenter
                                            username:retainedUsername
                                             summary:retainedSummary
                                           validator:retainedValidator
                                           confirmed:retainedAction];
            if (!presented) [strongSelf presentNextIfNeeded];
        }];
        return YES;
    }
    NSString *token = NSUUID.UUID.UUIDString;
    NSString *displayName = NeoWCSendConfirmationDisplayName(username);
    NSString *message = NeoWCSendConfirmationTrimmed(summary);
    if (message.length == 0) message = @"请确认消息内容和接收人。";
    NeoWCSendConfirmationAlertController *alert = [[NeoWCSendConfirmationAlertController alloc] initWithUsername:username
                                                                                                     displayName:displayName
                                                                                                         summary:message];
    __weak typeof(self) weakSelf = self;
    alert.cancelHandler = ^{
        NeoWCSendConfirmationCoordinator *strongSelf = weakSelf;
        [strongSelf.pendingAlerts removeObjectForKey:token];
        [strongSelf presentNextIfNeeded];
    };
    alert.confirmHandler = ^{
        NeoWCSendConfirmationCoordinator *strongSelf = weakSelf;
        if (!strongSelf.pendingAlerts[token]) return;
        [strongSelf.pendingAlerts removeObjectForKey:token];
        BOOL valid = !validator || validator();
        if (valid && confirmedAction) confirmedAction();
        [strongSelf presentNextIfNeeded];
    };
    alert.pauseHandler = ^{
        NeoWCSendConfirmationCoordinator *strongSelf = weakSelf;
        if (!strongSelf.pendingAlerts[token]) return;
        [strongSelf.pendingAlerts removeObjectForKey:token];
        BOOL valid = !validator || validator();
        if (valid) {
            [strongSelf allowUsernameTemporarily:username];
            if (confirmedAction) confirmedAction();
            NeoWCShowSendConfirmationToast(presenter,
                                            [NSString stringWithFormat:@"本会话发送确认已暂停 %@",
                                             NeoWCSendConfirmationPauseDurationText()]);
        }
        [strongSelf presentNextIfNeeded];
    };
    self.pendingAlerts[token] = alert;
    [presenter presentViewController:alert animated:YES completion:nil];
    __weak NeoWCSendConfirmationAlertController *weakAlert = alert;
    __weak typeof(self) weakCoordinator = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NeoWCSendConfirmationCoordinator *strongCoordinator = weakCoordinator;
        NeoWCSendConfirmationAlertController *strongAlert = weakAlert;
        if (!strongCoordinator.pendingAlerts[token] || strongAlert.presentingViewController || strongAlert.view.window) return;
        [strongCoordinator.pendingAlerts removeObjectForKey:token];
        NeoWCShowSendConfirmationToast(presenter, @"确认窗口未能显示，本次发送已取消");
        [strongCoordinator presentNextIfNeeded];
    });
    return YES;
}

@end

BOOL NeoWCPresentSendConfirmationIfNeeded(UIViewController *presenter,
                                           NSString *username,
                                           NSString *summary,
                                           NeoWCSendConfirmationValidator validator,
                                           dispatch_block_t confirmedAction) {
    if (!presenter || username.length == 0 || !confirmedAction) return NO;
    return [[NeoWCSendConfirmationCoordinator sharedCoordinator] presentFrom:presenter
                                                                    username:username
                                                                     summary:summary
                                                                   validator:validator
                                                                   confirmed:confirmedAction];
}

void NeoWCCancelPendingSendConfirmations(void) {
    [[NeoWCSendConfirmationCoordinator sharedCoordinator] cancelAll];
}
