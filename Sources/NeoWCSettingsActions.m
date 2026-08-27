#import "NeoWCSettingsActions.h"
#import "NeoWCSettingsCatalog.h"
#import "NeoWCAntiRevoke.h"
#import "NeoWCAntiRevokeTemplateEditor.h"
#import "NeoWCConfigManagerViewController.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import "NeoWCInterfaceTweaks.h"
#import "NeoWCCompatibility.h"
#import "NeoWCListEditorViewController.h"
#import "NeoWCLongPressMenuViewController.h"
#import "NeoWCMeMenuViewController.h"
#import "NeoWCMessageBlock.h"
#import "NeoWCMediaGroupViewController.h"
#import "NeoWCPluginManager.h"
#import "NeoWCReleaseNotes.h"
#import "NeoWCQuickReplyViewController.h"
#import "NeoWCSendConfirmationViewController.h"
#import "NeoWCMomentsReminder.h"
#import <math.h>
#import <objc/message.h>
#import <objc/runtime.h>

static char NeoWCAuthorSearchLogicKey;
static NSString *const NeoWCAuthorUserName = @"ic7ouo";

static id NeoWCSettingsServiceForClass(Class serviceClass) {
    Class centerClass = NSClassFromString(@"MMServiceCenter");
    SEL centerSelector = NSSelectorFromString(@"defaultCenter");
    SEL serviceSelector = NSSelectorFromString(@"getService:");
    if (!centerClass || !serviceClass || ![centerClass respondsToSelector:centerSelector]) return nil;
    id center = ((id (*)(id, SEL))objc_msgSend)(centerClass, centerSelector);
    if (!center || ![center respondsToSelector:serviceSelector]) return nil;
    return ((id (*)(id, SEL, Class))objc_msgSend)(center, serviceSelector, serviceClass);
}

@interface NeoWCSettingsActions () <UIColorPickerViewControllerDelegate>
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, copy) NeoWCSettingsReloadHandler reloadHandler;
@property (nonatomic, copy) NSString *activeColorDefaultsKey;
@end


@implementation NeoWCSettingsActions

- (instancetype)initWithViewController:(UIViewController *)viewController
                         reloadHandler:(NeoWCSettingsReloadHandler)reloadHandler {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _reloadHandler = [reloadHandler copy];
    }
    return self;
}

- (void)reload {
    if (self.reloadHandler) self.reloadHandler(NO);
}

- (void)presentSheet:(UIAlertController *)sheet {
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.viewController.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(self.viewController.view.bounds), CGRectGetMaxY(self.viewController.view.bounds) - 1.0, 1.0, 1.0);
    }
    [self.viewController presentViewController:sheet animated:YES completion:nil];
}

- (void)push:(UIViewController *)controller {
    if (controller) [self.viewController.navigationController pushViewController:controller animated:YES];
}

