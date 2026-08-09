#import "NeoWCSettingsActions.h"
#import "NeoWCSettingsCatalog.h"
#import "NeoWCAntiRevoke.h"
#import "NeoWCAntiRevokeTemplateEditor.h"
#import "NeoWCConfigManagerViewController.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import "NeoWCCompatibility.h"
#import "NeoWCListEditorViewController.h"
#import "NeoWCLongPressMenuViewController.h"
#import "NeoWCMeMenuViewController.h"
#import "NeoWCPluginVisibility.h"
#import "NeoWCPluginShortcuts.h"
#import <math.h>

@interface NeoWCSettingsActions ()
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, copy) NeoWCSettingsReloadHandler reloadHandler;
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

- (void)presentRevokeFilterPicker {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"回复时间限制" message:@"仅影响“回复撤回者”，不会影响本地防撤回" preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[@{@"title": @"不限制", @"value": @0}, @{@"title": @"1 分钟", @"value": @60}, @{@"title": @"5 分钟", @"value": @300}, @{@"title": @"30 分钟", @"value": @1800}, @{@"title": @"1 小时", @"value": @3600}, @{@"title": @"24 小时", @"value": @86400}];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        [sheet addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
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
    NSString *colorKey = [key isEqualToString:NeoWCAntiRevokeLocalTemplateKey] ? NeoWCAntiRevokeLocalTextColorKey : nil;
    [self push:[[NeoWCAntiRevokeTemplateEditorViewController alloc] initWithTitle:title defaultsKey:key defaultValue:defaultValue colorKey:colorKey]];
}

- (void)presentTextEditorForKey:(NSString *)key title:(NSString *)title placeholder:(NSString *)placeholder {
    BOOL editingClass = [key isEqualToString:NeoWCPluginShortcutCustomClassKey];
    NSString *message = editingClass ? @"输入 Objective-C Runtime 类名；支持 UIViewController 或 UIView 子类。修改已注册的类名后建议重启微信。" : @"此名称会显示在插件管理页面中。";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = [NSUserDefaults.standardUserDefaults stringForKey:key];
        field.placeholder = placeholder;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *value = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (!editingClass && value.length == 0) value = @"快捷页面";
        [NSUserDefaults.standardUserDefaults setObject:value ?: @"" forKey:key];
        NeoWCRegisterPluginShortcutsIfAvailable();
        [weakSelf reload];
    }]];
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentNumberEditorWithTitle:(NSString *)title message:(NSString *)message key:(NSString *)key minimum:(CGFloat)minimum maximum:(CGFloat)maximum notifyChange:(BOOL)notifyChange applyScale:(BOOL)applyScale {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = [NSString stringWithFormat:@"%.0f", [NSUserDefaults.standardUserDefaults doubleForKey:key]];
        field.keyboardType = UIKeyboardTypeDecimalPad;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *raw = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        CGFloat fallback = minimum == 70.0 && maximum == 100.0 ? 100.0 : 0.0;
        if ([key isEqualToString:NeoWCRedEnvelopeDetailFontSizeKey]) fallback = 14.0;
        CGFloat value = MIN(maximum, MAX(minimum, raw.length > 0 ? raw.doubleValue : fallback));
        [NSUserDefaults.standardUserDefaults setDouble:value forKey:key];
        if (notifyChange) [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification object:key];
        if (weakSelf.reloadHandler) weakSelf.reloadHandler(applyScale);
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

- (void)presentHapticIntensityPicker {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"点赞震动力度" message:@"选择双击点赞时的触感强度" preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[@{@"title": @"轻", @"value": @0.25}, @{@"title": @"中", @"value": @0.65}, @{@"title": @"强", @"value": @1.0}];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) [sheet addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [NSUserDefaults.standardUserDefaults setDouble:[option[@"value"] doubleValue] forKey:NeoWCMomentsLikeHapticIntensityKey];
        [weakSelf reload];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)presentStepModePicker {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"每日目标模式" message:@"随机模式每天只生成一次目标" preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[@{@"title": @"每日固定", @"value": @(NeoWCStepModeDailyFixed)}, @{@"title": @"每日随机", @"value": @(NeoWCStepModeDailyRandom)}];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) [sheet addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        [defaults setInteger:[option[@"value"] integerValue] forKey:NeoWCStepModeKey];
        [defaults setBool:YES forKey:NeoWCStepOverrideEnabledKey];
        NeoWCSettingsRegenerateDailyStepTarget(defaults);
        [weakSelf reload];
    }]];
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

