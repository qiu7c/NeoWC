#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import <stdlib.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "Sources/NeoWCSettingsViewController.h"
#import "Sources/NeoWCSettingsCatalog.h"
#import "Sources/NeoWCAccount.h"
#import "Sources/NeoWCAntiRevoke.h"
#import "Sources/NeoWCChatExport.h"
#import "Sources/NeoWCCompatibility.h"
#import "Sources/NeoWCDebug.h"
#import "Sources/NeoWCEnhancements.h"
#import "Sources/NeoWCPluginManager.h"
#import "Sources/NeoWCRuntimeFeatures.h"
#import "Sources/NeoWCInterfaceTweaks.h"
#import "Sources/NeoWCMessageTime.h"

@interface WCActionSheet : NSObject
- (void)addButtonWithTitle:(NSString *)title eventAction:(void (^)(void))eventAction;
- (BOOL)isContainButtonTitle:(NSString *)title;
@end

@interface WCActionSheetItem : NSObject
- (instancetype)initWithTitle:(NSString *)title;
- (void)setBEnable:(BOOL)enabled;
- (void)setBDestructiveButton:(BOOL)destructive;
- (void)setEventAction:(void (^)(void))eventAction;
@end

@interface MMMenuItem : NSObject
- (instancetype)initWithTitle:(NSString *)title icon:(UIImage *)icon target:(id)target action:(SEL)action;
- (instancetype)initWithTitle:(NSString *)title svgName:(NSString *)svgName target:(id)target action:(SEL)action;
- (instancetype)initWithTitle:(NSString *)title svgName:(NSString *)svgName action:(SEL)action;
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
- (void)editBlackList;
- (void)initTimeLabel;
- (void)updateWithDataItem:(id)dataItem actionAreaVM:(id)actionAreaVM;
- (void)onAccessibilityLike;
- (id)operateBtnImage:(BOOL)spring isSpringStyle:(BOOL)springStyle;
- (void)neowc_handleMomentsDoubleTap;
- (void)neowc_handleMomentsForward:(id)sender;
@end

@interface WCTimeLineOperateButtonView : UIButton
@end

@interface MMUILabel : UILabel
@end

@interface WCOperateFloatView : UIView
- (void)showWithItemData:(id)item tipPoint:(CGPoint)tipPoint;
- (void)hide;
- (void)neowc_handleMomentsForward:(id)sender;
@end

@interface CommonMessageCellView : UIView
- (void)neowc_refreshAntiRevokeSidePrompt;
- (void)neowc_scheduleAntiRevokeSidePromptRefresh;
- (void)neowc_handleReplyPan:(UIPanGestureRecognizer *)recognizer;
- (void)neowc_handleMessageTapAction:(UITapGestureRecognizer *)recognizer;
- (void)handleTapReferMessage;
- (void)handleTapForReferMsg:(id)sender;
- (void)onReturnToOriginalMsg;
@end

@interface RoomContentLogicController : NSObject
- (NSArray *)getDefaultTitleTailSubViews;
- (id)getMemeberCountLabel;
- (CGFloat)GetTitleLabelOffset;
@end

@interface BaseMsgContentViewController : UIViewController
- (id)GetContact;
- (void)returnToOriginalMsg:(id)message;
@end

@interface VoIPBubbleMessageCellView : UIView
- (void)startVoiceVoip;
- (void)startVideoVoip;
@end

@interface ScanQRCodeLogicController : NSObject
- (void)onDetectCodesWithMarkDotInfoList:(id)list isCameraScan:(BOOL)isCameraScan;
- (BOOL)isInScanSceneAndUseCameraScan;
- (NSInteger)fromScene;
- (NSInteger)m_sourceType;
- (NSInteger)fromRawScene;
- (NSInteger)picFrom;
- (void)setIsFromAlbum:(BOOL)isFromAlbum;
@end

@interface WCRedEnvelopesRedEnvelopesDetailViewController : UIViewController
@end

@interface BaseMessageCellView : UIView
- (NSArray *)filteredMenuItems:(NSArray *)items;
@end

@interface VoiceMessageCellView : UIView
- (void)onVoiceTrans:(id)sender;
@end

@interface MoreViewController : UIViewController
- (void)addCardsIfNeededToSection:(id)section;
- (void)addEmoticonsIfNeededToSection:(id)section;
- (id)createFinderEntranceCellConfig:(CGRect)frame;
@end

@interface WCTableViewSectionManager : NSObject
- (void)addCell:(id)cell;
- (void)insertCell:(id)cell At:(NSUInteger)index;
@end

@interface WeixinContactInfoAssist : NSObject
- (void)neowc_copyRawContactID;
@end

@interface ChatRoomInfoViewController : UIViewController
- (void)neowc_copyRawContactID;
@end

@interface SessionSelectController : UIViewController
@end

@interface ShortVideoToolbar : UIView
@end

@interface MMScreenShotViewController : UIViewController
- (void)show;
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

@interface UploadVoiceWrap : NSObject
- (void)setM_uiVoiceForwardFlag:(unsigned int)forwardFlag;
@end

@interface UploadVoiceRequest : NSObject
- (void)setForwardFlag:(unsigned int)forwardFlag;
@end

@interface CMessageMgr : NSObject
- (void)AddEmoticonMsg:(NSString *)message MsgWrap:(CMessageWrap *)wrap;
- (void)onNewSyncNotAddDBMessage:(CMessageWrap *)wrap;
- (void)AsyncOnAddMsg:(NSString *)sessionUserName MsgWrap:(CMessageWrap *)wrap;
@end

@interface CContactMgr : NSObject
- (void)printContactImportantChangeData:(id)newContact oldContact:(id)oldContact;
@end

@interface WCDeviceStepObject : NSObject
- (unsigned int)m7StepCount;
- (unsigned int)hkStepCount;
- (void)setM7StepCount:(unsigned int)value;
- (void)setHkStepCount:(unsigned int)value;
@end

@interface UploadDeviceStepReq : NSObject
- (unsigned int)stepCount;
- (unsigned int)m7StepCount;
- (unsigned int)hkStepCount;
- (void)setStepCount:(unsigned int)value;
- (void)setM7StepCount:(unsigned int)value;
- (void)setHkStepCount:(unsigned int)value;
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
static NSTimeInterval NeoWCVoiceRepeatForwardDeadline = 0;
static char NeoWCDeviceCardDidConfirmKey;
static char NeoWCGameDidAuthorizeKey;
static char NeoWCMomentsDoubleTapRecognizerKey;
static char NeoWCMomentsForwardButtonKey;
static char NeoWCMomentsOriginalOperateFrameKey;
static char NeoWCMomentsFloatForwardButtonKey;
static char NeoWCMomentsFloatSeparatorKey;
static char NeoWCMomentsFloatDataItemKey;
static char NeoWCMomentsFloatSnapshotKey;
static char NeoWCMomentsForwardTaskKey;
static char NeoWCImageJokerPickerDelegateKey;
static char NeoWCEmoticonPreviewLongPressKey;
static char NeoWCMomentsOriginalTimeTextKey;
static char NeoWCMomentsOriginalTimeLinesKey;
static char NeoWCMomentsPreciseTimeAppliedKey;
static id NeoWCPendingMomentsPermissionDataItem;
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
static char NeoWCReplyPanRecognizerKey;
static char NeoWCReplyPanDelegateKey;
static char NeoWCMessageDoubleTapRecognizerKey;
static char NeoWCMessageTripleTapRecognizerKey;
static char NeoWCReplyOriginalTransformKey;
static char NeoWCReplyFeedbackGeneratorKey;
static char NeoWCReplyFeedbackTriggeredKey;
static char NeoWCReplyPanRightwardKey;
static char NeoWCSeparatorOriginalHiddenKey;
static char NeoWCVoiceTranscriptionScheduledKey;
static char NeoWCVoiceTranscriptionDoneKey;
static char NeoWCVoiceTranscriptionInProgressKey;
static char NeoWCVoiceTranscriptionAttemptedKey;
static char NeoWCChatTopProfileItemKey;
static char NeoWCChatTopCapsuleItemKey;
static char NeoWCChatTopOriginalLeftItemsKey;
static char NeoWCChatTopOriginalRightItemsKey;
static char NeoWCChatTopOriginalTitleViewKey;
static char NeoWCChatTopOriginalSupplementKey;
static char NeoWCChatTopMoreProxyKey;
static char NeoWCChatTopBackProxyKey;
static char NeoWCChatTopOriginalStandardAppearanceKey;
static char NeoWCChatTopOriginalCompactAppearanceKey;
static char NeoWCChatTopOriginalScrollEdgeAppearanceKey;
static char NeoWCChatTopOriginalCompactScrollEdgeAppearanceKey;
static char NeoWCChatTopBackgroundOriginalAlphaKey;
static char NeoWCChatTopPlaceholderTitleViewKey;
static char NeoWCChatTopOriginalNavigationStandardAppearanceKey;
static char NeoWCChatTopOriginalNavigationCompactAppearanceKey;
static char NeoWCChatTopOriginalNavigationScrollEdgeAppearanceKey;
static char NeoWCChatTopOriginalNavigationCompactScrollEdgeAppearanceKey;
static char NeoWCChatTopOriginalNavigationTranslucentKey;
static char NeoWCChatTopOriginalEdgesForExtendedLayoutKey;
static char NeoWCChatTopOriginalExtendedLayoutIncludesOpaqueBarsKey;
static char NeoWCChatTopContainerOriginalBackgroundColorKey;
static char NeoWCChatTopBackgroundOriginalHiddenKey;
static char NeoWCChatTopGlassEffectMarkerKey;
static char NeoWCChatTopGlassEffectAnimatorKey;
static char NeoWCChatTopTypingActiveKey;
static char NeoWCChatTopStableDisplayNameKey;
static char NeoWCChatTypingStatusLabelMarkerKey;
static char NeoWCChatGlassAppliedStyleKey;
static char NeoWCChatTopOriginalClipsToBoundsKey;
static char NeoWCChatTopOriginalBorderWidthKey;
static char NeoWCChatTopOriginalCornerRadiusKey;
static char NeoWCChatTopContentNavigationBarKey;
static char NeoWCChatTopOriginalVisualEffectKey;
static char NeoWCChatTopOriginalVisualEffectMaskKey;
static char NeoWCChatTopOriginalBackgroundMaskKey;
static char NeoWCChatTopFadeBackgroundMaskKey;
static char NeoWCChatPinnedBlurViewKey;
static char NeoWCChatPinnedOriginalBackgroundColorKey;
static char NeoWCChatPinnedOriginalShadowOpacityKey;
static char NeoWCChatPinnedOriginalShadowRadiusKey;
static char NeoWCChatPinnedOriginalShadowOffsetKey;
static char NeoWCChatPinnedOriginalShadowColorKey;
static char NeoWCChatPinnedOriginalBorderWidthKey;
static char NeoWCChatPinnedOriginalBorderColorKey;
static char NeoWCRedEnvelopeOriginalAttributedTextKey;
static char NeoWCCallVoiceConfirmedKey;
static char NeoWCCallVideoConfirmedKey;
static __weak BaseMsgContentViewController *NeoWCVisibleChatController;
static __weak id NeoWCCurrentEditImageLogicController;
static BOOL NeoWCMomentsDispatchingQuickComment = NO;

static void NeoWCUpdateChatTopBar(BaseMsgContentViewController *controller);
static void NeoWCRefreshChatTopBarAfterWechatUpdate(BaseMsgContentViewController *controller);
static void NeoWCUpdatePinnedMessageGlass(UIView *tipsView);
static BaseMsgContentViewController *NeoWCResolveVisibleChatController(void);

@interface NeoWCBarButtonActionProxy : NSObject
@property (nonatomic, strong) UIBarButtonItem *originalItem;
@property (nonatomic, weak) UIViewController *fallbackController;
@property (nonatomic, assign) BOOL popsNavigationController;
- (void)invoke:(id)sender;
@end

static id NeoWCTweakSafeValue(id object, NSString *key);
static void NeoWCTweakSetValue(id object, NSString *key, id value);
static id NeoWCMessageWrapForCell(id cell);
static id NeoWCContactForUserName(NSString *userName);

static BOOL NeoWCMessageCellIsSender(CommonMessageCellView *cell) {
    if (!cell) return NO;
    id viewModel = NeoWCTweakSafeValue(cell, @"viewModel") ?: NeoWCTweakSafeValue(cell, @"m_viewModel");
    id senderValue = NeoWCTweakSafeValue(viewModel, @"isSender");
    if ([senderValue respondsToSelector:@selector(boolValue)] && [senderValue boolValue]) return YES;
    id message = NeoWCMessageWrapForCell(cell);
    senderValue = NeoWCTweakSafeValue(message, @"isSender");
    if ([senderValue respondsToSelector:@selector(boolValue)] && [senderValue boolValue]) return YES;
    NSString *fromUser = NeoWCTweakSafeValue(message, @"m_nsFromUsr");
    NSString *currentUser = NeoWCCurrentUserWXID();
    return fromUser.length > 0 && currentUser.length > 0 && [fromUser isEqualToString:currentUser];
}

static NeoWCReplySwipeAction NeoWCMessageGestureAction(CommonMessageCellView *cell,
                                                        NSString *selfKey,
                                                        NSString *otherKey) {
    BOOL selfMessage = NeoWCMessageCellIsSender(cell);
    NSInteger action = [[NSUserDefaults standardUserDefaults] integerForKey:selfMessage ? selfKey : otherKey];
    if (action < NeoWCReplySwipeActionNone || action > NeoWCReplySwipeActionRepeat) return NeoWCReplySwipeActionNone;
    if (!selfMessage && action == NeoWCReplySwipeActionRevoke) return NeoWCReplySwipeActionNone;
    return (NeoWCReplySwipeAction)action;
}

static NeoWCReplySwipeAction NeoWCMessageSwipeAction(CommonMessageCellView *cell, BOOL rightward) {
    return NeoWCMessageGestureAction(cell,
                                     rightward ? NeoWCReplySwipeRightSelfActionKey : NeoWCReplySwipeSelfActionKey,
                                     rightward ? NeoWCReplySwipeRightOtherActionKey : NeoWCReplySwipeOtherActionKey);
}

static CGFloat NeoWCReplySwipeTriggerDistance(void) {
    CGFloat value = [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCReplySwipeTriggerDistanceKey];
    if (value <= 0.0) value = 56.0;
    return MIN(100.0, MAX(36.0, value));
}

static UIControl *NeoWCFirstControlInView(UIView *view) {
    if (!view) return nil;
    id button = NeoWCTweakSafeValue(view, @"m_btn");
    if ([button isKindOfClass:[UIControl class]]) return button;
    for (UIView *subview in view.subviews) {
        UIControl *control = NeoWCFirstControlInView(subview);
        if (control) return control;
    }
    return [view isKindOfClass:[UIControl class]] ? (UIControl *)view : nil;
}

@implementation NeoWCBarButtonActionProxy

- (void)invoke:(id)sender {
    UIBarButtonItem *item = self.originalItem;
    if (!item) {
        if (self.popsNavigationController) {
            [self.fallbackController.navigationController popViewControllerAnimated:YES];
        }
        return;
    }
    UIControl *control = NeoWCFirstControlInView(item.customView);
    if (control) {
        [control sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }
    if (item.action &&
        [UIApplication.sharedApplication sendAction:item.action to:item.target from:item forEvent:nil]) {
        return;
    }
    if (self.popsNavigationController) {
        [self.fallbackController.navigationController popViewControllerAnimated:YES];
    }
    (void)sender;
}

@end

@interface NeoWCMomentsFloatMenuSnapshot : NSObject
@property (nonatomic, assign) CGRect baseFrame;
@property (nonatomic, assign) CGFloat addedWidth;
@property (nonatomic, strong) UIView *container;
@property (nonatomic, assign) CGRect baseContainerFrame;
@property (nonatomic, assign) BOOL containerIsDirectChild;
@property (nonatomic, copy) NSArray<UIView *> *baseViews;
@property (nonatomic, copy) NSArray<NSValue *> *baseFrames;
@property (nonatomic, strong) CALayer *originalLayerMask;
@property (nonatomic, strong) CAShapeLayer *expandedLayerMask;
@property (nonatomic, assign) CGRect forwardFrame;
@property (nonatomic, assign) CGRect separatorFrame;
@property (nonatomic, assign) BOOL applying;
@end

@implementation NeoWCMomentsFloatMenuSnapshot
@end

static UIViewController *NeoWCViewControllerForResponder(id responderObject) {
    UIResponder *responder = [responderObject isKindOfClass:[UIResponder class]] ? (UIResponder *)responderObject : nil;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) return (UIViewController *)responder;
        responder = responder.nextResponder;
    }
    return nil;
}

@interface NeoWCReplyPanGestureDelegate : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIView *cell;
@end

@implementation NeoWCReplyPanGestureDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer {
    if (!NeoWCEnhancementEnabled(NeoWCReplySwipeEnabledKey) ||
        !self.cell.window ||
        ![recognizer isKindOfClass:[UIPanGestureRecognizer class]]) return NO;
    UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)recognizer;
    CGPoint velocity = [pan velocityInView:self.cell];
    if (fabs(velocity.x) <= fabs(velocity.y)) return NO;
    if (NeoWCMessageSwipeAction((CommonMessageCellView *)self.cell, velocity.x > 0.0) == NeoWCReplySwipeActionNone) return NO;
    CGPoint location = [pan locationInView:self.cell];
    CGFloat width = CGRectGetWidth(self.cell.bounds);
    // Preserve the native interactive-pop edge. A rightward message action must
    // start farther inside the chat so returning cannot accidentally trigger it.
    CGFloat minimumX = velocity.x > 0.0 ? 44.0 : 24.0;
    return location.x >= minimumX && location.x <= MAX(minimumX, width - 24.0);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    (void)gestureRecognizer;
    (void)otherGestureRecognizer;
    return NO;
}

@end

static void NeoWCSynchronizeReplyGesture(CommonMessageCellView *cell) {
    if (!cell) return;
    UIPanGestureRecognizer *panRecognizer = objc_getAssociatedObject(cell, &NeoWCReplyPanRecognizerKey);
    UITapGestureRecognizer *doubleRecognizer = objc_getAssociatedObject(cell, &NeoWCMessageDoubleTapRecognizerKey);
    UITapGestureRecognizer *tripleRecognizer = objc_getAssociatedObject(cell, &NeoWCMessageTripleTapRecognizerKey);
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCReplySwipeEnabledKey) && cell.window;
    NeoWCReplySwipeAction leftSwipeAction = enabled ? NeoWCMessageSwipeAction(cell, NO) : NeoWCReplySwipeActionNone;
    NeoWCReplySwipeAction rightSwipeAction = enabled ? NeoWCMessageSwipeAction(cell, YES) : NeoWCReplySwipeActionNone;
    BOOL hasSwipeAction = leftSwipeAction != NeoWCReplySwipeActionNone || rightSwipeAction != NeoWCReplySwipeActionNone;
    NeoWCReplySwipeAction doubleAction = enabled
        ? NeoWCMessageGestureAction(cell, NeoWCMessageDoubleTapSelfActionKey, NeoWCMessageDoubleTapOtherActionKey)
        : NeoWCReplySwipeActionNone;
    NeoWCReplySwipeAction tripleAction = enabled
        ? NeoWCMessageGestureAction(cell, NeoWCMessageTripleTapSelfActionKey, NeoWCMessageTripleTapOtherActionKey)
        : NeoWCReplySwipeActionNone;

    if (!hasSwipeAction) {
        if (panRecognizer) {
            NSValue *originalTransform = objc_getAssociatedObject(cell, &NeoWCReplyOriginalTransformKey);
            if (originalTransform) cell.transform = originalTransform.CGAffineTransformValue;
            [cell removeGestureRecognizer:panRecognizer];
        }
        objc_setAssociatedObject(cell, &NeoWCReplyPanRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCReplyPanDelegateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCReplyOriginalTransformKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCReplyFeedbackGeneratorKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCReplyFeedbackTriggeredKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCReplyPanRightwardKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        panRecognizer = nil;
    }
    if (!panRecognizer && hasSwipeAction) {
        NeoWCReplyPanGestureDelegate *delegate = [NeoWCReplyPanGestureDelegate new];
        delegate.cell = cell;
        panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:cell action:@selector(neowc_handleReplyPan:)];
        panRecognizer.delegate = delegate;
        panRecognizer.maximumNumberOfTouches = 1;
        panRecognizer.cancelsTouchesInView = YES;
        panRecognizer.delaysTouchesBegan = NO;
        panRecognizer.delaysTouchesEnded = NO;
        [cell addGestureRecognizer:panRecognizer];
        UIViewController *controller = NeoWCViewControllerForResponder(cell);
        UIGestureRecognizer *popGesture = controller.navigationController.interactivePopGestureRecognizer;
        if (popGesture && popGesture != panRecognizer) {
            [panRecognizer requireGestureRecognizerToFail:popGesture];
        }
        objc_setAssociatedObject(cell, &NeoWCReplyPanRecognizerKey, panRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCReplyPanDelegateKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (doubleAction == NeoWCReplySwipeActionNone && doubleRecognizer) {
        [cell removeGestureRecognizer:doubleRecognizer];
        objc_setAssociatedObject(cell, &NeoWCMessageDoubleTapRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        doubleRecognizer = nil;
    }
    if (tripleAction == NeoWCReplySwipeActionNone && tripleRecognizer) {
        [cell removeGestureRecognizer:tripleRecognizer];
        objc_setAssociatedObject(cell, &NeoWCMessageTripleTapRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        tripleRecognizer = nil;
        // Recreate double tap so it no longer retains a failure dependency on the removed triple tap.
        if (doubleRecognizer) {
            [cell removeGestureRecognizer:doubleRecognizer];
            objc_setAssociatedObject(cell, &NeoWCMessageDoubleTapRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            doubleRecognizer = nil;
        }
    }
    if (!doubleRecognizer && doubleAction != NeoWCReplySwipeActionNone) {
        doubleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:cell action:@selector(neowc_handleMessageTapAction:)];
        doubleRecognizer.numberOfTapsRequired = 2;
        doubleRecognizer.numberOfTouchesRequired = 1;
        doubleRecognizer.cancelsTouchesInView = YES;
        [cell addGestureRecognizer:doubleRecognizer];
        objc_setAssociatedObject(cell, &NeoWCMessageDoubleTapRecognizerKey, doubleRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (!tripleRecognizer && tripleAction != NeoWCReplySwipeActionNone) {
        tripleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:cell action:@selector(neowc_handleMessageTapAction:)];
        tripleRecognizer.numberOfTapsRequired = 3;
        tripleRecognizer.numberOfTouchesRequired = 1;
        tripleRecognizer.cancelsTouchesInView = YES;
        [cell addGestureRecognizer:tripleRecognizer];
        objc_setAssociatedObject(cell, &NeoWCMessageTripleTapRecognizerKey, tripleRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (doubleRecognizer && tripleRecognizer) [doubleRecognizer requireGestureRecognizerToFail:tripleRecognizer];
}

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

static BOOL NeoWCInvokeFirstMessageCellAction(CommonMessageCellView *cell, NSArray<NSString *> *selectorNames) {
    for (NSString *selectorName in selectorNames) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![cell respondsToSelector:selector]) continue;
        ((void (*)(id, SEL, id))objc_msgSend)(cell, selector, nil);
        return YES;
    }
    return NO;
}

@interface NeoWCMessageRepeatSession : NSObject
@property (nonatomic, strong) id forwardLogic;
@property (nonatomic, strong) id message;
@property (nonatomic, strong) id contact;
@property (nonatomic, weak) UIViewController *presenter;
@property (nonatomic, assign) BOOL finished;
- (void)finishSession;
@end

@implementation NeoWCMessageRepeatSession

- (void)finishSession {
    if (self.finished) return;
    self.finished = YES;
    [NeoWCActiveQuickSendSessions() removeObject:self];
    self.forwardLogic = nil;
    self.message = nil;
    self.contact = nil;
    self.presenter = nil;
}

- (UIViewController *)getCurrentViewController { return self.presenter; }
- (UIViewController *)GetCurrentViewController { return self.presenter; }
- (void)OnForwardMessageSend:(__unused id)logic { [self finishSession]; }
- (void)OnForwardMessageCancel:(__unused id)logic { [self finishSession]; }
- (void)OnForwardMessageConfirmCanceled:(id)logic { [self OnForwardMessageCancel:logic]; }
- (void)OnForwardDone { [self finishSession]; }

@end

static id NeoWCMessageManager(void) {
    Class centerClass = objc_getClass("MMServiceCenter");
    Class managerClass = objc_getClass("CMessageMgr");
    SEL centerSelector = sel_registerName("defaultCenter");
    SEL serviceSelector = sel_registerName("getService:");
    if (!centerClass || !managerClass || ![centerClass respondsToSelector:centerSelector]) return nil;
    id center = ((id (*)(id, SEL))objc_msgSend)(centerClass, centerSelector);
    if (![center respondsToSelector:serviceSelector]) return nil;
    return ((id (*)(id, SEL, Class))objc_msgSend)(center, serviceSelector, managerClass);
}

static NSString *NeoWCSessionForMessage(id message) {
    SEL selector = NSSelectorFromString(@"GetChatName");
    if ([message respondsToSelector:selector]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(message, selector);
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    NSString *fromUser = NeoWCTweakSafeValue(message, @"m_nsFromUsr");
    NSString *toUser = NeoWCTweakSafeValue(message, @"m_nsToUsr");
    NSString *currentUser = NeoWCCurrentUserWXID();
    if ([fromUser hasSuffix:@"@chatroom"]) return fromUser;
    if ([toUser hasSuffix:@"@chatroom"]) return toUser;
    if (currentUser.length > 0 && [fromUser isEqualToString:currentUser]) return toUser;
    return fromUser.length > 0 ? fromUser : toUser;
}

static BOOL NeoWCRepeatPlainTextMessageFallback(CommonMessageCellView *cell) {
    id source = NeoWCMessageWrapForCell(cell);
    NSInteger messageType = [NeoWCTweakSafeValue(source, @"m_uiMessageType") integerValue];
    NSString *content = NeoWCTweakSafeValue(source, @"m_nsContent");
    NSString *session = NeoWCSessionForMessage(source);
    if (messageType != 1 || content.length == 0 || session.length == 0) return NO;

    Class wrapClass = objc_getClass("CMessageWrap");
    SEL initSelector = sel_registerName("initWithMsgType:");
    if (!wrapClass || ![wrapClass instancesRespondToSelector:initSelector]) return NO;
    id repeated = ((id (*)(id, SEL, NSUInteger))objc_msgSend)([wrapClass alloc], initSelector, 1);
    if (!repeated) return NO;
    NeoWCTweakSetValue(repeated, @"m_nsFromUsr", NeoWCCurrentUserWXID() ?: @"");
    NeoWCTweakSetValue(repeated, @"m_nsToUsr", session);
    NeoWCTweakSetValue(repeated, @"m_nsContent", content);
    NeoWCTweakSetValue(repeated, @"m_uiStatus", @1);
    NeoWCTweakSetValue(repeated, @"m_uiCreateTime", @((NSUInteger)NSDate.date.timeIntervalSince1970));

    id manager = NeoWCMessageManager();
    SEL sendSelector = sel_registerName("AddMsg:MsgWrap:");
    if (!manager || ![manager respondsToSelector:sendSelector]) return NO;
    ((void (*)(id, SEL, NSString *, id))objc_msgSend)(manager, sendSelector, session, repeated);
    return YES;
}

static BOOL NeoWCVoiceRepeatUploadIsActive(void) {
    return NeoWCVoiceRepeatForwardDeadline > NSDate.date.timeIntervalSince1970;
}

static BOOL NeoWCRepeatVoiceMessage(id source, NSString *session) {
    if (!source || session.length == 0) return NO;

    id manager = NeoWCMessageManager();
    SEL voicePathSelector = sel_registerName("getVoicePath");
    SEL destinationPathSelector = sel_registerName("getPathOfAudio:");
    SEL addLocalSelector = sel_registerName("AddLocalMsg:MsgWrap:");
    SEL saveVoiceSelector = sel_registerName("SaveMesVoice:MsgWrap:");
    SEL resendSelector = sel_registerName("ResendVoiceMsg:MsgWrap:");
    SEL uploaderSelector = sel_registerName("uploaderForMsgWrap:");
    Class messageWrapClass = objc_getClass("CMessageWrap");
    Class audioSenderClass = objc_getClass("AudioSender");
    id audioSender = audioSenderClass ? NeoWCServiceForClass(audioSenderClass) : nil;
    if (![source respondsToSelector:voicePathSelector] ||
        !manager ||
        ![manager respondsToSelector:addLocalSelector] ||
        !messageWrapClass ||
        ![messageWrapClass respondsToSelector:destinationPathSelector] ||
        !audioSender) {
        NeoWCLog(@"语音复读入口不完整，取消发送");
        return NO;
    }

    NSString *sourcePath = ((id (*)(id, SEL))objc_msgSend)(source, voicePathSelector);
    if (![sourcePath isKindOfClass:[NSString class]] || sourcePath.length == 0 ||
        ![[NSFileManager defaultManager] fileExistsAtPath:sourcePath]) {
        NeoWCLog(@"语音复读找不到本地语音文件");
        return NO;
    }

    id repeated = nil;
    @try {
        repeated = [source copy];
        if (!repeated) return NO;

        NeoWCTweakSetValue(repeated, @"m_uiMesLocalID", @0);
        NeoWCTweakSetValue(repeated, @"m_n64MesSvrID", @0);
        SEL resetLocalIDSelector = sel_registerName("resetLocalId");
        if ([repeated respondsToSelector:resetLocalIDSelector]) {
            ((void (*)(id, SEL))objc_msgSend)(repeated, resetLocalIDSelector);
        }

        NSString *currentUser = NeoWCCurrentUserWXID() ?: @"";
        NSUInteger now = (NSUInteger)NSDate.date.timeIntervalSince1970;
        NeoWCTweakSetValue(repeated, @"m_nsFromUsr", currentUser);
        NeoWCTweakSetValue(repeated, @"m_nsRealChatUsr", currentUser);
        NeoWCTweakSetValue(repeated, @"m_nsToUsr", session);
        NeoWCTweakSetValue(repeated, @"m_uiCreateTime", @(now));
        NeoWCTweakSetValue(repeated, @"m_uiSendTime", @(now));
        NeoWCTweakSetValue(repeated, @"m_uiStatus", @1);
        NeoWCTweakSetValue(repeated, @"m_uiVoiceForwardFlag", @1);
        id extendInfo = NeoWCTweakSafeValue(repeated, @"m_extendInfoWithMsgType");
        NeoWCTweakSetValue(extendInfo, @"m_uiVoiceForwardFlag", @1);

        // AddLocalMsg assigns the new local message ID. WeChat derives the
        // audio destination path from that ID, so this must happen first.
        ((void (*)(id, SEL, id, id))objc_msgSend)(manager, addLocalSelector, session, repeated);

        NSString *destinationPath = ((id (*)(id, SEL, id))objc_msgSend)(messageWrapClass,
                                                                        destinationPathSelector,
                                                                        repeated);
        if (![destinationPath isKindOfClass:[NSString class]] || destinationPath.length == 0) {
            NeoWCLog(@"语音复读无法生成目标文件路径");
            return NO;
        }

        BOOL voiceSaved = [sourcePath isEqualToString:destinationPath];
        if (!voiceSaved) {
            NSError *copyError = nil;
            voiceSaved = [[NSFileManager defaultManager] copyItemAtPath:sourcePath
                                                                 toPath:destinationPath
                                                                  error:&copyError];
            if (!voiceSaved && [manager respondsToSelector:saveVoiceSelector]) {
                NSData *voiceData = [NSData dataWithContentsOfFile:sourcePath];
                if (voiceData.length > 0) {
                    ((void (*)(id, SEL, id, id))objc_msgSend)(manager,
                                                              saveVoiceSelector,
                                                              voiceData,
                                                              repeated);
                    voiceSaved = YES;
                }
            }
            if (!voiceSaved) {
                NeoWCLog(@"语音复读保存语音失败：%@", copyError.localizedDescription ?: @"未知错误");
                return NO;
            }
        }

        id resendTarget = audioSender;
        if (![resendTarget respondsToSelector:resendSelector] &&
            [audioSender respondsToSelector:uploaderSelector]) {
            resendTarget = ((id (*)(id, SEL, id))objc_msgSend)(audioSender, uploaderSelector, repeated);
        }
        if (![resendTarget respondsToSelector:resendSelector]) {
            NeoWCLog(@"语音复读找不到微信语音上传入口");
            return NO;
        }
        // WeChatX keeps the native upload pipeline in forwarding mode for a
        // short, repeat-scoped window. The setter hooks below never affect
        // ordinary voice recording or forwarding outside this window.
        NeoWCVoiceRepeatForwardDeadline = NSDate.date.timeIntervalSince1970 + 60.0;
        ((void (*)(id, SEL, id, id))objc_msgSend)(resendTarget, resendSelector, session, repeated);
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"语音复读调用失败：%@", exception.reason ?: exception.name);
        return NO;
    }
}

static BOOL NeoWCRepeatMessage(CommonMessageCellView *cell) {
    id source = NeoWCMessageWrapForCell(cell);
    NSString *chatName = NeoWCSessionForMessage(source);
    NSInteger messageType = [NeoWCTweakSafeValue(source, @"m_uiMessageType") integerValue];
    if (messageType == 34) return NeoWCRepeatVoiceMessage(source, chatName);
    id contact = NeoWCContactForUserName(chatName);
    Class forwardClass = objc_getClass("ForwardMessageLogicController");
    SEL forwardSelector = sel_registerName("forwardNoConfirmForMsgList:toContacts:");
    SEL delegateSelector = sel_registerName("setDelegate:");
    if (source && contact && forwardClass) {
        BOOL canForward = YES;
        Class utilityClass = objc_getClass("ForwardMsgUtil");
        SEL canForwardSelector = sel_registerName("canBeForwardWithMsg:");
        if ([utilityClass respondsToSelector:canForwardSelector]) {
            canForward = ((BOOL (*)(id, SEL, id))objc_msgSend)(utilityClass, canForwardSelector, source);
        }
        id logic = canForward ? [forwardClass new] : nil;
        if (logic && [logic respondsToSelector:forwardSelector] && [logic respondsToSelector:delegateSelector]) {
            NeoWCMessageRepeatSession *repeatSession = [NeoWCMessageRepeatSession new];
            repeatSession.forwardLogic = logic;
            repeatSession.message = source;
            repeatSession.contact = contact;
            repeatSession.presenter = NeoWCVisibleChatController;
            ((void (*)(id, SEL, id))objc_msgSend)(logic, delegateSelector, repeatSession);
            [NeoWCActiveQuickSendSessions() addObject:repeatSession];
            @try {
                ((void (*)(id, SEL, id, id))objc_msgSend)(logic, forwardSelector, @[source], @[contact]);
            } @catch (NSException *exception) {
                NeoWCLog(@"复读调用微信转发引擎失败：%@", exception.reason ?: exception.name);
                [repeatSession finishSession];
                return NeoWCRepeatPlainTextMessageFallback(cell);
            }
            __weak NeoWCMessageRepeatSession *weakSession = repeatSession;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60.0 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                NeoWCMessageRepeatSession *activeSession = weakSession;
                if (activeSession && !activeSession.finished) [activeSession finishSession];
            });
            return YES;
        }
    }
    return NeoWCRepeatPlainTextMessageFallback(cell);
}

static BOOL NeoWCPerformMessageGestureAction(CommonMessageCellView *cell, NeoWCReplySwipeAction action) {
    if (!cell.window || action == NeoWCReplySwipeActionNone) return NO;
    BOOL performed = NO;
    switch (action) {
        case NeoWCReplySwipeActionQuote:
            performed = NeoWCInvokeFirstMessageCellAction(cell, @[@"onShowMsgReplyMenuItem:"]);
            break;
        case NeoWCReplySwipeActionRevoke:
            if (!NeoWCMessageCellIsSender(cell)) return NO;
            performed = NeoWCInvokeFirstMessageCellAction(cell, @[@"onRevokeMsg:"]);
            break;
        case NeoWCReplySwipeActionCopy:
            performed = NeoWCInvokeFirstMessageCellAction(cell, @[@"onCopy:"]);
            if (!performed) {
                NSString *content = NeoWCTweakSafeValue(NeoWCMessageWrapForCell(cell), @"m_nsContent");
                if (content.length > 0) {
                    UIPasteboard.generalPasteboard.string = content;
                    performed = YES;
                }
            }
            break;
        case NeoWCReplySwipeActionDelete:
            performed = NeoWCInvokeFirstMessageCellAction(cell, @[@"onDelete:", @"onDeleteMessage:"]);
            break;
        case NeoWCReplySwipeActionRepeat:
            performed = NeoWCRepeatMessage(cell);
            break;
        case NeoWCReplySwipeActionNone:
            break;
    }
    if (performed) NeoWCCompatibilityMarkTriggered(@"reply-swipe");
    else NeoWCLog(@"消息手势动作不可用，action=%ld cell=%@", (long)action, NSStringFromClass(cell.class));
    return performed;
}

static unsigned int NeoWCGradualStepCountForTarget(NSInteger target, NSDate *date) {
    NSDateComponents *components = [[NSCalendar currentCalendar]
        components:(NSCalendarUnitHour | NSCalendarUnitMinute)
          fromDate:date];
    NSInteger minuteOfDay = components.hour * 60 + components.minute;
    static const NSInteger stageMinutes[] = {
        0,          // 凌晨保留少量基础步数
        7 * 60,     // 07:00
        9 * 60 + 30,// 09:30
        12 * 60,    // 12:00
        14 * 60 + 30,// 14:30
        16 * 60 + 30,// 16:30
        18 * 60 + 30,// 18:30，19:00 前完成目标
    };
    static const CGFloat stageProgress[] = {0.02, 0.15, 0.32, 0.50, 0.66, 0.82, 1.0};
    CGFloat fraction = stageProgress[0];
    for (NSUInteger index = 1; index < sizeof(stageMinutes) / sizeof(stageMinutes[0]); index++) {
        if (minuteOfDay < stageMinutes[index]) break;
        fraction = stageProgress[index];
    }
    NSInteger value = (NSInteger)floor(target * fraction);
    return (unsigned int)MIN(100000, MAX(1, value));
}

static unsigned int NeoWCConfiguredDailyStepCount(void) {
    if (!NeoWCEnhancementEnabled(NeoWCStepOverrideEnabledKey)) return 0;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NeoWCStepMode mode = (NeoWCStepMode)[defaults integerForKey:NeoWCStepModeKey];
    if (mode != NeoWCStepModeDailyRandom) mode = NeoWCStepModeDailyFixed;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSInteger dailyTarget = 0;
    @synchronized (defaults) {
        NSDate *configuredDate = [defaults objectForKey:NeoWCStepCountDateKey];
        dailyTarget = [defaults integerForKey:NeoWCStepDailyTargetKey];
        BOOL targetIsCurrent = [configuredDate isKindOfClass:[NSDate class]] &&
                               [calendar isDateInToday:configuredDate] && dailyTarget > 0;
        if (!targetIsCurrent) {
            if (mode == NeoWCStepModeDailyRandom) {
                NSInteger minimum = MIN(100000, MAX(1, [defaults integerForKey:NeoWCStepRandomMinimumKey]));
                NSInteger maximum = MIN(100000, MAX(minimum, [defaults integerForKey:NeoWCStepRandomMaximumKey]));
                dailyTarget = minimum + (NSInteger)arc4random_uniform((uint32_t)(maximum - minimum + 1));
            } else {
                dailyTarget = MIN(100000, MAX(0, [defaults integerForKey:NeoWCStepCountKey]));
            }
            if (dailyTarget > 0) {
                [defaults setInteger:dailyTarget forKey:NeoWCStepDailyTargetKey];
                [defaults setObject:now forKey:NeoWCStepCountDateKey];
            }
        }
    }
    if (dailyTarget <= 0) return 0;
    if ([defaults boolForKey:NeoWCStepGradualEnabledKey]) {
        return NeoWCGradualStepCountForTarget(dailyTarget, now);
    }
    return (unsigned int)MIN(100000, dailyTarget);
}

static CGFloat NeoWCGlobalPageScaleFactor(void) {
    return NeoWCScalePercentForDefaultsKey(NeoWCPageScaleGlobalPercentKey, 100.0) / 100.0;
}

static BOOL NeoWCThemeValueShouldScale(id property, id ruleSet) {
    if (!NeoWCEnhancementEnabled(NeoWCPageScaleEnabledKey) ||
        ![property isKindOfClass:[NSString class]] ||
        ![ruleSet isKindOfClass:[NSString class]]) return NO;
    if (![(NSString *)ruleSet isEqualToString:@"#font_set"]) return NO;
    return [(NSString *)property isEqualToString:@"alllevel"] ||
           [(NSString *)property isEqualToString:@"chatLevel"];
}

static id NeoWCScaledThemeValue(id originalValue, id property, id ruleSet) {
    if (!NeoWCThemeValueShouldScale(property, ruleSet) ||
        ![originalValue isKindOfClass:[NSArray class]] ||
        [(NSArray *)originalValue count] == 0) return originalValue;
    id firstValue = [(NSArray *)originalValue firstObject];
    id scaledValue = nil;
    CGFloat scale = NeoWCGlobalPageScaleFactor();
    if ([firstValue isKindOfClass:[NSNumber class]]) {
        scaledValue = @([(NSNumber *)firstValue doubleValue] * scale);
    } else if ([firstValue isKindOfClass:[NSString class]]) {
        NSScanner *scanner = [NSScanner scannerWithString:firstValue];
        double ignored = 0.0;
        if (![scanner scanDouble:&ignored] || !scanner.isAtEnd) return originalValue;
        NSDecimalNumber *value = [NSDecimalNumber decimalNumberWithString:firstValue];
        NSDecimalNumber *factor = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", scale]];
        NSDecimalNumber *result = [value decimalNumberByMultiplyingBy:factor];
        if (![result isEqualToNumber:[NSDecimalNumber notANumber]]) scaledValue = result.stringValue;
    }
    if (!scaledValue) return originalValue;
    NSMutableArray *values = [(NSArray *)originalValue mutableCopy];
    values[0] = scaledValue;
    NeoWCCompatibilityMarkTriggered(@"page-scale");
    return values;
}

static void NeoWCApplyWebViewTextScale(id webView) {
    if (!NeoWCEnhancementEnabled(NeoWCPageScaleEnabledKey) || !webView) return;
    SEL selector = NSSelectorFromString(@"_setTextZoomFactor:");
    if (![webView respondsToSelector:selector]) return;
    ((void (*)(id, SEL, CGFloat))objc_msgSend)(webView, selector, NeoWCGlobalPageScaleFactor());
    NeoWCCompatibilityMarkTriggered(@"page-scale");
}

static NSString *NeoWCMomentsUserNameForDataItem(id dataItem) {
    SEL selector = NSSelectorFromString(@"username");
    if (!dataItem || ![dataItem respondsToSelector:selector]) return nil;
    @try {
        id value = ((id (*)(id, SEL))objc_msgSend)(dataItem, selector);
        return [value isKindOfClass:[NSString class]] ? value : nil;
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static NSMutableDictionary<NSString *, id> *NeoWCMomentsPermissionsControllerCache(void) {
    static NSMutableDictionary<NSString *, id> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ cache = [NSMutableDictionary dictionary]; });
    return cache;
}

static id NeoWCMomentsPermissionsController(NSString *userName, id delegate) {
    if (userName.length == 0) return nil;
    Class controllerClass = NSClassFromString(@"WCSetPermissionsViewController");
    SEL initSelector = NSSelectorFromString(@"initWithUserName:");
    SEL viewSelector = NSSelectorFromString(@"view");
    SEL delegateSelector = NSSelectorFromString(@"setDelegate:");
    SEL viewDelegateSelector = NSSelectorFromString(@"setViewDelegate:");
    if (!controllerClass || ![controllerClass instancesRespondToSelector:initSelector]) return nil;

    id controller = nil;
    @try {
        id allocated = [controllerClass alloc];
        controller = ((id (*)(id, SEL, id))objc_msgSend)(allocated, initSelector, userName);
        if (!controller ||
            ![controller respondsToSelector:viewSelector] ||
            ![controller respondsToSelector:delegateSelector] ||
            ![controller respondsToSelector:viewDelegateSelector]) return nil;
        (void)((id (*)(id, SEL))objc_msgSend)(controller, viewSelector);
        ((void (*)(id, SEL, id))objc_msgSend)(controller, delegateSelector, delegate);
        ((void (*)(id, SEL, id))objc_msgSend)(controller, viewDelegateSelector, delegate);
    } @catch (__unused NSException *exception) {
        return nil;
    }

    NSMutableDictionary<NSString *, id> *cache = NeoWCMomentsPermissionsControllerCache();
    cache[userName] = controller;
    NSString *cacheKey = [userName copy];
    __weak id weakController = controller;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id strongController = weakController;
        if (strongController && cache[cacheKey] == strongController) [cache removeObjectForKey:cacheKey];
    });
    return controller;
}

