#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <math.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "Sources/NeoWCSettingsViewController.h"
#import "Sources/NeoWCAntiRevoke.h"
#import "Sources/NeoWCChatExport.h"
#import "Sources/NeoWCCompatibility.h"
#import "Sources/NeoWCDebug.h"
#import "Sources/NeoWCEnhancements.h"
#import "Sources/NeoWCPluginVisibility.h"
#import "Sources/NeoWCPluginShortcuts.h"
#import "Sources/NeoWCInterfaceTweaks.h"

@interface WCPluginsMgr : NSObject
+ (instancetype)sharedInstance;
- (void)registerControllerWithTitle:(NSString *)title
                            version:(NSString *)version
                         controller:(NSString *)controller;
- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key;
@end

@interface WCPluginsViewController : UIViewController
@end

@interface WCActionSheet : NSObject
- (void)addButtonWithTitle:(NSString *)title eventAction:(void (^)(void))eventAction;
- (BOOL)isContainButtonTitle:(NSString *)title;
@end

@interface MMMenuItem : NSObject
- (instancetype)initWithTitle:(NSString *)title icon:(UIImage *)icon target:(id)target action:(SEL)action;
@end

@interface SharePreConfirmSheetView : UIView
@end

@interface EditImageForwardAndEditLogicController : NSObject
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

@interface CommonMessageCellView : UIView
- (void)neowc_refreshAntiRevokeSidePrompt;
- (void)neowc_scheduleAntiRevokeSidePromptRefresh;
@end

@interface SystemMessageCellView : UIView
- (id)getRichTextView;
- (void)neowc_applyAntiRevokeTextColor;
@end

@interface MMGrowTextView : UIView
- (void)neowc_handleInputSwipeLeft:(UISwipeGestureRecognizer *)recognizer;
- (void)neowc_handleInputSwipeRight:(UISwipeGestureRecognizer *)recognizer;
@end

@interface MMInputToolView : UIView
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
- (unsigned int)hkStepCount;
@end

@interface WCDataItem : NSObject
- (BOOL)isAd;
- (BOOL)isVideoAd;
- (unsigned int)stepCount;
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
static char NeoWCChatExportBuildingMenuKey;
static char NeoWCAntiRevokeSideLabelKey;
static char NeoWCAntiRevokeSideRefreshScheduledKey;
static char NeoWCAntiRevokeOriginalSystemTextColorKey;
static char NeoWCAntiRevokeSystemColorAppliedKey;
static char NeoWCEditedImageKey;
static char NeoWCEditConversationUserNameKey;
static char NeoWCEditPresenterControllerKey;
static char NeoWCQuickSendPendingImageKey;
static char NeoWCInputSwipeLeftRecognizerKey;
static char NeoWCInputSwipeRightRecognizerKey;
static char NeoWCWalletGestureRecognizerKey;
static __weak id NeoWCCurrentEditImageLogicController;

static NSMutableSet *NeoWCActiveQuickSendSessions(void) {
    static NSMutableSet *sessions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sessions = [NSMutableSet set]; });
    return sessions;
}

static id NeoWCTweakSafeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static BOOL NeoWCUsesAntiRevokeSidePrompt(void) {
    return NeoWCEnhancementEnabled(NeoWCAntiRevokeKey) &&
           [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCAntiRevokePromptStyleKey] == 1;
}

static void NeoWCTweakSetValue(id object, NSString *key, id value) {
    if (!object || key.length == 0) return;
    @try {
        [object setValue:value forKey:key];
    } @catch (__unused NSException *exception) {
    }
}

static id NeoWCTweakValueForSelectorNames(id object, NSArray<NSString *> *selectorNames) {
    for (NSString *selectorName in selectorNames) {
        SEL selector = NSSelectorFromString(selectorName);
        if ([object respondsToSelector:selector]) return ((id (*)(id, SEL))objc_msgSend)(object, selector);
    }
    return nil;
}

static void NeoWCTweakSetStringForSelectorName(id object, NSString *selectorName, NSString *value) {
    SEL selector = NSSelectorFromString(selectorName);
    if ([object respondsToSelector:selector]) ((void (*)(id, SEL, id))objc_msgSend)(object, selector, value);
}

static long long NeoWCLongLongDefaultForKey(NSString *key) {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return [value respondsToSelector:@selector(longLongValue)] ? [value longLongValue] : 0;
}

static unsigned long long NeoWCWalletBalanceFenOverride(void) {
    if (!NeoWCEnhancementEnabled(NeoWCWalletBalanceEnabledKey)) return 0;
    long long fen = NeoWCLongLongDefaultForKey(NeoWCWalletBalanceFenKey);
    return fen > 0 ? (unsigned long long)fen : 0;
}

static NSString *NeoWCContactsCountTextForOriginal(NSString *original) {
    if (!NeoWCEnhancementEnabled(NeoWCContactsCountEnabledKey)) return nil;
    NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCContactsCountKey];
    if (count <= 0 || ![original isKindOfClass:[NSString class]]) return nil;
    NSString *trimmed = [original stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if ([trimmed hasSuffix:@" 个朋友"]) return [NSString stringWithFormat:@"%ld 个朋友", (long)count];
    if ([trimmed hasSuffix:@"个朋友"]) return [NSString stringWithFormat:@"%ld个朋友", (long)count];
    if ([trimmed hasSuffix:@"个"] && [trimmed rangeOfString:@"朋友"].location == NSNotFound) {
        NSString *number = [[trimmed substringToIndex:trimmed.length - 1]
            stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (number.length > 0 &&
            [number rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location == NSNotFound) {
            return [NSString stringWithFormat:@"%ld 个", (long)count];
        }
    }
    return nil;
}

static id NeoWCMessageWrapForCell(id cell) {
    id viewModel = NeoWCTweakValueForSelectorNames(cell, @[@"viewModel"]);
    return NeoWCTweakValueForSelectorNames(viewModel, @[@"messageWrap"]);
}

static BOOL NeoWCMessageIsText(id message) {
    SEL selector = NSSelectorFromString(@"IsTextMsg");
    return message && [message respondsToSelector:selector] && ((BOOL (*)(id, SEL))objc_msgSend)(message, selector);
}

static BOOL NeoWCMessageIsRefer(id message) {
    SEL selector = NSSelectorFromString(@"isReferMsgType");
    return message && [message respondsToSelector:selector] && ((BOOL (*)(id, SEL))objc_msgSend)(message, selector);
}

static BOOL NeoWCMessageIsTransfer(id message) {
    if (!message) return NO;
    SEL parseSelector = NSSelectorFromString(@"parseWCPayInfoItemIfNeed");
    if ([message respondsToSelector:parseSelector]) ((void (*)(id, SEL))objc_msgSend)(message, parseSelector);
    id payItem = NeoWCTweakSafeValue(message, @"m_oWCPayInfoItem");
    if (!payItem) return NO;
    NSUInteger subType = [NeoWCTweakSafeValue(payItem, @"m_uiPaySubType") unsignedIntegerValue];
    if (subType == 3 || subType == 4) return YES;
    NSString *transferID = NeoWCTweakSafeValue(payItem, @"m_nsTransferID");
    return [transferID isKindOfClass:[NSString class]] && transferID.length > 0;
}

static BOOL NeoWCMessageCanJokerEdit(id message) {
    return NeoWCMessageIsText(message) || NeoWCMessageIsRefer(message) || NeoWCMessageIsTransfer(message);
}

static NSString *NeoWCDisplayTextForJokerCell(id cell, id message) {
    if (NeoWCMessageIsText(message)) {
        SEL contentSelector = NSSelectorFromString(@"GetDisplayContent");
        if ([message respondsToSelector:contentSelector]) {
            id value = ((id (*)(id, SEL))objc_msgSend)(message, contentSelector);
            if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
        }
    }
    if (NeoWCMessageIsRefer(message)) {
        id value = NeoWCTweakSafeValue(message, @"m_nsTitle");
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    if (NeoWCMessageIsTransfer(message)) {
        id payItem = NeoWCTweakSafeValue(message, @"m_oWCPayInfoItem");
        id value = NeoWCTweakSafeValue(payItem, @"m_nsFeeDesc");
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    return @"";
}

static UIViewController *NeoWCJokerPresenterForCell(id cell) {
    UIResponder *responder = [cell isKindOfClass:[UIResponder class]] ? (UIResponder *)cell : nil;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) return (UIViewController *)responder;
        responder = responder.nextResponder;
    }
    return nil;
}

static void NeoWCReloadJokerCell(id cell, id message) {
    UIViewController *controller = NeoWCJokerPresenterForCell(cell);
    if (!controller || !message) return;
    SEL clearSelector = NSSelectorFromString(@"clearNodeLayoutCache");
    if ([controller respondsToSelector:clearSelector]) ((void (*)(id, SEL))objc_msgSend)(controller, clearSelector);
    SEL reloadWrapSelector = NSSelectorFromString(@"reloadNodeWithMessageWrap:");
    if ([controller respondsToSelector:reloadWrapSelector]) ((void (*)(id, SEL, id))objc_msgSend)(controller, reloadWrapSelector, message);
    SEL reloadCellSelector = NSSelectorFromString(@"reloadVisibleNodeWithCellView:");
    if ([controller respondsToSelector:reloadCellSelector]) ((void (*)(id, SEL, id))objc_msgSend)(controller, reloadCellSelector, cell);
    SEL tableSelector = NSSelectorFromString(@"getMsgTableView");
    if ([controller respondsToSelector:tableSelector]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            id tableView = ((id (*)(id, SEL))objc_msgSend)(controller, tableSelector);
            if ([tableView isKindOfClass:[UITableView class]]) {
                [UIView performWithoutAnimation:^{
                    [(UITableView *)tableView beginUpdates];
                    [(UITableView *)tableView endUpdates];
                }];
            }
        });
    }
}