- (void)openProfileForUserName:(NSString *)requestedUserName {
    UIViewController *sourceController = self.viewController;
    NSString *userName = [requestedUserName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!sourceController || userName.length == 0) return;

    Class handlerClass = NSClassFromString(@"MMURLHandler");
    SEL sharedSelector = NSSelectorFromString(@"sharedInstance");
    SEL constructSelector = NSSelectorFromString(@"constructContactInfoView:withUserName:");
    id handler = handlerClass && [handlerClass respondsToSelector:sharedSelector]
        ? ((id (*)(id, SEL))objc_msgSend)(handlerClass, sharedSelector) : nil;
    Class contactManagerClass = NSClassFromString(@"CContactMgr");
    id contactManager = NeoWCSettingsServiceForClass(contactManagerClass);
    id contact = nil;
    for (NSString *selectorName in @[@"getContactByName:", @"getContactByNameFromCache:"]) {
        SEL selector = NSSelectorFromString(selectorName);
        if (!contactManager || ![contactManager respondsToSelector:selector]) continue;
        contact = ((id (*)(id, SEL, id))objc_msgSend)(contactManager, selector, userName);
        if (contact) break;
    }
    if (handler && contact && [handler respondsToSelector:constructSelector]) {
        id profileController = ((id (*)(id, SEL, id, id))objc_msgSend)(handler,
                                                                       constructSelector,
                                                                       contact,
                                                                       userName);
        if ([profileController isKindOfClass:[UIViewController class]] && sourceController.navigationController) {
            [sourceController.navigationController pushViewController:profileController animated:YES];
            return;
        }
    }

    Class searchClass = NSClassFromString(@"GetA8KeyLogic");
    SEL initializer = NSSelectorFromString(@"initWithViewController:delegate:");
    SEL searchSelector = NSSelectorFromString(@"doSearchContact:FromScene:SearchScene:picUrl:");
    id searchLogic = searchClass && [searchClass instancesRespondToSelector:initializer]
        ? ((id (*)(id, SEL, id, id))objc_msgSend)([searchClass alloc], initializer, sourceController, nil)
        : nil;
    if (searchLogic && [searchLogic respondsToSelector:searchSelector]) {
        objc_setAssociatedObject(sourceController, &NeoWCAuthorSearchLogicKey,
                                 searchLogic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        ((void (*)(id, SEL, id, NSUInteger, NSUInteger, id))objc_msgSend)(searchLogic,
                                                                          searchSelector,
                                                                          userName,
                                                                          0,
                                                                          0,
                                                                          nil);
        return;
    }

    NSString *URLString = [NSString stringWithFormat:@"weixin://contacts/profile/%@", userName];
    NSURL *URL = [NSURL URLWithString:URLString];
    UIApplication *application = UIApplication.sharedApplication;
    if (URL && [application canOpenURL:URL]) {
        [application openURL:URL options:@{} completionHandler:nil];
        return;
    }

    UIPasteboard.generalPasteboard.string = userName;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"暂时无法打开资料页"
                                                                   message:@"账号已复制，可在微信中继续搜索。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [sourceController presentViewController:alert animated:YES completion:nil];
}

- (void)openAuthorProfile {
    [self openProfileForUserName:NeoWCAuthorUserName];
}

- (void)presentFindFriend {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"查找好友"
                                                                   message:@"输入微信号或 wxid，将使用微信的原生联系人搜索链路。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"微信号 / wxid";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"查找" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [weakSelf openProfileForUserName:alert.textFields.firstObject.text];
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentRevokeFilterPicker {
    NSTimeInterval current = [NSUserDefaults.standardUserDefaults doubleForKey:NeoWCAntiRevokeTimeFilterKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"回复时间限制" message:@"仅影响“回复撤回者”，不会影响本地防撤回" preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[@{@"title": @"不限制", @"value": @0}, @{@"title": @"1 分钟", @"value": @60}, @{@"title": @"5 分钟", @"value": @300}, @{@"title": @"30 分钟", @"value": @1800}, @{@"title": @"1 小时", @"value": @3600}, @{@"title": @"24 小时", @"value": @86400}];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        NSString *title = fabs([option[@"value"] doubleValue] - current) < 0.5
            ? [NSString stringWithFormat:@"✓  %@", option[@"title"]]
            : option[@"title"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [NSUserDefaults.standardUserDefaults setDouble:[option[@"value"] doubleValue] forKey:NeoWCAntiRevokeTimeFilterKey];
            [weakSelf reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentRevokePromptStylePicker {
    NSInteger current = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCAntiRevokePromptStyleKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"防撤回提示方案" message:@"“消息下方”显示完整提示；“气泡旁”显示与气泡持平的小字" preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[@{@"title": current == 0 ? @"✓  消息下方" : @"消息下方", @"value": @0}, @{@"title": current == 1 ? @"✓  气泡旁" : @"气泡旁", @"value": @1}];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        [sheet addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [NSUserDefaults.standardUserDefaults setInteger:[option[@"value"] integerValue] forKey:NeoWCAntiRevokePromptStyleKey];
            [weakSelf reload];
            [NSNotificationCenter.defaultCenter postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentTemplateWithTitle:(NSString *)title key:(NSString *)key defaultValue:(NSString *)defaultValue {
    [self push:[[NeoWCAntiRevokeTemplateEditorViewController alloc] initWithTitle:title defaultsKey:key defaultValue:defaultValue colorKey:nil]];
}

- (void)presentNumberEditorWithTitle:(NSString *)title message:(NSString *)message key:(NSString *)key minimum:(CGFloat)minimum maximum:(CGFloat)maximum notifyChange:(BOOL)notifyChange applyScale:(BOOL)applyScale {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = [NSString stringWithFormat:@"%.0f", [NSUserDefaults.standardUserDefaults doubleForKey:key]];
        field.keyboardType = minimum < 0.0 ? UIKeyboardTypeNumbersAndPunctuation : UIKeyboardTypeDecimalPad;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *raw = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        CGFloat fallback = minimum == 70.0 && maximum == 100.0 ? 100.0 : 0.0;
        if ([key isEqualToString:NeoWCRedEnvelopeDetailFontSizeKey]) fallback = 14.0;
        if ([key isEqualToString:NeoWCChatGlassBlurIntensityKey]) fallback = 100.0;
        CGFloat value = MIN(maximum, MAX(minimum, raw.length > 0 ? raw.doubleValue : fallback));
        [NSUserDefaults.standardUserDefaults setDouble:value forKey:key];
        if (notifyChange) [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification object:key];
        if ([key isEqualToString:NeoWCMomentsReminderIntervalKey]) NeoWCMomentsReminderSettingsDidChange();
        if (weakSelf.reloadHandler) weakSelf.reloadHandler(applyScale);
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentSendConfirmationPauseDurationEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"临时暂停时长"
                                                                   message:@"输入暂停确认的秒数"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        NSInteger saved = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCSendConfirmationPauseSecondsKey];
        field.text = [NSString stringWithFormat:@"%ld", (long)(saved > 0 ? saved : 60)];
        field.keyboardType = UIKeyboardTypeNumberPad;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *raw = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        NSInteger seconds = raw.integerValue;
        [NSUserDefaults.standardUserDefaults setInteger:seconds > 0 ? seconds : 60
                                                 forKey:NeoWCSendConfirmationPauseSecondsKey];
        [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification
                                                           object:NeoWCSendConfirmationPauseSecondsKey];
        if (weakSelf.reloadHandler) weakSelf.reloadHandler(NO);
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentMomentsDateFormatEditor {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *saved = NeoWCNormalizedMomentsDateFormat([defaults stringForKey:NeoWCMomentsPreciseTimeFormatKey]) ?: NeoWCMomentsPreciseTimeDefaultFormat;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"朋友圈日期格式" message:@"仅支持 yyyy、MM、dd、E、HH、mm、ss，区分大小写；留空恢复默认格式" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = saved;
        field.placeholder = NeoWCMomentsPreciseTimeDefaultFormat;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *raw = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        NSString *normalized = raw.length == 0 ? NeoWCMomentsPreciseTimeDefaultFormat : NeoWCNormalizedMomentsDateFormat(raw);
        if (!normalized) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIAlertController *error = [UIAlertController alertControllerWithTitle:@"日期格式不支持" message:@"格式最长 64 个字符，只能使用支持的日期符号及普通分隔文字。" preferredStyle:UIAlertControllerStyleAlert];
                [error addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
                [weakSelf.viewController presentViewController:error animated:YES completion:nil];
            });
            return;
        }
        [defaults setObject:normalized forKey:NeoWCMomentsPreciseTimeFormatKey];
        [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification object:NeoWCMomentsPreciseTimeFormatKey];
        [weakSelf reload];
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentMessageTimeFormatEditor {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *saved = [defaults stringForKey:NeoWCChatMessageTimeFormatKey];
    if (saved.length == 0) saved = @"MM-dd HH:mm:ss";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"消息时间格式"
                                                                   message:@"仅支持 yyyy、MM、dd、E、HH、mm、ss，区分大小写；留空恢复默认格式"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = saved;
        field.placeholder = @"MM-dd HH:mm:ss";
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *raw = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        NSString *normalized = raw.length == 0 ? @"MM-dd HH:mm:ss" : NeoWCNormalizedMomentsDateFormat(raw);
        if (!normalized) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIAlertController *error = [UIAlertController alertControllerWithTitle:@"时间格式不支持"
                                                                                message:@"格式最长 64 个字符，只能使用支持的日期符号及普通分隔文字。"
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                [error addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
                [weakSelf.viewController presentViewController:error animated:YES completion:nil];
            });
            return;
        }
        [defaults setObject:normalized forKey:NeoWCChatMessageTimeFormatKey];
        [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification object:NeoWCChatMessageTimeFormatKey];
        [weakSelf reload];
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentMessageTimeModePicker {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL bubbleMode = [defaults boolForKey:NeoWCChatMessageTimeBubbleSideKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"消息时间显示模式"
                                                                    message:@"两种模式互斥；头像模式紧贴头像底部，消息旁模式支持全部消息类型。"
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSDictionary *> *options = @[
        @{@"title": @"头像下方", @"bubble": @NO},
        @{@"title": @"消息右侧", @"bubble": @YES},
    ];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        BOOL value = [option[@"bubble"] boolValue];
        NSString *title = value == bubbleMode ? [NSString stringWithFormat:@"✓  %@", option[@"title"]] : option[@"title"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [defaults setBool:!value forKey:NeoWCChatMessageTimeBelowAvatarKey];
            [defaults setBool:value forKey:NeoWCChatMessageTimeBubbleSideKey];
            [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification object:NeoWCChatMessageTimeBubbleSideKey];
            [weakSelf reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentMessageTimePositionPicker {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSInteger current = MIN(2, MAX(0, [defaults integerForKey:NeoWCChatMessageTimeBubbleVerticalPositionKey]));
    NSArray<NSString *> *names = @[@"顶部", @"中间", @"底部"];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"消息旁时间位置"
                                                                    message:@"底部可避开默认位于中间的防撤回提示。"
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger index, __unused BOOL *stop) {
        NSString *title = (NSInteger)index == current ? [NSString stringWithFormat:@"✓  %@", name] : name;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [defaults setInteger:(NSInteger)index forKey:NeoWCChatMessageTimeBubbleVerticalPositionKey];
            [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification object:NeoWCChatMessageTimeBubbleVerticalPositionKey];
            [weakSelf reload];
        }]];
    }];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentMessageTimeColorPickerForKey:(NSString *)defaultsKey title:(NSString *)title {
    self.activeColorDefaultsKey = defaultsKey;
    UIColorPickerViewController *picker = [UIColorPickerViewController new];
    picker.title = title;
    picker.supportsAlpha = YES;
    picker.selectedColor = NeoWCColorForDefaultsKey(defaultsKey, UIColor.secondaryLabelColor);
    picker.delegate = self;
    [self.viewController presentViewController:picker animated:YES completion:nil];
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController {
    if (self.activeColorDefaultsKey.length == 0) return;
    UIColor *resolved = [viewController.selectedColor resolvedColorWithTraitCollection:self.viewController.traitCollection];
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0;
    if (![resolved getRed:&red green:&green blue:&blue alpha:&alpha]) {
        CGFloat white = 0.0;
        if ([resolved getWhite:&white alpha:&alpha]) red = green = blue = white;
    }
    NSString *hex = [NSString stringWithFormat:@"#%02X%02X%02X%02X",
                     (unsigned int)lrint(MIN(1.0, MAX(0.0, red)) * 255.0),
                     (unsigned int)lrint(MIN(1.0, MAX(0.0, green)) * 255.0),
                     (unsigned int)lrint(MIN(1.0, MAX(0.0, blue)) * 255.0),
                     (unsigned int)lrint(MIN(1.0, MAX(0.0, alpha)) * 255.0)];
    [NSUserDefaults.standardUserDefaults setObject:hex forKey:self.activeColorDefaultsKey];
    [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification object:self.activeColorDefaultsKey];
    self.activeColorDefaultsKey = nil;
    [self reload];
}

- (void)presentHapticIntensityPicker {
    CGFloat current = [NSUserDefaults.standardUserDefaults doubleForKey:NeoWCMomentsLikeHapticIntensityKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"点赞震动力度" message:@"选择双击点赞时的触感强度" preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[@{@"title": @"轻", @"value": @0.25}, @{@"title": @"中", @"value": @0.65}, @{@"title": @"强", @"value": @1.0}];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        CGFloat value = [option[@"value"] doubleValue];
        BOOL selected = (current < 0.34 && value < 0.34) ||
                        (current >= 0.34 && current < 0.75 && value >= 0.34 && value < 0.75) ||
                        (current >= 0.75 && value >= 0.75);
        NSString *title = selected ? [NSString stringWithFormat:@"✓  %@", option[@"title"]] : option[@"title"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [NSUserDefaults.standardUserDefaults setDouble:[option[@"value"] doubleValue] forKey:NeoWCMomentsLikeHapticIntensityKey];
        [weakSelf reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentChatTopEffectStylePicker {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL supportsLiquid = NeoWCSystemSupportsNativeLiquidGlass();
    NSInteger stored = [defaults integerForKey:NeoWCChatTopBarEffectStyleKey];
    NSInteger current = stored == NeoWCChatTopBarEffectStyleFauxLiquid
        ? NeoWCChatTopBarEffectStyleFauxLiquid
        : (supportsLiquid && stored == NeoWCChatTopBarEffectStyleLiquid
            ? NeoWCChatTopBarEffectStyleLiquid : NeoWCChatTopBarEffectStyleMaterial);
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"模糊效果"
                                                                    message:supportsLiquid
                                                                        ? @"伪液态玻璃使用低开销高光与轮廓层；原生液态玻璃使用 iOS 26 UIGlassEffect。"
                                                                        : @"伪液态玻璃使用低开销高光与轮廓层，支持当前系统。"
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    NSMutableArray *options = [NSMutableArray arrayWithObject:
        @{@"title": @"超薄玻璃", @"value": @(NeoWCChatTopBarEffectStyleMaterial)}];
    [options addObject:@{@"title": @"伪液态玻璃", @"value": @(NeoWCChatTopBarEffectStyleFauxLiquid)}];
    if (supportsLiquid) {
        [options addObject:@{@"title": @"原生液态玻璃", @"value": @(NeoWCChatTopBarEffectStyleLiquid)}];
    }
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        NSInteger value = [option[@"value"] integerValue];
        NSString *title = value == current
            ? [NSString stringWithFormat:@"✓  %@", option[@"title"]]
            : option[@"title"];
        [sheet addAction:[UIAlertAction actionWithTitle:title
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(__unused UIAlertAction *action) {
            [defaults setInteger:value forKey:NeoWCChatTopBarEffectStyleKey];
            [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification
                                                               object:NeoWCChatTopBarEffectStyleKey];
            [weakSelf reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentStepModePicker {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSInteger current = [defaults integerForKey:NeoWCStepModeKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"步数模式" message:@"固定模式使用同一个数值；随机模式每天生成一次并显示当天结果。" preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[@{@"title": @"固定步数", @"value": @(NeoWCStepModeDailyFixed)}, @{@"title": @"每日随机", @"value": @(NeoWCStepModeDailyRandom)}];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        NSInteger value = [option[@"value"] integerValue];
        NSString *title = value == current ? [NSString stringWithFormat:@"✓  %@", option[@"title"]] : option[@"title"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [defaults setInteger:value forKey:NeoWCStepModeKey];
        [defaults setBool:YES forKey:NeoWCStepOverrideEnabledKey];
        NeoWCSettingsRegenerateDailyStepTarget(defaults);
        [weakSelf reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentFixedStepsEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置每日固定目标" message:@"请输入 1–100000 之间的数值" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        NSInteger value = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCStepCountKey];
        field.text = value > 0 ? [NSString stringWithFormat:@"%ld", (long)value] : nil;
        field.keyboardType = UIKeyboardTypeNumberPad;
        field.placeholder = @"步数";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        [defaults setInteger:MIN(100000, MAX(1, alert.textFields.firstObject.text.integerValue)) forKey:NeoWCStepCountKey];
        [defaults setInteger:NeoWCStepModeDailyFixed forKey:NeoWCStepModeKey];
        [defaults setBool:YES forKey:NeoWCStepOverrideEnabledKey];
        NeoWCSettingsRegenerateDailyStepTarget(defaults);
        [weakSelf reload];
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentRandomStepRangeEditor {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置每日随机目标" message:@"每天在最小值和最大值之间生成一次" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.text = [NSString stringWithFormat:@"%ld", (long)MAX(1, [defaults integerForKey:NeoWCStepRandomMinimumKey])]; field.keyboardType = UIKeyboardTypeNumberPad; field.placeholder = @"最小步数"; }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.text = [NSString stringWithFormat:@"%ld", (long)MAX(1, [defaults integerForKey:NeoWCStepRandomMaximumKey])]; field.keyboardType = UIKeyboardTypeNumberPad; field.placeholder = @"最大步数"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSInteger minimum = MIN(100000, MAX(1, alert.textFields.firstObject.text.integerValue));
        NSInteger maximum = MIN(100000, MAX(1, alert.textFields.lastObject.text.integerValue));
        if (minimum > maximum) { NSInteger swap = minimum; minimum = maximum; maximum = swap; }
        [defaults setInteger:minimum forKey:NeoWCStepRandomMinimumKey];
        [defaults setInteger:maximum forKey:NeoWCStepRandomMaximumKey];
        [defaults setInteger:NeoWCStepModeDailyRandom forKey:NeoWCStepModeKey];
        [defaults setBool:YES forKey:NeoWCStepOverrideEnabledKey];
        if ([defaults integerForKey:NeoWCStepCountKey] <= 0) [defaults setInteger:minimum forKey:NeoWCStepCountKey];
        NeoWCSettingsRegenerateDailyStepTarget(defaults);
        [weakSelf reload];
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentRegenerateRandomSteps {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSInteger current = [defaults integerForKey:NeoWCStepDailyTargetKey];
    NSString *message = current > 0
        ? [NSString stringWithFormat:@"当前结果为 %ld 步。重新生成后，今天将改用新结果。", (long)current]
        : @"今天尚未生成随机步数。";
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"今日随机结果"
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"重新生成" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [defaults setInteger:NeoWCStepModeDailyRandom forKey:NeoWCStepModeKey];
        [defaults setBool:YES forKey:NeoWCStepOverrideEnabledKey];
        NeoWCSettingsRegenerateDailyStepTarget(defaults);
        [weakSelf reload];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentWalletEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置钱包余额" message:@"仅修改本机界面显示；留空或输入 0 可恢复真实显示" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        id stored = [NSUserDefaults.standardUserDefaults objectForKey:NeoWCWalletBalanceFenKey];
        long long fen = [stored respondsToSelector:@selector(longLongValue)] ? [stored longLongValue] : 0;
        field.text = fen > 0 ? [NSString stringWithFormat:@"%.2f", fen / 100.0] : nil;
        field.keyboardType = UIKeyboardTypeDecimalPad;
        field.placeholder = @"例如 888.88";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        long long fen = text.length > 0 && text.doubleValue > 0 ? (long long)llround(text.doubleValue * 100.0) : 0;
        [NSUserDefaults.standardUserDefaults setObject:@(MAX(0LL, fen)) forKey:NeoWCWalletBalanceFenKey];
        [NSUserDefaults.standardUserDefaults setBool:fen > 0 forKey:NeoWCWalletBalanceEnabledKey];
        [weakSelf reload];
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentContactsEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置好友数量" message:@"仅替换本机界面中的好友数量文案" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        NSInteger value = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCContactsCountKey];
        field.text = value > 0 ? [NSString stringWithFormat:@"%ld", (long)value] : nil;
        field.keyboardType = UIKeyboardTypeNumberPad;
        field.placeholder = @"好友数量";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSInteger value = MAX(0, alert.textFields.firstObject.text.integerValue);
        [NSUserDefaults.standardUserDefaults setInteger:value forKey:NeoWCContactsCountKey];
        [NSUserDefaults.standardUserDefaults setBool:value > 0 forKey:NeoWCContactsCountEnabledKey];
        [weakSelf reload];
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentMessageGestureActionPickerForItem:(NeoWCSettingItem *)item {
    NSString *defaultsKey = item.defaultsKey;
    if (defaultsKey.length == 0) return;
    BOOL selfMessage = [defaultsKey isEqualToString:NeoWCReplySwipeSelfActionKey] ||
                       [defaultsKey isEqualToString:NeoWCReplySwipeRightSelfActionKey] ||
                       [defaultsKey isEqualToString:NeoWCMessageDoubleTapSelfActionKey] ||
                       [defaultsKey isEqualToString:NeoWCMessageTripleTapSelfActionKey];
    NSInteger current = [NSUserDefaults.standardUserDefaults integerForKey:defaultsKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:item.title
                                                                   message:selfMessage ? @"选择自己消息触发的动作" : @"选择对方消息触发的动作；不支持撤回"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSDictionary *> *options = selfMessage
        ? @[
            @{@"title": @"不设置", @"value": @(NeoWCReplySwipeActionNone)},
            @{@"title": @"引用", @"value": @(NeoWCReplySwipeActionQuote)},
            @{@"title": @"撤回", @"value": @(NeoWCReplySwipeActionRevoke)},
            @{@"title": @"复制", @"value": @(NeoWCReplySwipeActionCopy)},
            @{@"title": @"删除", @"value": @(NeoWCReplySwipeActionDelete)},
            @{@"title": @"复读", @"value": @(NeoWCReplySwipeActionRepeat)},
        ]
        : @[
            @{@"title": @"不设置", @"value": @(NeoWCReplySwipeActionNone)},
            @{@"title": @"引用", @"value": @(NeoWCReplySwipeActionQuote)},
            @{@"title": @"复制", @"value": @(NeoWCReplySwipeActionCopy)},
            @{@"title": @"删除", @"value": @(NeoWCReplySwipeActionDelete)},
            @{@"title": @"复读", @"value": @(NeoWCReplySwipeActionRepeat)},
        ];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        NSInteger value = [option[@"value"] integerValue];
        NSString *title = value == current ? [@"✓  " stringByAppendingString:option[@"title"]] : option[@"title"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [NSUserDefaults.standardUserDefaults setInteger:value forKey:defaultsKey];
            [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification object:NeoWCReplySwipeEnabledKey];
            [weakSelf reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentAvatarQuickMenuGesturePicker {
    NSInteger current = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCAvatarQuickMenuGestureKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"头像快捷面板"
                                                                   message:@"只启用一种头像手势，不影响消息气泡手势"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSDictionary *> *options = @[
        @{@"title": @"关闭", @"value": @(NeoWCAvatarQuickMenuGestureOff)},
        @{@"title": @"双击头像", @"value": @(NeoWCAvatarQuickMenuGestureDoubleTap)},
        @{@"title": @"长按头像", @"value": @(NeoWCAvatarQuickMenuGestureLongPress)},
    ];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        NSInteger value = [option[@"value"] integerValue];
        NSString *title = value == current ? [@"✓  " stringByAppendingString:option[@"title"]] : option[@"title"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [NSUserDefaults.standardUserDefaults setInteger:value forKey:NeoWCAvatarQuickMenuGestureKey];
            [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification
                                                               object:NeoWCAvatarQuickMenuGestureKey];
            [weakSelf reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentVideoParserURLEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"视频解析接口"
                                                                   message:@"接口需使用 HTTPS。NeoWC 会 POST wxid 与 url，并兼容 video_url、videoUrl、play_url、download_url 等返回字段。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"https://example.com/parse";
        field.keyboardType = UIKeyboardTypeURL;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.text = [NSUserDefaults.standardUserDefaults stringForKey:NeoWCVideoParserCustomURLKey] ?: @"";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *value = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        NSURL *URL = value.length > 0 ? [NSURL URLWithString:value] : nil;
        if (value.length > 0 && ![[URL.scheme lowercaseString] isEqualToString:@"https"]) {
            UIAlertController *error = [UIAlertController alertControllerWithTitle:@"接口格式不正确"
                                                                           message:@"请输入完整的 HTTPS 地址。"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [error addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
            [weakSelf.viewController presentViewController:error animated:YES completion:nil];
            return;
        }
        [NSUserDefaults.standardUserDefaults setObject:value ?: @"" forKey:NeoWCVideoParserCustomURLKey];
        [weakSelf reload];
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentVideoParserSendModePicker {
    NSInteger current = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCVideoParserSendModeKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"视频解析发送方式"
                                                                   message:@"原生视频先下载文件再交给微信发送；链接卡片点击后由微信内置浏览器打开解析地址。"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSDictionary *> *options = @[
        @{@"title": @"原生视频", @"value": @0},
        @{@"title": @"链接卡片", @"value": @1},
    ];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        NSInteger value = [option[@"value"] integerValue];
        NSString *title = value == current ? [@"✓  " stringByAppendingString:option[@"title"]] : option[@"title"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [NSUserDefaults.standardUserDefaults setInteger:value forKey:NeoWCVideoParserSendModeKey];
            [weakSelf reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)performActionForItem:(NeoWCSettingItem *)item {
    switch (item.action) {
        case NeoWCSettingActionConfigManager: [self push:[NeoWCConfigManagerViewController new]]; break;
        case NeoWCSettingActionAuthorProfile: [self openAuthorProfile]; break;
        case NeoWCSettingActionFindFriend: [self presentFindFriend]; break;
        case NeoWCSettingActionReleaseNotes: [self.viewController presentViewController:[NeoWCReleaseNotesViewController new] animated:NO completion:nil]; break;
        case NeoWCSettingActionBlockUsers: [self push:[NeoWCMessageBlockViewController new]]; break;
        case NeoWCSettingActionBlockKeywords: [self push:[[NeoWCListEditorViewController alloc] initWithTitle:item.title subtitle:@"仅匹配新收到的普通文字消息，每行填写一个关键词" defaultsKey:NeoWCMessageBlockKeywordsKey mode:NeoWCListEditorModeList]]; break;
        case NeoWCSettingActionLongPressMenus: [self push:[NeoWCLongPressMenuViewController new]]; break;
        case NeoWCSettingActionMeMenu: [self push:[NeoWCMeMenuViewController new]]; break;
        case NeoWCSettingActionRevokePromptStyle: [self presentRevokePromptStylePicker]; break;
        case NeoWCSettingActionRevokeAppearance: [self push:[NeoWCAntiRevokeAppearanceViewController new]]; break;
        case NeoWCSettingActionRevokeRecords: [self push:[NeoWCAntiRevokeRecordsViewController new]]; break;
        case NeoWCSettingActionRevokeFilter: [self presentRevokeFilterPicker]; break;
        case NeoWCSettingActionRevokeLocalTemplate: [self presentTemplateWithTitle:item.title key:NeoWCAntiRevokeLocalTemplateKey defaultValue:@"拦截到一条{用户名}撤回的消息\n发送时间：{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}\n内容：{内容}"]; break;
        case NeoWCSettingActionRevokeReplyTemplate: [self presentTemplateWithTitle:item.title key:NeoWCAntiRevokeReplyTemplateKey defaultValue:@"【捕捉到一条撤回消息】\n操作用户：{用户名}\n发送时间：{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}\n撤回内容：{内容}\n\n撤回无效，消息已保存"]; break;
        case NeoWCSettingActionDebugCenter: [[NeoWCDebugManager sharedManager] presentDashboardFromViewController:self.viewController]; break;
        case NeoWCSettingActionCompatibility: [self push:[NeoWCCompatibilityViewController new]]; break;
        case NeoWCSettingActionGlobalScale: [self presentNumberEditorWithTitle:item.title message:@"请输入 70 到 100 之间的百分比" key:NeoWCPageScaleGlobalPercentKey minimum:70 maximum:100 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionSettingsScale: [self presentNumberEditorWithTitle:item.title message:@"请输入 70 到 100 之间的百分比" key:NeoWCSettingsPageScalePercentKey minimum:70 maximum:100 notifyChange:YES applyScale:YES]; break;
        case NeoWCSettingActionInnerRadius: [self presentNumberEditorWithTitle:item.title message:@"请输入 0 到 40 之间的数值；0 表示直角" key:NeoWCChatInputInnerRadiusKey minimum:0 maximum:40 notifyChange:NO applyScale:NO]; break;
        case NeoWCSettingActionOuterRadius: [self presentNumberEditorWithTitle:item.title message:@"请输入 0 到 40 之间的数值；0 表示直角" key:NeoWCChatInputOuterRadiusKey minimum:0 maximum:40 notifyChange:NO applyScale:NO]; break;
        case NeoWCSettingActionMomentsDateFormat: [self presentMomentsDateFormatEditor]; break;
        case NeoWCSettingActionMessageTimeFormat: [self presentMessageTimeFormatEditor]; break;
        case NeoWCSettingActionMessageTimeFontSize: [self presentNumberEditorWithTitle:item.title message:@"请输入 8 到 18 之间的字号" key:NeoWCChatMessageTimeFontSizeKey minimum:8 maximum:18 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionMessageTimeMode: [self presentMessageTimeModePicker]; break;
        case NeoWCSettingActionMessageTimeColor: [self presentMessageTimeColorPickerForKey:item.defaultsKey title:item.title]; break;
        case NeoWCSettingActionMessageTimePosition: [self presentMessageTimePositionPicker]; break;
        case NeoWCSettingActionMessageTimeAvatarSpacing: [self presentNumberEditorWithTitle:item.title message:@"请输入 -6 到 8 之间的数值；负值向上，正值向下" key:NeoWCChatMessageTimeAvatarSpacingKey minimum:-6 maximum:8 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionPluginManager: [self push:[WCPluginsViewController new]]; break;
        case NeoWCSettingActionHapticIntensity: [self presentHapticIntensityPicker]; break;
        case NeoWCSettingActionStepMode: [self presentStepModePicker]; break;
        case NeoWCSettingActionFixedSteps: [self presentFixedStepsEditor]; break;
        case NeoWCSettingActionRandomStepRange: [self presentRandomStepRangeEditor]; break;
        case NeoWCSettingActionRegenerateRandomSteps: [self presentRegenerateRandomSteps]; break;
        case NeoWCSettingActionWalletBalance: [self presentWalletEditor]; break;
        case NeoWCSettingActionContactsCount: [self presentContactsEditor]; break;
        case NeoWCSettingActionRedEnvelopeFontSize: [self presentNumberEditorWithTitle:item.title message:@"请输入 10 到 24 之间的字号" key:NeoWCRedEnvelopeDetailFontSizeKey minimum:10 maximum:24 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionChatTopAvatarSize: [self presentNumberEditorWithTitle:item.title message:@"请输入 24 到 34 之间的头像大小" key:NeoWCChatTopBarAvatarSizeKey minimum:24 maximum:34 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionChatTopNicknameSize: [self presentNumberEditorWithTitle:item.title message:@"请输入 12 到 18 之间的昵称字号" key:NeoWCChatTopBarNicknameSizeKey minimum:12 maximum:18 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionChatTopEffectStyle: [self presentChatTopEffectStylePicker]; break;
        case NeoWCSettingActionChatGlassBlurIntensity: [self presentNumberEditorWithTitle:item.title message:@"请输入 20 到 100 之间的百分比" key:NeoWCChatGlassBlurIntensityKey minimum:20 maximum:100 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionChatGlassTintOpacity: [self presentNumberEditorWithTitle:item.title message:@"请输入 0 到 30 之间的百分比；0 表示不额外染色" key:NeoWCChatGlassTintOpacityKey minimum:0 maximum:30 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionChatGlassWhiteStrength: [self presentNumberEditorWithTitle:item.title message:@"请输入 0 到 50 之间的百分比；数值越高白玻璃越明显" key:NeoWCChatGlassWhiteStrengthKey minimum:0 maximum:50 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionMessageGestureAction: [self presentMessageGestureActionPickerForItem:item]; break;
        case NeoWCSettingActionAvatarQuickMenuGesture: [self presentAvatarQuickMenuGesturePicker]; break;
        case NeoWCSettingActionReplySwipeTriggerDistance: [self presentNumberEditorWithTitle:item.title message:@"请输入 36 到 100 之间的触发距离；数值越小越容易触发" key:NeoWCReplySwipeTriggerDistanceKey minimum:36 maximum:100 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionGlobalAvatarCornerPercent: [self presentNumberEditorWithTitle:item.title message:@"请输入 0 到 100 之间的百分比；0 为直角，100 为圆形" key:NeoWCGlobalAvatarCornerPercentKey minimum:0 maximum:100 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionQuickReplyLibrary: [self push:[[NeoWCQuickReplyViewController alloc] initWithSelectionHandler:nil]]; break;
        case NeoWCSettingActionVideoParserURL: [self presentVideoParserURLEditor]; break;
        case NeoWCSettingActionVideoParserSendMode: [self presentVideoParserSendModePicker]; break;
        case NeoWCSettingActionVideoParserGroups: [self push:[[NeoWCMediaGroupViewController alloc] initWithTitle:@"视频解析群聊" defaultsKey:NeoWCVideoParserGroupsKey]]; break;
        case NeoWCSettingActionMusicOrderGroups: [self push:[[NeoWCMediaGroupViewController alloc] initWithTitle:@"音乐点歌群聊" defaultsKey:NeoWCMusicOrderGroupsKey]]; break;
        case NeoWCSettingActionSendConfirmationConversations: [self push:[NeoWCSendConfirmationViewController new]]; break;
        case NeoWCSettingActionSendConfirmationPauseDuration: [self presentSendConfirmationPauseDurationEditor]; break;
        case NeoWCSettingActionMomentsReminderUsers: {
            UIViewController *picker = NeoWCCreateFriendPicker(@"特别关注好友",
                                                               @"勾选后会建立当前朋友圈基线，只提醒后续检测到的新内容。",
                                                               ^BOOL(NSString *username) {
                return [NeoWCMomentsReminderUsers() containsObject:username];
            }, ^(NSString *username) {
                BOOL selected = [NeoWCMomentsReminderUsers() containsObject:username];
                NeoWCMomentsReminderSetUserSelected(username, !selected);
                NeoWCMomentsReminderSettingsDidChange();
            });
            [self push:picker];
            break;
        }
        case NeoWCSettingActionMomentsReminderInterval:
            [self presentNumberEditorWithTitle:item.title
                                       message:@"请输入 30 到 3600 秒；后台检测频率仍会受 iOS 调度影响"
                                           key:NeoWCMomentsReminderIntervalKey
                                       minimum:30
                                       maximum:3600
                                   notifyChange:YES
                                    applyScale:NO];
            break;
        default: break;
    }
}

@end