static NSString *NeoWCMomentsCheckedPermissionTitle(NSString *title, BOOL checked) {
    return checked ? [NSString stringWithFormat:@"✓ %@", title] : title;
}

static WCActionSheetItem *NeoWCMomentsPermissionItem(NSString *title,
                                                     BOOL enabled,
                                                     BOOL destructive,
                                                     void (^eventAction)(void)) {
    Class itemClass = NSClassFromString(@"WCActionSheetItem");
    if (!itemClass || title.length == 0 || !eventAction) return nil;
    id allocated = [itemClass alloc];
    SEL initSelector = NSSelectorFromString(@"initWithTitle:");
    if (![allocated respondsToSelector:initSelector]) return nil;
    WCActionSheetItem *item = [(WCActionSheetItem *)allocated initWithTitle:title];
    if (!item ||
        ![item respondsToSelector:@selector(setBEnable:)] ||
        ![item respondsToSelector:@selector(setBDestructiveButton:)] ||
        ![item respondsToSelector:@selector(setEventAction:)]) return nil;
    [item setBEnable:enabled];
    [item setBDestructiveButton:destructive];
    [item setEventAction:eventAction];
    return item;
}

static void NeoWCPerformMomentsPermissionAction(NSString *userName,
                                                id delegate,
                                                NSString *selectorName,
                                                NSNumber *switchState) {
    id controller = NeoWCMomentsPermissionsController(userName, delegate);
    SEL selector = NSSelectorFromString(selectorName);
    if (!controller || ![controller respondsToSelector:selector]) return;
    @try {
        if (switchState) {
            UISwitch *permissionSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            permissionSwitch.on = switchState.boolValue;
            ((void (*)(id, SEL, id))objc_msgSend)(controller, selector, permissionSwitch);
        } else {
            ((void (*)(id, SEL))objc_msgSend)(controller, selector);
        }
    } @catch (__unused NSException *exception) {
    }
}

static BOOL NeoWCConfigureMomentsPermissionsActionSheet(WCActionSheet *sheet, id dataItem) {
    if (!sheet || !dataItem || !NeoWCEnhancementEnabled(NeoWCMomentsQuickPermissionsKey)) return NO;
    NSArray *buttonTitleList = NeoWCTweakSafeValue(sheet, @"buttonTitleList");
    if (![buttonTitleList isKindOfClass:[NSArray class]] || buttonTitleList.count != 2) return NO;
    NSString *firstTitle = NeoWCTweakSafeValue(buttonTitleList.firstObject, @"title");
    NSString *lastTitle = NeoWCTweakSafeValue(buttonTitleList.lastObject, @"title");
    if ((! [firstTitle isEqualToString:@"设置权限"] && ![firstTitle isEqualToString:@"设置"]) ||
        ![lastTitle isEqualToString:@"投诉"]) return NO;

    NSString *userName = NeoWCMomentsUserNameForDataItem(dataItem);
    id delegate = NeoWCTweakSafeValue(sheet, @"delegate");
    id controller = NeoWCMomentsPermissionsController(userName, delegate);
    SEL contactSelector = NSSelectorFromString(@"m_contact");
    if (userName.length == 0 || !delegate || !controller || ![controller respondsToSelector:contactSelector]) return NO;
    id contact = ((id (*)(id, SEL))objc_msgSend)(controller, contactSelector);
    SEL onlyChatSelector = NSSelectorFromString(@"isSocialBlack");
    if (!contact || ![contact respondsToSelector:onlyChatSelector]) return NO;
    BOOL onlyChat = ((BOOL (*)(id, SEL))objc_msgSend)(contact, onlyChatSelector);

    SEL allSelector = NSSelectorFromString(@"opAllPermission");
    SEL onlyChatActionSelector = NSSelectorFromString(@"opSocialBlackPermission");
    SEL outsiderActionSelector = NSSelectorFromString(@"opOutsider:");
    SEL blacklistActionSelector = NSSelectorFromString(@"opWCBlacklist:");
    if (![controller respondsToSelector:allSelector] ||
        ![controller respondsToSelector:onlyChatActionSelector] ||
        ![controller respondsToSelector:outsiderActionSelector] ||
        ![controller respondsToSelector:blacklistActionSelector]) return NO;

    BOOL outsider = NO;
    BOOL blacklist = NO;
    Class stateControllerClass = NSClassFromString(@"ContactSetPermissionsViewController");
    id stateController = stateControllerClass ? [stateControllerClass new] : nil;
    SEL setContactSelector = NSSelectorFromString(@"setM_contact:");
    SEL outsiderStateSelector = NSSelectorFromString(@"getIsOutsiderSwitchOn:");
    SEL blacklistStateSelector = NSSelectorFromString(@"getIsWCBlackSwitchOn:");
    if (stateController &&
        [stateController respondsToSelector:setContactSelector] &&
        [stateController respondsToSelector:outsiderStateSelector] &&
        [stateController respondsToSelector:blacklistStateSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(stateController, setContactSelector, contact);
        outsider = ((BOOL (*)(id, SEL, id))objc_msgSend)(stateController, outsiderStateSelector, contact);
        blacklist = ((BOOL (*)(id, SEL, id))objc_msgSend)(stateController, blacklistStateSelector, contact);
    }

    unsigned int sex = 0;
    SEL sexSelector = NSSelectorFromString(@"m_uiSex");
    if ([contact respondsToSelector:sexSelector]) sex = ((unsigned int (*)(id, SEL))objc_msgSend)(contact, sexSelector);
    NSString *pronoun = sex == 1 ? @"他" : (sex == 2 ? @"她" : @"TA");

    __weak id weakDelegate = delegate;
    __weak WCActionSheet *weakSheet = sheet;
    NSString *capturedUserName = [userName copy];
    WCActionSheetItem *allItem = NeoWCMomentsPermissionItem(
        NeoWCMomentsCheckedPermissionTitle(@"聊天、朋友圈、微信运动等", !onlyChat), YES, NO, ^{
            NeoWCPerformMomentsPermissionAction(capturedUserName, weakDelegate, @"opAllPermission", nil);
        });
    WCActionSheetItem *onlyChatItem = NeoWCMomentsPermissionItem(
        NeoWCMomentsCheckedPermissionTitle(@"仅聊天", onlyChat), YES, NO, ^{
            NeoWCPerformMomentsPermissionAction(capturedUserName, weakDelegate, @"opSocialBlackPermission", nil);
        });
    WCActionSheetItem *outsiderItem = NeoWCMomentsPermissionItem(
        NeoWCMomentsCheckedPermissionTitle([NSString stringWithFormat:@"不让%@看", pronoun], outsider), !onlyChat, NO, ^{
            NeoWCPerformMomentsPermissionAction(capturedUserName, weakDelegate, @"opOutsider:", @(!outsider));
        });
    WCActionSheetItem *blacklistItem = NeoWCMomentsPermissionItem(
        NeoWCMomentsCheckedPermissionTitle([NSString stringWithFormat:@"不看%@", pronoun], blacklist), !onlyChat, NO, ^{
            NeoWCPerformMomentsPermissionAction(capturedUserName, weakDelegate, @"opWCBlacklist:", @(!blacklist));
        });
    WCActionSheetItem *complaintItem = NeoWCMomentsPermissionItem(@"投诉", YES, YES, ^{
        id strongDelegate = weakDelegate;
        WCActionSheet *strongSheet = weakSheet;
        SEL selector = NSSelectorFromString(@"actionSheet:clickedButtonAtIndex:");
        if (strongDelegate && strongSheet && [strongDelegate respondsToSelector:selector]) {
            ((void (*)(id, SEL, id, NSInteger))objc_msgSend)(strongDelegate, selector, strongSheet, 1);
        }
    });
    if (!allItem || !onlyChatItem || !outsiderItem || !blacklistItem || !complaintItem) return NO;

    SEL listSelector = NSSelectorFromString(@"setButtonTitleList:");
    SEL countSelector = NSSelectorFromString(@"setNumberOfButtons:");
    SEL firstSelector = NSSelectorFromString(@"setFirstOtherButtonIndex:");
    SEL destructiveSelector = NSSelectorFromString(@"setDestructiveButtonIndex:");
    if (![sheet respondsToSelector:listSelector] ||
        ![sheet respondsToSelector:countSelector] ||
        ![sheet respondsToSelector:firstSelector] ||
        ![sheet respondsToSelector:destructiveSelector]) return NO;
    NSMutableArray *items = [@[allItem, onlyChatItem, outsiderItem, blacklistItem, complaintItem] mutableCopy];
    ((void (*)(id, SEL, id))objc_msgSend)(sheet, listSelector, items);
    ((void (*)(id, SEL, NSInteger))objc_msgSend)(sheet, countSelector, 5);
    ((void (*)(id, SEL, NSInteger))objc_msgSend)(sheet, firstSelector, 0);
    ((void (*)(id, SEL, NSInteger))objc_msgSend)(sheet, destructiveSelector, 4);
    NeoWCCompatibilityMarkTriggered(@"moments-quick-permissions");
    return YES;
}

static id NeoWCTweakValueForSelectorNames(id object, NSArray<NSString *> *selectorNames) {
    for (NSString *selectorName in selectorNames) {
        SEL selector = NSSelectorFromString(selectorName);
        if ([object respondsToSelector:selector]) return ((id (*)(id, SEL))objc_msgSend)(object, selector);
    }
    return nil;
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

static BOOL NeoWCResponderIsInsideControllerClass(UIResponder *responder, NSString *className) {
    Class controllerClass = NSClassFromString(className);
    if (!controllerClass) return NO;
    while (responder) {
        if ([responder isKindOfClass:controllerClass]) return YES;
        responder = responder.nextResponder;
    }
    return NO;
}

static id NeoWCMessageWrapForCell(id cell) {
    id viewModel = NeoWCTweakValueForSelectorNames(cell, @[@"viewModel", @"m_viewModel"]);
    id message = NeoWCTweakValueForSelectorNames(viewModel, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap"]);
    if (message) return message;
    id parentModel = NeoWCTweakSafeValue(viewModel, @"parentModel");
    return NeoWCTweakValueForSelectorNames(parentModel, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap"]);
}

static NSString *NeoWCImageJokerKeyForMessage(id message);
static id NeoWCImageJokerMessageForObject(id object);

static void NeoWCRecordMeMenuTitle(NSString *title) {
    if (title.length == 0 || [title isEqualToString:@"插件"]) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    @synchronized (defaults) {
        NSMutableArray<NSString *> *known = [[defaults arrayForKey:NeoWCMeMenuKnownTitlesKey] mutableCopy] ?: [NSMutableArray array];
        if (![known containsObject:title]) {
            [known addObject:title];
            [defaults setObject:known forKey:NeoWCMeMenuKnownTitlesKey];
        }
    }
}

static BOOL NeoWCHidesMeMenuTitle(NSString *title) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id master = [defaults objectForKey:@"com.qiu7c.neowc.enabled"];
    return title.length > 0 && (!master || [master boolValue]) &&
           [[defaults arrayForKey:NeoWCMeMenuHiddenTitlesKey] containsObject:title];
}

static BOOL NeoWCVoiceMessageIsGroup(id message) {
    NSString *from = NeoWCTweakValueForSelectorNames(message, @[@"m_nsFromUsr", @"fromUser"]);
    NSString *to = NeoWCTweakValueForSelectorNames(message, @[@"m_nsToUsr", @"toUser"]);
    return [from hasSuffix:@"@chatroom"] || [to hasSuffix:@"@chatroom"];
}

static BOOL NeoWCVoiceTranscriptionHasResult(id cell, id message) {
    SEL resultSelector = NSSelectorFromString(@"hasLocalTranslateResult");
    if ([message respondsToSelector:resultSelector] &&
        ((BOOL (*)(id, SEL))objc_msgSend)(message, resultSelector)) return YES;
    for (NSString *key in @[@"m_textTranslateView", @"m_textTranslateLabel", @"m_translateResultLabel"]) {
        UIView *view = NeoWCTweakSafeValue(cell, key);
        if ([view isKindOfClass:[UIView class]] && !view.hidden && view.alpha > 0.01) return YES;
    }
    return NO;
}

static BOOL NeoWCVoiceTranscriptionIsActive(id cell) {
    if ([NeoWCTweakSafeValue(cell, @"m_isTranslating") boolValue]) return YES;
    for (NSString *key in @[@"m_translatingView", @"m_textTranslateLoadingView"]) {
        UIView *view = NeoWCTweakSafeValue(cell, key);
        if ([view isKindOfClass:[UIView class]] && !view.hidden && view.alpha > 0.01) return YES;
    }
    return NO;
}

static BOOL NeoWCShouldAutoTranscribeVoiceCell(id cell, id message) {
    if (!NeoWCEnhancementEnabled(NeoWCAutoVoiceTranscriptionEnabledKey) || !message) return NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL group = NeoWCVoiceMessageIsGroup(message);
    if (group && [defaults boolForKey:NeoWCAutoVoiceTranscriptionIgnoreGroupKey]) return NO;
    if (!group && [defaults boolForKey:NeoWCAutoVoiceTranscriptionIgnorePrivateKey]) return NO;
    id viewModel = NeoWCTweakValueForSelectorNames(cell, @[@"viewModel", @"m_viewModel"]);
    BOOL isSender = [NeoWCTweakSafeValue(viewModel, @"isSender") boolValue] ||
                    [NeoWCTweakSafeValue(message, @"isSender") boolValue];
    if (isSender && [defaults boolForKey:NeoWCAutoVoiceTranscriptionIgnoreSelfKey]) return NO;
    if ([objc_getAssociatedObject(message, &NeoWCVoiceTranscriptionDoneKey) boolValue] ||
        [objc_getAssociatedObject(message, &NeoWCVoiceTranscriptionInProgressKey) boolValue] ||
        [objc_getAssociatedObject(message, &NeoWCVoiceTranscriptionAttemptedKey) boolValue]) return NO;
    if (NeoWCVoiceTranscriptionHasResult(cell, message)) {
        objc_setAssociatedObject(message, &NeoWCVoiceTranscriptionDoneKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return NO;
    }
    return !NeoWCVoiceTranscriptionIsActive(cell);
}

static void NeoWCScheduleVoiceTranscription(VoiceMessageCellView *cell, id message) {
    if (!cell.window || !NeoWCShouldAutoTranscribeVoiceCell(cell, message)) return;
    if ([objc_getAssociatedObject(cell, &NeoWCVoiceTranscriptionScheduledKey) boolValue]) return;
    objc_setAssociatedObject(cell, &NeoWCVoiceTranscriptionScheduledKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak VoiceMessageCellView *weakCell = cell;
    __weak id weakMessage = message;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        VoiceMessageCellView *strongCell = weakCell;
        id strongMessage = weakMessage;
        if (!strongCell) return;
        objc_setAssociatedObject(strongCell, &NeoWCVoiceTranscriptionScheduledKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        id currentMessage = NeoWCImageJokerMessageForObject(strongCell);
        if (currentMessage != strongMessage || !NeoWCShouldAutoTranscribeVoiceCell(strongCell, strongMessage)) return;
        SEL selector = NSSelectorFromString(@"onVoiceTrans:");
        if (![strongCell respondsToSelector:selector]) return;
        id button = NeoWCTweakSafeValue(strongCell, @"m_quickTransTipButton") ?: strongCell;
        objc_setAssociatedObject(strongMessage, &NeoWCVoiceTranscriptionAttemptedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(strongMessage, &NeoWCVoiceTranscriptionInProgressKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        ((void (*)(id, SEL, id))objc_msgSend)(strongCell, selector, button);
        NeoWCCompatibilityMarkTriggered(@"auto-voice-transcription");
        __weak VoiceMessageCellView *checkingCell = strongCell;
        __weak id checkingMessage = strongMessage;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            VoiceMessageCellView *cellToCheck = checkingCell;
            id messageToCheck = checkingMessage;
            if (!messageToCheck) return;
            if (cellToCheck && NeoWCVoiceTranscriptionHasResult(cellToCheck, messageToCheck)) {
                objc_setAssociatedObject(messageToCheck, &NeoWCVoiceTranscriptionDoneKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            objc_setAssociatedObject(messageToCheck, &NeoWCVoiceTranscriptionInProgressKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        });
    });
}

static BOOL NeoWCMessageIsText(id message) {
    SEL selector = NSSelectorFromString(@"IsTextMsg");
    return message && [message respondsToSelector:selector] && ((BOOL (*)(id, SEL))objc_msgSend)(message, selector);
}

static BOOL NeoWCMessageIsRefer(id message) {
    SEL selector = NSSelectorFromString(@"isReferMsgType");
    return message && [message respondsToSelector:selector] && ((BOOL (*)(id, SEL))objc_msgSend)(message, selector);
}

static id NeoWCPayInfoItemForMessage(id message) {
    if (!message) return nil;
    SEL parseSelector = NSSelectorFromString(@"parseWCPayInfoItemIfNeed");
    if ([message respondsToSelector:parseSelector]) ((void (*)(id, SEL))objc_msgSend)(message, parseSelector);

    SEL payItemSelector = NSSelectorFromString(@"m_oWCPayInfoItem");
    if (![message respondsToSelector:payItemSelector]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(message, payItemSelector);
}

static BOOL NeoWCMessageIsTransfer(id message) {
    id payItem = NeoWCPayInfoItemForMessage(message);
    if (!payItem) return NO;

    unsigned int subType = 0;
    SEL subTypeSelector = NSSelectorFromString(@"m_uiPaySubType");
    if ([payItem respondsToSelector:subTypeSelector]) {
        subType = ((unsigned int (*)(id, SEL))objc_msgSend)(payItem, subTypeSelector);
    }
    if (subType == 3 || subType == 4) return YES;

    SEL transferIDSelector = NSSelectorFromString(@"m_nsTransferID");
    NSString *transferID = [payItem respondsToSelector:transferIDSelector]
        ? ((id (*)(id, SEL))objc_msgSend)(payItem, transferIDSelector)
        : nil;
    return [transferID isKindOfClass:[NSString class]] && transferID.length > 0;
}

static BOOL NeoWCMessageCanJokerEdit(id message) {
    return NeoWCMessageIsText(message) || NeoWCMessageIsRefer(message) || NeoWCMessageIsTransfer(message);
}

static NSString *NeoWCTransferDisplayText(id message) {
    id payItem = NeoWCPayInfoItemForMessage(message);
    SEL feeDescSelector = NSSelectorFromString(@"m_nsFeeDesc");
    id value = payItem ? ((id (*)(id, SEL))objc_msgSend)(payItem, feeDescSelector) : nil;
    return [value isKindOfClass:[NSString class]] ? value : @"";
}

static NSString *NeoWCDisplayTextForJokerMessage(id message) {
    if (NeoWCMessageIsText(message)) {
        SEL contentSelector = NSSelectorFromString(@"GetDisplayContent");
        id value = ((id (*)(id, SEL))objc_msgSend)(message, contentSelector);
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    } else if (NeoWCMessageIsRefer(message)) {
        SEL titleSelector = NSSelectorFromString(@"m_nsTitle");
        id value = ((id (*)(id, SEL))objc_msgSend)(message, titleSelector);
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    } else if (NeoWCMessageIsTransfer(message)) {
        return NeoWCTransferDisplayText(message);
    }
    return @"";
}

static UIViewController *NeoWCJokerPresenterForCell(id cell) {
    return NeoWCViewControllerForResponder(cell);
}

static void NeoWCReloadJokerCell(id cell, id message, UIViewController *controller) {
    if (!controller) controller = NeoWCJokerPresenterForCell(cell);
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

static void NeoWCApplyJokerText(id cell,
                                id message,
                                UIViewController *controller,
                                NSString *text,
                                BOOL transferContext) {
    BOOL isText = !transferContext && NeoWCMessageIsText(message);
    BOOL isRefer = !transferContext && !isText && NeoWCMessageIsRefer(message);
    BOOL isTransfer = transferContext || (!isText && !isRefer && NeoWCMessageIsTransfer(message));
    if (!message || (!isText && !isRefer && !isTransfer)) return;
    BOOL changed = NO;
    if (isText) {
        NSString *original = NeoWCDisplayTextForJokerMessage(message);
        if (text.length > 0 && ![text isEqualToString:original]) {
            ((void (*)(id, SEL, id))objc_msgSend)(message, NSSelectorFromString(@"setM_nsContent:"), text);
            changed = YES;
        }
    } else if (isRefer) {
        NSString *original = NeoWCDisplayTextForJokerMessage(message);
        if (text.length > 0 && ![text isEqualToString:original]) {
            ((void (*)(id, SEL, id))objc_msgSend)(message, NSSelectorFromString(@"setM_nsTitle:"), text);
            changed = YES;
        }
    } else if (isTransfer) {
        if (text.length == 0) return;
        NSString *original = NeoWCTransferDisplayText(message);
        if ([original hasPrefix:@"¥"] || [original hasPrefix:@"￥"]) {
            original = [original substringFromIndex:1];
        }
        if ([text isEqualToString:original]) return;
        NSString *amount = NeoWCJokerSanitizedAmountText(text);
        if (amount.length == 0) return;
        id payItem = NeoWCPayInfoItemForMessage(message);
        NSString *feeDesc = [@"¥" stringByAppendingString:amount];
        if (payItem) {
            ((void (*)(id, SEL, id))objc_msgSend)(payItem, NSSelectorFromString(@"setM_nsFeeDesc:"), feeDesc);
            ((void (*)(id, SEL, id))objc_msgSend)(payItem, NSSelectorFromString(@"setM_receiverDesc:"), feeDesc);
            ((void (*)(id, SEL, id))objc_msgSend)(payItem, NSSelectorFromString(@"setM_senderDesc:"), feeDesc);
            changed = YES;
        }
    }
    if (!changed) return;
    NeoWCReloadJokerCell(cell, message, controller);
    NeoWCLog(@"聊天记录小丑已修改当前页面显示");
}

static NSObject *NeoWCImageJokerCacheLock(void) {
    static NSObject *lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ lock = [NSObject new]; });
    return lock;
}

static NSMutableDictionary<NSString *, UIImage *> *NeoWCImageJokerImages(void) {
    static NSMutableDictionary<NSString *, UIImage *> *images;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ images = [NSMutableDictionary dictionary]; });
    return images;
}

static NSMutableDictionary<NSString *, NSData *> *NeoWCImageJokerData(void) {
    static NSMutableDictionary<NSString *, NSData *> *data;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ data = [NSMutableDictionary dictionary]; });
    return data;
}

static NSMutableDictionary<NSString *, NSString *> *NeoWCImageJokerPaths(void) {
    static NSMutableDictionary<NSString *, NSString *> *paths;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ paths = [NSMutableDictionary dictionary]; });
    return paths;
}

static NSString *NeoWCImageJokerKeyForMessage(id message) {
    if (!message) return nil;
    SEL combinedSelector = NSSelectorFromString(@"combineChatNameWithLocalId");
    if ([message respondsToSelector:combinedSelector]) {
        id combined = ((id (*)(id, SEL))objc_msgSend)(message, combinedSelector);
        if ([combined isKindOfClass:[NSString class]] && [combined length] > 0) return combined;
    }
    SEL chatSelector = NSSelectorFromString(@"GetChatName");
    SEL localIDSelector = NSSelectorFromString(@"m_uiMesLocalID");
    if (![message respondsToSelector:chatSelector] || ![message respondsToSelector:localIDSelector]) return nil;
    id chatName = ((id (*)(id, SEL))objc_msgSend)(message, chatSelector);
    if (![chatName isKindOfClass:[NSString class]] || [chatName length] == 0) return nil;
    unsigned int localID = ((unsigned int (*)(id, SEL))objc_msgSend)(message, localIDSelector);
    return localID > 0 ? [NSString stringWithFormat:@"%@_%u", chatName, localID] : nil;
}

static id NeoWCImageJokerMessageForObject(id object) {
    if (!object) return nil;
    Class messageClass = NSClassFromString(@"CMessageWrap");
    if (messageClass && [object isKindOfClass:messageClass]) return object;
    id message = NeoWCTweakValueForSelectorNames(object, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap", @"message"]);
    if (message) return message;
    id viewModel = NeoWCTweakValueForSelectorNames(object, @[@"viewModel", @"m_viewModel"]);
    return NeoWCTweakValueForSelectorNames(viewModel, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap"]);
}

static UIImage *NeoWCImageJokerImageForMessage(id message) {
    if (!NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey)) return nil;
    NSString *key = NeoWCImageJokerKeyForMessage(message);
    if (key.length == 0) return nil;
    @synchronized (NeoWCImageJokerCacheLock()) {
        return NeoWCImageJokerImages()[key];
    }
}

static NSData *NeoWCImageJokerDataForMessage(id message) {
    if (!NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey)) return nil;
    NSString *key = NeoWCImageJokerKeyForMessage(message);
    if (key.length == 0) return nil;
    @synchronized (NeoWCImageJokerCacheLock()) {
        return NeoWCImageJokerData()[key];
    }
}

static NSString *NeoWCImageJokerPathForMessage(id message) {
    if (!NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey)) return nil;
    NSString *key = NeoWCImageJokerKeyForMessage(message);
    if (key.length == 0) return nil;
    @synchronized (NeoWCImageJokerCacheLock()) {
        return NeoWCImageJokerPaths()[key];
    }
}