static NSString *NeoWCJokerSanitizedAmountText(NSString *text) {
    NSMutableString *result = [NSMutableString string];
    for (NSUInteger index = 0; index < text.length; index++) {
        unichar character = [text characterAtIndex:index];
        if (character == '.' || (character >= '0' && character <= '9')) {
            [result appendFormat:@"%C", character];
        }
    }
    return result.length > 0 ? result : nil;
}

static void NeoWCApplyJokerText(id cell, NSString *text) {
    if (text.length == 0) return;
    id message = NeoWCMessageWrapForCell(cell);
    if (!NeoWCMessageCanJokerEdit(message)) return;
    NSString *original = NeoWCDisplayTextForJokerCell(cell, message);
    if ([text isEqualToString:original]) return;
    if (NeoWCMessageIsText(message)) {
        NeoWCTweakSetStringForSelectorName(message, @"setM_nsContent:", text);
    } else if (NeoWCMessageIsRefer(message)) {
        NeoWCTweakSetStringForSelectorName(message, @"setM_nsTitle:", text);
    } else if (NeoWCMessageIsTransfer(message)) {
        NSString *amount = NeoWCJokerSanitizedAmountText(text);
        if (amount.length == 0) return;
        id payItem = NeoWCTweakSafeValue(message, @"m_oWCPayInfoItem");
        NSString *feeDesc = [@"¥" stringByAppendingString:amount];
        if (payItem) {
            NeoWCTweakSetStringForSelectorName(payItem, @"setM_nsFeeDesc:", feeDesc);
            NeoWCTweakSetStringForSelectorName(payItem, @"setM_receiverDesc:", feeDesc);
            NeoWCTweakSetStringForSelectorName(payItem, @"setM_senderDesc:", feeDesc);
        }
    }
    NeoWCReloadJokerCell(cell, message);
    NeoWCLog(@"聊天记录小丑已修改当前页面显示");
}

static UITextView *NeoWCInnerTextView(id growTextView) {
    id textView = NeoWCTweakSafeValue(growTextView, @"textView");
    if (![textView isKindOfClass:[UITextView class]]) textView = NeoWCTweakSafeValue(growTextView, @"_textView");
    return [textView isKindOfClass:[UITextView class]] ? textView : nil;
}