- (void)performActionForItem:(NeoWCSettingItem *)item {
    switch (item.action) {
        case NeoWCSettingActionConfigManager: [self push:[NeoWCConfigManagerViewController new]]; break;
        case NeoWCSettingActionBlockUsers: [self push:[[NeoWCListEditorViewController alloc] initWithTitle:item.title subtitle:@"每行填写一个 wxid 或以 @chatroom 结尾的群聊账号" defaultsKey:NeoWCMessageBlockUsersKey mode:NeoWCListEditorModeList]]; break;
        case NeoWCSettingActionBlockKeywords: [self push:[[NeoWCListEditorViewController alloc] initWithTitle:item.title subtitle:@"仅匹配新收到的普通文字消息，每行填写一个关键词" defaultsKey:NeoWCMessageBlockKeywordsKey mode:NeoWCListEditorModeList]]; break;
        case NeoWCSettingActionReminderKeywords: [self push:[[NeoWCListEditorViewController alloc] initWithTitle:item.title subtitle:@"命中任意一项即提醒，每行填写一个关键词" defaultsKey:NeoWCKeywordReminderKeywordsKey mode:NeoWCListEditorModeList]]; break;
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
        case NeoWCSettingActionPluginShortcutTitle: [self presentTextEditorForKey:NeoWCPluginShortcutCustomTitleKey title:item.title placeholder:@"快捷页面"]; break;
        case NeoWCSettingActionPluginShortcutClass: [self presentTextEditorForKey:NeoWCPluginShortcutCustomClassKey title:item.title placeholder:@"例如 NewSettingViewController"]; break;
        case NeoWCSettingActionGlobalScale: [self presentNumberEditorWithTitle:item.title message:@"请输入 70 到 100 之间的百分比" key:NeoWCPageScaleGlobalPercentKey minimum:70 maximum:100 notifyChange:YES applyScale:NO]; break;
        case NeoWCSettingActionSettingsScale: [self presentNumberEditorWithTitle:item.title message:@"请输入 70 到 100 之间的百分比" key:NeoWCSettingsPageScalePercentKey minimum:70 maximum:100 notifyChange:YES applyScale:YES]; break;
        case NeoWCSettingActionInnerRadius: [self presentNumberEditorWithTitle:item.title message:@"请输入 0 到 40 之间的数值；0 表示直角" key:NeoWCChatInputInnerRadiusKey minimum:0 maximum:40 notifyChange:NO applyScale:NO]; break;
        case NeoWCSettingActionOuterRadius: [self presentNumberEditorWithTitle:item.title message:@"请输入 0 到 40 之间的数值；0 表示直角" key:NeoWCChatInputOuterRadiusKey minimum:0 maximum:40 notifyChange:NO applyScale:NO]; break;
        case NeoWCSettingActionMomentsDateFormat: [self presentMomentsDateFormatEditor]; break;
        case NeoWCSettingActionPluginVisibility: [self push:[NeoWCPluginVisibilityViewController new]]; break;
        case NeoWCSettingActionHapticIntensity: [self presentHapticIntensityPicker]; break;
        case NeoWCSettingActionStepMode: [self presentStepModePicker]; break;
        case NeoWCSettingActionFixedSteps: [self presentFixedStepsEditor]; break;
        case NeoWCSettingActionRandomStepRange: [self presentRandomStepRangeEditor]; break;
        case NeoWCSettingActionWalletBalance: [self presentWalletEditor]; break;
        case NeoWCSettingActionContactsCount: [self presentContactsEditor]; break;
        case NeoWCSettingActionRedEnvelopeFontSize: [self presentNumberEditorWithTitle:item.title message:@"请输入 10 到 24 之间的字号" key:NeoWCRedEnvelopeDetailFontSizeKey minimum:10 maximum:24 notifyChange:YES applyScale:NO]; break;
        default: break;
    }
}

@end
