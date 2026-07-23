#import "NeoWCPluginShortcuts.h"

#import <UIKit/UIKit.h>
#import <objc/message.h>

#import "NeoWCDebug.h"

NSString *const NeoWCPluginShortcutsEnabledKey = @"com.qiu7c.neowc.plugin-shortcuts.enabled";
NSString *const NeoWCPluginShortcutLoggingKey = @"com.qiu7c.neowc.plugin-shortcuts.logging";
NSString *const NeoWCPluginShortcutFloatingDebugKey = @"com.qiu7c.neowc.plugin-shortcuts.floating-debug";
NSString *const NeoWCPluginShortcutDebugCenterKey = @"com.qiu7c.neowc.plugin-shortcuts.debug-center";
NSString *const NeoWCPluginShortcutRevokeRecordsKey = @"com.qiu7c.neowc.plugin-shortcuts.revoke-records";
NSString *const NeoWCPluginShortcutCustomPageKey = @"com.qiu7c.neowc.plugin-shortcuts.custom-page";
NSString *const NeoWCPluginShortcutCustomTitleKey = @"com.qiu7c.neowc.plugin-shortcuts.custom-title";
NSString *const NeoWCPluginShortcutCustomClassKey = @"com.qiu7c.neowc.plugin-shortcuts.custom-class";

@interface NeoWCDynamicViewShortcutController : UIViewController
@end

@implementation NeoWCDynamicViewShortcutController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *title = [defaults stringForKey:NeoWCPluginShortcutCustomTitleKey];
    NSString *className = [defaults stringForKey:NeoWCPluginShortcutCustomClassKey];
    self.title = title.length > 0 ? title : className;
    Class viewClass = NSClassFromString(className);
    if (viewClass && [viewClass isSubclassOfClass:[UIView class]]) {
        UIView *content = [[viewClass alloc] initWithFrame:self.view.bounds];
        content.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:content];
        return;
    }
    UILabel *message = [UILabel new];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.numberOfLines = 0;
    message.textAlignment = NSTextAlignmentCenter;
    message.textColor = [UIColor secondaryLabelColor];
    message.text = [NSString stringWithFormat:@"无法创建 View：%@", className.length > 0 ? className : @"未设置类名"];
    [self.view addSubview:message];
    [NSLayoutConstraint activateConstraints:@[
        [message.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [message.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [message.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

@end

static BOOL NeoWCShortcutOptionEnabled(NSUserDefaults *defaults, NSString *key, BOOL fallback) {
    id value = [defaults objectForKey:key];
    return value ? [value boolValue] : fallback;
}

void NeoWCRegisterPluginShortcuts(id manager) {
    if (!manager) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:NeoWCPluginShortcutsEnabledKey]) return;

    static NSMutableSet<NSString *> *registered;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ registered = [NSMutableSet set]; });

    SEL switchSelector = NSSelectorFromString(@"registerSwitchWithTitle:key:");
    SEL controllerSelector = NSSelectorFromString(@"registerControllerWithTitle:version:controller:");
    @synchronized (registered) {
        if (NeoWCShortcutOptionEnabled(defaults, NeoWCPluginShortcutLoggingKey, YES) &&
            ![registered containsObject:@"logging"] && [manager respondsToSelector:switchSelector]) {
            ((void (*)(id, SEL, NSString *, NSString *))objc_msgSend)(manager, switchSelector,
                @"NeoWC · 调试日志", NeoWCDebugLoggingEnabledKey);
            [registered addObject:@"logging"];
        }
        if (NeoWCShortcutOptionEnabled(defaults, NeoWCPluginShortcutFloatingDebugKey, NO) &&
            ![registered containsObject:@"floating"] && [manager respondsToSelector:switchSelector]) {
            ((void (*)(id, SEL, NSString *, NSString *))objc_msgSend)(manager, switchSelector,
                @"NeoWC · 调试悬浮窗", NeoWCDebugFloatingEnabledKey);
            [registered addObject:@"floating"];
        }
        if (NeoWCShortcutOptionEnabled(defaults, NeoWCPluginShortcutDebugCenterKey, YES) &&
            ![registered containsObject:@"debug-center"] && [manager respondsToSelector:controllerSelector]) {
            ((void (*)(id, SEL, NSString *, NSString *, NSString *))objc_msgSend)(manager, controllerSelector,
                @"NeoWC · 调试中心", @"0.1.2", @"NeoWCDebugShortcutViewController");
            [registered addObject:@"debug-center"];
        }
        if (NeoWCShortcutOptionEnabled(defaults, NeoWCPluginShortcutRevokeRecordsKey, NO) &&
            ![registered containsObject:@"revoke-records"] && [manager respondsToSelector:controllerSelector]) {
            ((void (*)(id, SEL, NSString *, NSString *, NSString *))objc_msgSend)(manager, controllerSelector,
                @"NeoWC · 防撤回记录", @"0.1.2", @"NeoWCAntiRevokeRecordsViewController");
            [registered addObject:@"revoke-records"];
        }
        if (NeoWCShortcutOptionEnabled(defaults, NeoWCPluginShortcutCustomPageKey, NO) &&
            [manager respondsToSelector:controllerSelector]) {
            NSString *className = [[defaults stringForKey:NeoWCPluginShortcutCustomClassKey]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *title = [[defaults stringForKey:NeoWCPluginShortcutCustomTitleKey]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            Class targetClass = NSClassFromString(className);
            NSString *registrationClass = nil;
            if (targetClass && [targetClass isSubclassOfClass:[UIViewController class]]) {
                registrationClass = className;
            } else if (targetClass && [targetClass isSubclassOfClass:[UIView class]]) {
                registrationClass = @"NeoWCDynamicViewShortcutController";
            }
            NSString *marker = registrationClass.length > 0 ? [@"custom:" stringByAppendingString:className] : nil;
            if (marker.length > 0 && ![registered containsObject:marker]) {
                ((void (*)(id, SEL, NSString *, NSString *, NSString *))objc_msgSend)(manager, controllerSelector,
                    title.length > 0 ? title : className, @"快捷入口", registrationClass);
                [registered addObject:marker];
            } else if (className.length > 0 && registrationClass.length == 0) {
                NeoWCLog(@"自定义快捷入口未注册：类 %@ 不存在或不是 UIViewController / UIView", className);
            }
        }
    }
}

void NeoWCRegisterPluginShortcutsIfAvailable(void) {
    Class managerClass = NSClassFromString(@"WCPluginsMgr");
    SEL sharedSelector = NSSelectorFromString(@"sharedInstance");
    if (!managerClass || ![managerClass respondsToSelector:sharedSelector]) return;
    id manager = ((id (*)(id, SEL))objc_msgSend)(managerClass, sharedSelector);
    NeoWCRegisterPluginShortcuts(manager);
}