static void NeoWCSynchronizeInputSwipeActions(MMGrowTextView *view) {
    if (!view) return;
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCInputSwipeActionsEnabledKey);
    UISwipeGestureRecognizer *left = objc_getAssociatedObject(view, &NeoWCInputSwipeLeftRecognizerKey);
    UISwipeGestureRecognizer *right = objc_getAssociatedObject(view, &NeoWCInputSwipeRightRecognizerKey);
    if (enabled) {
        NeoWCCompatibilityMarkTriggered(@"input-swipe");
        if (!left) {
            left = [[UISwipeGestureRecognizer alloc] initWithTarget:view action:@selector(neowc_handleInputSwipeLeft:)];
            left.direction = UISwipeGestureRecognizerDirectionLeft;
            left.cancelsTouchesInView = NO;
            [view addGestureRecognizer:left];
            objc_setAssociatedObject(view, &NeoWCInputSwipeLeftRecognizerKey, left, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (!right) {
            right = [[UISwipeGestureRecognizer alloc] initWithTarget:view action:@selector(neowc_handleInputSwipeRight:)];
            right.direction = UISwipeGestureRecognizerDirectionRight;
            right.cancelsTouchesInView = NO;
            [view addGestureRecognizer:right];
            objc_setAssociatedObject(view, &NeoWCInputSwipeRightRecognizerKey, right, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return;
    }
    if (left) {
        [view removeGestureRecognizer:left];
        objc_setAssociatedObject(view, &NeoWCInputSwipeLeftRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (right) {
        [view removeGestureRecognizer:right];
        objc_setAssociatedObject(view, &NeoWCInputSwipeRightRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static id NeoWCContactForUserName(NSString *userName) {
    if (userName.length == 0) return nil;
    Class centerClass = objc_getClass("MMServiceCenter");
    Class contactManagerClass = objc_getClass("CContactMgr");
    if (!centerClass || !contactManagerClass) return nil;
    id center = ((id (*)(id, SEL))objc_msgSend)(centerClass, sel_registerName("defaultCenter"));
    if (!center) return nil;
    id manager = ((id (*)(id, SEL, Class))objc_msgSend)(center, sel_registerName("getService:"), contactManagerClass);
    SEL selector = sel_registerName("getContactByName:");
    if (!manager || ![manager respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL, id))objc_msgSend)(manager, selector, userName);
}

static NSString *NeoWCConversationUserNameForEditLogic(id logic) {
    SEL selector = sel_registerName("c2CUserName");
    if (!logic) return nil;
    if ([logic respondsToSelector:selector]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(logic, selector);
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
            objc_setAssociatedObject(logic, &NeoWCEditConversationUserNameKey, value, OBJC_ASSOCIATION_COPY_NONATOMIC);
            return value;
        }
    }
    id cachedValue = objc_getAssociatedObject(logic, &NeoWCEditConversationUserNameKey);
    return [cachedValue isKindOfClass:[NSString class]] && [cachedValue length] > 0 ? cachedValue : nil;
}

static UIImage *NeoWCImageFromEditValue(id value, NSUInteger depth) {
    if (!value || depth > 4) return nil;
    if ([value isKindOfClass:[UIImage class]]) return value;
    if ([value isKindOfClass:[CIImage class]]) return [UIImage imageWithCIImage:value];
    if ([value isKindOfClass:[NSData class]]) return [UIImage imageWithData:value];
    if ([value isKindOfClass:[NSURL class]]) {
        NSURL *url = value;
        return url.isFileURL ? [UIImage imageWithContentsOfFile:url.path] : nil;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *path = value;
        if ([path hasPrefix:@"file://"]) path = [NSURL URLWithString:path].path;
        return path.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:path] ? [UIImage imageWithContentsOfFile:path] : nil;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        for (id candidate in [(NSArray *)value reverseObjectEnumerator]) {
            UIImage *image = NeoWCImageFromEditValue(candidate, depth + 1);
            if (image) return image;
        }
        return nil;
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        NSArray<NSString *> *preferredKeys = @[@"editedImage", @"image", @"outputImage", @"resultImage", @"fullImage", @"path", @"url"];
        for (NSString *key in preferredKeys) {
            UIImage *image = NeoWCImageFromEditValue(dictionary[key], depth + 1);
            if (image) return image;
        }
        NSUInteger checked = 0;
        for (id candidate in dictionary.allValues.reverseObjectEnumerator) {
            UIImage *image = NeoWCImageFromEditValue(candidate, depth + 1);
            if (image) return image;
            if (++checked >= 16) break;
        }
    }
    return nil;
}

static void NeoWCCacheEditedImage(id logic, UIImage *image, NSString *source) {
    if (!logic || ![image isKindOfClass:[UIImage class]]) return;
    objc_setAssociatedObject(logic, &NeoWCEditedImageKey, image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCLog(@"已从 %@ 取得编辑图片：%.0f × %.0f", source ?: @"未知来源", image.size.width * image.scale, image.size.height * image.scale);
}

static UIImage *NeoWCEditedImageFromLogic(id logic) {
    UIImage *image = objc_getAssociatedObject(logic, &NeoWCEditedImageKey);
    return [image isKindOfClass:[UIImage class]] ? image : nil;
}

static void NeoWCLogEditImageDiagnostics(id logic) {
    id attribute = NeoWCTweakSafeValue(logic, @"_editImageAttr");
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (NSString *key in @[@"editedImage", @"editedImages", @"unCropImage", @"editImageAttrDic", @"originalImage", @"isEdited"]) {
        id value = NeoWCTweakSafeValue(attribute, key);
        [parts addObject:[NSString stringWithFormat:@"%@=%@", key, value ? NSStringFromClass([value class]) : @"nil"]];
    }
    NeoWCLog(@"编辑图片取图诊断：logic=%@ attr=%@ %@", NSStringFromClass([logic class]), attribute ? NSStringFromClass([attribute class]) : @"nil", [parts componentsJoinedByString:@" "]);
}

static UIWindow *NeoWCActiveWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive || ![scene isKindOfClass:[UIWindowScene class]]) continue;
        NSArray<UIWindow *> *windows = ((UIWindowScene *)scene).windows;
        for (UIWindow *window in windows) {
            NSString *className = NSStringFromClass(window.class);
            if (window.isKeyWindow && window.windowLevel == UIWindowLevelNormal && ![className containsString:@"iConsole"]) return window;
        }
        for (UIWindow *window in windows) {
            NSString *className = NSStringFromClass(window.class);
            if (!window.hidden && window.alpha > 0.0 && window.windowLevel == UIWindowLevelNormal && ![className containsString:@"iConsole"]) return window;
        }
    }
    id windows = NeoWCTweakSafeValue(UIApplication.sharedApplication, @"windows");
    if ([windows isKindOfClass:[NSArray class]]) {
        for (UIWindow *window in windows) {
            if (!window.hidden && window.alpha > 0.0 && window.windowLevel == UIWindowLevelNormal && ![NSStringFromClass(window.class) containsString:@"iConsole"]) return window;
        }
    }
    return nil;
}

static void NeoWCShowTransientMessage(NSString *message, BOOL success) {
    UIWindow *window = NeoWCActiveWindow();
    if (!window || message.length == 0) return;
    UILabel *label = [UILabel new];
    label.text = message;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.78];
    label.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    label.layer.cornerRadius = 12.0;
    label.layer.masksToBounds = YES;
    label.alpha = 0.0;
    CGFloat width = MIN(CGRectGetWidth(window.bounds) - 48.0, 320.0);
    label.frame = CGRectMake((CGRectGetWidth(window.bounds) - width) * 0.5, window.safeAreaInsets.top + 18.0, width, success ? 44.0 : 60.0);
    [window addSubview:label];
    [UIView animateWithDuration:0.18 animations:^{ label.alpha = 1.0; } completion:^(__unused BOOL finished) {
        [UIView animateWithDuration:0.20 delay:2.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{ label.alpha = 0.0; } completion:^(__unused BOOL done) { [label removeFromSuperview]; }];
    }];
}

static UIViewController *NeoWCEditPresenterController(id logic) {
    if (!logic) return nil;
    UIViewController *cached = objc_getAssociatedObject(logic, &NeoWCEditPresenterControllerKey);
    if ([cached isKindOfClass:[UIViewController class]]) return cached;
    id candidate = NeoWCTweakSafeValue(logic, @"currentViewController");
    if (![candidate isKindOfClass:[UIViewController class]]) candidate = NeoWCTweakSafeValue(logic, @"forwardBasedViewController");
    SEL selector = NSSelectorFromString(@"getCurrentViewController");
    if (![candidate isKindOfClass:[UIViewController class]] && [logic respondsToSelector:selector]) {
        candidate = ((id (*)(id, SEL))objc_msgSend)(logic, selector);
    }
    if (![candidate isKindOfClass:[UIViewController class]]) return nil;
    objc_setAssociatedObject(logic, &NeoWCEditPresenterControllerKey, candidate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return candidate;
}

@interface NeoWCQuickSendSession : NSObject
@property (nonatomic, strong) id sourceLogic;
@property (nonatomic, strong) id forwardLogic;
@property (nonatomic, strong) id message;
@property (nonatomic, strong) id contact;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIViewController *presenter;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL sendButtonTapped;
- (void)finishSession;
@end

@implementation NeoWCQuickSendSession

- (UIViewController *)getCurrentViewController { return self.presenter; }
- (UIViewController *)GetCurrentViewController { return self.presenter; }
- (BOOL)shouldShowSendSuccessView:(__unused id)logic { return YES; }

- (void)OnForwardMessageSend:(id)logic {
    if (self.finished) return;
    id confirmSheet = NeoWCTweakSafeValue(self.forwardLogic, @"confirmSheetView");
    BOOL confirmedBySheet = [NeoWCTweakSafeValue(confirmSheet, @"isClickedSend") boolValue];
    if (!self.sendButtonTapped && !confirmedBySheet) {
        NeoWCLog(@"快捷发送收到确认页准备回调，等待用户点击发送");
        return;
    }
    SEL selector = NSSelectorFromString(@"OnForwardMessageSend:");
    if ([self.sourceLogic respondsToSelector:selector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(self.sourceLogic, selector, logic ?: self.forwardLogic);
    }
    NeoWCLog(@"快捷发送已确认发送，结束图片编辑流程");
    [self finishSession];
}

- (void)OnForwardMessageCancel:(id)logic {
    if (self.finished) return;
    SEL selector = NSSelectorFromString(@"OnForwardMessageCancel:");
    if ([self.sourceLogic respondsToSelector:selector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(self.sourceLogic, selector, logic ?: self.forwardLogic);
    }
    NeoWCLog(@"快捷发送已取消，保留图片编辑流程");
    [self finishSession];
}

- (void)OnForwardMessageConfirmCanceled:(id)logic {
    [self OnForwardMessageCancel:logic];
}

- (void)finishSession {
    if (self.finished) return;
    self.finished = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NeoWCActiveQuickSendSessions() removeObject:self];
        self.forwardLogic = nil;
        self.sourceLogic = nil;
        self.message = nil;
        self.contact = nil;
        self.image = nil;
        self.presenter = nil;
    });
}

@end

static BOOL NeoWCSendEditedImageToCurrentConversation(id logic, NSString **failureReason) {
    UIImage *image = NeoWCEditedImageFromLogic(logic);
    NSString *userName = NeoWCConversationUserNameForEditLogic(logic);
    id contact = NeoWCContactForUserName(userName);
    Class providerClass = objc_getClass("PasteboardMsgProvider");
    Class forwardClass = objc_getClass("ForwardMessageLogicController");
    SEL makeMessageSelector = sel_registerName("GetMessageFromImage:contact:");
    if (!image) {
        NeoWCLogEditImageDiagnostics(logic);
        if (failureReason) *failureReason = @"没有取得微信编辑后的图片";
        return NO;
    }
    if (userName.length == 0) { if (failureReason) *failureReason = @"当前编辑页不属于聊天会话"; return NO; }
    if (!contact) { if (failureReason) *failureReason = @"当前聊天联系人已失效"; return NO; }
    id contactNameValue = NeoWCTweakSafeValue(contact, @"m_nsUsrName");
    NSString *contactName = [contactNameValue isKindOfClass:[NSString class]] ? contactNameValue : nil;
    if (contactName.length > 0 && ![contactName isEqualToString:userName]) { if (failureReason) *failureReason = @"会话校验失败，已阻止串会话发送"; return NO; }
    if (!providerClass || ![providerClass respondsToSelector:makeMessageSelector]) { if (failureReason) *failureReason = @"微信图片消息接口已变化"; return NO; }
    if (!forwardClass) { if (failureReason) *failureReason = @"微信确认发送组件不存在"; return NO; }
    id message = ((id (*)(id, SEL, id, id))objc_msgSend)(providerClass, makeMessageSelector, image, contact);
    if (!message) { if (failureReason) *failureReason = @"微信未能创建编辑图片消息"; return NO; }
    id forwardLogic = [forwardClass new];
    SEL forwardSelector = sel_registerName("forwardMsgList:msgOriginList:toContacts:ignoreTips:showConfirmView:");
    if (!forwardLogic || ![forwardLogic respondsToSelector:forwardSelector]) { if (failureReason) *failureReason = @"微信确认发送方法已变化"; return NO; }
    SEL delegateSelector = sel_registerName("setDelegate:");
    if (![forwardLogic respondsToSelector:delegateSelector]) { if (failureReason) *failureReason = @"微信转发代理接口已变化"; return NO; }
    UIViewController *presenter = NeoWCEditPresenterController(logic);
    if (!presenter) {
        if (failureReason) *failureReason = @"无法取得微信图片编辑页面";
        return NO;
    }
    NeoWCQuickSendSession *session = [NeoWCQuickSendSession new];
    session.sourceLogic = logic;
    session.forwardLogic = forwardLogic;
    session.message = message;
    session.contact = contact;
    session.image = image;
    session.presenter = presenter;
    ((void (*)(id, SEL, id))objc_msgSend)(forwardLogic, delegateSelector, session);
    NeoWCTweakSetValue(forwardLogic, @"bSpecificContact", @YES);
    NeoWCTweakSetValue(forwardLogic, @"bPresent", @YES);
    NeoWCTweakSetValue(forwardLogic, @"bAnimation", @YES);
    [NeoWCActiveQuickSendSessions() addObject:session];
    NeoWCLog(@"快捷发送调用微信官方确认页：会话=%@ 页面=%@", userName, NSStringFromClass(presenter.class));
    ((void (*)(id, SEL, id, id, id, BOOL, BOOL))objc_msgSend)(forwardLogic, forwardSelector, @[message], nil, @[contact], NO, YES);
    __weak NeoWCQuickSendSession *weakSession = session;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NeoWCQuickSendSession *activeSession = weakSession;
        if (activeSession && !activeSession.finished) {
            NeoWCLog(@"快捷发送确认会话超时，释放保留资源");
            [activeSession finishSession];
        }
    });
    return YES;
}

