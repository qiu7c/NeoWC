#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "Sources/NeoWCSettingsViewController.h"
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
@end

@interface GameController : NSObject
+ (NSString *)getMD5ByGameContent:(NSUInteger)content;
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

static BOOL NeoWCFindAndTapButton(NSString *title, UIView *rootView) {
    if (!rootView || title.length == 0) return NO;
    for (UIView *subview in rootView.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            NSString *buttonTitle = button.currentTitle ?: button.currentAttributedTitle.string;
            if ([buttonTitle isEqualToString:title]) {
                [button sendActionsForControlEvents:UIControlEventTouchUpInside];
                return YES;
            }
        }
        if (NeoWCFindAndTapButton(title, subview)) return YES;
    }
    return NO;
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

static void NeoWCShowLoginToast(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (scene.activationState != UISceneActivationStateForegroundActive || ![scene isKindOfClass:[UIWindowScene class]]) continue;
                for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
                    if (candidate.isKeyWindow) { window = candidate; break; }
                }
            }
        }
        if (!window) window = UIApplication.sharedApplication.windows.firstObject;
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

- (void)AddEmoticonMsg:(NSString *)message MsgWrap:(CMessageWrap *)wrap {
    BOOL isGameMessage = wrap.m_uiMessageType == 47 && (wrap.m_uiGameType == 1 || wrap.m_uiGameType == 2);
    if (!NeoWCEnhancementEnabled(NeoWCGameSelectorKey) || !isGameMessage) {
        %orig;
        return;
    }
    if ([objc_getAssociatedObject(wrap, &NeoWCGameSelectorPresentedKey) boolValue]) return;

    UIWindow *window = UIApplication.sharedApplication.keyWindow ?: UIApplication.sharedApplication.windows.firstObject;
    UIViewController *presenter = NeoWCTopControllerForLoginToast(window.rootViewController);
    if (!presenter.view.window) {
        %orig;
        return;
    }

    objc_setAssociatedObject(wrap, &NeoWCGameSelectorPresentedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSString *sourceType = wrap.m_uiGameType == 1 ? @"猜拳" : @"骰子";
    UIAlertController *selector = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@结果选择", sourceType]
                                                                      message:@"彩蛋：可以跨类型选择结果"
                                                               preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSDictionary *> *choices = @[
        @{@"title": @"剪刀", @"value": @1}, @{@"title": @"石头", @"value": @2}, @{@"title": @"布", @"value": @3},
        @{@"title": @"骰子 1", @"value": @4}, @{@"title": @"骰子 2", @"value": @5}, @{@"title": @"骰子 3", @"value": @6},
        @{@"title": @"骰子 4", @"value": @7}, @{@"title": @"骰子 5", @"value": @8}, @{@"title": @"骰子 6", @"value": @9},
    ];
    for (NSDictionary *choice in choices) {
        [selector addAction:[UIAlertAction actionWithTitle:choice[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSUInteger value = [choice[@"value"] unsignedIntegerValue];
            wrap.m_nsEmoticonMD5 = [GameController getMD5ByGameContent:value];
            wrap.m_uiGameContent = value;
            objc_setAssociatedObject(wrap, &NeoWCGameSelectorPresentedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            NeoWCLog(@"小游戏结果已选择：%@（原始值 %lu）", choice[@"title"], (unsigned long)value);
            %orig(message, wrap);
        }]];
    }
    [selector addAction:[UIAlertAction actionWithTitle:@"取消发送" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
        objc_setAssociatedObject(wrap, &NeoWCGameSelectorPresentedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }]];
    UIPopoverPresentationController *popover = selector.popoverPresentationController;
    if (popover) {
        popover.sourceView = presenter.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds), CGRectGetMaxY(presenter.view.bounds) - 1.0, 1.0, 1.0);
    }
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

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!NeoWCEnhancementEnabled(NeoWCAutoGameAuthorizeKey)) return;
    if ([objc_getAssociatedObject(self, &NeoWCGameDidAuthorizeKey) boolValue]) return;
    objc_setAssociatedObject(self, &NeoWCGameDidAuthorizeKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (NeoWCFindAndTapButton(@"允许", self.view)) {
            NeoWCLog(@"已自动允许游戏扫码授权");
            NeoWCShowLoginToast(@"已自动允许游戏授权");
        } else {
            objc_setAssociatedObject(self, &NeoWCGameDidAuthorizeKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            NeoWCLog(@"游戏授权页面未找到允许按钮");
        }
    });
}

%end
