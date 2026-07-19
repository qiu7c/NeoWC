#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "Sources/NeoWCSettingsViewController.h"
#import "Sources/NeoWCAntiRevoke.h"
#import "Sources/NeoWCChatCapture.h"
#import "Sources/NeoWCDebug.h"
#import "Sources/NeoWCEnhancements.h"
#import "Sources/NeoWCPluginVisibility.h"

@interface WCPluginsMgr : NSObject
+ (instancetype)sharedInstance;
- (void)registerControllerWithTitle:(NSString *)title
                            version:(NSString *)version
                         controller:(NSString *)controller;
- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key;
@end

@interface WCPluginsViewController : UIViewController
@end

@interface MultiDeviceCardLoginContentView : UIView
- (void)onTapConfirmButton;
@end

@interface MMAuthorizeUserInfoViewController : UIViewController
@end

@interface WCTimeLineCellView : UIView
- (void)onAccessibilityLike;
- (void)onAccessibilityComment;
- (id)operateBtnImage:(BOOL)spring isSpringStyle:(BOOL)springStyle;
- (void)neowc_handleMomentsDoubleTap;
@end

@interface WCTimeLineOperateButtonView : UIButton
@end

@interface CMessageWrap : NSObject
@property (nonatomic, assign) NSUInteger m_uiMessageType;
@property (nonatomic, assign) NSUInteger m_uiGameType;
@property (nonatomic, assign) NSUInteger m_uiGameContent;
@property (nonatomic, copy) NSString *m_nsEmoticonMD5;
@end

@interface CMessageMgr : NSObject
- (void)AddEmoticonMsg:(NSString *)message MsgWrap:(CMessageWrap *)wrap;
- (void)onNewSyncNotAddDBMessage:(CMessageWrap *)wrap;
@end

@interface WCDeviceStepObject : NSObject
- (unsigned int)m7StepCount;
@end

@interface WCDataItem : NSObject
- (BOOL)isAd;
- (BOOL)isVideoAd;
@end

@interface WAAppTaskSplashADConfig : NSObject
- (BOOL)canShowSplashADWindow;
- (BOOL)launchShow;
@end

static BOOL NeoWCDidRegister = NO;
static char NeoWCDeviceCardDidConfirmKey;
static char NeoWCGameDidAuthorizeKey;
static char NeoWCMomentsDoubleTapRecognizerKey;
static char NeoWCGameSelectorPresentedKey;
static char NeoWCChatCaptureBuildingMenuKey;

static id NeoWCTweakSafeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static void NeoWCTweakSetValue(id object, NSString *key, id value) {
    if (!object || key.length == 0) return;
    @try {
        [object setValue:value forKey:key];
    } @catch (__unused NSException *exception) {
    }
}

static NSString *NeoWCGameMD5ForContent(NSUInteger content) {
    Class gameControllerClass = objc_getClass("GameController");
    SEL selector = sel_registerName("getMD5ByGameContent:");
    if (!gameControllerClass || ![gameControllerClass respondsToSelector:selector]) return nil;
    return ((NSString *(*)(id, SEL, NSUInteger))objc_msgSend)(gameControllerClass, selector, content);
}