static void NeoWCAttemptQuickSendWhenReady(id logic, __unused NSUInteger attempt) {
    if (!logic) {
        NeoWCShowTransientMessage(@"发送失败：图片编辑会话已经结束", NO);
        return;
    }
    NSString *reason = nil;
    if (NeoWCSendEditedImageToCurrentConversation(logic, &reason)) return;
    NSString *message = [NSString stringWithFormat:@"发送失败：%@", reason ?: @"未知原因"];
    NeoWCShowTransientMessage(message, NO);
    NeoWCLog(@"%@", message);
}

static void NeoWCResumePendingQuickSendIfReady(id logic) {
    if (!logic || ![objc_getAssociatedObject(logic, &NeoWCQuickSendPendingImageKey) boolValue]) return;
    UIImage *image = objc_getAssociatedObject(logic, &NeoWCEditedImageKey);
    if (![image isKindOfClass:[UIImage class]]) return;
    objc_setAssociatedObject(logic, &NeoWCQuickSendPendingImageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCAttemptQuickSendWhenReady(logic, 0);
}

static void NeoWCBeginQuickSend(id logic) {
    if (!logic) {
        NeoWCShowTransientMessage(@"发送失败：图片编辑会话已经结束", NO);
        return;
    }
    UIImage *cachedImage = objc_getAssociatedObject(logic, &NeoWCEditedImageKey);
    if ([cachedImage isKindOfClass:[UIImage class]]) {
        NeoWCAttemptQuickSendWhenReady(logic, 0);
        return;
    }
    objc_setAssociatedObject(logic, &NeoWCQuickSendPendingImageKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCLog(@"快捷发送等待微信生成最终编辑图片");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![objc_getAssociatedObject(logic, &NeoWCQuickSendPendingImageKey) boolValue]) return;
        objc_setAssociatedObject(logic, &NeoWCQuickSendPendingImageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NeoWCLogEditImageDiagnostics(logic);
        NeoWCShowTransientMessage(@"发送失败：微信未生成编辑后的图片", NO);
        NeoWCLog(@"发送失败：等待最终编辑图片超时");
    });
}

static NSString *NeoWCGameMD5ForContent(NSUInteger content) {
    Class gameControllerClass = objc_getClass("GameController");
    SEL selector = sel_registerName("getMD5ByGameContent:");
    if (!gameControllerClass || ![gameControllerClass respondsToSelector:selector]) return nil;
    return ((NSString *(*)(id, SEL, NSUInteger))objc_msgSend)(gameControllerClass, selector, content);
}

static void NeoWCRefreshDailyStepOverride(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:NeoWCStepOverrideEnabledKey]) return;
    NSInteger stepCount = [defaults integerForKey:NeoWCStepCountKey];
    if (stepCount <= 0) return;
    NSDate *configuredDate = [defaults objectForKey:NeoWCStepCountDateKey];
    if (![configuredDate isKindOfClass:[NSDate class]] || ![[NSCalendar currentCalendar] isDateInToday:configuredDate]) {
        [defaults setObject:[NSDate date] forKey:NeoWCStepCountDateKey];
        NeoWCLog(@"微信运动已按每日配置刷新为 %ld 步", (long)stepCount);
    }
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

static void NeoWCShowMomentsHeart(WCTimeLineCellView *cell) {
    UITapGestureRecognizer *recognizer = objc_getAssociatedObject(cell, &NeoWCMomentsDoubleTapRecognizerKey);
    UIWindow *window = cell.window;
    if (!window || !recognizer) return;
    CGPoint point = [recognizer locationInView:window];
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:34.0 weight:UIImageSymbolWeightSemibold];
    UIImageView *heart = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"heart.fill" withConfiguration:configuration]];
    heart.tintColor = [UIColor colorWithRed:0.96 green:0.25 blue:0.34 alpha:1.0];
    heart.contentMode = UIViewContentModeScaleAspectFit;
    heart.bounds = CGRectMake(0.0, 0.0, 44.0, 44.0);
    heart.center = point;
    heart.alpha = 0.0;
    heart.transform = CGAffineTransformMakeScale(0.52, 0.52);
    heart.userInteractionEnabled = NO;
    [window addSubview:heart];
    [UIView animateKeyframesWithDuration:0.52 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic | UIViewAnimationOptionAllowUserInteraction animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.30 animations:^{
            heart.alpha = 1.0;
            heart.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(0.0, -5.0), CGAffineTransformMakeScale(1.12, 1.12));
        }];
        [UIView addKeyframeWithRelativeStartTime:0.30 relativeDuration:0.32 animations:^{
            heart.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(0.0, -12.0), CGAffineTransformIdentity);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.62 relativeDuration:0.38 animations:^{
            heart.alpha = 0.0;
            heart.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(0.0, -24.0), CGAffineTransformMakeScale(0.88, 0.88));
        }];
    } completion:^(__unused BOOL finished) {
        [heart removeFromSuperview];
    }];
}