static UIImage *NeoWCImageJokerImageForObject(id object) {
    return NeoWCImageJokerImageForMessage(NeoWCImageJokerMessageForObject(object));
}

static CGSize NeoWCImageJokerDisplaySize(UIImage *image) {
    CGSize imageSize = image.size;
    if (imageSize.width <= 0.0 || imageSize.height <= 0.0 ||
        !isfinite(imageSize.width) || !isfinite(imageSize.height)) return CGSizeZero;

    CGFloat ratio = imageSize.width / imageSize.height;
    CGFloat width = 0.0;
    CGFloat height = 0.0;
    if (ratio < 1.0) {
        height = 180.0;
        width = ratio * height;
        if (width < 76.0) {
            width = 76.0;
            height = width / ratio;
        }
        if (width > 135.0) {
            width = 135.0;
            height = width / ratio;
        }
    } else {
        width = 180.0;
        height = width / ratio;
        if (height < 76.0) {
            height = 76.0;
            width = ratio * height;
        }
        if (height > 135.0) {
            height = 135.0;
            width = ratio * height;
        }
    }
    return CGSizeMake(floor(MAX(1.0, width)), floor(MAX(1.0, height)));
}

static NSString *NeoWCImageJokerTemporaryDirectory(void) {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"wxi_image_joker"];
}

static NSString *NeoWCImageJokerSafeFilename(NSString *key) {
    NSMutableString *name = [NSMutableString stringWithCapacity:MIN((NSUInteger)80, key.length)];
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"];
    for (NSUInteger index = 0; index < key.length && name.length < 80; index++) {
        unichar character = [key characterAtIndex:index];
        if ([allowed characterIsMember:character]) [name appendFormat:@"%C", character];
        else [name appendString:@"_"];
    }
    return [(name.length > 0 ? name : [@"image" mutableCopy]) stringByAppendingPathExtension:@"jpg"];
}

static BOOL NeoWCStoreImageJokerOverride(id message, UIImage *image) {
    NSString *key = NeoWCImageJokerKeyForMessage(message);
    if (key.length == 0 || ![image isKindOfClass:[UIImage class]]) return NO;
    NSData *data = UIImageJPEGRepresentation(image, 0.95);
    if (data.length == 0) data = UIImagePNGRepresentation(image);
    if (data.length == 0) return NO;
    NSString *directory = NeoWCImageJokerTemporaryDirectory();
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *path = [directory stringByAppendingPathComponent:NeoWCImageJokerSafeFilename(key)];
    if (![data writeToFile:path options:NSDataWritingAtomic error:nil]) path = nil;
    @synchronized (NeoWCImageJokerCacheLock()) {
        NeoWCImageJokerImages()[key] = image;
        NeoWCImageJokerData()[key] = data;
        if (path.length > 0) NeoWCImageJokerPaths()[key] = path;
        else [NeoWCImageJokerPaths() removeObjectForKey:key];
    }
    return YES;
}

static void NeoWCClearImageJokerOverrides(void) {
    @synchronized (NeoWCImageJokerCacheLock()) {
        [NeoWCImageJokerImages() removeAllObjects];
        [NeoWCImageJokerData() removeAllObjects];
        [NeoWCImageJokerPaths() removeAllObjects];
    }
    [[NSFileManager defaultManager] removeItemAtPath:NeoWCImageJokerTemporaryDirectory() error:nil];
}

static void NeoWCApplyImageJokerToCell(id cell, id message, UIImage *image) {
    id imageView = NeoWCTweakSafeValue(cell, @"m_imageView");
    if ([imageView isKindOfClass:[UIImageView class]]) ((UIImageView *)imageView).image = image;
    id viewModel = NeoWCTweakValueForSelectorNames(cell, @[@"viewModel", @"m_viewModel"]);
    SEL resetSelector = NSSelectorFromString(@"resetLayoutCache");
    if ([viewModel respondsToSelector:resetSelector]) ((void (*)(id, SEL))objc_msgSend)(viewModel, resetSelector);
    NeoWCReloadJokerCell(cell, message, NeoWCJokerPresenterForCell(cell));
}

@interface NeoWCImageJokerPickerDelegate : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, weak) id cell;
@property (nonatomic, weak) UIViewController *presenter;
@property (nonatomic, strong) id message;
@end

@implementation NeoWCImageJokerPickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (![image isKindOfClass:[UIImage class]]) image = info[UIImagePickerControllerEditedImage];
    id cell = self.cell;
    id message = self.message;
    if (image && message && NeoWCStoreImageJokerOverride(message, image)) {
        if (cell) NeoWCApplyImageJokerToCell(cell, message, image);
        NeoWCCompatibilityMarkTriggered(@"image-joker");
        NeoWCCompatibilityMarkTriggered(@"chat-joker");
        NeoWCLog(@"聊天图片已在当前页面伪装");
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end

static void NeoWCPresentImageJokerPickerForCell(id cell) {
    if (!NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey)) return;
    id message = NeoWCMessageWrapForCell(cell);
    UIViewController *presenter = NeoWCJokerPresenterForCell(cell);
    if (!message || !presenter.view.window ||
        ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) return;
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = NO;
    NeoWCImageJokerPickerDelegate *delegate = [NeoWCImageJokerPickerDelegate new];
    delegate.cell = cell;
    delegate.presenter = presenter;
    delegate.message = message;
    picker.delegate = delegate;
    objc_setAssociatedObject(picker, &NeoWCImageJokerPickerDelegateKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [presenter presentViewController:picker animated:YES completion:nil];
}

static NSArray *NeoWCOperationMenuItemsWithImageJoker(id target, NSArray *originalItems) {
    if (![originalItems isKindOfClass:[NSArray class]]) return originalItems;
    NSMutableArray *items = [originalItems mutableCopy];
    if (NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey) && NeoWCMessageWrapForCell(target)) {
        BOOL exists = NO;
        for (id item in items) {
            if ([NeoWCTweakSafeValue(item, @"title") isEqualToString:@"修改图片"]) { exists = YES; break; }
        }
        if (!exists) {
            Class itemClass = NSClassFromString(@"MMMenuItem");
            if ([itemClass instancesRespondToSelector:@selector(initWithTitle:icon:target:action:)]) {
                UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:18.0 weight:UIImageSymbolWeightRegular];
                UIImage *icon = [UIImage systemImageNamed:@"photo.badge.pencil" withConfiguration:configuration];
                if (!icon) icon = [UIImage systemImageNamed:@"square.and.pencil" withConfiguration:configuration];
                icon = [icon imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
                MMMenuItem *menuItem = [[itemClass alloc] initWithTitle:@"修改图片" icon:icon target:target action:@selector(joker_handleImageMenuItem:)];
                if (menuItem) [items insertObject:menuItem atIndex:0];
            }
        }
    }
    return items;
}

static id NeoWCEmoticonExtendInfoForCell(id cell, NSString *expectedClassName) {
    id message = NeoWCMessageWrapForCell(cell);
    id extendInfo = NeoWCTweakValueForSelectorNames(message, @[@"m_extendInfoWithMsgType"]);
    Class expectedClass = NSClassFromString(expectedClassName);
    if (!extendInfo || (expectedClass && ![extendInfo isKindOfClass:expectedClass])) return nil;
    return extendInfo;
}

static NSData *NeoWCEmoticonDataForMD5(NSString *md5, BOOL needUpdateTime) {
    if (![md5 isKindOfClass:[NSString class]] || md5.length == 0) return nil;
    Class utilClass = NSClassFromString(@"EmoticonUtil");
    SEL existsSelector = NSSelectorFromString(@"fileExistOfEmoticonForMd5:");
    SEL dataSelector = NSSelectorFromString(@"dataOfEmoticonForMd5:needUpdateTime:ignoreWxAM:");
    if (!utilClass || ![utilClass respondsToSelector:existsSelector] || ![utilClass respondsToSelector:dataSelector]) return nil;
    if (!((BOOL (*)(id, SEL, id))objc_msgSend)(utilClass, existsSelector, md5)) return nil;
    id data = ((id (*)(id, SEL, id, BOOL, BOOL))objc_msgSend)(utilClass, dataSelector, md5, needUpdateTime, NO);
    return [data isKindOfClass:[NSData class]] && [data length] > 0 ? data : nil;
}

static id NeoWCEmoticonAddLogicController(void) {
    static id controller;
    @synchronized ([NSObject class]) {
        if (!controller) {
            Class controllerClass = NSClassFromString(@"EmoticonCustomAddLogicController");
            if (controllerClass) controller = [controllerClass new];
        }
    }
    return controller;
}

static BOOL NeoWCSaveDataAsSelfieEmoticon(NSData *data) {
    if (![data isKindOfClass:[NSData class]] || data.length == 0) return NO;
    Class fileClass = NSClassFromString(@"CBaseFile");
    Class uploadClass = NSClassFromString(@"EmoticonUploadInfoObj");
    Class utilClass = NSClassFromString(@"EmoticonUtil");
    SEL md5Selector = NSSelectorFromString(@"GetDataMD5:");
    if (!fileClass || !uploadClass || !utilClass || ![fileClass respondsToSelector:md5Selector]) return NO;

    NSString *md5 = ((id (*)(id, SEL, id))objc_msgSend)(fileClass, md5Selector, data);
    id uploadInfo = [uploadClass new];
    if (![md5 isKindOfClass:[NSString class]] || md5.length == 0 || !uploadInfo) return NO;

    SEL setUploadMD5 = NSSelectorFromString(@"setUploadImgMd5:");
    SEL setIsSelfie = NSSelectorFromString(@"setIsSelfie:");
    SEL setScene = NSSelectorFromString(@"setSelfieScene:");
    SEL setWXAM = NSSelectorFromString(@"setIsUploadWxam:");
    SEL setEnterTime = NSSelectorFromString(@"setSelfieEnterTime:");
    SEL setLensID = NSSelectorFromString(@"setLensId:");
    SEL saveTemp = NSSelectorFromString(@"saveImgDataToTempPathWithImgData:");
    NSArray<NSString *> *requiredSelectors = @[
        NSStringFromSelector(setUploadMD5), NSStringFromSelector(setIsSelfie), NSStringFromSelector(setScene),
        NSStringFromSelector(setWXAM), NSStringFromSelector(setEnterTime), NSStringFromSelector(setLensID),
        NSStringFromSelector(saveTemp),
    ];
    for (NSString *selectorName in requiredSelectors) {
        if (![uploadInfo respondsToSelector:NSSelectorFromString(selectorName)]) return NO;
    }

    ((void (*)(id, SEL, id))objc_msgSend)(uploadInfo, setUploadMD5, md5);
    ((void (*)(id, SEL, BOOL))objc_msgSend)(uploadInfo, setIsSelfie, YES);
    ((void (*)(id, SEL, NSUInteger))objc_msgSend)(uploadInfo, setScene, 2);
    SEL isWXAMSelector = NSSelectorFromString(@"isWxAMData:");
    BOOL isWXAM = [utilClass respondsToSelector:isWXAMSelector]
        ? ((BOOL (*)(id, SEL, id))objc_msgSend)(utilClass, isWXAMSelector, data)
        : NO;
    ((void (*)(id, SEL, BOOL))objc_msgSend)(uploadInfo, setWXAM, isWXAM);

    NSTimeInterval timestamp = NSDate.date.timeIntervalSince1970;
    ((void (*)(id, SEL, unsigned long long))objc_msgSend)(uploadInfo, setEnterTime, (unsigned long long)timestamp);
    ((void (*)(id, SEL, id))objc_msgSend)(uploadInfo, setLensID, [NSString stringWithFormat:@"%.0f", timestamp]);
    BOOL saved = ((BOOL (*)(id, SEL, id))objc_msgSend)(uploadInfo, saveTemp, data);
    if (!saved) return NO;

    id controller = NeoWCEmoticonAddLogicController();
    SEL handleSelector = NSSelectorFromString(@"handleEmoticonUploadInfo:source:");
    if (!controller || ![controller respondsToSelector:handleSelector]) return NO;
    ((void (*)(id, SEL, id, NSUInteger))objc_msgSend)(controller, handleSelector, uploadInfo, 7);
    NeoWCCompatibilityMarkTriggered(@"emoticon-to-selfie");
    return YES;
}

static BOOL NeoWCSaveCellEmoticonAsSelfie(id cell, NSString *extendInfoClassName, BOOL needUpdateTime) {
    id extendInfo = NeoWCEmoticonExtendInfoForCell(cell, extendInfoClassName);
    NSString *md5 = NeoWCTweakValueForSelectorNames(extendInfo, @[@"m_nsEmoticonMD5"]);
    NSData *data = NeoWCEmoticonDataForMD5(md5, needUpdateTime);
    return NeoWCSaveDataAsSelfieEmoticon(data);
}

static NSArray *NeoWCMenuItemsWithEmoticonToSelfie(id target, NSArray *originalItems, NSString *extendInfoClassName) {
    if (![originalItems isKindOfClass:[NSArray class]] || !NeoWCEnhancementEnabled(NeoWCEmoticonToSelfieEnabledKey)) return originalItems;
    if (!NeoWCEmoticonExtendInfoForCell(target, extendInfoClassName)) return originalItems;
    for (id item in originalItems) {
        if ([NeoWCTweakSafeValue(item, @"title") isEqualToString:@"存入自拍"]) return originalItems;
    }

    Class itemClass = NSClassFromString(@"MMMenuItem");
    if (!itemClass) return originalItems;
    id menuItem = nil;
    SEL action = NSSelectorFromString(@"neowc_saveEmoticonAsSelfie");
    SEL targetInitializer = NSSelectorFromString(@"initWithTitle:svgName:target:action:");
    SEL initializer = NSSelectorFromString(@"initWithTitle:svgName:action:");
    if ([itemClass instancesRespondToSelector:targetInitializer]) {
        menuItem = ((id (*)(id, SEL, id, id, id, SEL))objc_msgSend)([itemClass alloc], targetInitializer,
            @"存入自拍", @"icons_outlined_takephoto_nor", target, action);
    } else if ([itemClass instancesRespondToSelector:initializer]) {
        menuItem = ((id (*)(id, SEL, id, id, SEL))objc_msgSend)([itemClass alloc], initializer,
            @"存入自拍", @"icons_outlined_takephoto_nor", action);
    }
    if (!menuItem) return originalItems;
    NSMutableArray *items = [originalItems mutableCopy];
    [items addObject:menuItem];
    return items;
}

static NSData *NeoWCPreviewEmoticonData(id controller) {
    id popoverView = NeoWCTweakValueForSelectorNames(controller, @[@"popoverView"]);
    SEL downloadedSelector = NSSelectorFromString(@"checkIfEmojiDownloaded");
    if ([popoverView respondsToSelector:downloadedSelector] &&
        !((BOOL (*)(id, SEL))objc_msgSend)(popoverView, downloadedSelector)) return nil;
    id model = NeoWCTweakValueForSelectorNames(popoverView, @[@"model"]);
    id emoticonWrap = NeoWCTweakValueForSelectorNames(model, @[@"emoticonWrap"]);
    SEL selfieSelector = NSSelectorFromString(@"isSelfieEmoticon");
    if ([emoticonWrap respondsToSelector:selfieSelector] &&
        ((BOOL (*)(id, SEL))objc_msgSend)(emoticonWrap, selfieSelector)) return nil;
    id imageData = NeoWCTweakValueForSelectorNames(emoticonWrap, @[@"m_imageData"]);
    if ([imageData isKindOfClass:[NSData class]] && [imageData length] > 0) return imageData;
    NSString *md5 = NeoWCTweakValueForSelectorNames(emoticonWrap, @[@"m_nsEmoticonMD5"]);
    return NeoWCEmoticonDataForMD5(md5, YES);
}

static NSString *NeoWCAdBlockerRewrittenURLString(NSString *URLString) {
    if (!NeoWCEnhancementEnabled(NeoWCAdBlockerKey) ||
        ![URLString isKindOfClass:[NSString class]]) return URLString;
    static NSArray<NSString *> *blockedFragments;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        blockedFragments = @[
            @"mp.weixin.qq.com/mp/getappmsgad",
            @"wxsnsdy.wxs.qq.com",
            @"wxsnsdy.tc.qq.com",
            @"wxsnsdy.video.qq.com",
            @"wxsnsdythumb.wxs.qq.com",
            @"ad_data",
            @"/wxfile://usr/ad/",
            @"/ad.wx.com",
            @"lib/WASplashadWorker.js",
            @"lib/WAAppAd.js",
        ];
    });
    for (NSString *fragment in blockedFragments) {
        if ([URLString containsString:fragment]) return @"/t";
    }
    return URLString;
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
    Class contactManagerClass = objc_getClass("CContactMgr");
    if (!contactManagerClass) return nil;
    id manager = NeoWCServiceForClass(contactManagerClass);
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
    unsigned int stepCount = NeoWCConfiguredDailyStepCount();
    if (stepCount > 0) NeoWCLog(@"微信运动今日配置为 %u 步", stepCount);
}