static void NeoWCSynchronizeMomentsCell(WCTimeLineCellView *cell) {
    if (!cell) return;
    UITapGestureRecognizer *recognizer = objc_getAssociatedObject(cell, &NeoWCMomentsDoubleTapRecognizerKey);
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCMomentsDoubleTapLikeKey);
    if (enabled && !recognizer) {
        recognizer = [[UITapGestureRecognizer alloc] initWithTarget:cell action:@selector(neowc_handleMomentsDoubleTap)];
        recognizer.numberOfTapsRequired = 2;
        recognizer.cancelsTouchesInView = NO;
        [cell addGestureRecognizer:recognizer];
        objc_setAssociatedObject(cell, &NeoWCMomentsDoubleTapRecognizerKey, recognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (!enabled && recognizer) {
        [cell removeGestureRecognizer:recognizer];
        objc_setAssociatedObject(cell, &NeoWCMomentsDoubleTapRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void NeoWCSynchronizeMomentsCellsInView(UIView *view) {
    if (!view) return;
    Class cellClass = NSClassFromString(@"WCTimeLineCellView");
    if (cellClass && [view isKindOfClass:cellClass]) NeoWCSynchronizeMomentsCell((WCTimeLineCellView *)view);
    for (UIView *subview in view.subviews) NeoWCSynchronizeMomentsCellsInView(subview);
}

static void NeoWCSynchronizeVisibleMomentsCells(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (![scene isKindOfClass:[UIWindowScene class]]) continue;
                for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                    if (!window.hidden) NeoWCSynchronizeMomentsCellsInView(window);
                }
            }
            return;
        }
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            if (!window.hidden) NeoWCSynchronizeMomentsCellsInView(window);
        }
    });
}

static UIButton *NeoWCFindButton(NSString *title, UIView *rootView) {
    if (!rootView || title.length == 0) return nil;
    for (UIView *subview in rootView.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            NSString *buttonTitle = button.currentTitle ?: button.currentAttributedTitle.string;
            if ([buttonTitle isEqualToString:title] && button.enabled && !button.hidden && button.alpha > 0.01) return button;
        }
        UIButton *button = NeoWCFindButton(title, subview);
        if (button) return button;
    }
    return nil;
}

static UIViewController *NeoWCTopControllerForLoginToast(UIViewController *controller) {
    if (controller.presentedViewController) return NeoWCTopControllerForLoginToast(controller.presentedViewController);
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return NeoWCTopControllerForLoginToast(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return NeoWCTopControllerForLoginToast(((UITabBarController *)controller).selectedViewController);
    }
    return controller;
}