static void NeoWCPlayMomentsLikeHaptic(NSUserDefaults *defaults) {
    if (![defaults boolForKey:NeoWCMomentsLikeHapticEnabledKey]) return;
    CGFloat savedIntensity = [defaults objectForKey:NeoWCMomentsLikeHapticIntensityKey] ? [defaults doubleForKey:NeoWCMomentsLikeHapticIntensityKey] : 0.65;
    CGFloat calibratedIntensity = savedIntensity < 0.34 ? 0.58 : (savedIntensity < 0.75 ? 0.76 : 0.90);
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [generator prepare];
    if (@available(iOS 13.0, *)) [generator impactOccurredWithIntensity:calibratedIntensity];
    else [generator impactOccurred];
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
                if ([NSStringFromClass(candidate.class) containsString:@"iConsole"]) continue;
                if (candidate.isKeyWindow) return candidate;
                if (!candidate.hidden && candidate.alpha > 0.0 && !fallbackWindow) fallbackWindow = candidate;
            }
        }
        if (fallbackWindow) return fallbackWindow;
    }
    for (UIWindow *candidate in UIApplication.sharedApplication.windows) {
        if ([NSStringFromClass(candidate.class) containsString:@"iConsole"]) continue;
        if (candidate.isKeyWindow) return candidate;
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

static void NeoWCRefreshAntiRevokeCellsInView(UIView *view) {
    if (!view) return;
    Class cellClass = NSClassFromString(@"CommonMessageCellView");
    if (cellClass && [view isKindOfClass:cellClass]) {
        SEL refreshSelector = NSSelectorFromString(@"neowc_scheduleAntiRevokeSidePromptRefresh");
        if ([view respondsToSelector:refreshSelector]) {
            ((void (*)(id, SEL))objc_msgSend)(view, refreshSelector);
        }
    }
    Class systemCellClass = NSClassFromString(@"SystemMessageCellView");
    if (systemCellClass && [view isKindOfClass:systemCellClass]) {
        SEL colorSelector = NSSelectorFromString(@"neowc_applyAntiRevokeTextColor");
        if ([view respondsToSelector:colorSelector]) {
            ((void (*)(id, SEL))objc_msgSend)(view, colorSelector);
        }
    }
    for (UIView *subview in view.subviews) NeoWCRefreshAntiRevokeCellsInView(subview);
}

static void NeoWCRefreshVisibleAntiRevokeCells(void) {
    UIWindow *window = NeoWCActiveApplicationWindow();
    if (window) NeoWCRefreshAntiRevokeCellsInView(window);
}

static void NeoWCPresentJokerEditorForCell(id cell) {
    if (!NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey)) return;
    id message = NeoWCMessageWrapForCell(cell);
    if (!NeoWCMessageCanJokerEdit(message)) return;
    UIViewController *presenter = NeoWCJokerPresenterForCell(cell);
    if (!presenter.view.window) return;
    NSString *current = NeoWCDisplayTextForJokerCell(cell, message);
    BOOL isTransfer = NeoWCMessageIsTransfer(message);
    if (isTransfer && ([current hasPrefix:@"¥"] || [current hasPrefix:@"￥"])) current = [current substringFromIndex:1];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"聊天记录小丑"
                                                                   message:@"仅修改当前页面的本机显示，离开页面后可能恢复"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = current;
        textField.placeholder = @"输入新的显示文字或金额";
        if (isTransfer) textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    id targetCell = cell;
    [alert addAction:[UIAlertAction actionWithTitle:@"应用" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (targetCell && text.length > 0) NeoWCApplyJokerText(targetCell, text);
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static MMMenuItem *NeoWCJokerMenuItem(id target) {
    if (!NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey)) return nil;
    id message = NeoWCMessageWrapForCell(target);
    if (!NeoWCMessageCanJokerEdit(message)) return nil;
    Class itemClass = NSClassFromString(@"MMMenuItem");
    if (!itemClass) return nil;
    if (![itemClass instancesRespondToSelector:@selector(initWithTitle:icon:target:action:)]) return nil;
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:18.0 weight:UIImageSymbolWeightRegular];
    UIImage *icon = [[UIImage systemImageNamed:@"face.smiling.fill" withConfiguration:configuration] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    return [[itemClass alloc] initWithTitle:@"小丑" icon:icon target:target action:@selector(joker_handleMenuItem:)];
}

static NSArray *NeoWCOperationMenuItemsWithJoker(id target, NSArray *originalItems) {
    if (![originalItems isKindOfClass:[NSArray class]] || !NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey)) return originalItems;
    for (id item in originalItems) {
        if ([NeoWCTweakSafeValue(item, @"title") isEqualToString:@"小丑"]) return originalItems;
    }
    MMMenuItem *jokerItem = NeoWCJokerMenuItem(target);
    if (!jokerItem) return originalItems;
    NSMutableArray *items = [originalItems mutableCopy];
    [items insertObject:jokerItem atIndex:0];
    return items;
}

static void NeoWCPresentWalletBalanceEditor(void) {
    UIWindow *window = NeoWCActiveApplicationWindow();
    UIViewController *presenter = NeoWCTopControllerForLoginToast(window.rootViewController);
    if (!presenter.view.window) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"钱包余额本地显示"
                                                                   message:@"仅修改本机界面文字；留空或输入 0 恢复真实显示"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        long long fen = NeoWCLongLongDefaultForKey(NeoWCWalletBalanceFenKey);
        textField.text = fen > 0 ? [NSString stringWithFormat:@"%.2f", fen / 100.0] : nil;
        textField.placeholder = @"例如 888.88";
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        long long fen = text.length > 0 ? (long long)llround(text.doubleValue * 100.0) : 0;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(MAX(0LL, fen)) forKey:NeoWCWalletBalanceFenKey];
        [defaults setBool:fen > 0 forKey:NeoWCWalletBalanceEnabledKey];
        NeoWCShowTransientMessage(fen > 0 ? @"钱包余额显示已更新" : @"钱包余额显示已恢复", YES);
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static void NeoWCInstallWalletLongPressIfNeeded(UIView *view, id target, SEL action) {
    if (!view || objc_getAssociatedObject(view, &NeoWCWalletGestureRecognizerKey)) return;
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:target action:action];
    recognizer.minimumPressDuration = 0.55;
    recognizer.cancelsTouchesInView = NO;
    [view addGestureRecognizer:recognizer];
    view.userInteractionEnabled = YES;
    objc_setAssociatedObject(view, &NeoWCWalletGestureRecognizerKey, recognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    self.sheetView.transform = CGAffineTransformMakeTranslation(0.0, 120.0);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.16 delay:0.0 usingSpringWithDamping:0.94 initialSpringVelocity:0.25 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
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
                                 version:@"0.1.1"
                              controller:NSStringFromClass([NeoWCSettingsViewController class])];
    NeoWCRegisterPluginShortcuts(manager);
    NeoWCDidRegister = YES;
    NeoWCLog(@"已注册 WCPluginsMgr 设置入口");
}

@interface NeoWCEntryLoader : NSObject
@end

@implementation NeoWCEntryLoader

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        NeoWCRegisterPlugin();
        NeoWCRefreshDailyStepOverride();

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        NeoWCRegisterPlugin();
                        NeoWCRefreshDailyStepOverride();
                        [[NeoWCDebugManager sharedManager] applySavedState];
                    }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationWillEnterForegroundNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        NeoWCRefreshDailyStepOverride();
                    }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:NeoWCEnhancementDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        NeoWCSynchronizeVisibleMomentsCells();
                    }];

        __block BOOL lastFloatingDebugState = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCDebugFloatingEnabledKey];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSUserDefaultsDidChangeNotification
                        object:[NSUserDefaults standardUserDefaults]
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        BOOL currentState = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCDebugFloatingEnabledKey];
                        if (currentState == lastFloatingDebugState) return;
                        lastFloatingDebugState = currentState;
                        [[NeoWCDebugManager sharedManager] setFloatingEnabled:currentState];
                    }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:NeoWCAntiRevokePromptDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        NeoWCRefreshVisibleAntiRevokeCells();
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
    NeoWCCompatibilityMarkTriggered(@"plugin-visibility");
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

%hook EditImageForwardAndEditLogicController

