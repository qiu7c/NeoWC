#import "NeoWCReminder.h"

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

static NSInteger const NeoWCReminderToastTag = 0x4E575243;

static UIViewController *NeoWCReminderTopController(UIViewController *controller) {
    if (controller.presentedViewController) return NeoWCReminderTopController(controller.presentedViewController);
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return NeoWCReminderTopController(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return NeoWCReminderTopController(((UITabBarController *)controller).selectedViewController);
    }
    return controller;
}

static UIWindow *NeoWCReminderActiveWindow(void) {
    if (@available(iOS 13.0, *)) {
        UIWindow *fallback = nil;
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]] ||
                scene.activationState != UISceneActivationStateForegroundActive) continue;
            for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                if (window.isKeyWindow) return window;
                if (!window.hidden && window.alpha > 0.01 && !fallback) fallback = window;
            }
        }
        if (fallback) return fallback;
    }
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow) return window;
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

static void NeoWCShowReminderToast(NSString *title, NSString *body) {
    UIWindow *window = NeoWCReminderActiveWindow();
    UIViewController *controller = NeoWCReminderTopController(window.rootViewController);
    if (!controller.view.window) return;
    [[controller.view viewWithTag:NeoWCReminderToastTag] removeFromSuperview];

    UIView *toast = [UIView new];
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    toast.tag = NeoWCReminderToastTag;
    toast.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.94];
    toast.layer.cornerRadius = 8.0;
    toast.layer.masksToBounds = YES;
    toast.userInteractionEnabled = NO;

    UILabel *titleLabel = [UILabel new];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = title;
    titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.numberOfLines = 1;

    UILabel *bodyLabel = [UILabel new];
    bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    bodyLabel.text = body;
    bodyLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    bodyLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.78];
    bodyLabel.numberOfLines = 2;

    [toast addSubview:titleLabel];
    [toast addSubview:bodyLabel];
    [controller.view addSubview:toast];
    [NSLayoutConstraint activateConstraints:@[
        [toast.leadingAnchor constraintGreaterThanOrEqualToAnchor:controller.view.leadingAnchor constant:20.0],
        [toast.trailingAnchor constraintLessThanOrEqualToAnchor:controller.view.trailingAnchor constant:-20.0],
        [toast.centerXAnchor constraintEqualToAnchor:controller.view.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:controller.view.safeAreaLayoutGuide.bottomAnchor constant:-42.0],
        [titleLabel.topAnchor constraintEqualToAnchor:toast.topAnchor constant:10.0],
        [titleLabel.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:14.0],
        [titleLabel.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-14.0],
        [bodyLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:3.0],
        [bodyLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [bodyLabel.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],
        [bodyLabel.bottomAnchor constraintEqualToAnchor:toast.bottomAnchor constant:-10.0],
        [toast.widthAnchor constraintLessThanOrEqualToConstant:360.0],
    ]];

    toast.alpha = 0.0;
    [UIView animateWithDuration:0.16 animations:^{ toast.alpha = 1.0; }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.18 animations:^{ toast.alpha = 0.0; }
                         completion:^(__unused BOOL finished) { [toast removeFromSuperview]; }];
    });
}

void NeoWCDeliverReminder(NSString *title, NSString *body, NSString *conversationUserName) {
    if (title.length == 0 || body.length == 0) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            NeoWCShowReminderToast(title, body);
            return;
        }

        UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
            UNAuthorizationStatus status = settings.authorizationStatus;
            BOOL allowed = status == UNAuthorizationStatusAuthorized ||
                           status == UNAuthorizationStatusProvisional;
            if (@available(iOS 14.0, *)) allowed = allowed || status == UNAuthorizationStatusEphemeral;
            if (!allowed) return;

            UNMutableNotificationContent *content = [UNMutableNotificationContent new];
            content.title = title;
            content.body = body;
            content.sound = UNNotificationSound.defaultSound;
            if (conversationUserName.length > 0) content.userInfo = @{ @"u": conversationUserName };
            UNNotificationRequest *request = [UNNotificationRequest
                requestWithIdentifier:[@"com.qiu7c.neowc.reminder." stringByAppendingString:NSUUID.UUID.UUIDString]
                              content:content
                              trigger:nil];
            [center addNotificationRequest:request withCompletionHandler:nil];
        }];
    });
}