static UIWindow *NeoWCActiveApplicationWindow(void) {
    if (@available(iOS 13.0, *)) {
        UIWindow *fallbackWindow = nil;
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive || ![scene isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
                if (candidate.isKeyWindow) return candidate;
                if (!candidate.hidden && candidate.alpha > 0.0 && !fallbackWindow) fallbackWindow = candidate;
            }
        }
        if (fallbackWindow) return fallbackWindow;
    }
    for (UIWindow *candidate in UIApplication.sharedApplication.windows) {
        if (candidate.isKeyWindow) return candidate;
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

@interface NeoWCGameSelectorViewController : UIViewController
@property (nonatomic, copy) NSString *sourceType;
@property (nonatomic, copy) void (^selectionHandler)(NSUInteger value, NSString *title);
@property (nonatomic, copy) void (^cancelHandler)(void);
@property (nonatomic, strong) UIButton *dimmingButton;
@property (nonatomic, strong) UIView *sheetView;
@end

@implementation NeoWCGameSelectorViewController

- (UIButton *)choiceButtonWithTitle:(NSString *)title symbol:(NSString *)symbol value:(NSUInteger)value {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tag = (NSInteger)value;
    button.backgroundColor = [UIColor secondarySystemFillColor];
    button.layer.cornerRadius = 16.0;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.accessibilityLabel = title;
    [button addTarget:self action:@selector(choiceTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:symbol]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.tintColor = [UIColor labelColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.userInteractionEnabled = NO;

    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = title;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.textColor = [UIColor labelColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.userInteractionEnabled = NO;

    [button addSubview:imageView];
    [button addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [imageView.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
        [imageView.topAnchor constraintEqualToAnchor:button.topAnchor constant:11.0],
        [imageView.widthAnchor constraintEqualToConstant:24.0],
        [imageView.heightAnchor constraintEqualToConstant:24.0],
        [label.leadingAnchor constraintEqualToAnchor:button.leadingAnchor constant:4.0],
        [label.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-4.0],
        [label.topAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:5.0],
        [label.bottomAnchor constraintLessThanOrEqualToAnchor:button.bottomAnchor constant:-8.0],
    ]];
    return button;
}

- (UIStackView *)rowWithButtons:(NSArray<UIButton *> *)buttons height:(CGFloat)height {
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:buttons];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentFill;
    row.distribution = UIStackViewDistributionFillEqually;
    row.spacing = 10.0;
    [row.heightAnchor constraintEqualToConstant:height].active = YES;
    return row;
}

- (UILabel *)sectionLabel:(NSString *)text {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    label.textColor = [UIColor secondaryLabelColor];
    return label;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    UIButton *dimmingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dimmingButton.translatesAutoresizingMaskIntoConstraints = NO;
    dimmingButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.32];
    dimmingButton.alpha = 0.0;
    [dimmingButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dimmingButton];
    self.dimmingButton = dimmingButton;

    UIView *sheet = [UIView new];
    sheet.translatesAutoresizingMaskIntoConstraints = NO;
    sheet.backgroundColor = [UIColor systemBackgroundColor];
    sheet.layer.cornerRadius = 28.0;
    sheet.layer.cornerCurve = kCACornerCurveContinuous;
    sheet.layer.masksToBounds = YES;
    [self.view addSubview:sheet];
    self.sheetView = sheet;

    UIView *grabber = [UIView new];
    grabber.translatesAutoresizingMaskIntoConstraints = NO;
    grabber.backgroundColor = [UIColor tertiaryLabelColor];
    grabber.layer.cornerRadius = 2.5;
    UIView *grabberContainer = [UIView new];
    [grabberContainer addSubview:grabber];
    [NSLayoutConstraint activateConstraints:@[
        [grabber.centerXAnchor constraintEqualToAnchor:grabberContainer.centerXAnchor],
        [grabber.topAnchor constraintEqualToAnchor:grabberContainer.topAnchor],
        [grabber.bottomAnchor constraintEqualToAnchor:grabberContainer.bottomAnchor],
        [grabber.widthAnchor constraintEqualToConstant:38.0],
        [grabber.heightAnchor constraintEqualToConstant:5.0],
    ]];

    UILabel *title = [UILabel new];
    title.text = @"选择小游戏结果";
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    title.textColor = [UIColor labelColor];

    UILabel *subtitle = [UILabel new];
    subtitle.text = [NSString stringWithFormat:@"当前：%@ · 支持跨类型彩蛋", self.sourceType ?: @"小游戏"];
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    subtitle.textColor = [UIColor secondaryLabelColor];

    UIStackView *guessRow = [self rowWithButtons:@[
        [self choiceButtonWithTitle:@"剪刀" symbol:@"scissors" value:1],
        [self choiceButtonWithTitle:@"石头" symbol:@"circle.fill" value:2],
        [self choiceButtonWithTitle:@"布" symbol:@"hand.raised" value:3],
    ] height:70.0];

    UIStackView *diceRowOne = [self rowWithButtons:@[
        [self choiceButtonWithTitle:@"1 点" symbol:@"die.face.1" value:4],
        [self choiceButtonWithTitle:@"2 点" symbol:@"die.face.2" value:5],
        [self choiceButtonWithTitle:@"3 点" symbol:@"die.face.3" value:6],
    ] height:64.0];
    UIStackView *diceRowTwo = [self rowWithButtons:@[
        [self choiceButtonWithTitle:@"4 点" symbol:@"die.face.4" value:7],
        [self choiceButtonWithTitle:@"5 点" symbol:@"die.face.5" value:8],
        [self choiceButtonWithTitle:@"6 点" symbol:@"die.face.6" value:9],
    ] height:64.0];

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.backgroundColor = [UIColor secondarySystemFillColor];
    cancelButton.layer.cornerRadius = 16.0;
    cancelButton.layer.cornerCurve = kCACornerCurveContinuous;
    cancelButton.tintColor = [UIColor labelColor];
    cancelButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [cancelButton setTitle:@"取消发送" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton.heightAnchor constraintEqualToConstant:50.0].active = YES;

    UIStackView *content = [[UIStackView alloc] initWithArrangedSubviews:@[
        grabberContainer, title, subtitle, [self sectionLabel:@"猜拳"], guessRow,
        [self sectionLabel:@"骰子"], diceRowOne, diceRowTwo, cancelButton,
    ]];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentFill;
    content.spacing = 10.0;
    [content setCustomSpacing:18.0 afterView:subtitle];
    [content setCustomSpacing:8.0 afterView:grabberContainer];
    [content setCustomSpacing:14.0 afterView:guessRow];
    [sheet addSubview:content];

    NSLayoutConstraint *phoneWidth = [sheet.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-28.0];
    phoneWidth.priority = UILayoutPriorityDefaultHigh;
    [NSLayoutConstraint activateConstraints:@[
        [dimmingButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [dimmingButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [dimmingButton.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [dimmingButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [sheet.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [sheet.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-10.0],
        [sheet.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:14.0],
        [sheet.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-14.0],
        [sheet.widthAnchor constraintLessThanOrEqualToConstant:520.0],
        phoneWidth,
        [content.leadingAnchor constraintEqualToAnchor:sheet.leadingAnchor constant:18.0],
        [content.trailingAnchor constraintEqualToAnchor:sheet.trailingAnchor constant:-18.0],
        [content.topAnchor constraintEqualToAnchor:sheet.topAnchor constant:10.0],
        [content.bottomAnchor constraintEqualToAnchor:sheet.safeAreaLayoutGuide.bottomAnchor constant:-16.0],
    ]];
    self.sheetView.transform = CGAffineTransformMakeTranslation(0.0, 480.0);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.30 delay:0.0 usingSpringWithDamping:0.88 initialSpringVelocity:0.15 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.dimmingButton.alpha = 1.0;
        self.sheetView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)choiceTapped:(UIButton *)sender {
    NSArray<NSString *> *titles = @[@"", @"剪刀", @"石头", @"布", @"骰子 1", @"骰子 2", @"骰子 3", @"骰子 4", @"骰子 5", @"骰子 6"];
    NSUInteger value = (NSUInteger)sender.tag;
    NSString *title = value < titles.count ? titles[value] : @"未知结果";
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.selectionHandler) self.selectionHandler(value, title);
    }];
}

- (void)cancelTapped {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.cancelHandler) self.cancelHandler();
    }];
}

@end

static void NeoWCShowLoginToast(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = NeoWCActiveApplicationWindow();
        UIViewController *controller = NeoWCTopControllerForLoginToast(window.rootViewController);
        if (!controller.view.window) return;

        UILabel *toast = [UILabel new];
        toast.translatesAutoresizingMaskIntoConstraints = NO;
        toast.text = message;
        toast.textAlignment = NSTextAlignmentCenter;
        toast.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        toast.textColor = UIColor.whiteColor;
        toast.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.90];
        toast.layer.cornerRadius = 12.0;
        toast.layer.cornerCurve = kCACornerCurveContinuous;
        toast.layer.masksToBounds = YES;
        toast.userInteractionEnabled = NO;
        [controller.view addSubview:toast];
        [NSLayoutConstraint activateConstraints:@[
            [toast.centerXAnchor constraintEqualToAnchor:controller.view.centerXAnchor],
            [toast.bottomAnchor constraintEqualToAnchor:controller.view.safeAreaLayoutGuide.bottomAnchor constant:-44.0],
            [toast.heightAnchor constraintEqualToConstant:40.0],
            [toast.widthAnchor constraintGreaterThanOrEqualToConstant:164.0],
        ]];
        toast.alpha = 0.0;
        [UIView animateWithDuration:0.18 animations:^{ toast.alpha = 1.0; }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{ toast.alpha = 0.0; } completion:^(__unused BOOL finished) { [toast removeFromSuperview]; }];
        });
    });
}