- (void)OnClickEditImageDoneBarButton {
    if (NeoWCEnhancementEnabled(NeoWCImageEditQuickSendEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"image-edit");
        NeoWCCurrentEditImageLogicController = self;
        (void)NeoWCConversationUserNameForEditLogic(self);
        (void)NeoWCEditPresenterController(self);
        objc_setAssociatedObject(self, &NeoWCEditedImageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    %orig;
}

%end

%hook EditImageAttr

- (void)setEditedImage:(id)value {
    %orig;
    if (!NeoWCEnhancementEnabled(NeoWCImageEditQuickSendEnabledKey)) return;
    UIImage *image = NeoWCImageFromEditValue(value, 0);
    id logic = NeoWCCurrentEditImageLogicController;
    if (image && logic) {
        NeoWCCacheEditedImage(logic, image, @"setEditedImage:");
        NeoWCResumePendingQuickSendIfReady(logic);
    }
}

- (void)setEditedImages:(id)value {
    %orig;
    if (!NeoWCEnhancementEnabled(NeoWCImageEditQuickSendEnabledKey)) return;
    UIImage *image = NeoWCImageFromEditValue(value, 0);
    id logic = NeoWCCurrentEditImageLogicController;
    if (image && logic) {
        NeoWCCacheEditedImage(logic, image, @"setEditedImages:");
        NeoWCResumePendingQuickSendIfReady(logic);
    }
}

%end

%hook WCActionSheet

- (void)showInView:(UIView *)view {
    BOOL hasForward = [self isContainButtonTitle:@"转发给朋友"] || [self isContainButtonTitle:@"发送给朋友"];
    BOOL isEditedImageMenu = hasForward &&
                             [self isContainButtonTitle:@"收藏"] &&
                             [self isContainButtonTitle:@"保存图片"];
    if (NeoWCEnhancementEnabled(NeoWCImageEditQuickSendEnabledKey) && isEditedImageMenu && ![self isContainButtonTitle:@"发送到当前会话"]) {
        id logic = NeoWCTweakSafeValue(self, @"delegateEx") ?: NeoWCTweakSafeValue(self, @"delegate");
        Class logicClass = objc_getClass("EditImageForwardAndEditLogicController");
        if (!logicClass || ![logic isKindOfClass:logicClass]) logic = NeoWCCurrentEditImageLogicController;
        NSString *conversationUserName = NeoWCConversationUserNameForEditLogic(logic);
        (void)NeoWCEditPresenterController(logic);
        id conversationContact = NeoWCContactForUserName(conversationUserName);
        if (logic && conversationUserName.length > 0 && conversationContact) {
            __weak id weakLogic = logic;
            [self addButtonWithTitle:@"发送到当前会话" eventAction:^{
                id strongLogic = weakLogic;
                if (!strongLogic) { NeoWCShowTransientMessage(@"发送失败：图片编辑会话已经结束", NO); return; }
                // WeChat writes the final image shortly after the action callback on
                // some versions. Send immediately when ready, otherwise resume from
                // EditImageAttr's setter without leaving the official editor flow.
                NeoWCBeginQuickSend(strongLogic);
            }];
        }
    }
    %orig;
}

%end

%hook SharePreConfirmSheetView

- (void)onConfirmButtonClick {
    id owner = NeoWCTweakSafeValue(self, @"delegate") ?: NeoWCTweakSafeValue(self, @"msgLogicController");
    for (NeoWCQuickSendSession *session in [NeoWCActiveQuickSendSessions() copy]) {
        if (session.forwardLogic == owner) session.sendButtonTapped = YES;
    }
    %orig;
}

- (void)onCancelButtonClick {
    id owner = NeoWCTweakSafeValue(self, @"delegate") ?: NeoWCTweakSafeValue(self, @"msgLogicController");
    NSArray<NeoWCQuickSendSession *> *sessions = [NeoWCActiveQuickSendSessions() copy];
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NeoWCQuickSendSession *session in sessions) {
            if (!session.finished && session.forwardLogic == owner) [session OnForwardMessageCancel:owner];
        }
    });
}

%end

%hook UIImageView

- (void)setAccessibilityLabel:(NSString *)label {
    %orig;
    if ([label isEqualToString:@"免打扰"]) NeoWCUpdateChatMuteImageView(self);
}

- (void)didMoveToWindow {
    %orig;
    if ([self.accessibilityLabel isEqualToString:@"免打扰"]) NeoWCUpdateChatMuteImageView(self);
}

- (void)setHidden:(BOOL)hidden {
    if (!hidden && NeoWCShouldKeepManagedChatMuteImageViewHidden(self)) {
        %orig(YES);
        return;
    }
    %orig;
}

%end

%hook MMInputToolView

- (void)didMoveToWindow {
    %orig;
    if (self.window) NeoWCApplyChatInputRoundingToToolView(self);
}

%end

%hook MMGrowTextView

- (void)didMoveToWindow {
    %orig;
    NeoWCSynchronizeInputSwipeActions(self);
}

%new
- (void)neowc_handleInputSwipeLeft:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateEnded || !NeoWCEnhancementEnabled(NeoWCInputSwipeActionsEnabledKey)) return;
    UITextView *textView = NeoWCInnerTextView(self);
    NeoWCTweakSetValue(self, @"text", @"");
    if (textView) {
        textView.text = @"";
        textView.selectedRange = NSMakeRange(0, 0);
        SEL changeSelector = NSSelectorFromString(@"textViewDidChange:");
        if ([self respondsToSelector:changeSelector]) ((void (*)(id, SEL, id))objc_msgSend)(self, changeSelector, textView);
    }
}

%new
- (void)neowc_handleInputSwipeRight:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateEnded || !NeoWCEnhancementEnabled(NeoWCInputSwipeActionsEnabledKey)) return;
    UITextView *textView = NeoWCInnerTextView(self);
    if (textView) {
        [textView becomeFirstResponder];
        [textView paste:nil];
        return;
    }
    NSString *pasteText = UIPasteboard.generalPasteboard.string;
    if (pasteText.length == 0) return;
    NSString *currentText = NeoWCTweakSafeValue(self, @"text");
    if (![currentText isKindOfClass:[NSString class]]) currentText = @"";
    NeoWCTweakSetValue(self, @"text", [currentText stringByAppendingString:pasteText]);
}

%end

%hook BaseMsgContentViewController

- (void)ShowMultiSelectMoreOperation:(id)argument {
    NeoWCCompatibilityMarkTriggered(@"multi-select-export");
    BOOL exportEnabled = NeoWCEnhancementEnabled(NeoWCMultiSelectExportEnabledKey);
    if (!exportEnabled) {
        %orig;
        return;
    }
    objc_setAssociatedObject(self, &NeoWCChatExportBuildingMenuKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig;
    objc_setAssociatedObject(self, &NeoWCChatExportBuildingMenuKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)scrollActionSheet:(id)sheet didSelecteItem:(id)item {
    NSString *identifier = NeoWCTweakSafeValue(item, @"userInfo");
    BOOL isExportAction = NO;
    for (NSDictionary *action in NeoWCChatMultiSelectActions()) {
        if ([identifier isEqualToString:action[@"id"]]) { isExportAction = YES; break; }
    }
    if (isExportAction) {
        SEL dismissSelector = NSSelectorFromString(@"dismissAnimated:");
        if ([sheet respondsToSelector:dismissSelector]) ((void (*)(id, SEL, BOOL))objc_msgSend)(sheet, dismissSelector, YES);
        __weak UIViewController *weakController = (UIViewController *)self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NeoWCHandleChatMultiSelectAction(weakController, identifier);
        });
        return;
    }
    %orig;
}

%end

%hook MMScrollActionSheet