static id NeoWCMomentsObjectForSelector(id object, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!object || ![object respondsToSelector:selector]) return nil;
    @try {
        return ((id (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static id NeoWCMomentsObjectForName(id object, NSString *name) {
    id value = NeoWCMomentsObjectForSelector(object, name);
    return value ?: NeoWCTweakSafeValue(object, name);
}

static NSArray<UIControl *> *NeoWCMomentsVisibleControls(UIView *root) {
    if (![root isKindOfClass:[UIView class]]) return @[];
    NSMutableArray<UIControl *> *controls = [NSMutableArray array];
    id injectedForwardButton = objc_getAssociatedObject(root, &NeoWCMomentsFloatForwardButtonKey);
    NSMutableArray<UIView *> *pending = [NSMutableArray arrayWithObject:root];
    while (pending.count > 0) {
        UIView *view = pending.lastObject;
        [pending removeLastObject];
        for (UIView *subview in view.subviews) {
            [pending addObject:subview];
            if (subview == injectedForwardButton || ![subview isKindOfClass:[UIControl class]] ||
                subview.hidden || subview.alpha <= 0.01) continue;
            CGRect frame = [subview convertRect:subview.bounds toView:root];
            if (CGRectGetWidth(frame) >= 36.0 && CGRectGetHeight(frame) >= 24.0) {
                [controls addObject:(UIControl *)subview];
            }
        }
    }
    [controls sortUsingComparator:^NSComparisonResult(UIControl *left, UIControl *right) {
        CGFloat leftX = CGRectGetMinX([left convertRect:left.bounds toView:root]);
        CGFloat rightX = CGRectGetMinX([right convertRect:right.bounds toView:root]);
        if (leftX < rightX) return NSOrderedAscending;
        if (leftX > rightX) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    return controls;
}

static NSString *NeoWCMomentsControlDescription(UIControl *control) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (NSString *value in @[control.accessibilityIdentifier ?: @"", control.accessibilityLabel ?: @""]) {
        if (value.length > 0) [parts addObject:value];
    }
    if ([control isKindOfClass:[UIButton class]]) {
        NSString *title = [(UIButton *)control currentTitle];
        if (title.length > 0) [parts addObject:title];
    }
    return [[parts componentsJoinedByString:@" "] lowercaseString];
}

static void NeoWCMomentsNativeFloatControls(WCOperateFloatView *floatView,
                                            UIControl **likeControl,
                                            UIControl **commentControl) {
    id like = NeoWCMomentsObjectForName(floatView, @"m_likeBtn");
    id comment = NeoWCMomentsObjectForName(floatView, @"m_commentBtn");
    NSArray<UIControl *> *controls = NeoWCMomentsVisibleControls(floatView);
    for (UIControl *control in controls) {
        NSString *description = NeoWCMomentsControlDescription(control);
        if (![comment isKindOfClass:[UIControl class]] &&
            ([description containsString:@"comment"] || [description containsString:@"评论"])) comment = control;
        if (![like isKindOfClass:[UIControl class]] &&
            ([description containsString:@"like"] || [description containsString:@"赞"])) like = control;
    }
    if (![comment isKindOfClass:[UIControl class]] && controls.count > 0) comment = controls.lastObject;
    if (![like isKindOfClass:[UIControl class]] && controls.count > 1) like = controls[controls.count - 2];
    if (likeControl) *likeControl = [like isKindOfClass:[UIControl class]] ? like : nil;
    if (commentControl) *commentControl = [comment isKindOfClass:[UIControl class]] ? comment : nil;
}

static BOOL NeoWCMomentsBoolForSelector(id object, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!object || ![object respondsToSelector:selector]) return NO;
    @try {
        return ((BOOL (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

static unsigned int NeoWCMomentsUnsignedForSelector(id object, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!object || ![object respondsToSelector:selector]) return 0;
    @try {
        return ((unsigned int (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        return 0;
    }
}

static id NeoWCMomentsContentObject(id dataItem) {
    return NeoWCMomentsObjectForSelector(dataItem, @"contentObj");
}

static NSArray *NeoWCMomentsMediaItems(id dataItem) {
    id mediaList = NeoWCMomentsObjectForSelector(NeoWCMomentsContentObject(dataItem), @"mediaList");
    return [mediaList isKindOfClass:[NSArray class]] ? mediaList : @[];
}

static NSString *NeoWCMomentsBodyText(id dataItem) {
    id text = NeoWCMomentsObjectForSelector(dataItem, @"contentDesc");
    return [text isKindOfClass:[NSString class]] ? text : @"";
}

static BOOL NeoWCMomentsHasStructuredContent(id contentObject) {
    static NSArray<NSString *> *selectors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        selectors = @[@"noteInfo", @"musicShareItem", @"musicInfo", @"finderLiveShareItem",
                      @"finderThemeLiveShareItem", @"finderShareToMomentsItem", @"finderLongVideoShareItem",
                      @"finderShareItem", @"weappInfo", @"snsWeAppInfo", @"tingListenItem",
                      @"tingCategoryItem", @"tingChatRoomItem", @"tingLyricsItem"];
    });
    for (NSString *selectorName in selectors) {
        if (NeoWCMomentsObjectForSelector(contentObject, selectorName)) return YES;
    }
    return NO;
}

static BOOL NeoWCMomentCanForward(id dataItem) {
    if (!dataItem) return NO;
    id contentObject = NeoWCMomentsContentObject(dataItem);
    if (!contentObject) return NO;
    if (NeoWCMomentsHasStructuredContent(contentObject)) return YES;
    NSArray *mediaItems = NeoWCMomentsMediaItems(dataItem);
    if ((NeoWCMomentsBoolForSelector(contentObject, @"isPhotoType") ||
         NeoWCMomentsBoolForSelector(contentObject, @"isVideoType")) && mediaItems.count > 0) return YES;
    if (NeoWCMomentsUnsignedForSelector(contentObject, @"type") != 2 ||
        mediaItems.count > 0 || NeoWCMomentsBodyText(dataItem).length == 0) return NO;
    id linkURL = NeoWCMomentsObjectForSelector(contentObject, @"linkUrl");
    return ![linkURL isKindOfClass:[NSString class]] || [linkURL length] == 0;
}

static NSString *NeoWCMomentsExistingMediaPath(id mediaItem, NSArray<NSString *> *selectors) {
    for (NSString *selectorName in selectors) {
        id value = NeoWCMomentsObjectForSelector(mediaItem, selectorName);
        NSString *path = [value isKindOfClass:[NSURL class]] ? [value path] : ([value isKindOfClass:[NSString class]] ? value : nil);
        if (path.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    return nil;
}

@interface NeoWCMomentsForwardTask : NSObject
@property (nonatomic, strong) id dataItem;
@property (nonatomic, weak) UIViewController *presenter;
@property (nonatomic, strong) NSArray *mediaItems;
@property (nonatomic, strong) NSMutableArray *resolvedPaths;
@property (nonatomic, strong) NSMutableArray *downloaders;
@property (nonatomic, assign) NSUInteger remainingDownloads;
@property (nonatomic, assign) BOOL video;
@property (nonatomic, assign) BOOL failed;
- (void)start;
@end

@implementation NeoWCMomentsForwardTask

- (void)releasePresenterRetention {
    UIViewController *presenter = self.presenter;
    if (presenter && objc_getAssociatedObject(presenter, &NeoWCMomentsForwardTaskKey) == self) {
        objc_setAssociatedObject(presenter, &NeoWCMomentsForwardTaskKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)applyBodyTextToController:(id)controller attempt:(NSUInteger)attempt {
    NSString *body = NeoWCMomentsBodyText(self.dataItem);
    if (body.length == 0 || !controller) return;
    id textView = NeoWCMomentsObjectForSelector(controller, @"textView");
    SEL setTextSelector = NSSelectorFromString(@"setText:");
    if (!textView || ![textView respondsToSelector:setTextSelector]) {
        if (attempt < 3) {
            __weak typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf applyBodyTextToController:controller attempt:attempt + 1];
            });
        }
        return;
    }
    ((void (*)(id, SEL, id))objc_msgSend)(textView, setTextSelector, body);
    for (NSString *selectorName in @[@"changeContentSize", @"adjustRect"]) {
        SEL selector = NSSelectorFromString(selectorName);
        if ([textView respondsToSelector:selector]) ((void (*)(id, SEL))objc_msgSend)(textView, selector);
    }
    SEL changedSelector = NSSelectorFromString(@"textViewTextDidChange");
    if ([controller respondsToSelector:changedSelector]) ((void (*)(id, SEL))objc_msgSend)(controller, changedSelector);
    SEL heightSelector = NSSelectorFromString(@"MMGrowTextViewHeightDidChanged:");
    if ([controller respondsToSelector:heightSelector]) ((void (*)(id, SEL, id))objc_msgSend)(controller, heightSelector, textView);
}

- (void)presentController:(id)controller applyBody:(BOOL)applyBody {
    UIViewController *presenter = self.presenter;
    if (![controller isKindOfClass:[UIViewController class]] || !presenter.view.window) {
        NeoWCShowTransientMessage(@"朋友圈转发失败：当前页面不可用", NO);
        [self releasePresenterRetention];
        return;
    }
    SEL delegateSelector = NSSelectorFromString(@"setDelegate:");
    if ([controller respondsToSelector:delegateSelector]) ((void (*)(id, SEL, id))objc_msgSend)(controller, delegateSelector, presenter);
    SEL fromListSelector = NSSelectorFromString(@"setM_bFromWCList:");
    if ([controller respondsToSelector:fromListSelector]) ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, fromListSelector, YES);
    Class navigationClass = NSClassFromString(@"MMUINavigationController");
    if (!navigationClass) navigationClass = [UINavigationController class];
    id navigation = [[navigationClass alloc] initWithRootViewController:controller];
    objc_setAssociatedObject(navigation, &NeoWCMomentsForwardTaskKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self releasePresenterRetention];
    if ([navigation isKindOfClass:[UIViewController class]]) ((UIViewController *)navigation).modalPresentationStyle = UIModalPresentationFullScreen;
    __weak typeof(self) weakSelf = self;
    [presenter presentViewController:navigation animated:YES completion:^{
        if (applyBody) [weakSelf applyBodyTextToController:controller attempt:0];
    }];
    NeoWCCompatibilityMarkTriggered(@"moments-forward");
}

- (void)presentStructuredForward {
    Class controllerClass = NSClassFromString(@"WCForwardViewController");
    SEL initializer = NSSelectorFromString(@"initWithDataItem:");
    if (!controllerClass || ![controllerClass instancesRespondToSelector:initializer]) {
        NeoWCShowTransientMessage(@"当前微信版本不支持此类朋友圈转发", NO);
        [self releasePresenterRetention];
        return;
    }
    id controller = ((id (*)(id, SEL, id))objc_msgSend)([controllerClass alloc], initializer, self.dataItem);
    [self presentController:controller applyBody:NO];
}

- (void)presentTextCommit {
    Class controllerClass = NSClassFromString(@"WCNewCommitViewController");
    SEL initializer = NSSelectorFromString(@"initWithTextType");
    if (!controllerClass || ![controllerClass instancesRespondToSelector:initializer]) {
        NeoWCShowTransientMessage(@"当前微信版本不支持文字朋友圈转发", NO);
        [self releasePresenterRetention];
        return;
    }
    id controller = ((id (*)(id, SEL))objc_msgSend)([controllerClass alloc], initializer);
    [self presentController:controller applyBody:YES];
}

- (void)presentImageCommit {
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:self.resolvedPaths.count];
    Class imageClass = NSClassFromString(@"MMImage");
    SEL initializer = NSSelectorFromString(@"initWithImage:");
    for (id value in self.resolvedPaths) {
        NSString *path = [value isKindOfClass:[NSString class]] ? value : nil;
        UIImage *image = path.length > 0 ? [UIImage imageWithContentsOfFile:path] : nil;
        if (!image || !imageClass || ![imageClass instancesRespondToSelector:initializer]) continue;
        id wrappedImage = ((id (*)(id, SEL, id))objc_msgSend)([imageClass alloc], initializer, image);
        SEL dataPathSelector = NSSelectorFromString(@"setDataPath:");
        if ([wrappedImage respondsToSelector:dataPathSelector]) ((void (*)(id, SEL, id))objc_msgSend)(wrappedImage, dataPathSelector, path);
        if (wrappedImage) [images addObject:wrappedImage];
    }
    Class controllerClass = NSClassFromString(@"WCNewCommitViewController");
    SEL controllerInitializer = NSSelectorFromString(@"initWithImages:contacts:");
    if (images.count == 0 || !controllerClass || ![controllerClass instancesRespondToSelector:controllerInitializer]) {
        NeoWCShowTransientMessage(@"朋友圈图片读取失败", NO);
        [self releasePresenterRetention];
        return;
    }
    id controller = ((id (*)(id, SEL, id, id))objc_msgSend)([controllerClass alloc], controllerInitializer, images, nil);
    SEL loadingSelector = NSSelectorFromString(@"setLoadingOKStr:");
    if ([controller respondsToSelector:loadingSelector]) ((void (*)(id, SEL, id))objc_msgSend)(controller, loadingSelector, nil);
    [self presentController:controller applyBody:YES];
}

- (void)presentVideoCommit {
    NSString *path = [self.resolvedPaths.firstObject isKindOfClass:[NSString class]] ? self.resolvedPaths.firstObject : nil;
    Class draftClass = NSClassFromString(@"SightDraft");
    SEL draftSelector = NSSelectorFromString(@"draftWithVideoURL:");
    id draft = path.length > 0 && [draftClass respondsToSelector:draftSelector]
        ? ((id (*)(id, SEL, id))objc_msgSend)(draftClass, draftSelector, [NSURL fileURLWithPath:path]) : nil;
    Class controllerClass = NSClassFromString(@"WCNewCommitViewController");
    SEL initializer = NSSelectorFromString(@"initWithSightDraft:");
    if (!draft || !controllerClass || ![controllerClass instancesRespondToSelector:initializer]) {
        NeoWCShowTransientMessage(@"朋友圈视频读取失败", NO);
        [self releasePresenterRetention];
        return;
    }
    id controller = ((id (*)(id, SEL, id))objc_msgSend)([controllerClass alloc], initializer, draft);
    [self presentController:controller applyBody:YES];
}

- (void)finishMediaResolutionIfNeeded {
    if (self.remainingDownloads > 0) return;
    if (self.failed) {
        NeoWCShowTransientMessage(@"朋友圈媒体下载失败，请稍后重试", NO);
        [self releasePresenterRetention];
        return;
    }
    if (self.video) [self presentVideoCommit];
    else [self presentImageCommit];
}

- (void)resolveMediaItem:(id)mediaItem index:(NSUInteger)index {
    NSArray *pathSelectors = self.video
        ? @[@"pathForSightData"]
        : @[@"pathForUhdData", @"pathForHdData", @"pathForData", @"pathForExistData"];
    NSString *path = NeoWCMomentsExistingMediaPath(mediaItem, pathSelectors);
    if (path.length > 0) {
        self.resolvedPaths[index] = path;
        self.remainingDownloads--;
        [self finishMediaResolutionIfNeeded];
        return;
    }
    Class downloaderClass = NSClassFromString(@"WCMediaDownloader");
    SEL initializer = NSSelectorFromString(@"initWithDataItem:mediaItem:");
    SEL startSelector = NSSelectorFromString(@"startDownloadWithCompletionHandler:");
    id downloader = downloaderClass && [downloaderClass instancesRespondToSelector:initializer]
        ? ((id (*)(id, SEL, id, id))objc_msgSend)([downloaderClass alloc], initializer, self.dataItem, mediaItem) : nil;
    if (!downloader || ![downloader respondsToSelector:startSelector]) {
        self.failed = YES;
        self.remainingDownloads--;
        [self finishMediaResolutionIfNeeded];
        return;
    }
    [self.downloaders addObject:downloader];
    __weak typeof(self) weakSelf = self;
    void (^completion)(BOOL, NSError *) = ^(__unused BOOL success, __unused NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            NSString *resolvedPath = NeoWCMomentsExistingMediaPath(mediaItem, pathSelectors);
            if (resolvedPath.length > 0) strongSelf.resolvedPaths[index] = resolvedPath;
            else strongSelf.failed = YES;
            [strongSelf.downloaders removeObject:downloader];
            strongSelf.remainingDownloads--;
            [strongSelf finishMediaResolutionIfNeeded];
        });
    };
    ((void (*)(id, SEL, id))objc_msgSend)(downloader, startSelector, completion);
}

- (void)startMediaResolution:(NSArray *)mediaItems video:(BOOL)video {
    self.video = video;
    self.mediaItems = video ? [mediaItems subarrayWithRange:NSMakeRange(0, 1)]
                            : [mediaItems subarrayWithRange:NSMakeRange(0, MIN((NSUInteger)9, mediaItems.count))];
    self.resolvedPaths = [NSMutableArray arrayWithCapacity:self.mediaItems.count];
    for (__unused id item in self.mediaItems) [self.resolvedPaths addObject:NSNull.null];
    self.downloaders = [NSMutableArray array];
    self.remainingDownloads = self.mediaItems.count;
    [self.mediaItems enumerateObjectsUsingBlock:^(id mediaItem, NSUInteger index, __unused BOOL *stop) {
        [self resolveMediaItem:mediaItem index:index];
    }];
}

- (void)start {
    id contentObject = NeoWCMomentsContentObject(self.dataItem);
    NSArray *mediaItems = NeoWCMomentsMediaItems(self.dataItem);
    if (NeoWCMomentsHasStructuredContent(contentObject)) {
        [self presentStructuredForward];
    } else if (NeoWCMomentsBoolForSelector(contentObject, @"isVideoType") && mediaItems.count > 0) {
        [self startMediaResolution:mediaItems video:YES];
    } else if (NeoWCMomentsBoolForSelector(contentObject, @"isPhotoType") && mediaItems.count > 0) {
        [self startMediaResolution:mediaItems video:NO];
    } else if (NeoWCMomentCanForward(self.dataItem)) {
        [self presentTextCommit];
    } else {
        NeoWCShowTransientMessage(@"当前朋友圈类型暂不支持转发", NO);
        [self releasePresenterRetention];
    }
}

@end

static void NeoWCForwardMoment(id dataItem, UIViewController *presenter) {
    if (!NeoWCEnhancementEnabled(NeoWCMomentsForwardEnabledKey) || !presenter.view.window) return;
    if (!NeoWCMomentCanForward(dataItem)) {
        NeoWCShowTransientMessage(@"当前朋友圈类型暂不支持转发", NO);
        return;
    }
    NeoWCMomentsForwardTask *task = [NeoWCMomentsForwardTask new];
    task.dataItem = dataItem;
    task.presenter = presenter;
    objc_setAssociatedObject(presenter, &NeoWCMomentsForwardTaskKey, task, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [task start];
}

static UIButton *NeoWCMomentsForwardButton(id target, SEL action) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:13.0 weight:UIImageSymbolWeightRegular];
    UIImage *icon = [UIImage systemImageNamed:@"arrow.turn.up.right" withConfiguration:configuration] ?:
                    [UIImage systemImageNamed:@"arrowshape.turn.up.right" withConfiguration:configuration] ?:
                    [UIImage systemImageNamed:@"square.and.arrow.up" withConfiguration:configuration];
    icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:icon forState:UIControlStateNormal];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.tintColor = UIColor.darkGrayColor;
    button.accessibilityLabel = @"转发";
    button.layer.zPosition = 1000.0;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

static BOOL NeoWCMomentsVisibleTextIntersectsRect(UIView *view,
                                                   UIView *root,
                                                   UIView *excludedView,
                                                   UIView *excludedLabel,
                                                   CGRect rect) {
    if (!view || view == excludedView || view == excludedLabel || view.hidden || view.alpha <= 0.01) return NO;
    if ([view isKindOfClass:[UILabel class]] && ((UILabel *)view).text.length > 0) {
        UILabel *label = (UILabel *)view;
        CGRect textRect = [label textRectForBounds:label.bounds limitedToNumberOfLines:label.numberOfLines];
        CGRect textFrame = [label convertRect:textRect toView:root];
        if (CGRectIntersectsRect(textFrame, rect)) return YES;
    }
    for (UIView *subview in view.subviews) {
        if (NeoWCMomentsVisibleTextIntersectsRect(subview, root, excludedView, excludedLabel, rect)) return YES;
    }
    return NO;
}

static void NeoWCSynchronizeMomentsForwardButton(WCTimeLineCellView *cell) {
    UIButton *button = objc_getAssociatedObject(cell, &NeoWCMomentsForwardButtonKey);
    BOOL shouldShow = NeoWCEnhancementEnabled(NeoWCMomentsForwardEnabledKey) &&
                      NeoWCEnhancementEnabled(NeoWCMomentsQuickCommentKey);
    id dataItem = NeoWCMomentsObjectForName(cell, @"m_dataItem");
    UIView *operateButton = NeoWCMomentsObjectForName(cell, @"m_operateBtn");
    NSValue *storedFrameValue = [operateButton isKindOfClass:[UIView class]]
        ? objc_getAssociatedObject(operateButton, &NeoWCMomentsOriginalOperateFrameKey)
        : nil;
    BOOL hasLayout = cell.window && CGRectGetWidth(cell.bounds) > 0.0 &&
                      [operateButton isKindOfClass:[UIView class]] &&
                      CGRectGetWidth(operateButton.bounds) > 0.0;
    if (!shouldShow || !dataItem || !hasLayout) {
        if (storedFrameValue) {
            operateButton.frame = storedFrameValue.CGRectValue;
            objc_setAssociatedObject(operateButton, &NeoWCMomentsOriginalOperateFrameKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [button removeFromSuperview];
        objc_setAssociatedObject(cell, &NeoWCMomentsForwardButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    if (!button) {
        button = NeoWCMomentsForwardButton(cell, @selector(neowc_handleMomentsForward:));
        objc_setAssociatedObject(cell, &NeoWCMomentsForwardButtonKey, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (button.superview != cell) {
        [button removeFromSuperview];
        [cell addSubview:button];
    }
    button.tintColor = operateButton.tintColor ?: UIColor.darkGrayColor;
    CGRect originalFrame = storedFrameValue ? storedFrameValue.CGRectValue : operateButton.frame;
    CGRect shiftedFrame = CGRectOffset(originalFrame, -36.0, 0.0);
    if (storedFrameValue &&
        !CGRectEqualToRect(operateButton.frame, originalFrame) &&
        !CGRectEqualToRect(operateButton.frame, shiftedFrame)) {
        originalFrame = operateButton.frame;
        shiftedFrame = CGRectOffset(originalFrame, -36.0, 0.0);
    }
    objc_setAssociatedObject(operateButton, &NeoWCMomentsOriginalOperateFrameKey,
                             [NSValue valueWithCGRect:originalFrame], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIView *operateSuperview = operateButton.superview;
    CGRect originalFrameInCell = operateSuperview
        ? [operateSuperview convertRect:originalFrame toView:cell]
        : [operateButton convertRect:operateButton.bounds toView:cell];
    CGRect shiftedFrameInCell = operateSuperview
        ? [operateSuperview convertRect:shiftedFrame toView:cell]
        : shiftedFrame;
    UIView *timeLabel = NeoWCMomentsObjectForName(cell, @"m_timeLabel");
    BOOL shouldStackVertically = NeoWCEnhancementEnabled(NeoWCMomentsPreciseTimeKey) &&
        NeoWCMomentsVisibleTextIntersectsRect(cell, cell, operateButton, timeLabel, shiftedFrameInCell) &&
        CGRectGetMinY(originalFrameInCell) >= CGRectGetHeight(originalFrameInCell) + 2.0;
    if (shouldStackVertically) {
        operateButton.frame = originalFrame;
        button.frame = CGRectOffset(originalFrameInCell, 0.0, -CGRectGetHeight(originalFrameInCell) - 2.0);
    } else {
        operateButton.frame = shiftedFrame;
        button.frame = originalFrameInCell;
    }
    button.hidden = NO;
    button.alpha = 1.0;
    [cell bringSubviewToFront:button];
}

static void NeoWCRestoreMomentsFloatMenu(WCOperateFloatView *floatView) {
    NeoWCMomentsFloatMenuSnapshot *snapshot = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSnapshotKey);
    if (![snapshot isKindOfClass:[NeoWCMomentsFloatMenuSnapshot class]] || snapshot.applying) return;
    snapshot.applying = YES;
    [snapshot.expandedLayerMask removeAllAnimations];
    UIButton *button = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatForwardButtonKey);
    UIImageView *separator = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSeparatorKey);
    floatView.frame = snapshot.baseFrame;
    if (snapshot.container != floatView) snapshot.container.frame = snapshot.baseContainerFrame;
    NSUInteger count = MIN(snapshot.baseViews.count, snapshot.baseFrames.count);
    for (NSUInteger index = 0; index < count; index++) {
        snapshot.baseViews[index].frame = snapshot.baseFrames[index].CGRectValue;
    }
    button.hidden = YES;
    separator.hidden = YES;
    floatView.layer.mask = snapshot.originalLayerMask;
    snapshot.applying = NO;
    objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSnapshotKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NeoWCMomentsFloatMenuSnapshot *NeoWCCaptureMomentsFloatMenu(WCOperateFloatView *floatView,
                                                                   UIButton *button,
                                                                   UIView *separator) {
    UIControl *likeButton = nil;
    UIControl *commentButton = nil;
    NeoWCMomentsNativeFloatControls(floatView, &likeButton, &commentButton);
    UIControl *anchor = commentButton ?: likeButton;
    if (![anchor isKindOfClass:[UIControl class]]) return nil;

    UIView *container = anchor.superview ?: floatView;
    CGFloat slotWidth = CGRectGetWidth(anchor.frame);
    if (slotWidth < 44.0) slotWidth = 80.0;

    NeoWCMomentsFloatMenuSnapshot *snapshot = [NeoWCMomentsFloatMenuSnapshot new];
    snapshot.baseFrame = floatView.frame;
    snapshot.addedWidth = slotWidth;
    snapshot.container = container;
    snapshot.baseContainerFrame = container.frame;
    snapshot.containerIsDirectChild = container.superview == floatView;
    snapshot.originalLayerMask = floatView.layer.mask;

    NSMutableArray<UIView *> *baseViews = [NSMutableArray array];
    NSMutableArray<NSValue *> *baseFrames = [NSMutableArray array];
    for (UIView *view in container.subviews) {
        if (view == button || view == separator) continue;
        [baseViews addObject:view];
        [baseFrames addObject:[NSValue valueWithCGRect:view.frame]];
    }
    snapshot.baseViews = baseViews;
    snapshot.baseFrames = baseFrames;

    CGFloat slotHeight = CGRectGetHeight(anchor.frame);
    CGFloat slotY = CGRectGetMinY(anchor.frame);
    if (slotHeight < 24.0) {
        slotHeight = CGRectGetHeight(container.bounds);
        slotY = 0.0;
    }
    CGFloat separatorWidth = CGRectGetWidth(separator.bounds);
    if (separatorWidth < 0.75) separatorWidth = 1.0;
    CGFloat separatorHeight = CGRectGetHeight(separator.bounds);
    if (separatorHeight < 12.0) separatorHeight = 24.0;
    CGFloat separatorY = slotY + (slotHeight - separatorHeight) * 0.5;
    CGFloat containerWidth = CGRectGetWidth(container.bounds);
    if (containerWidth <= 0.0) containerWidth = CGRectGetWidth(snapshot.baseContainerFrame);
    snapshot.forwardFrame = CGRectMake(containerWidth, slotY, slotWidth, slotHeight);
    snapshot.separatorFrame = CGRectMake(containerWidth - separatorWidth,
                                         separatorY,
                                         separatorWidth,
                                         separatorHeight);
    return snapshot;
}

static void NeoWCCollectMomentsNativeSeparators(UIView *root,
                                                 UIView *excluded,
                                                 NSMutableArray<UIImageView *> *matches) {
    for (UIView *view in root.subviews) {
        if (view == excluded) continue;
        if ([view isKindOfClass:[UIImageView class]]) {
            UIImageView *imageView = (UIImageView *)view;
            CGFloat width = CGRectGetWidth(imageView.bounds);
            CGFloat height = CGRectGetHeight(imageView.bounds);
            if (width >= 0.75 && width <= 2.0 && height >= 12.0 && height <= 32.0) {
                [matches addObject:imageView];
            }
        }
        NeoWCCollectMomentsNativeSeparators(view, excluded, matches);
    }
}

static UIImageView *NeoWCMomentsNativeSeparator(WCOperateFloatView *floatView,
                                                 UIControl *anchor,
                                                 UIImageView *excluded) {
    NSMutableArray<UIImageView *> *candidates = [NSMutableArray array];
    NeoWCCollectMomentsNativeSeparators(floatView, excluded, candidates);
    UIImageView *nearest = nil;
    CGFloat nearestDistance = CGFLOAT_MAX;
    CGFloat anchorEdge = CGRectGetMinX([anchor convertRect:anchor.bounds toView:floatView]);
    for (UIImageView *candidate in candidates) {
        NSString *description = candidate.image.description ?: @"";
        if ([description rangeOfString:@"AlbumCommentLine"
                               options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return candidate;
        }
        CGRect frame = [candidate convertRect:candidate.bounds toView:floatView];
        CGFloat distance = fabs(CGRectGetMaxX(frame) - anchorEdge);
        if (distance < nearestDistance) {
            nearest = candidate;
            nearestDistance = distance;
        }
    }
    return nearestDistance <= 3.0 ? nearest : nil;
}

static UIImageView *NeoWCCloneMomentsNativeSeparator(UIImageView *source,
                                                      UIImageView *separator) {
    UIImage *image = source.image ?: [UIImage imageNamed:@"AlbumCommentLine"];
    if (!separator || separator.image != image) {
        [separator removeFromSuperview];
        separator = [[UIImageView alloc] initWithImage:image highlightedImage:source.highlightedImage];
    }
    separator.contentMode = source ? source.contentMode : UIViewContentModeScaleToFill;
    separator.backgroundColor = source.backgroundColor;
    separator.tintColor = source.tintColor;
    separator.alpha = source ? source.alpha : 1.0;
    separator.highlighted = source.highlighted;
    separator.userInteractionEnabled = NO;
    return separator;
}

static void NeoWCApplyMomentsFloatMenuSnapshot(WCOperateFloatView *floatView) {
    NeoWCMomentsFloatMenuSnapshot *snapshot = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSnapshotKey);
    if (![snapshot isKindOfClass:[NeoWCMomentsFloatMenuSnapshot class]] ||
        snapshot.addedWidth <= 0.0 || snapshot.applying) return;
    snapshot.applying = YES;

    UIButton *button = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatForwardButtonKey);
    UIImageView *separator = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSeparatorKey);
    CGRect expandedFrame = snapshot.baseFrame;
    expandedFrame.origin.x -= snapshot.addedWidth;
    expandedFrame.size.width += snapshot.addedWidth;
    floatView.frame = expandedFrame;

    if (snapshot.container != floatView) {
        CGRect containerFrame = snapshot.baseContainerFrame;
        containerFrame.size.width += snapshot.addedWidth;
        snapshot.container.frame = containerFrame;
    }

    NSUInteger count = MIN(snapshot.baseViews.count, snapshot.baseFrames.count);
    CGFloat containerWidth = CGRectGetWidth(snapshot.baseContainerFrame);
    for (NSUInteger index = 0; index < count; index++) {
        UIView *view = snapshot.baseViews[index];
        CGRect frame = snapshot.baseFrames[index].CGRectValue;
        BOOL fillsContainer = CGRectGetMinX(frame) <= 1.0 &&
                              CGRectGetWidth(frame) >= containerWidth - 2.0;
        if (fillsContainer) {
            frame.size.width += snapshot.addedWidth;
        }
        view.frame = frame;
    }

    button.frame = snapshot.forwardFrame;
    separator.frame = snapshot.separatorFrame;
    button.hidden = NO;
    separator.hidden = NO;
    button.alpha = 1.0;
    [snapshot.container bringSubviewToFront:separator];
    [snapshot.container bringSubviewToFront:button];

    if (!snapshot.expandedLayerMask) {
        snapshot.expandedLayerMask = [CAShapeLayer layer];
        snapshot.expandedLayerMask.fillColor = UIColor.blackColor.CGColor;
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    snapshot.expandedLayerMask.frame = floatView.bounds;
    snapshot.expandedLayerMask.path = [UIBezierPath bezierPathWithRect:floatView.bounds].CGPath;
    floatView.layer.mask = snapshot.expandedLayerMask;
    [CATransaction commit];
    snapshot.applying = NO;
}

static void NeoWCPrepareMomentsFloatMenu(WCOperateFloatView *floatView) {
    id dataItem = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatDataItemKey);
    BOOL shouldShow = NeoWCEnhancementEnabled(NeoWCMomentsForwardEnabledKey) &&
                      !NeoWCEnhancementEnabled(NeoWCMomentsQuickCommentKey) &&
                      dataItem != nil;
    UIControl *likeButton = nil;
    UIControl *commentButton = nil;
    NeoWCMomentsNativeFloatControls(floatView, &likeButton, &commentButton);
    UIControl *anchor = commentButton ?: likeButton;
    UIButton *button = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatForwardButtonKey);
    UIImageView *separator = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSeparatorKey);
    if (!shouldShow || ![anchor isKindOfClass:[UIControl class]]) {
        NeoWCRestoreMomentsFloatMenu(floatView);
        [button removeFromSuperview];
        [separator removeFromSuperview];
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSnapshotKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatForwardButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSeparatorKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    UIView *container = anchor.superview ?: floatView;
    if (!button) {
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"转发" forState:UIControlStateNormal];
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:14.0 weight:UIImageSymbolWeightRegular];
        UIImage *icon = [UIImage systemImageNamed:@"arrow.turn.up.right" withConfiguration:configuration] ?:
                        [UIImage systemImageNamed:@"arrowshape.turn.up.right" withConfiguration:configuration] ?:
                        [UIImage systemImageNamed:@"square.and.arrow.up" withConfiguration:configuration];
        [button setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        button.accessibilityIdentifier = @"moments_forward";
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        button.contentEdgeInsets = UIEdgeInsetsZero;
        button.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        button.imageEdgeInsets = UIEdgeInsetsMake(0.0, -3.0, 0.0, 3.0);
        button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 3.0, 0.0, -3.0);
        [button addTarget:floatView action:@selector(neowc_handleMomentsForward:) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatForwardButtonKey, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIButton *anchorButton = [anchor isKindOfClass:[UIButton class]] ? (UIButton *)anchor : nil;
    UIColor *contentColor = [anchorButton titleColorForState:UIControlStateNormal] ?: anchor.tintColor ?: UIColor.whiteColor;
    [button setTitleColor:contentColor forState:UIControlStateNormal];
    [button setTitleColor:[anchorButton titleColorForState:UIControlStateHighlighted] ?: contentColor
                 forState:UIControlStateHighlighted];
    [button setTitleColor:[anchorButton titleColorForState:UIControlStateDisabled] ?: contentColor
                 forState:UIControlStateDisabled];
    button.tintColor = contentColor;
    button.titleLabel.font = anchorButton.titleLabel.font ?: [UIFont systemFontOfSize:14.0];
    button.contentHorizontalAlignment = anchorButton ? anchorButton.contentHorizontalAlignment : UIControlContentHorizontalAlignmentCenter;
    button.contentVerticalAlignment = anchorButton ? anchorButton.contentVerticalAlignment : UIControlContentVerticalAlignmentCenter;
    button.enabled = anchor.enabled;
    if (button.superview != container) {
        [button removeFromSuperview];
        [container addSubview:button];
    }
    UIImageView *nativeSeparator = NeoWCMomentsNativeSeparator(floatView, anchor, separator);
    UIImageView *clonedSeparator = NeoWCCloneMomentsNativeSeparator(nativeSeparator, separator);
    if (clonedSeparator != separator) {
        separator = clonedSeparator;
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSeparatorKey, separator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (separator.superview != container) {
        [separator removeFromSuperview];
        [container addSubview:separator];
    }

    NeoWCMomentsFloatMenuSnapshot *snapshot = NeoWCCaptureMomentsFloatMenu(floatView, button, separator);
    objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSnapshotKey, snapshot, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCApplyMomentsFloatMenuSnapshot(floatView);
}

static BOOL NeoWCTriggerNativeMomentsComment(WCOperateFloatView *floatView) {
    UIControl *commentButton = nil;
    NeoWCMomentsNativeFloatControls(floatView, nil, &commentButton);
    if (![commentButton isKindOfClass:[UIControl class]]) return NO;
    [commentButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    return YES;
}

static NSDateFormatter *NeoWCMomentsPreciseDateFormatter(void) {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
        formatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    });
    return formatter;
}

static id NeoWCMomentsValueForExactSelector(id object, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!object || ![object respondsToSelector:selector]) return nil;
    @try {
        return ((id (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static void NeoWCRestoreMomentsTimeLabel(WCTimeLineCellView *cell, id label) {
    if (![objc_getAssociatedObject(cell, &NeoWCMomentsPreciseTimeAppliedKey) boolValue]) return;
    SEL setTextSelector = NSSelectorFromString(@"setText:");
    if ([label respondsToSelector:setTextSelector]) {
        id original = objc_getAssociatedObject(cell, &NeoWCMomentsOriginalTimeTextKey);
        ((void (*)(id, SEL, id))objc_msgSend)(label, setTextSelector, original == NSNull.null ? nil : original);
    }
    NSNumber *originalLines = objc_getAssociatedObject(cell, &NeoWCMomentsOriginalTimeLinesKey);
    SEL linesSelector = NSSelectorFromString(@"setNumberOfLines:");
    if (originalLines && [label respondsToSelector:linesSelector]) {
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(label, linesSelector, originalLines.integerValue);
    }
    objc_setAssociatedObject(cell, &NeoWCMomentsPreciseTimeAppliedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NSString *NeoWCMomentsPreciseTimeText(unsigned int createTime) {
    if (createTime == 0) return nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *format = NeoWCNormalizedMomentsDateFormat([defaults stringForKey:NeoWCMomentsPreciseTimeFormatKey]);
    if (!format) format = NeoWCMomentsPreciseTimeDefaultFormat;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)createTime];
    NSDateFormatter *formatter = NeoWCMomentsPreciseDateFormatter();
    @synchronized (formatter) {
        formatter.timeZone = NSTimeZone.localTimeZone;
        if (![formatter.dateFormat isEqualToString:format]) formatter.dateFormat = format;
        return [formatter stringFromDate:date];
    }
}

static void NeoWCApplyMomentsPreciseTime(WCTimeLineCellView *cell, BOOL nativeTimeRefreshed) {
    if (!cell) return;
    id label = NeoWCMomentsValueForExactSelector(cell, @"m_timeLabel");
    if (!label) return;
    SEL textSelector = NSSelectorFromString(@"text");
    SEL setTextSelector = NSSelectorFromString(@"setText:");
    if (![label respondsToSelector:textSelector] || ![label respondsToSelector:setTextSelector]) return;

    if (nativeTimeRefreshed) {
        id originalText = ((id (*)(id, SEL))objc_msgSend)(label, textSelector);
        objc_setAssociatedObject(cell, &NeoWCMomentsOriginalTimeTextKey,
                                 originalText ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SEL numberOfLinesSelector = NSSelectorFromString(@"numberOfLines");
        if ([label respondsToSelector:numberOfLinesSelector]) {
            NSInteger lines = ((NSInteger (*)(id, SEL))objc_msgSend)(label, numberOfLinesSelector);
            objc_setAssociatedObject(cell, &NeoWCMomentsOriginalTimeLinesKey,
                                     @(lines), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        objc_setAssociatedObject(cell, &NeoWCMomentsPreciseTimeAppliedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (!objc_getAssociatedObject(cell, &NeoWCMomentsOriginalTimeTextKey)) {
        id currentText = ((id (*)(id, SEL))objc_msgSend)(label, textSelector);
        objc_setAssociatedObject(cell, &NeoWCMomentsOriginalTimeTextKey,
                                 currentText ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (!NeoWCEnhancementEnabled(NeoWCMomentsPreciseTimeKey)) {
        NeoWCRestoreMomentsTimeLabel(cell, label);
        return;
    }
    id dataItem = NeoWCMomentsValueForExactSelector(cell, @"m_dataItem");
    SEL createTimeSelector = NSSelectorFromString(@"createtime");
    if (!dataItem || ![dataItem respondsToSelector:createTimeSelector]) {
        NeoWCRestoreMomentsTimeLabel(cell, label);
        return;
    }
    unsigned int createTime = 0;
    @try {
        createTime = ((unsigned int (*)(id, SEL))objc_msgSend)(dataItem, createTimeSelector);
    } @catch (__unused NSException *exception) {
        NeoWCRestoreMomentsTimeLabel(cell, label);
        return;
    }
    NSString *preciseText = NeoWCMomentsPreciseTimeText(createTime);
    if (preciseText.length == 0) {
        NeoWCRestoreMomentsTimeLabel(cell, label);
        return;
    }
    NSString *currentText = ((id (*)(id, SEL))objc_msgSend)(label, textSelector);
    if (![currentText isEqualToString:preciseText]) {
        ((void (*)(id, SEL, id))objc_msgSend)(label, setTextSelector, preciseText);
    }
    SEL linesSelector = NSSelectorFromString(@"setNumberOfLines:");
    if ([label respondsToSelector:linesSelector]) {
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(label, linesSelector, 1);
    }
    objc_setAssociatedObject(cell, &NeoWCMomentsPreciseTimeAppliedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    NeoWCApplyMomentsPreciseTime(cell, NO);
    NeoWCSynchronizeMomentsForwardButton(cell);
}

static void NeoWCSynchronizeMomentsCellsInView(UIView *view) {
    if (!view) return;
    Class cellClass = NSClassFromString(@"WCTimeLineCellView");
    if (cellClass && [view isKindOfClass:cellClass]) NeoWCSynchronizeMomentsCell((WCTimeLineCellView *)view);
    Class floatClass = NSClassFromString(@"WCOperateFloatView");
    if (floatClass && [view isKindOfClass:floatClass]) {
        NeoWCApplyMomentsFloatMenuSnapshot((WCOperateFloatView *)view);
    }
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

static BaseMsgContentViewController *NeoWCChatControllerInControllerTree(UIViewController *controller) {
    if (!controller) return nil;
    BaseMsgContentViewController *match = nil;
    if (controller.presentedViewController) {
        match = NeoWCChatControllerInControllerTree(controller.presentedViewController);
        if (match) return match;
    }
    if ([controller isKindOfClass:UINavigationController.class]) {
        match = NeoWCChatControllerInControllerTree(((UINavigationController *)controller).visibleViewController);
        if (match) return match;
    }
    if ([controller isKindOfClass:UITabBarController.class]) {
        match = NeoWCChatControllerInControllerTree(((UITabBarController *)controller).selectedViewController);
        if (match) return match;
    }
    if ([controller isKindOfClass:NSClassFromString(@"BaseMsgContentViewController")] &&
        controller.isViewLoaded && controller.view.window &&
        (!controller.navigationController || controller.navigationController.topViewController == controller)) {
        return (BaseMsgContentViewController *)controller;
    }
    for (UIViewController *child in controller.childViewControllers.reverseObjectEnumerator) {
        match = NeoWCChatControllerInControllerTree(child);
        if (match) return match;
    }
    return nil;
}

static BaseMsgContentViewController *NeoWCResolveVisibleChatController(void) {
    BaseMsgContentViewController *cached = NeoWCVisibleChatController;
    if (cached.isViewLoaded && cached.view.window &&
        (!cached.navigationController || cached.navigationController.topViewController == cached)) return cached;

    NSMutableOrderedSet<UIWindow *> *windows = [NSMutableOrderedSet orderedSet];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
        }
    }
    [windows addObjectsFromArray:UIApplication.sharedApplication.windows ?: @[]];
    for (UIWindow *window in windows.reverseObjectEnumerator) {
        if (window.hidden || window.alpha <= 0.0) continue;
        BaseMsgContentViewController *controller =
            NeoWCChatControllerInControllerTree(window.rootViewController);
        if (controller) {
            NeoWCVisibleChatController = controller;
            return controller;
        }
    }
    return nil;
}

static void NeoWCRefreshPinnedMessageGlassInView(UIView *view) {
    if (!view) return;
    if ([view isKindOfClass:NSClassFromString(@"MMMsgCommonTipsView")]) {
        NeoWCUpdatePinnedMessageGlass(view);
    }
    for (UIView *subview in view.subviews) NeoWCRefreshPinnedMessageGlassInView(subview);
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

static void NeoWCSynchronizeReplyGesturesInView(UIView *view) {
    if (!view) return;
    Class cellClass = NSClassFromString(@"CommonMessageCellView");
    if (cellClass && [view isKindOfClass:cellClass]) {
        NeoWCSynchronizeReplyGesture((CommonMessageCellView *)view);
        NeoWCScheduleMessageTimeRefresh(view);
    }
    for (UIView *subview in view.subviews) NeoWCSynchronizeReplyGesturesInView(subview);
}

static void NeoWCSynchronizeVisibleReplyGestures(void) {
    UIWindow *window = NeoWCActiveApplicationWindow();
    if (window) NeoWCSynchronizeReplyGesturesInView(window);
}

static void NeoWCApplyAutoOriginalSelection(id controller) {
    if (!NeoWCEnhancementEnabled(NeoWCAutoOriginalImageEnabledKey)) return;
    SEL selector = NSSelectorFromString(@"setIsOriginSelected:");
    if (![controller respondsToSelector:selector]) return;
    ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, selector, YES);
    NeoWCCompatibilityMarkTriggered(@"auto-original-image");
}

static void NeoWCPresentJokerEditorForCell(id cell, BOOL transferContext) {
    if (!NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey)) return;
    id message = NeoWCMessageWrapForCell(cell);
    if (!message || (!transferContext && !NeoWCMessageCanJokerEdit(message))) return;
    UIViewController *presenter = NeoWCJokerPresenterForCell(cell);
    if (!presenter.view.window) return;
    BOOL isText = !transferContext && NeoWCMessageIsText(message);
    BOOL isRefer = !transferContext && !isText && NeoWCMessageIsRefer(message);
    BOOL isTransfer = transferContext || (!isText && !isRefer && NeoWCMessageIsTransfer(message));
    NSString *current = transferContext ? NeoWCTransferDisplayText(message) : NeoWCDisplayTextForJokerMessage(message);
    if (isTransfer && ([current hasPrefix:@"¥"] || [current hasPrefix:@"￥"])) current = [current substringFromIndex:1];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"聊天记录小丑"
                                                                   message:@"仅修改当前页面的本机显示，离开页面后可能恢复"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = current;
        textField.placeholder = isRefer ? @"输入新的回复文字" : @"输入新的显示文字或金额";
        textField.accessibilityLabel = isRefer ? @"新的回复文字" : @"新的显示文字或金额";
        if (isTransfer) textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak id targetCell = cell;
    id targetMessage = message;
    UIViewController *targetController = presenter;
    [alert addAction:[UIAlertAction actionWithTitle:@"应用" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (targetCell && text.length > 0) {
            NeoWCApplyJokerText(targetCell, targetMessage, targetController, text, transferContext);
        }
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static MMMenuItem *NeoWCJokerMenuItem(id target, BOOL transferContext) {
    if (!NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey)) return nil;
    id message = NeoWCMessageWrapForCell(target);
    if (!message || (!transferContext && !NeoWCMessageCanJokerEdit(message))) return nil;
    Class itemClass = NSClassFromString(@"MMMenuItem");
    if (!itemClass) return nil;
    if (![itemClass instancesRespondToSelector:@selector(initWithTitle:icon:target:action:)]) return nil;
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:18.0 weight:UIImageSymbolWeightRegular];
    UIImage *icon = [UIImage systemImageNamed:@"pencil.circle.fill" withConfiguration:configuration];
    if (!icon) icon = [UIImage systemImageNamed:@"square.and.pencil" withConfiguration:configuration];
    icon = [icon imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    return [[itemClass alloc] initWithTitle:@"小丑" icon:icon target:target action:@selector(joker_handleMenuItem:)];
}

static NSArray *NeoWCOperationMenuItemsWithJoker(id target, NSArray *originalItems, BOOL transferContext) {
    if (![originalItems isKindOfClass:[NSArray class]]) return originalItems;
    NSArray *items = originalItems;
    if (NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey)) {
        BOOL containsJoker = NO;
        for (id item in originalItems) {
            if ([NeoWCTweakSafeValue(item, @"title") isEqualToString:@"小丑"]) {
                containsJoker = YES;
                break;
            }
        }
        if (!containsJoker) {
            MMMenuItem *jokerItem = NeoWCJokerMenuItem(target, transferContext);
            if (jokerItem) {
                NSMutableArray *mutableItems = [originalItems mutableCopy];
                [mutableItems insertObject:jokerItem atIndex:0];
                items = mutableItems;
            }
        }
    }
    return items;
}

static void NeoWCPresentWalletBalanceEditor(id headerView) {
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
    __weak id weakHeaderView = headerView;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        long long fen = text.length > 0 ? (long long)llround(text.doubleValue * 100.0) : 0;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(MAX(0LL, fen)) forKey:NeoWCWalletBalanceFenKey];
        [defaults setBool:fen > 0 forKey:NeoWCWalletBalanceEnabledKey];
        id currentHeaderView = weakHeaderView;
        if (fen > 0 && currentHeaderView) {
            NeoWCRefreshWalletHeaderBalance(currentHeaderView);
        } else if (currentHeaderView) {
            SEL refreshSelector = NSSelectorFromString(@"updateBalanceEntryView");
            if ([currentHeaderView respondsToSelector:refreshSelector]) {
                ((void (*)(id, SEL))objc_msgSend)(currentHeaderView, refreshSelector);
            }
        }
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

static void NeoWCRemoveWalletLongPressIfNeeded(UIView *view) {
    if (!view) return;
    UIGestureRecognizer *recognizer = objc_getAssociatedObject(view, &NeoWCWalletGestureRecognizerKey);
    if (!recognizer) return;
    [view removeGestureRecognizer:recognizer];
    objc_setAssociatedObject(view, &NeoWCWalletGestureRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

    NeoWCSettingsRegisterDefaults();

    Class managerClass = NSClassFromString(@"WCPluginsMgr");
    if (!managerClass || ![managerClass respondsToSelector:@selector(sharedInstance)]) return;

    WCPluginsMgr *manager = [managerClass sharedInstance];
    if (!manager) return;

    [manager registerControllerWithTitle:@"NeoWC"
                                 version:NeoWCDisplayVersion
                              controller:NSStringFromClass([NeoWCSettingsViewController class])];
    NeoWCPluginManagerRegisterSavedQuickSwitches();
    NeoWCDidRegister = YES;
    NeoWCLog(@"已注册插件管理入口与用户选择的快捷开关");
}

@interface NeoWCEntryLoader : NSObject
@end

@implementation NeoWCEntryLoader

+ (void)load {
    NeoWCInstallServiceCenterCompatibility();
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
                    usingBlock:^(NSNotification *note) {
                        NeoWCSynchronizeVisibleMomentsCells();
                        NeoWCSynchronizeVisibleReplyGestures();
                        NSString *changedKey = [note.object isKindOfClass:[NSString class]] ? note.object : nil;
                        BOOL refreshChatTop = !changedKey ||
                            [changedKey isEqualToString:NeoWCChatTopBarCapsuleEnabledKey] ||
                            [changedKey isEqualToString:NeoWCChatTopBarEffectStyleKey] ||
                            [changedKey isEqualToString:NeoWCChatTopBarShadowEnabledKey] ||
                            [changedKey isEqualToString:NeoWCChatGlassBlurIntensityKey] ||
                            [changedKey isEqualToString:NeoWCChatGlassTintOpacityKey] ||
                            [changedKey isEqualToString:NeoWCChatTopBarAvatarSizeKey] ||
                            [changedKey isEqualToString:NeoWCChatTopBarNicknameSizeKey];
                        BaseMsgContentViewController *visibleChat = NeoWCResolveVisibleChatController();
                        if (refreshChatTop && visibleChat) {
                            NeoWCUpdateChatTopBar(visibleChat);
                        }
                    }];

        void (^refreshVisibleChatChrome)(void) = ^{
            BaseMsgContentViewController *controller = NeoWCResolveVisibleChatController();
            if (!controller) return;
            NeoWCRefreshChatTopBarAfterWechatUpdate(controller);
            NeoWCRefreshPinnedMessageGlassInView(controller.view);
        };
        for (NSNotificationName lifecycleName in @[UIApplicationDidBecomeActiveNotification,
                                                    UIApplicationProtectedDataDidBecomeAvailable]) {
            [[NSNotificationCenter defaultCenter]
                addObserverForName:lifecycleName
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(__unused NSNotification *note) {
                            refreshVisibleChatChrome();
                            // WeChat restores different background layers in separate passes.
                            // Replay after both passes without forcing a layout cycle.
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)),
                                           dispatch_get_main_queue(), refreshVisibleChatChrome);
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                                           dispatch_get_main_queue(), refreshVisibleChatChrome);
                        }];
        }

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

static BOOL NeoWCViewLooksLikeGlobalSeparator(UIView *view) {
    if (!view) return NO;
    NSString *className = NSStringFromClass(view.class);
    BOOL nativeSeparator = [className isEqualToString:@"_UITableViewCellSeparatorView"];
    CGRect frame = view.frame;
    CGFloat width = CGRectGetWidth(frame);
    CGFloat height = CGRectGetHeight(frame);
    BOOL thinLine = ((width > 0.3 && width <= 0.55) ||
                     (height > 0.3 && height <= 0.55)) &&
                    view.alpha > 0.9 &&
                    view.backgroundColor != nil &&
                    ![view isKindOfClass:[UILabel class]] &&
                    ![view isKindOfClass:[UIImageView class]];
    BOOL candidate = nativeSeparator || thinLine;
    if ([className isEqualToString:@"UIView"]) candidate = thinLine && view.subviews.count == 0;
    return candidate;
}

%hook UIView

- (void)layoutSubviews {
    %orig;
    NSNumber *originalHidden = objc_getAssociatedObject(self, &NeoWCSeparatorOriginalHiddenKey);
    BOOL shouldHide = NeoWCEnhancementEnabled(NeoWCHideSeparatorLinesKey) && NeoWCViewLooksLikeGlobalSeparator(self);
    if (shouldHide) {
        if (!originalHidden) {
            originalHidden = @(self.hidden);
            objc_setAssociatedObject(self, &NeoWCSeparatorOriginalHiddenKey, originalHidden, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (!self.hidden) self.hidden = YES;
    } else if (originalHidden) {
        self.hidden = originalHidden.boolValue;
        objc_setAssociatedObject(self, &NeoWCSeparatorOriginalHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%end

%hook NewSettingViewController

- (void)viewDidLoad {
    %orig;
    NeoWCRegisterPlugin();
}

%end

%hook MMAssetPickerController

- (void)viewDidLoad {
    %orig;
    NeoWCApplyAutoOriginalSelection(self);
}

%end

%hook MMImagePreviewBrowserController

- (void)viewDidLoad {
    %orig;
    NeoWCApplyAutoOriginalSelection(self);
}

%end

%hook NotificationActionsMgr

- (void)userNotificationCenter:(id)center
didReceiveNotificationResponse:(id)response
         withCompletionHandler:(void (^)(void))completionHandler {
    if (NeoWCHandleNotificationResponse(response, completionHandler)) {
        NeoWCCompatibilityMarkTriggered(@"notification-direct-chat");
        return;
    }
    %orig;
}

%end

%hook MicroMessengerAppDelegate

- (void)userNotificationCenter:(id)center
didReceiveNotificationResponse:(id)response
         withCompletionHandler:(void (^)(void))completionHandler {
    if (NeoWCHandleNotificationResponse(response, completionHandler)) {
        NeoWCCompatibilityMarkTriggered(@"notification-direct-chat");
        return;
    }
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
    id permissionsDataItem = NeoWCPendingMomentsPermissionDataItem;
    if (permissionsDataItem) {
        @try {
            (void)NeoWCConfigureMomentsPermissionsActionSheet(self, permissionsDataItem);
        } @catch (__unused NSException *exception) {
        }
    }
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
    if (NeoWCPendingMomentsPermissionDataItem == permissionsDataItem) NeoWCPendingMomentsPermissionDataItem = nil;
}

%end

%hook SharePreConfirmSheetView

- (void)onConfirmButtonClick {
    id owner = NeoWCTweakSafeValue(self, @"delegate") ?: NeoWCTweakSafeValue(self, @"msgLogicController");
    for (id session in [NeoWCActiveQuickSendSessions() copy]) {
        if (NeoWCTweakSafeValue(session, @"forwardLogic") == owner) {
            NeoWCTweakSetValue(session, @"sendButtonTapped", @YES);
        }
    }
    %orig;
}

- (void)onCancelButtonClick {
    id owner = NeoWCTweakSafeValue(self, @"delegate") ?: NeoWCTweakSafeValue(self, @"msgLogicController");
    NSArray *sessions = [NeoWCActiveQuickSendSessions() copy];
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id session in sessions) {
            if (![NeoWCTweakSafeValue(session, @"finished") boolValue] &&
                NeoWCTweakSafeValue(session, @"forwardLogic") == owner) {
                SEL selector = NSSelectorFromString(@"OnForwardMessageCancel:");
                if ([session respondsToSelector:selector]) {
                    ((void (*)(id, SEL, id))objc_msgSend)(session, selector, owner);
                }
            }
        }
    });
}

%end

%hook MoreViewController

- (void)addFunctionSection {
    %orig;
    NeoWCInstallPluginManagerEntry(self);
    NeoWCCompatibilityMarkTriggered(@"plugin-manager");
}

%new
- (void)pushPluginController {
    NeoWCPushPluginManager(self);
}

- (void)addCardsIfNeededToSection:(id)section {
    (void)section;
    NeoWCRecordMeMenuTitle(@"小店与卡包");
    if (NeoWCHidesMeMenuTitle(@"小店与卡包")) {
        NeoWCCompatibilityMarkTriggered(@"me-menu-visibility");
        return;
    }
    %orig;
}

- (void)addEmoticonsIfNeededToSection:(id)section {
    (void)section;
    NeoWCRecordMeMenuTitle(@"表情");
    if (NeoWCHidesMeMenuTitle(@"表情")) {
        NeoWCCompatibilityMarkTriggered(@"me-menu-visibility");
        return;
    }
    %orig;
}

- (id)createFinderEntranceCellConfig:(CGRect)frame {
    NeoWCRecordMeMenuTitle(@"作品");
    if (NeoWCHidesMeMenuTitle(@"作品")) {
        NeoWCCompatibilityMarkTriggered(@"me-menu-visibility");
        return nil;
    }
    return %orig(frame);
}

%end

%hook VoiceMessageCellView

- (void)layoutSubviews {
    %orig;
    id message = NeoWCImageJokerMessageForObject(self);
    NeoWCScheduleVoiceTranscription(self, message);
}

%end

%hook MMScreenShotViewController

- (void)show {
    if (NeoWCEnhancementEnabled(NeoWCHideScreenshotForwardKey)) {
        NeoWCCompatibilityMarkTriggered(@"hide-screenshot-forward");
        return;
    }
    %orig;
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
    if (self.window) {
        NeoWCApplyChatInputRoundingToToolView(self);
    }
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

static NSString *NeoWCChatUserName(id controller) {
    id contact = NeoWCTweakValueForSelectorNames(controller, @[@"m_contact", @"chatContact", @"contact"]);
    if (!contact && [controller respondsToSelector:@selector(GetContact)]) {
        contact = ((id (*)(id, SEL))objc_msgSend)(controller, @selector(GetContact));
    }
    NSString *userName = NeoWCTweakValueForSelectorNames(contact, @[@"m_nsUsrName", @"userName"]);
    if (userName.length == 0) userName = NeoWCTweakValueForSelectorNames(controller, @[@"m_nsUsrName", @"sessionUserName"]);
    return userName;
}

static void NeoWCRestoreChatTopBar(BaseMsgContentViewController *controller);
static void NeoWCUpdateChatTopBar(BaseMsgContentViewController *controller);

static CGFloat NeoWCChatTopClampedValue(NSString *key, CGFloat fallback,
                                       CGFloat minimum, CGFloat maximum) {
    id stored = [NSUserDefaults.standardUserDefaults objectForKey:key];
    CGFloat value = [stored respondsToSelector:@selector(doubleValue)] ? [stored doubleValue] : fallback;
    if (!isfinite(value)) value = fallback;
    return MIN(maximum, MAX(minimum, value));
}

static CGFloat NeoWCChatTopAvatarSize(void) {
    return NeoWCChatTopClampedValue(NeoWCChatTopBarAvatarSizeKey, 30.0, 24.0, 34.0);
}

static CGFloat NeoWCChatTopNicknameSize(void) {
    return NeoWCChatTopClampedValue(NeoWCChatTopBarNicknameSizeKey, 15.0, 12.0, 18.0);
}

static CGFloat NeoWCChatTopLeftCapsuleHeight(void) {
    return MAX(38.0, NeoWCChatTopAvatarSize() + 8.0);
}

static UIView *NeoWCChatTopAvatarView(id contact, NSString *userName) {
    NSString *headURL = NeoWCTweakSafeValue(contact, @"m_nsHeadImgUrl");
    if (![headURL isKindOfClass:[NSString class]] || headURL.length == 0) {
        headURL = NeoWCTweakSafeValue(contact, @"m_nsHeadImgUrlHD");
    }
    Class helperClass = NSClassFromString(@"MMHeadImageHelper");
    SEL selector = NSSelectorFromString(@"getContactHeadImageViewWithUsrName:headImgUrl:bAutoUpdate:bRoundCorner:");
    if (helperClass && [helperClass respondsToSelector:selector] && userName.length > 0) {
        id view = ((id (*)(id, SEL, id, id, BOOL, BOOL))objc_msgSend)(helperClass,
                                                                      selector,
                                                                      userName,
                                                                      headURL ?: @"",
                                                                      YES,
                                                                      NO);
        if ([view isKindOfClass:[UIView class]]) return view;
    }
    UIImageView *fallback = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"person.crop.circle.fill"]];
    fallback.tintColor = UIColor.tertiaryLabelColor;
    fallback.contentMode = UIViewContentModeScaleAspectFit;
    return fallback;
}

static NSString *NeoWCChatTopDisplayName(BaseMsgContentViewController *controller, id contact) {
    for (NSString *key in @[@"m_nsRemark", @"m_nsNickName", @"m_nsAlias"]) {
        NSString *value = NeoWCTweakSafeValue(contact, key);
        if ([value isKindOfClass:[NSString class]] && value.length > 0) {
            objc_setAssociatedObject(controller, &NeoWCChatTopStableDisplayNameKey,
                                     value, OBJC_ASSOCIATION_COPY_NONATOMIC);
            return value;
        }
    }
    NSString *stableName = objc_getAssociatedObject(controller, &NeoWCChatTopStableDisplayNameKey);
    BOOL typing = [objc_getAssociatedObject(controller, &NeoWCChatTopTypingActiveKey) boolValue];
    if (typing && stableName.length > 0) return stableName;
    NSString *title = controller.navigationItem.title ?: controller.title;
    if (title.length > 0 && ![title containsString:@"正在输入"]) {
        objc_setAssociatedObject(controller, &NeoWCChatTopStableDisplayNameKey,
                                 title, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return title;
    }
    return stableName.length > 0 ? stableName : @"聊天";
}

static BOOL NeoWCChatTitleViewShowsTypingStatus(id titleView) {
    if ([titleView isKindOfClass:UILabel.class]) {
        NSString *text = ((UILabel *)titleView).text;
        return [text isKindOfClass:NSString.class] && [text containsString:@"正在输入"];
    }
    if (![titleView isKindOfClass:UIView.class]) return NO;
    for (UIView *subview in ((UIView *)titleView).subviews) {
        if (NeoWCChatTitleViewShowsTypingStatus(subview)) return YES;
    }
    return NO;
}

static BOOL NeoWCSetChatTypingState(BaseMsgContentViewController *controller, id titleView) {
    BOOL typing = NeoWCChatTitleViewShowsTypingStatus(titleView);
    BOOL previous = [objc_getAssociatedObject(controller, &NeoWCChatTopTypingActiveKey) boolValue];
    if (typing == previous) return NO;
    objc_setAssociatedObject(controller, &NeoWCChatTopTypingActiveKey,
                             @(typing), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return YES;
}

static UIButton *NeoWCChatTopCapsuleButton(UIImage *image, NSString *accessibilityLabel);

static NeoWCChatTopBarEffectStyle NeoWCChatTopEffectStyle(void) {
    NSInteger value = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCChatTopBarEffectStyleKey];
    return value == NeoWCChatTopBarEffectStyleLiquid && NeoWCSystemSupportsNativeLiquidGlass()
        ? NeoWCChatTopBarEffectStyleLiquid
        : NeoWCChatTopBarEffectStyleMaterial;
}

static UIVisualEffect *NeoWCChatTopVisualEffect(void) {
    if (NeoWCChatTopEffectStyle() == NeoWCChatTopBarEffectStyleLiquid) {
        Class glassEffectClass = NSClassFromString(@"UIGlassEffect");
        SEL factory = NSSelectorFromString(@"effectWithStyle:");
        if (glassEffectClass && [glassEffectClass respondsToSelector:factory]) {
            UIVisualEffect *effect = ((id (*)(id, SEL, NSInteger))objc_msgSend)(glassEffectClass,
                                                                                factory,
                                                                                0);
            SEL interactiveSelector = NSSelectorFromString(@"setInteractive:");
            if ([effect respondsToSelector:interactiveSelector]) {
                ((void (*)(id, SEL, BOOL))objc_msgSend)(effect, interactiveSelector, NO);
            }
            if (effect) return effect;
        }
        return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    }
    return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
}

static CGFloat NeoWCChatGlassPercent(NSString *key, CGFloat fallback,
                                     CGFloat minimum, CGFloat maximum) {
    id stored = [NSUserDefaults.standardUserDefaults objectForKey:key];
    CGFloat value = [stored respondsToSelector:@selector(doubleValue)] ? [stored doubleValue] : fallback;
    return MIN(maximum, MAX(minimum, value));
}

static void NeoWCConfigureChatTopGlassLayer(UIVisualEffectView *effectView) {
    UIVisualEffect *effect = NeoWCChatTopVisualEffect();
    CGFloat blurIntensity = NeoWCChatGlassPercent(NeoWCChatGlassBlurIntensityKey,
                                                  100.0, 20.0, 100.0) / 100.0;
    if (blurIntensity >= 0.999) {
        effectView.effect = effect;
    } else {
        effectView.effect = nil;
        __weak UIVisualEffectView *weakEffectView = effectView;
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc]
            initWithDuration:1.0 curve:UIViewAnimationCurveLinear animations:^{
                weakEffectView.effect = effect;
            }];
        [animator startAnimation];
        [animator pauseAnimation];
        animator.fractionComplete = blurIntensity;
        objc_setAssociatedObject(effectView, &NeoWCChatTopGlassEffectAnimatorKey,
                                 animator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat tintOpacity = NeoWCChatGlassPercent(NeoWCChatGlassTintOpacityKey,
                                                0.0, 0.0, 30.0) / 100.0;
    if (tintOpacity > 0.001) {
        UIView *tintView = [[UIView alloc] initWithFrame:effectView.contentView.bounds];
        tintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tintView.userInteractionEnabled = NO;
        tintView.backgroundColor = [UIColor.systemBackgroundColor colorWithAlphaComponent:tintOpacity];
        [effectView.contentView insertSubview:tintView atIndex:0];
    }
    effectView.layer.borderWidth = 0.0;
    effectView.layer.borderColor = UIColor.clearColor.CGColor;
}

static UIView *NeoWCChatTopGlassContainer(CGFloat cornerRadius, UIVisualEffectView **effectViewOut) {
    UIView *container = [UIView new];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = UIColor.clearColor;
    BOOL shadowEnabled = [NSUserDefaults.standardUserDefaults boolForKey:NeoWCChatTopBarShadowEnabledKey];
    container.layer.shadowColor = UIColor.blackColor.CGColor;
    container.layer.shadowOpacity = shadowEnabled ? 0.045 : 0.0;
    container.layer.shadowRadius = shadowEnabled ? 3.0 : 0.0;
    container.layer.shadowOffset = CGSizeZero;
    objc_setAssociatedObject(container, &NeoWCChatTopGlassEffectMarkerKey,
                             @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:nil];
    effectView.translatesAutoresizingMaskIntoConstraints = NO;
    effectView.clipsToBounds = YES;
    effectView.layer.cornerRadius = cornerRadius;
    effectView.layer.cornerCurve = kCACornerCurveContinuous;
    NeoWCConfigureChatTopGlassLayer(effectView);
    objc_setAssociatedObject(effectView, &NeoWCChatTopGlassEffectMarkerKey,
                             @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [container addSubview:effectView];
    [NSLayoutConstraint activateConstraints:@[
        [effectView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [effectView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [effectView.topAnchor constraintEqualToAnchor:container.topAnchor],
        [effectView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    ]];
    if (effectViewOut) *effectViewOut = effectView;
    return container;
}

static UIBarButtonItem *NeoWCChatTopProfileItem(BaseMsgContentViewController *controller,
                                                UIBarButtonItem *backItem) {
    id contact = NeoWCTweakValueForSelectorNames(controller, @[@"m_contact", @"chatContact", @"contact"]);
    if (!contact && [controller respondsToSelector:@selector(GetContact)]) {
        contact = ((id (*)(id, SEL))objc_msgSend)(controller, @selector(GetContact));
    }
    NSString *userName = NeoWCChatUserName(controller);
    NSString *displayName = NeoWCChatTopDisplayName(controller, contact);
    CGFloat availableWidth = MIN(205.0, CGRectGetWidth(UIScreen.mainScreen.bounds) - 130.0);
    CGFloat avatarSize = NeoWCChatTopAvatarSize();
    CGFloat nicknameSize = NeoWCChatTopNicknameSize();
    CGFloat capsuleHeight = NeoWCChatTopLeftCapsuleHeight();

    UIVisualEffectView *glass = nil;
    UIView *container = NeoWCChatTopGlassContainer(capsuleHeight / 2.0, &glass);
    UIView *content = glass.contentView;

    UIImageSymbolConfiguration *backConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:15.0
                                                                                                      weight:UIImageSymbolWeightMedium];
    UIImage *backImage = [UIImage systemImageNamed:@"chevron.left"
                                  withConfiguration:backConfiguration];
    UIButton *backButton = NeoWCChatTopCapsuleButton(backImage, backItem.accessibilityLabel ?: @"返回");
    NeoWCBarButtonActionProxy *backProxy = [NeoWCBarButtonActionProxy new];
    backProxy.originalItem = backItem;
    backProxy.fallbackController = controller;
    backProxy.popsNavigationController = YES;
    [backButton addTarget:backProxy action:@selector(invoke:) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:backButton];
    objc_setAssociatedObject(controller, &NeoWCChatTopBackProxyKey, backProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIView *avatarSource = NeoWCChatTopAvatarView(contact, userName);
    UIView *avatar = [UIView new];
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    avatar.backgroundColor = UIColor.clearColor;
    avatar.clipsToBounds = YES;
    avatar.layer.cornerRadius = avatarSize / 2.0;
    avatar.layer.cornerCurve = kCACornerCurveContinuous;
    avatarSource.translatesAutoresizingMaskIntoConstraints = NO;
    avatarSource.clipsToBounds = YES;
    avatarSource.layer.cornerRadius = avatarSize / 2.0;
    avatarSource.layer.cornerCurve = kCACornerCurveContinuous;
    avatarSource.userInteractionEnabled = NO;
    [avatar addSubview:avatarSource];
    [content addSubview:avatar];

    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = displayName;
    UIFont *nicknameFont = [UIFont systemFontOfSize:nicknameSize weight:UIFontWeightRegular];
    label.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:nicknameFont];
    label.adjustsFontForContentSizeCategory = YES;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.78;
    label.textColor = UIColor.labelColor;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.numberOfLines = 1;
    label.accessibilityLabel = displayName;
    [content addSubview:label];

    BOOL typing = [objc_getAssociatedObject(controller, &NeoWCChatTopTypingActiveKey) boolValue];
    UILabel *typingIndicator = nil;
    if (typing) {
        typingIndicator = [UILabel new];
        typingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        typingIndicator.text = @"•••";
        typingIndicator.font = [UIFont systemFontOfSize:8.0 weight:UIFontWeightSemibold];
        typingIndicator.textColor = UIColor.systemGreenColor;
        typingIndicator.accessibilityLabel = @"对方正在输入";
        typingIndicator.isAccessibilityElement = YES;
        [typingIndicator setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisHorizontal];
        [content addSubview:typingIndicator];
        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
        pulse.fromValue = @0.35;
        pulse.toValue = @1.0;
        pulse.duration = 0.65;
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        [typingIndicator.layer addAnimation:pulse forKey:@"neowc.typing-pulse"];
    }

    CGFloat labelWidth = ceil([displayName sizeWithAttributes:@{NSFontAttributeName: label.font}].width);
    CGFloat avatarDelta = avatarSize - 30.0;
    CGFloat typingWidth = typing ? 22.0 : 0.0;
    CGFloat width = MIN(availableWidth, MAX(96.0 + avatarDelta,
                                           85.0 + avatarDelta + labelWidth + typingWidth));

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithArray:@[
        [container.widthAnchor constraintEqualToConstant:width],
        [container.heightAnchor constraintEqualToConstant:capsuleHeight],
        [backButton.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [backButton.topAnchor constraintEqualToAnchor:content.topAnchor],
        [backButton.bottomAnchor constraintEqualToAnchor:content.bottomAnchor],
        [backButton.widthAnchor constraintEqualToConstant:36.0],
        [avatar.leadingAnchor constraintEqualToAnchor:backButton.trailingAnchor constant:1.0],
        [avatar.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
        [avatar.widthAnchor constraintEqualToConstant:avatarSize],
        [avatar.heightAnchor constraintEqualToConstant:avatarSize],
        [avatarSource.centerXAnchor constraintEqualToAnchor:avatar.centerXAnchor],
        [avatarSource.centerYAnchor constraintEqualToAnchor:avatar.centerYAnchor],
        [avatarSource.widthAnchor constraintEqualToConstant:avatarSize],
        [avatarSource.heightAnchor constraintEqualToConstant:avatarSize],
        [label.leadingAnchor constraintEqualToAnchor:avatar.trailingAnchor constant:8.0],
        [label.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
    ]];
    if (typingIndicator) {
        [constraints addObjectsFromArray:@[
            [label.trailingAnchor constraintLessThanOrEqualToAnchor:typingIndicator.leadingAnchor constant:-4.0],
            [typingIndicator.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-10.0],
            [typingIndicator.centerYAnchor constraintEqualToAnchor:content.centerYAnchor constant:1.0],
        ]];
    } else {
        [constraints addObject:[label.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-10.0]];
    }
    [NSLayoutConstraint activateConstraints:constraints];
    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

static UIButton *NeoWCChatTopCapsuleButton(UIImage *image, NSString *accessibilityLabel) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    button.tintColor = UIColor.labelColor;
    button.accessibilityLabel = accessibilityLabel;
    return button;
}

static UIBarButtonItem *NeoWCChatTopCapsuleItem(BaseMsgContentViewController *controller,
                                                UIBarButtonItem *moreItem) {
    if (!moreItem) return nil;
    UIVisualEffectView *glass = nil;
    CGFloat capsuleHeight = MAX(36.0, NeoWCChatTopLeftCapsuleHeight() - 2.0);
    UIView *capsule = NeoWCChatTopGlassContainer(capsuleHeight / 2.0, &glass);

    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentFill;
    stack.distribution = UIStackViewDistributionFillEqually;
    [glass.contentView addSubview:stack];

    UIImage *moreImage = moreItem.image ?: [UIImage systemImageNamed:@"ellipsis"];
    UIButton *more = NeoWCChatTopCapsuleButton(moreImage, moreItem.accessibilityLabel ?: @"更多");
    NeoWCBarButtonActionProxy *proxy = [NeoWCBarButtonActionProxy new];
    proxy.originalItem = moreItem;
    objc_setAssociatedObject(controller, &NeoWCChatTopMoreProxyKey, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [more addTarget:proxy action:@selector(invoke:) forControlEvents:UIControlEventTouchUpInside];
    if (moreItem.menu) {
        more.menu = moreItem.menu;
        more.showsMenuAsPrimaryAction = YES;
    }
    [stack addArrangedSubview:more];
    [NSLayoutConstraint activateConstraints:@[
        [capsule.widthAnchor constraintEqualToConstant:40.0],
        [capsule.heightAnchor constraintEqualToConstant:capsuleHeight],
        [stack.leadingAnchor constraintEqualToAnchor:glass.contentView.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:glass.contentView.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:glass.contentView.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:glass.contentView.bottomAnchor],
    ]];
    return [[UIBarButtonItem alloc] initWithCustomView:capsule];
}

static UINavigationBarAppearance *NeoWCTransparentChatTopAppearance(void) {
    UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
    [appearance configureWithTransparentBackground];
    appearance.backgroundColor = UIColor.clearColor;
    appearance.backgroundEffect = nil;
    appearance.shadowColor = UIColor.clearColor;
    return appearance;
}

static void NeoWCApplyTransparentChatTopAppearance(BaseMsgContentViewController *controller) {
    UINavigationItem *navigationItem = controller.navigationItem;
    UINavigationBarAppearance *appearance = NeoWCTransparentChatTopAppearance();
    navigationItem.standardAppearance = appearance;
    navigationItem.compactAppearance = appearance;
    navigationItem.scrollEdgeAppearance = appearance;
    if (@available(iOS 15.0, *)) navigationItem.compactScrollEdgeAppearance = appearance;

    UINavigationBar *navigationBar = controller.navigationController.navigationBar;
    if (navigationBar) {
        navigationBar.standardAppearance = appearance;
        navigationBar.compactAppearance = appearance;
        navigationBar.scrollEdgeAppearance = appearance;
        if (@available(iOS 15.0, *)) navigationBar.compactScrollEdgeAppearance = appearance;
        navigationBar.translucent = YES;
    }
    controller.edgesForExtendedLayout |= UIRectEdgeTop;
    controller.extendedLayoutIncludesOpaqueBars = YES;
}

static BOOL NeoWCIsNavigationBarBackgroundView(UIView *view) {
    if (objc_getAssociatedObject(view, &NeoWCChatTopGlassEffectMarkerKey)) return NO;
    NSString *className = NSStringFromClass(view.class);
    return [view isKindOfClass:[UIVisualEffectView class]] ||
           [className containsString:@"Background"] ||
           [className containsString:@"Backdrop"] ||
           [className containsString:@"Material"];
}

static BOOL NeoWCViewContainsChatTopContent(UIView *view) {
    if (!view) return NO;
    if (objc_getAssociatedObject(view, &NeoWCChatTopGlassEffectMarkerKey)) return YES;
    NSString *className = NSStringFromClass(view.class);
    if ([className containsString:@"ContentView"] || [className containsString:@"BarContent"]) return YES;
    for (UIView *subview in view.subviews) {
        if (NeoWCViewContainsChatTopContent(subview)) return YES;
    }
    return NO;
}

static UIView *NeoWCFirstDescendantOfClass(UIView *view, Class targetClass) {
    if (!view || !targetClass) return nil;
    if ([view isKindOfClass:targetClass]) return view;
    for (UIView *subview in view.subviews) {
        UIView *match = NeoWCFirstDescendantOfClass(subview, targetClass);
        if (match) return match;
    }
    return nil;
}

static BOOL NeoWCViewContainsVisualEffect(UIView *view) {
    if (!view) return NO;
    if ([view isKindOfClass:[UIVisualEffectView class]]) return YES;
    for (UIView *subview in view.subviews) {
        if (NeoWCViewContainsVisualEffect(subview)) return YES;
    }
    return NO;
}

static void NeoWCSetChatNavigationBackgroundHidden(UIView *view, BOOL hidden) {
    if (!view) return;
    if (objc_getAssociatedObject(view, &NeoWCChatTopGlassEffectMarkerKey)) return;
    if (NeoWCIsNavigationBarBackgroundView(view)) {
        NSNumber *originalAlpha = objc_getAssociatedObject(view, &NeoWCChatTopBackgroundOriginalAlphaKey);
        NSNumber *originalHidden = objc_getAssociatedObject(view, &NeoWCChatTopBackgroundOriginalHiddenKey);
        if (hidden) {
            if (!originalAlpha) {
                objc_setAssociatedObject(view, &NeoWCChatTopBackgroundOriginalAlphaKey,
                                         @(view.alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(view, &NeoWCChatTopBackgroundOriginalHiddenKey,
                                         @(view.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            view.hidden = YES;
            view.alpha = 0.0;
        } else if (originalAlpha) {
            view.alpha = originalAlpha.doubleValue;
            view.hidden = originalHidden.boolValue;
            objc_setAssociatedObject(view, &NeoWCChatTopBackgroundOriginalAlphaKey,
                                     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(view, &NeoWCChatTopBackgroundOriginalHiddenKey,
                                     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return;
    }
    for (UIView *subview in view.subviews) {
        NeoWCSetChatNavigationBackgroundHidden(subview, hidden);
    }
}

static void NeoWCSetChatNavigationDirectBackgroundsHidden(UINavigationBar *navigationBar, BOOL hidden) {
    if (!navigationBar) return;
    for (UIView *subview in navigationBar.subviews) {
        if (NeoWCViewContainsChatTopContent(subview)) continue;
        NSNumber *originalAlpha = objc_getAssociatedObject(subview, &NeoWCChatTopBackgroundOriginalAlphaKey);
        NSNumber *originalHidden = objc_getAssociatedObject(subview, &NeoWCChatTopBackgroundOriginalHiddenKey);
        if (hidden) {
            if (!originalAlpha) {
                objc_setAssociatedObject(subview, &NeoWCChatTopBackgroundOriginalAlphaKey,
                                         @(subview.alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(subview, &NeoWCChatTopBackgroundOriginalHiddenKey,
                                         @(subview.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            subview.hidden = YES;
            subview.alpha = 0.0;
        } else if (originalAlpha) {
            subview.alpha = originalAlpha.doubleValue;
            subview.hidden = originalHidden.boolValue;
            objc_setAssociatedObject(subview, &NeoWCChatTopBackgroundOriginalAlphaKey,
                                     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(subview, &NeoWCChatTopBackgroundOriginalHiddenKey,
                                     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

static void NeoWCSetChatNavigationHostTransparent(UIView *hostView, BOOL transparent);
static void NeoWCSetChatNavigationContainerClear(UIView *view, BOOL clear);

static void NeoWCSetChatTopFadeMask(UIView *backgroundView, BOOL enabled) {
    if (!backgroundView) return;
    id originalMask = objc_getAssociatedObject(backgroundView, &NeoWCChatTopOriginalBackgroundMaskKey);
    if (enabled) {
        if (!originalMask) {
            objc_setAssociatedObject(backgroundView, &NeoWCChatTopOriginalBackgroundMaskKey,
                                     backgroundView.layer.mask ?: NSNull.null,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        CAGradientLayer *fadeMask = objc_getAssociatedObject(backgroundView, &NeoWCChatTopFadeBackgroundMaskKey);
        if (!fadeMask) {
            fadeMask = [CAGradientLayer layer];
            fadeMask.startPoint = CGPointMake(0.5, 0.0);
            fadeMask.endPoint = CGPointMake(0.5, 1.0);
            fadeMask.colors = @[(id)UIColor.blackColor.CGColor,
                                (id)[UIColor.blackColor colorWithAlphaComponent:0.55].CGColor,
                                (id)[UIColor.blackColor colorWithAlphaComponent:0.18].CGColor,
                                (id)[UIColor.blackColor colorWithAlphaComponent:0.04].CGColor,
                                (id)UIColor.clearColor.CGColor,
                                (id)UIColor.clearColor.CGColor];
            fadeMask.locations = @[@0.0, @0.15, @0.30, @0.40, @0.45, @1.0];
            objc_setAssociatedObject(backgroundView, &NeoWCChatTopFadeBackgroundMaskKey,
                                     fadeMask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        fadeMask.frame = backgroundView.bounds;
        backgroundView.layer.mask = fadeMask;
    } else if (originalMask) {
        backgroundView.layer.mask = originalMask == NSNull.null ? nil : originalMask;
        objc_setAssociatedObject(backgroundView, &NeoWCChatTopOriginalBackgroundMaskKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(backgroundView, &NeoWCChatTopFadeBackgroundMaskKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void NeoWCSetVisualEffectsTopFade(UIView *view, BOOL enabled) {
    if (!view) return;
    if ([view isKindOfClass:[UIVisualEffectView class]]) {
        UIVisualEffectView *effectView = (UIVisualEffectView *)view;
        id originalEffect = objc_getAssociatedObject(effectView, &NeoWCChatTopOriginalVisualEffectKey);
        id originalMask = objc_getAssociatedObject(effectView, &NeoWCChatTopOriginalVisualEffectMaskKey);
        if (enabled) {
            if (!originalEffect) {
                objc_setAssociatedObject(effectView, &NeoWCChatTopOriginalVisualEffectKey,
                                         effectView.effect ?: NSNull.null,
                                         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(effectView, &NeoWCChatTopOriginalVisualEffectMaskKey,
                                         effectView.layer.mask ?: NSNull.null,
                                         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            if (!effectView.effect) {
                effectView.effect = originalEffect && originalEffect != NSNull.null
                    ? originalEffect
                    : [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
            }
            effectView.layer.mask = originalMask == NSNull.null ? nil : originalMask;
            NeoWCSetChatNavigationContainerClear(effectView, YES);
        } else if (originalEffect) {
            effectView.effect = originalEffect == NSNull.null ? nil : originalEffect;
            effectView.layer.mask = originalMask == NSNull.null ? nil : originalMask;
            NeoWCSetChatNavigationContainerClear(effectView, NO);
            objc_setAssociatedObject(effectView, &NeoWCChatTopOriginalVisualEffectKey,
                                     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(effectView, &NeoWCChatTopOriginalVisualEffectMaskKey,
                                     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    for (UIView *subview in view.subviews) {
        NeoWCSetVisualEffectsTopFade(subview, enabled);
    }
}

static void NeoWCSetChatContentNavigationBackgroundTransparent(BaseMsgContentViewController *controller,
                                                                BOOL transparent) {
    UIView *contentNavigationBar = objc_getAssociatedObject(controller, &NeoWCChatTopContentNavigationBarKey);
    if (transparent && (!contentNavigationBar || !contentNavigationBar.superview)) {
        Class contentNavigationBarClass = NSClassFromString(@"MMNewMsgContentNavBar");
        contentNavigationBar = NeoWCFirstDescendantOfClass(controller.view, contentNavigationBarClass);
        if (!contentNavigationBar) {
            contentNavigationBarClass = NSClassFromString(@"MMMsgContentNavBar");
            contentNavigationBar = NeoWCFirstDescendantOfClass(controller.view, contentNavigationBarClass);
        }
        if (contentNavigationBar) {
            objc_setAssociatedObject(controller, &NeoWCChatTopContentNavigationBarKey,
                                     contentNavigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    if (!contentNavigationBar) return;
    NeoWCSetChatNavigationHostTransparent(contentNavigationBar, transparent);
    NeoWCSetChatNavigationContainerClear(contentNavigationBar, transparent);
    for (UIView *subview in contentNavigationBar.subviews) {
        BOOL fillsTopBar = CGRectGetWidth(subview.bounds) >= CGRectGetWidth(contentNavigationBar.bounds) - 1.0 &&
                           CGRectGetHeight(subview.bounds) >= CGRectGetHeight(contentNavigationBar.bounds) - 1.0;
        if (fillsTopBar && NeoWCViewContainsVisualEffect(subview)) {
            NeoWCSetChatNavigationContainerClear(subview, transparent);
            NeoWCSetVisualEffectsTopFade(subview, transparent);
            NeoWCSetChatTopFadeMask(subview, transparent);
            for (UIView *backgroundSubview in subview.subviews) {
                if (CGRectGetHeight(backgroundSubview.bounds) <= 1.0) {
                    NeoWCSetChatNavigationContainerClear(backgroundSubview, transparent);
                    NeoWCSetChatNavigationBackgroundHidden(backgroundSubview, transparent);
                }
            }
        }
    }
    if (!transparent) {
        objc_setAssociatedObject(controller, &NeoWCChatTopContentNavigationBarKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void NeoWCSetChatNavigationHostTransparent(UIView *hostView, BOOL transparent) {
    if (!hostView) return;
    NSNumber *originalClips = objc_getAssociatedObject(hostView, &NeoWCChatTopOriginalClipsToBoundsKey);
    NSNumber *originalBorder = objc_getAssociatedObject(hostView, &NeoWCChatTopOriginalBorderWidthKey);
    NSNumber *originalCorner = objc_getAssociatedObject(hostView, &NeoWCChatTopOriginalCornerRadiusKey);
    if (transparent) {
        if (!originalClips) {
            objc_setAssociatedObject(hostView, &NeoWCChatTopOriginalClipsToBoundsKey,
                                     @(hostView.clipsToBounds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(hostView, &NeoWCChatTopOriginalBorderWidthKey,
                                     @(hostView.layer.borderWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(hostView, &NeoWCChatTopOriginalCornerRadiusKey,
                                     @(hostView.layer.cornerRadius), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        hostView.clipsToBounds = NO;
        hostView.layer.borderWidth = 0.0;
        hostView.layer.cornerRadius = 0.0;
    } else if (originalClips) {
        hostView.clipsToBounds = originalClips.boolValue;
        hostView.layer.borderWidth = originalBorder.doubleValue;
        hostView.layer.cornerRadius = originalCorner.doubleValue;
        objc_setAssociatedObject(hostView, &NeoWCChatTopOriginalClipsToBoundsKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(hostView, &NeoWCChatTopOriginalBorderWidthKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(hostView, &NeoWCChatTopOriginalCornerRadiusKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void NeoWCSetChatNavigationContainerClear(UIView *view, BOOL clear) {
    if (!view) return;
    id originalColor = objc_getAssociatedObject(view, &NeoWCChatTopContainerOriginalBackgroundColorKey);
    if (clear) {
        if (!originalColor) {
            objc_setAssociatedObject(view, &NeoWCChatTopContainerOriginalBackgroundColorKey,
                                     view.backgroundColor ?: NSNull.null,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        view.backgroundColor = UIColor.clearColor;
    } else if (originalColor) {
        view.backgroundColor = originalColor == NSNull.null ? nil : originalColor;
        objc_setAssociatedObject(view, &NeoWCChatTopContainerOriginalBackgroundColorKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void NeoWCApplyChatNavigationBackground(BaseMsgContentViewController *controller, BOOL hidden) {
    NeoWCSetChatContentNavigationBackgroundTransparent(controller, hidden);
    UINavigationBar *navigationBar = controller.navigationController.navigationBar;
    NeoWCSetChatNavigationHostTransparent(navigationBar, hidden);
    NeoWCSetChatNavigationHostTransparent(navigationBar.superview, hidden);
    NeoWCSetChatNavigationBackgroundHidden(navigationBar, hidden);
    NeoWCSetChatNavigationDirectBackgroundsHidden(navigationBar, hidden);
    UIView *navigationRoot = controller.navigationController.view;
    UIView *view = navigationBar;
    for (NSUInteger depth = 0; view && depth < 4; depth++, view = view.superview) {
        NeoWCSetChatNavigationContainerClear(view, hidden);
        for (UIView *sibling in view.superview.subviews) {
            if (sibling != view && NeoWCIsNavigationBarBackgroundView(sibling)) {
                NeoWCSetChatNavigationBackgroundHidden(sibling, hidden);
            }
        }
        if (view == navigationRoot) break;
    }
}

static void NeoWCRestoreChatNavigationPresentation(BaseMsgContentViewController *controller) {
    UINavigationBar *navigationBar = controller.navigationController.navigationBar;
    id standardAppearance = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalNavigationStandardAppearanceKey);
    id compactAppearance = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalNavigationCompactAppearanceKey);
    id scrollEdgeAppearance = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalNavigationScrollEdgeAppearanceKey);
    id compactScrollEdgeAppearance = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalNavigationCompactScrollEdgeAppearanceKey);
    NSNumber *translucent = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalNavigationTranslucentKey);
    if (navigationBar && standardAppearance) {
        navigationBar.standardAppearance = standardAppearance == NSNull.null ? nil : standardAppearance;
        navigationBar.compactAppearance = compactAppearance == NSNull.null ? nil : compactAppearance;
        navigationBar.scrollEdgeAppearance = scrollEdgeAppearance == NSNull.null ? nil : scrollEdgeAppearance;
        if (@available(iOS 15.0, *)) {
            navigationBar.compactScrollEdgeAppearance = compactScrollEdgeAppearance == NSNull.null ? nil : compactScrollEdgeAppearance;
        }
        navigationBar.translucent = translucent.boolValue;
    }
    NSNumber *edges = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalEdgesForExtendedLayoutKey);
    NSNumber *includesOpaqueBars = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalExtendedLayoutIncludesOpaqueBarsKey);
    if (edges) controller.edgesForExtendedLayout = (UIRectEdge)edges.unsignedIntegerValue;
    if (includesOpaqueBars) controller.extendedLayoutIncludesOpaqueBars = includesOpaqueBars.boolValue;
    NeoWCApplyChatNavigationBackground(controller, NO);
}

static UIBarButtonItem *NeoWCNativeChatMoreItem(BaseMsgContentViewController *controller) {
    SEL selector = NSSelectorFromString(@"getRightBarButton");
    if ([controller respondsToSelector:selector]) {
        @try {
            id item = ((id (*)(id, SEL))objc_msgSend)(controller, selector);
            if ([item isKindOfClass:[UIBarButtonItem class]]) return item;
        } @catch (__unused NSException *exception) {
        }
    }
    UIBarButtonItem *installed = objc_getAssociatedObject(controller, &NeoWCChatTopCapsuleItemKey);
    for (UIBarButtonItem *item in controller.navigationItem.rightBarButtonItems) {
        if (item != installed) return item;
    }
    NSArray *original = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalRightItemsKey);
    return original.firstObject;
}

static void NeoWCCaptureOriginalChatNavigationPresentationIfNeeded(BaseMsgContentViewController *controller) {
    UINavigationBar *navigationBar = controller.navigationController.navigationBar;
    if (navigationBar &&
        !objc_getAssociatedObject(controller, &NeoWCChatTopOriginalNavigationStandardAppearanceKey)) {
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalNavigationStandardAppearanceKey,
                                 navigationBar.standardAppearance ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalNavigationCompactAppearanceKey,
                                 navigationBar.compactAppearance ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalNavigationScrollEdgeAppearanceKey,
                                 navigationBar.scrollEdgeAppearance ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (@available(iOS 15.0, *)) {
            objc_setAssociatedObject(controller, &NeoWCChatTopOriginalNavigationCompactScrollEdgeAppearanceKey,
                                     navigationBar.compactScrollEdgeAppearance ?: NSNull.null,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalNavigationTranslucentKey,
                                 @(navigationBar.translucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (!objc_getAssociatedObject(controller, &NeoWCChatTopOriginalEdgesForExtendedLayoutKey)) {
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalEdgesForExtendedLayoutKey,
                                 @((NSUInteger)controller.edgesForExtendedLayout), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalExtendedLayoutIncludesOpaqueBarsKey,
                                 @(controller.extendedLayoutIncludesOpaqueBars), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void NeoWCRestoreChatTopBar(BaseMsgContentViewController *controller) {
    NSArray *originalLeft = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalLeftItemsKey);
    if (!originalLeft) return;
    NSArray *originalRight = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalRightItemsKey) ?: @[];
    id originalTitleView = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalTitleViewKey);
    NSNumber *originalSupplement = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalSupplementKey);
    controller.navigationItem.leftBarButtonItems = originalLeft;
    controller.navigationItem.rightBarButtonItems = originalRight;
    controller.navigationItem.titleView = originalTitleView == NSNull.null ? nil : originalTitleView;
    controller.navigationItem.leftItemsSupplementBackButton = originalSupplement.boolValue;
    id standardAppearance = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalStandardAppearanceKey);
    id compactAppearance = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalCompactAppearanceKey);
    id scrollEdgeAppearance = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalScrollEdgeAppearanceKey);
    id compactScrollEdgeAppearance = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalCompactScrollEdgeAppearanceKey);
    controller.navigationItem.standardAppearance = standardAppearance == NSNull.null ? nil : standardAppearance;
    controller.navigationItem.compactAppearance = compactAppearance == NSNull.null ? nil : compactAppearance;
    controller.navigationItem.scrollEdgeAppearance = scrollEdgeAppearance == NSNull.null ? nil : scrollEdgeAppearance;
    if (@available(iOS 15.0, *)) {
        controller.navigationItem.compactScrollEdgeAppearance = compactScrollEdgeAppearance == NSNull.null ? nil : compactScrollEdgeAppearance;
    }
    NeoWCRestoreChatNavigationPresentation(controller);
    const void *keys[] = {&NeoWCChatTopProfileItemKey, &NeoWCChatTopCapsuleItemKey,
                          &NeoWCChatTopOriginalLeftItemsKey, &NeoWCChatTopOriginalRightItemsKey,
                          &NeoWCChatTopOriginalTitleViewKey, &NeoWCChatTopOriginalSupplementKey,
                          &NeoWCChatTopMoreProxyKey, &NeoWCChatTopBackProxyKey,
                          &NeoWCChatTopOriginalStandardAppearanceKey,
                          &NeoWCChatTopOriginalCompactAppearanceKey,
                          &NeoWCChatTopOriginalScrollEdgeAppearanceKey,
                          &NeoWCChatTopOriginalCompactScrollEdgeAppearanceKey,
                          &NeoWCChatTopPlaceholderTitleViewKey,
                          &NeoWCChatTopOriginalNavigationStandardAppearanceKey,
                          &NeoWCChatTopOriginalNavigationCompactAppearanceKey,
                          &NeoWCChatTopOriginalNavigationScrollEdgeAppearanceKey,
                          &NeoWCChatTopOriginalNavigationCompactScrollEdgeAppearanceKey,
                          &NeoWCChatTopOriginalNavigationTranslucentKey,
                          &NeoWCChatTopOriginalEdgesForExtendedLayoutKey,
                          &NeoWCChatTopOriginalExtendedLayoutIncludesOpaqueBarsKey};
    for (NSUInteger index = 0; index < sizeof(keys) / sizeof(keys[0]); index++) {
        objc_setAssociatedObject(controller, keys[index], nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void NeoWCUpdateChatTopBar(BaseMsgContentViewController *controller) {
    if (!NeoWCEnhancementEnabled(NeoWCChatTopBarCapsuleEnabledKey)) {
        NeoWCRestoreChatTopBar(controller);
        return;
    }
    NeoWCCaptureOriginalChatNavigationPresentationIfNeeded(controller);
    UINavigationItem *navigationItem = controller.navigationItem;
    NSArray *originalLeft = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalLeftItemsKey);
    if (!originalLeft) {
        originalLeft = navigationItem.leftBarButtonItems ?: @[];
        NSMutableArray *originalRight = [navigationItem.rightBarButtonItems mutableCopy] ?: [NSMutableArray array];
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalLeftItemsKey, originalLeft, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalRightItemsKey, originalRight, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalTitleViewKey,
                                 navigationItem.titleView ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalSupplementKey,
                                 @(navigationItem.leftItemsSupplementBackButton), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalStandardAppearanceKey,
                                 navigationItem.standardAppearance ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalCompactAppearanceKey,
                                 navigationItem.compactAppearance ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(controller, &NeoWCChatTopOriginalScrollEdgeAppearanceKey,
                                 navigationItem.scrollEdgeAppearance ?: NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (@available(iOS 15.0, *)) {
            objc_setAssociatedObject(controller, &NeoWCChatTopOriginalCompactScrollEdgeAppearanceKey,
                                     navigationItem.compactScrollEdgeAppearance ?: NSNull.null,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    NSArray<UIBarButtonItem *> *originalRight = objc_getAssociatedObject(controller, &NeoWCChatTopOriginalRightItemsKey) ?: @[];
    UIBarButtonItem *moreItem = NeoWCNativeChatMoreItem(controller) ?: originalRight.firstObject;
    NSArray *remainingRight = @[];

    UIBarButtonItem *backItem = originalLeft.firstObject;
    NSArray *remainingLeft = originalLeft.count > 1
        ? [originalLeft subarrayWithRange:NSMakeRange(1, originalLeft.count - 1)] : @[];
    UIBarButtonItem *profileItem = NeoWCChatTopProfileItem(controller, backItem);
    NSMutableArray *leftItems = [NSMutableArray arrayWithObject:profileItem];
    [leftItems addObjectsFromArray:remainingLeft];
    navigationItem.leftItemsSupplementBackButton = NO;
    navigationItem.leftBarButtonItems = leftItems;
    UIView *placeholderTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    navigationItem.titleView = placeholderTitleView;
    objc_setAssociatedObject(controller, &NeoWCChatTopPlaceholderTitleViewKey,
                             placeholderTitleView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCApplyTransparentChatTopAppearance(controller);
    NeoWCApplyChatNavigationBackground(controller, YES);
    objc_setAssociatedObject(controller, &NeoWCChatTopProfileItemKey, profileItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIBarButtonItem *capsuleItem = NeoWCChatTopCapsuleItem(controller, moreItem);
    NSMutableArray *rightItems = [NSMutableArray array];
    if (capsuleItem) [rightItems addObject:capsuleItem];
    [rightItems addObjectsFromArray:remainingRight];
    navigationItem.rightBarButtonItems = rightItems;
    objc_setAssociatedObject(controller, &NeoWCChatTopCapsuleItemKey, capsuleItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void NeoWCRefreshChatTopBarAfterWechatUpdate(BaseMsgContentViewController *controller) {
    if (!NeoWCEnhancementEnabled(NeoWCChatTopBarCapsuleEnabledKey)) return;
    if (!controller.isViewLoaded || !controller.view.window) return;
    if (controller.navigationController.topViewController != controller) return;
    UIBarButtonItem *profileItem = objc_getAssociatedObject(controller, &NeoWCChatTopProfileItemKey);
    UIBarButtonItem *capsuleItem = objc_getAssociatedObject(controller, &NeoWCChatTopCapsuleItemKey);
    UIView *placeholderTitleView = objc_getAssociatedObject(controller, &NeoWCChatTopPlaceholderTitleViewKey);
    BOOL profileMissing = !profileItem || ![controller.navigationItem.leftBarButtonItems containsObject:profileItem];
    BOOL capsuleMissing = capsuleItem && ![controller.navigationItem.rightBarButtonItems containsObject:capsuleItem];
    BOOL titleWasReplaced = !placeholderTitleView || controller.navigationItem.titleView != placeholderTitleView;
    if (profileMissing || capsuleMissing || titleWasReplaced) NeoWCUpdateChatTopBar(controller);
    NeoWCApplyTransparentChatTopAppearance(controller);
    NeoWCApplyChatNavigationBackground(controller, YES);
}

static BOOL NeoWCJumpToReferencedMessage(CommonMessageCellView *cell) {
    if (!NeoWCEnhancementEnabled(NeoWCQuoteJumpEnabledKey)) return NO;
    id viewModel = NeoWCTweakValueForSelectorNames(cell, @[@"viewModel", @"_viewModel"]);
    id message = NeoWCImageJokerMessageForObject(cell);
    if (!message) {
        message = NeoWCTweakValueForSelectorNames(viewModel,
            @[@"messageWrap", @"getMessageWrap", @"getCurrentMessageWrap", @"msgWrap"]);
    }
    id referencedMessage = nil;
    for (id object in @[message ?: NSNull.null, viewModel ?: NSNull.null, cell]) {
        if (object == NSNull.null) continue;
        for (NSString *key in @[@"referHostMsg", @"referingMessageWrap", @"replyingMessageWrap"]) {
            referencedMessage = NeoWCTweakSafeValue(object, key);
            if (referencedMessage) break;
        }
        if (referencedMessage) break;
    }
    if (!referencedMessage) return NO;
    UIViewController *controller = NeoWCJokerPresenterForCell(cell) ?: NeoWCVisibleChatController;
    for (NSString *selectorName in @[@"returnToOriginalMsg:", @"locateToMsg:"]) {
        SEL selector = NSSelectorFromString(selectorName);
        if ([controller respondsToSelector:selector]) {
            ((void (*)(id, SEL, id))objc_msgSend)(controller, selector, referencedMessage);
            NeoWCCompatibilityMarkTriggered(@"quote-jump");
            return YES;
        }
    }
    if ([cell respondsToSelector:@selector(onReturnToOriginalMsg)]) {
        ((void (*)(id, SEL))objc_msgSend)(cell, @selector(onReturnToOriginalMsg));
        NeoWCCompatibilityMarkTriggered(@"quote-jump");
        return YES;
    }
    return NO;
}

static void NeoWCSetPinnedMessageDescendantBackgroundsClear(UIView *view,
                                                            UIVisualEffectView *blurView,
                                                            BOOL clear) {
    if (!view || view == blurView || [view isDescendantOfView:blurView]) return;
    id originalColor = objc_getAssociatedObject(view, &NeoWCChatPinnedOriginalBackgroundColorKey);
    if (clear) {
        if (!originalColor) {
            objc_setAssociatedObject(view, &NeoWCChatPinnedOriginalBackgroundColorKey,
                                     view.backgroundColor ?: NSNull.null,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        view.backgroundColor = UIColor.clearColor;
    } else if (originalColor) {
        view.backgroundColor = originalColor == NSNull.null ? nil : originalColor;
        objc_setAssociatedObject(view, &NeoWCChatPinnedOriginalBackgroundColorKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    for (UIView *subview in view.subviews) {
        NeoWCSetPinnedMessageDescendantBackgroundsClear(subview, blurView, clear);
    }
}

static void NeoWCUpdatePinnedMessageGlass(UIView *tipsView) {
    if (!tipsView) return;
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCChatTopBarCapsuleEnabledKey);
    UIVisualEffectView *blurView = objc_getAssociatedObject(tipsView, &NeoWCChatPinnedBlurViewKey);
    if (!enabled) {
        NeoWCSetPinnedMessageDescendantBackgroundsClear(tipsView, blurView, NO);
        NSNumber *shadowOpacity = objc_getAssociatedObject(tipsView, &NeoWCChatPinnedOriginalShadowOpacityKey);
        if (shadowOpacity) {
            tipsView.layer.shadowOpacity = shadowOpacity.floatValue;
            tipsView.layer.shadowRadius = [objc_getAssociatedObject(tipsView, &NeoWCChatPinnedOriginalShadowRadiusKey) doubleValue];
            tipsView.layer.shadowOffset = [objc_getAssociatedObject(tipsView, &NeoWCChatPinnedOriginalShadowOffsetKey) CGSizeValue];
            id shadowColor = objc_getAssociatedObject(tipsView, &NeoWCChatPinnedOriginalShadowColorKey);
            tipsView.layer.shadowColor = shadowColor == NSNull.null ? nil : (__bridge CGColorRef)shadowColor;
            tipsView.layer.borderWidth = [objc_getAssociatedObject(tipsView, &NeoWCChatPinnedOriginalBorderWidthKey) doubleValue];
            id borderColor = objc_getAssociatedObject(tipsView, &NeoWCChatPinnedOriginalBorderColorKey);
            tipsView.layer.borderColor = borderColor == NSNull.null ? nil : (__bridge CGColorRef)borderColor;
            objc_setAssociatedObject(tipsView, &NeoWCChatPinnedOriginalShadowOpacityKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [blurView removeFromSuperview];
        objc_setAssociatedObject(tipsView, &NeoWCChatPinnedBlurViewKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    if (!objc_getAssociatedObject(tipsView, &NeoWCChatPinnedOriginalShadowOpacityKey)) {
        objc_setAssociatedObject(tipsView, &NeoWCChatPinnedOriginalShadowOpacityKey, @(tipsView.layer.shadowOpacity), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(tipsView, &NeoWCChatPinnedOriginalShadowRadiusKey, @(tipsView.layer.shadowRadius), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(tipsView, &NeoWCChatPinnedOriginalShadowOffsetKey, [NSValue valueWithCGSize:tipsView.layer.shadowOffset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(tipsView, &NeoWCChatPinnedOriginalShadowColorKey, tipsView.layer.shadowColor ? (__bridge id)tipsView.layer.shadowColor : NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(tipsView, &NeoWCChatPinnedOriginalBorderWidthKey, @(tipsView.layer.borderWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(tipsView, &NeoWCChatPinnedOriginalBorderColorKey, tipsView.layer.borderColor ? (__bridge id)tipsView.layer.borderColor : NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    tipsView.layer.shadowOpacity = 0.0;
    tipsView.layer.shadowRadius = 0.0;
    tipsView.layer.shadowOffset = CGSizeZero;
    tipsView.layer.shadowColor = UIColor.clearColor.CGColor;
    tipsView.layer.borderWidth = 0.0;
    tipsView.layer.borderColor = UIColor.clearColor.CGColor;

    if (!blurView) {
        blurView = [[UIVisualEffectView alloc] initWithEffect:nil];
        blurView.userInteractionEnabled = NO;
        blurView.clipsToBounds = YES;
        blurView.layer.cornerRadius = 14.0;
        blurView.layer.cornerCurve = kCACornerCurveContinuous;
        objc_setAssociatedObject(blurView, &NeoWCChatTopGlassEffectMarkerKey,
                                 @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(tipsView, &NeoWCChatPinnedBlurViewKey,
                                 blurView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSNumber *appliedStyle = objc_getAssociatedObject(blurView, &NeoWCChatGlassAppliedStyleKey);
    NSNumber *desiredStyle = @(NeoWCChatTopEffectStyle());
    if (![appliedStyle isEqualToNumber:desiredStyle]) {
        blurView.effect = NeoWCChatTopVisualEffect();
        NeoWCConfigureChatTopGlassLayer(blurView);
        objc_setAssociatedObject(blurView, &NeoWCChatGlassAppliedStyleKey,
                                 desiredStyle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    blurView.frame = CGRectInset(tipsView.bounds, 8.0, 0.0);
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (blurView.superview != tipsView) {
        [tipsView insertSubview:blurView atIndex:0];
    } else {
        [tipsView sendSubviewToBack:blurView];
    }
    NeoWCSetPinnedMessageDescendantBackgroundsClear(tipsView, blurView, YES);
}

static char NeoWCRawContactIDKey;
static char NeoWCRawContactIDCellMarkerKey;

static NSUInteger NeoWCCallUnsignedSelector(id object, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!object || ![object respondsToSelector:selector]) return 0;
    @try {
        return ((NSUInteger (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        return 0;
    }
}

static id NeoWCTableSectionAtIndex(id tableInfo, NSUInteger index) {
    SEL selector = NSSelectorFromString(@"getSectionAt:");
    if (!tableInfo || ![tableInfo respondsToSelector:selector]) return nil;
    @try {
        return ((id (*)(id, SEL, NSUInteger))objc_msgSend)(tableInfo, selector, index);
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static id NeoWCTableCellAtIndex(id section, NSUInteger index) {
    for (NSString *name in @[@"getCellAt:", @"cellAtIndex:"]) {
        SEL selector = NSSelectorFromString(name);
        if (![section respondsToSelector:selector]) continue;
        @try {
            return ((id (*)(id, SEL, NSUInteger))objc_msgSend)(section, selector, index);
        } @catch (__unused NSException *exception) {
        }
    }
    NSArray *cells = NeoWCTweakValueForSelectorNames(section, @[@"cells", @"cellArray", @"m_arrCells"]);
    return [cells isKindOfClass:NSArray.class] && index < cells.count ? cells[index] : nil;
}

static NSUInteger NeoWCTableCellCount(id section) {
    for (NSString *name in @[@"getCellCount", @"cellCount"]) {
        SEL selector = NSSelectorFromString(name);
        if (![section respondsToSelector:selector]) continue;
        @try {
            return ((NSUInteger (*)(id, SEL))objc_msgSend)(section, selector);
        } @catch (__unused NSException *exception) {
        }
    }
    NSArray *cells = NeoWCTweakValueForSelectorNames(section, @[@"cells", @"cellArray", @"m_arrCells"]);
    return [cells isKindOfClass:NSArray.class] ? cells.count : 0;
}

static NSString *NeoWCTableCellTitle(id cell) {
    id title = NeoWCTweakValueForSelectorNames(cell, @[@"title", @"m_title", @"leftTitle", @"text"]);
    if ([title isKindOfClass:NSString.class]) return title;
    UILabel *label = NeoWCTweakValueForSelectorNames(cell, @[@"titleLabel", @"m_titleLabel", @"leftLabel"]);
    return [label isKindOfClass:UILabel.class] ? label.text : nil;
}

static BOOL NeoWCSectionContainsRawIDCell(id section, NSString *title) {
    NSUInteger count = NeoWCTableCellCount(section);
    for (NSUInteger index = 0; index < count; index++) {
        id cell = NeoWCTableCellAtIndex(section, index);
        if ([objc_getAssociatedObject(cell, &NeoWCRawContactIDCellMarkerKey) boolValue]) return YES;
        NSString *cellTitle = NeoWCTableCellTitle(cell);
        if ([cellTitle isEqualToString:title]) return YES;
    }
    return NO;
}

static id NeoWCCreateRawIDCell(id target, NSString *title, NSString *rawID) {
    Class cellClass = NSClassFromString(@"WCTableViewCellManager");
    SEL copyFactory = NSSelectorFromString(@"normalCellForSel:target:title:rightValue:canRightValueCopy:");
    SEL basicFactory = NSSelectorFromString(@"normalCellForSel:target:title:rightValue:");
    id cell = nil;
    if ([cellClass respondsToSelector:copyFactory]) {
        cell = ((id (*)(id, SEL, SEL, id, NSString *, NSString *, BOOL))objc_msgSend)(cellClass,
                                                                                     copyFactory,
                                                                                     @selector(neowc_copyRawContactID),
                                                                                     target,
                                                                                     title,
                                                                                     rawID,
                                                                                     YES);
    } else if ([cellClass respondsToSelector:basicFactory]) {
        cell = ((id (*)(id, SEL, SEL, id, NSString *, NSString *))objc_msgSend)(cellClass,
                                                                                basicFactory,
                                                                                @selector(neowc_copyRawContactID),
                                                                                target,
                                                                                title,
                                                                                rawID);
    }
    return cell;
}

static void NeoWCInjectRawIDCell(id controller, BOOL group) {
    if (!NeoWCEnhancementEnabled(NeoWCShowRawContactIDEnabledKey) || !controller) return;
    NSString *contactKey = group ? @"m_chatRoomContact" : @"m_contact";
    id contact = NeoWCTweakSafeValue(controller, contactKey);
    if (!contact) contact = NeoWCTweakValueForSelectorNames(controller, @[contactKey, @"contact", @"chatRoomContact"]);
    NSString *rawID = NeoWCTweakValueForSelectorNames(contact, @[@"m_nsUsrName", @"userName"]);
    if (![rawID isKindOfClass:NSString.class] || rawID.length == 0) return;

    id tableInfo = NeoWCTweakValueForSelectorNames(controller, @[@"m_tableViewInfo", @"tableViewInfo", @"m_tableViewMgr"]);
    NSUInteger sectionCount = NeoWCCallUnsignedSelector(tableInfo, @"getSectionCount");
    if (!tableInfo || sectionCount == 0) return;
    NSString *title = group ? @"原始群号码" : @"原始号码";
    id targetSection = nil;
    NSUInteger targetIndex = NSNotFound;
    for (NSUInteger sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++) {
        id section = NeoWCTableSectionAtIndex(tableInfo, sectionIndex);
        if (!section) continue;
        if (NeoWCSectionContainsRawIDCell(section, title)) return;
        NSUInteger cellCount = NeoWCTableCellCount(section);
        for (NSUInteger cellIndex = 0; cellIndex < cellCount; cellIndex++) {
            NSString *cellTitle = NeoWCTableCellTitle(NeoWCTableCellAtIndex(section, cellIndex));
            if ([cellTitle containsString:@"微信号"] || [cellTitle containsString:@"群聊名称"] ||
                [cellTitle containsString:@"朋友资料"]) {
                targetSection = section;
                targetIndex = cellIndex + 1;
            }
        }
    }
    if (!targetSection) {
        targetSection = NeoWCTableSectionAtIndex(tableInfo, MIN((NSUInteger)1, sectionCount - 1));
        targetIndex = NeoWCTableCellCount(targetSection);
    }
    id cell = NeoWCCreateRawIDCell(controller, title, rawID);
    if (!cell || !targetSection) return;
    objc_setAssociatedObject(cell, &NeoWCRawContactIDCellMarkerKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSUInteger count = NeoWCTableCellCount(targetSection);
    if (targetIndex == NSNotFound || targetIndex > count) targetIndex = count;
    SEL insertSelector = NSSelectorFromString(@"insertCell:At:");
    SEL addSelector = NSSelectorFromString(@"addCell:");
    if ([targetSection respondsToSelector:insertSelector]) {
        ((void (*)(id, SEL, id, NSUInteger))objc_msgSend)(targetSection, insertSelector, cell, targetIndex);
    } else if ([targetSection respondsToSelector:addSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(targetSection, addSelector, cell);
    } else {
        return;
    }
    objc_setAssociatedObject(controller, &NeoWCRawContactIDKey, rawID, OBJC_ASSOCIATION_COPY_NONATOMIC);
    NeoWCCompatibilityMarkTriggered(@"raw-contact-id");
}

static id NeoWCHomeObjectAtIndexPath(id target, NSArray<NSString *> *selectorNames, NSIndexPath *indexPath) {
    if (!target || !indexPath) return nil;
    for (NSString *selectorName in selectorNames) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![target respondsToSelector:selector]) continue;
        @try {
            id value = ((id (*)(id, SEL, NSIndexPath *))objc_msgSend)(target, selector, indexPath);
            if (value) return value;
        } @catch (__unused NSException *exception) {
        }
    }
    return nil;
}

static id NeoWCHomeSessionCellData(id owner, UITableView *tableView, NSIndexPath *indexPath) {
    // WeChatX uses these two native main-frame accessors. Reading through the
    // controller first avoids depending on a particular reused cell subclass.
    id data = NeoWCHomeObjectAtIndexPath(owner,
                                         @[@"getCellDataAtIndexPath:", @"getSessionInfoAtIndexPath:"],
                                         indexPath);
    if (data) return data;
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    data = NeoWCTweakValueForSelectorNames(cell, @[@"m_cellData", @"cellData", @"m_sessionInfo", @"sessionInfo"]);
    if (data) return data;
    id delegate = tableView.delegate;
    if (delegate && delegate != owner) {
        data = NeoWCHomeObjectAtIndexPath(delegate,
                                          @[@"getCellDataAtIndexPath:", @"getSessionInfoAtIndexPath:"],
                                          indexPath);
    }
    return data;
}

static NSString *NeoWCHomeSessionUserName(id data) {
    NSString *userName = NeoWCTweakValueForSelectorNames(data, @[@"m_nsUsrName", @"m_nsUserName", @"userName"]);
    if (userName.length == 0) {
        id sessionInfo = NeoWCTweakValueForSelectorNames(data, @[@"m_sessionInfo", @"sessionInfo"]);
        userName = NeoWCTweakValueForSelectorNames(sessionInfo, @[@"m_nsUsrName", @"m_nsUserName", @"userName"]);
    }
    return userName;
}

static BOOL NeoWCHomeBooleanValue(id object, NSArray<NSString *> *names) {
    for (NSString *name in names) {
        SEL selector = NSSelectorFromString(name);
        if ([object respondsToSelector:selector]) {
            @try { return ((BOOL (*)(id, SEL))objc_msgSend)(object, selector); }
            @catch (__unused NSException *exception) {}
        }
        id value = NeoWCTweakSafeValue(object, name);
        if ([value respondsToSelector:@selector(boolValue)]) return [value boolValue];
    }
    return NO;
}

static BOOL NeoWCHomeSessionMuted(id data) {
    if ([data respondsToSelector:NSSelectorFromString(@"isSilent")]) {
        return NeoWCHomeBooleanValue(data, @[@"isSilent"]);
    }
    if ([data respondsToSelector:NSSelectorFromString(@"isChatStatusNotifyOpen")]) {
        return !NeoWCHomeBooleanValue(data, @[@"isChatStatusNotifyOpen"]);
    }
    return NeoWCHomeBooleanValue(data, @[@"m_bIsSilent", @"m_isSilent"]);
}

static void NeoWCPushHomeController(id owner, id controller) {
    if (![owner isKindOfClass:UIViewController.class] || ![controller isKindOfClass:UIViewController.class]) return;
    UIViewController *presenter = owner;
    UINavigationController *navigationController = presenter.navigationController;
    if (navigationController) [navigationController pushViewController:controller animated:YES];
    else [presenter presentViewController:controller animated:YES completion:nil];
}

static void NeoWCOpenHomeRemark(id owner, id contact, BOOL group) {
    Class controllerClass = NSClassFromString(group ? @"ChatRoomRemarkEditViewController" : @"NewRemarkViewController");
    id controller = controllerClass ? [controllerClass new] : nil;
    if (!controller) return;
    NeoWCTweakSetValue(controller, group ? @"chatRoomContact" : @"m_contact", contact);
    NeoWCTweakSetValue(controller, group ? @"m_chatRoomContact" : @"contact", contact);
    SEL editSelector = NSSelectorFromString(@"setNeedEditState:");
    if ([controller respondsToSelector:editSelector]) ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, editSelector, YES);
    NeoWCPushHomeController(owner, controller);
}

static void NeoWCOpenHomeMoments(id owner, id contact) {
    Class controllerClass = NSClassFromString(@"WCListViewController");
    id controller = controllerClass ? [controllerClass new] : nil;
    if (!controller) return;
    NeoWCTweakSetValue(controller, @"m_contact", contact);
    NeoWCPushHomeController(owner, controller);
}

static id NeoWCHomeSessionInfoController(id contact, BOOL group) {
    Class controllerClass = NSClassFromString(group ? @"ChatRoomInfoViewController" : @"AddContactToChatRoomViewController");
    id controller = controllerClass ? [controllerClass new] : nil;
    if (!controller) return nil;
    NeoWCTweakSetValue(controller, group ? @"m_chatRoomContact" : @"m_contact", contact);
    return controller;
}

static void NeoWCCommitHomeSessionToggle(id contact, BOOL group, NSString *selectorName, BOOL enabled) {
    id controller = NeoWCHomeSessionInfoController(contact, group);
    SEL selector = NSSelectorFromString(selectorName);
    if (!controller || ![controller respondsToSelector:selector]) return;
    @try {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, selector, enabled);
        SEL willDisappear = @selector(viewWillDisappear:);
        SEL didDisappear = @selector(viewDidDisappear:);
        if ([controller respondsToSelector:willDisappear]) ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, willDisappear, YES);
        if ([controller respondsToSelector:didDisappear]) ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, didDisappear, YES);
    } @catch (__unused NSException *exception) {
    }
}

typedef UISwipeActionsConfiguration *(*NeoWCHomeLeadingSwipeIMP)(id, SEL, UITableView *, NSIndexPath *);
static NeoWCHomeLeadingSwipeIMP NeoWCOriginalHomeLeadingSwipe;

static UISwipeActionsConfiguration *NeoWCHomeLeadingSwipe(id owner, SEL selector,
                                                           UITableView *tableView,
                                                           NSIndexPath *indexPath) {
    if (!NeoWCEnhancementEnabled(NeoWCHomeSwipeActionsEnabledKey)) {
        return NeoWCOriginalHomeLeadingSwipe ? NeoWCOriginalHomeLeadingSwipe(owner, selector, tableView, indexPath) : nil;
    }
    id data = NeoWCHomeSessionCellData(owner, tableView, indexPath);
    NSString *userName = NeoWCHomeSessionUserName(data);
    if (userName.length == 0 || [userName isEqualToString:@"filehelper"] || [userName hasPrefix:@"gh_"]) {
        if (userName.length == 0) {
            NeoWCLog(@"主页右滑：未取得会话数据，owner=%@ delegate=%@ row=%ld",
                     NSStringFromClass([owner class]),
                     NSStringFromClass([tableView.delegate class]),
                     (long)indexPath.row);
        }
        return NeoWCOriginalHomeLeadingSwipe ? NeoWCOriginalHomeLeadingSwipe(owner, selector, tableView, indexPath) : nil;
    }
    id contact = NeoWCContactForUserName(userName) ?: data;
    BOOL group = [userName hasSuffix:@"@chatroom"];
    id sessionInfo = NeoWCTweakValueForSelectorNames(data, @[@"m_sessionInfo", @"sessionInfo"]) ?: data;
    BOOL muted = NeoWCHomeSessionMuted(data);
    BOOL top = NeoWCHomeBooleanValue(sessionInfo, @[@"m_bIsTop", @"isTop"]);
    __weak UITableView *weakTableView = tableView;

    UIContextualAction *remark = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                          title:@"备注"
                                                                        handler:^(__unused UIContextualAction *action,
                                                                                  __unused UIView *sourceView,
                                                                                  void (^completionHandler)(BOOL)) {
        NeoWCOpenHomeRemark(owner, contact, group);
        completionHandler(YES);
    }];
    remark.backgroundColor = UIColor.systemGrayColor;

    UIContextualAction *mute = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                        title:muted ? @"取消勿扰" : @"勿扰"
                                                                      handler:^(__unused UIContextualAction *action,
                                                                                __unused UIView *sourceView,
                                                                                void (^completionHandler)(BOOL)) {
        NeoWCCommitHomeSessionToggle(contact, group, @"setUpdateNotifyMuted:", !muted);
        [weakTableView reloadData];
        completionHandler(YES);
    }];
    mute.backgroundColor = UIColor.systemOrangeColor;

    UIContextualAction *pin = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                       title:top ? @"取消置顶" : @"置顶"
                                                                     handler:^(__unused UIContextualAction *action,
                                                                               __unused UIView *sourceView,
                                                                               void (^completionHandler)(BOOL)) {
        NeoWCCommitHomeSessionToggle(contact, group, @"onTopSession:", !top);
        [weakTableView reloadData];
        completionHandler(YES);
    }];
    pin.backgroundColor = UIColor.systemBlueColor;

    NSMutableArray<UIContextualAction *> *actions = [NSMutableArray arrayWithObjects:remark, mute, pin, nil];
    if (group) {
        UIContextualAction *fold = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                             title:@"折叠群聊"
                                                                           handler:^(__unused UIContextualAction *action,
                                                                                     __unused UIView *sourceView,
                                                                                     void (^completionHandler)(BOOL)) {
            NeoWCCommitHomeSessionToggle(contact, YES, @"setChatBoxStatus:", YES);
            [weakTableView reloadData];
            completionHandler(YES);
        }];
        fold.backgroundColor = UIColor.systemPurpleColor;
        [actions insertObject:fold atIndex:1];
    } else {
        UIContextualAction *moments = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                               title:@"朋友圈"
                                                                             handler:^(__unused UIContextualAction *action,
                                                                                       __unused UIView *sourceView,
                                                                                       void (^completionHandler)(BOOL)) {
            NeoWCOpenHomeMoments(owner, contact);
            completionHandler(YES);
        }];
        moments.backgroundColor = UIColor.systemGreenColor;
        [actions insertObject:moments atIndex:1];
    }
    NeoWCCompatibilityMarkTriggered(@"home-swipe-actions");
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:actions];
    configuration.performsFirstActionWithFullSwipe = NO;
    return configuration;
}

static BOOL NeoWCHomeLeadingSwipeInstalled;

static void NeoWCTryInstallHomeLeadingSwipe(void) {
    if (NeoWCHomeLeadingSwipeInstalled) return;
    Class controllerClass = objc_getClass("NewMainFrameViewController");
    SEL selector = NSSelectorFromString(@"tableView:leadingSwipeActionsConfigurationForRowAtIndexPath:");
    if (!controllerClass) return;
    Method method = class_getInstanceMethod(controllerClass, selector);
    const char *types = "@@:@@";
    if (method) {
        NeoWCOriginalHomeLeadingSwipe = (NeoWCHomeLeadingSwipeIMP)method_getImplementation(method);
        if (NeoWCOriginalHomeLeadingSwipe == NeoWCHomeLeadingSwipe) {
            NeoWCHomeLeadingSwipeInstalled = YES;
            return;
        }
        types = method_getTypeEncoding(method) ?: types;
    }
    // class_addMethod also handles an inherited implementation without mutating
    // the superclass. Only replace directly when this class already owns it.
    if (class_addMethod(controllerClass, selector, (IMP)NeoWCHomeLeadingSwipe, types)) {
        NeoWCHomeLeadingSwipeInstalled = YES;
        return;
    }
    Method ownedMethod = class_getInstanceMethod(controllerClass, selector);
    if (!ownedMethod) return;
    method_setImplementation(ownedMethod, (IMP)NeoWCHomeLeadingSwipe);
    NeoWCHomeLeadingSwipeInstalled = YES;
}

__attribute__((constructor)) static void NeoWCInstallHomeLeadingSwipe(void) {
    NeoWCTryInstallHomeLeadingSwipe();
    dispatch_async(dispatch_get_main_queue(), ^{
        NeoWCTryInstallHomeLeadingSwipe();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NeoWCTryInstallHomeLeadingSwipe();
    });
    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification
                                                    object:nil
                                                     queue:NSOperationQueue.mainQueue
                                                usingBlock:^(__unused NSNotification *note) {
        NeoWCTryInstallHomeLeadingSwipe();
    }];
}

%hook WeixinContactInfoAssist

- (void)initData {
    %orig;
    NeoWCInjectRawIDCell(self, NO);
}

- (void)reloadTableView {
    %orig;
    NeoWCInjectRawIDCell(self, NO);
}

%new
- (void)neowc_copyRawContactID {
    NSString *rawID = objc_getAssociatedObject(self, &NeoWCRawContactIDKey);
    if (rawID.length > 0) UIPasteboard.generalPasteboard.string = rawID;
}

%end

%hook ChatRoomInfoViewController

- (void)initData {
    %orig;
    NeoWCInjectRawIDCell(self, YES);
}

- (void)reloadTableData {
    %orig;
    NeoWCInjectRawIDCell(self, YES);
}

- (void)reloadProfileTableData {
    %orig;
    NeoWCInjectRawIDCell(self, YES);
}

%new
- (void)neowc_copyRawContactID {
    NSString *rawID = objc_getAssociatedObject(self, &NeoWCRawContactIDKey);
    if (rawID.length > 0) UIPasteboard.generalPasteboard.string = rawID;
}

%end

%hook SessionSelectController

- (void)setMaxSelectionCount:(NSUInteger)count {
    if (NeoWCEnhancementEnabled(NeoWCMultiSelectLimitEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"multi-select-limit");
    }
    %orig(NeoWCEnhancementEnabled(NeoWCMultiSelectLimitEnabledKey) ? 999 : count);
}

- (BOOL)ignoreMaxSelectionLimit {
    if (NeoWCEnhancementEnabled(NeoWCMultiSelectLimitEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"multi-select-limit");
        return YES;
    }
    return %orig;
}

%end

%hook ShortVideoToolbar

- (CGFloat)sightCaptureMaxDuration {
    if (NeoWCEnhancementEnabled(NeoWCMultiSelectLimitEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"multi-select-limit");
        return 999.0;
    }
    return %orig;
}

%end

%hook MMMsgCommonTipsView

- (void)layoutSubviews {
    %orig;
    NeoWCUpdatePinnedMessageGlass((UIView *)self);
}

%end

%hook BaseMsgContentViewController

- (NSUInteger)uiMultiSelectMaxCount {
    if (NeoWCEnhancementEnabled(NeoWCMultiSelectLimitEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"multi-select-limit");
        return 9999;
    }
    return %orig;
}

- (NSUInteger)getMultiSelectMaxCount {
    if (NeoWCEnhancementEnabled(NeoWCMultiSelectLimitEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"multi-select-limit");
        return 9999;
    }
    return %orig;
}

- (void)viewDidLoad {
    %orig;
    NeoWCUpdateChatTopBar(self);
}

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    NeoWCVisibleChatController = self;
    NeoWCUpdateChatTopBar(self);
}

- (void)updateTitleView:(id)titleView {
    BOOL typingChanged = NeoWCSetChatTypingState(self, titleView);
    %orig(titleView);
    if (typingChanged) NeoWCUpdateChatTopBar(self);
    else NeoWCRefreshChatTopBarAfterWechatUpdate(self);
}

- (void)updateTitleView:(id)titleView ignoreAnimation:(BOOL)ignoreAnimation {
    BOOL typingChanged = NeoWCSetChatTypingState(self, titleView);
    %orig(titleView, ignoreAnimation);
    if (typingChanged) NeoWCUpdateChatTopBar(self);
    else NeoWCRefreshChatTopBarAfterWechatUpdate(self);
}

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

- (void)viewWillDisappear:(BOOL)animated {
    %orig(animated);
    NeoWCRestoreChatNavigationPresentation(self);
    UIViewController *controller = (UIViewController *)self;
    if (controller.isMovingFromParentViewController || controller.isBeingDismissed) {
        NeoWCClearImageJokerOverrides();
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    NeoWCVisibleChatController = self;
    __weak UIViewController *weakController = (UIViewController *)self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *controller = weakController;
        if (controller.view.window) NeoWCRefreshVisibleAntiRevokeCells();
    });
}

- (void)viewDidLayoutSubviews {
    %orig;
    NeoWCRefreshChatTopBarAfterWechatUpdate(self);
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig(animated);
    if (NeoWCVisibleChatController == self) NeoWCVisibleChatController = nil;
}

- (void)dealloc {
    NeoWCClearImageJokerOverrides();
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

%hook BaseMessageCellView

- (NSArray *)filteredMenuItems:(NSArray *)items {
    NSArray *filteredItems = %orig(items);
    if (NeoWCEnhancementEnabled(NeoWCLongPressMenuEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"long-press-menu");
    }
    return NeoWCManagedLongPressMenuItems(filteredItems);
}

%end

%hook EmoticonPreviewWindowViewController

- (void)viewDidLoad {
    %orig;
    if (!NeoWCEnhancementEnabled(NeoWCEmoticonToSelfieEnabledKey) ||
        [objc_getAssociatedObject(self, &NeoWCEmoticonPreviewLongPressKey) boolValue]) return;
    id popoverView = NeoWCTweakValueForSelectorNames(self, @[@"popoverView"]);
    SEL addSelector = NSSelectorFromString(@"addLongPressTarget:action:");
    if (![popoverView respondsToSelector:addSelector]) return;
    ((void (*)(id, SEL, id, SEL))objc_msgSend)(popoverView, addSelector, self,
        NSSelectorFromString(@"neowc_handleEmoticonToSelfie:"));
    objc_setAssociatedObject(self, &NeoWCEmoticonPreviewLongPressKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (void)neowc_handleEmoticonToSelfie:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan ||
        !NeoWCEnhancementEnabled(NeoWCEmoticonToSelfieEnabledKey)) return;
    if (NeoWCSaveDataAsSelfieEmoticon(NeoWCPreviewEmoticonData(self))) {
        NeoWCLog(@"表情已提交到自拍表情添加流程");
    }
}

%end

%hook EmoticonMessageCellView

- (NSArray *)filteredMenuItems:(NSArray *)items {
    return NeoWCMenuItemsWithEmoticonToSelfie(self, %orig(items), @"CExtendInfoOfEmoticon");
}

%new
- (void)neowc_saveEmoticonAsSelfie {
    if (NeoWCEnhancementEnabled(NeoWCEmoticonToSelfieEnabledKey)) {
        (void)NeoWCSaveCellEmoticonAsSelfie(self, @"CExtendInfoOfEmoticon", YES);
    }
}

%end

%hook AppEmoticonMessageCellView

- (NSArray *)filteredMenuItems:(NSArray *)items {
    return NeoWCMenuItemsWithEmoticonToSelfie(self, %orig(items), @"CExtendInfoOfAPP");
}

%new
- (void)neowc_saveEmoticonAsSelfie {
    if (NeoWCEnhancementEnabled(NeoWCEmoticonToSelfieEnabledKey)) {
        (void)NeoWCSaveCellEmoticonAsSelfie(self, @"CExtendInfoOfAPP", NO);
    }
}

%end

%hook ImageMessageCellView

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    return NeoWCOperationMenuItemsWithImageJoker(self, items);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(joker_handleImageMenuItem:)) {
        return NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey) && NeoWCMessageWrapForCell(self) != nil;
    }
    return %orig;
}

- (id)getCoverImage {
    UIImage *image = NeoWCImageJokerImageForMessage(NeoWCMessageWrapForCell(self));
    return image ?: %orig;
}

- (id)displayViewForImageBrowser {
    id displayView = %orig;
    UIImage *image = NeoWCImageJokerImageForMessage(NeoWCMessageWrapForCell(self));
    SEL imageSelector = NSSelectorFromString(@"setImage:");
    if (image && [displayView respondsToSelector:imageSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(displayView, imageSelector, image);
    }
    return displayView;
}

- (void)layoutContentView {
    %orig;
    UIImage *image = NeoWCImageJokerImageForMessage(NeoWCMessageWrapForCell(self));
    id imageView = NeoWCTweakSafeValue(self, @"m_imageView");
    if (image && [imageView isKindOfClass:[UIImageView class]]) ((UIImageView *)imageView).image = image;
}

%new
- (void)joker_handleImageMenuItem:(id)sender {
    (void)sender;
    NeoWCPresentImageJokerPickerForCell(self);
}

%end

%hook ImageMessageViewModel

- (UIImage *)thumbImage {
    UIImage *image = NeoWCImageJokerImageForObject(self);
    return image ?: %orig;
}

- (UIImage *)maskedThumbImage {
    UIImage *image = NeoWCImageJokerImageForObject(self);
    return image ?: %orig;
}

- (NSData *)imageData {
    NSData *data = NeoWCImageJokerDataForMessage(NeoWCImageJokerMessageForObject(self));
    return data ?: %orig;
}

- (BOOL)isImageExists {
    return NeoWCImageJokerImageForObject(self) ? YES : %orig;
}

- (CGSize)thumbImageSize {
    UIImage *image = NeoWCImageJokerImageForObject(self);
    if (!image) return %orig;
    CGSize displaySize = NeoWCImageJokerDisplaySize(image);
    if (CGSizeEqualToSize(displaySize, CGSizeZero)) return %orig;
    return displaySize;
}

- (CGSize)measureContentViewSize:(CGSize)size {
    UIImage *image = NeoWCImageJokerImageForObject(self);
    if (!image) return %orig(size);
    CGSize displaySize = NeoWCImageJokerDisplaySize(image);
    if (CGSizeEqualToSize(displaySize, CGSizeZero)) return %orig(size);
    return displaySize;
}

%end

%hook MMImgDataItem_Message

- (NSData *)imageData {
    NSData *data = NeoWCImageJokerDataForMessage(NeoWCImageJokerMessageForObject(self));
    return data ?: %orig;
}

- (UIImage *)image {
    UIImage *image = NeoWCImageJokerImageForObject(self);
    return image ?: %orig;
}

- (UIImage *)hdImage {
    UIImage *image = NeoWCImageJokerImageForObject(self);
    return image ?: %orig;
}

- (NSString *)imagePath {
    NSString *path = NeoWCImageJokerPathForMessage(NeoWCImageJokerMessageForObject(self));
    return path ?: %orig;
}

- (NSString *)hdImagePath {
    NSString *path = NeoWCImageJokerPathForMessage(NeoWCImageJokerMessageForObject(self));
    return path ?: %orig;
}

- (BOOL)isHDImage {
    return NeoWCImageJokerImageForObject(self) ? YES : %orig;
}

- (CGSize)hdImageSize {
    UIImage *image = NeoWCImageJokerImageForObject(self);
    return image ? image.size : %orig;
}

%end

%hook CMessageWrap

+ (NSString *)getJpgPathOfMsgMiddleImg:(id)message {
    return NeoWCImageJokerPathForMessage(message) ?: %orig(message);
}

+ (NSString *)getJpgPathOfMsgHDImg:(id)message {
    return NeoWCImageJokerPathForMessage(message) ?: %orig(message);
}

+ (NSString *)getJpgPathOfMsgHdOrMiddleImg:(id)message {
    return NeoWCImageJokerPathForMessage(message) ?: %orig(message);
}

+ (NSString *)getPathOfMsgImg:(id)message {
    return NeoWCImageJokerPathForMessage(message) ?: %orig(message);
}

+ (UIImage *)getMsgMiddleImg:(id)message {
    return NeoWCImageJokerImageForMessage(message) ?: %orig(message);
}

+ (UIImage *)getMsgHDImg:(id)message {
    return NeoWCImageJokerImageForMessage(message) ?: %orig(message);
}

+ (UIImage *)getMsgHdOrMiddleImg:(id)message {
    return NeoWCImageJokerImageForMessage(message) ?: %orig(message);
}

+ (NSData *)getMsgMiddleImgData:(id)message {
    return NeoWCImageJokerDataForMessage(message) ?: %orig(message);
}

+ (NSData *)getMsgMiddleImgData:(id)message canUseHeif:(BOOL)canUseHeif {
    return NeoWCImageJokerDataForMessage(message) ?: %orig(message, canUseHeif);
}

+ (NSData *)getMsgHDImgData:(id)message {
    return NeoWCImageJokerDataForMessage(message) ?: %orig(message);
}

+ (NSData *)getMsgHdOrMiddleImgData:(id)message {
    return NeoWCImageJokerDataForMessage(message) ?: %orig(message);
}

+ (NSData *)getMsgHdOrMiddleImgData:(id)message canUseHeif:(BOOL)canUseHeif {
    return NeoWCImageJokerDataForMessage(message) ?: %orig(message, canUseHeif);
}

%end

%hook UploadVoiceWrap

- (void)setM_uiVoiceForwardFlag:(unsigned int)forwardFlag {
    %orig(NeoWCVoiceRepeatUploadIsActive() ? 1 : forwardFlag);
}

%end

%hook UploadVoiceRequest

- (void)setForwardFlag:(unsigned int)forwardFlag {
    %orig(NeoWCVoiceRepeatUploadIsActive() ? 1 : forwardFlag);
}

%end

%hook TextMessageCellView

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    return NeoWCOperationMenuItemsWithJoker(self, items, NO);
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
    NeoWCPresentJokerEditorForCell(self, NO);
}

%end

%hook AppMessageCellView

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    return NeoWCOperationMenuItemsWithJoker(self, items, NO);
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
    NeoWCPresentJokerEditorForCell(self, NO);
}

%end

%hook WCPayTransferMessageCellView

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    return NeoWCOperationMenuItemsWithJoker(self, items, YES);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(joker_handleMenuItem:)) {
        return NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey);
    }
    return %orig;
}

%new
- (void)joker_handleMenuItem:(id)sender {
    NeoWCCompatibilityMarkTriggered(@"chat-joker");
    NeoWCPresentJokerEditorForCell(self, YES);
}

%end

%hook WCTimeLineCellView

- (void)layoutSubviews {
    %orig;
    NeoWCSynchronizeMomentsForwardButton(self);
}

- (void)editBlackList {
    if (!NeoWCEnhancementEnabled(NeoWCMomentsQuickPermissionsKey)) {
        %orig;
        return;
    }
    id dataItem = NeoWCMomentsValueForExactSelector(self, @"m_dataItem");
    if (NeoWCMomentsUserNameForDataItem(dataItem).length == 0) {
        %orig;
        return;
    }
    NeoWCCompatibilityMarkTriggered(@"moments-quick-permissions");
    NeoWCPendingMomentsPermissionDataItem = dataItem;
    %orig;
    id capturedDataItem = dataItem;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (NeoWCPendingMomentsPermissionDataItem == capturedDataItem) NeoWCPendingMomentsPermissionDataItem = nil;
    });
}

- (void)initTimeLabel {
    %orig;
    NeoWCApplyMomentsPreciseTime(self, YES);
}

- (void)updateWithDataItem:(id)dataItem actionAreaVM:(id)actionAreaVM {
    %orig(dataItem, actionAreaVM);
    NeoWCCompatibilityMarkTriggered(@"moments-precise-time");
    NeoWCApplyMomentsPreciseTime(self, YES);
    NeoWCSynchronizeMomentsForwardButton(self);
}

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
    } else {
        id operateButton = NeoWCMomentsObjectForSelector(self, @"m_operateBtn");
        if ([operateButton isKindOfClass:[UIView class]]) {
            for (UIView *subview in [(UIView *)operateButton subviews]) {
                if ([subview isKindOfClass:[UIImageView class]]) subview.hidden = NO;
            }
        }
    }
}

- (void)didMoveToWindow {
    %orig;
    NeoWCSynchronizeMomentsCell(self);
    NeoWCSynchronizeMomentsForwardButton(self);
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

%new
- (void)neowc_handleMomentsForward:(id)sender {
    (void)sender;
    id dataItem = NeoWCMomentsObjectForName(self, @"m_dataItem");
    UIViewController *presenter = NeoWCJokerPresenterForCell(self);
    if (!NeoWCMomentCanForward(dataItem) || !presenter) return;
    NeoWCForwardMoment(dataItem, presenter);
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
        NeoWCMomentsDispatchingQuickComment = YES;
        @try {
            %orig;
        } @finally {
            NeoWCMomentsDispatchingQuickComment = NO;
        }
        return;
    }
    %orig;
}

%end

%hook WCOperateFloatView

- (void)layoutSubviews {
    %orig;
    NeoWCApplyMomentsFloatMenuSnapshot(self);
}

- (void)showWithItemData:(id)item tipPoint:(CGPoint)tipPoint {
    NeoWCRestoreMomentsFloatMenu(self);
    objc_setAssociatedObject(self, &NeoWCMomentsFloatSnapshotKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &NeoWCMomentsFloatDataItemKey, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (NeoWCMomentsDispatchingQuickComment) {
        BOOL animationsEnabled = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        @try {
            %orig(item, tipPoint);
            if (!NeoWCTriggerNativeMomentsComment(self)) [self hide];
        } @finally {
            [UIView setAnimationsEnabled:animationsEnabled];
        }
        return;
    }
    %orig(item, tipPoint);
    NeoWCPrepareMomentsFloatMenu(self);
}

- (void)hide {
    UIButton *button = objc_getAssociatedObject(self, &NeoWCMomentsFloatForwardButtonKey);
    button.hidden = YES;
    NeoWCRestoreMomentsFloatMenu(self);
    %orig;
}

%new
- (void)neowc_handleMomentsForward:(id)sender {
    (void)sender;
    id dataItem = objc_getAssociatedObject(self, &NeoWCMomentsFloatDataItemKey);
    UIViewController *presenter = NeoWCJokerPresenterForCell(self);
    if (!dataItem || !presenter) return;
    [self hide];
    NeoWCForwardMoment(dataItem, presenter);
}

%end

%hook MMThemeManager

- (id)getValueOfProperty:(id)property inRuleSet:(id)ruleSet {
    id value = %orig(property, ruleSet);
    return NeoWCScaledThemeValue(value, property, ruleSet);
}

- (id)getValueOfProperty:(id)property inRuleSet:(id)ruleSet isAdapt:(BOOL)isAdapt {
    id value = %orig(property, ruleSet, isAdapt);
    return NeoWCScaledThemeValue(value, property, ruleSet);
}

%end

%hook CLocalInfo

- (unsigned int)m_uiGlobalFontLevel {
    unsigned int value = %orig;
    return NeoWCEnhancementEnabled(NeoWCPageScaleEnabledKey) ? 1 : value;
}

- (unsigned int)m_uiWebviewFontLevel {
    unsigned int value = %orig;
    return NeoWCEnhancementEnabled(NeoWCPageScaleEnabledKey) ? 1 : value;
}

%end

%hook WKWebView

- (id)initWithFrame:(CGRect)frame configuration:(id)configuration {
    id webView = %orig(frame, configuration);
    NeoWCApplyWebViewTextScale(webView);
    return webView;
}

- (void)didMoveToWindow {
    %orig;
    NeoWCApplyWebViewTextScale(self);
}

- (void)_setTextZoomFactor:(CGFloat)factor {
    if (NeoWCEnhancementEnabled(NeoWCPageScaleEnabledKey)) {
        factor = NeoWCGlobalPageScaleFactor();
        NeoWCCompatibilityMarkTriggered(@"page-scale");
    }
    %orig(factor);
}

%end

%hook WAThemeProxy

+ (id)getValueOfProperty:(id)property inRuleSet:(id)ruleSet {
    id value = %orig(property, ruleSet);
    return NeoWCScaledThemeValue(value, property, ruleSet);
}

%end

%hook CMessageMgr

- (void)AsyncOnAddMsg:(NSString *)sessionUserName MsgWrap:(CMessageWrap *)wrap {
    if (NeoWCShouldBlockIncomingMessage(sessionUserName, wrap)) {
        NeoWCCompatibilityMarkTriggered(@"message-block");
        return;
    }
    %orig;
}

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

%hook CContactMgr

- (id)getSelfContact {
    id contact = %orig;
    NeoWCUpdateCachedCurrentUserContact(contact);
    return contact;
}

- (void)printContactImportantChangeData:(id)newContact oldContact:(id)oldContact {
    id snapshot = NeoWCCaptureGroupMemberChange(newContact, oldContact);
    if (snapshot) NeoWCCompatibilityMarkTriggered(@"group-member-reminder");
    %orig;
    if (snapshot) NeoWCCompleteGroupMemberChange(snapshot, self, newContact);
}

%end

%hook WCDeviceStepObject

- (unsigned int)m7StepCount {
    static dispatch_once_t compatibilityOnce;
    dispatch_once(&compatibilityOnce, ^{ NeoWCCompatibilityMarkTriggered(@"steps"); });
    unsigned int originalValue = %orig;
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    return configuredValue > 0 ? configuredValue : originalValue;
}

- (unsigned int)hkStepCount {
    unsigned int originalValue = %orig;
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    return configuredValue > 0 ? configuredValue : originalValue;
}

- (void)setM7StepCount:(unsigned int)value {
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    %orig(configuredValue > 0 ? configuredValue : value);
}

- (void)setHkStepCount:(unsigned int)value {
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    %orig(configuredValue > 0 ? configuredValue : value);
}

%end

%hook UploadDeviceStepReq

- (unsigned int)stepCount {
    static dispatch_once_t compatibilityOnce;
    dispatch_once(&compatibilityOnce, ^{ NeoWCCompatibilityMarkTriggered(@"steps-upload"); });
    unsigned int originalValue = %orig;
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    return configuredValue > 0 ? configuredValue : originalValue;
}

- (unsigned int)m7StepCount {
    unsigned int originalValue = %orig;
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    return configuredValue > 0 ? configuredValue : originalValue;
}

- (unsigned int)hkStepCount {
    unsigned int originalValue = %orig;
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    return configuredValue > 0 ? configuredValue : originalValue;
}

- (void)setStepCount:(unsigned int)value {
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    %orig(configuredValue > 0 ? configuredValue : value);
}

- (void)setM7StepCount:(unsigned int)value {
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    %orig(configuredValue > 0 ? configuredValue : value);
}

- (void)setHkStepCount:(unsigned int)value {
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    %orig(configuredValue > 0 ? configuredValue : value);
}

%end

static id NeoWCDirectMessageForViewModel(id viewModel) {
    if (!viewModel) return nil;
    for (NSString *key in @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap"]) {
        id message = NeoWCTweakSafeValue(viewModel, key);
        if (message) return message;
    }
    return nil;
}

static id NeoWCMessageForCellViewModel(id viewModel) {
    id message = NeoWCDirectMessageForViewModel(viewModel);
    if (message) return message;

    id parentModel = NeoWCTweakSafeValue(viewModel, @"parentModel");
    message = NeoWCDirectMessageForViewModel(parentModel);
    if (message) return message;
    return nil;
}

%hook CommonMessageCellView

- (void)setViewModel:(id)viewModel {
    %orig;
    NeoWCHideMessageTimeLabels(self);
    NeoWCScheduleMessageTimeRefresh(self);
    NeoWCSynchronizeReplyGesture(self);
    [self neowc_scheduleAntiRevokeSidePromptRefresh];
}

- (void)updateStatus {
    %orig;
    NeoWCScheduleMessageTimeRefresh(self);
    [self neowc_scheduleAntiRevokeSidePromptRefresh];
}

- (void)updateNodeStatus {
    %orig;
    NeoWCScheduleMessageTimeRefresh(self);
    [self neowc_scheduleAntiRevokeSidePromptRefresh];
}

- (void)didMoveToWindow {
    %orig;
    NeoWCSynchronizeReplyGesture(self);
    if (self.window) {
        NeoWCScheduleMessageTimeRefresh(self);
        [self neowc_scheduleAntiRevokeSidePromptRefresh];
    } else {
        NeoWCHideMessageTimeLabels(self);
        UILabel *label = objc_getAssociatedObject(self, &NeoWCAntiRevokeSideLabelKey);
        if (label && !label.hidden) label.hidden = YES;
    }
}

- (void)handleTapReferMessage {
    if (NeoWCJumpToReferencedMessage(self)) return;
    %orig;
}

- (void)handleTapForReferMsg:(id)sender {
    if (NeoWCJumpToReferencedMessage(self)) return;
    %orig(sender);
}

%new
- (void)neowc_handleReplyPan:(UIPanGestureRecognizer *)recognizer {
    if (!NeoWCEnhancementEnabled(NeoWCReplySwipeEnabledKey)) return;
    CGPoint translation = [recognizer translationInView:self];
    CGPoint velocity = [recognizer velocityInView:self];
    CGFloat triggerDistance = NeoWCReplySwipeTriggerDistance();

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        BOOL rightward = velocity.x > 0.0;
        if (NeoWCMessageSwipeAction(self, rightward) == NeoWCReplySwipeActionNone) return;
        objc_setAssociatedObject(self, &NeoWCReplyPanRightwardKey, @(rightward), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self,
                                 &NeoWCReplyOriginalTransformKey,
                                 [NSValue valueWithCGAffineTransform:self.transform],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [feedback prepare];
        objc_setAssociatedObject(self, &NeoWCReplyFeedbackGeneratorKey, feedback, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, &NeoWCReplyFeedbackTriggeredKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    NSValue *originalTransformValue = objc_getAssociatedObject(self, &NeoWCReplyOriginalTransformKey);
    CGAffineTransform originalTransform = originalTransformValue
        ? originalTransformValue.CGAffineTransformValue
        : CGAffineTransformIdentity;
    BOOL rightward = [objc_getAssociatedObject(self, &NeoWCReplyPanRightwardKey) boolValue];

    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat distance = MAX(0.0, rightward ? translation.x : -translation.x);
        if (distance > triggerDistance) {
            distance = triggerDistance + MIN(10.0, (distance - triggerDistance) * 0.18);
        }
        self.transform = CGAffineTransformTranslate(originalTransform, rightward ? distance : -distance, 0.0);
        if (distance >= triggerDistance &&
            ![objc_getAssociatedObject(self, &NeoWCReplyFeedbackTriggeredKey) boolValue]) {
            UIImpactFeedbackGenerator *feedback = objc_getAssociatedObject(self, &NeoWCReplyFeedbackGeneratorKey);
            [feedback impactOccurred];
            objc_setAssociatedObject(self, &NeoWCReplyFeedbackTriggeredKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return;
    }

    if (recognizer.state != UIGestureRecognizerStateEnded &&
        recognizer.state != UIGestureRecognizerStateCancelled &&
        recognizer.state != UIGestureRecognizerStateFailed) return;

    BOOL shouldTrigger = recognizer.state == UIGestureRecognizerStateEnded &&
                         fabs(translation.x) > fabs(translation.y) &&
                         (rightward
                              ? (translation.x >= triggerDistance || velocity.x >= 700.0)
                              : (translation.x <= -triggerDistance || velocity.x <= -700.0));
    __weak CommonMessageCellView *weakCell = self;
    if (shouldTrigger && self.window && NeoWCEnhancementEnabled(NeoWCReplySwipeEnabledKey)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CommonMessageCellView *cell = weakCell;
            if (!cell.window || !NeoWCEnhancementEnabled(NeoWCReplySwipeEnabledKey)) return;
            NeoWCReplySwipeAction currentAction = NeoWCMessageSwipeAction(cell, rightward);
            NeoWCPerformMessageGestureAction(cell, currentAction);
        });
    }
    [UIView animateWithDuration:0.22
                          delay:0.0
         usingSpringWithDamping:0.82
          initialSpringVelocity:0.25
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         weakCell.transform = originalTransform;
                     }
                     completion:^(BOOL finished) {
                         (void)finished;
                          CommonMessageCellView *cell = weakCell;
                          if (!cell) return;
                          objc_setAssociatedObject(cell, &NeoWCReplyOriginalTransformKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                          objc_setAssociatedObject(cell, &NeoWCReplyFeedbackGeneratorKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                          objc_setAssociatedObject(cell, &NeoWCReplyFeedbackTriggeredKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                          objc_setAssociatedObject(cell, &NeoWCReplyPanRightwardKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                      }];
}

%new
- (void)neowc_handleMessageTapAction:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateRecognized ||
        !self.window ||
        !NeoWCEnhancementEnabled(NeoWCReplySwipeEnabledKey)) return;
    NSString *selfKey = recognizer.numberOfTapsRequired >= 3
        ? NeoWCMessageTripleTapSelfActionKey
        : NeoWCMessageDoubleTapSelfActionKey;
    NSString *otherKey = recognizer.numberOfTapsRequired >= 3
        ? NeoWCMessageTripleTapOtherActionKey
        : NeoWCMessageDoubleTapOtherActionKey;
    NeoWCReplySwipeAction action = NeoWCMessageGestureAction(self, selfKey, otherKey);
    NeoWCPerformMessageGestureAction(self, action);
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
        if (cell.window) [cell neowc_refreshAntiRevokeSidePrompt];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            CommonMessageCellView *delayedCell = weakCell;
            if (!delayedCell) return;
            objc_setAssociatedObject(delayedCell, &NeoWCAntiRevokeSideRefreshScheduledKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (delayedCell.window) [delayedCell neowc_refreshAntiRevokeSidePrompt];
        });
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
    id message = NeoWCMessageForCellViewModel(viewModel);
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
    if (label.superview != self) [self addSubview:label];
    if (label.hidden) label.hidden = NO;
    if (label.alpha != 1.0) label.alpha = 1.0;
    if (![label.text isEqualToString:prompt]) label.text = prompt;
    UIColor *promptColor = NeoWCColorForDefaultsKey(NeoWCAntiRevokeSideTextColorKey, UIColor.tertiaryLabelColor);
    if (![label.textColor isEqual:promptColor]) label.textColor = promptColor;

    UIView *bubbleView = NeoWCMessageSideAnchorView(self);
    if (!bubbleView) {
        if (!label.hidden) label.hidden = YES;
        return;
    }
    CGRect bubbleFrame = [bubbleView convertRect:bubbleView.bounds toView:self];
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
    [self bringSubviewToFront:label];
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
    unsigned int configuredValue = NeoWCConfiguredDailyStepCount();
    return configuredValue > 0 ? configuredValue : originalValue;
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

%hook RoomContentLogicController

- (NSArray *)getDefaultTitleTailSubViews {
    if (NeoWCEnhancementEnabled(NeoWCHideChatMuteIconKey)) {
        NeoWCCompatibilityMarkTriggered(@"hide-chat-mute-icon");
        return @[];
    }
    return %orig;
}

- (id)getMemeberCountLabel {
    id label = %orig;
    if (NeoWCEnhancementEnabled(NeoWCHideChatMuteIconKey) && [label isKindOfClass:[UILabel class]]) {
        ((UILabel *)label).hidden = YES;
        ((UILabel *)label).text = @"";
    }
    return label;
}

- (CGFloat)GetTitleLabelOffset {
    if (NeoWCEnhancementEnabled(NeoWCHideChatMuteIconKey)) return 0.0;
    return %orig;
}

%end

static BOOL NeoWCViewIsInsideNavigationChrome(UIView *view,
                                               BaseMsgContentViewController *controller) {
    UINavigationBar *navigationBar = controller.navigationController.navigationBar;
    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        if (ancestor == navigationBar ||
            [NSStringFromClass(ancestor.class) containsString:@"NavigationBar"]) return YES;
    }
    return NO;
}

static void NeoWCObserveTypingStatusLabel(MMUILabel *label, NSString *text) {
    BOOL typing = [text isKindOfClass:NSString.class] && [text containsString:@"正在输入"];
    BOOL tracked = [objc_getAssociatedObject(label, &NeoWCChatTypingStatusLabelMarkerKey) boolValue];
    if (!typing && !tracked) return;

    if (typing && !label.window) {
        objc_setAssociatedObject(label, &NeoWCChatTypingStatusLabelMarkerKey,
                                 @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    BaseMsgContentViewController *controller = NeoWCResolveVisibleChatController();
    if (!controller) return;
    if (typing && !NeoWCViewIsInsideNavigationChrome(label, controller)) {
        objc_setAssociatedObject(label, &NeoWCChatTypingStatusLabelMarkerKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    objc_setAssociatedObject(label, &NeoWCChatTypingStatusLabelMarkerKey,
                             typing ? @YES : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!NeoWCSetChatTypingState(controller, label)) return;
    __weak BaseMsgContentViewController *weakController = controller;
    dispatch_async(dispatch_get_main_queue(), ^{
        BaseMsgContentViewController *strongController = weakController;
        if (strongController && strongController.view.window) NeoWCUpdateChatTopBar(strongController);
    });
}

%hook MMUILabel

- (void)setText:(NSString *)text {
    NSString *contactsText = NeoWCResponderIsInsideControllerClass(self, @"ContactsViewController")
        ? NeoWCContactsCountTextForOriginal(text)
        : nil;
    if (contactsText.length > 0 && ![contactsText isEqualToString:text]) {
        NeoWCCompatibilityMarkTriggered(@"contacts-count");
    }
    NSString *resolvedText = contactsText ?: text;
    %orig(resolvedText);
    NeoWCObserveTypingStatusLabel(self, resolvedText);
}

- (void)didMoveToWindow {
    %orig;
    if (self.window && NeoWCResponderIsInsideControllerClass(self, @"ContactsViewController")) {
        NSString *contactsText = NeoWCContactsCountTextForOriginal(self.text);
        if (contactsText.length > 0 && ![contactsText isEqualToString:self.text]) self.text = contactsText;
    }
    NeoWCObserveTypingStatusLabel(self, self.text);
}

%end

%hook TimeoutNumber

- (void)didMoveToSuperview {
    %orig;
    if (NeoWCEnhancementEnabled(NeoWCWalletBalanceEnabledKey) &&
        NeoWCViewIsInsideWalletHeader((UIView *)self)) {
        NeoWCInstallWalletLongPressIfNeeded((UIView *)self, self, @selector(neowc_walletHandleLongPress:));
    } else {
        NeoWCRemoveWalletLongPressIfNeeded((UIView *)self);
    }
}

- (void)updateNumber:(unsigned long long)number {
    unsigned long long balanceFen = NeoWCViewIsInsideWalletHeader((UIView *)self)
        ? NeoWCWalletBalanceFenOverride()
        : 0;
    if (balanceFen > 0) {
        NeoWCCompatibilityMarkTriggered(@"wallet-balance");
        %orig(balanceFen);
        return;
    }
    %orig(number);
}

- (void)defaultNumber:(unsigned long long)number {
    unsigned long long balanceFen = NeoWCViewIsInsideWalletHeader((UIView *)self)
        ? NeoWCWalletBalanceFenOverride()
        : 0;
    %orig(balanceFen > 0 ? balanceFen : number);
}

%new
- (void)neowc_walletHandleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan &&
        NeoWCEnhancementEnabled(NeoWCWalletBalanceEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"wallet-balance");
        id headerView = NeoWCWalletHeaderForView((UIView *)self);
        NeoWCPresentWalletBalanceEditor(headerView);
    }
}

%end

%hook WCPayWalletEntryHeaderView

- (void)didMoveToSuperview {
    %orig;
    if (NeoWCEnhancementEnabled(NeoWCWalletBalanceEnabledKey)) {
        NeoWCInstallWalletLongPressIfNeeded((UIView *)self, self, @selector(neowc_walletHeaderHandleLongPress:));
    } else {
        NeoWCRemoveWalletLongPressIfNeeded((UIView *)self);
    }
    NeoWCRefreshWalletHeaderBalance(self);
}

- (void)handleUpdateWalletBalance {
    %orig;
    NeoWCRefreshWalletHeaderBalance(self);
}

- (void)setupTimeoutNumber {
    %orig;
    NeoWCRefreshWalletHeaderBalance(self);
}

- (void)updateBalanceEntryView {
    %orig;
    NeoWCRefreshWalletHeaderBalance(self);
}

- (void)updateBalanceAndRefreshView {
    %orig;
    NeoWCRefreshWalletHeaderBalance(self);
}

%new
- (void)neowc_walletHeaderHandleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan &&
        NeoWCEnhancementEnabled(NeoWCWalletBalanceEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"wallet-balance");
        NeoWCPresentWalletBalanceEditor(self);
    }
}

%end

%hook MMWebViewConfig

+ (BOOL)isEnableWebDebugFunctions {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return YES;
    return %orig;
}

%end

%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    return %orig(NeoWCAdBlockerRewrittenURLString(URLString));
}

%end

%hook WebviewJSEventHandler_adDataReport

- (void)handleJSEvent:(id)event HandlerFacade:(id)facade ExtraData:(id)extraData {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(event, facade, extraData);
}

%end

%hook WCAdvertiseStatMgr

- (id)getAdvertiseInfoForItem:(id)item {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return %orig(nil);
    return %orig(item);
}

- (void)logSphereViewWithSphereReportInfo:(id)reportInfo dataItem:(id)dataItem scene:(unsigned int)scene {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(reportInfo, dataItem, scene);
}

- (void)logSphereViewInDetailWithWrapInfo:(id)wrapInfo dataItem:(id)dataItem {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(wrapInfo, dataItem);
}

- (void)logSphereViewInTimeLineWithWrapInfo:(id)wrapInfo dataItem:(id)dataItem {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(wrapInfo, dataItem);
}

- (void)logHeadImageH5:(id)value {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(value);
}

- (void)logADBrandProfile:(id)value {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(value);
}

- (void)logADFloatView:(id)value {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(value);
}

- (void)logADPoiH5:(id)value {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(value);
}

- (void)logADH5:(id)value withUserInfo:(id)userInfo reportType:(unsigned int)reportType {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(value, userInfo, reportType);
}

- (void)logADH5:(id)value {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(value);
}

- (void)logADDetail:(id)detail dataItem:(id)dataItem {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(detail, dataItem);
}

- (void)logADCommentLog:(id)value {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(value);
}

- (void)logADBodyLog:(id)value {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(value);
}

- (void)reportAllFeedsADLog {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig;
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

%hook WAJSEventHandler_showSplashAd

- (void)handleJSEvent:(id)event {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(event);
}

%end

%hook WAJSEventHandler_showSplashAdMenu

- (void)handleJSEvent:(id)event {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(event);
}

%end

%hook BrandTLExptConfig

- (BOOL)isExptNotShowAd {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return YES;
    return %orig;
}

%end

%hook BSTLExptConfig

- (BOOL)isExptNotShowAd {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return YES;
    return %orig;
}

%end

%hook BrandTLFlutterViewController

- (BOOL)enableAd {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (void)setEnableAd:(BOOL)enabled {
    %orig(NeoWCEnhancementEnabled(NeoWCAdBlockerKey) ? NO : enabled);
}

%end

%hook BoxBrandTLFlutterViewController

- (BOOL)enableAd {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (void)setEnableAd:(BOOL)enabled {
    %orig(NeoWCEnhancementEnabled(NeoWCAdBlockerKey) ? NO : enabled);
}

%end

%hook BSTimelineFlutterViewController

- (BOOL)enableAd {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (void)setEnableAd:(BOOL)enabled {
    %orig(NeoWCEnhancementEnabled(NeoWCAdBlockerKey) ? NO : enabled);
}

%end

%hook _TtC6WeChat19MagicAdBrandService

- (BOOL)isBrandTimelineOpen {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

%end

%hook MagicAdPushMgrService

- (void)onServiceInit {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig;
}

- (void)handleAdMsg:(id)message {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(message);
}

- (void)OnGetNewXmlMsg:(id)xml Type:(unsigned int)type MsgWrap:(id)message {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(xml, type, message);
}

- (id)getSpecificSlotMsg:(id)slot withBizName:(id)bizName {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return nil;
    return %orig(slot, bizName);
}

%end


%hook BrandTimelineMsgMgr

- (NSArray *)getInsertedAdCardListWithLimit:(NSUInteger)limit {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return @[];
    return %orig(limit);
}

- (BOOL)isAdDataLegal:(id)data {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig(data);
}

- (BOOL)getAdCardExposeInToday {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return YES;
    return %orig;
}

%end

%hook BoxBrandTimelineMsgMgr

- (NSArray *)getInsertedAdCardListWithLimit:(NSUInteger)limit {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return @[];
    return %orig(limit);
}

- (BOOL)isAdDataLegal:(id)data {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig(data);
}

- (BOOL)getAdCardExposeInToday {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return YES;
    return %orig;
}

%end

%hook WAJSEventHandler_adOperateWXData

- (void)handleJSEvent:(id)event {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(event);
}

%end

%hook WCUserComment

- (BOOL)isAdvertiserComment {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)isRefAdvertiserComment {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)isAdPreferInfo {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)isAtedAdvertiserComment {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)isAdBossFirstComment {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)isAdBossFirstLike {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (id)adExtInfo {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return nil;
    return %orig;
}

- (void)setAdExtInfo:(id)info {
    %orig(NeoWCEnhancementEnabled(NeoWCAdBlockerKey) ? nil : info);
}

%end

%hook BrandTLCanvasCardMgr

+ (BOOL)isAdRequestOpen {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

+ (BOOL)isAdCardOpen {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (void)handleBizAdNotifyNewXml:(id)xml {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(xml);
}

%end


%hook JailBreakHelper

+ (id)loadSetting {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return nil;
    return %orig;
}

- (instancetype)init {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return nil;
    return %orig;
}

+ (NSString *)getJailbreakPath {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return nil;
    return %orig;
}

+ (NSString *)getJailbreakRootDir {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return nil;
    return %orig;
}

+ (BOOL)JailBroken {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)HasInstallJailbreakPluginInvalidIAPPurchase {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)HasInstallJailbreakPlugin:(id)plugin {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig(plugin);
}

- (BOOL)IsJailBreak {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

- (BOOL)isOverADay {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

%end

%hook CUtility

+ (BOOL)isBeingDebugged {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

%end

%hook TSEnvironment

+ (BOOL)isBeingDebugged {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return NO;
    return %orig;
}

%end

%hook ClientCheckMgr

- (void)reportAppList:(id)appList {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(appList);
}

- (void)checkHookWithSeq:(id)sequence {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(sequence);
}

- (void)checkHook:(id)value {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(value);
}

- (void)reportFileConsistency:(id)consistency
                     fileName:(id)fileName
                       offset:(unsigned long long)offset
                   bufferSize:(unsigned int)bufferSize
                          seq:(unsigned int)sequence {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(consistency, fileName, offset, bufferSize, sequence);
}

- (void)checkConsistency:(id)value {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig(value);
}

%end

%hook WCCrashBlockExtensionHandler

- (void)renewInfoForReport {
    if (NeoWCEnhancementEnabled(NeoWCAdBlockerKey)) return;
    %orig;
}

%end

static void NeoWCApplyRedEnvelopeDetail(WCRedEnvelopesRedEnvelopesDetailViewController *controller) {
    id delegate = NeoWCTweakValueForSelectorNames(controller, @[@"m_delegate"]) ?: NeoWCTweakSafeValue(controller, @"m_delegate");
    Class logicClass = NSClassFromString(@"WCRedEnvelopesReceiveControlLogic");
    if (logicClass && ![delegate isKindOfClass:logicClass]) return;
    id data = NeoWCTweakValueForSelectorNames(delegate, @[@"m_data"]) ?: NeoWCTweakSafeValue(delegate, @"m_data");
    Class dataClass = NSClassFromString(@"WCRedEnvelopesControlData");
    if (dataClass && ![data isKindOfClass:dataClass]) return;
    id detail = NeoWCTweakValueForSelectorNames(data, @[@"m_oWCRedEnvelopesDetailInfo"]) ?:
                NeoWCTweakSafeValue(data, @"m_oWCRedEnvelopesDetailInfo");
    Class detailClass = NSClassFromString(@"WCRedEnvelopesDetailInfo");
    if (!detail || (detailClass && ![detail isKindOfClass:detailClass])) return;
    UILabel *nickNameLabel = NeoWCTweakSafeValue(controller, @"nickNameLabel");
    UILabel *receivedInfoLabel = NeoWCTweakSafeValue(controller, @"m_receivedInfoLable");
    if (![receivedInfoLabel isKindOfClass:[UILabel class]]) return;
    NSAttributedString *original = objc_getAssociatedObject(receivedInfoLabel, &NeoWCRedEnvelopeOriginalAttributedTextKey);
    if (!original) {
        original = receivedInfoLabel.attributedText ?: [[NSAttributedString alloc] initWithString:receivedInfoLabel.text ?: @""];
        objc_setAssociatedObject(receivedInfoLabel, &NeoWCRedEnvelopeOriginalAttributedTextKey,
                                 original, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    if (!NeoWCEnhancementEnabled(NeoWCRedEnvelopeDetailEnabledKey)) {
        receivedInfoLabel.attributedText = original;
        return;
    }
    if ([nickNameLabel isKindOfClass:[UILabel class]]) {
        NSString *nickName = nickNameLabel.text ?: @"";
        NSRange oldDetail = [nickName rangeOfString:@"\n(¥" options:NSBackwardsSearch];
        if (oldDetail.location != NSNotFound) nickName = [nickName substringToIndex:oldDetail.location];
        nickNameLabel.attributedText = nil;
        nickNameLabel.text = nickName;
    }
    SEL totalAmountSelector = NSSelectorFromString(@"m_lTotalAmount");
    SEL receivedAmountSelector = NSSelectorFromString(@"m_lRecAmount");
    SEL totalCountSelector = NSSelectorFromString(@"m_lTotalNum");
    SEL receivedCountSelector = NSSelectorFromString(@"m_lRecNum");
    long long totalAmount = [detail respondsToSelector:totalAmountSelector]
        ? ((long long (*)(id, SEL))objc_msgSend)(detail, totalAmountSelector)
        : [NeoWCTweakSafeValue(detail, @"m_lTotalAmount") longLongValue];
    long long receivedAmount = [detail respondsToSelector:receivedAmountSelector]
        ? ((long long (*)(id, SEL))objc_msgSend)(detail, receivedAmountSelector)
        : [NeoWCTweakSafeValue(detail, @"m_lRecAmount") longLongValue];
    long long totalCount = [detail respondsToSelector:totalCountSelector]
        ? ((long long (*)(id, SEL))objc_msgSend)(detail, totalCountSelector)
        : [NeoWCTweakSafeValue(detail, @"m_lTotalNum") longLongValue];
    long long receivedCount = [detail respondsToSelector:receivedCountSelector]
        ? ((long long (*)(id, SEL))objc_msgSend)(detail, receivedCountSelector)
        : [NeoWCTweakSafeValue(detail, @"m_lRecNum") longLongValue];
    double remainingAmount = MAX(0LL, totalAmount - receivedAmount) / 100.0;
    long long remainingCount = MAX(0LL, totalCount - receivedCount);
    NSString *displayText = [NSString stringWithFormat:@"总 %.2f元｜已领 %lld个｜剩余 %lld个 · %.2f元",
                             totalAmount / 100.0, receivedCount, remainingCount, remainingAmount];
    CGFloat size = [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCRedEnvelopeDetailFontSizeKey];
    UIFont *font = [UIFont systemFontOfSize:size >= 10.0 && size <= 24.0 ? size : 14.0 weight:UIFontWeightRegular];
    UIColor *color = receivedInfoLabel.textColor ?: [UIColor colorWithWhite:1.0 alpha:0.7];
    receivedInfoLabel.numberOfLines = 1;
    receivedInfoLabel.textAlignment = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCRedEnvelopeDetailCenterKey]
        ? NSTextAlignmentCenter
        : NSTextAlignmentNatural;
    receivedInfoLabel.attributedText = [[NSAttributedString alloc] initWithString:displayText
                                                                       attributes:@{NSFontAttributeName: font,
                                                                                    NSForegroundColorAttributeName: color}];
    CGRect frame = receivedInfoLabel.frame;
    frame.size.width = MAX(frame.size.width, 220.0);
    receivedInfoLabel.frame = frame;
    NeoWCCompatibilityMarkTriggered(@"red-envelope-detail");
}

static BOOL NeoWCPresentCallConfirmation(VoIPBubbleMessageCellView *cell, BOOL video) {
    UIWindow *window = NeoWCActiveApplicationWindow();
    UIViewController *presenter = NeoWCTopControllerForLoginToast(window.rootViewController);
    if (!presenter.view.window || presenter.presentedViewController) return NO;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:video ? @"发起视频通话？" : @"发起语音通话？"
                                                                   message:@"确认后将立即呼叫对方"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak VoIPBubbleMessageCellView *weakCell = cell;
    [alert addAction:[UIAlertAction actionWithTitle:@"呼叫" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        (void)action;
        VoIPBubbleMessageCellView *strongCell = weakCell;
        if (!strongCell) return;
        const void *key = video ? &NeoWCCallVideoConfirmedKey : &NeoWCCallVoiceConfirmedKey;
        objc_setAssociatedObject(strongCell, key, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        SEL selector = video ? @selector(startVideoVoip) : @selector(startVoiceVoip);
        ((void (*)(id, SEL))objc_msgSend)(strongCell, selector);
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
    NeoWCCompatibilityMarkTriggered(@"call-confirm");
    return YES;
}

%hook WCRedEnvelopesRedEnvelopesDetailViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    NeoWCApplyRedEnvelopeDetail(self);
}

%end

%hook VoIPBubbleMessageCellView

- (void)startVoiceVoip {
    if ([objc_getAssociatedObject(self, &NeoWCCallVoiceConfirmedKey) boolValue]) {
        objc_setAssociatedObject(self, &NeoWCCallVoiceConfirmedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        %orig;
        return;
    }
    if (!NeoWCEnhancementEnabled(NeoWCCallConfirmEnabledKey)) {
        %orig;
        return;
    }
    if (!NeoWCPresentCallConfirmation(self, NO)) {
        %orig;
    }
}

- (void)startVideoVoip {
    if ([objc_getAssociatedObject(self, &NeoWCCallVideoConfirmedKey) boolValue]) {
        objc_setAssociatedObject(self, &NeoWCCallVideoConfirmedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        %orig;
        return;
    }
    if (!NeoWCEnhancementEnabled(NeoWCCallConfirmEnabledKey)) {
        %orig;
        return;
    }
    if (!NeoWCPresentCallConfirmation(self, YES)) {
        %orig;
    }
}

%end

%hook ScanQRCodeLogicController

- (void)onDetectCodesWithMarkDotInfoList:(id)list isCameraScan:(BOOL)isCameraScan {
    BOOL disguise = NeoWCEnhancementEnabled(NeoWCQRCodeCameraSourceEnabledKey);
    if (disguise) NeoWCCompatibilityMarkTriggered(@"qr-camera-source");
    BOOL cameraScan = disguise ? YES : isCameraScan;
    %orig(list, cameraScan);
}

- (BOOL)isInScanSceneAndUseCameraScan {
    if (NeoWCEnhancementEnabled(NeoWCQRCodeCameraSourceEnabledKey)) return YES;
    return %orig;
}

- (NSInteger)fromScene {
    if (NeoWCEnhancementEnabled(NeoWCQRCodeCameraSourceEnabledKey)) return 1;
    return %orig;
}

- (NSInteger)m_sourceType {
    if (NeoWCEnhancementEnabled(NeoWCQRCodeCameraSourceEnabledKey)) return 0;
    return %orig;
}

- (NSInteger)fromRawScene {
    if (NeoWCEnhancementEnabled(NeoWCQRCodeCameraSourceEnabledKey)) return 0;
    return %orig;
}

- (NSInteger)picFrom {
    if (NeoWCEnhancementEnabled(NeoWCQRCodeCameraSourceEnabledKey)) return 0;
    return %orig;
}

- (void)setIsFromAlbum:(BOOL)isFromAlbum {
    BOOL value = NeoWCEnhancementEnabled(NeoWCQRCodeCameraSourceEnabledKey) ? NO : isFromAlbum;
    %orig(value);
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