static BOOL NeoWCTryAuthorizeGame(MMAuthorizeUserInfoViewController *controller) {
    if (!controller || !NeoWCEnhancementEnabled(NeoWCAutoGameAuthorizeKey)) return NO;
    if ([objc_getAssociatedObject(controller, &NeoWCGameDidAuthorizeKey) boolValue]) return YES;
    UIButton *allowButton = NeoWCFindButton(@"允许", controller.view);
    if (!allowButton || !allowButton.window) return NO;
    objc_setAssociatedObject(controller, &NeoWCGameDidAuthorizeKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [allowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    NeoWCLog(@"已自动允许游戏扫码授权");
    NeoWCShowLoginToast(@"已自动允许游戏授权");
    return YES;
}

static void NeoWCRegisterPlugin(void) {
    if (NeoWCDidRegister) return;

    Class managerClass = NSClassFromString(@"WCPluginsMgr");
    if (!managerClass || ![managerClass respondsToSelector:@selector(sharedInstance)]) return;

    WCPluginsMgr *manager = [managerClass sharedInstance];
    if (!manager) return;

    [manager registerControllerWithTitle:@"NeoWC"
                                 version:@"0.1.0"
                              controller:NSStringFromClass([NeoWCSettingsViewController class])];
    NeoWCDidRegister = YES;
    NeoWCLog(@"已注册 WCPluginsMgr 设置入口");
}

@interface NeoWCEntryLoader : NSObject
@end

@implementation NeoWCEntryLoader

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        NeoWCRegisterPlugin();

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        NeoWCRegisterPlugin();
                        [[NeoWCDebugManager sharedManager] applySavedState];
                    }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:NeoWCEnhancementDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        NeoWCSynchronizeVisibleMomentsCells();
                    }];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            NeoWCRegisterPlugin();
            [[NeoWCDebugManager sharedManager] applySavedState];
        });
    });
}