- (void)showInView:(UIView *)view {
    id delegate = NeoWCTweakSafeValue(self, @"delegate");
    BOOL isExportMenu = [objc_getAssociatedObject(delegate, &NeoWCChatExportBuildingMenuKey) boolValue];
    if (isExportMenu && NeoWCEnhancementEnabled(NeoWCMultiSelectExportEnabledKey)) {
        NSArray *originalRows = NeoWCTweakSafeValue(self, @"itemArray");
        if ([originalRows isKindOfClass:[NSArray class]] && originalRows.count > 0) {
            NSMutableArray *rows = [NSMutableArray arrayWithCapacity:originalRows.count];
            for (id originalRow in originalRows) {
                NSMutableArray *row = [originalRow isKindOfClass:[NSArray class]] ? [originalRow mutableCopy] : [NSMutableArray array];
                [rows addObject:row];
            }
            for (NSDictionary *action in NeoWCChatMultiSelectActions()) {
                BOOL exists = NO;
                for (NSArray *row in rows) {
                    for (id existingItem in row) {
                        if ([NeoWCTweakSafeValue(existingItem, @"userInfo") isEqualToString:action[@"id"]]) { exists = YES; break; }
                    }
                    if (exists) break;
                }
                if (exists) continue;
                Class itemClass = NSClassFromString(@"MMScrollActionSheetItem");
                id exportItem = itemClass ? [itemClass new] : nil;
                if (!exportItem) continue;
                UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:21.0 weight:UIImageSymbolWeightRegular];
                UIImage *icon = [UIImage systemImageNamed:action[@"symbol"] withConfiguration:configuration];
                icon = [icon imageWithTintColor:UIColor.labelColor renderingMode:UIImageRenderingModeAlwaysOriginal];
                NeoWCTweakSetValue(exportItem, @"title", action[@"title"]);
                NeoWCTweakSetValue(exportItem, @"iconImg", icon);
                NeoWCTweakSetValue(exportItem, @"userInfo", action[@"id"]);
                [(NSMutableArray *)rows.firstObject addObject:exportItem];
            }
            NeoWCTweakSetValue(self, @"itemArray", rows);
        }
    }
    %orig;
}

%end

%hook TextMessageCellView

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    return NeoWCOperationMenuItemsWithJoker(self, items);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(joker_handleMenuItem:)) {
        return NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey) && NeoWCMessageCanJokerEdit(NeoWCMessageWrapForCell(self));
    }
    return %orig;
}

%new
- (void)joker_handleMenuItem:(id)sender {
    NeoWCCompatibilityMarkTriggered(@"chat-joker");
    NeoWCPresentJokerEditorForCell(self);
}

%end

%hook AppMessageCellView

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    return NeoWCOperationMenuItemsWithJoker(self, items);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(joker_handleMenuItem:)) {
        return NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey) && NeoWCMessageCanJokerEdit(NeoWCMessageWrapForCell(self));
    }
    return %orig;
}

%new
- (void)joker_handleMenuItem:(id)sender {
    NeoWCCompatibilityMarkTriggered(@"chat-joker");
    NeoWCPresentJokerEditorForCell(self);
}

%end

%hook WCPayTransferMessageCellView

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    return NeoWCOperationMenuItemsWithJoker(self, items);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(joker_handleMenuItem:)) {
        return NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey) && NeoWCMessageCanJokerEdit(NeoWCMessageWrapForCell(self));
    }
    return %orig;
}

%new
- (void)joker_handleMenuItem:(id)sender {
    NeoWCCompatibilityMarkTriggered(@"chat-joker");
    NeoWCPresentJokerEditorForCell(self);
}

%end

%hook WCTimeLineCellView

- (void)initView {
    %orig;
    NeoWCCompatibilityMarkTriggered(@"moments-like");
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self onAccessibilityLike];
    NeoWCShowMomentsHeart(self);
    NeoWCPlayMomentsLikeHaptic(defaults);
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
    static dispatch_once_t compatibilityOnce;
    dispatch_once(&compatibilityOnce, ^{ NeoWCCompatibilityMarkTriggered(@"anti-revoke"); });
    @try {
        if (NeoWCHandleRevokeMessage(self, wrap)) return;
    } @catch (NSException *exception) {
        NeoWCLog(@"防撤回兼容保护已回退微信原逻辑：%@", exception.reason ?: exception.name);
    }
    %orig;
}

- (void)AddEmoticonMsg:(NSString *)message MsgWrap:(CMessageWrap *)wrap {
    static dispatch_once_t compatibilityOnce;
    dispatch_once(&compatibilityOnce, ^{ NeoWCCompatibilityMarkTriggered(@"game-selector"); });
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
    [presenter presentViewController:selector animated:NO completion:nil];
}

%end

%hook WCDeviceStepObject

- (unsigned int)m7StepCount {
    static dispatch_once_t compatibilityOnce;
    dispatch_once(&compatibilityOnce, ^{ NeoWCCompatibilityMarkTriggered(@"steps"); });
    unsigned int originalValue = %orig;
    if (!NeoWCEnhancementEnabled(NeoWCStepOverrideEnabledKey)) return originalValue;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *configuredDate = [defaults objectForKey:NeoWCStepCountDateKey];
    if (![configuredDate isKindOfClass:[NSDate class]] || ![[NSCalendar currentCalendar] isDateInToday:configuredDate]) return originalValue;
    NSInteger configuredValue = [defaults integerForKey:NeoWCStepCountKey];
    return configuredValue > 0 ? (unsigned int)MIN(100000, configuredValue) : originalValue;
}

- (unsigned int)hkStepCount {
    unsigned int originalValue = %orig;
    if (!NeoWCEnhancementEnabled(NeoWCStepOverrideEnabledKey)) return originalValue;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *configuredDate = [defaults objectForKey:NeoWCStepCountDateKey];
    if (![configuredDate isKindOfClass:[NSDate class]] || ![[NSCalendar currentCalendar] isDateInToday:configuredDate]) return originalValue;
    NSInteger configuredValue = [defaults integerForKey:NeoWCStepCountKey];
    return configuredValue > 0 ? (unsigned int)MIN(100000, configuredValue) : originalValue;
}

%end

%hook CommonMessageCellView

- (void)setViewModel:(id)viewModel {
    %orig;
    [self neowc_scheduleAntiRevokeSidePromptRefresh];
}

- (void)updateStatus {
    %orig;
    [self neowc_scheduleAntiRevokeSidePromptRefresh];
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [self neowc_scheduleAntiRevokeSidePromptRefresh];
    } else {
        UILabel *label = objc_getAssociatedObject(self, &NeoWCAntiRevokeSideLabelKey);
        if (label && !label.hidden) label.hidden = YES;
    }
}

%new
- (void)neowc_scheduleAntiRevokeSidePromptRefresh {
    UILabel *label = objc_getAssociatedObject(self, &NeoWCAntiRevokeSideLabelKey);
    if (!NeoWCUsesAntiRevokeSidePrompt()) {
        if (label && !label.hidden) label.hidden = YES;
        return;
    }
    if ([objc_getAssociatedObject(self, &NeoWCAntiRevokeSideRefreshScheduledKey) boolValue]) return;
    objc_setAssociatedObject(self, &NeoWCAntiRevokeSideRefreshScheduledKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak CommonMessageCellView *weakCell = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        CommonMessageCellView *cell = weakCell;
        if (!cell) return;
        objc_setAssociatedObject(cell, &NeoWCAntiRevokeSideRefreshScheduledKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (!cell.window) return;
        [cell neowc_refreshAntiRevokeSidePrompt];
    });
}

%new
- (void)neowc_refreshAntiRevokeSidePrompt {
    UILabel *label = objc_getAssociatedObject(self, &NeoWCAntiRevokeSideLabelKey);
    BOOL useSidePromptStyle = NeoWCUsesAntiRevokeSidePrompt();
    if (!useSidePromptStyle) {
        if (label && !label.hidden) label.hidden = YES;
        return;
    }
    id viewModel = NeoWCTweakSafeValue(self, @"viewModel");
    if (!viewModel) viewModel = NeoWCTweakSafeValue(self, @"m_viewModel");
    id message = NeoWCTweakSafeValue(viewModel, @"messageWrap");
    if (!message) message = NeoWCTweakSafeValue(viewModel, @"m_messageWrap");
    if (!message) message = NeoWCTweakSafeValue(viewModel, @"msgWrap");
    NSString *prompt = NeoWCAntiRevokeSidePromptForMessage(message);
    BOOL useSidePrompt = prompt.length > 0;
    if (!useSidePrompt) {
        if (label && !label.hidden) label.hidden = YES;
        return;
    }

    if (!label) {
        label = [UILabel new];
        label.userInteractionEnabled = NO;
        label.font = [UIFont systemFontOfSize:10.5 weight:UIFontWeightRegular];
        label.textColor = [UIColor tertiaryLabelColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 1;
        label.layer.zPosition = 1000.0;
        [self addSubview:label];
        objc_setAssociatedObject(self, &NeoWCAntiRevokeSideLabelKey, label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (label.hidden) label.hidden = NO;
    if (label.alpha != 1.0) label.alpha = 1.0;
    if (![label.text isEqualToString:prompt]) label.text = prompt;
    UIColor *promptColor = NeoWCColorForDefaultsKey(NeoWCAntiRevokeSideTextColorKey, UIColor.tertiaryLabelColor);
    if (![label.textColor isEqual:promptColor]) label.textColor = promptColor;

    id bubble = nil;
    SEL bubbleSelector = NSSelectorFromString(@"getBgImageView");
    if ([self respondsToSelector:bubbleSelector]) bubble = ((id (*)(id, SEL))objc_msgSend)(self, bubbleSelector);
    if (![bubble isKindOfClass:[UIView class]]) {
        if (!label.hidden) label.hidden = YES;
        return;
    }
    UIView *bubbleView = bubble;
    CGRect bubbleFrame = [bubbleView.superview convertRect:bubbleView.frame toView:self];
    CGSize promptSize = [prompt sizeWithAttributes:@{ NSFontAttributeName: label.font }];
    CGFloat labelWidth = MIN(160.0, MAX(36.0, ceil(promptSize.width) + 8.0));
    CGFloat labelHeight = 18.0;
    BOOL isSender = [NeoWCTweakSafeValue(viewModel, @"isSender") boolValue];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id storedOffsetX = [defaults objectForKey:NeoWCAntiRevokeSideOffsetXKey];
    id storedOffsetY = [defaults objectForKey:NeoWCAntiRevokeSideOffsetYKey];
    CGFloat offsetX = storedOffsetX ? [storedOffsetX doubleValue] : 0.0;
    CGFloat offsetY = storedOffsetY ? [storedOffsetY doubleValue] : 10.0;
    CGFloat x = isSender ? CGRectGetMinX(bubbleFrame) - labelWidth - 7.0 + offsetX : CGRectGetMaxX(bubbleFrame) + 7.0 - offsetX;
    x = MIN(MAX(4.0, x), MAX(4.0, CGRectGetWidth(self.bounds) - labelWidth - 4.0));
    CGFloat y = CGRectGetMidY(bubbleFrame) - labelHeight * 0.5 + offsetY;
    CGRect targetFrame = CGRectIntegral(CGRectMake(x, y, labelWidth, labelHeight));
    if (!CGRectEqualToRect(label.frame, targetFrame)) label.frame = targetFrame;
}

- (void)prepareForReuse {
    %orig;
    UILabel *label = objc_getAssociatedObject(self, &NeoWCAntiRevokeSideLabelKey);
    label.hidden = YES;
    label.text = nil;
}

%end

%hook SystemMessageCellView

- (void)layoutSubviews {
    %orig;
    BOOL wasApplied = [objc_getAssociatedObject(self, &NeoWCAntiRevokeSystemColorAppliedKey) boolValue];
    if (!NeoWCEnhancementEnabled(NeoWCAntiRevokeKey) && !wasApplied) return;
    [self neowc_applyAntiRevokeTextColor];
}

%new
- (void)neowc_applyAntiRevokeTextColor {
    id viewModel = NeoWCTweakSafeValue(self, @"viewModel");
    id message = NeoWCTweakSafeValue(viewModel, @"messageWrap");
    id richTextView = [self respondsToSelector:@selector(getRichTextView)] ? [self getRichTextView] : NeoWCTweakSafeValue(self, @"m_richTextView");
    if (!richTextView) return;
    UIColor *originalColor = objc_getAssociatedObject(richTextView, &NeoWCAntiRevokeOriginalSystemTextColorKey);
    if (!originalColor) {
        id currentColor = NeoWCTweakSafeValue(richTextView, @"textColor");
        if (![currentColor isKindOfClass:[UIColor class]]) currentColor = NeoWCTweakSafeValue(richTextView, @"oTextColor");
        if ([currentColor isKindOfClass:[UIColor class]]) {
            originalColor = currentColor;
            objc_setAssociatedObject(richTextView, &NeoWCAntiRevokeOriginalSystemTextColorKey, originalColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    BOOL shouldApply = NeoWCEnhancementEnabled(NeoWCAntiRevokeKey) && NeoWCAntiRevokeIsLocalPromptMessage(message);
    UIColor *color = shouldApply
        ? NeoWCColorForDefaultsKey(NeoWCAntiRevokeLocalTextColorKey, UIColor.secondaryLabelColor)
        : originalColor;
    if (color) {
        UIColor *currentColor = NeoWCTweakSafeValue(richTextView, @"textColor");
        if (![currentColor isEqual:color]) {
            NeoWCTweakSetValue(richTextView, @"textColor", color);
            NeoWCTweakSetValue(richTextView, @"oTextColor", color);
            if ([richTextView isKindOfClass:[UIView class]]) [(UIView *)richTextView setNeedsDisplay];
        }
    }
    objc_setAssociatedObject(self, &NeoWCAntiRevokeSystemColorAppliedKey,
                             shouldApply ? @YES : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end

%hook WCDataItem

- (unsigned int)stepCount {
    unsigned int originalValue = %orig;
    if (!NeoWCEnhancementEnabled(NeoWCStepOverrideEnabledKey)) return originalValue;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *configuredDate = [defaults objectForKey:NeoWCStepCountDateKey];
    if (![configuredDate isKindOfClass:[NSDate class]] || ![[NSCalendar currentCalendar] isDateInToday:configuredDate]) return originalValue;
    NSInteger configuredValue = [defaults integerForKey:NeoWCStepCountKey];
    return configuredValue > 0 ? (unsigned int)MIN(100000, configuredValue) : originalValue;
}

- (BOOL)isAd {
    static dispatch_once_t compatibilityOnce;
    dispatch_once(&compatibilityOnce, ^{ NeoWCCompatibilityMarkTriggered(@"ad-block"); });
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)isVideoAd {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

%end

%hook MMUILabel

- (void)setText:(NSString *)text {
    NSString *contactsText = NeoWCContactsCountTextForOriginal(text);
    if (contactsText.length > 0 && ![contactsText isEqualToString:text]) {
        NeoWCCompatibilityMarkTriggered(@"contacts-count");
    }
    %orig(contactsText ?: text);
}

%end

%hook TimeoutNumber

- (void)didMoveToSuperview {
    %orig;
    NeoWCInstallWalletLongPressIfNeeded((UIView *)self, self, @selector(neowc_walletHandleLongPress:));
}

- (void)updateNumber:(unsigned long long)number {
    unsigned long long balanceFen = NeoWCWalletBalanceFenOverride();
    if (balanceFen > 0) {
        NeoWCCompatibilityMarkTriggered(@"wallet-balance");
        %orig(balanceFen);
        return;
    }
    %orig;
}

%new
- (void)neowc_walletHandleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NeoWCCompatibilityMarkTriggered(@"wallet-balance");
        NeoWCPresentWalletBalanceEditor();
    }
}

%end

%hook WCPayWalletEntryHeaderView

- (void)didMoveToSuperview {
    %orig;
    NeoWCInstallWalletLongPressIfNeeded((UIView *)self, self, @selector(neowc_walletHeaderHandleLongPress:));
}

%new
- (void)neowc_walletHeaderHandleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NeoWCCompatibilityMarkTriggered(@"wallet-balance");
        NeoWCPresentWalletBalanceEditor();
    }
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
    NeoWCCompatibilityMarkTriggered(@"device-login");
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
    NeoWCCompatibilityMarkTriggered(@"game-login");
    if (NeoWCTryAuthorizeGame(self)) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        NeoWCTryAuthorizeGame(self);
    });
}

%end