@end

%hook NewSettingViewController

- (void)viewDidLoad {
    %orig;
    NeoWCRegisterPlugin();
}

%end

%hook WCPluginsMgr

- (void)registerControllerWithTitle:(NSString *)title version:(NSString *)version controller:(NSString *)controller {
    %orig;
    [[NeoWCPluginVisibilityManager sharedManager] recordControllerWithTitle:title version:version controller:controller];
}

- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key {
    %orig;
    [[NeoWCPluginVisibilityManager sharedManager] recordSwitchWithTitle:title key:key];
}

%end

%hook WCPluginsViewController

- (void)reloadTableData {
    NeoWCFilterPluginListController(self);
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    NeoWCFilterPluginListController(self);
    %orig;
}

%end

%hook BaseMsgContentViewController

- (void)ShowMultiSelectMoreOperation:(id)argument {
    if (!NeoWCEnhancementEnabled(NeoWCChatCaptureEnabledKey)) {
        %orig;
        return;
    }
    objc_setAssociatedObject(self, &NeoWCChatCaptureBuildingMenuKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig;
    objc_setAssociatedObject(self, &NeoWCChatCaptureBuildingMenuKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)scrollActionSheet:(id)sheet didSelecteItem:(id)item {
    NSString *identifier = NeoWCTweakSafeValue(item, @"userInfo");
    if ([identifier isEqualToString:NeoWCChatCaptureActionIdentifier()] && NeoWCEnhancementEnabled(NeoWCChatCaptureEnabledKey)) {
        NeoWCStartChatCapture((UIViewController *)self);
        return;
    }
    %orig;
}

%end

%hook MMScrollActionSheet

- (void)showInView:(UIView *)view {
    id delegate = NeoWCTweakSafeValue(self, @"delegate");
    BOOL isCaptureMenu = [objc_getAssociatedObject(delegate, &NeoWCChatCaptureBuildingMenuKey) boolValue];
    if (isCaptureMenu && NeoWCEnhancementEnabled(NeoWCChatCaptureEnabledKey)) {
        NSArray *originalRows = NeoWCTweakSafeValue(self, @"itemArray");
        if ([originalRows isKindOfClass:[NSArray class]] && originalRows.count > 0) {
            NSMutableArray *rows = [NSMutableArray arrayWithCapacity:originalRows.count];
            BOOL alreadyAdded = NO;
            for (id originalRow in originalRows) {
                NSMutableArray *row = [originalRow isKindOfClass:[NSArray class]] ? [originalRow mutableCopy] : [NSMutableArray array];
                for (id existingItem in row) {
                    if ([NeoWCTweakSafeValue(existingItem, @"userInfo") isEqualToString:NeoWCChatCaptureActionIdentifier()]) {
                        alreadyAdded = YES;
                    }
                }
                [rows addObject:row];
            }
            if (!alreadyAdded) {
                Class itemClass = NSClassFromString(@"MMScrollActionSheetItem");
                id captureItem = itemClass ? [itemClass new] : nil;
                if (captureItem) {
                    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:22.0 weight:UIImageSymbolWeightRegular];
                    UIImage *icon = [UIImage systemImageNamed:@"rectangle.dashed" withConfiguration:configuration];
                    icon = [icon imageWithTintColor:[UIColor labelColor] renderingMode:UIImageRenderingModeAlwaysOriginal];
                    NeoWCTweakSetValue(captureItem, @"title", @"截图");
                    NeoWCTweakSetValue(captureItem, @"iconImg", icon);
                    NeoWCTweakSetValue(captureItem, @"userInfo", NeoWCChatCaptureActionIdentifier());
                    [(NSMutableArray *)rows.firstObject addObject:captureItem];
                }
            }
            NeoWCTweakSetValue(self, @"itemArray", rows);
        }
    }
    %orig;
}

%end

%hook WCTimeLineCellView

- (void)initView {
    %orig;
    NeoWCSynchronizeMomentsCell(self);
    if (NeoWCEnhancementEnabled(NeoWCMomentsQuickCommentKey)) {
        @try {
            UIView *operateButton = [self valueForKey:@"m_operateBtn"];
            if ([operateButton isKindOfClass:NSClassFromString(@"WCTimeLineOperateButtonView")]) {
                for (UIView *subview in operateButton.subviews) {
                    if ([subview isKindOfClass:[UIImageView class]]) subview.hidden = YES;
                }
                operateButton.tintColor = [UIColor darkGrayColor];
            }
        } @catch (__unused NSException *exception) {
            NeoWCLog(@"当前微信版本无法调整朋友圈操作按钮外观");
        }
    }
}

- (void)didMoveToWindow {
    %orig;
    NeoWCSynchronizeMomentsCell(self);
}

%new
- (void)neowc_handleMomentsDoubleTap {
    if (!NeoWCEnhancementEnabled(NeoWCMomentsDoubleTapLikeKey)) return;
    [self onAccessibilityLike];
    NeoWCLog(@"已通过双击点赞朋友圈");
}

- (id)operateBtnImage:(BOOL)spring isSpringStyle:(BOOL)springStyle {
    if (NeoWCEnhancementEnabled(NeoWCMomentsQuickCommentKey)) {
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:16.0 weight:UIImageSymbolWeightMedium];
        return [[UIImage systemImageNamed:@"bubble.middle.bottom" withConfiguration:configuration] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return %orig;
}

%end

%hook WCTimeLineOperateButtonView

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (NeoWCEnhancementEnabled(NeoWCMomentsQuickCommentKey)) {
        UIView *ancestor = self.superview;
        Class cellClass = NSClassFromString(@"WCTimeLineCellView");
        while (ancestor) {
            if (cellClass && [ancestor isKindOfClass:cellClass]) {
                [(WCTimeLineCellView *)ancestor onAccessibilityComment];
                NeoWCLog(@"已通过快捷按钮打开朋友圈评论");
                return;
            }
            ancestor = ancestor.superview;
        }
    }
    %orig;
}

%end

%hook CMessageMgr

- (void)onNewSyncNotAddDBMessage:(CMessageWrap *)wrap {
    if (NeoWCHandleRevokeMessage(self, wrap)) return;
    %orig;
}

- (void)AddEmoticonMsg:(NSString *)message MsgWrap:(CMessageWrap *)wrap {
    BOOL isGameMessage = wrap.m_uiMessageType == 47 && (wrap.m_uiGameType == 1 || wrap.m_uiGameType == 2);
    if (!NeoWCEnhancementEnabled(NeoWCGameSelectorKey) || !isGameMessage) {
        %orig;
        return;
    }
    if ([objc_getAssociatedObject(wrap, &NeoWCGameSelectorPresentedKey) boolValue]) return;

    UIWindow *window = NeoWCActiveApplicationWindow();
    UIViewController *presenter = NeoWCTopControllerForLoginToast(window.rootViewController);
    if (!presenter.view.window) {
        %orig;
        return;
    }

    objc_setAssociatedObject(wrap, &NeoWCGameSelectorPresentedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCGameSelectorViewController *selector = [NeoWCGameSelectorViewController new];
    selector.sourceType = wrap.m_uiGameType == 1 ? @"猜拳" : @"骰子";
    selector.modalPresentationStyle = UIModalPresentationOverFullScreen;
    selector.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    selector.selectionHandler = ^(NSUInteger value, NSString *title) {
        NSString *gameMD5 = NeoWCGameMD5ForContent(value);
        if (gameMD5.length > 0) wrap.m_nsEmoticonMD5 = gameMD5;
        wrap.m_uiGameContent = value;
        objc_setAssociatedObject(wrap, &NeoWCGameSelectorPresentedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NeoWCLog(@"小游戏结果已选择：%@（原始值 %lu）", title, (unsigned long)value);
        %orig(message, wrap);
    };
    selector.cancelHandler = ^{
        objc_setAssociatedObject(wrap, &NeoWCGameSelectorPresentedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    };
    [presenter presentViewController:selector animated:YES completion:nil];
}

%end

%hook WCDeviceStepObject

- (unsigned int)m7StepCount {
    unsigned int originalValue = %orig;
    if (!NeoWCEnhancementEnabled(NeoWCStepOverrideEnabledKey)) return originalValue;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *configuredDate = [defaults objectForKey:NeoWCStepCountDateKey];
    if (![configuredDate isKindOfClass:[NSDate class]] || ![[NSCalendar currentCalendar] isDateInToday:configuredDate]) return originalValue;
    NSInteger configuredValue = [defaults integerForKey:NeoWCStepCountKey];
    return configuredValue > 0 ? (unsigned int)MIN(100000, configuredValue) : originalValue;
}

%end

%hook WCDataItem

- (BOOL)isAd {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)isVideoAd {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

%end

%hook WAAppTaskSplashADConfig

- (BOOL)canShowSplashADWindow {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)launchShow {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

%end

%hook MultiDeviceCardLoginContentView

- (void)layoutSubviews {
    %orig;
    if (!NeoWCEnhancementEnabled(NeoWCAutoDeviceLoginKey)) return;
    if ([objc_getAssociatedObject(self, &NeoWCDeviceCardDidConfirmKey) boolValue]) return;
    objc_setAssociatedObject(self, &NeoWCDeviceCardDidConfirmKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onTapConfirmButton];
        NeoWCLog(@"已自动确认多设备登录");
        NeoWCShowLoginToast(@"已自动确认设备登录");
    });
}

%end


%hook MMAuthorizeUserInfoViewController

- (void)viewDidLayoutSubviews {
    %orig;
    NeoWCTryAuthorizeGame(self);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (NeoWCTryAuthorizeGame(self)) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        NeoWCTryAuthorizeGame(self);
    });
}

%end
