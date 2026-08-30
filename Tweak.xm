#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <math.h>
#import <stdlib.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <string.h>
#include <atomic>

extern "C" void MSHookMessageEx(Class _class, SEL message, IMP hook, IMP *old);

#import "Sources/NeoWCSettingsViewController.h"
#import "Sources/NeoWCSettingsCatalog.h"
#import "Sources/NeoWCBackgroundKeeper.h"
#import "Sources/NeoWCMomentsReminder.h"
#import "Sources/NeoWCMomentsInteractionReminder.h"
#import "Sources/NeoWCMomentsPrewarmer.h"
#import "Sources/NeoWCMomentsCommentAntiDelete.h"
#import "Sources/NeoWCAccount.h"
#import "Sources/NeoWCAntiRevoke.h"
#import "Sources/NeoWCChatExport.h"
#import "Sources/NeoWCCompatibility.h"
#import "Sources/NeoWCLogging.h"
#import "Sources/NeoWCEnhancements.h"
#import "Sources/NeoWCPluginManager.h"
#import "Sources/NeoWCRuntimeFeatures.h"
#import "Sources/NeoWCInterfaceTweaks.h"
#import "Sources/NeoWCMessageTime.h"
#import "Sources/NeoWCGlassCapsuleView.h"
#import "Sources/NeoWCQuickReplyStore.h"
#import "Sources/NeoWCQuickReplyViewController.h"
#import "Sources/NeoWCSendConfirmation.h"
#import "Sources/NeoWCMessageBlock.h"
#import "Sources/NeoWCAvatarQuickPanel.h"
#import "Sources/NeoWCContactInfoCard.h"
#import "Sources/NeoWCInfoListViewController.h"
#import "Sources/NeoWCSilkEncoder.h"
#import "Sources/NeoWCInAppNotification.h"
#import "Sources/NeoWCEncryption.h"

@interface WCActionSheet : NSObject
- (void)addButtonWithTitle:(NSString *)title eventAction:(void (^)(void))eventAction;
- (BOOL)isContainButtonTitle:(NSString *)title;
@end

@interface WCTimeLineViewController : UIViewController
- (void)showPhotoAlert:(id)context;
- (void)showImagePicker:(id)context;
@end

@interface WCCommentDetailViewControllerFB : UIViewController
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
- (void)neowc_handleMomentsSaveImages:(id)sender;
@end

@interface WCTimeLineOperateButtonView : UIButton
@end

@interface MMUILabel : UILabel
@end

@interface WCOperateFloatView : UIView
- (void)showWithItemData:(id)item tipPoint:(CGPoint)tipPoint;
- (void)hide;
- (void)neowc_handleMomentsForward:(id)sender;
- (void)neowc_handleMomentsSaveImages:(id)sender;
@end

@interface CommonMessageCellView : UIView
- (void)neowc_refreshAntiRevokeSidePrompt;
- (void)neowc_scheduleAntiRevokeSidePromptRefresh;
- (void)neowc_handleReplyPan:(UIPanGestureRecognizer *)recognizer;
- (void)neowc_handleMessageTapAction:(UITapGestureRecognizer *)recognizer;
- (void)handleTapReferMessage;
- (void)handleTapForReferMsg:(id)sender;
- (void)onReturnToOriginalMsg;
- (void)onHeadImageLongPressed:(id)sender;
@end

@interface RoomContentLogicController : NSObject
- (NSArray *)getDefaultTitleTailSubViews;
- (id)getMemeberCountLabel;
- (CGFloat)GetTitleLabelOffset;
@end

@interface BaseMsgContentViewController : UIViewController
- (id)GetContact;
- (void)returnToOriginalMsg:(id)message;
- (void)neowc_openChatSearch:(id)sender;
- (void)neowc_handleChatSearchEdgePan:(UIScreenEdgePanGestureRecognizer *)recognizer;
- (void)neowc_toggleSendConfirmation:(UILongPressGestureRecognizer *)recognizer;
@end

@interface BaseMsgContentLogicController : NSObject
- (NSString *)getCurrentChatName;
- (void)SendTextMessage:(id)text;
- (void)SendTextMessage:(id)text replyingMessage:(id)replyingMessage isPasted:(BOOL)isPasted;
- (void)SendImageMessageByMMAsset:(id)asset;
@end

@interface WeixinContentLogicController : NSObject
- (NSString *)getCurrentChatName;
- (void)AddMsg:(id)message MsgWrap:(id)wrap;
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
- (void)neowc_openInfoCard;
@end

@interface ChatRoomInfoViewController : UIViewController
- (void)neowc_copyRawContactID;
- (void)neowc_openInfoCard;
@end

@interface SocialInfomationViewController : UIViewController
- (void)setM_contact:(id)contact;
- (void)reloadTableView;
- (void)onCRGDataUpdated;
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
- (void)neowc_handleQuickReplyPlusLongPress:(UILongPressGestureRecognizer *)recognizer;
- (void)sendMsgWithText:(id)text;
@end

@interface AppFileMessageCellViewV2 : CommonMessageCellView
- (void)neowc_previewEncryptedMedia:(id)sender;
@end

@interface TextMessageCellView : CommonMessageCellView
- (void)setViewModel:(id)viewModel;
- (NSString *)getTextString;
- (id)getRichTextViewForDelegate;
- (void)updateTranslateSuccessView;
@end

@interface MMHeadImageView : UIView
- (instancetype)initWithUsrName:(NSString *)userName
                     headImgUrl:(NSString *)headImageURL
                    bAutoUpdate:(BOOL)autoUpdate
                   bRoundCorner:(BOOL)roundCorner;
- (void)setTargetForDoubleClick:(id)target action:(SEL)action;
- (void)setConerSize:(unsigned int)cornerSize;
@end

@interface FakeHeadImageView : UIView
- (instancetype)initWithRoundCorner:(BOOL)roundCorner;
- (void)setConerSize:(unsigned int)cornerSize;
@end

@interface CMessageWrap : NSObject
@property (nonatomic, assign) NSUInteger m_uiMessageType;
@property (nonatomic, assign) NSUInteger m_uiGameType;
@property (nonatomic, assign) NSUInteger m_uiGameContent;
@property (nonatomic, copy) NSString *m_nsEmoticonMD5;
@property (nonatomic, copy) NSString *m_nsContent;
@property (nonatomic, copy) NSString *m_nsToUsr;
@end

@interface UploadVoiceWrap : NSObject
- (void)setM_uiVoiceForwardFlag:(unsigned int)forwardFlag;
@end

@interface UploadVoiceRequest : NSObject
- (void)setForwardFlag:(unsigned int)forwardFlag;
@end

@interface CMessageMgr : NSObject
- (void)AddMsg:(NSString *)target MsgWrap:(CMessageWrap *)wrap;
- (id)AddAppMsg:(NSString *)target MsgWrap:(CMessageWrap *)wrap DataPath:(NSString *)dataPath Scene:(NSUInteger)scene;
- (id)AddVideoMsg:(id)message ToUsr:(NSString *)target VideoInfo:(id)videoInfo;
- (void)AddEmoticonMsg:(NSString *)message MsgWrap:(CMessageWrap *)wrap;
- (void)onNewSyncNotAddDBMessage:(CMessageWrap *)wrap;
- (void)AsyncOnAddMsg:(NSString *)sessionUserName MsgWrap:(CMessageWrap *)wrap;
- (void)AsyncOnAddMsgForSession:(NSString *)sessionUserName MsgWrap:(CMessageWrap *)wrap;
- (void)AsyncOnAddMsgForSession:(NSString *)sessionUserName
                        MsgWrap:(CMessageWrap *)wrap
             NewMsgArriveNotify:(BOOL)notify;
- (void)HandleMsgList:(NSString *)sessionUserName MsgList:(NSArray *)messages;
@end

@interface MMNewSessionMgr : NSObject
- (void)OnAddMsg:(NSString *)sessionUserName MsgWrap:(CMessageWrap *)wrap;
- (void)OnMsgNotAddDBNotify:(NSString *)sessionUserName MsgWrap:(CMessageWrap *)wrap;
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
static std::atomic_bool NeoWCHighRefreshRateEnabled(false);
static std::atomic_bool NeoWCHighRefreshRateApplicationActive(false);
static std::atomic_int NeoWCHighRefreshRateScreenMaximum(60);
static char NeoWCDeviceCardDidConfirmKey;
static char NeoWCGameDidAuthorizeKey;
static char NeoWCMomentsDoubleTapRecognizerKey;
static char NeoWCMomentsForwardButtonKey;
static char NeoWCMomentsSaveButtonKey;
static char NeoWCMomentsOriginalOperateFrameKey;
static char NeoWCMomentsFloatForwardButtonKey;
static char NeoWCMomentsFloatSaveButtonKey;
static char NeoWCMomentsFloatSeparatorKey;
static char NeoWCMomentsFloatSaveSeparatorKey;
static char NeoWCMomentsFloatDataItemKey;
static char NeoWCMomentsFloatSnapshotKey;
static char NeoWCMomentsForwardTaskKey;
static char NeoWCMomentsSaveTaskKey;
static char NeoWCMomentsDataItemSaveTaskKey;
static char NeoWCMediaToVoiceInProgressKey;
static char NeoWCMomentsHighQualityMenuKey;
static char NeoWCImageJokerPickerDelegateKey;
static char NeoWCEmoticonPreviewLongPressKey;
static char NeoWCMomentsOriginalTimeTextKey;
static char NeoWCMomentsOriginalTimeLinesKey;
static char NeoWCMomentsPreciseTimeAppliedKey;
static id NeoWCPendingMomentsPermissionDataItem;
static __weak id NeoWCPendingMomentsCameraController;
static id NeoWCActiveMomentsMediaSaveTask;
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
static char NeoWCQuickReplyPlusRecognizerKey;
static char NeoWCQuickReplyPlusDelegateKey;
static char NeoWCAlbumEncryptionSelectedKey;
static char NeoWCAlbumEncryptionButtonKey;
static char NeoWCAlbumEncryptionSendingKey;
static char NeoWCOfficialAlbumTargetKey;
static char NeoWCEncryptedTextDisplayOverrideKey;
static char NeoWCEncryptedTextRefreshInFlightKey;
static char NeoWCEncryptedTextManualPlainKey;
static char NeoWCWalletGestureRecognizerKey;
static char NeoWCReplyPanRecognizerKey;
static char NeoWCReplyPanDelegateKey;
static char NeoWCMessageDoubleTapRecognizerKey;
static char NeoWCMessageTripleTapRecognizerKey;
static char NeoWCAvatarQuickHeadViewKey;
static char NeoWCAvatarQuickDoubleTapRecognizerKey;
static char NeoWCAvatarQuickGestureProxyKey;
static char NeoWCAvatarNativeDoubleTapTargetKey;
static char NeoWCAvatarNativeDoubleTapActionKey;
static char NeoWCAvatarNativeDoubleTapOwnedKey;
static char NeoWCOfficialInfoCardBoxKey;
static char NeoWCOfficialInfoBaseRowsKey;
static char NeoWCInfoCardOfficialControllerKey;
static char NeoWCOfficialRelatedGroupLogicKey;
static char NeoWCExclusiveRedEnvelopeContactKey;
static char NeoWCExclusiveRedEnvelopeViewContactKey;
static char NeoWCExclusiveRedEnvelopeViewDataKey;
static BOOL NeoWCUpdatingAvatarNativeDoubleTap = NO;
static BOOL NeoWCPerformingNativeAvatarLongPress = NO;
static id NeoWCPendingExclusiveRedEnvelopeContact;
static NSString *NeoWCPendingExclusiveRedEnvelopeGroupID;
static CFTimeInterval NeoWCPendingExclusiveRedEnvelopeDeadline;
static NSUInteger NeoWCPendingExclusiveRedEnvelopeGeneration;
static char NeoWCReplyOriginalTransformKey;
static char NeoWCReplyTransformSnapshotsKey;
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
static char NeoWCChatSearchItemKey;
static char NeoWCChatSearchActiveKey;
static char NeoWCChatSearchCleanupKey;
static char NeoWCChatSearchEdgePanKey;
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
static char NeoWCChatTopTypingActiveKey;
static char NeoWCChatTopStableDisplayNameKey;
static char NeoWCChatTypingStatusLabelMarkerKey;
static char NeoWCChatTopOriginalClipsToBoundsKey;
static char NeoWCChatTopOriginalBorderWidthKey;
static char NeoWCChatTopOriginalCornerRadiusKey;
static char NeoWCChatTopContentNavigationBarKey;
static char NeoWCChatTopOriginalVisualEffectKey;
static char NeoWCChatTopOriginalVisualEffectMaskKey;
static char NeoWCChatTopOriginalBackgroundMaskKey;
static char NeoWCChatTopFadeBackgroundMaskKey;
static char NeoWCChatSearchTransitionKey;
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
static char NeoWCSendConfirmationNativeBypassKey;
static NSString *NeoWCSendConfirmationImageBypassUsername;
static CFTimeInterval NeoWCSendConfirmationImageBypassDeadline;
static NSString *NeoWCSendConfirmationVideoBypassUsername;
static CFTimeInterval NeoWCSendConfirmationVideoBypassDeadline;
static NSString *NeoWCSendConfirmationRepeatBypassUsername;
static CFTimeInterval NeoWCSendConfirmationRepeatBypassDeadline;
static NSInteger NeoWCSendConfirmationRepeatBypassMessageType;
static __weak BaseMsgContentViewController *NeoWCVisibleChatController;
static __weak BaseMsgContentViewController *NeoWCSendConfirmationChatController;
static __weak id NeoWCCurrentEditImageLogicController;
static __weak UIViewController *NeoWCActiveMomentsDetailController;
static BOOL NeoWCMomentsDispatchingQuickComment = NO;

static void NeoWCUpdateChatTopBar(BaseMsgContentViewController *controller);
static void NeoWCRefreshChatTopBarAfterWechatUpdate(BaseMsgContentViewController *controller);
static void NeoWCUpdatePinnedMessageGlass(UIView *tipsView);
static BaseMsgContentViewController *NeoWCResolveVisibleChatController(void);
static void NeoWCPresentQuickReplyLibrary(BaseMsgContentViewController *controller);
static NSString *NeoWCChatUserName(id controller);
static void NeoWCShowTransientMessage(NSString *message, BOOL success);
static BOOL NeoWCMethodReturnsVoid(Method method);
static BOOL NeoWCMethodReturnsObject(Method method);
static BOOL NeoWCMethodArgumentIsObject(Method method, unsigned int index);
static BOOL NeoWCMethodArgumentIsIntegerScalar(Method method, unsigned int index);
static BOOL NeoWCMethodArgumentIsSelector(Method method, unsigned int index);
static BOOL NeoWCMomentCanSaveMedia(id dataItem);
static void NeoWCSaveMomentMedia(id dataItem, UIViewController *presenter);
@class NeoWCReplyTransformSnapshot;
static NSArray<NeoWCReplyTransformSnapshot *> *NeoWCReplyTransformSnapshots(CommonMessageCellView *sourceCell);
static void NeoWCApplyReplyTransform(NSArray<NeoWCReplyTransformSnapshot *> *snapshots, CGFloat offset);
static void NeoWCRestoreReplyTransforms(NSArray<NeoWCReplyTransformSnapshot *> *snapshots);

@interface NeoWCBarButtonActionProxy : NSObject
@property (nonatomic, strong) UIBarButtonItem *originalItem;
@property (nonatomic, weak) UIViewController *fallbackController;
@property (nonatomic, assign) BOOL popsNavigationController;
- (void)invoke:(id)sender;
@end

static id NeoWCTweakSafeValue(id object, NSString *key);
static void NeoWCTweakSetValue(id object, NSString *key, id value);
static id NeoWCTweakValueForSelectorNames(id object, NSArray<NSString *> *selectorNames);
static id NeoWCMessageManager(void);
static id NeoWCMessageWrapForCell(id cell);
static void NeoWCTriggerNativeTextRefresh(id cell);
static id NeoWCMessageForCellViewModel(id viewModel);
static id NeoWCImageJokerMessageForObject(id object);
static id NeoWCContactForUserName(NSString *userName);
static void NeoWCOpenHomeRemark(id owner, id contact, BOOL group);
static void NeoWCOpenHomeMoments(id owner, id contact);
static void NeoWCSynchronizeAvatarQuickGesture(CommonMessageCellView *cell);
static BOOL NeoWCPresentAvatarQuickMenu(CommonMessageCellView *cell, UIView *headView);
static NSInteger NeoWCGroupMemberRemovalScene(id groupContact,
                                               id memberContact,
                                               NSString *memberUserName);
static void NeoWCConfirmRemoveGroupMember(UIViewController *presenter,
                                          id groupContact,
                                          id memberContact,
                                          NSString *memberUserName,
                                          NSInteger scene);
static NSArray<NSDictionary<NSString *, NSString *> *> *NeoWCProfileInfoRows(id contact, BOOL group);
static NSArray<NSDictionary<NSString *, NSString *> *> *NeoWCGroupMemberInfoRows(id contact,
                                                                                   id groupContact,
                                                                                   NSString *userName);
static void NeoWCAddInfoCardRow(NSMutableArray<NSDictionary<NSString *, NSString *> *> *rows,
                                NSString *title,
                                id value);
static UIViewController *NeoWCCreateOfficialSocialInformation(id contact);
static NSArray<NSDictionary<NSString *, NSString *> *> *NeoWCOfficialSocialInformationRows(id controller);
static NSArray<NSDictionary<NSString *, NSString *> *> *NeoWCMergeInfoCardRows(NSArray *baseRows,
                                                                                NSArray *officialRows);
static void NeoWCRefreshInfoCardFromOfficialController(id officialController);
static void NeoWCConfigureInfoCardSwitches(NeoWCContactInfoCardViewController *card,
                                           NSString *username,
                                           BOOL group);
static void NeoWCConfigureInfoCardDetailActions(NeoWCContactInfoCardViewController *card,
                                                id contact,
                                                id groupContact,
                                                NSString *username,
                                                id officialController);
static UIViewController *NeoWCSendConfirmationPresenterForTarget(NSString *target);
static BOOL NeoWCSendConfirmationValidateTarget(NSString *target);
static BOOL NeoWCSendConfirmationMessageIsAppEmoticon(id wrap);

static void NeoWCArmRepeatSendConfirmationBypass(NSString *target, NSInteger messageType) {
    NeoWCSendConfirmationRepeatBypassUsername = [target copy];
    NeoWCSendConfirmationRepeatBypassMessageType = messageType;
    NeoWCSendConfirmationRepeatBypassDeadline = CACurrentMediaTime() + 3.0;
}

static void NeoWCClearRepeatSendConfirmationBypass(void) {
    NeoWCSendConfirmationRepeatBypassUsername = nil;
    NeoWCSendConfirmationRepeatBypassDeadline = 0.0;
    NeoWCSendConfirmationRepeatBypassMessageType = 0;
}

static BOOL NeoWCConsumeRepeatSendConfirmationBypass(NSString *target,
                                                       NSInteger messageType,
                                                       BOOL keepForImageSecondStage) {
    CFTimeInterval now = CACurrentMediaTime();
    if (now > NeoWCSendConfirmationRepeatBypassDeadline) {
        NeoWCClearRepeatSendConfirmationBypass();
        return NO;
    }
    BOOL videoTypeMatches = (messageType == 43 || messageType == 62) &&
                            (NeoWCSendConfirmationRepeatBypassMessageType == 43 ||
                             NeoWCSendConfirmationRepeatBypassMessageType == 62);
    BOOL matches = target.length > 0 &&
                   [NeoWCSendConfirmationRepeatBypassUsername isEqualToString:target] &&
                   (NeoWCSendConfirmationRepeatBypassMessageType == messageType || videoTypeMatches);
    if (matches && !keepForImageSecondStage) {
        NeoWCClearRepeatSendConfirmationBypass();
    }
    return matches;
}

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
@property (nonatomic, assign) CGRect saveFrame;
@property (nonatomic, assign) CGRect separatorFrame;
@property (nonatomic, assign) CGRect saveSeparatorFrame;
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

static BOOL NeoWCMomentsIsNativeDetailContext(id responderObject) {
    Class detailClass = NSClassFromString(@"WCCommentDetailViewControllerFB");
    if (!detailClass) return NO;
    UIViewController *controller = NeoWCViewControllerForResponder(responderObject);
    UIViewController *activeDetail = NeoWCActiveMomentsDetailController;
    if ([activeDetail isKindOfClass:detailClass] && !controller) return YES;
    for (UIViewController *current = controller; current; current = current.parentViewController) {
        if ([current isKindOfClass:detailClass] || current == activeDetail) return YES;
    }
    return [controller.navigationController.topViewController isKindOfClass:detailClass];
}

static NSArray<UIGestureRecognizer *> *NeoWCNavigationReturnGesturesForView(UIView *view) {
    UIViewController *controller = NeoWCViewControllerForResponder(view);
    UINavigationController *navigationController = controller.navigationController;
    if (!navigationController || navigationController.viewControllers.count <= 1) return @[];

    NSMutableArray<UIGestureRecognizer *> *gestures = [NSMutableArray array];
    UIGestureRecognizer *interactivePop = navigationController.interactivePopGestureRecognizer;
    if (interactivePop && interactivePop.enabled) [gestures addObject:interactivePop];

    // WCPulse and some WeChat navigation containers expose an additional
    // full-screen return recognizer. Resolve it dynamically so message gestures
    // keep yielding even when the navigation view recreates that recognizer.
    for (id owner in @[navigationController, navigationController.view]) {
        for (NSString *selectorName in @[@"screenDismissPanGestureRecognizer", @"dismissPanGestureRecognizer"]) {
            SEL selector = NSSelectorFromString(selectorName);
            if (![owner respondsToSelector:selector]) continue;
            id candidate = ((id (*)(id, SEL))objc_msgSend)(owner, selector);
            if (![candidate isKindOfClass:[UIGestureRecognizer class]] ||
                ![(UIGestureRecognizer *)candidate isEnabled] ||
                [gestures containsObject:candidate]) continue;
            [gestures addObject:candidate];
        }
    }
    return gestures;
}

static BOOL NeoWCIsNavigationReturnGesture(UIGestureRecognizer *candidate, UIView *view) {
    if (!candidate) return NO;
    return [NeoWCNavigationReturnGesturesForView(view) containsObject:candidate];
}

@interface NeoWCReplyPanGestureDelegate : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIView *cell;
@property (nonatomic, assign) CGFloat initialWindowX;
@end

@interface NeoWCAvatarQuickGestureProxy : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, weak) CommonMessageCellView *cell;
@property (nonatomic, weak) UIView *headView;
- (void)handleGesture:(UIGestureRecognizer *)recognizer;
@end

@interface NeoWCWeakObjectBox : NSObject
@property (nonatomic, weak) id object;
@end

@interface NeoWCReplyTransformSnapshot : NSObject
@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) CGAffineTransform transform;
@end

@implementation NeoWCReplyTransformSnapshot
@end

@implementation NeoWCAvatarQuickGestureProxy

- (void)handleGesture:(UIGestureRecognizer *)recognizer {
    if ([recognizer isKindOfClass:UILongPressGestureRecognizer.class] &&
        recognizer.state != UIGestureRecognizerStateBegan) return;
    if ([recognizer isKindOfClass:UITapGestureRecognizer.class] &&
        recognizer.state != UIGestureRecognizerStateRecognized) return;
    CommonMessageCellView *cell = self.cell;
    UIView *headView = self.headView;
    if (!cell.window || !headView.window) return;
    (void)NeoWCPresentAvatarQuickMenu(cell, headView);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    (void)gestureRecognizer;
    return self.cell.window && self.headView.window &&
           NeoWCEnhancementEnabled(NeoWCAvatarQuickMenuGestureKey);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    (void)gestureRecognizer;
    (void)otherGestureRecognizer;
    return NO;
}

@end

@implementation NeoWCWeakObjectBox
@end

@interface NeoWCQuickReplyPlusGestureDelegate : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, weak) MMInputToolView *toolView;
@end

@implementation NeoWCQuickReplyPlusGestureDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    MMInputToolView *toolView = self.toolView;
    if (!toolView) return NO;
    BOOL quickReplyEnabled = NeoWCEnhancementEnabled(NeoWCQuickReplyEnabledKey);
    if (!quickReplyEnabled) return NO;
    UIView *candidate = [toolView hitTest:[gestureRecognizer locationInView:toolView] withEvent:nil];
    UIView *sendButton = NeoWCTweakValueForSelectorNames(toolView, @[@"sendButton", @"_sendButton"]);
    UIView *attachmentButton = NeoWCTweakValueForSelectorNames(toolView, @[@"attachmentButton", @"_attachmentButton"]);
    while (candidate && candidate != toolView) {
        if (candidate == sendButton) return NO;
        if (candidate == attachmentButton) return quickReplyEnabled;
        if ([candidate isKindOfClass:UIControl.class]) {
            NSMutableString *semanticText = [NSMutableString string];
            for (NSString *value in @[candidate.accessibilityLabel ?: @"",
                                      candidate.accessibilityIdentifier ?: @"",
                                      [candidate isKindOfClass:UIButton.class] ? [(UIButton *)candidate currentTitle] ?: @"" : @""]) {
                if (value.length > 0) [semanticText appendFormat:@" %@", value.lowercaseString];
            }
            if ([semanticText containsString:@"发送"] || [semanticText containsString:@"send"]) {
                return NO;
            }
            if ([semanticText containsString:@"更多"] || [semanticText containsString:@"添加"] ||
                [semanticText containsString:@"加号"] || [semanticText containsString:@"more"] ||
                [semanticText containsString:@"plus"] || [semanticText containsString:@"add"]) {
                return quickReplyEnabled;
            }
        }
        candidate = candidate.superview;
    }
    return NO;
}

@end


@interface NeoWCEncryptedImagePreviewController : UIViewController
@property (nonatomic, strong) UIImage *image;
@end

@interface NeoWCEncryptedVideoPreviewController : AVPlayerViewController
@property (nonatomic, copy) NSString *temporaryPath;
@end

static BOOL NeoWCMediaEncryptionActive(void) {
    return NeoWCEnhancementEnabled(NeoWCEncryptedMessageEnabledKey) &&
           NeoWCEnhancementEnabled(NeoWCMediaEncryptionEnabledKey);
}

static NSString *NeoWCEncryptionTemporaryDirectory(NSString *component) {
    NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent:@"NeoWCEncryption"];
    NSString *directory = component.length > 0 ? [root stringByAppendingPathComponent:component] : root;
    [NSFileManager.defaultManager createDirectoryAtPath:directory
                             withIntermediateDirectories:YES attributes:nil error:nil];
    return directory;
}

static NSString *NeoWCEncryptedMediaSenderUserName(void) {
    Class contextClass = objc_getClass("MMContext");
    SEL currentUserNameSelector = sel_registerName("currentUserName");
    if (contextClass && [contextClass respondsToSelector:currentUserNameSelector]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(contextClass, currentUserNameSelector);
        if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    }
    Class settingClass = objc_getClass("SettingUtil");
    SEL localUserNameSelector = sel_registerName("getLocalUsrName");
    if (settingClass && [settingClass respondsToSelector:localUserNameSelector]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(settingClass, localUserNameSelector);
        if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    }
    return NeoWCCurrentUserWXID();
}

static BOOL NeoWCSendEncryptedMediaFile(NSString *path,
                                        NSString *fileName,
                                        NSString *target,
                                        uint8_t type) {
    if (path.length == 0 || fileName.length == 0 || target.length == 0) return NO;
    Class wrapClass = objc_getClass("CMessageWrap");
    if (!wrapClass) return NO;
    NSString *extensionName = fileName.pathExtension;
    NSString *sender = NeoWCEncryptedMediaSenderUserName();
    if (extensionName.length == 0 || sender.length == 0) return NO;
    id wrap = nil;
    @try {
        Class forwardUtilClass = objc_getClass("ForwardMsgUtil");
        SEL buildSelector = sel_registerName("buildFileMsgWithFileName:filePath:fileExt:");
        if (forwardUtilClass && [forwardUtilClass respondsToSelector:buildSelector]) {
            wrap = ((id (*)(id, SEL, NSString *, NSString *, NSString *))objc_msgSend)(
                forwardUtilClass, buildSelector, fileName, path, extensionName ?: @"");
        }
        SEL generateSelector = sel_registerName("genFileAppMsgWithFileName:filePath:fileData:");
        if (!wrap && [wrapClass respondsToSelector:generateSelector]) {
            NSData *mappedData = [NSData dataWithContentsOfFile:path
                                                       options:NSDataReadingMappedIfSafe error:nil];
            if (mappedData) {
                wrap = ((id (*)(id, SEL, NSString *, NSString *, NSData *))objc_msgSend)(
                    wrapClass, generateSelector, fileName, path, mappedData);
            }
        }
    } @catch (__unused NSException *exception) {
        return NO;
    }
    if (!wrap) return NO;
    NSUInteger now = (NSUInteger)NSDate.date.timeIntervalSince1970;
    // Match WeChatX's native file-message setter order. In particular, leave
    // the inner app-message type and data size produced by ForwardMsgUtil
    // untouched; rewriting those fields makes WeChat validate WXC bytes as
    // ordinary image/video payloads.
    NeoWCTweakSetValue(wrap, @"m_nsFromUsr", sender);
    NeoWCTweakSetValue(wrap, @"m_nsToUsr", target);
    NeoWCTweakSetValue(wrap, @"m_nsTitle", fileName);
    NeoWCTweakSetValue(wrap, @"m_nsAppFileName", fileName);
    NeoWCTweakSetValue(wrap, @"m_nsAppFileExt", extensionName ?: @"");
    NeoWCTweakSetValue(wrap, @"m_uiCreateTime", @(now));
    NeoWCTweakSetValue(wrap, @"m_uiStatus", @1);
    if (type == NeoWCWXCFileTypeVideo) NeoWCTweakSetValue(wrap, @"m_previewType", @0);

    id manager = NeoWCMessageManager();
    if (!manager) return NO;
    BOOL submitted = NO;
    @try {
        SEL pathSelector = sel_registerName("AddAppMsg:MsgWrap:DataPath:Scene:");
        if ([manager respondsToSelector:pathSelector]) {
            ((void (*)(id, SEL, NSString *, id, NSString *, NSUInteger))objc_msgSend)(
                manager, pathSelector, target, wrap, path, 0);
            submitted = YES;
        } else {
            NSData *fileData = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
            SEL dataSelector = sel_registerName("AddAppMsg:MsgWrap:Data:Scene:");
            if (fileData.length > 0 && [manager respondsToSelector:dataSelector]) {
                ((void (*)(id, SEL, NSString *, id, NSData *, NSUInteger))objc_msgSend)(
                    manager, dataSelector, target, wrap, fileData, 0);
                submitted = YES;
            }
        }
    } @catch (__unused NSException *exception) {
        return NO;
    }
    if (!submitted) return NO;
    NSString *cleanupPath = [path copy];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * 60.0 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [NSFileManager.defaultManager removeItemAtPath:cleanupPath error:nil];
    });
    NeoWCCompatibilityMarkTriggered(@"encrypted-media-send");
    return YES;
}

static id NeoWCAlbumEncryptionStateOwner(id controller) {
    id controlCenter = NeoWCTweakValueForSelectorNames(controller, @[@"controlCenter"]);
    if (controlCenter) return controlCenter;
    if ([controller isKindOfClass:UIViewController.class]) {
        UINavigationController *navigationController =
            ((UIViewController *)controller).navigationController;
        if (navigationController) return navigationController;
    }
    return controller;
}

// Matches WeChatX's compact native-looking picker control: a small check
// glyph followed by a label, rather than a full-width system button.
@interface NeoWCAlbumEncryptionButton : UIControl
@property(nonatomic, strong) UIImageView *checkImageView;
@property(nonatomic, strong) UILabel *checkTitleLabel;
@end

@implementation NeoWCAlbumEncryptionButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    _checkImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _checkImageView.contentMode = UIViewContentModeScaleAspectFit;
    _checkImageView.userInteractionEnabled = NO;
    [self addSubview:_checkImageView];
    _checkTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _checkTitleLabel.text = @"加密";
    _checkTitleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    _checkTitleLabel.textAlignment = NSTextAlignmentLeft;
    _checkTitleLabel.userInteractionEnabled = NO;
    [self addSubview:_checkTitleLabel];
    self.accessibilityLabel = @"加密";
    self.selected = NO;
    return self;
}
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    UIImage *image = [UIImage systemImageNamed:selected ? @"checkmark.circle.fill" : @"circle"];
    self.checkImageView.image = image;
    UIColor *color = selected ? [UIColor colorWithRed:0.10 green:0.72 blue:0.36 alpha:1.0]
                              : UIColor.secondaryLabelColor;
    self.checkImageView.tintColor = color;
    self.checkTitleLabel.textColor = color;
    self.accessibilityValue = selected ? @"已选中" : @"未选中";
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = MIN(21.0, CGRectGetHeight(self.bounds));
    CGFloat y = floor((CGRectGetHeight(self.bounds) - h) * 0.5);
    self.checkImageView.frame = CGRectMake(0.0, y, h, h);
    self.checkTitleLabel.frame = CGRectMake(27.0, y,
                                             MAX(0.0, CGRectGetWidth(self.bounds) - 27.0), h);
}
@end

static BOOL NeoWCAlbumEncryptionSelected(id controller) {
    id owner = NeoWCAlbumEncryptionStateOwner(controller);
    return [objc_getAssociatedObject(owner, &NeoWCAlbumEncryptionSelectedKey) boolValue];
}

static void NeoWCUpdateAlbumEncryptionButton(id controller) {
    NeoWCAlbumEncryptionButton *button = objc_getAssociatedObject(controller, &NeoWCAlbumEncryptionButtonKey);
    if (!button) return;
    BOOL selected = NeoWCAlbumEncryptionSelected(controller);
    button.selected = selected;
}

static void NeoWCToggleAlbumEncryption(id controller) {
    id owner = NeoWCAlbumEncryptionStateOwner(controller);
    BOOL selected = ![objc_getAssociatedObject(owner, &NeoWCAlbumEncryptionSelectedKey) boolValue];
    objc_setAssociatedObject(owner, &NeoWCAlbumEncryptionSelectedKey, @(selected),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCUpdateAlbumEncryptionButton(controller);
}

static UIView *NeoWCAlbumViewForSelectorNames(id controller, NSArray<NSString *> *selectorNames) {
    id value = NeoWCTweakValueForSelectorNames(controller, selectorNames);
    return [value isKindOfClass:UIView.class] ? value : nil;
}

static UILabel *NeoWCFirstLabelInView(UIView *view) {
    if ([view isKindOfClass:UILabel.class]) return (UILabel *)view;
    for (UIView *subview in view.subviews) {
        UILabel *label = NeoWCFirstLabelInView(subview);
        if (label) return label;
    }
    return nil;
}

static BOOL NeoWCAlbumViewContributesToLayout(UIView *view, UIView *container) {
    return view && view != container && view.superview && !view.hidden && view.alpha > 0.01 &&
           CGRectGetWidth(view.bounds) > 0.0 && CGRectGetHeight(view.bounds) > 0.0;
}

static CGRect NeoWCAlbumFrameInContainer(UIView *view, UIView *container) {
    return [view.superview convertRect:view.frame toView:container];
}

static void NeoWCShiftAlbumViewHorizontally(UIView *view, UIView *container, CGFloat deltaX,
                                            NSSet<UIView *> *shiftedAncestors) {
    if (!NeoWCAlbumViewContributesToLayout(view, container)) return;
    for (UIView *ancestor = view.superview; ancestor && ancestor != container; ancestor = ancestor.superview) {
        if ([shiftedAncestors containsObject:ancestor]) return;
    }
    CGRect frameInContainer = NeoWCAlbumFrameInContainer(view, container);
    frameInContainer.origin.x += deltaX;
    view.frame = [container convertRect:frameInContainer toView:view.superview];
}

static void NeoWCLayoutAlbumEncryptionButton(id controller, NSString *originCheckKey) {
    if (!controller) return;
    NeoWCAlbumEncryptionButton *button = objc_getAssociatedObject(controller, &NeoWCAlbumEncryptionButtonKey);
    if (!NeoWCMediaEncryptionActive()) {
        button.hidden = YES;
        objc_setAssociatedObject(NeoWCAlbumEncryptionStateOwner(controller),
                                 &NeoWCAlbumEncryptionSelectedKey, @NO,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    UIView *originCheck = NeoWCTweakSafeValue(controller, originCheckKey);
    if (![originCheck isKindOfClass:UIView.class]) {
        NSString *fallbackKey = [originCheckKey hasPrefix:@"_"]
            ? [originCheckKey substringFromIndex:1]
            : [@"_" stringByAppendingString:originCheckKey];
        originCheck = NeoWCTweakSafeValue(controller, fallbackKey);
    }
    if (![originCheck isKindOfClass:UIView.class]) {
        originCheck = NeoWCTweakSafeValue(controller, @"originImageCheck");
    }
    if (![originCheck isKindOfClass:UIView.class] || !originCheck.superview) return;
    if (!button) {
        button = [[NeoWCAlbumEncryptionButton alloc] initWithFrame:CGRectZero];
        [button addTarget:controller action:NSSelectorFromString(@"neowc_toggleAlbumEncryption:")
             forControlEvents:UIControlEventTouchUpInside];
        [originCheck.superview addSubview:button];
        objc_setAssociatedObject(controller, &NeoWCAlbumEncryptionButtonKey, button,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (button.superview != originCheck.superview) {
        [button removeFromSuperview];
        [originCheck.superview addSubview:button];
    }
    UIView *container = originCheck.superview;
    UIView *originLabel = NeoWCAlbumViewForSelectorNames(controller,
        @[@"_originImageLabel", @"originImageLabel"]);
    UIView *originIcon = NeoWCAlbumViewForSelectorNames(controller,
        @[@"originSelectIconView", @"_originSelectIconView"]);
    UIView *rawSizeLabel = NeoWCAlbumViewForSelectorNames(controller,
        @[@"rawTotalSizeLabel", @"_rawTotalSizeLabel"]);
    if (!originLabel) originLabel = NeoWCFirstLabelInView(container);

    NSMutableArray<UIView *> *originViews = [NSMutableArray arrayWithObject:originCheck];
    for (UIView *candidate in @[originLabel ?: (UIView *)NSNull.null,
                                originIcon ?: (UIView *)NSNull.null,
                                rawSizeLabel ?: (UIView *)NSNull.null]) {
        if (![candidate isKindOfClass:UIView.class] || [originViews containsObject:candidate] ||
            !NeoWCAlbumViewContributesToLayout(candidate, container)) continue;
        [originViews addObject:candidate];
    }

    CGRect originUnion = CGRectNull;
    for (UIView *view in originViews) {
        if (!NeoWCAlbumViewContributesToLayout(view, container)) continue;
        CGRect frame = NeoWCAlbumFrameInContainer(view, container);
        originUnion = CGRectIsNull(originUnion) ? frame : CGRectUnion(originUnion, frame);
    }
    if (CGRectIsNull(originUnion) || CGRectIsEmpty(originUnion)) return;

    CGFloat slotWidth = MAX(CGRectGetWidth(originUnion), 64.0);
    CGFloat gap = 14.0;
    CGFloat groupLeft = floor((CGRectGetWidth(container.bounds) - (slotWidth * 2.0 + gap)) * 0.5);
    CGFloat deltaX = groupLeft - CGRectGetMinX(originUnion);
    NSSet<UIView *> *originViewSet = [NSSet setWithArray:originViews];
    for (UIView *view in originViews) {
        NeoWCShiftAlbumViewHorizontally(view, container, deltaX, originViewSet);
    }

    CGFloat height = MAX(CGRectGetHeight(originUnion), 32.0);
    CGFloat x = groupLeft + slotWidth + gap;
    CGFloat y = CGRectGetMidY(originUnion) - height * 0.5;
    button.frame = CGRectIntegral(CGRectMake(x, y, slotWidth, height));
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    button.hidden = NO;
    NeoWCUpdateAlbumEncryptionButton(controller);
}

static NSString *NeoWCSanitizedMediaExtension(NSString *extensionName, BOOL video) {
    NSString *value = extensionName.lowercaseString ?: @"";
    NSCharacterSet *invalid = [NSCharacterSet.alphanumericCharacterSet invertedSet];
    value = [[value componentsSeparatedByCharactersInSet:invalid] componentsJoinedByString:@""];
    if (value.length > 12) value = [value substringToIndex:12];
    return value.length > 0 ? value : (video ? @"mp4" : @"jpg");
}

static NSString *NeoWCOriginalAssetFileName(id asset, BOOL video) {
    id value = NeoWCTweakValueForSelectorNames(asset, @[@"originalFilename", @"assetFileName", @"fileName"]);
    if (![value isKindOfClass:NSString.class] || [value length] == 0) {
        value = video ? @"视频.mp4" : @"图片.jpg";
    }
    return [value lastPathComponent];
}

static NSString *NeoWCOfficialAlbumTarget(id controller) {
    id value = nil;
    // Prefer the live picker/presenting hierarchy. An associated target can
    // belong to a reused picker from the previous conversation.
    id cursor = controller;
    for (NSUInteger depth = 0; cursor && depth < 8; depth++) {
        value = NeoWCTweakValueForSelectorNames(cursor, @[@"getCurrentChatName",
            @"m_nsUserName", @"m_nsUsrName", @"sessionUserName", @"chatName", @"m_chatName",
            @"m_sessionName", @"m_nsSessionName"]);
        if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
        value = NeoWCChatUserName(cursor);
        if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
        id related = NeoWCTweakValueForSelectorNames(cursor, @[@"delegate", @"m_delegate",
            @"context", @"m_context", @"sessionInfo", @"m_sessionInfo"]);
        value = NeoWCChatUserName(related);
        if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
        if ([cursor isKindOfClass:UIViewController.class]) {
            UIViewController *viewController = cursor;
            UINavigationController *navigationController = viewController.navigationController;
            for (UIViewController *candidate in navigationController.viewControllers.reverseObjectEnumerator) {
                value = NeoWCTweakValueForSelectorNames(candidate, @[@"getCurrentChatName"]);
                if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
                value = NeoWCChatUserName(candidate);
                if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
            }
            cursor = viewController.presentingViewController ?: viewController.parentViewController;
        } else {
            break;
        }
    }
    value = objc_getAssociatedObject(controller, &NeoWCOfficialAlbumTargetKey);
    if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    value = NeoWCChatUserName(NeoWCVisibleChatController);
    return [value isKindOfClass:NSString.class] ? value : nil;
}

static NSArray *NeoWCOfficialSelectedAssets(id controller) {
    id value = NeoWCTweakValueForSelectorNames(controller, @[@"getSelectedAssets"]);
    if (![value isKindOfClass:NSArray.class]) {
        value = NeoWCTweakValueForSelectorNames(NeoWCAlbumEncryptionStateOwner(controller),
                                                @[@"getSelectedAssets", @"selectedAssets"]);
    }
    return [value isKindOfClass:NSArray.class] ? value : @[];
}

static void NeoWCEncryptAndSendOfficialMedia(NSString *inputPath,
                                             NSString *originalFileName,
                                             NSString *target,
                                             BOOL video,
                                             BOOL removeInput,
                                             void (^completion)(BOOL success)) {
    NSString *plainExtension = NeoWCSanitizedMediaExtension(inputPath.pathExtension.length > 0
        ? inputPath.pathExtension : originalFileName.pathExtension, video);
    NSString *baseName = originalFileName.lastPathComponent.stringByDeletingPathExtension;
    if (baseName.length == 0) baseName = video ? @"视频" : @"图片";
    NSString *displayName = [baseName stringByAppendingPathExtension:@"WeChatX"];
    NSString *outputName = [NSString stringWithFormat:@"%@_%@.%@",
        video ? @"WXC_VIDEO" : @"WXC_IMAGE", NSUUID.UUID.UUIDString, plainExtension];
    NSString *outputPath = [NeoWCEncryptionTemporaryDirectory(@"Upload")
        stringByAppendingPathComponent:outputName];
    NSString *metadata = [@"a:" stringByAppendingString:plainExtension];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NeoWCWXCFileType type = video ? NeoWCWXCFileTypeVideo : NeoWCWXCFileTypeImage;
        BOOL encrypted = NeoWCWXCEncryptFile(inputPath, outputPath, type, metadata, &error);
        if (removeInput) [NSFileManager.defaultManager removeItemAtPath:inputPath error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL sent = encrypted && NeoWCSendEncryptedMediaFile(outputPath, displayName, target, type);
            if (!sent) [NSFileManager.defaultManager removeItemAtPath:outputPath error:nil];
            if (!encrypted) NeoWCShowTransientMessage(error.localizedDescription ?: @"媒体加密失败", NO);
            if (completion) completion(sent);
        });
    });
}

static NSString *NeoWCImageExtensionForData(NSData *data, NSString *originalFileName) {
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    if (data.length >= 8 && bytes[0] == 0x89 && memcmp(bytes + 1, "PNG\r\n\x1a\n", 7) == 0) return @"png";
    if (data.length >= 3 && bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) return @"jpg";
    if (data.length >= 6 && memcmp(bytes, "GIF8", 4) == 0) return @"gif";
    return NeoWCSanitizedMediaExtension(originalFileName.pathExtension, NO);
}

static void NeoWCProcessOfficialImageAsset(id asset, NSString *target, void (^completion)(BOOL)) {
    NSString *originalName = NeoWCOriginalAssetFileName(asset, NO);
    void (^success)(id) = ^(id payload) {
        NSData *data = [payload isKindOfClass:NSData.class] ? payload :
            ([payload isKindOfClass:UIImage.class] ? UIImageJPEGRepresentation(payload, 1.0) : nil);
        if (data.length == 0) { if (completion) completion(NO); return; }
        NSString *extensionName = [payload isKindOfClass:UIImage.class] ? @"jpg" :
            NeoWCImageExtensionForData(data, originalName);
        NSString *inputName = [NSString stringWithFormat:@"image_%@.%@",
            NSUUID.UUID.UUIDString, extensionName];
        NSString *inputPath = [NeoWCEncryptionTemporaryDirectory(@"Album")
            stringByAppendingPathComponent:inputName];
        NSError *writeError = nil;
        if (![data writeToFile:inputPath options:NSDataWritingAtomic error:&writeError]) {
            if (completion) completion(NO);
            return;
        }
        NeoWCEncryptAndSendOfficialMedia(inputPath, originalName, target, NO, YES, completion);
    };
    void (^failure)(id) = ^(id error) {
        (void)error;
        if (completion) completion(NO);
    };
    SEL sourceSelector = NSSelectorFromString(@"asyncImageOriginSourceData:errorBlock:");
    SEL originSelector = NSSelectorFromString(@"asyncImageOriginData:completion:errorBlock:");
    if ([asset respondsToSelector:sourceSelector]) {
        ((void (*)(id, SEL, id, id))objc_msgSend)(asset, sourceSelector, success, failure);
    } else if ([asset respondsToSelector:originSelector]) {
        ((void (*)(id, SEL, BOOL, id, id))objc_msgSend)(asset, originSelector, NO, success, failure);
    } else {
        id URLValue = NeoWCTweakValueForSelectorNames(asset, @[@"assetUrl", @"mediaURL"]);
        NSString *path = [URLValue isKindOfClass:NSURL.class] ? [URLValue path] :
            ([URLValue isKindOfClass:NSString.class] ? URLValue : nil);
        NSData *data = path.length > 0 ? [NSData dataWithContentsOfFile:path] : nil;
        success(data);
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static void NeoWCProcessOfficialVideoAsset(id asset, NSString *target, void (^completion)(BOOL)) {
    NSString *originalName = NeoWCOriginalAssetFileName(asset, YES);
    void (^success)(id) = ^(id payload) {
        AVAsset *AVAssetValue = [payload isKindOfClass:AVAsset.class] ? payload : nil;
        if (!AVAssetValue) { if (completion) completion(NO); return; }
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
            initWithAsset:AVAssetValue presetName:AVAssetExportPresetPassthrough];
        if (!exporter) { if (completion) completion(NO); return; }
        NSArray *supportedTypes = exporter.supportedFileTypes;
        AVFileType fileType = nil;
        if ([supportedTypes containsObject:AVFileTypeMPEG4]) {
            fileType = AVFileTypeMPEG4;
        } else if ([supportedTypes containsObject:AVFileTypeQuickTimeMovie]) {
            fileType = AVFileTypeQuickTimeMovie;
        }
        if (fileType.length == 0) { if (completion) completion(NO); return; }
        NSString *extensionName = [fileType isEqualToString:AVFileTypeMPEG4] ? @"mp4" : @"mov";
        NSString *inputName = [NSString stringWithFormat:@"video_%@.%@",
            NSUUID.UUID.UUIDString, extensionName];
        NSString *inputPath = [NeoWCEncryptionTemporaryDirectory(@"Album")
            stringByAppendingPathComponent:inputName];
        [NSFileManager.defaultManager removeItemAtPath:inputPath error:nil];
        exporter.outputURL = [NSURL fileURLWithPath:inputPath];
        exporter.outputFileType = fileType;
        exporter.shouldOptimizeForNetworkUse = NO;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            if (exporter.status != AVAssetExportSessionStatusCompleted) {
                [NSFileManager.defaultManager removeItemAtPath:inputPath error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(NO); });
                return;
            }
            NeoWCEncryptAndSendOfficialMedia(inputPath, originalName, target, YES, YES, completion);
        }];
    };
    void (^failure)(id) = ^(id error) {
        (void)error;
        if (completion) completion(NO);
    };
    SEL selector = NSSelectorFromString(@"asyncGetVideoAsset:successBlock:errorBlock:");
    if ([asset respondsToSelector:selector]) {
        ((void (*)(id, SEL, BOOL, id, id))objc_msgSend)(asset, selector, YES, success, failure);
    } else {
        id URLValue = NeoWCTweakValueForSelectorNames(asset, @[@"assetUrl", @"mediaURL"]);
        NSURL *URL = [URLValue isKindOfClass:NSURL.class] ? URLValue :
            ([URLValue isKindOfClass:NSString.class] ? [NSURL fileURLWithPath:URLValue] : nil);
        success(URL ? [AVURLAsset URLAssetWithURL:URL options:nil] : nil);
    }
}
#pragma clang diagnostic pop

static NSArray *NeoWCOfficialAssetsFromPreviewInfos(id assetInfos) {
    if (![assetInfos isKindOfClass:NSArray.class]) return @[];
    NSMutableArray *assets = [NSMutableArray array];
    for (id item in (NSArray *)assetInfos) {
        id asset = nil;
        if ([item respondsToSelector:NSSelectorFromString(@"asyncImageOriginSourceData:errorBlock:")] ||
            [item respondsToSelector:NSSelectorFromString(@"asyncGetVideoAsset:successBlock:errorBlock:")]) {
            asset = item;
        } else if ([item isKindOfClass:NSDictionary.class]) {
            for (NSString *key in @[@"asset", @"mmAsset", @"mediaAsset", @"originalAsset"]) {
                id candidate = ((NSDictionary *)item)[key];
                if (candidate) { asset = candidate; break; }
            }
        } else {
            asset = NeoWCTweakValueForSelectorNames(item, @[@"asset", @"mmAsset", @"mediaAsset", @"originalAsset"]);
        }
        if (asset) [assets addObject:asset];
    }
    return assets;
}

static BOOL NeoWCAlbumEncryptionButtonIsExplicitlySelected(id controller) {
    NeoWCAlbumEncryptionButton *button =
        objc_getAssociatedObject(controller, &NeoWCAlbumEncryptionButtonKey);
    return NeoWCAlbumEncryptionSelected(controller) &&
           button && !button.hidden && button.isSelected;
}

static BOOL NeoWCHandleOfficialEncryptedMediaSend(id controller,
                                                   id selectionController,
                                                   NSArray *assetOverride) {
    // Do not touch WeChat's send state unless the control visible on the exact
    // sending surface is explicitly selected.  Picker and preview controllers
    // can coexist and their callbacks are chained by WeChat.
    if (!NeoWCMediaEncryptionActive() ||
        !NeoWCAlbumEncryptionButtonIsExplicitlySelected(selectionController)) return NO;
    if ([objc_getAssociatedObject(controller, &NeoWCAlbumEncryptionSendingKey) boolValue]) return YES;
    NSArray *assets = assetOverride.count > 0 ? assetOverride : NeoWCOfficialSelectedAssets(controller);
    NSString *target = NeoWCOfficialAlbumTarget(controller);
    if (assets.count == 0 || target.length == 0) {
        NeoWCShowTransientMessage(assets.count == 0 ? @"请先选择图片或视频" : @"无法确定当前聊天", NO);
        return YES;
    }
    objc_setAssociatedObject(controller, &NeoWCAlbumEncryptionSendingKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __block NSUInteger remaining = assets.count;
    __block NSUInteger sentCount = 0;
    void (^finishedOne)(BOOL) = ^(BOOL sent) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sent) sentCount++;
            if (remaining > 0) remaining--;
            if (remaining != 0) return;
            objc_setAssociatedObject(controller, &NeoWCAlbumEncryptionSendingKey, nil,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UIViewController *viewController = [controller isKindOfClass:UIViewController.class] ? controller : nil;
            UIViewController *dismissTarget = viewController.navigationController ?: viewController;
            [dismissTarget dismissViewControllerAnimated:YES completion:nil];
            NeoWCShowTransientMessage(sentCount == assets.count
                ? [NSString stringWithFormat:@"已发送 %lu 个加密媒体", (unsigned long)sentCount]
                : [NSString stringWithFormat:@"已发送 %lu/%lu 个加密媒体",
                   (unsigned long)sentCount, (unsigned long)assets.count], sentCount > 0);
            if (sentCount > 0) NeoWCCompatibilityMarkTriggered(@"official-album-encrypted-send");
        });
    };
    for (id asset in assets) {
        NSObject *completionGate = [NSObject new];
        __block BOOL didFinish = NO;
        void (^finishOnce)(BOOL) = ^(BOOL sent) {
            @synchronized (completionGate) {
                if (didFinish) return;
                didFinish = YES;
            }
            finishedOne(sent);
        };
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            finishOnce(NO);
        });
        BOOL video = NO;
        SEL isVideoSelector = NSSelectorFromString(@"isVideo");
        if ([asset respondsToSelector:isVideoSelector]) {
            video = ((BOOL (*)(id, SEL))objc_msgSend)(asset, isVideoSelector);
        }
        if (video) NeoWCProcessOfficialVideoAsset(asset, target, finishOnce);
        else NeoWCProcessOfficialImageAsset(asset, target, finishOnce);
    }
    return YES;
}

@implementation NeoWCEncryptedImagePreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = self.image;
    [self.view addSubview:imageView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePreview)];
    [self.view addGestureRecognizer:tap];
}

- (void)closePreview { [self dismissViewControllerAnimated:YES completion:nil]; }
- (BOOL)prefersStatusBarHidden { return YES; }

@end

@implementation NeoWCEncryptedVideoPreviewController

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed || !self.presentingViewController) {
        [self.player pause];
        [NSFileManager.defaultManager removeItemAtPath:self.temporaryPath error:nil];
        self.temporaryPath = nil;
    }
}

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
    if (velocity.x > 0.0 && NeoWCNavigationReturnGesturesForView(self.cell).count > 0) {
        CGFloat edgeWidth = MAX(50.0, self.cell.window.safeAreaInsets.left + 32.0);
        if (self.initialWindowX <= edgeWidth) return NO;
    }
    CGPoint location = [pan locationInView:self.cell];
    CGFloat width = CGRectGetWidth(self.cell.bounds);
    return location.x >= 24.0 && location.x <= MAX(24.0, width - 24.0);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {
    UIWindow *window = self.cell.window;
    self.initialWindowX = window ? [touch locationInView:window].x : CGFLOAT_MAX;
    if (!window || NeoWCNavigationReturnGesturesForView(self.cell).count == 0) return YES;
    CGFloat edgeWidth = MAX(50.0, window.safeAreaInsets.left + 32.0);
    // The decision is based on the original touch, not the later point at which
    // UIKit asks shouldBegin. This prevents an edge-back drag from entering a
    // message cell and subsequently firing its configured right-swipe action.
    return self.initialWindowX > edgeWidth;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    (void)gestureRecognizer;
    return NeoWCIsNavigationReturnGesture(otherGestureRecognizer, self.cell);
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
            NSArray *snapshots = objc_getAssociatedObject(cell, &NeoWCReplyTransformSnapshotsKey);
            if (snapshots.count) NeoWCRestoreReplyTransforms(snapshots);
            else {
                NSValue *originalTransform = objc_getAssociatedObject(cell, &NeoWCReplyOriginalTransformKey);
                if (originalTransform) cell.transform = originalTransform.CGAffineTransformValue;
            }
            [cell removeGestureRecognizer:panRecognizer];
        }
        objc_setAssociatedObject(cell, &NeoWCReplyPanRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCReplyPanDelegateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCReplyOriginalTransformKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCReplyTransformSnapshotsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        for (UIGestureRecognizer *returnGesture in NeoWCNavigationReturnGesturesForView(cell)) {
            if (returnGesture != panRecognizer) [panRecognizer requireGestureRecognizerToFail:returnGesture];
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
    Class managerClass = objc_getClass("CMessageMgr");
    return NeoWCServiceForClass(managerClass);
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

static BOOL NeoWCSendVoiceMessage(id source, NSString *sourcePathOverride, NSString *session) {
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
    if ((sourcePathOverride.length == 0 && ![source respondsToSelector:voicePathSelector]) ||
        !manager ||
        ![manager respondsToSelector:addLocalSelector] ||
        !messageWrapClass ||
        ![messageWrapClass respondsToSelector:destinationPathSelector] ||
        !audioSender) {
        NeoWCLog(@"语音复读入口不完整，取消发送");
        return NO;
    }

    NSString *sourcePath = sourcePathOverride;
    if (sourcePath.length == 0) sourcePath = ((id (*)(id, SEL))objc_msgSend)(source, voicePathSelector);
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
            NSString *destinationDirectory = destinationPath.stringByDeletingLastPathComponent;
            if (destinationDirectory.length > 0) {
                [[NSFileManager defaultManager] createDirectoryAtPath:destinationDirectory
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:nil];
            }
            [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
            NSError *copyError = nil;
            voiceSaved = [[NSFileManager defaultManager] copyItemAtPath:sourcePath
                                                                 toPath:destinationPath
                                                                  error:&copyError];
            if (!voiceSaved && [manager respondsToSelector:saveVoiceSelector]) {
                NSData *voiceData = [NSData dataWithContentsOfFile:sourcePath];
                if (voiceData.length > 0) {
                    voiceSaved = ((BOOL (*)(id, SEL, id, id))objc_msgSend)(manager,
                                                                           saveVoiceSelector,
                                                                           voiceData,
                                                                           repeated);
                }
            }
            NSDictionary *destinationAttributes = [[NSFileManager defaultManager]
                                                    attributesOfItemAtPath:destinationPath
                                                    error:nil];
            unsigned long long destinationSize = [destinationAttributes[NSFileSize] unsignedLongLongValue];
            if (!voiceSaved || destinationSize == 0) {
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
        NeoWCVoiceRepeatForwardDeadline = NSDate.date.timeIntervalSince1970 + 12.0;
        ((void (*)(id, SEL, id, id))objc_msgSend)(resendTarget, resendSelector, session, repeated);
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"语音复读调用失败：%@", exception.reason ?: exception.name);
        return NO;
    }
}

static BOOL NeoWCRepeatVoiceMessage(id source, NSString *session) {
    return NeoWCSendVoiceMessage(source, nil, session);
}

static NSString *NeoWCVoiceForwardSessionForContact(id contact) {
    if (!contact) return nil;
    if ([contact isKindOfClass:[NSString class]] && [contact length] > 0) return contact;
    for (NSString *key in @[@"m_nsUsrName", @"userName", @"username"]) {
        id value = NeoWCTweakSafeValue(contact, key);
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    return nil;
}

// WeChat's stock forward controller accepts voice messages into its local
// result flow, but current versions do not start a usable voice upload for
// them. Match WeChatX by consuming voice wraps before the stock forward path
// and sending each one through AudioSender's native resend pipeline.
static NSArray *NeoWCForwardMessagesBySendingVoices(NSArray *messages,
                                                    NSArray *contacts,
                                                    NSIndexSet **handledIndexes) {
    if (handledIndexes) *handledIndexes = nil;
    if (!NeoWCEnhancementEnabled(NeoWCVoiceForwardEnabledKey) ||
        ![messages isKindOfClass:[NSArray class]] || messages.count == 0 ||
        ![contacts isKindOfClass:[NSArray class]] || contacts.count == 0) {
        return messages;
    }

    NSMutableArray *remaining = [NSMutableArray arrayWithCapacity:messages.count];
    NSMutableIndexSet *handled = [NSMutableIndexSet indexSet];
    [messages enumerateObjectsUsingBlock:^(id message, NSUInteger index, BOOL *stop) {
        (void)stop;
        if ([NeoWCTweakSafeValue(message, @"m_uiMessageType") integerValue] != 34) {
            [remaining addObject:message];
            return;
        }

        BOOL sentToEveryContact = YES;
        for (id contact in contacts) {
            NSString *session = NeoWCVoiceForwardSessionForContact(contact);
            if (session.length == 0 || !NeoWCRepeatVoiceMessage(message, session)) {
                sentToEveryContact = NO;
                break;
            }
        }
        if (sentToEveryContact) {
            [handled addIndex:index];
            NeoWCCompatibilityMarkTriggered(@"voice-forward");
        } else {
            [remaining addObject:message];
        }
    }];
    if (handledIndexes && handled.count > 0) *handledIndexes = [handled copy];
    return remaining;
}

static NSArray *NeoWCVoiceForwardFilteredOrigins(NSArray *origins, NSIndexSet *handledIndexes) {
    if (![origins isKindOfClass:[NSArray class]] || handledIndexes.count == 0) return origins;
    NSMutableArray *remaining = [origins mutableCopy];
    [handledIndexes enumerateIndexesWithOptions:NSEnumerationReverse
                                     usingBlock:^(NSUInteger index, BOOL *stop) {
        (void)stop;
        if (index < remaining.count) [remaining removeObjectAtIndex:index];
    }];
    return remaining;
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

static NSString *NeoWCRepeatConfirmationSummary(id message) {
    NSInteger messageType = [NeoWCTweakSafeValue(message, @"m_uiMessageType") integerValue];
    if (messageType == 1) {
        NSString *content = NeoWCTweakSafeValue(message, @"m_nsContent");
        if (content.length > 40) content = [[content substringToIndex:40] stringByAppendingString:@"…"];
        return content.length > 0 ? [NSString stringWithFormat:@"复读文字：%@", content] : @"复读文字消息";
    }
    if (messageType == 3) return @"复读图片消息";
    if (messageType == 34) return @"复读语音消息";
    if (messageType == 43 || messageType == 62) return @"复读视频消息";
    if (messageType == 47 || NeoWCSendConfirmationMessageIsAppEmoticon(message)) return @"复读表情消息";
    return @"复读这条消息";
}

static BOOL NeoWCRepeatMessageWithConfirmation(CommonMessageCellView *cell) {
    id source = NeoWCMessageWrapForCell(cell);
    NSString *target = NeoWCSessionForMessage(source);
    UIViewController *presenter = NeoWCSendConfirmationPresenterForTarget(target);
    if (!presenter) return NeoWCRepeatMessage(cell);
    __weak CommonMessageCellView *weakCell = cell;
    id retainedSource = source;
    BOOL held = NeoWCPresentSendConfirmationIfNeeded(presenter,
                                                      target,
                                                      NeoWCRepeatConfirmationSummary(source),
                                                      ^BOOL{
        CommonMessageCellView *strongCell = weakCell;
        return strongCell && NeoWCSendConfirmationValidateTarget(target) &&
               NeoWCMessageWrapForCell(strongCell) == retainedSource;
    }, ^{
        CommonMessageCellView *strongCell = weakCell;
        if (strongCell && NeoWCMessageWrapForCell(strongCell) == retainedSource) {
            NSInteger messageType = [NeoWCTweakSafeValue(retainedSource, @"m_uiMessageType") integerValue];
            if (messageType == 1 || messageType == 3 || messageType == 43 ||
                messageType == 47 || messageType == 49 || messageType == 62) {
                NeoWCArmRepeatSendConfirmationBypass(target, messageType);
            }
            @try {
                (void)NeoWCRepeatMessage(strongCell);
            } @finally {
                // The exemption belongs only to this synchronous repeat dispatch.
                // If WeChat defers the real send, the downstream hook will ask again
                // instead of allowing an unrelated message through later.
                NeoWCClearRepeatSendConfirmationBypass();
            }
        }
    });
    return held ? YES : NeoWCRepeatMessage(cell);
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
            performed = NeoWCRepeatMessageWithConfirmation(cell);
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

static void NeoWCOpenMomentsHighQualityPicker(UIViewController *timelineController) {
    SEL selector = NSSelectorFromString(@"showImagePicker:");
    if (!timelineController || ![timelineController respondsToSelector:selector]) {
        NeoWCShowTransientMessage(@"当前微信版本不支持朋友圈原生媒体选择", NO);
        return;
    }
    ((void (*)(id, SEL, id))objc_msgSend)(timelineController, selector, nil);
}

static void NeoWCPrepareMomentsHighQualityMenu(WCActionSheet *sheet) {
    if (!sheet || !NeoWCEnhancementEnabled(NeoWCMomentsOriginalMediaPostEnabledKey) ||
        !NeoWCPendingMomentsCameraController ||
        objc_getAssociatedObject(sheet, &NeoWCMomentsHighQualityMenuKey)) return;
    __weak UIViewController *weakController = NeoWCPendingMomentsCameraController;
    objc_setAssociatedObject(sheet, &NeoWCMomentsHighQualityMenuKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    BOOL added = NO;
    @try {
        [sheet addButtonWithTitle:@"选择高清图片/原视频" eventAction:^{
            NeoWCOpenMomentsHighQualityPicker(weakController);
        }];
        added = YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"增加朋友圈高清入口失败：%@", exception.reason ?: @"未知异常");
    }
    if (!added) {
        objc_setAssociatedObject(sheet, &NeoWCMomentsHighQualityMenuKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    NeoWCLog(@"已在朋友圈相机菜单增加高清入口");
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
    // PKC resolves the visible native text cell through this WeChat selector.
    // Prefer it over guessing the internal view-model layout.
    id currentMessage = NeoWCTweakValueForSelectorNames(cell,
        @[@"getCurrentMessageWrap", @"currentMessageWrap"]);
    if (currentMessage) return currentMessage;
    id directMessage = NeoWCImageJokerMessageForObject(cell);
    if (directMessage) return directMessage;
    id viewModel = NeoWCTweakValueForSelectorNames(cell, @[@"viewModel", @"m_viewModel"]);
    // Some WeChat builds expose the wrap directly as the view model rather
    // than under messageWrap; accept it when the content ivar is present.
    id directContent = NeoWCTweakSafeValue(viewModel, @"m_nsContent");
    if ([directContent isKindOfClass:NSString.class]) return viewModel;
    id message = NeoWCTweakValueForSelectorNames(viewModel, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap"]);
    if (message) return message;
    id parentModel = NeoWCTweakSafeValue(viewModel, @"parentModel");
    message = NeoWCTweakValueForSelectorNames(parentModel, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap"]);
    if (message) return message;
    return NeoWCTweakValueForSelectorNames(cell, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap", @"message"]);
}

static NSString *NeoWCImageJokerKeyForMessage(id message);

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

static void NeoWCCollectReplyTransformTargets(UIView *view,
                                               NSString *messageKey,
                                               NSMutableArray<NeoWCReplyTransformSnapshot *> *snapshots) {
    if (!view || !messageKey.length) return;
    id message = NeoWCMessageWrapForCell(view);
    NSString *candidateKey = NeoWCImageJokerKeyForMessage(message);
    if ([candidateKey isEqualToString:messageKey]) {
        NeoWCReplyTransformSnapshot *snapshot = [NeoWCReplyTransformSnapshot new];
        snapshot.view = view;
        snapshot.transform = view.transform;
        [snapshots addObject:snapshot];
        return;
    }
    for (UIView *subview in view.subviews) NeoWCCollectReplyTransformTargets(subview, messageKey, snapshots);
}

static NSArray<NeoWCReplyTransformSnapshot *> *NeoWCReplyTransformSnapshots(CommonMessageCellView *sourceCell) {
    NSString *messageKey = NeoWCImageJokerKeyForMessage(NeoWCMessageWrapForCell(sourceCell));
    NSMutableArray<NeoWCReplyTransformSnapshot *> *snapshots = [NSMutableArray array];
    if (messageKey.length && sourceCell.window) {
        NeoWCCollectReplyTransformTargets(sourceCell.window, messageKey, snapshots);
    }
    if (snapshots.count == 0 && sourceCell) {
        NeoWCReplyTransformSnapshot *snapshot = [NeoWCReplyTransformSnapshot new];
        snapshot.view = sourceCell;
        snapshot.transform = sourceCell.transform;
        [snapshots addObject:snapshot];
    }
    return snapshots;
}

static void NeoWCApplyReplyTransform(NSArray<NeoWCReplyTransformSnapshot *> *snapshots, CGFloat offset) {
    for (NeoWCReplyTransformSnapshot *snapshot in snapshots) {
        UIView *view = snapshot.view;
        if (view.window) view.transform = CGAffineTransformTranslate(snapshot.transform, offset, 0.0);
    }
}

static void NeoWCRestoreReplyTransforms(NSArray<NeoWCReplyTransformSnapshot *> *snapshots) {
    for (NeoWCReplyTransformSnapshot *snapshot in snapshots) {
        if (snapshot.view) snapshot.view.transform = snapshot.transform;
    }
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

static void NeoWCSynchronizeQuickReplyPlusGesture(MMInputToolView *view) {
    if (!view) return;
    UILongPressGestureRecognizer *recognizer = objc_getAssociatedObject(view, &NeoWCQuickReplyPlusRecognizerKey);
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCQuickReplyEnabledKey) && view.window;
    if (enabled && !recognizer) {
        NeoWCQuickReplyPlusGestureDelegate *delegate = [NeoWCQuickReplyPlusGestureDelegate new];
        delegate.toolView = view;
        recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:view
                                                                   action:@selector(neowc_handleQuickReplyPlusLongPress:)];
        recognizer.minimumPressDuration = 0.55;
        recognizer.cancelsTouchesInView = YES;
        recognizer.delegate = delegate;
        [view addGestureRecognizer:recognizer];
        objc_setAssociatedObject(view, &NeoWCQuickReplyPlusRecognizerKey, recognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view, &NeoWCQuickReplyPlusDelegateKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (!enabled && recognizer) {
        [view removeGestureRecognizer:recognizer];
        objc_setAssociatedObject(view, &NeoWCQuickReplyPlusRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view, &NeoWCQuickReplyPlusDelegateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

static id NeoWCMessageChatContact(id message) {
    if (!message) return nil;
    Class contactManagerClass = objc_getClass("CContactMgr");
    id manager = contactManagerClass ? NeoWCServiceForClass(contactManagerClass) : nil;
    SEL selector = sel_registerName("getMessageChatContactByMessageWrap:");
    if (!manager || ![manager respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL, id))objc_msgSend)(manager, selector, message);
}

static UIView *NeoWCAvatarHeadViewForCell(CommonMessageCellView *cell) {
    id candidate = NeoWCTweakValueForSelectorNames(cell, @[@"getHeadImageView", @"m_headImageView", @"headImageView"]);
    if (!candidate) candidate = NeoWCTweakSafeValue(cell, @"m_headImageView");
    if ([candidate isKindOfClass:UIView.class]) return candidate;
    Class headViewClass = NSClassFromString(@"MMHeadImageView");
    if (!headViewClass) return nil;
    NSMutableArray<UIView *> *pending = [NSMutableArray arrayWithArray:cell.subviews ?: @[]];
    while (pending.count) {
        UIView *view = pending.lastObject;
        [pending removeLastObject];
        if ([view isKindOfClass:headViewClass]) return view;
        if (view.subviews.count) [pending addObjectsFromArray:view.subviews];
    }
    return nil;
}

static CommonMessageCellView *NeoWCAvatarMessageCellForView(UIView *view) {
    Class cellClass = NSClassFromString(@"CommonMessageCellView");
    UIView *candidate = view.superview;
    while (candidate) {
        if (cellClass && [candidate isKindOfClass:cellClass]) return (CommonMessageCellView *)candidate;
        candidate = candidate.superview;
    }
    return nil;
}

static void NeoWCResolveAvatarGestureConflicts(UIView *headView, UIGestureRecognizer *ownedRecognizer) {
    if (!headView || !ownedRecognizer) return;
    NSArray<UIGestureRecognizer *> *recognizers = [headView.gestureRecognizers copy];
    for (UIGestureRecognizer *recognizer in recognizers) {
        if (recognizer == ownedRecognizer) continue;
        if ([ownedRecognizer isKindOfClass:UITapGestureRecognizer.class] &&
            [recognizer isKindOfClass:UITapGestureRecognizer.class]) {
            UITapGestureRecognizer *ownedTap = (UITapGestureRecognizer *)ownedRecognizer;
            UITapGestureRecognizer *nativeTap = (UITapGestureRecognizer *)recognizer;
            if (ownedTap.numberOfTapsRequired > nativeTap.numberOfTapsRequired) {
                [nativeTap requireGestureRecognizerToFail:ownedTap];
            }
        } else if ([ownedRecognizer isKindOfClass:UILongPressGestureRecognizer.class] &&
                   [recognizer isKindOfClass:UILongPressGestureRecognizer.class]) {
            [recognizer requireGestureRecognizerToFail:ownedRecognizer];
        }
    }
}

static BOOL NeoWCConfigureNativeAvatarDoubleTap(UIView *headView,
                                                NeoWCAvatarQuickGestureProxy *proxy,
                                                BOOL enabled) {
    SEL setter = NSSelectorFromString(@"setTargetForDoubleClick:action:");
    if (![headView respondsToSelector:setter]) return NO;
    NeoWCWeakObjectBox *originalTargetBox = objc_getAssociatedObject(headView, &NeoWCAvatarNativeDoubleTapTargetKey);
    NSString *originalActionName = objc_getAssociatedObject(headView, &NeoWCAvatarNativeDoubleTapActionKey);
    BOOL owned = [objc_getAssociatedObject(headView, &NeoWCAvatarNativeDoubleTapOwnedKey) boolValue];
    if (enabled) {
        if (!originalTargetBox.object || originalActionName.length == 0) return NO;
        NeoWCUpdatingAvatarNativeDoubleTap = YES;
        ((void (*)(id, SEL, id, SEL))objc_msgSend)(headView, setter, proxy, @selector(handleGesture:));
        NeoWCUpdatingAvatarNativeDoubleTap = NO;
        objc_setAssociatedObject(headView, &NeoWCAvatarNativeDoubleTapOwnedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return YES;
    }
    if (owned) {
        SEL originalAction = NSSelectorFromString(originalActionName);
        NeoWCUpdatingAvatarNativeDoubleTap = YES;
        ((void (*)(id, SEL, id, SEL))objc_msgSend)(headView, setter, originalTargetBox.object, originalAction);
        NeoWCUpdatingAvatarNativeDoubleTap = NO;
        objc_setAssociatedObject(headView, &NeoWCAvatarNativeDoubleTapOwnedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return NO;
}

static UIImage *NeoWCFirstImageInView(UIView *view) {
    if ([view isKindOfClass:UIImageView.class] && ((UIImageView *)view).image) return ((UIImageView *)view).image;
    for (UIView *subview in view.subviews) {
        UIImage *image = NeoWCFirstImageInView(subview);
        if (image) return image;
    }
    return nil;
}

static UIImage *NeoWCAvatarSnapshot(UIView *view) {
    UIImage *image = NeoWCFirstImageInView(view);
    CGSize size = view.bounds.size;
    if (image || size.width <= 0.0 || size.height <= 0.0) return image;
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context) [view.layer renderInContext:context];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

static NSString *NeoWCAvatarDisplayName(id contact, NSString *fallback) {
    for (NSString *selectorName in @[@"getContactDisplayName", @"getRemark", @"m_nsRemark", @"m_nsNickName", @"nickname"]) {
        id value = NeoWCTweakValueForSelectorNames(contact, @[selectorName]);
        if (!value) value = NeoWCTweakSafeValue(contact, selectorName);
        if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    }
    return fallback ?: @"";
}

static NSString *NeoWCAvatarTargetUserName(CommonMessageCellView *cell, NSString *chatUserName) {
    id message = NeoWCMessageWrapForCell(cell);
    NSString *currentUser = NeoWCCurrentUserWXID();
    if (NeoWCMessageCellIsSender(cell)) return currentUser;
    if ([chatUserName hasSuffix:@"@chatroom"]) {
        for (NSString *key in @[@"m_nsRealChatUsr", @"m_nsRealChatUsrName", @"realChatUserName", @"m_nsFromUsr"]) {
            id value = NeoWCTweakValueForSelectorNames(message, @[key]);
            if (!value) value = NeoWCTweakSafeValue(message, key);
            if ([value isKindOfClass:NSString.class] && [value length] > 0 && ![value hasSuffix:@"@chatroom"]) return value;
        }
        return nil;
    }
    return chatUserName;
}

static void NeoWCInvokeNativeAvatarDoubleTap(CommonMessageCellView *cell, UIView *headView) {
    NeoWCWeakObjectBox *targetBox = objc_getAssociatedObject(headView, &NeoWCAvatarNativeDoubleTapTargetKey);
    NSString *actionName = objc_getAssociatedObject(headView, &NeoWCAvatarNativeDoubleTapActionKey);
    id target = targetBox.object;
    SEL action = actionName.length ? NSSelectorFromString(actionName) : NULL;
    if (target && action && [target respondsToSelector:action]) {
        ((void (*)(id, SEL, id))objc_msgSend)(target, action, headView);
        return;
    }
    SEL cellAction = NSSelectorFromString(@"onHeadImageDoubleClick:");
    if (cell && [cell respondsToSelector:cellAction]) {
        ((void (*)(id, SEL, id))objc_msgSend)(cell, cellAction, headView);
        return;
    }
    NeoWCShowTransientMessage(@"当前微信版本不支持拍一拍", NO);
}

static void NeoWCInvokeNativeAvatarLongPress(CommonMessageCellView *cell, UIView *headView) {
    SEL selector = NSSelectorFromString(@"onHeadImageLongPressed:");
    if (!cell || !headView || ![cell respondsToSelector:selector]) {
        NeoWCShowTransientMessage(@"当前微信版本不支持艾特", NO);
        return;
    }
    NeoWCPerformingNativeAvatarLongPress = YES;
    ((void (*)(id, SEL, id))objc_msgSend)(cell, selector, headView);
    NeoWCPerformingNativeAvatarLongPress = NO;
}

static void NeoWCOpenAvatarProfile(UIViewController *chatController, UIView *headView, id contact) {
    SEL selector = NSSelectorFromString(@"onHeadImageClicked:");
    if ([chatController respondsToSelector:selector] && headView) {
        ((void (*)(id, SEL, id))objc_msgSend)(chatController, selector, headView);
        return;
    }
    Class controllerClass = NSClassFromString(@"ContactInfoViewController");
    UIViewController *profile = controllerClass ? [controllerClass new] : nil;
    if (!profile) {
        NeoWCShowTransientMessage(@"当前微信版本无法打开资料页", NO);
        return;
    }
    NeoWCTweakSetValue(profile, @"m_contact", contact);
    if (chatController.navigationController) [chatController.navigationController pushViewController:profile animated:YES];
    else [chatController presentViewController:profile animated:YES completion:nil];
}

static void NeoWCClearPendingExclusiveRedEnvelope(void) {
    NeoWCPendingExclusiveRedEnvelopeContact = nil;
    NeoWCPendingExclusiveRedEnvelopeGroupID = nil;
    NeoWCPendingExclusiveRedEnvelopeDeadline = 0.0;
}

static NSString *NeoWCContactUserName(id contact) {
    if ([contact isKindOfClass:NSString.class]) return contact;
    for (NSString *name in @[@"m_nsUsrName", @"userName", @"username"]) {
        id value = NeoWCTweakValueForSelectorNames(contact, @[name]);
        if (!value) value = NeoWCTweakSafeValue(contact, name);
        if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    }
    return nil;
}

static void NeoWCPrepareExclusiveRedEnvelopeData(id data) {
    if (!data || !NeoWCPendingExclusiveRedEnvelopeContact ||
        NeoWCPendingExclusiveRedEnvelopeGroupID.length == 0 ||
        CACurrentMediaTime() > NeoWCPendingExclusiveRedEnvelopeDeadline) {
        if (CACurrentMediaTime() > NeoWCPendingExclusiveRedEnvelopeDeadline) {
            NeoWCClearPendingExclusiveRedEnvelope();
        }
        return;
    }
    id selectedConversation = NeoWCTweakValueForSelectorNames(data, @[@"m_oSelectContact"]);
    if (!selectedConversation) selectedConversation = NeoWCTweakSafeValue(data, @"m_oSelectContact");
    NSString *selectedUserName = NeoWCContactUserName(selectedConversation);
    if (![selectedUserName isEqualToString:NeoWCPendingExclusiveRedEnvelopeGroupID]) return;

    id targetContact = NeoWCPendingExclusiveRedEnvelopeContact;
    SEL memberSelector = NSSelectorFromString(@"setSelectedMemberContact:");
    if ([data respondsToSelector:memberSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(data, memberSelector, targetContact);
    }
    objc_setAssociatedObject(data, &NeoWCExclusiveRedEnvelopeContactKey,
                             targetContact, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCClearPendingExclusiveRedEnvelope();
}

static void NeoWCOpenAvatarExclusiveRedEnvelope(id chatController,
                                                 id targetContact,
                                                 NSString *groupID) {
    SEL selector = NSSelectorFromString(@"redEnvelopesLogic");
    if (![chatController respondsToSelector:selector]) {
        NeoWCShowTransientMessage(@"当前页面无法发红包", NO);
        return;
    }
    if (!targetContact || groupID.length == 0 || ![groupID hasSuffix:@"@chatroom"]) {
        NeoWCShowTransientMessage(@"未取得群成员资料", NO);
        return;
    }
    NSUInteger generation = ++NeoWCPendingExclusiveRedEnvelopeGeneration;
    NeoWCPendingExclusiveRedEnvelopeContact = targetContact;
    NeoWCPendingExclusiveRedEnvelopeGroupID = [groupID copy];
    NeoWCPendingExclusiveRedEnvelopeDeadline = CACurrentMediaTime() + 2.0;
    @try {
        ((id (*)(id, SEL))objc_msgSend)(chatController, selector);
    } @catch (NSException *exception) {
        if (generation == NeoWCPendingExclusiveRedEnvelopeGeneration) {
            NeoWCClearPendingExclusiveRedEnvelope();
        }
        NeoWCLog(@"打开专属红包失败：%@", exception.reason ?: exception.name);
        NeoWCShowTransientMessage(@"打开红包失败", NO);
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (generation == NeoWCPendingExclusiveRedEnvelopeGeneration) {
            NeoWCClearPendingExclusiveRedEnvelope();
        }
    });
}

static void NeoWCOpenAvatarTransfer(id chatController, NSString *targetUserName, id targetContact, NSString *chatUserName) {
    Class dataClass = NSClassFromString(@"WCPayControlData");
    Class managerClass = NSClassFromString(@"WCPayControlMgr");
    id data = dataClass ? [dataClass new] : nil;
    id manager = managerClass ? NeoWCServiceForClass(managerClass) : nil;
    SEL startSelector = NSSelectorFromString(@"startTransferMoneyLogic:Data:");
    if (!data || !manager || ![manager respondsToSelector:startSelector]) {
        NeoWCShowTransientMessage(@"当前微信版本无法发起转账", NO);
        return;
    }
    NSMutableArray<NSDictionary *> *entries = [NSMutableArray arrayWithArray:@[
        @{@"selector": @"setM_nsSelectedUserNameFromQRCode:", @"value": targetUserName ?: @""},
        @{@"selector": @"setM_oSelectedContact:", @"value": targetContact ?: NSNull.null},
    ]];
    if ([chatUserName hasSuffix:@"@chatroom"]) {
        [entries addObject:@{@"selector": @"setSelectedTransferChatroomUsername:", @"value": chatUserName}];
    }
    for (NSDictionary *entry in entries) {
        id value = entry[@"value"];
        if (value == NSNull.null) continue;
        SEL selector = NSSelectorFromString(entry[@"selector"]);
        if ([data respondsToSelector:selector]) ((void (*)(id, SEL, id))objc_msgSend)(data, selector, value);
    }
    Class recorderClass = NSClassFromString(@"WeChat.WCPaySessionInfoRecorder");
    SEL chatTypeSelector = NSSelectorFromString(@"chatTypeValueFromTalker:");
    SEL sendTypeSelector = NSSelectorFromString(@"commonSendTypeValue");
    SEL setChatTypeSelector = NSSelectorFromString(@"setSessionChatType:");
    SEL setSendTypeSelector = NSSelectorFromString(@"setSessionSendType:");
    if (recorderClass && [recorderClass respondsToSelector:chatTypeSelector] &&
        [data respondsToSelector:setChatTypeSelector]) {
        NSInteger chatType = ((NSInteger (*)(id, SEL, id))objc_msgSend)(recorderClass,
                                                                         chatTypeSelector,
                                                                         chatUserName ?: targetUserName);
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(data, setChatTypeSelector, chatType);
    }
    if (recorderClass && [recorderClass respondsToSelector:sendTypeSelector] &&
        [data respondsToSelector:setSendTypeSelector]) {
        NSInteger sendType = ((NSInteger (*)(id, SEL))objc_msgSend)(recorderClass, sendTypeSelector);
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(data, setSendTypeSelector, sendType);
    }
    SEL contactTypeSelector = NSSelectorFromString(@"m_uiType");
    SEL setTypeSelector = NSSelectorFromString(@"setM_uiType:");
    if (targetContact && [targetContact respondsToSelector:contactTypeSelector] &&
        [targetContact respondsToSelector:setTypeSelector]) {
        NSUInteger contactType = ((NSUInteger (*)(id, SEL))objc_msgSend)(targetContact, contactTypeSelector);
        if ((contactType & 1U) == 0) {
            ((void (*)(id, SEL, NSUInteger))objc_msgSend)(targetContact, setTypeSelector, contactType | 1U);
        }
    }
    ((void (*)(id, SEL, id, id))objc_msgSend)(manager, startSelector, chatController, data);
}

static void NeoWCOpenGroupMemberHistory(UIViewController *presenter,
                                        NSString *chatRoomUserName,
                                        id memberContact) {
    if (!presenter || ![chatRoomUserName hasSuffix:@"@chatroom"] || !memberContact) {
        NeoWCShowTransientMessage(@"未取得群成员资料", NO);
        return;
    }
    Class controllerClass = NSClassFromString(@"ChatRoomMemMsgListViewController");
    SEL initializer = NSSelectorFromString(@"initWithChat:memContact:");
    Method method = controllerClass ? class_getInstanceMethod(controllerClass, initializer) : NULL;
    if (!method || method_getNumberOfArguments(method) != 4 ||
        !NeoWCMethodReturnsObject(method) ||
        !NeoWCMethodArgumentIsObject(method, 2) ||
        !NeoWCMethodArgumentIsObject(method, 3)) {
        NeoWCShowTransientMessage(@"当前微信版本不支持成员聊天记录", NO);
        return;
    }
    UIViewController *controller = nil;
    @try {
        controller = ((id (*)(id, SEL, id, id))objc_msgSend)([controllerClass alloc],
                                                              initializer,
                                                              chatRoomUserName,
                                                              memberContact);
    } @catch (NSException *exception) {
        NeoWCLog(@"打开群成员聊天记录失败：%@", exception.reason ?: exception.name);
    }
    if (![controller isKindOfClass:UIViewController.class]) {
        NeoWCShowTransientMessage(@"无法打开成员聊天记录", NO);
        return;
    }
    if (presenter.navigationController) {
        [presenter.navigationController pushViewController:controller animated:YES];
    } else {
        [presenter presentViewController:[[UINavigationController alloc] initWithRootViewController:controller]
                                animated:YES
                              completion:nil];
    }
}

static void NeoWCOpenAvatarInfoCard(UIViewController *chatController,
                                    id contact,
                                    UIImage *avatar,
                                    NSString *displayName,
                                    NSString *targetUserName,
                                    NSString *chatUserName) {
    if (!chatController || targetUserName.length == 0) return;
    UIViewController *officialController = contact ? NeoWCCreateOfficialSocialInformation(contact) : nil;
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *rows =
        [NeoWCProfileInfoRows(contact, NO) mutableCopy] ?: [NSMutableArray array];
    id groupContact = nil;
    if (contact == nil) {
        NeoWCAddInfoCardRow(rows, @"原始号码", targetUserName);
    }
    if ([chatUserName hasSuffix:@"@chatroom"]) {
        groupContact = NeoWCContactForUserName(chatUserName);
        [rows addObject:@{ @"title": @"所在群聊", @"value": chatUserName }];
        [rows addObjectsFromArray:NeoWCGroupMemberInfoRows(contact, groupContact, targetUserName)];
    }
    NSArray *baseRows = [rows copy];
    NSArray *displayRows = NeoWCMergeInfoCardRows(baseRows,
        officialController ? NeoWCOfficialSocialInformationRows(officialController) : @[]);
    NeoWCContactInfoCardViewController *card = [[NeoWCContactInfoCardViewController alloc]
        initWithTitle:[chatUserName hasSuffix:@"@chatroom"] ? @"群成员详细信息" : @"详细信息"
               avatar:avatar
                 name:displayName ?: targetUserName
             userName:targetUserName
             rows:displayRows];
    if (officialController) {
        NeoWCWeakObjectBox *box = [NeoWCWeakObjectBox new];
        box.object = card;
        objc_setAssociatedObject(officialController, &NeoWCOfficialInfoCardBoxKey,
                                 box, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(officialController, &NeoWCOfficialInfoBaseRowsKey,
                                 baseRows, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(card, &NeoWCInfoCardOfficialControllerKey,
                                 officialController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NeoWCRefreshInfoCardFromOfficialController(officialController);
    }
    NeoWCConfigureInfoCardSwitches(card, targetUserName, [chatUserName hasSuffix:@"@chatroom"]);
    NeoWCConfigureInfoCardDetailActions(card, contact, groupContact,
                                        targetUserName, officialController);
    if (chatController.navigationController) {
        [chatController.navigationController pushViewController:card animated:YES];
    } else {
        [chatController presentViewController:[[UINavigationController alloc] initWithRootViewController:card]
                                      animated:YES completion:nil];
    }
}

static BOOL NeoWCPresentAvatarQuickMenu(CommonMessageCellView *cell, UIView *headView) {
    BaseMsgContentViewController *chatController = NeoWCResolveVisibleChatController();
    NSString *chatUserName = NeoWCChatUserName(chatController);
    NSString *targetUserName = NeoWCAvatarTargetUserName(cell, chatUserName);
    if (!chatController || targetUserName.length == 0) {
        NeoWCShowTransientMessage(@"未能识别头像对应的联系人", NO);
        return NO;
    }
    BOOL group = [chatUserName hasSuffix:@"@chatroom"];
    BOOL isSelf = [targetUserName isEqualToString:NeoWCCurrentUserWXID()];
    id message = NeoWCMessageWrapForCell(cell);
    id contact = group ? NeoWCMessageChatContact(message) : nil;
    if (!contact) contact = NeoWCContactForUserName(targetUserName);
    id groupContact = group ? NeoWCContactForUserName(chatUserName) : nil;
    NSInteger removalScene = (group && !isSelf)
        ? NeoWCGroupMemberRemovalScene(groupContact, contact, targetUserName) : 0;
    NSString *displayName = NeoWCAvatarDisplayName(contact, targetUserName);
    UIImage *avatar = NeoWCAvatarSnapshot(headView);
    __weak UIViewController *weakController = chatController;
    __weak CommonMessageCellView *weakCell = cell;
    __weak UIView *weakHeadView = headView;
    NSString *retainedTarget = [targetUserName copy];
    NSString *retainedChat = [chatUserName copy];
    id retainedContact = contact;
    id retainedGroupContact = groupContact;

    NSMutableArray<NeoWCAvatarQuickAction *> *actions = [NSMutableArray array];
    if (NeoWCEnhancementEnabled(NeoWCShowRawContactIDEnabledKey)) {
        [actions addObject:[NeoWCAvatarQuickAction actionWithTitle:@"详细信息" symbolName:@"person.text.rectangle" handler:^{
            NeoWCOpenAvatarInfoCard(weakController, retainedContact, avatar, displayName,
                                   retainedTarget, retainedChat);
        }]];
    }
    if (group && !isSelf) {
        [actions addObject:[NeoWCAvatarQuickAction actionWithTitle:@"艾特" symbolName:@"at" handler:^{
            NeoWCInvokeNativeAvatarLongPress(weakCell, weakHeadView);
        }]];
    }
    [actions addObject:[NeoWCAvatarQuickAction actionWithTitle:@"拍一拍" symbolName:@"hand.tap" handler:^{
        NeoWCInvokeNativeAvatarDoubleTap(weakCell, weakHeadView);
    }]];
    if (group && !isSelf) {
        [actions addObject:[NeoWCAvatarQuickAction actionWithTitle:@"专属红包" symbolName:@"envelope" handler:^{
            NeoWCOpenAvatarExclusiveRedEnvelope(weakController, retainedContact, retainedChat);
        }]];
    }
    if (!isSelf) {
        [actions addObject:[NeoWCAvatarQuickAction actionWithTitle:@"转账" symbolName:@"arrow.left.arrow.right" handler:^{
            NeoWCOpenAvatarTransfer(weakController, retainedTarget, retainedContact, retainedChat);
        }]];
    }
    if (group && !isSelf) {
        [actions addObject:[NeoWCAvatarQuickAction actionWithTitle:@"私聊" symbolName:@"bubble.left" handler:^{
            NeoWCOpenChatForUserName(retainedTarget);
        }]];
    }
    if (group) {
        [actions addObject:[NeoWCAvatarQuickAction actionWithTitle:@"聊天记录" symbolName:@"clock.arrow.circlepath" handler:^{
            NeoWCOpenGroupMemberHistory(weakController, retainedChat, retainedContact);
        }]];
    }
    if (removalScene > 0) {
        [actions addObject:[NeoWCAvatarQuickAction actionWithTitle:@"移出群聊" symbolName:@"person.fill.xmark" handler:^{
            NeoWCConfirmRemoveGroupMember(weakController, retainedGroupContact, retainedContact,
                                          retainedTarget, removalScene);
        }]];
    }
    [actions addObject:[NeoWCAvatarQuickAction actionWithTitle:@"朋友圈" symbolName:@"circle.grid.3x3" handler:^{
        if (retainedContact) NeoWCOpenHomeMoments(weakController, retainedContact);
        else NeoWCShowTransientMessage(@"未获取到联系人资料", NO);
    }]];
    if (!isSelf) {
        [actions addObject:[NeoWCAvatarQuickAction actionWithTitle:@"改备注" symbolName:@"pencil" handler:^{
            if (retainedContact) NeoWCOpenHomeRemark(weakController, retainedContact, NO);
            else NeoWCShowTransientMessage(@"未获取到联系人资料", NO);
        }]];
    }
    NeoWCPresentAvatarQuickPanel(chatController,
                                 avatar,
                                 displayName,
                                 targetUserName,
                                 actions,
                                 ^{ NeoWCOpenAvatarProfile(weakController, weakHeadView, retainedContact); });
    return YES;
}

static void NeoWCSynchronizeAvatarQuickGesture(CommonMessageCellView *cell) {
    if (!cell) return;
    UIView *oldHeadView = objc_getAssociatedObject(cell, &NeoWCAvatarQuickHeadViewKey);
    UITapGestureRecognizer *doubleTap = objc_getAssociatedObject(cell, &NeoWCAvatarQuickDoubleTapRecognizerKey);
    NeoWCAvatarQuickGestureProxy *oldProxy = objc_getAssociatedObject(cell, &NeoWCAvatarQuickGestureProxyKey);
    UIView *headView = cell.window ? NeoWCAvatarHeadViewForCell(cell) : nil;
    NSInteger mode = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCAvatarQuickMenuGestureKey];
    if (!NeoWCEnhancementEnabled(NeoWCAvatarQuickMenuGestureKey)) mode = NeoWCAvatarQuickMenuGestureOff;
    if (mode < NeoWCAvatarQuickMenuGestureOff || mode > NeoWCAvatarQuickMenuGestureLongPress) {
        mode = NeoWCAvatarQuickMenuGestureOff;
    }
    if (!headView || mode == NeoWCAvatarQuickMenuGestureOff || oldHeadView != headView) {
        if (oldHeadView && oldProxy) NeoWCConfigureNativeAvatarDoubleTap(oldHeadView, oldProxy, NO);
        if (doubleTap && oldHeadView) [oldHeadView removeGestureRecognizer:doubleTap];
        doubleTap = nil;
        objc_setAssociatedObject(cell, &NeoWCAvatarQuickDoubleTapRecognizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCAvatarQuickGestureProxyKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCAvatarQuickHeadViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (!headView || mode == NeoWCAvatarQuickMenuGestureOff) return;
    }

    NeoWCAvatarQuickGestureProxy *proxy = objc_getAssociatedObject(cell, &NeoWCAvatarQuickGestureProxyKey);
    if (!proxy) proxy = [NeoWCAvatarQuickGestureProxy new];
    proxy.cell = cell;
    proxy.headView = headView;
    headView.userInteractionEnabled = YES;

    if (mode == NeoWCAvatarQuickMenuGestureDoubleTap) {
        BOOL usingNativeDoubleTap = NeoWCConfigureNativeAvatarDoubleTap(headView, proxy, YES);
        if (usingNativeDoubleTap && doubleTap) {
            [headView removeGestureRecognizer:doubleTap];
            doubleTap = nil;
        } else if (!usingNativeDoubleTap && !doubleTap) {
            doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:proxy action:@selector(handleGesture:)];
            doubleTap.numberOfTapsRequired = 2;
            doubleTap.cancelsTouchesInView = YES;
            doubleTap.delaysTouchesEnded = YES;
            doubleTap.delegate = proxy;
            [headView addGestureRecognizer:doubleTap];
        }
        if (doubleTap) NeoWCResolveAvatarGestureConflicts(headView, doubleTap);
    } else {
        NeoWCConfigureNativeAvatarDoubleTap(headView, proxy, NO);
        if (doubleTap) {
            [headView removeGestureRecognizer:doubleTap];
            doubleTap = nil;
        }
    }
    objc_setAssociatedObject(cell, &NeoWCAvatarQuickHeadViewKey, headView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(cell, &NeoWCAvatarQuickDoubleTapRecognizerKey, doubleTap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(cell, &NeoWCAvatarQuickGestureProxyKey, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NSString *NeoWCConversationUserNameForEditLogic(id logic) {
    if (!logic) return nil;
    SEL originalMessageSelector = sel_registerName("originalMessageWrap");
    if ([logic respondsToSelector:originalMessageSelector]) {
        id wrap = ((id (*)(id, SEL))objc_msgSend)(logic, originalMessageSelector);
        id fromValue = NeoWCTweakValueForSelectorNames(wrap, @[@"m_nsFromUsr"]);
        id toValue = NeoWCTweakValueForSelectorNames(wrap, @[@"m_nsToUsr"]);
        NSString *fromUser = [fromValue isKindOfClass:[NSString class]] ? fromValue : nil;
        NSString *toUser = [toValue isKindOfClass:[NSString class]] ? toValue : nil;
        Class settingUtilClass = objc_getClass("SettingUtil");
        SEL localUserSelector = sel_registerName("getLocalUsrName:");
        NSString *localUser = nil;
        if (settingUtilClass && [settingUtilClass respondsToSelector:localUserSelector]) {
            id localValue = ((id (*)(id, SEL, NSInteger))objc_msgSend)(settingUtilClass,
                                                                        localUserSelector,
                                                                        0);
            localUser = [localValue isKindOfClass:[NSString class]] ? localValue : nil;
        }
        NSString *conversation = nil;
        if (fromUser.length > 0 && localUser.length > 0 && [fromUser isEqualToString:localUser]) {
            conversation = toUser;
        } else if (fromUser.length > 0) {
            conversation = fromUser;
        }
        if (conversation.length > 0) {
            objc_setAssociatedObject(logic, &NeoWCEditConversationUserNameKey,
                                     conversation, OBJC_ASSOCIATION_COPY_NONATOMIC);
            return conversation;
        }
    }
    SEL selector = sel_registerName("c2CUserName");
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
    if ([image isKindOfClass:[UIImage class]]) return image;
    id initialView = NeoWCTweakSafeValue(logic, @"_editImageInitialView");
    id scrollView = NeoWCTweakValueForSelectorNames(initialView, @[@"eIScrollView"]);
    id editAttribute = NeoWCTweakValueForSelectorNames(scrollView, @[@"getEditImageAttr"]);
    image = NeoWCTweakSafeValue(editAttribute, @"editedImage");
    if ([image isKindOfClass:[UIImage class]]) {
        NeoWCCacheEditedImage(logic, image, @"编辑器最终图片");
        return image;
    }
    return nil;
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
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ NeoWCShowTransientMessage(message, success); });
        return;
    }
    Class toastClass = NSClassFromString(@"WeToast");
    SEL toastSelector = NSSelectorFromString(@"toast");
    id toast = toastClass && [toastClass respondsToSelector:toastSelector]
        ? ((id (*)(id, SEL))objc_msgSend)(toastClass, toastSelector) : nil;
    SEL showSelector = NSSelectorFromString(success ? @"showDoneToastWithText:" : @"showErrorToastWithText:");
    if (toast && [toast respondsToSelector:showSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(toast, showSelector, message);
        return;
    }
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
    [window bringSubviewToFront:label];
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
    UIImage *cachedImage = NeoWCEditedImageFromLogic(logic);
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
    id injectedSaveButton = objc_getAssociatedObject(root, &NeoWCMomentsFloatSaveButtonKey);
    NSMutableArray<UIView *> *pending = [NSMutableArray arrayWithObject:root];
    while (pending.count > 0) {
        UIView *view = pending.lastObject;
        [pending removeLastObject];
        for (UIView *subview in view.subviews) {
            [pending addObject:subview];
            if (subview == injectedForwardButton || subview == injectedSaveButton || ![subview isKindOfClass:[UIControl class]] ||
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

static BOOL NeoWCMomentsMediaFileIsUsable(NSString *path) {
    if (path.length == 0) return NO;
    BOOL directory = NO;
    NSFileManager *manager = NSFileManager.defaultManager;
    if (![manager fileExistsAtPath:path isDirectory:&directory] || directory) return NO;
    NSNumber *size = [[manager attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize];
    return size.unsignedLongLongValue > 0;
}

static void NeoWCAppendUniqueMomentObject(NSMutableArray *objects, id object) {
    if (!object) return;
    for (id existing in objects) if (existing == object) return;
    [objects addObject:object];
}

static NSArray *NeoWCLivePhotoVideoCandidateObjects(id mediaItem, id parentMediaItem) {
    NSMutableArray *objects = [NSMutableArray array];
    NeoWCAppendUniqueMomentObject(objects, mediaItem);
    for (id owner in @[mediaItem ?: NSNull.null, parentMediaItem ?: NSNull.null]) {
        if (owner == NSNull.null) continue;
        for (NSString *selectorName in @[@"livePhotoVideoMediaItem", @"pairedVideoMediaItem",
                                         @"livePhotoMediaItem"]) {
            NeoWCAppendUniqueMomentObject(objects, NeoWCMomentsObjectForSelector(owner, selectorName));
        }
    }
    NeoWCAppendUniqueMomentObject(objects, parentMediaItem);
    return objects;
}

static NSString *NeoWCLivePhotoExistingVideoPath(id mediaItem, id parentMediaItem) {
    NSArray *selectors = @[@"pathForSightData", @"pathForData", @"pathForAttachVideoData",
                           @"pathForExistData", @"tempPathForSightData",
                           @"pathForTempAttachVideoData", @"livePhotoVideoPath",
                           @"pairedVideoPath"];
    for (id object in NeoWCLivePhotoVideoCandidateObjects(mediaItem, parentMediaItem)) {
        for (NSString *selectorName in selectors) {
            id value = NeoWCMomentsObjectForSelector(object, selectorName);
            NSString *path = [value isKindOfClass:NSURL.class] ? [value path]
                : ([value isKindOfClass:NSString.class] ? value : nil);
            if (NeoWCMomentsMediaFileIsUsable(path)) return path;
        }
    }
    return nil;
}

static BOOL NeoWCMomentsLongLongForSelector(id object, NSString *selectorName, long long *result) {
    if (!object || selectorName.length == 0 || !result) return NO;
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = [object methodSignatureForSelector:selector];
    if (!signature || signature.numberOfArguments != 2) return NO;
    const char *returnType = signature.methodReturnType;
    if (!returnType || returnType[0] == 'v') return NO;

    BOOL integerReturn = strchr("cCsSiIlLqQ", returnType[0]) != NULL;
    if (integerReturn) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = object;
        invocation.selector = selector;
        @try {
            [invocation invoke];
            unsigned long long rawValue = 0;
            NSUInteger length = MIN(signature.methodReturnLength, sizeof(rawValue));
            [invocation getReturnValue:&rawValue];
            if (length < sizeof(rawValue) && (returnType[0] == 'c' || returnType[0] == 's' || returnType[0] == 'i' || returnType[0] == 'l')) {
                unsigned long long signBit = 1ULL << (length * 8 - 1);
                if (rawValue & signBit) rawValue |= ~0ULL << (length * 8);
            }
            *result = (long long)rawValue;
            return YES;
        } @catch (__unused NSException *exception) {
            return NO;
        }
    }

    if (returnType[0] != '@') return NO;
    // Some older builds expose the value as NSNumber rather than a scalar.
    id value = NeoWCMomentsObjectForSelector(object, selectorName);
    if ([value respondsToSelector:@selector(longLongValue)]) {
        *result = [value longLongValue];
        return YES;
    }
    return NO;
}

static long long NeoWCNormalizedLivePhotoStillImageTimeMs(long long stillImageTimeMs,
                                                           NSString *videoPath) {
    long long normalizedTimeMs = MAX(1LL, stillImageTimeMs);
    if (videoPath.length == 0) return normalizedTimeMs;

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:videoPath] options:nil];
    NSTimeInterval durationSeconds = CMTimeGetSeconds(asset.duration);
    if (!isfinite(durationSeconds) || durationSeconds <= 0.0) return normalizedTimeMs;

    long long durationMs = llround(durationSeconds * 1000.0);
    if (durationMs < 1) return normalizedTimeMs;
    if (stillImageTimeMs < 1 || stillImageTimeMs >= durationMs) {
        normalizedTimeMs = MAX(1LL, llround(MAX(1LL, durationMs) / 2.0));
    }
    long long maximumTimeMs = MAX(2LL, durationMs) - 1;
    return MIN(normalizedTimeMs, maximumTimeMs);
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

@interface NeoWCMomentsMediaSaveTask : NSObject
@property (nonatomic, strong) id dataItem;
@property (nonatomic, weak) UIViewController *presenter;
@property (nonatomic, strong) NSArray *mediaItems;
@property (nonatomic, strong) NSMutableArray *resolvedPaths;
@property (nonatomic, strong) NSMutableArray *resolvedVideoPaths;
@property (nonatomic, strong) NSMutableArray *livePhotoTimes;
@property (nonatomic, strong) NSMutableArray *livePhotoIndexes;
@property (nonatomic, strong) NSMutableArray *downloaders;
@property (nonatomic, strong) NSMutableArray *livePhotoSaveQueue;
@property (nonatomic, strong) NSMutableArray *livePhotoMakers;
@property (nonatomic, strong) NSMutableArray<NSString *> *temporaryPaths;
@property (nonatomic, assign) NSUInteger remainingDownloads;
@property (nonatomic, assign) NSUInteger nextLivePhotoIndex;
@property (nonatomic, assign) BOOL video;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, assign) BOOL saveStarted;
@property (nonatomic, assign) BOOL finished;
- (void)start;
- (void)finishDownloadedMediaItem:(id)mediaItem
                  parentMediaItem:(id)parentMediaItem
                            index:(NSUInteger)index
                        videoPath:(BOOL)videoPath
                    pathSelectors:(NSArray *)pathSelectors
                       downloader:(id)downloader
                          attempt:(NSUInteger)attempt;
@end

@implementation NeoWCMomentsMediaSaveTask

- (void)finish {
    UIViewController *presenter = self.presenter;
    if (presenter && objc_getAssociatedObject(presenter, &NeoWCMomentsSaveTaskKey) == self) {
        objc_setAssociatedObject(presenter, &NeoWCMomentsSaveTaskKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (self.dataItem && objc_getAssociatedObject(self.dataItem, &NeoWCMomentsDataItemSaveTaskKey) == self) {
        objc_setAssociatedObject(self.dataItem, &NeoWCMomentsDataItemSaveTaskKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    for (NSString *path in self.temporaryPaths) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    [self.temporaryPaths removeAllObjects];
    [self.livePhotoMakers removeAllObjects];
    if (NeoWCActiveMomentsMediaSaveTask == self) NeoWCActiveMomentsMediaSaveTask = nil;
}

- (BOOL)prepareLivePhotoForImagePath:(NSString *)imagePath
                           videoPath:(NSString *)videoPath
                    stillImageTimeMs:(long long)stillImageTimeMs
                          completion:(void (^)(NSString *, NSString *))completion {
    Class makerClass = NSClassFromString(@"WCLivePhotoMaker");
    Class pathManagerClass = NSClassFromString(@"WCLivePhotoFilePathManager");
    SEL heicSelector = NSSelectorFromString(@"getLivePhotoHEICPath:");
    SEL jpgSelector = NSSelectorFromString(@"getLivePhotoJPGPath:");
    SEL movSelector = NSSelectorFromString(@"getLivePhotoMovPath:");
    SEL makeSelector = NSSelectorFromString(@"makeLivePhotoByImagePath:videoPath:preferedHEVC:stillImageTimeMs:completionHandler:");
    if (!makerClass || !pathManagerClass ||
        ![pathManagerClass respondsToSelector:heicSelector] ||
        ![pathManagerClass respondsToSelector:jpgSelector] ||
        ![pathManagerClass respondsToSelector:movSelector]) return NO;

    NSString *fileIdentifier = imagePath.lastPathComponent.stringByDeletingPathExtension;
    if (fileIdentifier.length == 0) return NO;
    NSString *heicPath = ((id (*)(id, SEL, id))objc_msgSend)(pathManagerClass, heicSelector, fileIdentifier);
    NSString *jpgPath = ((id (*)(id, SEL, id))objc_msgSend)(pathManagerClass, jpgSelector, fileIdentifier);
    NSString *movPath = ((id (*)(id, SEL, id))objc_msgSend)(pathManagerClass, movSelector, fileIdentifier);
    if (heicPath.length == 0 || jpgPath.length == 0 || movPath.length == 0) return NO;

    NSFileManager *fileManager = NSFileManager.defaultManager;
    for (NSString *path in @[heicPath, jpgPath, movPath]) {
        if ([fileManager fileExistsAtPath:path]) [fileManager removeItemAtPath:path error:nil];
        [self.temporaryPaths addObject:path];
    }

    id maker = [makerClass new];
    if (!maker || ![maker respondsToSelector:makeSelector]) return NO;
    [self.livePhotoMakers addObject:maker];
    __weak typeof(self) weakSelf = self;
    __weak id weakMaker = maker;
    void (^makerCompletion)(void) = [^{
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || strongSelf.finished) return;
            NSString *pairedImagePath = [fileManager fileExistsAtPath:heicPath] ? heicPath :
                                        ([fileManager fileExistsAtPath:jpgPath] ? jpgPath : nil);
            NSString *pairedVideoPath = [fileManager fileExistsAtPath:movPath] ? movPath : nil;
            id completedMaker = weakMaker;
            if (completedMaker) [strongSelf.livePhotoMakers removeObject:completedMaker];
            if (completion) completion(pairedImagePath, pairedVideoPath);
        });
    } copy];
    @try {
        // WeChatX first creates a paired HEIC/JPG + MOV through this maker,
        // then passes those generated paths to MMAlbumService.
        ((void (*)(id, SEL, id, id, BOOL, long long, id))objc_msgSend)(
            maker, makeSelector, imagePath, videoPath, YES, stillImageTimeMs, makerCompletion);
        return YES;
    } @catch (NSException *exception) {
        [self.livePhotoMakers removeObject:maker];
        NeoWCLog(@"生成朋友圈实况配对文件失败：%@", exception.reason ?: @"未知异常");
        return NO;
    }
}

- (void)finishWithFailure:(NSString *)message {
    if (self.finished) return;
    self.finished = YES;
    NeoWCShowTransientMessage(message.length > 0 ? message : @"保存失败，请检查照片权限", NO);
    [self finish];
}

- (void)finishWithSuccess {
    if (self.finished) return;
    self.finished = YES;
    NSUInteger imageCount = 0;
    NSUInteger videoCount = 0;
    NSUInteger livePhotoCount = self.livePhotoIndexes.count;
    if (self.video) {
        videoCount = self.mediaItems.count;
    } else {
        for (NSUInteger index = 0; index < self.mediaItems.count; index++) {
            if ([self.livePhotoIndexes containsObject:@(index)]) continue;
            imageCount++;
        }
    }

    NSString *message = nil;
    if (videoCount > 0) {
        message = [NSString stringWithFormat:@"已保存 %lu 个朋友圈视频", (unsigned long)videoCount];
    } else if (imageCount > 0 && livePhotoCount > 0) {
        message = [NSString stringWithFormat:@"已保存 %lu 张朋友圈图片和 %lu 张实况照片",
                   (unsigned long)imageCount, (unsigned long)livePhotoCount];
    } else if (livePhotoCount > 0) {
        message = [NSString stringWithFormat:@"已保存 %lu 张实况照片", (unsigned long)livePhotoCount];
    } else {
        message = [NSString stringWithFormat:@"已保存 %lu 张朋友圈图片", (unsigned long)imageCount];
    }
    NeoWCShowTransientMessage(message, YES);
    UINotificationFeedbackGenerator *feedback = [UINotificationFeedbackGenerator new];
    [feedback notificationOccurred:UINotificationFeedbackTypeSuccess];
    NeoWCCompatibilityMarkTriggered(@"moments-save-images");
    [self finish];
}

- (BOOL)invokeLivePhotoSaveForImagePath:(NSString *)imagePath
                              videoPath:(NSString *)videoPath
                       stillImageTimeMs:(long long)stillImageTimeMs
                                success:(void (^)(void))success
                                failure:(void (^)(void))failure {
    Class albumServiceClass = NSClassFromString(@"MMAlbumService");
    SEL saveSelector = NSSelectorFromString(@"saveLivePhotoToAlbumWithImagePath:videoPath:stillImageTimeMs:isShowTips:successBlock:failureBlock:");
    if (!albumServiceClass) return NO;
    // Match WeChatX's service lookup order through NeoWC's MMContext-aware
    // compatibility helper, which falls back to MMServiceCenter.defaultCenter.
    id service = NeoWCServiceForClass(albumServiceClass);
    if (!service || ![service respondsToSelector:saveSelector]) return NO;
    void (^successBlock)(void) = [^{
        if (success) success();
    } copy];
    void (^failureBlock)(void) = [^{
        if (failure) failure();
    } copy];
    @try {
        // WeChatX calls this private API directly with two NSString paths,
        // a 64-bit millisecond time, isShowTips=NO and two no-argument blocks.
        ((void (*)(id, SEL, id, id, long long, BOOL, id, id))objc_msgSend)(
            service, saveSelector, imagePath, videoPath, stillImageTimeMs, NO, successBlock, failureBlock);
        return YES;
    } @catch (NSException *exception) {
        NeoWCLog(@"调用微信实况保存接口失败：%@", exception.reason ?: @"未知异常");
        return NO;
    }
}

- (void)saveNextLivePhoto {
    if (self.nextLivePhotoIndex >= self.livePhotoSaveQueue.count) {
        [self finishWithSuccess];
        return;
    }
    NSUInteger queueIndex = self.nextLivePhotoIndex++;
    NSNumber *mediaIndexValue = self.livePhotoSaveQueue[queueIndex];
    NSUInteger mediaIndex = mediaIndexValue.unsignedIntegerValue;
    NSString *imagePath = [self.resolvedPaths[mediaIndex] isKindOfClass:[NSString class]] ? self.resolvedPaths[mediaIndex] : nil;
    NSString *videoPath = [self.resolvedVideoPaths[mediaIndex] isKindOfClass:[NSString class]] ? self.resolvedVideoPaths[mediaIndex] : nil;
    NSNumber *timeValue = [self.livePhotoTimes[mediaIndex] isKindOfClass:[NSNumber class]] ? self.livePhotoTimes[mediaIndex] : nil;
    if (imagePath.length == 0 || videoPath.length == 0 || !timeValue) {
        [self finishWithFailure:@"实况照片数据不完整，请稍后重试"];
        return;
    }
    __weak typeof(self) weakSelf = self;
    long long normalizedTimeMs = NeoWCNormalizedLivePhotoStillImageTimeMs(timeValue.longLongValue, videoPath);
    BOOL preparing = [self prepareLivePhotoForImagePath:imagePath
                                              videoPath:videoPath
                                       stillImageTimeMs:normalizedTimeMs
                                             completion:^(NSString *pairedImagePath, NSString *pairedVideoPath) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.finished) return;
        if (pairedImagePath.length == 0 || pairedVideoPath.length == 0) {
            [strongSelf finishWithFailure:@"实况照片配对文件生成失败"];
            return;
        }
        BOOL invoked = [strongSelf invokeLivePhotoSaveForImagePath:pairedImagePath
                                                          videoPath:pairedVideoPath
                                                   stillImageTimeMs:normalizedTimeMs
                                                            success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) innerSelf = weakSelf;
                if (!innerSelf || innerSelf.finished) return;
                [innerSelf saveNextLivePhoto];
            });
        } failure:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) innerSelf = weakSelf;
                if (!innerSelf || innerSelf.finished) return;
                [innerSelf finishWithFailure:@"实况照片保存失败，请检查照片权限"];
            });
        }];
        if (!invoked) [strongSelf finishWithFailure:@"当前微信版本不支持保存实况照片"];
    }];
    if (!preparing) {
        [self finishWithFailure:@"当前微信版本不支持生成实况照片"];
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.finished || strongSelf.nextLivePhotoIndex != queueIndex + 1) return;
        [strongSelf finishWithFailure:@"实况照片保存超时，请检查照片权限"];
    });
}

- (void)saveResolvedMedia {
    if (self.failed) {
        [self finishWithFailure:self.video ? @"朋友圈视频下载失败，请稍后重试" : @"朋友圈媒体下载失败，请稍后重试"];
        return;
    }

    if (self.video) {
        NSString *path = [self.resolvedPaths.firstObject isKindOfClass:[NSString class]] ? self.resolvedPaths.firstObject : nil;
        if (path.length == 0) {
            [self finishWithFailure:@"朋友圈视频下载失败，请稍后重试"];
            return;
        }
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:path]];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success) {
                    NeoWCLog(@"保存朋友圈视频失败：%@", error.localizedDescription ?: @"未知错误");
                    [self finishWithFailure:@"保存视频失败，请检查照片权限"];
                    return;
                }
                [self finishWithSuccess];
            });
        }];
        return;
    }

    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    for (NSUInteger index = 0; index < self.mediaItems.count; index++) {
        if ([self.livePhotoIndexes containsObject:@(index)]) continue;
        NSString *path = [self.resolvedPaths[index] isKindOfClass:[NSString class]] ? self.resolvedPaths[index] : nil;
        UIImage *image = path.length > 0 ? [UIImage imageWithContentsOfFile:path] : nil;
        if (!image) {
            [self finishWithFailure:@"朋友圈图片下载失败，请稍后重试"];
            return;
        }
        [images addObject:image];
    }

    void (^saveLivePhotos)(void) = ^{
        self.nextLivePhotoIndex = 0;
        [self saveNextLivePhoto];
    };
    if (images.count == 0) {
        saveLivePhotos();
        return;
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        for (UIImage *image in images) {
            [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        }
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success) {
                NeoWCLog(@"保存朋友圈图片失败：%@", error.localizedDescription ?: @"未知错误");
                [self finishWithFailure:@"保存图片失败，请检查照片权限"];
                return;
            }
            saveLivePhotos();
        });
    }];
}

- (void)finishMediaResolutionIfNeeded {
    if (self.remainingDownloads != 0 || self.saveStarted || self.finished) return;
    self.saveStarted = YES;
    [self saveResolvedMedia];
}

- (void)resolvePathForMediaItem:(id)mediaItem
                parentMediaItem:(id)parentMediaItem
                          index:(NSUInteger)index
                    videoPath:(BOOL)videoPath {
    BOOL useVideoSelectors = self.video || videoPath;
    NSArray *pathSelectors = useVideoSelectors
        ? @[@"pathForSightData", @"pathForData", @"pathForAttachVideoData", @"pathForExistData"]
        : @[@"pathForUhdData", @"pathForHdData", @"pathForData", @"pathForExistData"];
    NSString *path = videoPath
        ? NeoWCLivePhotoExistingVideoPath(mediaItem, parentMediaItem)
        : NeoWCMomentsExistingMediaPath(mediaItem, pathSelectors);
    if (path.length > 0) {
        NSMutableArray *targetPaths = videoPath ? self.resolvedVideoPaths : self.resolvedPaths;
        targetPaths[index] = path;
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
    void (^completion)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || strongSelf.finished) return;
            [strongSelf finishDownloadedMediaItem:mediaItem
                                  parentMediaItem:parentMediaItem
                                            index:index
                                        videoPath:videoPath
                                    pathSelectors:pathSelectors
                                       downloader:downloader
                                          attempt:0];
        });
    };
    ((void (*)(id, SEL, id))objc_msgSend)(downloader, startSelector, completion);
}

- (void)finishDownloadedMediaItem:(id)mediaItem
                  parentMediaItem:(id)parentMediaItem
                            index:(NSUInteger)index
                        videoPath:(BOOL)videoPath
                    pathSelectors:(NSArray *)pathSelectors
                       downloader:(id)downloader
                          attempt:(NSUInteger)attempt {
    if (self.finished) return;
    NSString *resolvedPath = videoPath
        ? NeoWCLivePhotoExistingVideoPath(mediaItem, parentMediaItem)
        : NeoWCMomentsExistingMediaPath(mediaItem, pathSelectors);
    // AFN also rechecks after its completion when the path/file-size update is
    // slightly behind the callback. Keep this bounded below one second.
    if (resolvedPath.length == 0 && videoPath && attempt < 3) {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.22 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf finishDownloadedMediaItem:mediaItem
                                  parentMediaItem:parentMediaItem
                                            index:index
                                        videoPath:videoPath
                                    pathSelectors:pathSelectors
                                       downloader:downloader
                                          attempt:attempt + 1];
        });
        return;
    }
    if (resolvedPath.length > 0) {
        NSMutableArray *targetPaths = videoPath ? self.resolvedVideoPaths : self.resolvedPaths;
        targetPaths[index] = resolvedPath;
    } else {
        self.failed = YES;
    }
    [self.downloaders removeObject:downloader];
    self.remainingDownloads--;
    [self finishMediaResolutionIfNeeded];
}

- (void)start {
    id contentObject = NeoWCMomentsContentObject(self.dataItem);
    NSArray *mediaItems = NeoWCMomentsMediaItems(self.dataItem);
    BOOL isVideo = NeoWCMomentsBoolForSelector(contentObject, @"isVideoType");
    BOOL isPhoto = NeoWCMomentsBoolForSelector(contentObject, @"isPhotoType");
    if ((!isVideo && !isPhoto) || mediaItems.count == 0) {
        [self finishWithFailure:@"该条朋友圈没有可保存的媒体"];
        return;
    }

    self.video = isVideo;
    self.mediaItems = [mediaItems subarrayWithRange:NSMakeRange(0, isVideo ? 1 : MIN((NSUInteger)9, mediaItems.count))];
    self.resolvedPaths = [NSMutableArray arrayWithCapacity:self.mediaItems.count];
    self.resolvedVideoPaths = [NSMutableArray arrayWithCapacity:self.mediaItems.count];
    self.livePhotoTimes = [NSMutableArray arrayWithCapacity:self.mediaItems.count];
    self.livePhotoIndexes = [NSMutableArray array];
    self.downloaders = [NSMutableArray array];
    self.livePhotoMakers = [NSMutableArray array];
    self.temporaryPaths = [NSMutableArray array];
    for (__unused id item in self.mediaItems) {
        [self.resolvedPaths addObject:NSNull.null];
        [self.resolvedVideoPaths addObject:NSNull.null];
        [self.livePhotoTimes addObject:NSNull.null];
    }

    NSMutableArray<NSDictionary *> *requests = [NSMutableArray array];
    for (NSUInteger index = 0; index < self.mediaItems.count; index++) {
        id mediaItem = self.mediaItems[index];
        [requests addObject:@{ @"item": mediaItem, @"index": @(index), @"video": @NO }];
        id livePhotoMediaItem = !isVideo ? NeoWCMomentsObjectForSelector(mediaItem, @"livePhotoMediaItem") : nil;
        BOOL isLivePhoto = !isVideo && (NeoWCMomentsBoolForSelector(mediaItem, @"isLivePhoto") || livePhotoMediaItem != nil);
        if (isLivePhoto) {
            long long stillImageTimeMs = 0;
            BOOL hasStillImageTime = NeoWCMomentsLongLongForSelector(mediaItem, @"livePhotoStillImageTimeMs", &stillImageTimeMs);
            if (!hasStillImageTime && livePhotoMediaItem) {
                hasStillImageTime = NeoWCMomentsLongLongForSelector(livePhotoMediaItem, @"livePhotoStillImageTimeMs", &stillImageTimeMs);
            }
            if (!livePhotoMediaItem) {
                self.failed = YES;
                continue;
            }
            [self.livePhotoIndexes addObject:@(index)];
            // A cold, never-played Live Photo commonly reports no still-image
            // timestamp (or zero). Match WeChatX by allowing that state; after
            // the MOV finishes downloading, the save path derives a safe time
            // from its duration instead of requiring playback to prime it.
            self.livePhotoTimes[index] = @(hasStillImageTime ? stillImageTimeMs : 0);
            [requests addObject:@{ @"item": livePhotoMediaItem, @"parent": mediaItem,
                                   @"index": @(index), @"video": @YES }];
        }
    }
    self.livePhotoSaveQueue = [self.livePhotoIndexes mutableCopy];
    self.remainingDownloads = requests.count;
    for (NSDictionary *request in requests) {
        [self resolvePathForMediaItem:request[@"item"]
                      parentMediaItem:request[@"parent"]
                                index:[request[@"index"] unsignedIntegerValue]
                          videoPath:[request[@"video"] boolValue]];
    }
    if (self.remainingDownloads == 0) [self finishMediaResolutionIfNeeded];
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

static BOOL NeoWCMomentCanSaveMedia(id dataItem) {
    id contentObject = NeoWCMomentsContentObject(dataItem);
    return (NeoWCMomentsBoolForSelector(contentObject, @"isPhotoType") ||
            NeoWCMomentsBoolForSelector(contentObject, @"isVideoType")) &&
           NeoWCMomentsMediaItems(dataItem).count > 0;
}

static void NeoWCSaveMomentMedia(id dataItem, UIViewController *presenter) {
    if (!NeoWCEnhancementEnabled(NeoWCMomentsSaveImagesEnabledKey) || !presenter.view.window) return;
    if (!NeoWCMomentCanSaveMedia(dataItem)) {
        NeoWCShowTransientMessage(@"该条朋友圈没有可保存的媒体", NO);
        return;
    }
    NeoWCMomentsMediaSaveTask *activeTask = [NeoWCActiveMomentsMediaSaveTask isKindOfClass:[NeoWCMomentsMediaSaveTask class]]
        ? NeoWCActiveMomentsMediaSaveTask
        : objc_getAssociatedObject(dataItem, &NeoWCMomentsDataItemSaveTaskKey);
    if ([activeTask isKindOfClass:[NeoWCMomentsMediaSaveTask class]] && !activeTask.finished) {
        NeoWCLog(@"已忽略同一条朋友圈媒体的重复保存触发");
        return;
    }
    NeoWCMomentsMediaSaveTask *task = [NeoWCMomentsMediaSaveTask new];
    task.dataItem = dataItem;
    task.presenter = presenter;
    objc_setAssociatedObject(presenter, &NeoWCMomentsSaveTaskKey, task, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(dataItem, &NeoWCMomentsDataItemSaveTaskKey, task, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCActiveMomentsMediaSaveTask = task;
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
    UIButton *saveButton = objc_getAssociatedObject(cell, &NeoWCMomentsSaveButtonKey);
    id dataItem = NeoWCMomentsObjectForName(cell, @"m_dataItem");
    BOOL detailContext = NeoWCMomentsIsNativeDetailContext(cell);
    BOOL quickComment = NeoWCEnhancementEnabled(NeoWCMomentsQuickCommentKey) && !detailContext;
    BOOL shouldShowForward = quickComment && NeoWCEnhancementEnabled(NeoWCMomentsForwardEnabledKey);
    BOOL shouldShowSave = quickComment && NeoWCEnhancementEnabled(NeoWCMomentsSaveImagesEnabledKey) &&
                          NeoWCMomentCanSaveMedia(dataItem);
    BOOL shouldShow = shouldShowForward || shouldShowSave;
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
        [saveButton removeFromSuperview];
        objc_setAssociatedObject(cell, &NeoWCMomentsForwardButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &NeoWCMomentsSaveButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    if (!button) {
        button = NeoWCMomentsForwardButton(cell, @selector(neowc_handleMomentsForward:));
        objc_setAssociatedObject(cell, &NeoWCMomentsForwardButtonKey, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (!saveButton) {
        saveButton = NeoWCMomentsForwardButton(cell, @selector(neowc_handleMomentsSaveImages:));
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:13.0 weight:UIImageSymbolWeightRegular];
        UIImage *icon = [UIImage systemImageNamed:@"square.and.arrow.down" withConfiguration:configuration] ?:
                        [UIImage systemImageNamed:@"arrow.down.to.line" withConfiguration:configuration];
        [saveButton setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        saveButton.accessibilityLabel = @"保存朋友圈媒体";
        objc_setAssociatedObject(cell, &NeoWCMomentsSaveButtonKey, saveButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    button.hidden = !shouldShowForward;
    saveButton.hidden = !shouldShowSave;
    if (button.superview != cell) {
        [button removeFromSuperview];
        [cell addSubview:button];
    }
    if (saveButton.superview != cell) {
        [saveButton removeFromSuperview];
        [cell addSubview:saveButton];
    }
    button.tintColor = operateButton.tintColor ?: UIColor.darkGrayColor;
    saveButton.tintColor = button.tintColor;
    CGRect originalFrame = storedFrameValue ? storedFrameValue.CGRectValue : operateButton.frame;
    NSUInteger slotCount = (shouldShowForward ? 1 : 0) + (shouldShowSave ? 1 : 0);
    CGRect shiftedFrame = CGRectOffset(originalFrame, -36.0 * slotCount, 0.0);
    CGRect oneSlotFrame = CGRectOffset(originalFrame, -36.0, 0.0);
    CGRect twoSlotFrame = CGRectOffset(originalFrame, -72.0, 0.0);
    if (storedFrameValue &&
        !CGRectEqualToRect(operateButton.frame, originalFrame) &&
        !CGRectEqualToRect(operateButton.frame, oneSlotFrame) &&
        !CGRectEqualToRect(operateButton.frame, twoSlotFrame)) {
        originalFrame = operateButton.frame;
        shiftedFrame = CGRectOffset(originalFrame, -36.0 * slotCount, 0.0);
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
        CGFloat nextX = CGRectGetMinX(originalFrameInCell) - 36.0 * (slotCount - 1);
        if (shouldShowForward) {
            button.frame = CGRectMake(nextX, CGRectGetMinY(originalFrameInCell) - CGRectGetHeight(originalFrameInCell) - 2.0,
                                      CGRectGetWidth(originalFrameInCell), CGRectGetHeight(originalFrameInCell));
            nextX += 36.0;
        }
        if (shouldShowSave) {
            saveButton.frame = CGRectMake(nextX, CGRectGetMinY(originalFrameInCell) - CGRectGetHeight(originalFrameInCell) - 2.0,
                                          CGRectGetWidth(originalFrameInCell), CGRectGetHeight(originalFrameInCell));
        }
    } else {
        operateButton.frame = shiftedFrame;
        CGFloat nextX = CGRectGetMinX(originalFrameInCell) - 36.0 * (slotCount - 1);
        if (shouldShowForward) {
            button.frame = CGRectMake(nextX, CGRectGetMinY(originalFrameInCell), CGRectGetWidth(originalFrameInCell), CGRectGetHeight(originalFrameInCell));
            nextX += 36.0;
        }
        if (shouldShowSave) {
            saveButton.frame = CGRectMake(nextX, CGRectGetMinY(originalFrameInCell), CGRectGetWidth(originalFrameInCell), CGRectGetHeight(originalFrameInCell));
        }
    }
    if (shouldShowForward) {
        button.alpha = 1.0;
        [cell bringSubviewToFront:button];
    }
    if (shouldShowSave) {
        saveButton.alpha = 1.0;
        [cell bringSubviewToFront:saveButton];
    }
}

static void NeoWCRestoreMomentsFloatMenu(WCOperateFloatView *floatView) {
    NeoWCMomentsFloatMenuSnapshot *snapshot = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSnapshotKey);
    if (![snapshot isKindOfClass:[NeoWCMomentsFloatMenuSnapshot class]] || snapshot.applying) return;
    snapshot.applying = YES;
    [snapshot.expandedLayerMask removeAllAnimations];
    UIButton *button = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatForwardButtonKey);
    UIButton *saveButton = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSaveButtonKey);
    UIImageView *separator = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSeparatorKey);
    UIImageView *saveSeparator = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSaveSeparatorKey);
    floatView.frame = snapshot.baseFrame;
    if (snapshot.container != floatView) snapshot.container.frame = snapshot.baseContainerFrame;
    NSUInteger count = MIN(snapshot.baseViews.count, snapshot.baseFrames.count);
    for (NSUInteger index = 0; index < count; index++) {
        snapshot.baseViews[index].frame = snapshot.baseFrames[index].CGRectValue;
    }
    button.hidden = YES;
    saveButton.hidden = YES;
    separator.hidden = YES;
    saveSeparator.hidden = YES;
    floatView.layer.mask = snapshot.originalLayerMask;
    snapshot.applying = NO;
    objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSnapshotKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NeoWCMomentsFloatMenuSnapshot *NeoWCCaptureMomentsFloatMenu(WCOperateFloatView *floatView,
                                                                   UIButton *button,
                                                                   UIButton *saveButton,
                                                                   UIView *separator,
                                                                   UIView *saveSeparator) {
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
    NSUInteger slotCount = (button.hidden ? 0 : 1) + (saveButton.hidden ? 0 : 1);
    snapshot.addedWidth = slotWidth * slotCount;
    snapshot.container = container;
    snapshot.baseContainerFrame = container.frame;
    snapshot.containerIsDirectChild = container.superview == floatView;
    snapshot.originalLayerMask = floatView.layer.mask;

    NSMutableArray<UIView *> *baseViews = [NSMutableArray array];
    NSMutableArray<NSValue *> *baseFrames = [NSMutableArray array];
    for (UIView *view in container.subviews) {
        if (view == button || view == saveButton || view == separator || view == saveSeparator) continue;
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
    CGFloat nextX = containerWidth;
    if (!button.hidden) {
        snapshot.forwardFrame = CGRectMake(nextX, slotY, slotWidth, slotHeight);
        snapshot.separatorFrame = CGRectMake(nextX - separatorWidth, separatorY, separatorWidth, separatorHeight);
        nextX += slotWidth;
    }
    if (!saveButton.hidden) {
        snapshot.saveFrame = CGRectMake(nextX, slotY, slotWidth, slotHeight);
        snapshot.saveSeparatorFrame = CGRectMake(nextX - separatorWidth, separatorY, separatorWidth, separatorHeight);
    }
    if (button.hidden) snapshot.separatorFrame = CGRectMake(containerWidth - separatorWidth,
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
    UIButton *saveButton = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSaveButtonKey);
    UIImageView *separator = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSeparatorKey);
    UIImageView *saveSeparator = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSaveSeparatorKey);
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
    saveButton.frame = snapshot.saveFrame;
    separator.frame = snapshot.separatorFrame;
    saveSeparator.frame = snapshot.saveSeparatorFrame;
    if (!button.hidden) {
        button.alpha = 1.0;
        separator.hidden = NO;
        [snapshot.container bringSubviewToFront:separator];
        [snapshot.container bringSubviewToFront:button];
    }
    if (!saveButton.hidden) {
        saveButton.alpha = 1.0;
        saveSeparator.hidden = NO;
        [snapshot.container bringSubviewToFront:saveSeparator];
        [snapshot.container bringSubviewToFront:saveButton];
    }

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
    BOOL detailContext = NeoWCMomentsIsNativeDetailContext(floatView);
    BOOL allowFloatExtension = (!NeoWCEnhancementEnabled(NeoWCMomentsQuickCommentKey) || detailContext) &&
                               dataItem != nil;
    BOOL shouldShowForward = allowFloatExtension && NeoWCEnhancementEnabled(NeoWCMomentsForwardEnabledKey);
    BOOL shouldShowSave = allowFloatExtension && NeoWCEnhancementEnabled(NeoWCMomentsSaveImagesEnabledKey) &&
                          NeoWCMomentCanSaveMedia(dataItem);
    BOOL shouldShow = shouldShowForward || shouldShowSave;
    UIControl *likeButton = nil;
    UIControl *commentButton = nil;
    NeoWCMomentsNativeFloatControls(floatView, &likeButton, &commentButton);
    UIControl *anchor = commentButton ?: likeButton;
    UIButton *button = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatForwardButtonKey);
    UIButton *saveButton = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSaveButtonKey);
    UIImageView *separator = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSeparatorKey);
    UIImageView *saveSeparator = objc_getAssociatedObject(floatView, &NeoWCMomentsFloatSaveSeparatorKey);
    if (!shouldShow || ![anchor isKindOfClass:[UIControl class]]) {
        NeoWCRestoreMomentsFloatMenu(floatView);
        [button removeFromSuperview];
        [saveButton removeFromSuperview];
        [separator removeFromSuperview];
        [saveSeparator removeFromSuperview];
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSnapshotKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatForwardButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSaveButtonKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSeparatorKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSaveSeparatorKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    if (!saveButton) {
        saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [saveButton setTitle:@"保存" forState:UIControlStateNormal];
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:14.0 weight:UIImageSymbolWeightRegular];
        UIImage *icon = [UIImage systemImageNamed:@"square.and.arrow.down" withConfiguration:configuration] ?:
                        [UIImage systemImageNamed:@"arrow.down.to.line" withConfiguration:configuration];
        [saveButton setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        saveButton.accessibilityIdentifier = @"moments_save_images";
        saveButton.accessibilityLabel = @"保存朋友圈媒体";
        saveButton.contentEdgeInsets = UIEdgeInsetsZero;
        saveButton.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        saveButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, -3.0, 0.0, 3.0);
        saveButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 3.0, 0.0, -3.0);
        [saveButton addTarget:floatView action:@selector(neowc_handleMomentsSaveImages:) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSaveButtonKey, saveButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    button.hidden = !shouldShowForward;
    saveButton.hidden = !shouldShowSave;
    UIButton *anchorButton = [anchor isKindOfClass:[UIButton class]] ? (UIButton *)anchor : nil;
    UIColor *contentColor = [anchorButton titleColorForState:UIControlStateNormal] ?: anchor.tintColor ?: UIColor.whiteColor;
    [button setTitleColor:contentColor forState:UIControlStateNormal];
    [saveButton setTitleColor:contentColor forState:UIControlStateNormal];
    [button setTitleColor:[anchorButton titleColorForState:UIControlStateHighlighted] ?: contentColor
                 forState:UIControlStateHighlighted];
    [saveButton setTitleColor:[anchorButton titleColorForState:UIControlStateHighlighted] ?: contentColor
                     forState:UIControlStateHighlighted];
    [button setTitleColor:[anchorButton titleColorForState:UIControlStateDisabled] ?: contentColor
                 forState:UIControlStateDisabled];
    button.tintColor = contentColor;
    saveButton.tintColor = contentColor;
    button.titleLabel.font = anchorButton.titleLabel.font ?: [UIFont systemFontOfSize:14.0];
    saveButton.titleLabel.font = button.titleLabel.font;
    button.contentHorizontalAlignment = anchorButton ? anchorButton.contentHorizontalAlignment : UIControlContentHorizontalAlignmentCenter;
    button.contentVerticalAlignment = anchorButton ? anchorButton.contentVerticalAlignment : UIControlContentVerticalAlignmentCenter;
    button.enabled = anchor.enabled;
    saveButton.enabled = anchor.enabled;
    if (button.superview != container) {
        [button removeFromSuperview];
        [container addSubview:button];
    }
    if (saveButton.superview != container) {
        [saveButton removeFromSuperview];
        [container addSubview:saveButton];
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

    UIImageView *clonedSaveSeparator = NeoWCCloneMomentsNativeSeparator(nativeSeparator, saveSeparator);
    if (clonedSaveSeparator != saveSeparator) {
        saveSeparator = clonedSaveSeparator;
        objc_setAssociatedObject(floatView, &NeoWCMomentsFloatSaveSeparatorKey, saveSeparator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (saveSeparator.superview != container) {
        [saveSeparator removeFromSuperview];
        [container addSubview:saveSeparator];
    }

    NeoWCMomentsFloatMenuSnapshot *snapshot = NeoWCCaptureMomentsFloatMenu(floatView, button, saveButton, separator, saveSeparator);
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
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCMomentsDoubleTapLikeKey) &&
                   !NeoWCMomentsIsNativeDetailContext(cell);
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

static void NeoWCRefreshGlassBackdropsInView(UIView *view) {
    if (!view) return;
    if ([view isKindOfClass:NeoWCGlassCapsuleView.class]) {
        [(NeoWCGlassCapsuleView *)view refreshBackdropAfterForeground];
    }
    for (UIView *subview in view.subviews) NeoWCRefreshGlassBackdropsInView(subview);
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
        NeoWCSynchronizeAvatarQuickGesture((CommonMessageCellView *)view);
        NeoWCScheduleMessageTimeRefresh(view);
    }
    for (UIView *subview in view.subviews) NeoWCSynchronizeReplyGesturesInView(subview);
}

static void NeoWCSynchronizeVisibleReplyGestures(void) {
    UIWindow *window = NeoWCActiveApplicationWindow();
    if (window) NeoWCSynchronizeReplyGesturesInView(window);
}

static id NeoWCExactIvarValue(id object, NSString *ivarName) {
    if (!object || ivarName.length == 0) return nil;
    Ivar ivar = class_getInstanceVariable([object class], ivarName.UTF8String);
    if (ivar) return object_getIvar(object, ivar);
    return NeoWCTweakSafeValue(object, ivarName);
}

static void NeoWCApplyAutoOriginalSelection(id controller, NSString *originCheckKey) {
    if (!controller || !NeoWCEnhancementEnabled(NeoWCAutoOriginalImageEnabledKey)) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!NeoWCEnhancementEnabled(NeoWCAutoOriginalImageEnabledKey)) return;

        SEL selectedSelector = NSSelectorFromString(@"isOriginSelected");
        SEL checkSelector = NSSelectorFromString(@"onOriginImageCheck:");
        if ([controller respondsToSelector:selectedSelector] &&
            [controller respondsToSelector:checkSelector]) {
            BOOL selected = ((BOOL (*)(id, SEL))objc_msgSend)(controller, selectedSelector);
            if (selected) return;

            id originCheck = NeoWCExactIvarValue(controller, originCheckKey);
            if (originCheck) {
                ((void (*)(id, SEL, id))objc_msgSend)(controller, checkSelector, originCheck);
                NeoWCCompatibilityMarkTriggered(@"auto-original-image");
                return;
            }
        }

        // Older WeChat builds may not expose the native checkbox callback.
        SEL setter = NSSelectorFromString(@"setIsOriginSelected:");
        if ([controller respondsToSelector:setter]) {
            ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, setter, YES);
            NeoWCCompatibilityMarkTriggered(@"auto-original-image");
        }
    });
}

static void NeoWCSetMomentsOriginalFlag(id object) {
    if (!object || !NeoWCEnhancementEnabled(NeoWCMomentsOriginalMediaPostEnabledKey)) return;
    SEL originalSelector = NSSelectorFromString(@"setOriginal:");
    if ([object respondsToSelector:originalSelector]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(object, originalSelector, YES);
    }

    // Copy WCUploadTask.mediaList before marking each upload subtask so the
    // collection cannot change while the compression flags are being updated.
    SEL mediaListSelector = NSSelectorFromString(@"mediaList");
    SEL skipSelector = NSSelectorFromString(@"setSkipCompress:");
    if (![object respondsToSelector:mediaListSelector]) return;
    id mediaList = ((id (*)(id, SEL))objc_msgSend)(object, mediaListSelector);
    id stableMediaList = [mediaList respondsToSelector:@selector(copy)] ? [mediaList copy] : mediaList;
    if (![stableMediaList conformsToProtocol:@protocol(NSFastEnumeration)]) return;
    for (id mediaTask in stableMediaList) {
        if ([mediaTask respondsToSelector:skipSelector]) {
            ((void (*)(id, SEL, BOOL))objc_msgSend)(mediaTask, skipSelector, YES);
        }
    }
}

static void NeoWCSetMomentsCommitImagesOriginal(id controller) {
    if (!controller || !NeoWCEnhancementEnabled(NeoWCMomentsOriginalMediaPostEnabledKey)) return;
    SEL imageSelectorControllerSelector = NSSelectorFromString(@"imageSelectorController");
    SEL imagesSelector = NSSelectorFromString(@"arrImages");
    SEL assetSelector = NSSelectorFromString(@"m_asset");
    SEL needOriginSelector = NSSelectorFromString(@"setM_isNeedOriginImage:");
    SEL useAssetSelector = NSSelectorFromString(@"setM_isUseMMAsset:");
    id imageSelectorController = [controller respondsToSelector:imageSelectorControllerSelector]
        ? ((id (*)(id, SEL))objc_msgSend)(controller, imageSelectorControllerSelector) : nil;
    id images = [imageSelectorController respondsToSelector:imagesSelector]
        ? ((id (*)(id, SEL))objc_msgSend)(imageSelectorController, imagesSelector) : nil;
    id stableImages = [images respondsToSelector:@selector(copy)] ? [images copy] : images;
    if ([stableImages conformsToProtocol:@protocol(NSFastEnumeration)]) {
        for (id image in stableImages) {
            id asset = [image respondsToSelector:assetSelector]
                ? ((id (*)(id, SEL))objc_msgSend)(image, assetSelector) : nil;
            if ([asset respondsToSelector:needOriginSelector]) {
                ((void (*)(id, SEL, BOOL))objc_msgSend)(asset, needOriginSelector, YES);
            }
        }
    }
    if ([controller respondsToSelector:useAssetSelector]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, useAssetSelector, YES);
    }
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

static BOOL NeoWCMessageIsFileAttachment(id message) {
    SEL fileSelector = sel_registerName("IsFileMsg");
    if ([message respondsToSelector:fileSelector] &&
        ((BOOL (*)(id, SEL))objc_msgSend)(message, fileSelector)) return YES;
    NSInteger messageType = [NeoWCTweakSafeValue(message, @"m_uiMessageType") integerValue];
    NSInteger innerType = [NeoWCTweakSafeValue(message, @"m_uiAppMsgInnerType") integerValue];
    return messageType == 0x31 && innerType == 6;
}

static NeoWCQuickReplyType NeoWCQuickReplyTypeForMessage(id message, BOOL *supported) {
    if (supported) *supported = NO;
    NSInteger messageType = [NeoWCTweakSafeValue(message, @"m_uiMessageType") integerValue];
    if (messageType == 1) {
        if (supported) *supported = YES;
        return NeoWCQuickReplyTypeText;
    }
    if (messageType == 3) {
        if (supported) *supported = YES;
        return NeoWCQuickReplyTypeImage;
    }
    if (messageType == 34) {
        if (supported) *supported = YES;
        return NeoWCQuickReplyTypeVoice;
    }
    if (NeoWCMessageIsFileAttachment(message)) {
        NSString *fileName = NeoWCTweakSafeValue(message, @"m_nsAppFileName");
        NSString *extension = fileName.pathExtension.lowercaseString;
        static NSSet<NSString *> *videoExtensions;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ videoExtensions = [NSSet setWithArray:@[@"mp4", @"mov", @"m4v"]]; });
        if ([videoExtensions containsObject:extension]) {
            if (supported) *supported = YES;
            return NeoWCQuickReplyTypeVideo;
        }
    }
    return NeoWCQuickReplyTypeText;
}

static BOOL NeoWCMessageCanAddToQuickReply(id message) {
    if (!NeoWCEnhancementEnabled(NeoWCQuickReplyEnabledKey) || !message) return NO;
    if (![[NeoWCSessionForMessage(message) lowercaseString] isEqualToString:@"filehelper"]) return NO;
    BOOL supported = NO;
    (void)NeoWCQuickReplyTypeForMessage(message, &supported);
    return supported;
}

static NSString *NeoWCQuickReplySourceMessageID(id message) {
    long long serverID = [NeoWCTweakSafeValue(message, @"m_n64MesSvrID") longLongValue];
    unsigned long long localID = [NeoWCTweakSafeValue(message, @"m_uiMesLocalID") unsignedLongLongValue];
    return serverID != 0 ? [NSString stringWithFormat:@"svr:%lld", serverID]
                         : [NSString stringWithFormat:@"local:%llu", localID];
}

static NSString *NeoWCExistingQuickReplyImagePath(id message) {
    Class wrapClass = objc_getClass("CMessageWrap");
    if (!wrapClass) return nil;
    for (NSString *selectorName in @[@"getJpgPathOfMsgHDImg:",
                                     @"getJpgPathOfMsgHdOrMiddleImg:",
                                     @"getJpgPathOfMsgMiddleImg:",
                                     @"getPathOfMsgImg:"]) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![wrapClass respondsToSelector:selector]) continue;
        id value = ((id (*)(id, SEL, id))objc_msgSend)(wrapClass, selector, message);
        NSString *path = [value isKindOfClass:NSString.class] ? value : nil;
        if (path.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:path]) return path;
    }
    return nil;
}

static NSString *NeoWCExistingQuickReplyAttachmentPath(id message) {
    SEL selector = sel_registerName("GetAppAttachmentPath");
    if (![message respondsToSelector:selector]) return nil;
    id value = ((id (*)(id, SEL))objc_msgSend)(message, selector);
    NSString *path = [value isKindOfClass:NSString.class] ? value : nil;
    return path.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:path] ? path : nil;
}

static NSString *NeoWCExistingQuickReplyVoicePath(id message) {
    SEL selector = sel_registerName("getVoicePath");
    if (![message respondsToSelector:selector]) return nil;
    id value = ((id (*)(id, SEL))objc_msgSend)(message, selector);
    NSString *path = [value isKindOfClass:NSString.class] ? value : nil;
    return path.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:path] ? path : nil;
}

static NSDictionary *NeoWCQuickReplyVoiceMetadata(id message) {
    id extendInfo = NeoWCTweakSafeValue(message, @"m_extendInfoWithMsgType");
    NSNumber *voiceTime = NeoWCTweakSafeValue(extendInfo, @"m_uiVoiceTime");
    NSNumber *voiceFormat = NeoWCTweakSafeValue(extendInfo, @"m_uiVoiceFormat");
    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    if ([voiceTime respondsToSelector:@selector(unsignedIntegerValue)] && voiceTime.unsignedIntegerValue > 0) metadata[@"voiceTime"] = voiceTime;
    if ([voiceFormat respondsToSelector:@selector(unsignedIntegerValue)]) metadata[@"voiceFormat"] = voiceFormat;
    return metadata;
}

typedef NS_ENUM(NSUInteger, NeoWCMediaToVoiceKind) {
    NeoWCMediaToVoiceKindAudioFile = 1,
    NeoWCMediaToVoiceKindVideo,
    NeoWCMediaToVoiceKindMusic,
};

static BOOL NeoWCMediaToVoiceKindEnabled(NeoWCMediaToVoiceKind kind) {
    if (!NeoWCEnhancementEnabled(NeoWCMediaToVoiceEnabledKey)) return NO;
    NSString *key = kind == NeoWCMediaToVoiceKindAudioFile ? NeoWCAudioFileToVoiceEnabledKey :
        (kind == NeoWCMediaToVoiceKindVideo ? NeoWCVideoToVoiceEnabledKey : NeoWCMusicToVoiceEnabledKey);
    return NeoWCEnhancementEnabled(key);
}

static NSSet<NSString *> *NeoWCAudioFileExtensions(void) {
    static NSSet<NSString *> *extensions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Matches the exact extension allow-list in WeChatX(14).
        extensions = [NSSet setWithArray:@[@"mp3", @"m4a", @"wav", @"flac"]];
    });
    return extensions;
}

static BOOL NeoWCMessageIsConvertibleAudioFile(id message) {
    if (!message) return NO;
    id extension = NeoWCTweakSafeValue(message, @"m_extendInfoWithMsgType");
    NSString *fileName = NeoWCTweakSafeValue(message, @"m_nsAppFileName");
    if (fileName.length == 0) fileName = NeoWCTweakSafeValue(extension, @"m_nsAppFileName");
    BOOL supportedExtension = [NeoWCAudioFileExtensions() containsObject:fileName.pathExtension.lowercaseString ?: @""];
    NSInteger messageType = [NeoWCTweakSafeValue(message, @"m_uiMessageType") integerValue];
    return supportedExtension && (NeoWCMessageIsFileAttachment(message) || messageType == 49);
}

static BOOL NeoWCMessageIsMusicCard(id message) {
    if (!message || [NeoWCTweakSafeValue(message, @"m_uiMessageType") integerValue] != 49) return NO;
    NSInteger innerType = [NeoWCTweakSafeValue(message, @"m_uiAppMsgInnerType") integerValue];
    if (innerType == 0) {
        innerType = [NeoWCTweakSafeValue(NeoWCTweakSafeValue(message, @"m_extendInfoWithMsgType"),
                                         @"m_uiAppMsgInnerType") integerValue];
    }
    if (innerType == 3) return YES;
    // AFN identifies music app messages from the serialized app-message body as
    // well as the parsed inner-type field. Some WeChat builds populate the XML
    // before exposing m_uiAppMsgInnerType to AppMessageCellView.
    NSString *content = NeoWCTweakSafeValue(message, @"m_nsContent");
    if (![content isKindOfClass:NSString.class]) return NO;
    return [content rangeOfString:@"<appmsg type=\"3\"" options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [content rangeOfString:@"<appmsg type='3'" options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [content rangeOfString:@"<type>3</type>" options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [content rangeOfString:@"<mediatagname>music" options:NSCaseInsensitiveSearch].location != NSNotFound;
}

static NSString *NeoWCMusicCardPlayableURLString(id message) {
    id extension = NeoWCTweakSafeValue(message, @"m_extendInfoWithMsgType");
    NSArray<NSString *> *keys = @[@"m_nsAppMediaDataUrl", @"m_nsAppMediaLowBandDataUrl",
                                  @"m_nsAppMediaUrl", @"m_nsAppMediaLowUrl"];
    for (id owner in @[message ?: NSNull.null, extension ?: NSNull.null]) {
        if (owner == NSNull.null) continue;
        for (NSString *key in keys) {
            NSString *value = NeoWCTweakSafeValue(owner, key);
            if (![value isKindOfClass:NSString.class]) continue;
            NSString *trimmed = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            NSURL *URL = [NSURL URLWithString:trimmed];
            NSString *scheme = URL.scheme.lowercaseString;
            if (([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"]) && URL.host.length > 0) {
                return trimmed;
            }
        }
    }
    NSString *content = NeoWCTweakSafeValue(message, @"m_nsContent");
    if ([content isKindOfClass:NSString.class]) {
        NSRegularExpression *expression = [NSRegularExpression
            regularExpressionWithPattern:@"(?is)<(?:dataurl|lowdataurl|musicurl|musichighbandurl|musiclowbandurl)>\\s*(?:<!\\[CDATA\\[)?(.*?)(?:\\]\\]>)?\\s*</(?:dataurl|lowdataurl|musicurl|musichighbandurl|musiclowbandurl)>"
                                 options:0 error:nil];
        for (NSTextCheckingResult *match in [expression matchesInString:content options:0
                                                                        range:NSMakeRange(0, content.length)]) {
            if (match.numberOfRanges < 2) continue;
            NSString *value = [[content substringWithRange:[match rangeAtIndex:1]]
                stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            value = [value stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
            NSURL *URL = [NSURL URLWithString:value];
            NSString *scheme = URL.scheme.lowercaseString;
            if (([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"]) && URL.host.length > 0) {
                return value;
            }
        }
    }
    return nil;
}

static NSString *NeoWCExistingVideoMessagePath(id message) {
    if (!message) return nil;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    Class wrapClass = objc_getClass("CMessageWrap");
    for (NSString *selectorName in @[@"GetPathOfMesVideoWithMessageWrap:",
                                     @"GetPathOfRawVideoWithMessageWrap:",
                                     @"GetPathOfRawOrCompressVideo:"]) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![wrapClass respondsToSelector:selector]) continue;
        id value = ((id (*)(id, SEL, id))objc_msgSend)(wrapClass, selector, message);
        NSString *path = [value isKindOfClass:NSURL.class] ? [value path] :
            ([value isKindOfClass:NSString.class] ? value : nil);
        NSNumber *size = path.length > 0 ? [[fileManager attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize] : nil;
        if (size.unsignedLongLongValue > 0) return path;
    }
    for (NSString *selectorName in @[@"GetCdnDownloadPathOfVideo",
                                     @"GetLivePhotoVideoPath",
                                     @"GetLivePhotoHDVideoPath"]) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![message respondsToSelector:selector]) continue;
        id value = ((id (*)(id, SEL))objc_msgSend)(message, selector);
        NSString *path = [value isKindOfClass:NSURL.class] ? [value path] :
            ([value isKindOfClass:NSString.class] ? value : nil);
        NSNumber *size = path.length > 0 ? [[fileManager attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize] : nil;
        if (size.unsignedLongLongValue > 0) return path;
    }
    return nil;
}

static NSString *NeoWCExistingAudioFileMessagePath(id message) {
    if (!message) return nil;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    for (NSString *selectorName in @[@"GetAppAttachmentPath", @"getAppAttachmentPath",
                                     @"appAttachmentPath", @"getFilePath", @"filePath",
                                     @"localPath", @"path", @"m_nsFilePath", @"m_nsAppFilePath"]) {
        id value = NeoWCTweakValueForSelectorNames(message, @[selectorName]);
        NSString *path = [value isKindOfClass:NSURL.class] ? [value path] :
            ([value isKindOfClass:NSString.class] ? value : nil);
        NSNumber *size = path.length > 0 ? [[fileManager attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize] : nil;
        if (size.unsignedLongLongValue > 0) return path;
    }
    return nil;
}

static NSString *NeoWCMediaToVoiceLocalPath(id message, NeoWCMediaToVoiceKind kind) {
    if (kind == NeoWCMediaToVoiceKindAudioFile) return NeoWCExistingAudioFileMessagePath(message);
    if (kind == NeoWCMediaToVoiceKindVideo) return NeoWCExistingVideoMessagePath(message);
    return nil;
}

static NSString *NeoWCMediaToVoiceTemporaryPath(NSString *extension) {
    NSString *name = [NSString stringWithFormat:@"NeoWC-media-to-voice-%@.%@",
                      NSUUID.UUID.UUIDString, extension.length > 0 ? extension : @"tmp"];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:name];
}

static BOOL NeoWCSendConvertedSilkVoice(NSString *silkPath,
                                        NSUInteger durationMilliseconds,
                                        NSString *session) {
    Class wrapClass = objc_getClass("CMessageWrap");
    SEL initializer = sel_registerName("initWithMsgType:");
    if (!wrapClass || ![wrapClass instancesRespondToSelector:initializer]) return NO;
    id voice = ((id (*)(id, SEL, NSUInteger))objc_msgSend)([wrapClass alloc], initializer, 34);
    if (!voice) return NO;
    NeoWCTweakSetValue(voice, @"m_uiMessageType", @34);
    id extension = NeoWCTweakSafeValue(voice, @"m_extendInfoWithMsgType");
    NeoWCTweakSetValue(voice, @"m_uiVoiceTime", @(MAX((NSUInteger)1, durationMilliseconds)));
    NeoWCTweakSetValue(voice, @"m_uiVoiceFormat", @4);
    NeoWCTweakSetValue(voice, @"m_uiVoiceForwardFlag", @1);
    NeoWCTweakSetValue(extension, @"m_uiVoiceTime", @(MAX((NSUInteger)1, durationMilliseconds)));
    NeoWCTweakSetValue(extension, @"m_uiVoiceFormat", @4);
    NeoWCTweakSetValue(extension, @"m_uiVoiceForwardFlag", @1);
    return NeoWCSendVoiceMessage(voice, silkPath, session);
}

static void NeoWCFinishMediaToVoiceConversion(NSString *sourcePath,
                                               NSString *downloadedPath,
                                               NSString *session,
                                               id message) {
    NSString *silkPath = NeoWCMediaToVoiceTemporaryPath(@"silk");
    NSError *conversionError = nil;
    NSUInteger durationMilliseconds = 0;
    BOOL converted = NeoWCEncodeAudioFileToSilk(sourcePath, silkPath, &durationMilliseconds, &conversionError);
    if (downloadedPath.length > 0) [NSFileManager.defaultManager removeItemAtPath:downloadedPath error:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL queued = converted && NeoWCSendConvertedSilkVoice(silkPath, durationMilliseconds, session);
        [NSFileManager.defaultManager removeItemAtPath:silkPath error:nil];
        objc_setAssociatedObject(message, &NeoWCMediaToVoiceInProgressKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (!converted) {
            NeoWCShowTransientMessage(conversionError.localizedDescription ?: @"媒体转语音失败", NO);
        } else if (!queued) {
            NeoWCShowTransientMessage(@"微信语音发送接口已变化，未发送", NO);
        } else {
            NeoWCShowTransientMessage(@"已提交微信语音发送", YES);
        }
    });
}

static void NeoWCConvertMusicURLToVoice(NSString *URLString, NSString *session, id message) {
    NSURL *URL = [NSURL URLWithString:URLString];
    if (!URL) {
        objc_setAssociatedObject(message, &NeoWCMediaToVoiceInProgressKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NeoWCShowTransientMessage(@"音乐卡片没有有效播放地址", NO);
        return;
    }
    NSURLSessionDownloadTask *task = [NSURLSession.sharedSession downloadTaskWithURL:URL
        completionHandler:^(NSURL *location, NSURLResponse *response, NSError *downloadError) {
        NSInteger statusCode = [response isKindOfClass:NSHTTPURLResponse.class]
            ? [(NSHTTPURLResponse *)response statusCode] : 200;
        if (downloadError || !location || statusCode < 200 || statusCode >= 300) {
            dispatch_async(dispatch_get_main_queue(), ^{
                objc_setAssociatedObject(message, &NeoWCMediaToVoiceInProgressKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                NeoWCShowTransientMessage(downloadError.localizedDescription ?: @"音乐音频下载失败", NO);
            });
            return;
        }
        NSString *downloadExtension = response.suggestedFilename.pathExtension.lowercaseString;
        if (downloadExtension.length == 0) downloadExtension = URL.pathExtension.lowercaseString;
        if (downloadExtension.length == 0) {
            NSString *MIMEType = response.MIMEType.lowercaseString;
            if ([MIMEType containsString:@"mpeg"]) downloadExtension = @"mp3";
            else if ([MIMEType containsString:@"wav"]) downloadExtension = @"wav";
            else if ([MIMEType containsString:@"flac"]) downloadExtension = @"flac";
            else if ([MIMEType containsString:@"mp4"] || [MIMEType containsString:@"aac"]) downloadExtension = @"m4a";
        }
        NSString *downloadedPath = NeoWCMediaToVoiceTemporaryPath(downloadExtension.length > 0 ? downloadExtension : @"m4a");
        NSError *moveError = nil;
        if (![NSFileManager.defaultManager moveItemAtURL:location
                                                   toURL:[NSURL fileURLWithPath:downloadedPath]
                                                   error:&moveError]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                objc_setAssociatedObject(message, &NeoWCMediaToVoiceInProgressKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                NeoWCShowTransientMessage(moveError.localizedDescription ?: @"无法保存音乐音频", NO);
            });
            return;
        }
        NeoWCFinishMediaToVoiceConversion(downloadedPath, downloadedPath, session, message);
    }];
    [task resume];
}

static NSString *NeoWCMediaToVoiceDisplayName(id message, NeoWCMediaToVoiceKind kind) {
    NSString *title = kind == NeoWCMediaToVoiceKindAudioFile
        ? NeoWCTweakSafeValue(message, @"m_nsAppFileName")
        : NeoWCTweakSafeValue(message, @"m_nsTitle");
    if ([title isKindOfClass:NSString.class] && title.length > 0) return title;
    return kind == NeoWCMediaToVoiceKindVideo ? @"聊天视频" :
        (kind == NeoWCMediaToVoiceKindMusic ? @"音乐卡片" : @"音频文件");
}

static void NeoWCPresentMediaToVoiceConfirmation(id cell, NeoWCMediaToVoiceKind kind) {
    if (!NeoWCMediaToVoiceKindEnabled(kind)) return;
    id message = NeoWCMessageWrapForCell(cell);
    if (kind == NeoWCMediaToVoiceKindAudioFile && !NeoWCMessageIsConvertibleAudioFile(message)) return;
    if (kind == NeoWCMediaToVoiceKindMusic && !NeoWCMessageIsMusicCard(message)) return;
    NSString *session = [NeoWCSessionForMessage(message) copy];
    UIViewController *presenter = NeoWCJokerPresenterForCell(cell);
    if (!message || session.length == 0 || !presenter.view.window) return;
    if ([objc_getAssociatedObject(message, &NeoWCMediaToVoiceInProgressKey) boolValue]) {
        NeoWCShowTransientMessage(@"该媒体正在转换，请稍候", NO);
        return;
    }

    NSString *localPath = NeoWCMediaToVoiceLocalPath(message, kind);
    NSString *musicURL = kind == NeoWCMediaToVoiceKindMusic ? NeoWCMusicCardPlayableURLString(message) : nil;
    if (kind != NeoWCMediaToVoiceKindMusic && localPath.length == 0) {
        NeoWCShowTransientMessage(kind == NeoWCMediaToVoiceKindVideo
            ? @"未找到完整视频文件，请先播放或下载完视频"
            : @"未找到完整音频文件，请先下载完成", NO);
        return;
    }
    if (kind == NeoWCMediaToVoiceKindMusic && musicURL.length == 0) {
        NeoWCShowTransientMessage(@"音乐卡片没有可下载的播放地址", NO);
        return;
    }

    NSString *name = NeoWCMediaToVoiceDisplayName(message, kind);
    NSString *detail = [NSString stringWithFormat:@"发送到：%@\n来源：%@", session, name];
    if (localPath.length > 0) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:localPath] options:nil];
        if ([asset tracksWithMediaType:AVMediaTypeAudio].count == 0) {
            NeoWCShowTransientMessage(@"该媒体不包含可用音轨", NO);
            return;
        }
        NSTimeInterval seconds = CMTimeGetSeconds(asset.duration);
        if (isfinite(seconds) && seconds > 0.0) {
            NSInteger totalSeconds = MAX((NSInteger)1, (NSInteger)llround(seconds));
            detail = [detail stringByAppendingFormat:@"\n时长：%ld:%02ld",
                      (long)(totalSeconds / 60), (long)(totalSeconds % 60)];
        }
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"转为语音发送？"
                                                                   message:detail
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"转换并发送" style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction *action) {
        objc_setAssociatedObject(message, &NeoWCMediaToVoiceInProgressKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NeoWCShowTransientMessage(kind == NeoWCMediaToVoiceKindMusic ? @"正在下载并转换音乐" : @"正在转换媒体音轨", YES);
        if (kind == NeoWCMediaToVoiceKindMusic) {
            NeoWCConvertMusicURLToVoice(musicURL, session, message);
        } else {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                NeoWCFinishMediaToVoiceConversion(localPath, nil, session, message);
            });
        }
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static NSArray *NeoWCOperationMenuItemsWithMediaToVoice(id target,
                                                         NSArray *originalItems,
                                                         NeoWCMediaToVoiceKind kind) {
    if (![originalItems isKindOfClass:NSArray.class] || !NeoWCMediaToVoiceKindEnabled(kind)) return originalItems;
    id message = NeoWCMessageWrapForCell(target);
    BOOL eligible = kind == NeoWCMediaToVoiceKindAudioFile ? NeoWCMessageIsConvertibleAudioFile(message) :
        (kind == NeoWCMediaToVoiceKindMusic ? NeoWCMessageIsMusicCard(message) : message != nil);
    if (!eligible) return originalItems;
    for (id item in originalItems) {
        if ([NeoWCTweakSafeValue(item, @"title") isEqualToString:@"转语音"]) return originalItems;
    }
    Class itemClass = objc_getClass("MMMenuItem");
    if (!itemClass || ![itemClass instancesRespondToSelector:@selector(initWithTitle:icon:target:action:)]) return originalItems;
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:18.0
                                                                                                  weight:UIImageSymbolWeightRegular];
    UIImage *icon = [[UIImage systemImageNamed:@"waveform" withConfiguration:configuration]
        imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    SEL action = kind == NeoWCMediaToVoiceKindAudioFile ? @selector(neowc_convertAudioFileToVoice:) :
        (kind == NeoWCMediaToVoiceKindVideo ? @selector(neowc_convertVideoToVoice:) :
                                             @selector(neowc_convertMusicToVoice:));
    MMMenuItem *item = [[itemClass alloc] initWithTitle:@"转语音" icon:icon target:target action:action];
    if (!item) return originalItems;
    NSMutableArray *items = [originalItems mutableCopy];
    [items addObject:item];
    return items;
}

static BOOL NeoWCMessageLooksLikeEncryptedMedia(id message) {
    if (!NeoWCMediaEncryptionActive() || !message) return NO;
    NSString *path = NeoWCExistingQuickReplyAttachmentPath(message);
    if (path.length > 0 && NeoWCWXCInspectFile(path, nil, nil)) return YES;
    NSString *fileName = NeoWCTweakSafeValue(message, @"m_nsAppFileName");
    if (fileName.length == 0) {
        fileName = NeoWCTweakSafeValue(NeoWCTweakSafeValue(message, @"m_extendInfoWithMsgType"),
                                       @"m_nsAppFileName");
    }
    NSString *upper = fileName.uppercaseString;
    return [fileName.pathExtension caseInsensitiveCompare:@"WeChatX"] == NSOrderedSame ||
           [upper hasPrefix:@"WXC_IMAGE_"] || [upper hasPrefix:@"WXCA_IMAGE_"] ||
           [upper hasPrefix:@"WXC_VIDEO_"] || [upper hasPrefix:@"WXCA_VIDEO_"];
}

static NSArray *NeoWCOperationMenuItemsWithEncryptedPreview(id target, NSArray *originalItems) {
    if (![originalItems isKindOfClass:NSArray.class] ||
        !NeoWCMessageLooksLikeEncryptedMedia(NeoWCMessageWrapForCell(target))) return originalItems;
    for (id item in originalItems) {
        if ([NeoWCTweakSafeValue(item, @"title") isEqualToString:@"解密预览"]) return originalItems;
    }
    Class itemClass = objc_getClass("MMMenuItem");
    if (!itemClass || ![itemClass instancesRespondToSelector:@selector(initWithTitle:icon:target:action:)]) {
        return originalItems;
    }
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:18.0
                                                                                                  weight:UIImageSymbolWeightRegular];
    UIImage *icon = [[UIImage systemImageNamed:@"lock.open" withConfiguration:configuration]
        imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    MMMenuItem *item = [[itemClass alloc] initWithTitle:@"解密预览" icon:icon target:target
                                                action:@selector(neowc_previewEncryptedMedia:)];
    if (!item) return originalItems;
    NSMutableArray *items = [originalItems mutableCopy];
    [items insertObject:item atIndex:0];
    return items;
}

static void NeoWCPresentEncryptedMediaPreview(id cell) {
    id message = NeoWCMessageWrapForCell(cell);
    NSString *path = NeoWCExistingQuickReplyAttachmentPath(message);
    if (path.length == 0) {
        NeoWCShowTransientMessage(@"请先下载加密文件后再预览", NO);
        return;
    }
    UIViewController *presenter = NeoWCJokerPresenterForCell(cell);
    if (!presenter.view.window) return;
    NSString *temporaryBase = [NeoWCEncryptionTemporaryDirectory(@"Preview")
        stringByAppendingPathComponent:[NSString stringWithFormat:@"preview_%@", NSUUID.UUID.UUIDString]];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        uint8_t type = 0;
        NSString *metadata = nil;
        NSString *temporaryPath = [temporaryBase stringByAppendingPathExtension:@"tmp"];
        BOOL decrypted = NeoWCWXCDecryptFile(path, temporaryPath, &type, &metadata, &error);
        NSString *finalPath = temporaryPath;
        if (decrypted) {
            NSString *extensionName = metadata.lowercaseString;
            if ([extensionName hasPrefix:@"a:"]) extensionName = [extensionName substringFromIndex:2];
            NSCharacterSet *invalidExtensionCharacters =
                [NSCharacterSet.alphanumericCharacterSet invertedSet];
            extensionName = [[extensionName componentsSeparatedByCharactersInSet:invalidExtensionCharacters]
                componentsJoinedByString:@""];
            if (extensionName.length > 12) extensionName = [extensionName substringToIndex:12];
            if (extensionName.length == 0) {
                extensionName = type == NeoWCWXCFileTypeVideo ? @"mp4" : @"jpg";
            }
            finalPath = [temporaryBase stringByAppendingPathExtension:extensionName];
            [NSFileManager.defaultManager removeItemAtPath:finalPath error:nil];
            if (![NSFileManager.defaultManager moveItemAtPath:temporaryPath toPath:finalPath error:&error]) {
                decrypted = NO;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!decrypted) {
                [NSFileManager.defaultManager removeItemAtPath:temporaryPath error:nil];
                NeoWCShowTransientMessage(error.localizedDescription ?: @"解密预览失败", NO);
                return;
            }
            UIViewController *visiblePresenter = NeoWCJokerPresenterForCell(cell);
            if (!visiblePresenter.view.window) {
                [NSFileManager.defaultManager removeItemAtPath:finalPath error:nil];
                return;
            }
            if (type == NeoWCWXCFileTypeVideo) {
                NeoWCEncryptedVideoPreviewController *controller = [NeoWCEncryptedVideoPreviewController new];
                controller.temporaryPath = finalPath;
                controller.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:finalPath]];
                controller.modalPresentationStyle = UIModalPresentationFullScreen;
                [visiblePresenter presentViewController:controller animated:YES completion:^{ [controller.player play]; }];
            } else {
                UIImage *image = [UIImage imageWithContentsOfFile:finalPath];
                [NSFileManager.defaultManager removeItemAtPath:finalPath error:nil];
                if (!image) {
                    NeoWCShowTransientMessage(@"解密成功，但图片格式无法预览", NO);
                    return;
                }
                NeoWCEncryptedImagePreviewController *controller = [NeoWCEncryptedImagePreviewController new];
                controller.image = image;
                controller.modalPresentationStyle = UIModalPresentationFullScreen;
                [visiblePresenter presentViewController:controller animated:YES completion:nil];
            }
            (void)metadata;
            NeoWCCompatibilityMarkTriggered(@"encrypted-media-preview");
        });
    });
}

static void NeoWCCommitMessageToQuickReply(id message, NeoWCQuickReplyType type, NSString *session,
                                           NSString *messageID, NSString *path, NSString *remark,
                                           NSString *folderIdentifier) {
    NSString *trimmedRemark = [remark stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSUInteger beforeCount = NeoWCQuickReplyStore.sharedStore.items.count;
    NSError *error = nil;
    NeoWCQuickReplyItem *item = nil;
    if (type == NeoWCQuickReplyTypeText) {
        NSString *text = NeoWCTweakSafeValue(message, @"m_nsContent");
        item = [NeoWCQuickReplyStore.sharedStore addText:text ?: @""
                                                    title:trimmedRemark
                                        folderIdentifier:folderIdentifier
                                       sourceConversation:session
                                          sourceMessageID:messageID
                                                    error:&error];
    } else {
        item = [NeoWCQuickReplyStore.sharedStore addMediaAtURL:[NSURL fileURLWithPath:path]
                                                          type:type
                                                         title:trimmedRemark
                                              folderIdentifier:folderIdentifier
                                            sourceConversation:session
                                               sourceMessageID:messageID
                                                         error:&error];
        if (item && NeoWCQuickReplyStore.sharedStore.items.count > beforeCount) {
            if (type == NeoWCQuickReplyTypeVoice) item.metadata = NeoWCQuickReplyVoiceMetadata(message);
            [NeoWCQuickReplyStore.sharedStore updateItem:item error:&error];
        }
    }
    if (error) NeoWCShowTransientMessage(error.localizedDescription ?: @"加入快捷回复失败", NO);
    else if (item && NeoWCQuickReplyStore.sharedStore.items.count > beforeCount) NeoWCShowTransientMessage(@"已加入快捷回复", YES);
    else if (item) NeoWCShowTransientMessage(@"该消息已在消息库中", YES);
    else NeoWCShowTransientMessage(@"加入快捷回复失败", NO);
}

static void NeoWCPresentQuickReplyFolderPicker(UIViewController *presenter, id message, NeoWCQuickReplyType type,
                                                NSString *session, NSString *messageID, NSString *path,
                                                NSString *remark) {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"存入文件夹" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    void (^commit)(NSString *) = ^(NSString *folderIdentifier) {
        NeoWCCommitMessageToQuickReply(message, type, session, messageID, path, remark, folderIdentifier);
    };
    [sheet addAction:[UIAlertAction actionWithTitle:@"消息库根目录" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        commit(nil);
    }]];
    for (NeoWCQuickReplyFolder *folder in NeoWCQuickReplyStore.sharedStore.folders) {
        [sheet addAction:[UIAlertAction actionWithTitle:folder.name style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            commit(folder.identifier);
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"新建文件夹" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建文件夹" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"文件夹名称"; }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"创建并导入" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *saveAction) {
            NSError *error = nil;
            NeoWCQuickReplyFolder *folder = [NeoWCQuickReplyStore.sharedStore createFolderWithName:alert.textFields.firstObject.text error:&error];
            if (folder) commit(folder.identifier);
            else NeoWCShowTransientMessage(error.localizedDescription ?: @"创建文件夹失败", NO);
        }]];
        [presenter presentViewController:alert animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) { popover.sourceView = presenter.view; popover.sourceRect = presenter.view.bounds; }
    [presenter presentViewController:sheet animated:YES completion:nil];
}

static void NeoWCAddMessageToQuickReply(id cell) {
    id message = NeoWCMessageWrapForCell(cell);
    if (!NeoWCMessageCanAddToQuickReply(message)) return;
    BOOL supported = NO;
    NeoWCQuickReplyType type = NeoWCQuickReplyTypeForMessage(message, &supported);
    if (!supported) return;
    NSString *path = nil;
    if (type != NeoWCQuickReplyTypeText) {
        path = type == NeoWCQuickReplyTypeImage ? NeoWCExistingQuickReplyImagePath(message) :
            (type == NeoWCQuickReplyTypeVoice ? NeoWCExistingQuickReplyVoicePath(message) : NeoWCExistingQuickReplyAttachmentPath(message));
        if (path.length == 0) {
            NSString *notice = type == NeoWCQuickReplyTypeImage ? @"请先下载或打开原图后再加入快捷回复" :
                (type == NeoWCQuickReplyTypeVoice ? @"请先播放或下载语音后再加入快捷回复" : @"请先下载视频文件后再加入快捷回复");
            NeoWCShowTransientMessage(notice, NO);
            return;
        }
    }
    UIViewController *presenter = NeoWCJokerPresenterForCell(cell);
    if (!presenter.view.window) return;
    NSString *session = NeoWCSessionForMessage(message);
    NSString *messageID = NeoWCQuickReplySourceMessageID(message);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"加入快捷回复"
                                                                   message:@"可填写备注并选择保存文件夹。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"备注（可选）"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"选择文件夹" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NeoWCPresentQuickReplyFolderPicker(presenter, message, type, session, messageID, path,
                                           alert.textFields.firstObject.text ?: @"");
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static NSArray *NeoWCOperationMenuItemsWithQuickReply(id target, NSArray *originalItems) {
    if (![originalItems isKindOfClass:NSArray.class]) return originalItems;
    id message = NeoWCMessageWrapForCell(target);
    if (!NeoWCMessageCanAddToQuickReply(message)) return originalItems;
    for (id item in originalItems) {
        NSString *title = NeoWCTweakSafeValue(item, @"title");
        if ([title isEqualToString:@"存入素材"] || [title isEqualToString:@"加入快捷回复"]) return originalItems;
    }
    Class itemClass = objc_getClass("MMMenuItem");
    if (!itemClass || ![itemClass instancesRespondToSelector:@selector(initWithTitle:icon:target:action:)]) return originalItems;
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:18.0 weight:UIImageSymbolWeightRegular];
    UIImage *icon = [[UIImage systemImageNamed:@"tray.and.arrow.down.fill" withConfiguration:configuration]
        imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    MMMenuItem *menuItem = [[itemClass alloc] initWithTitle:@"存入素材"
                                                       icon:icon
                                                     target:target
                                                     action:@selector(neowc_addToQuickReply:)];
    if (!menuItem) return originalItems;
    NSMutableArray *items = [originalItems mutableCopy];
    [items insertObject:menuItem atIndex:0];
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

static BOOL NeoWCTryAuthorizeGame(MMAuthorizeUserInfoViewController *controller) {
    if (!controller || !NeoWCEnhancementEnabled(NeoWCAutoGameAuthorizeKey)) return NO;
    if ([objc_getAssociatedObject(controller, &NeoWCGameDidAuthorizeKey) boolValue]) return YES;
    UIButton *allowButton = NeoWCFindButton(@"允许", controller.view);
    if (!allowButton || !allowButton.window) return NO;
    objc_setAssociatedObject(controller, &NeoWCGameDidAuthorizeKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [allowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    NeoWCLog(@"已自动允许游戏扫码授权");
    NeoWCShowTransientHUD(@"已自动允许游戏授权", @"gamecontroller.fill");
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

static void NeoWCRefreshHighRefreshRateConfiguration(void) {
    NeoWCHighRefreshRateEnabled.store(NeoWCEnhancementEnabled(NeoWCScrollHighRefreshRateEnabledKey),
                                      std::memory_order_relaxed);
    NSInteger maximum = UIScreen.mainScreen.maximumFramesPerSecond;
    NeoWCHighRefreshRateScreenMaximum.store((int)MAX(60, maximum), std::memory_order_relaxed);
}

static BOOL NeoWCShouldUseHighRefreshRate(void) {
    return NeoWCHighRefreshRateEnabled.load(std::memory_order_relaxed) &&
           NeoWCHighRefreshRateApplicationActive.load(std::memory_order_relaxed);
}

@interface NeoWCEntryLoader : NSObject
@end

@implementation NeoWCEntryLoader

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        NeoWCRegisterPlugin();
        NeoWCRefreshDailyStepOverride();
        NeoWCHighRefreshRateApplicationActive.store(
            UIApplication.sharedApplication.applicationState == UIApplicationStateActive,
            std::memory_order_relaxed);
        NeoWCRefreshHighRefreshRateConfiguration();

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        NeoWCRegisterPlugin();
                        NeoWCRefreshDailyStepOverride();
                        NeoWCRefreshHighRefreshRateConfiguration();
                    }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationWillEnterForegroundNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        NeoWCRefreshDailyStepOverride();
                        NeoWCRefreshHighRefreshRateConfiguration();
                        BaseMsgContentViewController *controller = NeoWCResolveVisibleChatController();
                        if (controller) {
                            NeoWCRefreshGlassBackdropsInView(controller.navigationController.navigationBar);
                            NeoWCRefreshGlassBackdropsInView(controller.view);
                        }
                    }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        NeoWCHighRefreshRateApplicationActive.store(true, std::memory_order_relaxed);
                        NeoWCRefreshHighRefreshRateConfiguration();
                    }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationWillResignActiveNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
                        NeoWCHighRefreshRateApplicationActive.store(false, std::memory_order_relaxed);
                    }];

        [[NSNotificationCenter defaultCenter]
            addObserverForName:NeoWCEnhancementDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        NeoWCSynchronizeVisibleMomentsCells();
                        NeoWCSynchronizeVisibleReplyGestures();
                        NSString *changedKey = [note.object isKindOfClass:[NSString class]] ? note.object : nil;
                        if (!changedKey ||
                            [changedKey isEqualToString:NeoWCScrollHighRefreshRateEnabledKey] ||
                            [changedKey isEqualToString:NeoWCEnabledKey]) {
                            NeoWCRefreshHighRefreshRateConfiguration();
                        }
                        if (!changedKey ||
                            [changedKey isEqualToString:NeoWCGlobalAvatarRoundingEnabledKey] ||
                            [changedKey isEqualToString:NeoWCGlobalAvatarCornerPercentKey] ||
                            [changedKey isEqualToString:NeoWCEnabledKey]) {
                            NeoWCRefreshTrackedGlobalAvatarViews();
                        }
                        BOOL refreshChatTop = !changedKey ||
                            [changedKey isEqualToString:NeoWCChatSearchButtonEnabledKey] ||
                            [changedKey isEqualToString:NeoWCChatTopBarCapsuleEnabledKey] ||
                            [changedKey isEqualToString:NeoWCChatGlassStyleKey] ||
                            [changedKey isEqualToString:NeoWCChatGlassBlurIntensityKey] ||
                            [changedKey isEqualToString:NeoWCChatTopBarAvatarSizeKey] ||
                            [changedKey isEqualToString:NeoWCChatTopBarNicknameSizeKey];
                        BaseMsgContentViewController *visibleChat = NeoWCResolveVisibleChatController();
                        if (refreshChatTop && visibleChat) {
                            NeoWCUpdateChatTopBar(visibleChat);
                            NeoWCRefreshPinnedMessageGlassInView(visibleChat.view);
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
                            BaseMsgContentViewController *controller = NeoWCResolveVisibleChatController();
                            if (controller) {
                                NeoWCRefreshGlassBackdropsInView(controller.navigationController.navigationBar);
                                NeoWCRefreshGlassBackdropsInView(controller.view);
                            }
                            refreshVisibleChatChrome();
                            // WeChat restores different background layers in separate passes.
                            // Replay after both passes without forcing a layout cycle.
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)),
                                           dispatch_get_main_queue(), refreshVisibleChatChrome);
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                                           dispatch_get_main_queue(), refreshVisibleChatChrome);
                        }];
        }

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
        });
    });
}

@end

%hook CADisplayLink

- (void)setFrameInterval:(NSInteger)frameInterval {
    if (!NeoWCShouldUseHighRefreshRate()) {
        %orig;
        return;
    }
    %orig(1);
    if ([self respondsToSelector:@selector(setPreferredFramesPerSecond:)]) {
        self.preferredFramesPerSecond =
            NeoWCHighRefreshRateScreenMaximum.load(std::memory_order_relaxed);
    }
}

- (void)setPreferredFramesPerSecond:(NSInteger)framesPerSecond {
    if (NeoWCShouldUseHighRefreshRate()) {
        NSInteger maximum = NeoWCHighRefreshRateScreenMaximum.load(std::memory_order_relaxed);
        %orig(maximum);
        return;
    }
    %orig;
}

%end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"

%group NeoWCHighRefreshRateRange

%hook CADisplayLink

- (void)setPreferredFrameRateRange:(CAFrameRateRange)range {
    if (NeoWCShouldUseHighRefreshRate()) {
        float maximum = (float)NeoWCHighRefreshRateScreenMaximum.load(std::memory_order_relaxed);
        CAFrameRateRange preferredRange = CAFrameRateRangeMake(maximum, maximum, maximum);
        %orig(preferredRange);
        return;
    }
    %orig;
}

%end

%end

#pragma clang diagnostic pop

%hook CAMetalLayer

- (NSUInteger)maximumDrawableCount {
    if (NeoWCShouldUseHighRefreshRate()) return 2;
    return %orig;
}

- (void)setMaximumDrawableCount:(NSUInteger)maximumDrawableCount {
    if (NeoWCShouldUseHighRefreshRate()) {
        %orig(2);
        return;
    }
    %orig;
}

%end

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
    UIViewController *pickerController = (UIViewController *)self;
    NSString *target = NeoWCOfficialAlbumTarget(pickerController.presentingViewController);
    if (target.length > 0) {
        objc_setAssociatedObject(self, &NeoWCOfficialAlbumTargetKey, target,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(NeoWCAlbumEncryptionStateOwner(self), &NeoWCOfficialAlbumTargetKey, target,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    objc_setAssociatedObject(NeoWCAlbumEncryptionStateOwner(self),
                             &NeoWCAlbumEncryptionSelectedKey, @NO,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCApplyAutoOriginalSelection(self, @"m_originImageCheck");
    NeoWCLayoutAlbumEncryptionButton(self, @"m_originImageCheck");
}

- (void)initBottomBar {
    %orig;
    NeoWCLayoutAlbumEncryptionButton(self, @"m_originImageCheck");
}

- (void)initCombineSendViewIfNeeded {
    %orig;
    NeoWCApplyAutoOriginalSelection(self, @"m_originImageCheck");
    NeoWCLayoutAlbumEncryptionButton(self, @"m_originImageCheck");
}

- (void)reloadBottomBar {
    %orig;
    NeoWCApplyAutoOriginalSelection(self, @"m_originImageCheck");
    NeoWCLayoutAlbumEncryptionButton(self, @"m_originImageCheck");
}

- (void)viewDidLayoutSubviews {
    %orig;
    NeoWCLayoutAlbumEncryptionButton(self, @"m_originImageCheck");
}

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    NSString *target = NeoWCOfficialAlbumTarget((UIViewController *)self);
    if (target.length == 0) target = NeoWCChatUserName(NeoWCVisibleChatController);
    if (target.length > 0) {
        objc_setAssociatedObject(self, &NeoWCOfficialAlbumTargetKey, target, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(NeoWCAlbumEncryptionStateOwner(self), &NeoWCOfficialAlbumTargetKey, target,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    NeoWCLayoutAlbumEncryptionButton(self, @"m_originImageCheck");
}

%new
- (void)neowc_toggleAlbumEncryption:(id)sender {
    (void)sender;
    NeoWCToggleAlbumEncryption(self);
}

- (void)sendSelectedMedia {
    if (NeoWCHandleOfficialEncryptedMediaSend(self, self, nil)) return;
    %orig;
}

- (void)OnAssetSend:(id)asset {
    if (NeoWCHandleOfficialEncryptedMediaSend(self, self, asset ? @[asset] : nil)) return;
    %orig(asset);
}

- (void)sendImageFromScene:(id)scene {
    if (NeoWCHandleOfficialEncryptedMediaSend(self, self, nil)) return;
    %orig(scene);
}

- (void)sendVideoWithAsset:(id)asset {
    if (NeoWCHandleOfficialEncryptedMediaSend(self, self, asset ? @[asset] : nil)) return;
    %orig(asset);
}

- (void)previewBrowser:(id)browser
didFinishPickingWithAssetInfos:(id)assetInfos
       isUsingTemplate:(BOOL)usingTemplate {
    // This is the only path where the visible selection control belongs to
    // the preview controller while the delegate callback is received here.
    NeoWCAlbumEncryptionButton *previewButton =
        objc_getAssociatedObject(browser, &NeoWCAlbumEncryptionButtonKey);
    if (previewButton) {
        BOOL previewSelected = !previewButton.hidden && previewButton.isSelected;
        objc_setAssociatedObject(NeoWCAlbumEncryptionStateOwner(self),
                                 &NeoWCAlbumEncryptionSelectedKey, @(previewSelected),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NeoWCUpdateAlbumEncryptionButton(self);
    }
    if (!NeoWCMediaEncryptionActive() ||
        !NeoWCAlbumEncryptionButtonIsExplicitlySelected(browser)) {
        %orig(browser, assetInfos, usingTemplate);
        return;
    }
    NSArray *previewAssets = NeoWCOfficialAssetsFromPreviewInfos(assetInfos);
    if (NeoWCHandleOfficialEncryptedMediaSend(self, browser, previewAssets)) return;
    %orig(browser, assetInfos, usingTemplate);
}

%end

%hook MMAssetTimeLineConfig

- (BOOL)isRetrivingOriginImage {
    if (NeoWCEnhancementEnabled(NeoWCMomentsOriginalMediaPostEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"moments-original-media");
        return YES;
    }
    return %orig;
}

- (BOOL)shouldCompressLongImage {
    return NeoWCEnhancementEnabled(NeoWCMomentsOriginalMediaPostEnabledKey) ? NO : %orig;
}

- (CGSize)imageResultSizeForOriginSize:(CGSize)originSize {
    return NeoWCEnhancementEnabled(NeoWCMomentsOriginalMediaPostEnabledKey) ? originSize : %orig(originSize);
}

- (CGFloat)compressQuality {
    return NeoWCEnhancementEnabled(NeoWCMomentsOriginalMediaPostEnabledKey) ? 1.0 : %orig;
}

- (BOOL)useHighResolutionImageSize {
    return NeoWCEnhancementEnabled(NeoWCMomentsOriginalMediaPostEnabledKey) ? YES : %orig;
}

%end

%hook WCNewCommitViewController

- (void)OnDone {
    NeoWCSetMomentsCommitImagesOriginal(self);
    %orig;
}

- (void)commonUpdateWCUploadTask:(id)task {
    %orig(task);
    NeoWCSetMomentsOriginalFlag(task);
}

- (void)processUploadTask:(id)task {
    NeoWCSetMomentsOriginalFlag(task);
    %orig(task);
}

%end

%hook MMImagePreviewBrowserController

- (void)viewDidLoad {
    %orig;
    NeoWCApplyAutoOriginalSelection(self, @"_originImageCheck");
    NeoWCLayoutAlbumEncryptionButton(self, @"_originImageCheck");
}

- (void)initBottomBar {
    %orig;
    NeoWCLayoutAlbumEncryptionButton(self, @"_originImageCheck");
}

- (void)initCombineSendViewIfNeeded {
    %orig;
    NeoWCApplyAutoOriginalSelection(self, @"_originImageCheck");
    NeoWCLayoutAlbumEncryptionButton(self, @"_originImageCheck");
}

- (void)reactiveSendButton {
    %orig;
    NeoWCApplyAutoOriginalSelection(self, @"_originImageCheck");
    NeoWCLayoutAlbumEncryptionButton(self, @"_originImageCheck");
}

- (void)reloadSelectedCollectionView {
    %orig;
    NeoWCApplyAutoOriginalSelection(self, @"_originImageCheck");
    NeoWCLayoutAlbumEncryptionButton(self, @"_originImageCheck");
}

- (void)viewDidLayoutSubviews {
    %orig;
    NeoWCLayoutAlbumEncryptionButton(self, @"_originImageCheck");
}

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    NeoWCLayoutAlbumEncryptionButton(self, @"_originImageCheck");
}

%new
- (void)neowc_toggleAlbumEncryption:(id)sender {
    (void)sender;
    NeoWCToggleAlbumEncryption(self);
}

%end

%hook NotificationActionsMgr

- (void)userNotificationCenter:(id)center
didReceiveNotificationResponse:(id)response
         withCompletionHandler:(void (^)(void))completionHandler {
    if (NeoWCHandleNotificationResponse(response, completionHandler)) {
        return;
    }
    %orig;
}

%end

%hook MicroMessengerAppDelegate

- (void)applicationDidEnterBackground:(UIApplication *)application {
    %orig(application);
    NeoWCMomentsPrewarmCancel();
    NeoWCBackgroundKeeperEnterBackground();
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    %orig(application);
    NeoWCBackgroundKeeperWillEnterForeground();
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig(application);
    NeoWCMomentsPrewarmIfNeeded();
    NeoWCMomentsReminderTick();
    NeoWCMomentsInteractionReminderTick();
}

- (void)careEnoughForTheLiving {
    %orig;
    NeoWCMomentsReminderTick();
    NeoWCMomentsInteractionReminderTick();
}

- (void)userNotificationCenter:(id)center
didReceiveNotificationResponse:(id)response
         withCompletionHandler:(void (^)(void))completionHandler {
    if (NeoWCHandleNotificationResponse(response, completionHandler)) {
        return;
    }
    %orig;
}

%end

%hook WCNotificationCenterMgr

- (unsigned int)getUnReadMessageCount {
    unsigned int count = %orig;
    NeoWCMomentsInteractionObserveUnreadCount(self, count);
    return count;
}

- (id)getLastUnReadMessage {
    id message = %orig;
    NeoWCMomentsInteractionObserveLastUnreadMessage(self, message);
    return message;
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
        Class logicClass = objc_getClass("EditImageForwardAndEditLogicController");
        id extendedDelegate = NeoWCTweakSafeValue(self, @"delegateEx");
        id delegate = NeoWCTweakSafeValue(self, @"delegate");
        id logic = logicClass && [extendedDelegate isKindOfClass:logicClass]
            ? extendedDelegate
            : (logicClass && [delegate isKindOfClass:logicClass] ? delegate : nil);
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
    NeoWCPrepareMomentsHighQualityMenu(self);
    %orig;
    if (NeoWCPendingMomentsPermissionDataItem == permissionsDataItem) NeoWCPendingMomentsPermissionDataItem = nil;
}

%end

%hook WCTimeLineViewController

- (void)showPhotoAlert:(id)context {
    id previousController = NeoWCPendingMomentsCameraController;
    NeoWCPendingMomentsCameraController = NeoWCEnhancementEnabled(NeoWCMomentsOriginalMediaPostEnabledKey)
        ? self : nil;
    @try {
        %orig(context);
    } @finally {
        NeoWCPendingMomentsCameraController = previousController;
    }
}

%end

%hook WCCommentDetailViewControllerFB

- (void)viewDidLoad {
    NeoWCActiveMomentsDetailController = self;
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    NeoWCActiveMomentsDetailController = self;
    %orig(animated);
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig(animated);
    if (NeoWCActiveMomentsDetailController == self) NeoWCActiveMomentsDetailController = nil;
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

- (NSArray *)operationMenuItems {
    NSArray *originalItems = %orig;
    originalItems = NeoWCOperationMenuItemsWithQuickReply(self, originalItems);
    if (!NeoWCEnhancementEnabled(NeoWCVoiceForwardEnabledKey) ||
        ![originalItems isKindOfClass:[NSArray class]]) return originalItems;
    for (id item in originalItems) {
        if ([[NeoWCTweakSafeValue(item, @"title") description] containsString:@"转发"]) return originalItems;
    }
    SEL selector = NSSelectorFromString(@"forwardMenuItem");
    if (![self respondsToSelector:selector]) return originalItems;
    id forwardItem = ((id (*)(id, SEL))objc_msgSend)(self, selector);
    if (!forwardItem) return originalItems;
    NeoWCCompatibilityMarkTriggered(@"voice-forward");
    return [originalItems arrayByAddingObject:forwardItem];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(neowc_addToQuickReply:)) return NeoWCMessageCanAddToQuickReply(NeoWCMessageWrapForCell(self));
    if (NeoWCEnhancementEnabled(NeoWCVoiceForwardEnabledKey) &&
        (action == NSSelectorFromString(@"onForward:") ||
         action == NSSelectorFromString(@"doForward") ||
         action == NSSelectorFromString(@"onClickForwardMenu:"))) {
        return YES;
    }
    return %orig;
}

%new
- (void)neowc_addToQuickReply:(id)sender {
    (void)sender;
    NeoWCAddMessageToQuickReply(self);
}

- (void)layoutSubviews {
    %orig;
    id message = NeoWCImageJokerMessageForObject(self);
    NeoWCScheduleVoiceTranscription(self, message);
}

%end

%hook ForwardMessageLogicController

- (void)ForwardMsg:(id)message ToContact:(id)contact {
    NSArray *remaining = NeoWCForwardMessagesBySendingVoices(message ? @[message] : @[],
                                                             contact ? @[contact] : @[],
                                                             NULL);
    if (remaining.count == 0 && message) return;
    %orig(message, contact);
}

- (void)ForwardMsgList:(NSArray *)messages ToContact:(id)contact {
    NSArray *remaining = NeoWCForwardMessagesBySendingVoices(messages,
                                                             contact ? @[contact] : @[],
                                                             NULL);
    if (remaining.count == 0 && messages.count > 0) return;
    %orig(remaining, contact);
}

- (void)ForwardMsgList:(NSArray *)messages ToContact:(id)contact batchRevokeScene:(NSInteger)scene {
    NSArray *remaining = NeoWCForwardMessagesBySendingVoices(messages,
                                                             contact ? @[contact] : @[],
                                                             NULL);
    if (remaining.count == 0 && messages.count > 0) return;
    %orig(remaining, contact, scene);
}

- (void)ForwardMsgList:(NSArray *)messages ToContact:(id)contact WithRevokeBatchId:(id)batchID {
    NSArray *remaining = NeoWCForwardMessagesBySendingVoices(messages,
                                                             contact ? @[contact] : @[],
                                                             NULL);
    if (remaining.count == 0 && messages.count > 0) return;
    %orig(remaining, contact, batchID);
}

- (void)forwardMsgList:(NSArray *)messages toContacts:(NSArray *)contacts {
    NSArray *remaining = NeoWCForwardMessagesBySendingVoices(messages, contacts, NULL);
    if (remaining.count == 0 && messages.count > 0) return;
    %orig(remaining, contacts);
}

- (void)forwardNoConfirmForMsgList:(NSArray *)messages toContacts:(NSArray *)contacts {
    NSArray *remaining = NeoWCForwardMessagesBySendingVoices(messages, contacts, NULL);
    if (remaining.count == 0 && messages.count > 0) return;
    %orig(remaining, contacts);
}

- (void)forwardNoConfirmForMsgList:(NSArray *)messages
                        toContacts:(NSArray *)contacts
                withBatchSendScene:(NSInteger)scene {
    NSArray *remaining = NeoWCForwardMessagesBySendingVoices(messages, contacts, NULL);
    if (remaining.count == 0 && messages.count > 0) return;
    %orig(remaining, contacts, scene);
}

- (void)forwardMsgList:(NSArray *)messages
         msgOriginList:(NSArray *)origins
            toContacts:(NSArray *)contacts
            ignoreTips:(BOOL)ignoreTips {
    NSIndexSet *handled = nil;
    NSArray *remaining = NeoWCForwardMessagesBySendingVoices(messages, contacts, &handled);
    if (remaining.count == 0 && messages.count > 0) return;
    %orig(remaining, NeoWCVoiceForwardFilteredOrigins(origins, handled), contacts, ignoreTips);
}

- (void)forwardMsgList:(NSArray *)messages
         msgOriginList:(NSArray *)origins
            toContacts:(NSArray *)contacts
            ignoreTips:(BOOL)ignoreTips
       showConfirmView:(BOOL)showConfirmView {
    NSIndexSet *handled = nil;
    NSArray *remaining = NeoWCForwardMessagesBySendingVoices(messages, contacts, &handled);
    if (remaining.count == 0 && messages.count > 0) return;
    %orig(remaining,
          NeoWCVoiceForwardFilteredOrigins(origins, handled),
          contacts,
          ignoreTips,
          showConfirmView);
}

- (void)forwardMsgList:(NSArray *)messages
         msgOriginList:(NSArray *)origins
            toContacts:(NSArray *)contacts
            ignoreTips:(BOOL)ignoreTips
       showConfirmView:(BOOL)showConfirmView
      batchRevokeScene:(NSInteger)scene {
    NSIndexSet *handled = nil;
    NSArray *remaining = NeoWCForwardMessagesBySendingVoices(messages, contacts, &handled);
    if (remaining.count == 0 && messages.count > 0) return;
    %orig(remaining,
          NeoWCVoiceForwardFilteredOrigins(origins, handled),
          contacts,
          ignoreTips,
          showConfirmView,
          scene);
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

static BaseMsgContentViewController *NeoWCSendConfirmationSourceControllerForTarget(NSString *target) {
    BaseMsgContentViewController *controller = NeoWCSendConfirmationChatController;
    if (!controller || controller.isMovingFromParentViewController || controller.isBeingDismissed) return nil;
    if (controller.navigationController && controller.navigationController.topViewController != controller) return nil;
    UITabBarController *tabController = controller.tabBarController;
    if (tabController && tabController.selectedViewController != controller &&
        tabController.selectedViewController != controller.navigationController) return nil;
    return [NeoWCChatUserName(controller) isEqualToString:target] ? controller : nil;
}

static UIViewController *NeoWCSendConfirmationPresenterForTarget(NSString *target) {
    if (!NSThread.isMainThread || UIApplication.sharedApplication.applicationState != UIApplicationStateActive ||
        target.length == 0 || !NeoWCSendConfirmationIsProtectedConversation(target)) return nil;
    BaseMsgContentViewController *source = NeoWCSendConfirmationSourceControllerForTarget(target);
    if (!source) return nil;
    UIViewController *presentationRoot = source.tabBarController ?: source.navigationController ?: source;
    return presentationRoot.view.window ? presentationRoot : nil;
}

static NSString *NeoWCSendConfirmationTextSummary(id wrap) {
    NSString *content = NeoWCTweakSafeValue(wrap, @"m_nsContent");
    if (![content isKindOfClass:NSString.class]) content = @"";
    if (content.length > 60) content = [[content substringToIndex:60] stringByAppendingString:@"…"];
    return content.length > 0 ? [NSString stringWithFormat:@"文字：%@", content] : @"即将发送文字消息。";
}

static BOOL NeoWCSendConfirmationMessageIsAppEmoticon(id wrap) {
    if ([NeoWCTweakSafeValue(wrap, @"m_uiMessageType") integerValue] != 0x31) return NO;
    NSString *md5 = NeoWCTweakSafeValue(wrap, @"m_nsEmoticonMD5");
    if ([md5 isKindOfClass:NSString.class] && md5.length > 0) return YES;
    NSString *content = NeoWCTweakSafeValue(wrap, @"m_nsContent");
    if (![content isKindOfClass:NSString.class] || content.length == 0) return NO;
    return [content rangeOfString:@"<emoticonmd5>" options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [content rangeOfString:@"<emoji" options:NSCaseInsensitiveSearch].location != NSNotFound;
}

static BOOL NeoWCSendConfirmationValidateTarget(NSString *target) {
    return UIApplication.sharedApplication.applicationState == UIApplicationStateActive &&
           NeoWCSendConfirmationIsProtectedConversation(target) &&
           NeoWCSendConfirmationSourceControllerForTarget(target) != nil;
}

static void NeoWCArmImageSendConfirmationBypass(NSString *target) {
    NeoWCSendConfirmationImageBypassUsername = [target copy];
    NeoWCSendConfirmationImageBypassDeadline = CACurrentMediaTime() + 3.0;
}

static BOOL NeoWCConsumeImageSendConfirmationBypass(NSString *target) {
    CFTimeInterval now = CACurrentMediaTime();
    BOOL matches = target.length > 0 &&
        [NeoWCSendConfirmationImageBypassUsername isEqualToString:target] &&
        now <= NeoWCSendConfirmationImageBypassDeadline;
    if (matches || now > NeoWCSendConfirmationImageBypassDeadline) {
        NeoWCSendConfirmationImageBypassUsername = nil;
        NeoWCSendConfirmationImageBypassDeadline = 0.0;
    }
    return matches;
}

static void NeoWCArmVideoSendConfirmationBypass(NSString *target) {
    NeoWCSendConfirmationVideoBypassUsername = [target copy];
    NeoWCSendConfirmationVideoBypassDeadline = CACurrentMediaTime() + 3.0;
}

static BOOL NeoWCConsumeVideoSendConfirmationBypass(NSString *target) {
    CFTimeInterval now = CACurrentMediaTime();
    BOOL matches = target.length > 0 &&
        [NeoWCSendConfirmationVideoBypassUsername isEqualToString:target] &&
        now <= NeoWCSendConfirmationVideoBypassDeadline;
    if (matches || now > NeoWCSendConfirmationVideoBypassDeadline) {
        NeoWCSendConfirmationVideoBypassUsername = nil;
        NeoWCSendConfirmationVideoBypassDeadline = 0.0;
    }
    return matches;
}

%hook MMInputToolView

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        NeoWCApplyChatInputRoundingToToolView(self);
    }
    NeoWCSynchronizeQuickReplyPlusGesture(self);
}

- (void)sendMsgWithText:(id)text {
    if (!NeoWCEnhancementEnabled(NeoWCEncryptedMessageEnabledKey) ||
        ![text isKindOfClass:NSString.class]) {
        %orig(text);
        return;
    }
    NSString *sourceText = (NSString *)text;
    if (![sourceText hasPrefix:@"#加密"]) {
        %orig(text);
        return;
    }
    NSString *plainText = [[sourceText substringFromIndex:@"#加密".length]
        stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (plainText.length == 0) {
        NeoWCShowTransientMessage(@"请在“#加密”后输入要发送的文字", NO);
        return;
    }
    NSError *error = nil;
    NSString *wireText = NeoWCEncryptedTextWireString(plainText, &error);
    if (wireText.length == 0) {
        NeoWCShowTransientMessage(error.localizedDescription ?: @"生成密文失败", NO);
        return;
    }
    NeoWCCompatibilityMarkTriggered(@"encrypted-text-send");
    %orig(wireText);
}

%new
- (void)neowc_handleQuickReplyPlusLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) return;
    UIView *candidate = [self hitTest:[recognizer locationInView:self] withEvent:nil];
    UIView *sendButtonView = NeoWCTweakValueForSelectorNames(self, @[@"sendButton", @"_sendButton"]);
    BOOL sendControl = NO;
    while (candidate && candidate != self) {
        if (candidate == sendButtonView) {
            sendControl = YES;
            break;
        }
        if ([candidate isKindOfClass:UIControl.class]) {
            NSMutableString *semanticText = [NSMutableString string];
            for (NSString *value in @[candidate.accessibilityLabel ?: @"",
                                      candidate.accessibilityIdentifier ?: @"",
                                      [candidate isKindOfClass:UIButton.class] ? [(UIButton *)candidate currentTitle] ?: @"" : @""]) {
                if (value.length > 0) [semanticText appendFormat:@" %@", value.lowercaseString];
            }
            sendControl = [semanticText containsString:@"发送"] || [semanticText containsString:@"send"];
            if (sendControl) break;
        }
        candidate = candidate.superview;
    }
    if (sendControl) return;
    BaseMsgContentViewController *controller = NeoWCResolveVisibleChatController();
    if (!controller.view.window) return;
    BOOL quickReplyEnabled = NeoWCEnhancementEnabled(NeoWCQuickReplyEnabledKey);
    if (quickReplyEnabled) {
        NeoWCPresentQuickReplyLibrary(controller);
    }
}

%end

%hook MMHeadImageView

- (void)setTargetForDoubleClick:(id)target action:(SEL)action {
    BOOL nativeAssignment = !NeoWCUpdatingAvatarNativeDoubleTap;
    if (nativeAssignment) {
        if (target && action) {
            NeoWCWeakObjectBox *box = [NeoWCWeakObjectBox new];
            box.object = target;
            objc_setAssociatedObject(self, &NeoWCAvatarNativeDoubleTapTargetKey, box, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(self, &NeoWCAvatarNativeDoubleTapActionKey,
                                     NSStringFromSelector(action), OBJC_ASSOCIATION_COPY_NONATOMIC);
        } else {
            objc_setAssociatedObject(self, &NeoWCAvatarNativeDoubleTapTargetKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(self, &NeoWCAvatarNativeDoubleTapActionKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
    }
    %orig(target, action);
    if (nativeAssignment && self.window) {
        __weak MMHeadImageView *weakHeadView = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            MMHeadImageView *headView = weakHeadView;
            CommonMessageCellView *cell = headView ? NeoWCAvatarMessageCellForView(headView) : nil;
            if (cell.window) NeoWCSynchronizeAvatarQuickGesture(cell);
        });
    }
}

- (void)didMoveToSuperview {
    %orig;
    __weak MMHeadImageView *weakHeadView = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        MMHeadImageView *headView = weakHeadView;
        CommonMessageCellView *cell = headView ? NeoWCAvatarMessageCellForView(headView) : nil;
        if (cell.window) NeoWCSynchronizeAvatarQuickGesture(cell);
    });
}

- (void)layoutSubviews {
    %orig;
    if (NeoWCHeadViewIsExcludedFromGlobalAvatarRounding(self)) {
        id imageView = NeoWCTweakValueForSelectorNames(self, @[@"headImageView"]);
        if ([imageView isKindOfClass:UIImageView.class]) {
            ((UIImageView *)imageView).contentMode = UIViewContentModeScaleAspectFit;
        }
    }
    NeoWCApplyGlobalAvatarRoundingToHeadView(self);
}

- (void)didMoveToWindow {
    %orig;
    NeoWCApplyGlobalAvatarRoundingToHeadView(self);
    CommonMessageCellView *cell = NeoWCAvatarMessageCellForView(self);
    if (cell.window) NeoWCSynchronizeAvatarQuickGesture(cell);
}

- (void)setConerSize:(unsigned int)cornerSize {
    if (NeoWCHeadViewIsExcludedFromGlobalAvatarRounding(self)) {
        %orig(cornerSize);
        return;
    }
    %orig(NeoWCGlobalAvatarScaledCornerSize(cornerSize));
}

%end

%hook FakeHeadImageView

- (void)layoutSubviews {
    %orig;
    if (NeoWCHeadViewIsExcludedFromGlobalAvatarRounding(self)) {
        id imageView = NeoWCTweakValueForSelectorNames(self, @[@"headImageView"]);
        if ([imageView isKindOfClass:UIImageView.class]) {
            ((UIImageView *)imageView).contentMode = UIViewContentModeScaleAspectFit;
        }
    }
    NeoWCApplyGlobalAvatarRoundingToHeadView(self);
}

- (void)didMoveToWindow {
    %orig;
    NeoWCApplyGlobalAvatarRoundingToHeadView(self);
}

- (void)setConerSize:(unsigned int)cornerSize {
    if (NeoWCHeadViewIsExcludedFromGlobalAvatarRounding(self)) {
        %orig(cornerSize);
        return;
    }
    %orig(NeoWCGlobalAvatarScaledCornerSize(cornerSize));
}

%end

%hook MMGrowTextView

- (void)textViewDidChange:(id)textView {
    %orig(textView);
}

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
    NSString *directUserName = NeoWCTweakValueForSelectorNames(controller, @[@"getChatUserName"]);
    if ([directUserName isKindOfClass:NSString.class] && directUserName.length > 0) return directUserName;
    id contact = NeoWCTweakValueForSelectorNames(controller, @[@"m_contact", @"chatContact", @"contact"]);
    if (!contact && [controller respondsToSelector:@selector(GetContact)]) {
        contact = ((id (*)(id, SEL))objc_msgSend)(controller, @selector(GetContact));
    }
    SEL getCContactSelector = sel_registerName("GetCContact");
    if (!contact && [controller respondsToSelector:getCContactSelector]) {
        contact = ((id (*)(id, SEL))objc_msgSend)(controller, getCContactSelector);
    }
    NSString *userName = NeoWCTweakValueForSelectorNames(contact, @[@"m_nsUserName", @"m_nsUsrName", @"userName"]);
    if (userName.length == 0) userName = NeoWCTweakValueForSelectorNames(controller, @[@"m_nsUserName", @"m_nsUsrName", @"sessionUserName"]);
    return userName;
}

static MMGrowTextView *NeoWCFindGrowTextView(UIView *view) {
    if (!view) return nil;
    Class growTextClass = objc_getClass("MMGrowTextView");
    if (growTextClass && [view isKindOfClass:growTextClass]) return (MMGrowTextView *)view;
    for (UIView *subview in view.subviews) {
        MMGrowTextView *match = NeoWCFindGrowTextView(subview);
        if (match) return match;
    }
    return nil;
}

static BOOL NeoWCInsertQuickReplyText(BaseMsgContentViewController *controller, NSString *text) {
    if (!controller.view.window || text.length == 0) return NO;
    MMGrowTextView *growTextView = NeoWCFindGrowTextView(controller.view);
    UITextView *textView = NeoWCInnerTextView(growTextView);
    if (!growTextView || !textView) return NO;
    UITextRange *selection = textView.selectedTextRange;
    if (selection) {
        [textView replaceRange:selection withText:text];
    } else {
        NSString *existing = textView.text ?: @"";
        textView.text = [existing stringByAppendingString:text];
        textView.selectedRange = NSMakeRange(textView.text.length, 0);
    }
    SEL changedSelector = sel_registerName("textViewDidChange:");
    if ([growTextView respondsToSelector:changedSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(growTextView, changedSelector, textView);
    }
    [textView becomeFirstResponder];
    return YES;
}

static BOOL NeoWCSendQuickReplyTextNow(BaseMsgContentViewController *controller,
                                       NSString *lockedUserName,
                                       NSString *text) {
    if (!controller.view.window || ![NeoWCChatUserName(controller) isEqualToString:lockedUserName] || text.length == 0) return NO;
    Class wrapClass = objc_getClass("CMessageWrap");
    SEL initSelector = sel_registerName("initWithMsgType:");
    id manager = NeoWCMessageManager();
    SEL sendSelector = sel_registerName("AddMsg:MsgWrap:");
    if (!wrapClass || ![wrapClass instancesRespondToSelector:initSelector] ||
        !manager || ![manager respondsToSelector:sendSelector]) return NO;
    id wrap = ((id (*)(id, SEL, NSUInteger))objc_msgSend)([wrapClass alloc], initSelector, 1);
    if (!wrap) return NO;
    NSUInteger now = (NSUInteger)NSDate.date.timeIntervalSince1970;
    NeoWCTweakSetValue(wrap, @"m_nsFromUsr", NeoWCCurrentUserWXID() ?: @"");
    NeoWCTweakSetValue(wrap, @"m_nsToUsr", lockedUserName);
    NeoWCTweakSetValue(wrap, @"m_nsContent", text);
    NeoWCTweakSetValue(wrap, @"m_uiStatus", @1);
    NeoWCTweakSetValue(wrap, @"m_uiCreateTime", @(now));
    objc_setAssociatedObject(wrap, &NeoWCSendConfirmationNativeBypassKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    ((void (*)(id, SEL, id, id))objc_msgSend)(manager, sendSelector, lockedUserName, wrap);
    return YES;
}

static void NeoWCSendQuickReplyTextWithConfirmation(BaseMsgContentViewController *controller,
                                                     NSString *lockedUserName,
                                                     NSString *text) {
    __weak BaseMsgContentViewController *weakController = controller;
    dispatch_block_t sendAction = ^{
        BaseMsgContentViewController *strongController = weakController;
        if (!NeoWCSendQuickReplyTextNow(strongController, lockedUserName, text)) {
            NeoWCShowTransientMessage(@"快捷回复发送失败，会话或发送接口已失效", NO);
        }
    };
    NSString *preview = text.length > 60 ? [[text substringToIndex:60] stringByAppendingString:@"…"] : text;
    BOOL held = NeoWCPresentSendConfirmationIfNeeded(controller,
                                                      lockedUserName,
                                                      [NSString stringWithFormat:@"文字：%@", preview],
                                                      ^BOOL{
        BaseMsgContentViewController *strongController = weakController;
        return strongController.view.window &&
               [NeoWCChatUserName(strongController) isEqualToString:lockedUserName];
    }, sendAction);
    if (!held) sendAction();
}

@interface NeoWCMaterialSendSession : NSObject
@property (nonatomic, strong) id logic;
@property (nonatomic, strong) id message;
@property (nonatomic, strong) id contact;
@end

@implementation NeoWCMaterialSendSession
@end

static NSMutableSet<NeoWCMaterialSendSession *> *NeoWCActiveMaterialSendSessions(void) {
    static NSMutableSet<NeoWCMaterialSendSession *> *sessions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sessions = [NSMutableSet set]; });
    return sessions;
}

static BOOL NeoWCSendQuickReplyImageNow(BaseMsgContentViewController *controller,
                                        NSString *lockedUserName,
                                        NSString *path) {
    if (!controller.view.window || ![NeoWCChatUserName(controller) isEqualToString:lockedUserName]) return NO;
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    id contact = NeoWCContactForUserName(lockedUserName);
    Class providerClass = objc_getClass("PasteboardMsgProvider");
    Class forwardClass = objc_getClass("ForwardMessageLogicController");
    SEL makeSelector = sel_registerName("GetMessageFromImage:contact:");
    SEL sendSelector = sel_registerName("forwardNoConfirmForMsgList:toContacts:");
    if (!image || !contact || !providerClass || ![providerClass respondsToSelector:makeSelector] || !forwardClass) return NO;
    id message = ((id (*)(id, SEL, id, id))objc_msgSend)(providerClass, makeSelector, image, contact);
    if (message) objc_setAssociatedObject(message, &NeoWCSendConfirmationNativeBypassKey, @YES,
                                          OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    id logic = message ? [forwardClass new] : nil;
    if (!logic || ![logic respondsToSelector:sendSelector]) return NO;
    NeoWCMaterialSendSession *session = [NeoWCMaterialSendSession new];
    session.logic = logic;
    session.message = message;
    session.contact = contact;
    [NeoWCActiveMaterialSendSessions() addObject:session];
    @try {
        ((void (*)(id, SEL, id, id))objc_msgSend)(logic, sendSelector, @[message], @[contact]);
    } @catch (__unused NSException *exception) {
        [NeoWCActiveMaterialSendSessions() removeObject:session];
        return NO;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NeoWCActiveMaterialSendSessions() removeObject:session];
    });
    return YES;
}

static UIImage *NeoWCQuickReplyVideoThumbnail(NSString *path) {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(960.0, 960.0);
    CGImageRef frame = [generator copyCGImageAtTime:CMTimeMakeWithSeconds(0.0, 600) actualTime:NULL error:nil];
    if (!frame) return nil;
    UIImage *image = [UIImage imageWithCGImage:frame];
    CGImageRelease(frame);
    return image;
}

static id NeoWCQuickReplyVideoLogicController(BaseMsgContentViewController *controller) {
    if (!controller) return nil;
    id candidate = NeoWCTweakSafeValue(controller, @"m_delegate");
    if (!candidate) {
        SEL delegateSelector = sel_registerName("m_delegate");
        if ([controller respondsToSelector:delegateSelector]) {
            @try {
                candidate = ((id (*)(id, SEL))objc_msgSend)(controller, delegateSelector);
            } @catch (__unused NSException *exception) {
                candidate = nil;
            }
        }
    }
    if (candidate) return candidate;

    id manager = NeoWCServiceForClass(objc_getClass("MMMsgLogicManager"));
    for (NSString *selectorName in @[@"getTopLogicController", @"topLogicController", @"GetCurrentLogicController"]) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![manager respondsToSelector:selector]) continue;
        @try {
            candidate = ((id (*)(id, SEL))objc_msgSend)(manager, selector);
        } @catch (__unused NSException *exception) {
            candidate = nil;
        }
        if (candidate) return candidate;
    }
    return nil;
}

static BOOL NeoWCSendLocalVideoNow(BaseMsgContentViewController *controller,
                                   NSString *lockedUserName,
                                   NSString *path,
                                   UIImage *providedThumbnail,
                                   NSString **failureReason) {
    if (!controller.view.window || ![NeoWCChatUserName(controller) isEqualToString:lockedUserName] ||
        ![NSFileManager.defaultManager fileExistsAtPath:path]) {
        if (failureReason) *failureReason = @"原会话或视频文件已失效";
        return NO;
    }
    id logicController = NeoWCQuickReplyVideoLogicController(controller);
    if (!logicController) {
        if (failureReason) *failureReason = @"无法取得当前聊天的视频逻辑控制器";
        NeoWCLog(@"快捷视频发送失败：BaseMsg=%@，未取得 m_delegate 或 MMMsgLogicManager controller",
                 NSStringFromClass(controller.class));
        return NO;
    }
    id imageController = NeoWCTweakSafeValue(logicController, @"m_imageController");
    if (!imageController) {
        SEL getter = sel_registerName("m_imageController");
        if ([logicController respondsToSelector:getter]) {
            @try {
                imageController = ((id (*)(id, SEL))objc_msgSend)(logicController, getter);
            } @catch (__unused NSException *exception) {
                imageController = nil;
            }
        }
    }
    if (!imageController) {
        if (failureReason) *failureReason = @"当前聊天没有可用的视频发送控制器";
        NeoWCLog(@"快捷视频发送失败：logic=%@，未取得 m_imageController",
                 NSStringFromClass([logicController class]));
        return NO;
    }
    SEL selector = sel_registerName("onShortVideoTaken:thumbImg:editVideoAttr:paramModel:");
    if (![imageController respondsToSelector:selector]) {
        if (failureReason) *failureReason = @"当前微信的视频发送方法已变化";
        NeoWCLog(@"快捷视频发送失败：imageController=%@ 不响应 %@",
                 NSStringFromClass([imageController class]), NSStringFromSelector(selector));
        return NO;
    }
    UIImage *thumbnail = providedThumbnail;
    if (!thumbnail) thumbnail = NeoWCQuickReplyVideoThumbnail(path);
    if (!thumbnail) {
        if (failureReason) *failureReason = @"无法生成视频缩略图";
        return NO;
    }
    @try {
        NeoWCArmVideoSendConfirmationBypass(lockedUserName);
        ((void (*)(id, SEL, id, id, id, id))objc_msgSend)(imageController, selector, path, thumbnail, nil, nil);
    } @catch (NSException *exception) {
        NeoWCSendConfirmationVideoBypassUsername = nil;
        NeoWCSendConfirmationVideoBypassDeadline = 0.0;
        if (failureReason) *failureReason = @"调用微信视频发送方法失败";
        NeoWCLog(@"快捷视频发送异常：%@", exception.reason ?: exception.name);
        return NO;
    }
    return YES;
}

static BOOL NeoWCSendQuickReplyVideoNow(BaseMsgContentViewController *controller,
                                        NSString *lockedUserName,
                                        NSString *path,
                                        NeoWCQuickReplyItem *item,
                                        NSString **failureReason) {
    NSString *thumbnailPath = [NeoWCQuickReplyStore.sharedStore absoluteThumbnailPathForItem:item];
    UIImage *thumbnail = thumbnailPath.length > 0 ? [UIImage imageWithContentsOfFile:thumbnailPath] : nil;
    return NeoWCSendLocalVideoNow(controller, lockedUserName, path, thumbnail, failureReason);
}

static BOOL NeoWCSendQuickReplyVoiceNow(BaseMsgContentViewController *controller,
                                        NSString *lockedUserName,
                                        NSString *path,
                                        NeoWCQuickReplyItem *item) {
    if (!controller.view.window || ![NeoWCChatUserName(controller) isEqualToString:lockedUserName] ||
        ![NSFileManager.defaultManager fileExistsAtPath:path]) return NO;
    Class messageWrapClass = objc_getClass("CMessageWrap");
    SEL initializer = sel_registerName("initWithMsgType:");
    if (!messageWrapClass || ![messageWrapClass instancesRespondToSelector:initializer]) return NO;
    id message = ((id (*)(id, SEL, NSUInteger))objc_msgSend)([messageWrapClass alloc], initializer, 34);
    if (!message) return NO;
    NeoWCTweakSetValue(message, @"m_uiMessageType", @34);
    id extendInfo = NeoWCTweakSafeValue(message, @"m_extendInfoWithMsgType");
    NSNumber *voiceTime = [item.metadata[@"voiceTime"] respondsToSelector:@selector(unsignedIntegerValue)] ? item.metadata[@"voiceTime"] : nil;
    NSNumber *voiceFormat = [item.metadata[@"voiceFormat"] respondsToSelector:@selector(unsignedIntegerValue)] ? item.metadata[@"voiceFormat"] : nil;
    if (voiceTime.unsignedIntegerValue > 0) NeoWCTweakSetValue(extendInfo, @"m_uiVoiceTime", voiceTime);
    if (voiceFormat) NeoWCTweakSetValue(extendInfo, @"m_uiVoiceFormat", voiceFormat);
    NeoWCTweakSetValue(extendInfo, @"m_uiVoiceForwardFlag", @1);
    return NeoWCSendVoiceMessage(message, path, lockedUserName);
}

static void NeoWCSendQuickReplyMediaWithConfirmation(BaseMsgContentViewController *controller,
                                                      NSString *lockedUserName,
                                                      NeoWCQuickReplyItem *item) {
    NSString *path = [NeoWCQuickReplyStore.sharedStore absoluteMediaPathForItem:item];
    if (path.length == 0 || ![NSFileManager.defaultManager fileExistsAtPath:path]) {
        NeoWCShowTransientMessage(@"素材文件已丢失，请重新加入", NO);
        return;
    }
    __weak BaseMsgContentViewController *weakController = controller;
    dispatch_block_t sendAction = ^{
        BaseMsgContentViewController *strongController = weakController;
        NSString *failureReason = nil;
        BOOL sent = item.type == NeoWCQuickReplyTypeImage
            ? NeoWCSendQuickReplyImageNow(strongController, lockedUserName, path)
            : (item.type == NeoWCQuickReplyTypeVideo
                ? NeoWCSendQuickReplyVideoNow(strongController, lockedUserName, path, item, &failureReason)
                : NeoWCSendQuickReplyVoiceNow(strongController, lockedUserName, path, item));
        if (!sent) NeoWCShowTransientMessage(failureReason ?: @"微信媒体发送接口已变化，未发送素材", NO);
    };
    BOOL held = NeoWCPresentSendConfirmationIfNeeded(controller,
                                                      lockedUserName,
                                                      item.type == NeoWCQuickReplyTypeImage ? @"图片素材：1 张" :
                                                        (item.type == NeoWCQuickReplyTypeVideo ? @"视频素材：1 个" : @"语音素材：1 条"),
                                                      ^BOOL{
        BaseMsgContentViewController *strongController = weakController;
        return strongController.view.window &&
               [NeoWCChatUserName(strongController) isEqualToString:lockedUserName];
    }, sendAction);
    if (!held) sendAction();
}

static void NeoWCPresentQuickReplyLibrary(BaseMsgContentViewController *controller) {
    if (!controller.view.window || !NeoWCEnhancementEnabled(NeoWCQuickReplyEnabledKey)) return;
    NSString *lockedUserName = [NeoWCChatUserName(controller) copy];
    if (lockedUserName.length == 0) {
        NeoWCShowTransientMessage(@"无法识别当前会话", NO);
        return;
    }
    __weak BaseMsgContentViewController *weakController = controller;
    NeoWCQuickReplyViewController *library = [[NeoWCQuickReplyViewController alloc] initWithSelectionHandler:^(NeoWCQuickReplyItem *item) {
        BaseMsgContentViewController *strongController = weakController;
        NSString *currentUserName = NeoWCChatUserName(strongController);
        if (!strongController.view.window || ![currentUserName isEqualToString:lockedUserName]) {
            NeoWCShowTransientMessage(@"原会话已离开，未使用快捷回复", NO);
            return;
        }
        if (item.type == NeoWCQuickReplyTypeText) {
            if (!NeoWCInsertQuickReplyText(strongController, item.text)) {
                NeoWCShowTransientMessage(@"无法写入当前输入框", NO);
            }
            return;
        }
        NeoWCSendQuickReplyMediaWithConfirmation(strongController, lockedUserName, item);
    } directSendHandler:^(NeoWCQuickReplyItem *item) {
        __weak BaseMsgContentViewController *delayedController = weakController;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            BaseMsgContentViewController *strongController = delayedController;
            if (!strongController.view.window ||
                ![NeoWCChatUserName(strongController) isEqualToString:lockedUserName]) {
                NeoWCShowTransientMessage(@"原会话已离开，未发送快捷回复", NO);
                return;
            }
            if (item.type == NeoWCQuickReplyTypeText) {
                if (item.text.length > 0) NeoWCSendQuickReplyTextWithConfirmation(strongController, lockedUserName, item.text);
            } else {
                NeoWCSendQuickReplyMediaWithConfirmation(strongController, lockedUserName, item);
            }
        });
    }];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:library];
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;
    [controller presentViewController:navigation animated:YES completion:nil];
}

static void NeoWCRestoreChatTopBar(BaseMsgContentViewController *controller);
static void NeoWCUpdateChatTopBar(BaseMsgContentViewController *controller);

@interface NeoWCChatTopAvatarHostView : UIView
@property (nonatomic, strong) UIView *sourceView;
- (instancetype)initWithSourceView:(UIView *)sourceView;
@end

@implementation NeoWCChatTopAvatarHostView

- (instancetype)initWithSourceView:(UIView *)sourceView {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = YES;
    self.layer.cornerCurve = kCACornerCurveContinuous;
    _sourceView = sourceView;
    _sourceView.translatesAutoresizingMaskIntoConstraints = YES;
    _sourceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _sourceView.userInteractionEnabled = NO;
    [self addSubview:_sourceView];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat radius = CGRectGetHeight(self.bounds) * 0.5;
    // The source is now a plain image view, so the former optical inset only
    // makes the avatar appear off-axis relative to the nickname and capsule.
    CGRect imageFrame = self.bounds;
    CGFloat imageRadius = CGRectGetHeight(imageFrame) * 0.5;
    self.layer.cornerRadius = radius;
    self.sourceView.frame = imageFrame;
    self.sourceView.clipsToBounds = YES;
    self.sourceView.layer.cornerRadius = imageRadius;
    self.sourceView.layer.cornerCurve = kCACornerCurveContinuous;
    [self.sourceView layoutIfNeeded];

    UIImageView *imageView = [self.sourceView isKindOfClass:UIImageView.class]
        ? (UIImageView *)self.sourceView
        : NeoWCTweakValueForSelectorNames(self.sourceView, @[@"headImageView", @"imageView"]);
    if ([imageView isKindOfClass:UIImageView.class]) {
        imageView.frame = self.sourceView.bounds;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // Match the host/WCPulse avatar behavior: preserve the complete image
        // inside the circular viewport instead of zooming and center-cropping.
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = imageRadius;
        imageView.layer.cornerCurve = kCACornerCurveContinuous;
    }
}

@end

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

static UIImageView *NeoWCChatTopPlainAvatarImageView(UIImage *image) {
    if (![image isKindOfClass:UIImage.class]) return nil;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.backgroundColor = UIColor.clearColor;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    return imageView;
}

static UIView *NeoWCChatTopAvatarView(id contact, NSString *userName) {
    // Do not embed MMHeadImageView when the contact image is already available:
    // that host view applies its own crop while being resized and makes square
    // avatars look optically zoomed inside our second circular viewport.
    id contactImage = NeoWCTweakValueForSelectorNames(contact, @[@"getContactHeadImage"]);
    UIImageView *plainImageView = NeoWCChatTopPlainAvatarImageView(contactImage);
    if (plainImageView) return plainImageView;

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
        if ([view isKindOfClass:[UIView class]]) {
            id hostedImageView = [view isKindOfClass:UIImageView.class]
                ? view : NeoWCTweakValueForSelectorNames(view, @[@"headImageView", @"imageView"]);
            UIImage *hostedImage = [hostedImageView isKindOfClass:UIImageView.class]
                ? ((UIImageView *)hostedImageView).image : nil;
            plainImageView = NeoWCChatTopPlainAvatarImageView(hostedImage);
            if (plainImageView) return plainImageView;
            // The helper may still be loading asynchronously. Preserve it only
            // as a last-resort path so an uncached avatar can eventually appear.
            return view;
        }
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

static CGFloat NeoWCChatGlassPercent(NSString *key, CGFloat fallback,
                                     CGFloat minimum, CGFloat maximum) {
    id stored = [NSUserDefaults.standardUserDefaults objectForKey:key];
    CGFloat value = [stored respondsToSelector:@selector(doubleValue)] ? [stored doubleValue] : fallback;
    return MIN(maximum, MAX(minimum, value));
}

static UIView *NeoWCChatTopGlassContainer(CGFloat cornerRadius, UIView **contentViewOut) {
    NeoWCGlassCapsuleView *container = [NeoWCGlassCapsuleView new];
    container.capsuleCornerRadius = cornerRadius;
    objc_setAssociatedObject(container, &NeoWCChatTopGlassEffectMarkerKey,
                             @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIVisualEffectView *effectView = container.effectView;
    CGFloat blurIntensity = NeoWCChatGlassPercent(NeoWCChatGlassBlurIntensityKey,
                                                  100.0, 20.0, 100.0) / 100.0;
    NSInteger glassStyle = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCChatGlassStyleKey];
    if (glassStyle == 1) [container configurePseudoLiquidWithBlurIntensity:blurIntensity];
    else [container configureFrostedGlassWithBlurIntensity:blurIntensity];
    objc_setAssociatedObject(effectView, &NeoWCChatTopGlassEffectMarkerKey,
                             @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (contentViewOut) *contentViewOut = container.contentView;
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

    UIView *content = nil;
    UIView *container = NeoWCChatTopGlassContainer(capsuleHeight / 2.0, &content);

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
    NeoWCExcludeHeadViewFromGlobalAvatarRounding(avatarSource);
    NeoWCChatTopAvatarHostView *avatar = [[NeoWCChatTopAvatarHostView alloc]
        initWithSourceView:avatarSource];
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
    UILongPressGestureRecognizer *confirmationGesture = [[UILongPressGestureRecognizer alloc]
        initWithTarget:controller action:@selector(neowc_toggleSendConfirmation:)];
    confirmationGesture.minimumPressDuration = 0.55;
    [container addGestureRecognizer:confirmationGesture];
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

static id NeoWCOfficialChatSearchHost(BaseMsgContentViewController *controller) {
    if (!controller) return nil;
    UINavigationController *navigationController = controller.navigationController;
    return (!navigationController || navigationController.topViewController == controller)
        ? controller : nil;
}

static id NeoWCNativeChatSearchHelper(BaseMsgContentViewController *controller,
                                      BOOL createIfMissing) {
    if (!controller) return nil;
    id helper = NeoWCTweakSafeValue(controller, @"m_oMsgSearchHelper");
    if (!helper) helper = NeoWCExactIvarValue(controller, @"m_oMsgSearchHelper");
    if (helper || !createIfMissing) return helper;

    SEL selector = NSSelectorFromString(@"initMsgSearchHelper:");
    Method method = class_getInstanceMethod([controller class], selector);
    if (![controller respondsToSelector:selector] ||
        method_getNumberOfArguments(method) != 3 ||
        !NeoWCMethodArgumentIsIntegerScalar(method, 2)) return nil;
    @try {
        ((void (*)(id, SEL, NSUInteger))objc_msgSend)(controller, selector, (NSUInteger)0);
    } @catch (__unused NSException *exception) {
        return nil;
    }
    helper = NeoWCTweakSafeValue(controller, @"m_oMsgSearchHelper");
    return helper ?: NeoWCExactIvarValue(controller, @"m_oMsgSearchHelper");
}

static id NeoWCNativeChatSearcher(id helper) {
    if (!helper) return nil;
    id searcher = NeoWCTweakSafeValue(helper, @"searcher");
    if (!searcher) {
        SEL selector = NSSelectorFromString(@"getSearcher");
        if ([helper respondsToSelector:selector]) {
            searcher = ((id (*)(id, SEL))objc_msgSend)(helper, selector);
        }
    }
    return searcher ?: NeoWCExactIvarValue(helper, @"_searcher");
}

static void NeoWCSetChatSearchInteractivePop(BaseMsgContentViewController *controller,
                                             BOOL enabled) {
    SEL selector = NSSelectorFromString(@"setM_bInteractivePopEnabled:");
    Method method = class_getInstanceMethod([controller class], selector);
    if (![controller respondsToSelector:selector] ||
        method_getNumberOfArguments(method) != 3 ||
        !NeoWCMethodArgumentIsIntegerScalar(method, 2)) return;
    ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, selector, enabled);
}

static void NeoWCRemoveChatSearchEdgePan(BaseMsgContentViewController *controller) {
    UIGestureRecognizer *recognizer = objc_getAssociatedObject(controller, &NeoWCChatSearchEdgePanKey);
    if (recognizer.view) [recognizer.view removeGestureRecognizer:recognizer];
    objc_setAssociatedObject(controller, &NeoWCChatSearchEdgePanKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void NeoWCCleanupOfficialChatSearch(BaseMsgContentViewController *controller) {
    if (!controller || ![objc_getAssociatedObject(controller, &NeoWCChatSearchActiveKey) boolValue] ||
        [objc_getAssociatedObject(controller, &NeoWCChatSearchCleanupKey) boolValue]) return;
    objc_setAssociatedObject(controller, &NeoWCChatSearchCleanupKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCRemoveChatSearchEdgePan(controller);

    id helper = NeoWCNativeChatSearchHelper(controller, NO);
    id searcher = NeoWCNativeChatSearcher(helper);
    UIView *searchBar = NeoWCTweakSafeValue(searcher, @"searchBar");
    if ([searchBar isKindOfClass:UIView.class]) searchBar.superview.hidden = YES;
    SEL finishSelector = NSSelectorFromString(@"finishSearch");
    if ([helper respondsToSelector:finishSelector]) {
        @try {
            ((void (*)(id, SEL))objc_msgSend)(helper, finishSelector);
        } @catch (__unused NSException *exception) {
        }
    }
    NeoWCSetChatSearchInteractivePop(controller, YES);
    objc_setAssociatedObject(controller, &NeoWCChatSearchTransitionKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(controller, &NeoWCChatSearchActiveKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(controller, &NeoWCChatSearchCleanupKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static BOOL NeoWCOpenOfficialChatSearch(BaseMsgContentViewController *controller, id sender) {
    (void)sender;
    id searchHost = NeoWCOfficialChatSearchHost(controller);
    if (!searchHost) return NO;

    // WCRefine reuses WeChat's controller-owned helper. Creating and retaining
    // another helper leaves two independent delegate/dismiss lifecycles and is
    // the source of the stale search bar and cancel-time crash.
    id helper = NeoWCNativeChatSearchHelper(searchHost, YES);
    if (!helper) return NO;
    SEL panCancelSelector = NSSelectorFromString(@"setBUsePanCancelGesture:");
    if ([helper respondsToSelector:panCancelSelector]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(helper, panCancelSelector, YES);
    }
    id searcher = NeoWCNativeChatSearcher(helper);

    SEL pushSelector = NSSelectorFromString(@"pushSearchControllerWithCompletion:");
    SEL activeSelector = NSSelectorFromString(@"setActive:animated:completion:");
    if (![searcher respondsToSelector:pushSelector] &&
        ![searcher respondsToSelector:activeSelector]) return NO;
    if (objc_getAssociatedObject(controller, &NeoWCChatTopOriginalLeftItemsKey)) {
        objc_setAssociatedObject(controller, &NeoWCChatSearchTransitionKey,
                                 @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NeoWCRestoreChatTopBar(controller);
    }
    NeoWCSetChatSearchInteractivePop(controller, NO);
    objc_setAssociatedObject(controller, &NeoWCChatSearchActiveKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIScreenEdgePanGestureRecognizer *edgePan = [[UIScreenEdgePanGestureRecognizer alloc]
        initWithTarget:controller action:@selector(neowc_handleChatSearchEdgePan:)];
    edgePan.edges = UIRectEdgeLeft;
    [controller.view addGestureRecognizer:edgePan];
    objc_setAssociatedObject(controller, &NeoWCChatSearchEdgePanKey, edgePan,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    @try {
        if ([searcher respondsToSelector:pushSelector]) {
            ((void (*)(id, SEL, id))objc_msgSend)(searcher, pushSelector, nil);
        } else {
            ((void (*)(id, SEL, BOOL, BOOL, id))objc_msgSend)(searcher, activeSelector,
                                                             YES, NO, nil);
        }
    } @catch (__unused NSException *exception) {
        NeoWCCleanupOfficialChatSearch(controller);
        return NO;
    }
    return YES;
}

static UIImage *NeoWCChatSearchImage(void) {
    UIImage *image = [UIImage imageNamed:@"icons_outlined_search"];
    return image ?: [UIImage systemImageNamed:@"magnifyingglass"];
}

static UIImage *NeoWCChatCapsuleSearchImage(void) {
    UIImage *image = NeoWCChatSearchImage();
    if (!image) return nil;
    CGSize size = CGSizeMake(18.0, 18.0);
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    UIImage *resized = [renderer imageWithActions:^(__unused UIGraphicsImageRendererContext *context) {
        [image drawInRect:(CGRect){CGPointZero, size}];
    }];
    return [resized imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static UIBarButtonItem *NeoWCOfficialChatSearchBarButton(BaseMsgContentViewController *controller) {
    Class utilityClass = NSClassFromString(@"MMUICommonUtil");
    SEL factorySelector = NSSelectorFromString(@"getBarButtonWithImageName:target:action:style:accessibility:");
    Method factoryMethod = utilityClass ? class_getClassMethod(utilityClass, factorySelector) : NULL;
    if (factoryMethod && method_getNumberOfArguments(factoryMethod) == 7 &&
        NeoWCMethodReturnsObject(factoryMethod) &&
        NeoWCMethodArgumentIsObject(factoryMethod, 2) &&
        NeoWCMethodArgumentIsObject(factoryMethod, 3) &&
        NeoWCMethodArgumentIsSelector(factoryMethod, 4) &&
        NeoWCMethodArgumentIsIntegerScalar(factoryMethod, 5) &&
        NeoWCMethodArgumentIsObject(factoryMethod, 6)) {
        id item = ((id (*)(id, SEL, id, id, SEL, NSInteger, id))objc_msgSend)(
            utilityClass, factorySelector, @"icons_outlined_search", controller,
            @selector(neowc_openChatSearch:), 2, @"search");
        if ([item isKindOfClass:[UIBarButtonItem class]]) return item;
    }
    return [[UIBarButtonItem alloc] initWithImage:NeoWCChatSearchImage()
                                            style:UIBarButtonItemStylePlain
                                           target:controller
                                           action:@selector(neowc_openChatSearch:)];
}

static UIBarButtonItem *NeoWCChatTopCapsuleItem(BaseMsgContentViewController *controller,
                                                UIBarButtonItem *moreItem) {
    if (!moreItem) return nil;
    UIView *content = nil;
    CGFloat capsuleHeight = MAX(36.0, NeoWCChatTopLeftCapsuleHeight() - 2.0);
    UIView *capsule = NeoWCChatTopGlassContainer(capsuleHeight / 2.0, &content);

    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentFill;
    stack.distribution = UIStackViewDistributionFillEqually;
    [content addSubview:stack];

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
    BOOL includesSearch = NeoWCEnhancementEnabled(NeoWCChatSearchButtonEnabledKey);
    if (includesSearch) {
        UIButton *search = NeoWCChatTopCapsuleButton(NeoWCChatCapsuleSearchImage(), @"搜索聊天记录");
        [search addTarget:controller action:@selector(neowc_openChatSearch:) forControlEvents:UIControlEventTouchUpInside];
        [stack addArrangedSubview:search];
    }
    [stack addArrangedSubview:more];
    [NSLayoutConstraint activateConstraints:@[
        [capsule.widthAnchor constraintEqualToConstant:includesSearch ? 76.0 : 40.0],
        [capsule.heightAnchor constraintEqualToConstant:capsuleHeight],
        [stack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:content.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:content.bottomAnchor],
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

static void NeoWCApplyChatNavigationBackgroundWithNavigation(BaseMsgContentViewController *controller,
                                                              UINavigationController *navigationController,
                                                              BOOL hidden) {
    NeoWCSetChatContentNavigationBackgroundTransparent(controller, hidden);
    UINavigationBar *navigationBar = navigationController.navigationBar;
    NeoWCSetChatNavigationHostTransparent(navigationBar, hidden);
    NeoWCSetChatNavigationHostTransparent(navigationBar.superview, hidden);
    NeoWCSetChatNavigationBackgroundHidden(navigationBar, hidden);
    NeoWCSetChatNavigationDirectBackgroundsHidden(navigationBar, hidden);
    UIView *navigationRoot = navigationController.view;
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

static void NeoWCApplyChatNavigationBackground(BaseMsgContentViewController *controller, BOOL hidden) {
    NeoWCApplyChatNavigationBackgroundWithNavigation(controller,
                                                     controller.navigationController,
                                                     hidden);
}

static void NeoWCRestoreChatNavigationPresentationWithNavigation(BaseMsgContentViewController *controller,
                                                                  UINavigationController *navigationController) {
    UINavigationBar *navigationBar = navigationController.navigationBar;
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
    NeoWCApplyChatNavigationBackgroundWithNavigation(controller, navigationController, NO);
}

static void NeoWCRestoreChatNavigationPresentation(BaseMsgContentViewController *controller) {
    NeoWCRestoreChatNavigationPresentationWithNavigation(controller,
                                                         controller.navigationController);
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

static void NeoWCRemoveStandaloneChatSearchButton(BaseMsgContentViewController *controller) {
    UIBarButtonItem *searchItem = objc_getAssociatedObject(controller, &NeoWCChatSearchItemKey);
    if (!searchItem) return;
    NSMutableArray *rightItems = [controller.navigationItem.rightBarButtonItems mutableCopy] ?: [NSMutableArray array];
    [rightItems removeObjectIdenticalTo:searchItem];
    controller.navigationItem.rightBarButtonItems = rightItems;
    objc_setAssociatedObject(controller, &NeoWCChatSearchItemKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void NeoWCUpdateStandaloneChatSearchButton(BaseMsgContentViewController *controller) {
    if (!NeoWCEnhancementEnabled(NeoWCChatSearchButtonEnabledKey)) {
        NeoWCRemoveStandaloneChatSearchButton(controller);
        return;
    }
    UIBarButtonItem *installed = objc_getAssociatedObject(controller, &NeoWCChatSearchItemKey);
    NSArray *currentItems = controller.navigationItem.rightBarButtonItems ?: @[];
    if (installed && [currentItems containsObject:installed]) return;

    NSMutableArray *rightItems = [currentItems mutableCopy] ?: [NSMutableArray array];
    if (installed) [rightItems removeObjectIdenticalTo:installed];
    UIBarButtonItem *searchItem = NeoWCOfficialChatSearchBarButton(controller);
    if (!searchItem) return;
    [rightItems addObject:searchItem];
    controller.navigationItem.rightBarButtonItems = rightItems;
    objc_setAssociatedObject(controller, &NeoWCChatSearchItemKey,
                             searchItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        NeoWCUpdateStandaloneChatSearchButton(controller);
        return;
    }
    NeoWCRemoveStandaloneChatSearchButton(controller);
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
    if (!NeoWCEnhancementEnabled(NeoWCChatTopBarCapsuleEnabledKey)) {
        NeoWCUpdateStandaloneChatSearchButton(controller);
        return;
    }
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
                                                            UIView *glassView,
                                                            BOOL clear) {
    if (!view || view == glassView || [view isDescendantOfView:glassView]) return;
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
        NeoWCSetPinnedMessageDescendantBackgroundsClear(subview, glassView, clear);
    }
}

static void NeoWCUpdatePinnedMessageGlass(UIView *tipsView) {
    if (!tipsView) return;
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCChatTopBarCapsuleEnabledKey);
    NeoWCGlassCapsuleView *glassView = objc_getAssociatedObject(tipsView, &NeoWCChatPinnedBlurViewKey);
    if (!enabled) {
        NeoWCSetPinnedMessageDescendantBackgroundsClear(tipsView, glassView, NO);
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
        [glassView removeFromSuperview];
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

    if (!glassView) {
        glassView = [NeoWCGlassCapsuleView new];
        glassView.userInteractionEnabled = NO;
        glassView.capsuleCornerRadius = 14.0;
        objc_setAssociatedObject(glassView, &NeoWCChatTopGlassEffectMarkerKey,
                                 @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(tipsView, &NeoWCChatPinnedBlurViewKey,
                                 glassView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CGFloat blurIntensity = NeoWCChatGlassPercent(NeoWCChatGlassBlurIntensityKey,
                                                  100.0, 20.0, 100.0) / 100.0;
    NSInteger glassStyle = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCChatGlassStyleKey];
    if (glassStyle == 1) [glassView configurePseudoLiquidWithBlurIntensity:blurIntensity];
    else [glassView configureFrostedGlassWithBlurIntensity:blurIntensity];
    glassView.frame = CGRectInset(tipsView.bounds, 8.0, 0.0);
    glassView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (glassView.superview != tipsView) {
        [tipsView insertSubview:glassView atIndex:0];
    } else {
        [tipsView sendSubviewToBack:glassView];
    }
    NeoWCSetPinnedMessageDescendantBackgroundsClear(tipsView, glassView, YES);
}

static char NeoWCRawContactIDKey;
static char NeoWCProfileContactKey;
static char NeoWCProfileIsGroupKey;
static char NeoWCProfileChatRoomKey;
static char NeoWCRawContactIDCellMarkerKey;
static char NeoWCProfileMessageBlockCellMarkerKey;
static char NeoWCProfileSendConfirmationCellMarkerKey;

static NSUInteger NeoWCCallUnsignedSelector(id object, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!object || ![object respondsToSelector:selector]) return 0;
    @try {
        return ((NSUInteger (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        return 0;
    }
}

static id NeoWCRawProfileValue(id object, NSArray<NSString *> *names) {
    if (!object) return nil;
    id value = NeoWCTweakValueForSelectorNames(object, names);
    if (value) return value;
    for (NSString *name in names) {
        value = NeoWCTweakSafeValue(object, name);
        if (value) return value;
    }
    return nil;
}

static NSArray *NeoWCTableSections(id tableInfo) {
    if ([tableInfo isKindOfClass:NSArray.class]) return tableInfo;
    id sections = NeoWCRawProfileValue(tableInfo,
                                       @[@"sections", @"m_arrSections", @"sectionArray", @"allSections"]);
    return [sections isKindOfClass:NSArray.class] ? sections : nil;
}

static id NeoWCTableSectionAtIndex(id tableInfo, NSUInteger index) {
    for (NSString *name in @[@"getSectionAt:", @"sectionAtIndex:"]) {
        SEL selector = NSSelectorFromString(name);
        if (!tableInfo || ![tableInfo respondsToSelector:selector]) continue;
        @try {
            id section = ((id (*)(id, SEL, NSUInteger))objc_msgSend)(tableInfo, selector, index);
            if (section) return section;
        } @catch (__unused NSException *exception) {
        }
    }
    NSArray *sections = NeoWCTableSections(tableInfo);
    return index < sections.count ? sections[index] : nil;
}

static NSArray *NeoWCTableCells(id section) {
    id cells = NeoWCRawProfileValue(section,
                                    @[@"getAllCells", @"cells", @"m_arrCells", @"cellArray", @"allCells"]);
    return [cells isKindOfClass:NSArray.class] ? cells : nil;
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
    NSArray *cells = NeoWCTableCells(section);
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
    NSArray *cells = NeoWCTableCells(section);
    return [cells isKindOfClass:NSArray.class] ? cells.count : 0;
}

static NSString *NeoWCTableCellTitle(id cell) {
    id title = NeoWCRawProfileValue(cell, @[@"title", @"m_title", @"leftTitle", @"text"]);
    if ([title isKindOfClass:NSString.class]) return title;
    UILabel *label = NeoWCRawProfileValue(cell, @[@"titleLabel", @"m_titleLabel", @"leftLabel"]);
    if ([label isKindOfClass:UILabel.class]) return label.text;

    // Newer WeChat table cells keep their visible title in
    // cellConfig.leftConfig.title instead of exposing it on the cell itself.
    id cellConfig = NeoWCRawProfileValue(cell, @[@"cellConfig", @"m_cellConfig"]);
    id leftConfig = NeoWCRawProfileValue(cellConfig, @[@"leftConfig", @"m_leftConfig"]);
    title = NeoWCRawProfileValue(leftConfig, @[@"title", @"text"]);
    return [title isKindOfClass:NSString.class] ? title : nil;
}

static void NeoWCCollectLabels(UIView *view, NSMutableArray<UILabel *> *labels) {
    if ([view isKindOfClass:UILabel.class] && [(UILabel *)view text].length > 0) {
        [labels addObject:(UILabel *)view];
    }
    for (UIView *subview in view.subviews) NeoWCCollectLabels(subview, labels);
}

static NSString *NeoWCTableCellLeftmostText(id cell) {
    if (![cell isKindOfClass:UIView.class]) return nil;
    NSMutableArray<UILabel *> *labels = [NSMutableArray array];
    NeoWCCollectLabels(cell, labels);
    UILabel *leftmost = nil;
    for (UILabel *label in labels) {
        if (!leftmost || CGRectGetMinX(label.frame) < CGRectGetMinX(leftmost.frame)) leftmost = label;
    }
    return leftmost.text;
}

static NSString *NeoWCTableCellRightText(id cell, NSString *title) {
    for (NSString *name in @[@"rightValue", @"m_rightValue", @"detail", @"value", @"rightText"]) {
        id value = NeoWCRawProfileValue(cell, @[name]);
        if ([value isKindOfClass:NSString.class] && [value length] > 0 && ![value isEqualToString:title]) return value;
    }
    for (NSString *name in @[@"detailTextLabel", @"rightLabel", @"m_rightLabel", @"valueLabel"]) {
        UILabel *label = NeoWCRawProfileValue(cell, @[name]);
        if ([label isKindOfClass:UILabel.class] && label.text.length > 0 && ![label.text isEqualToString:title]) return label.text;
    }
    id cellConfig = NeoWCRawProfileValue(cell, @[@"cellConfig", @"m_cellConfig"]);
    id rightConfig = NeoWCRawProfileValue(cellConfig, @[@"rightConfig", @"m_rightConfig"]);
    id configured = NeoWCRawProfileValue(rightConfig, @[@"title", @"text", @"value"]);
    if ([configured isKindOfClass:NSString.class] && [configured length] > 0 && ![configured isEqualToString:title]) return configured;
    if ([cell isKindOfClass:UIView.class]) {
        NSMutableArray<UILabel *> *labels = [NSMutableArray array];
        NeoWCCollectLabels(cell, labels);
        UILabel *rightmost = nil;
        for (UILabel *label in labels) {
            if ([label.text isEqualToString:title]) continue;
            if (!rightmost || CGRectGetMinX(label.frame) > CGRectGetMinX(rightmost.frame)) rightmost = label;
        }
        if (rightmost.text.length > 0) return rightmost.text;
    }
    return nil;
}

static NSString *NeoWCAdditionDaysValue(NSString *title, NSString *value) {
    if (![title containsString:@"添加时间"] || value.length == 0) return nil;
    NSArray<NSDictionary *> *formats = @[
        @{ @"format": @"yyyy年M月d日 HH:mm:ss", @"approximate": @NO },
        @{ @"format": @"yyyy年M月d日 HH:mm", @"approximate": @NO },
        @{ @"format": @"yyyy年M月d日", @"approximate": @NO },
        @{ @"format": @"yyyy-MM-dd HH:mm:ss", @"approximate": @NO },
        @{ @"format": @"yyyy-MM-dd HH:mm", @"approximate": @NO },
        @{ @"format": @"yyyy-MM-dd", @"approximate": @NO },
        @{ @"format": @"yyyy/MM/dd HH:mm:ss", @"approximate": @NO },
        @{ @"format": @"yyyy/MM/dd HH:mm", @"approximate": @NO },
        @{ @"format": @"yyyy/MM/dd", @"approximate": @NO },
        @{ @"format": @"yyyy年M月", @"approximate": @YES },
        @{ @"format": @"yyyy-MM", @"approximate": @YES },
        @{ @"format": @"yyyy/MM", @"approximate": @YES },
    ];
    NSDate *date = nil;
    BOOL approximate = NO;
    for (NSDictionary *entry in formats) {
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        formatter.timeZone = NSTimeZone.localTimeZone;
        formatter.dateFormat = entry[@"format"];
        formatter.lenient = NO;
        date = [formatter dateFromString:value];
        if (date) {
            approximate = [entry[@"approximate"] boolValue];
            break;
        }
    }
    if (!date) return nil;
    NSCalendar *calendar = NSCalendar.currentCalendar;
    if (approximate) date = [calendar dateByAddingUnit:NSCalendarUnitDay value:14 toDate:date options:0] ?: date;
    NSDate *start = [calendar startOfDayForDate:date];
    NSDate *today = [calendar startOfDayForDate:NSDate.date];
    NSInteger days = [calendar components:NSCalendarUnitDay fromDate:start toDate:today options:0].day;
    if (days < 0) return nil;
    return [NSString stringWithFormat:@"%@%ld 天", approximate ? @"约 " : @"", (long)days];
}

static uint32_t NeoWCContactAddTime(id contact) {
    if (!contact) return 0;
    // WCPulse 1.7-2 hooks the official profile row and reads m_uiAddCreateTime.
    // Prefer that server-populated value; retain the local field only as a
    // compatibility fallback for host versions that do not expose it.
    for (NSString *name in @[@"m_uiAddCreateTime", @"m_uiLocalAddContactTime"]) {
        SEL selector = NSSelectorFromString(name);
        if (![contact respondsToSelector:selector]) continue;
        @try {
            uint32_t value = ((uint32_t (*)(id, SEL))objc_msgSend)(contact, selector);
            if (value > 0) return value;
        } @catch (__unused NSException *exception) {}
    }
    return 0;
}

static NSString *NeoWCContactAddTimeValue(id contact) {
    uint32_t timestamp = NeoWCContactAddTime(contact);
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    // The host getter is a 32-bit scalar. Only render values that are valid
    // Unix seconds, so a future host format change degrades to an empty row.
    if (timestamp < 946684800U || timestamp > now + 24.0 * 60.0 * 60.0) return nil;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    formatter.timeZone = NSTimeZone.localTimeZone;
    formatter.dateFormat = @"yyyy年M月d日 HH:mm:ss";
    NSString *text = [formatter stringFromDate:date];
    return text;
}

static NSString *NeoWCContactAddDaysValue(id contact) {
    uint32_t timestamp = NeoWCContactAddTime(contact);
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    if (timestamp < 946684800U || timestamp > now + 24.0 * 60.0 * 60.0) return nil;
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSInteger days = [calendar components:NSCalendarUnitDay
                                  fromDate:[calendar startOfDayForDate:date]
                                    toDate:[calendar startOfDayForDate:NSDate.date]
                                   options:0].day;
    return days >= 0 ? [NSString stringWithFormat:@"%ld 天", (long)days] : nil;
}

static id NeoWCCallCompatibleObjectGetter(id object, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    Method method = object ? class_getInstanceMethod([object class], selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != 2 || !NeoWCMethodReturnsObject(method)) return nil;
    @try {
        return ((id (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static NSArray *NeoWCOfficialRelatedGroups(id controller) {
    id logic = NeoWCRawProfileValue(controller,
                                    @[@"m_relatedGroupLogic", @"relatedGroupLogic"]);
    if (!logic) logic = objc_getAssociatedObject(controller, &NeoWCOfficialRelatedGroupLogicKey);
    // WCPulse 1.7-2 reads ContactRelatedGroupLogic through this no-argument
    // object getter for non-friends. Fall back to the backing ivar for host
    // versions where the getter is unavailable.
    id officialGroups = NeoWCCallCompatibleObjectGetter(logic, @"getContactRelatedGroup");
    if ([officialGroups isKindOfClass:NSArray.class]) return officialGroups;
    if ([officialGroups isKindOfClass:NSSet.class]) return [officialGroups allObjects];
    id groups = NeoWCRawProfileValue(logic, @[@"_arrRelatedGroup"]);
    if ([groups isKindOfClass:NSArray.class]) return groups;
    if ([groups isKindOfClass:NSSet.class]) return [groups allObjects];
    if ([NeoWCRawProfileValue(logic, @[@"_bSearchDone"]) boolValue]) return @[];
    return nil;
}

static NSArray<NSDictionary<NSString *, NSString *> *> *NeoWCOfficialSocialInformationRows(id controller) {
    id tableInfo = NeoWCRawProfileValue(controller, @[@"m_tableViewInfo", @"tableViewInfo"]);
    NSUInteger sectionCount = NeoWCCallUnsignedSelector(tableInfo, @"getSectionCount");
    if (sectionCount == 0) sectionCount = NeoWCTableSections(tableInfo).count;
    NSMutableArray *rows = [NSMutableArray array];
    NSMutableSet *titles = [NSMutableSet set];
    for (NSUInteger sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++) {
        id section = NeoWCTableSectionAtIndex(tableInfo, sectionIndex);
        NSUInteger cellCount = NeoWCTableCellCount(section);
        for (NSUInteger cellIndex = 0; cellIndex < cellCount; cellIndex++) {
            id cell = NeoWCTableCellAtIndex(section, cellIndex);
            NSString *title = [NeoWCTableCellTitle(cell)
                stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (title.length == 0) {
                title = [NeoWCTableCellLeftmostText(cell)
                    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            }
            NSString *value = [NeoWCTableCellRightText(cell, title)
                stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (title.length == 0 || value.length == 0 || [titles containsObject:title]) continue;
            [titles addObject:title];
            [rows addObject:@{ @"title": title, @"value": value }];
            NSString *days = NeoWCAdditionDaysValue(title, value);
            if (days.length > 0 && ![titles containsObject:@"添加天数"]) {
                [titles addObject:@"添加天数"];
                [rows addObject:@{ @"title": @"添加天数", @"value": days }];
            }
        }
    }
    NSArray *relatedGroups = NeoWCOfficialRelatedGroups(controller);
    if (relatedGroups != nil && ![titles containsObject:@"共同群聊"]) {
        [rows addObject:@{ @"title": @"共同群聊",
                           @"value": [NSString stringWithFormat:@"%lu 个", (unsigned long)relatedGroups.count] }];
    }
    return rows;
}

static NSArray<NSDictionary<NSString *, NSString *> *> *NeoWCMergeInfoCardRows(NSArray *baseRows,
                                                                                NSArray *officialRows) {
    BOOL friendCard = NO;
    BOOL allowsCommonGroups = NO;
    for (NSDictionary *row in baseRows ?: @[]) {
        NSString *title = row[@"title"];
        if ([title isEqualToString:@"原始号码"]) friendCard = YES;
        if ([title isEqualToString:@"共同群聊"]) allowsCommonGroups = YES;
    }
    NSMutableArray *rows = [NSMutableArray array];
    NSMutableSet *titles = [NSMutableSet set];
    // The direct m_uiAddCreateTime rendering preserves seconds and must win
    // over a coarser native table value. Other official values still replace
    // locally computed placeholders when they arrive asynchronously.
    NSMutableArray *combined = [NSMutableArray array];
    for (NSDictionary *row in baseRows ?: @[]) {
        NSString *title = row[@"title"];
        if ([title isEqualToString:@"添加时间"] || [title isEqualToString:@"添加天数"]) {
            [combined addObject:row];
        }
    }
    [combined addObjectsFromArray:officialRows ?: @[]];
    [combined addObjectsFromArray:baseRows ?: @[]];
    for (NSDictionary *row in combined) {
        NSString *title = row[@"title"];
        NSString *value = row[@"value"];
        if (title.length == 0 || value.length == 0 || [titles containsObject:title]) continue;
        [titles addObject:title];
        [rows addObject:@{ @"title": title, @"value": value }];
    }
    if (friendCard) {
        NSArray<NSString *> *order = @[@"昵称", @"备注", @"微信号", @"原始号码",
                                       @"添加时间", @"添加天数", @"共同群聊"];
        NSMutableDictionary<NSString *, NSDictionary *> *rowsByTitle = [NSMutableDictionary dictionary];
        for (NSDictionary *row in rows) {
            NSString *title = row[@"title"];
            if ([order containsObject:title] && !rowsByTitle[title]) rowsByTitle[title] = row;
        }
        NSMutableArray *orderedRows = [NSMutableArray arrayWithCapacity:order.count];
        for (NSString *title in order) {
            if ([title isEqualToString:@"共同群聊"] && !allowsCommonGroups) continue;
            NSDictionary *row = rowsByTitle[title];
            if (row) [orderedRows addObject:row];
        }
        return orderedRows;
    }
    return rows;
}

static void NeoWCRefreshInfoCardFromOfficialController(id officialController) {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ NeoWCRefreshInfoCardFromOfficialController(officialController); });
        return;
    }
    NeoWCWeakObjectBox *box = objc_getAssociatedObject(officialController, &NeoWCOfficialInfoCardBoxKey);
    NeoWCContactInfoCardViewController *card = [box.object isKindOfClass:NeoWCContactInfoCardViewController.class]
        ? box.object : nil;
    NSArray *baseRows = objc_getAssociatedObject(officialController, &NeoWCOfficialInfoBaseRowsKey) ?: @[];
    if (card) {
        [card updateRows:NeoWCMergeInfoCardRows(baseRows,
            NeoWCOfficialSocialInformationRows(officialController))];
        id contact = objc_getAssociatedObject(officialController, &NeoWCProfileContactKey);
        NSString *username = NeoWCRawProfileValue(contact, @[@"m_nsUsrName", @"userName", @"username"]);
        NeoWCConfigureInfoCardDetailActions(card, contact, nil, username, officialController);
    }
}

static BOOL NeoWCSectionContainsRawIDCell(id section, NSString *title) {
    NSUInteger count = NeoWCTableCellCount(section);
    for (NSUInteger index = 0; index < count; index++) {
        id cell = NeoWCTableCellAtIndex(section, index);
        if ([objc_getAssociatedObject(cell, &NeoWCRawContactIDCellMarkerKey) boolValue]) return YES;
        NSString *marker = NeoWCTweakSafeValue(cell, @"userInfo");
        if ([marker isKindOfClass:NSString.class] && [marker hasPrefix:@"neowc_profile_raw_"]) return YES;
        NSString *cellTitle = NeoWCTableCellTitle(cell);
        if ([cellTitle isEqualToString:title] || [cellTitle isEqualToString:@"原始 ID"] ||
            [cellTitle isEqualToString:@"原始群号码"]) return YES;
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
                                                                                     @selector(neowc_openInfoCard),
                                                                                     target,
                                                                                     title,
                                                                                     @"查看",
                                                                                     NO);
    } else if ([cellClass respondsToSelector:basicFactory]) {
        cell = ((id (*)(id, SEL, SEL, id, NSString *, NSString *))objc_msgSend)(cellClass,
                                                                                basicFactory,
                                                                                @selector(neowc_openInfoCard),
                                                                                target,
                                                                                title,
                                                                                @"查看");
    }
    if (cell) {
        NeoWCTweakSetValue(cell, @"userInfo", @"neowc_profile_info_card_cell");
        SEL heightSelector = NSSelectorFromString(@"setFCellHeight:");
        if ([cell respondsToSelector:heightSelector]) {
            ((void (*)(id, SEL, CGFloat))objc_msgSend)(cell, heightSelector, 56.0);
        }
    }
    return cell;
}

static BOOL NeoWCInsertRawIDCell(id section, id cell, NSUInteger index) {
    if (!section || !cell) return NO;
    NSUInteger count = NeoWCTableCellCount(section);
    if (index == NSNotFound || index > count) index = count;
    SEL insertSelector = NSSelectorFromString(@"insertCell:At:");
    SEL addSelector = NSSelectorFromString(@"addCell:");
    if ([section respondsToSelector:insertSelector]) {
        ((void (*)(id, SEL, id, NSUInteger))objc_msgSend)(section, insertSelector, cell, index);
        return YES;
    }
    if ([section respondsToSelector:addSelector] && index == count) {
        ((void (*)(id, SEL, id))objc_msgSend)(section, addSelector, cell);
        return YES;
    }
    NSArray *cells = NeoWCTableCells(section);
    if ([cells isKindOfClass:NSMutableArray.class]) {
        [(NSMutableArray *)cells insertObject:cell atIndex:MIN(index, cells.count)];
        return YES;
    }
    return NO;
}

static BOOL NeoWCProfileSectionContainsMarker(id section, const void *markerKey, NSString *title) {
    NSUInteger count = NeoWCTableCellCount(section);
    for (NSUInteger index = 0; index < count; index++) {
        id cell = NeoWCTableCellAtIndex(section, index);
        if ([objc_getAssociatedObject(cell, markerKey) boolValue]) return YES;
        if ([[NeoWCTableCellTitle(cell) stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
             isEqualToString:title]) return YES;
    }
    return NO;
}

static id NeoWCCreateProfileSwitchCell(id target, SEL rowAction, SEL switchAction,
                                       NSString *title, BOOL enabled) {
    Class cellClass = NSClassFromString(@"WCTableViewCellManager");
    UISwitch *toggle = [UISwitch new];
    toggle.on = enabled;
    [toggle addTarget:target action:switchAction forControlEvents:UIControlEventValueChanged];
    SEL rightViewFactory = NSSelectorFromString(@"normalCellForSel:target:title:rightView:");
    if ([cellClass respondsToSelector:rightViewFactory]) {
        return ((id (*)(id, SEL, SEL, id, NSString *, UIView *))objc_msgSend)(cellClass,
                                                                              rightViewFactory,
                                                                              rowAction,
                                                                              rowAction ? target : nil,
                                                                              title,
                                                                              toggle);
    }
    return nil;
}

static id NeoWCProfileFeatureTargetSection(id tableInfo, NSUInteger *insertionIndex) {
    NSUInteger sectionCount = NeoWCCallUnsignedSelector(tableInfo, @"getSectionCount");
    if (sectionCount == 0) sectionCount = NeoWCTableSections(tableInfo).count;
    id bestSection = nil;
    NSInteger bestScore = NSIntegerMin;
    NSUInteger bestIndex = NSNotFound;
    for (NSUInteger sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++) {
        id section = NeoWCTableSectionAtIndex(tableInfo, sectionIndex);
        NSUInteger cellCount = NeoWCTableCellCount(section);
        NSInteger score = -((NSInteger)sectionIndex);
        NSUInteger index = cellCount;
        for (NSUInteger cellIndex = 0; cellIndex < cellCount; cellIndex++) {
            id cell = NeoWCTableCellAtIndex(section, cellIndex);
            NSString *title = NeoWCTableCellTitle(cell);
            if ([objc_getAssociatedObject(cell, &NeoWCRawContactIDCellMarkerKey) boolValue] ||
                [title isEqualToString:@"原始号码"] || [title isEqualToString:@"原始群号码"]) {
                score += 200;
                index = cellIndex + 1;
            } else if ([title containsString:@"微信号"] || [title containsString:@"群聊名称"]) {
                score += 100;
                index = cellIndex + 1;
            } else if ([title containsString:@"朋友资料"] || [title containsString:@"群聊"] ||
                       [title containsString:@"备注"]) {
                score += 30;
            }
        }
        if (!bestSection || score > bestScore) {
            bestSection = section;
            bestScore = score;
            bestIndex = index;
        }
    }
    if (insertionIndex) *insertionIndex = bestIndex;
    return bestSection;
}

static void NeoWCInjectProfileConversationSwitches(id controller, BOOL group) {
    if (!controller) return;
    NSArray<NSString *> *contactNames = group ?
        @[@"m_chatRoomContact", @"chatRoomContact", @"contact", @"m_contact"] :
        @[@"m_contact", @"contact", @"contactInfo", @"m_contactInfo"];
    id contact = NeoWCRawProfileValue(controller, contactNames);
    NSString *username = NeoWCRawProfileValue(contact, @[@"m_nsUsrName", @"userName", @"username"]);
    if (![username isKindOfClass:NSString.class] || username.length == 0) return;
    objc_setAssociatedObject(controller, &NeoWCRawContactIDKey, username, OBJC_ASSOCIATION_COPY_NONATOMIC);

    id tableInfo = NeoWCRawProfileValue(controller,
                                        @[@"m_tableViewInfo", @"tableViewInfo", @"m_tableViewMgr", @"tableViewMgr"]);
    NSUInteger insertionIndex = NSNotFound;
    id section = NeoWCProfileFeatureTargetSection(tableInfo, &insertionIndex);
    if (!section) return;

    BOOL showBlockSwitch = NeoWCEnhancementEnabled(NeoWCMessageBlockEnabledKey) &&
                           [NSUserDefaults.standardUserDefaults boolForKey:NeoWCMessageBlockProfileSwitchEnabledKey];
    BOOL showConfirmSwitch = NeoWCEnhancementEnabled(NeoWCSendConfirmationEnabledKey) &&
                             [NSUserDefaults.standardUserDefaults boolForKey:NeoWCSendConfirmationProfileSwitchEnabledKey];
    NSString *blockTitle = group ? @"屏蔽本群消息" : @"屏蔽此人消息";
    NSString *confirmTitle = group ? @"本群发送确认" : @"对其发送确认";
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL blocked = [defaults boolForKey:NeoWCMessageBlockEnabledKey] &&
                   NeoWCMessageBlockTypesForConversation(username).count > 0;
    if (showBlockSwitch && !NeoWCProfileSectionContainsMarker(section, &NeoWCProfileMessageBlockCellMarkerKey, blockTitle)) {
        id cell = NeoWCCreateProfileSwitchCell(controller,
                                               NULL,
                                               @selector(neowc_toggleProfileMessageBlock:),
                                               blockTitle, blocked);
        if (cell) {
            objc_setAssociatedObject(cell, &NeoWCProfileMessageBlockCellMarkerKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (NeoWCInsertRawIDCell(section, cell, insertionIndex)) insertionIndex++;
        }
    }
    if (showConfirmSwitch &&
        !NeoWCProfileSectionContainsMarker(section, &NeoWCProfileSendConfirmationCellMarkerKey, confirmTitle)) {
        id cell = NeoWCCreateProfileSwitchCell(controller, NULL,
                                               @selector(neowc_toggleProfileSendConfirmation:),
                                               confirmTitle, NeoWCSendConfirmationIsProtectedConversation(username));
        if (cell) {
            objc_setAssociatedObject(cell, &NeoWCProfileSendConfirmationCellMarkerKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            NeoWCInsertRawIDCell(section, cell, insertionIndex);
        }
    }
}

static void NeoWCSetProfileMessageBlocked(NSString *username, BOOL blocked) {
    NeoWCMessageBlockSetTypesForConversation(username, blocked ? @[@"all"] : @[]);
}

static void NeoWCConfigureInfoCardSwitches(NeoWCContactInfoCardViewController *card,
                                           NSString *username,
                                           BOOL group) {
    if (!card || username.length == 0) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL showBlock = NeoWCEnhancementEnabled(NeoWCMessageBlockEnabledKey) &&
                     [defaults boolForKey:NeoWCMessageBlockProfileSwitchEnabledKey];
    BOOL showConfirm = NeoWCEnhancementEnabled(NeoWCSendConfirmationEnabledKey) &&
                       [defaults boolForKey:NeoWCSendConfirmationProfileSwitchEnabledKey];
    NSString *capturedUserName = [username copy];
    if (showBlock) {
        BOOL blocked = NeoWCMessageBlockTypesForConversation(capturedUserName).count > 0;
        [card configureMessageBlockSwitchWithTitle:(group ? @"屏蔽本群消息" : @"屏蔽此人消息")
                                            enabled:blocked
                                            handler:^(BOOL enabled) {
            NeoWCSetProfileMessageBlocked(capturedUserName, enabled);
        }];
    }
    if (showConfirm) {
        BOOL protectedConversation = NeoWCSendConfirmationIsProtectedConversation(capturedUserName);
        [card configureSendConfirmationSwitchWithTitle:(group ? @"本群发送确认" : @"对其发送确认")
                                                  enabled:protectedConversation
                                                  handler:^(BOOL enabled) {
            NeoWCSendConfirmationSetProtected(capturedUserName, enabled);
        }];
    }
}

static UIViewController *NeoWCProfileOwnerViewController(id controller) {
    if ([controller isKindOfClass:UIViewController.class]) return controller;
    id candidate = NeoWCRawProfileValue(controller,
                                        @[@"m_contactInfoViewController", @"contactInfoViewController",
                                          @"m_viewController", @"viewController", @"delegate"]);
    if ([candidate isKindOfClass:UIViewController.class]) return candidate;
    id tableInfo = NeoWCRawProfileValue(controller,
                                        @[@"m_tableViewInfo", @"tableViewInfo", @"m_tableViewMgr", @"tableViewMgr"]);
    id tableView = NeoWCRawProfileValue(tableInfo, @[@"getTableView", @"tableView", @"m_tableView"]);
    UIResponder *responder = [tableView isKindOfClass:UIView.class] ? tableView : nil;
    while ((responder = responder.nextResponder)) {
        if ([responder isKindOfClass:UIViewController.class]) return (UIViewController *)responder;
    }
    return nil;
}

static void NeoWCAddInfoCardRow(NSMutableArray<NSDictionary<NSString *, NSString *> *> *rows,
                                NSString *title,
                                id value) {
    NSString *text = [value isKindOfClass:NSString.class]
        ? [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : nil;
    if (title.length > 0 && text.length > 0) [rows addObject:@{ @"title": title, @"value": text }];
}

static NSArray<NSString *> *NeoWCProfileStringList(id value) {
    if ([value isKindOfClass:NSString.class]) {
        NSMutableArray *items = [NSMutableArray array];
        for (NSString *part in [(NSString *)value componentsSeparatedByCharactersInSet:
                                [NSCharacterSet characterSetWithCharactersInString:@";,|"]]) {
            NSString *item = [part stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (item.length > 0) [items addObject:item];
        }
        return items;
    }
    if ([value conformsToProtocol:@protocol(NSFastEnumeration)]) {
        NSMutableArray *items = [NSMutableArray array];
        for (id item in value) if ([item isKindOfClass:NSString.class] && [item length] > 0) [items addObject:item];
        return items;
    }
    return @[];
}

static void NeoWCAddProfileMemberNamesFromValue(id value, NSMutableSet<NSString *> *names) {
    if (!value || !names) return;
    if ([value isKindOfClass:NSString.class]) {
        NSString *string = value;
        if ([string rangeOfString:@"<member" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            NSArray<NSString *> *patterns = @[
                @"(?is)<userId>\\s*(?:<!\\[CDATA\\[)?(.*?)(?:\\]\\]>)?\\s*</userId>",
                @"(?is)<username>\\s*(?:<!\\[CDATA\\[)?(.*?)(?:\\]\\]>)?\\s*</username>",
                @"(?is)<UserName>\\s*(?:<!\\[CDATA\\[)?(.*?)(?:\\]\\]>)?\\s*</UserName>",
                @"(?is)<member[^>]+(?:userId|username)=[\"']([^\"']+)[\"']"
            ];
            for (NSString *pattern in patterns) {
                NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
                for (NSTextCheckingResult *match in [expression matchesInString:string options:0
                                                                          range:NSMakeRange(0, string.length)]) {
                    if (match.numberOfRanges < 2) continue;
                    NSString *name = [[string substringWithRange:[match rangeAtIndex:1]]
                        stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
                    if (name.length > 0) [names addObject:name];
                }
            }
            return;
        }
        for (NSString *part in [(NSString *)value componentsSeparatedByCharactersInSet:
                                [NSCharacterSet characterSetWithCharactersInString:@";,|"]]) {
            NSString *name = [part stringByTrimmingCharactersInSet:
                               NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (name.length > 0) [names addObject:name];
        }
        return;
    }
    if (![value conformsToProtocol:@protocol(NSFastEnumeration)]) return;
    @try {
        for (id item in value) {
            NSString *name = [item isKindOfClass:NSString.class]
                ? [item stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
                : NeoWCRawProfileValue(item, @[@"m_nsUsrName", @"m_nsUserName", @"userName", @"username", @"wxid"]);
            if (name.length > 0) [names addObject:name];
        }
    } @catch (__unused NSException *exception) {}
}

static NSSet<NSString *> *NeoWCGroupMemberUserNames(id groupContact) {
    NSMutableSet<NSString *> *names = [NSMutableSet set];
    id directValue = NeoWCRawProfileValue(groupContact, @[@"m_nsChatRoomMemList"]);
    NeoWCAddProfileMemberNamesFromValue(directValue, names);
    id roomData = NeoWCRawProfileValue(groupContact, @[@"m_ChatRoomData"]);
    id nestedValue = NeoWCRawProfileValue(roomData, @[@"m_nsChatRoomMemList"]);
    NeoWCAddProfileMemberNamesFromValue(nestedValue, names);
    return (directValue || nestedValue) ? names : nil;
}

static NSArray *NeoWCProfileObjectCollection(id target, NSArray<NSString *> *selectorNames) {
    for (NSString *selectorName in selectorNames) {
        id value = NeoWCCallCompatibleObjectGetter(target, selectorName);
        if (!value || [value isKindOfClass:NSString.class] ||
            ![value conformsToProtocol:@protocol(NSFastEnumeration)]) continue;
        NSMutableArray *items = [NSMutableArray array];
        @try {
            for (id item in value) if (item) [items addObject:item];
        } @catch (__unused NSException *exception) {
            continue;
        }
        return items;
    }
    return nil;
}

static NSArray *NeoWCAllChatRoomContacts(void) {
    NSMutableArray *groups = [NSMutableArray array];
    NSMutableSet<NSString *> *groupNames = [NSMutableSet set];
    void (^appendGroup)(id) = ^(id contact) {
        if (!contact) return;
        NSString *name = NeoWCRawProfileValue(contact,
            @[@"m_nsUsrName", @"m_nsUserName", @"userName", @"username"]);
        if (name.length == 0 || [groupNames containsObject:name]) return;
        BOOL isChatRoom = [name hasSuffix:@"@chatroom"];
        SEL chatRoomSelector = NSSelectorFromString(@"isChatroom");
        Method chatRoomMethod = class_getInstanceMethod([contact class], chatRoomSelector);
        if (chatRoomMethod && method_getNumberOfArguments(chatRoomMethod) == 2) {
            char returnType[8] = {0};
            method_getReturnType(chatRoomMethod, returnType, sizeof(returnType));
            if (returnType[0] == 'B' || returnType[0] == 'c') {
                @try {
                    isChatRoom = ((BOOL (*)(id, SEL))objc_msgSend)(contact, chatRoomSelector);
                } @catch (__unused NSException *exception) {}
            }
        }
        if (!isChatRoom) return;
        [groupNames addObject:name];
        [groups addObject:contact];
    };

    // WCPulse 1.7-2 first walks MMNewSessionMgr.SessionNewArray. This is
    // important for non-friends because some active groups are absent from
    // ContactsDataLogic's cached chat-room collection.
    Class sessionManagerClass = objc_getClass("MMNewSessionMgr");
    id sessionManager = sessionManagerClass ? NeoWCServiceForClass(sessionManagerClass) : nil;
    NSArray *sessions = NeoWCProfileObjectCollection(sessionManager, @[@"SessionNewArray"]);
    for (id session in sessions ?: @[]) {
        NSString *name = NeoWCRawProfileValue(session,
            @[@"m_nsUserName", @"m_nsUsrName", @"userName", @"username"]);
        if (name.length == 0 || [groupNames containsObject:name]) continue;
        appendGroup(NeoWCContactForUserName(name));
    }

    Class contactManagerClass = objc_getClass("CContactMgr");
    id contactManager = contactManagerClass ? NeoWCServiceForClass(contactManagerClass) : nil;
    SEL contactListSelector = NSSelectorFromString(@"getContactList:contactType:");
    Method contactListMethod = contactManager
        ? class_getInstanceMethod([contactManager class], contactListSelector) : NULL;
    if (contactListMethod && method_getNumberOfArguments(contactListMethod) == 4 &&
        NeoWCMethodReturnsObject(contactListMethod) &&
        NeoWCMethodArgumentIsIntegerScalar(contactListMethod, 2) &&
        NeoWCMethodArgumentIsIntegerScalar(contactListMethod, 3)) {
        @try {
            id value = ((id (*)(id, SEL, NSInteger, NSInteger))objc_msgSend)(
                contactManager, contactListSelector, 1, 0);
            if ([value conformsToProtocol:@protocol(NSFastEnumeration)]) {
                for (id contact in value) appendGroup(contact);
            }
        } @catch (__unused NSException *exception) {}
    }

    // Retain the older source as a compatibility fallback and merge it rather
    // than returning early; WeChat versions differ in which cache is complete.
    Class dataLogicClass = objc_getClass("ContactsDataLogic");
    id dataLogic = dataLogicClass ? NeoWCServiceForClass(dataLogicClass) : nil;
    for (id contact in NeoWCProfileObjectCollection(dataLogic, @[@"getChatRoomContacts"]) ?: @[]) {
        appendGroup(contact);
    }
    return groups;
}

static BOOL NeoWCContactListMethodIsCompatible(id manager, SEL selector) {
    Method method = manager ? class_getInstanceMethod([manager class], selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != 3) return NO;
    char returnType[8] = {0};
    char argumentType[8] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    method_getArgumentType(method, 2, argumentType, sizeof(argumentType));
    return (returnType[0] == 'B' || returnType[0] == 'c') && argumentType[0] == '@';
}

static BOOL NeoWCIsUsernameInContactList(id manager, SEL selector, NSString *userName, BOOL *available) {
    if (available) *available = NO;
    if (!manager || userName.length == 0 || !NeoWCContactListMethodIsCompatible(manager, selector)) return NO;
    if (available) *available = YES;
    @try {
        return ((BOOL (*)(id, SEL, id))objc_msgSend)(manager, selector, userName);
    } @catch (__unused NSException *exception) {
        if (available) *available = NO;
        return NO;
    }
}

static NSInteger NeoWCGroupFriendCount(id groupContact) {
    NSSet<NSString *> *memberNames = NeoWCGroupMemberUserNames(groupContact);
    if (memberNames.count == 0) return -1;
    Class contactManagerClass = objc_getClass("CContactMgr");
    id contactManager = contactManagerClass ? NeoWCServiceForClass(contactManagerClass) : nil;
    SEL membershipSelector = NSSelectorFromString(@"isInContactList:");
    if (!NeoWCContactListMethodIsCompatible(contactManager, membershipSelector)) return -1;

    NSString *currentUserName = NeoWCCurrentUserWXID();
    NSInteger friendCount = 0;
    BOOL available = YES;
    for (NSString *memberName in memberNames) {
        if (currentUserName.length > 0 && [memberName isEqualToString:currentUserName]) continue;
        BOOL isFriend = NeoWCIsUsernameInContactList(contactManager, membershipSelector,
                                                     memberName, &available);
        if (!available) return -1;
        if (isFriend) friendCount++;
    }
    return friendCount;
}

static NSArray *NeoWCCommonGroupContacts(NSString *userName) {
    if (userName.length == 0 || [userName hasSuffix:@"@chatroom"]) return nil;
    NSArray *groups = NeoWCAllChatRoomContacts();
    if (!groups) return nil;
    NSMutableArray *matches = [NSMutableArray array];
    for (id groupContact in groups) {
        NSSet<NSString *> *memberNames = NeoWCGroupMemberUserNames(groupContact);
        if ([memberNames containsObject:userName]) [matches addObject:groupContact];
    }
    return matches;
}

static NSInteger NeoWCCommonGroupCount(NSString *userName) {
    NSArray *groups = NeoWCCommonGroupContacts(userName);
    return groups ? (NSInteger)groups.count : -1;
}

static NSArray *NeoWCGroupFriendContacts(id groupContact) {
    NSSet<NSString *> *memberNames = NeoWCGroupMemberUserNames(groupContact);
    if (memberNames.count == 0) return nil;
    Class contactManagerClass = objc_getClass("CContactMgr");
    id contactManager = contactManagerClass ? NeoWCServiceForClass(contactManagerClass) : nil;
    SEL membershipSelector = NSSelectorFromString(@"isInContactList:");
    if (!NeoWCContactListMethodIsCompatible(contactManager, membershipSelector)) return nil;
    NSString *currentUserName = NeoWCCurrentUserWXID();
    NSMutableArray *contacts = [NSMutableArray array];
    for (NSString *memberName in memberNames) {
        if ([memberName isEqualToString:currentUserName]) continue;
        BOOL available = NO;
        if (!NeoWCIsUsernameInContactList(contactManager, membershipSelector, memberName, &available)) {
            if (!available) return nil;
            continue;
        }
        id contact = NeoWCContactForUserName(memberName);
        if (contact) [contacts addObject:contact];
    }
    return contacts;
}

static NSArray<NSDictionary<NSString *, id> *> *NeoWCInfoListRowsForContacts(NSArray *contacts) {
    NSMutableArray<NSDictionary<NSString *, id> *> *rows = [NSMutableArray array];
    NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
    for (id contact in contacts) {
        NSString *userName = NeoWCRawProfileValue(contact, @[@"m_nsUsrName", @"userName", @"username"]);
        if (userName.length == 0 || [identifiers containsObject:userName]) continue;
        [identifiers addObject:userName];
        NSString *name = NeoWCAvatarDisplayName(contact, userName);
        NSMutableDictionary<NSString *, id> *row = [@{ @"title": name.length > 0 ? name : userName,
                                                        @"value": userName } mutableCopy];
        id imageValue = NeoWCRawProfileValue(contact, @[@"getContactHeadImage"]);
        if ([imageValue isKindOfClass:UIImage.class]) row[@"image"] = imageValue;
        [rows addObject:row];
    }
    [rows sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [left[@"title"] localizedCaseInsensitiveCompare:right[@"title"]];
    }];
    return rows;
}

static NSArray *NeoWCMergedContactCollections(NSArray *primary, NSArray *secondary) {
    NSMutableArray *merged = [NSMutableArray array];
    NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
    for (id contact in [(primary ?: @[]) arrayByAddingObjectsFromArray:secondary ?: @[]]) {
        NSString *userName = NeoWCRawProfileValue(contact, @[@"m_nsUsrName", @"userName", @"username"]);
        if (userName.length == 0 || [identifiers containsObject:userName]) continue;
        [identifiers addObject:userName];
        [merged addObject:contact];
    }
    return merged;
}

static void NeoWCConfigureInfoCardDetailActions(NeoWCContactInfoCardViewController *card,
                                                id contact,
                                                id groupContact,
                                                NSString *username,
                                                id officialController) {
    if (!card) return;
    id resolvedGroupContact = groupContact;
    NSString *contactUserName = NeoWCRawProfileValue(contact, @[@"m_nsUsrName", @"userName", @"username"]);
    if (!resolvedGroupContact && [contactUserName hasSuffix:@"@chatroom"]) resolvedGroupContact = contact;
    NSArray *friends = NeoWCGroupFriendContacts(resolvedGroupContact);
    NSArray *friendRows = NeoWCInfoListRowsForContacts(friends);
    if (friendRows.count > 0) {
        [card configureRowActionWithTitle:@"群内好友" handler:^(UIViewController *presenter) {
            NeoWCInfoListViewController *list = [[NeoWCInfoListViewController alloc]
                initWithTitle:@"群内好友" rows:friendRows];
            [list configureSelectionHandler:^(UIViewController *listPresenter, NSDictionary<NSString *,id> *row) {
                NSString *memberUserName = row[@"value"];
                id memberContact = NeoWCContactForUserName(memberUserName);
                if (memberContact) NeoWCOpenAvatarProfile(listPresenter, nil, memberContact);
                else NeoWCShowTransientMessage(@"未获取到好友资料", NO);
            }];
            [presenter.navigationController pushViewController:list animated:YES];
        }];
    }

    if (username.length == 0 || [username hasSuffix:@"@chatroom"]) return;
    NSArray *localGroups = NeoWCCommonGroupContacts(username);
    NSArray *officialGroups = officialController ? NeoWCOfficialRelatedGroups(officialController) : nil;
    NSArray *groups = NeoWCMergedContactCollections(localGroups, officialGroups);
    NSArray *groupRows = NeoWCInfoListRowsForContacts(groups);
    if (groupRows.count > 0) {
        [card configureRowActionWithTitle:@"共同群聊" handler:^(UIViewController *presenter) {
            NeoWCInfoListViewController *list = [[NeoWCInfoListViewController alloc]
                initWithTitle:@"共同群聊" rows:groupRows];
            [list configureSelectionHandler:^(__unused UIViewController *listPresenter,
                                               NSDictionary<NSString *,id> *row) {
                NSString *groupUserName = row[@"value"];
                if ([groupUserName hasSuffix:@"@chatroom"]) NeoWCOpenChatForUserName(groupUserName);
            }];
            [presenter.navigationController pushViewController:list animated:YES];
        }];
    }
}

static NSArray<NSDictionary<NSString *, NSString *> *> *NeoWCProfileInfoRows(id contact, BOOL group) {
    NSMutableArray *rows = [NSMutableArray array];
    NeoWCAddInfoCardRow(rows, group ? @"原始群号码" : @"原始号码",
                       NeoWCRawProfileValue(contact, @[@"m_nsUsrName", @"userName", @"username"]));
    if (group) {
        NeoWCAddInfoCardRow(rows, @"群聊名称",
                           NeoWCRawProfileValue(contact, @[@"getContactDisplayName", @"m_nsNickName"]));
        NSSet<NSString *> *memberNames = NeoWCGroupMemberUserNames(contact);
        if (memberNames.count > 0) NeoWCAddInfoCardRow(rows, @"群成员",
                                                        [NSString stringWithFormat:@"%lu 人",
                                                         (unsigned long)memberNames.count]);
        NSInteger friendCount = NeoWCGroupFriendCount(contact);
        if (friendCount >= 0) NeoWCAddInfoCardRow(rows, @"群内好友",
                                                   [NSString stringWithFormat:@"%ld 人", (long)friendCount]);
        NeoWCAddInfoCardRow(rows, @"群主", NeoWCRawProfileValue(contact,
            @[@"m_nsChatRoomOwner", @"m_nsOwner", @"ownerUserName", @"owner"]));
        NSArray *admins = NeoWCProfileStringList(NeoWCRawProfileValue(contact,
            @[@"m_nsChatRoomAdminList", @"m_nsAdminList", @"m_adminList", @"adminList", @"admins", @"m_arrAdmin"]));
        if (admins.count > 0) NeoWCAddInfoCardRow(rows, @"管理员", [admins componentsJoinedByString:@"、"]);
        NeoWCAddInfoCardRow(rows, @"群简介", NeoWCRawProfileValue(contact, @[@"groupSummary"]));
        NeoWCAddInfoCardRow(rows, @"群链接", NeoWCRawProfileValue(contact, @[@"groupURL"]));
    } else {
        NeoWCAddInfoCardRow(rows, @"昵称", NeoWCRawProfileValue(contact, @[@"m_nsNickName"]));
        NeoWCAddInfoCardRow(rows, @"备注", NeoWCRawProfileValue(contact, @[@"m_nsRemark"]));
        NeoWCAddInfoCardRow(rows, @"微信号", NeoWCRawProfileValue(contact, @[@"m_nsAliasName", @"m_nsAlias"]));
        NeoWCAddInfoCardRow(rows, @"添加时间", NeoWCContactAddTimeValue(contact));
        NeoWCAddInfoCardRow(rows, @"添加天数", NeoWCContactAddDaysValue(contact));
        NSString *userName = NeoWCRawProfileValue(contact, @[@"m_nsUsrName", @"userName", @"username"]);
        // The native related-group search exits early for non-friends. Seed the
        // row from the WCPulse-compatible session/contact scan, then merge any
        // official result that becomes available asynchronously.
        NSInteger commonCount = NeoWCCommonGroupCount(userName);
        NeoWCAddInfoCardRow(rows, @"共同群聊", commonCount >= 0
            ? [NSString stringWithFormat:@"%ld 个", (long)commonCount]
            : @"正在加载");
    }
    return rows;
}

static UIViewController *NeoWCCreateOfficialSocialInformation(id contact) {
    if (!contact) return nil;
    Class controllerClass = NSClassFromString(@"SocialInfomationViewController");
    SEL setter = NSSelectorFromString(@"setM_contact:");
    UIViewController *controller = controllerClass ? [[controllerClass alloc] init] : nil;
    if (!controller || ![controller respondsToSelector:setter]) {
        return nil;
    }
    ((void (*)(id, SEL, id))objc_msgSend)(controller, setter, contact);
    NSString *rawID = NeoWCRawProfileValue(contact, @[@"m_nsUsrName", @"userName", @"username"]);
    objc_setAssociatedObject(controller, &NeoWCProfileContactKey, contact, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(controller, &NeoWCProfileIsGroupKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(controller, &NeoWCRawContactIDKey, rawID, OBJC_ASSOCIATION_COPY_NONATOMIC);
    (void)controller.view;
    SEL reloadSelector = NSSelectorFromString(@"reloadTableView");
    if ([controller respondsToSelector:reloadSelector]) {
        ((void (*)(id, SEL))objc_msgSend)(controller, reloadSelector);
    }
    id relatedGroupLogic = NeoWCRawProfileValue(controller,
        @[@"m_relatedGroupLogic", @"relatedGroupLogic"]);
    if (!relatedGroupLogic) {
        Class logicClass = objc_getClass("ContactRelatedGroupLogic");
        SEL initializer = NSSelectorFromString(@"initWithContact:");
        Method initializerMethod = logicClass ? class_getInstanceMethod(logicClass, initializer) : NULL;
        if (initializerMethod && method_getNumberOfArguments(initializerMethod) == 3 &&
            NeoWCMethodReturnsObject(initializerMethod)) {
            @try {
                relatedGroupLogic = ((id (*)(id, SEL, id))objc_msgSend)([logicClass alloc], initializer, contact);
            } @catch (__unused NSException *exception) {
                relatedGroupLogic = nil;
            }
        }
        if (relatedGroupLogic) {
            objc_setAssociatedObject(controller, &NeoWCOfficialRelatedGroupLogicKey,
                                     relatedGroupLogic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    // AFN registers this exact no-argument selector on ContactRelatedGroupLogic
    // and its replacement preserves the original call before processing results.
    SEL searchSelector = NSSelectorFromString(@"trySearchRelatedGroup");
    Class logicClass = objc_getClass("ContactRelatedGroupLogic");
    Method searchMethod = logicClass ? class_getInstanceMethod(logicClass, searchSelector) : NULL;
    char returnType[8] = {0};
    if (searchMethod) method_getReturnType(searchMethod, returnType, sizeof(returnType));
    if (relatedGroupLogic && searchMethod && method_getNumberOfArguments(searchMethod) == 2 &&
        returnType[0] == 'v' && [relatedGroupLogic respondsToSelector:searchSelector]) {
        @try {
            ((void (*)(id, SEL))objc_msgSend)(relatedGroupLogic, searchSelector);
        } @catch (__unused NSException *exception) {}
        for (NSNumber *delay in @[@0.25, @0.75, @1.5, @3.0, @6.0, @10.0]) {
            __weak UIViewController *weakController = controller;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                UIViewController *strongController = weakController;
                if (strongController) NeoWCRefreshInfoCardFromOfficialController(strongController);
            });
        }
    }
    return controller;
}

static NSArray<NSDictionary<NSString *, NSString *> *> *NeoWCGroupMemberInfoRows(id contact,
                                                                                   id groupContact,
                                                                                   NSString *userName) {
    NSMutableArray *rows = [NSMutableArray array];
    SEL displaySelector = NSSelectorFromString(@"getChatRoomMemberDisplayName:");
    if (groupContact && contact && [groupContact respondsToSelector:displaySelector]) {
        @try {
            id value = ((id (*)(id, SEL, id))objc_msgSend)(groupContact, displaySelector, contact);
            NeoWCAddInfoCardRow(rows, @"群昵称", value);
        } @catch (__unused NSException *exception) {}
    }
    NSString *owner = NeoWCRawProfileValue(groupContact,
        @[@"m_nsChatRoomOwner", @"m_nsOwner", @"ownerUserName", @"owner"]);
    NSArray *admins = NeoWCProfileStringList(NeoWCRawProfileValue(groupContact,
        @[@"m_nsChatRoomAdminList", @"m_nsAdminList", @"m_adminList", @"adminList", @"admins", @"m_arrAdmin"]));
    NSString *role = [owner isEqualToString:userName] ? @"群主"
        : ([admins containsObject:userName] ? @"管理员" : @"群成员");
    NeoWCAddInfoCardRow(rows, @"群身份", role);
    NSInteger friendCount = NeoWCGroupFriendCount(groupContact);
    if (friendCount >= 0) NeoWCAddInfoCardRow(rows, @"群内好友",
                                               [NSString stringWithFormat:@"%ld 人", (long)friendCount]);
    return rows;
}

static NSString *NeoWCGroupMemberInviterUserName(id groupContact, id memberContact,
                                                  NSString *memberUserName) {
    id chatRoomData = NeoWCRawProfileValue(groupContact,
        @[@"m_ChatRoomData", @"m_chatRoomData", @"chatRoomData"]);
    SEL selector = NSSelectorFromString(@"getInviterNameForUsername:");
    Method method = chatRoomData ? class_getInstanceMethod([chatRoomData class], selector) : NULL;
    if (method && method_getNumberOfArguments(method) == 3 &&
        NeoWCMethodReturnsObject(method) && NeoWCMethodArgumentIsObject(method, 2)) {
        @try {
            id value = ((id (*)(id, SEL, id))objc_msgSend)(chatRoomData, selector, memberUserName);
            if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
        } @catch (__unused NSException *exception) {}
    }
    id fallback = NeoWCRawProfileValue(memberContact,
        @[@"m_InviteUserName", @"m_inviteUserName", @"inviteUserName", @"inviterUserName"]);
    return [fallback isKindOfClass:NSString.class] && [fallback length] > 0 ? fallback : nil;
}

static NSInteger NeoWCGroupMemberRemovalScene(id groupContact,
                                               id memberContact,
                                               NSString *memberUserName) {
    NSString *selfUserName = NeoWCCurrentUserWXID();
    NSString *groupUserName = NeoWCContactUserName(groupContact);
    if (!groupContact || !memberContact || ![groupUserName hasSuffix:@"@chatroom"] ||
        memberUserName.length == 0 || selfUserName.length == 0 ||
        [memberUserName isEqualToString:selfUserName]) return 0;

    Class groupManagerClass = NSClassFromString(@"CGroupMgr");
    id groupManager = groupManagerClass ? NeoWCServiceForClass(groupManagerClass) : nil;
    SEL groupGetter = NSSelectorFromString(@"getContactByName:");
    Method groupGetterMethod = groupManager ? class_getInstanceMethod([groupManager class], groupGetter) : NULL;
    id resolvedGroupContact = groupContact;
    if (groupGetterMethod && method_getNumberOfArguments(groupGetterMethod) == 3 &&
        NeoWCMethodReturnsObject(groupGetterMethod) &&
        NeoWCMethodArgumentIsObject(groupGetterMethod, 2)) {
        @try {
            id value = ((id (*)(id, SEL, id))objc_msgSend)(groupManager, groupGetter, groupUserName);
            if (value) resolvedGroupContact = value;
        } @catch (__unused NSException *exception) {}
    }

    BOOL memberListAvailable = NO;
    BOOL isCurrentMember = NO;
    SEL memberListSelector = NSSelectorFromString(@"GetGroupMemberUserListByContact:");
    Method memberListMethod = groupManager
        ? class_getInstanceMethod([groupManager class], memberListSelector) : NULL;
    if (memberListMethod && method_getNumberOfArguments(memberListMethod) == 3 &&
        NeoWCMethodReturnsObject(memberListMethod) &&
        NeoWCMethodArgumentIsObject(memberListMethod, 2)) {
        @try {
            id list = ((id (*)(id, SEL, id))objc_msgSend)(groupManager,
                memberListSelector, resolvedGroupContact);
            if ([list isKindOfClass:NSArray.class]) {
                memberListAvailable = [(NSArray *)list count] > 0;
                isCurrentMember = [(NSArray *)list containsObject:memberUserName];
            }
        } @catch (__unused NSException *exception) {}
    }
    if (!memberListAvailable) {
        isCurrentMember = [NeoWCGroupMemberUserNames(resolvedGroupContact) containsObject:memberUserName];
    }
    if (!isCurrentMember) return 0;

    NSString *owner = NeoWCRawProfileValue(resolvedGroupContact,
        @[@"m_nsOwner", @"m_nsChatRoomOwner", @"ownerUserName", @"owner"]);
    if ([memberUserName isEqualToString:owner]) return 0;
    if ([selfUserName isEqualToString:owner]) return 1;

    NSArray<NSString *> *admins = NeoWCProfileStringList(NeoWCRawProfileValue(resolvedGroupContact,
        @[@"m_nsChatRoomAdminList", @"m_nsAdminList", @"adminList", @"admins"]));
    if ([admins containsObject:selfUserName]) return 1;

    NSString *inviter = NeoWCGroupMemberInviterUserName(resolvedGroupContact,
                                                         memberContact,
                                                         memberUserName);
    return [inviter isEqualToString:selfUserName] ? 2 : 0;
}

static BOOL NeoWCMethodArgumentIsIntegerScalar(Method method, unsigned int index) {
    if (!method || index >= method_getNumberOfArguments(method)) return NO;
    char type[16] = {0};
    method_getArgumentType(method, index, type, sizeof(type));
    const char *cursor = type;
    while (*cursor == 'r' || *cursor == 'n' || *cursor == 'N' || *cursor == 'o' ||
           *cursor == 'O' || *cursor == 'R' || *cursor == 'V') cursor++;
    return strchr("cCsSiIlLqQB", *cursor) != NULL;
}

static void NeoWCConfirmRemoveGroupMember(UIViewController *presenter,
                                          id groupContact,
                                          id memberContact,
                                          NSString *memberUserName,
                                          NSInteger scene) {
    NSInteger currentScene = NeoWCGroupMemberRemovalScene(groupContact, memberContact, memberUserName);
    if (!presenter || currentScene <= 0) {
        NeoWCShowTransientMessage(@"当前无权移出该成员", NO);
        return;
    }
    scene = currentScene;
    NSString *groupUserName = NeoWCContactUserName(groupContact);
    NSString *displayName = NeoWCAvatarDisplayName(memberContact, memberUserName);
    NSString *message = [NSString stringWithFormat:@"确定将“%@”移出当前群聊？", displayName];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"移出群成员"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"移出" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        Class managerClass = NSClassFromString(@"CGroupMgr");
        id manager = managerClass ? NeoWCServiceForClass(managerClass) : nil;
        SEL selector = NSSelectorFromString(@"DeleteGroupMember:withMemberList:scene:");
        if (![manager respondsToSelector:selector]) {
            selector = NSSelectorFromString(@"p_DeleteGroupMember:withMemberList:scene:");
        }
        Method method = manager ? class_getInstanceMethod([manager class], selector) : NULL;
        char returnType[8] = {0};
        if (method) method_getReturnType(method, returnType, sizeof(returnType));
        if (!method || method_getNumberOfArguments(method) != 5 ||
            (returnType[0] != 'B' && returnType[0] != 'c') ||
            !NeoWCMethodArgumentIsObject(method, 2) ||
            !NeoWCMethodArgumentIsObject(method, 3) ||
            !NeoWCMethodArgumentIsIntegerScalar(method, 4)) {
            NeoWCShowTransientMessage(@"当前微信版本不支持移出成员", NO);
            return;
        }
        BOOL accepted = NO;
        @try {
            accepted = ((BOOL (*)(id, SEL, id, id, NSInteger))objc_msgSend)(manager,
                selector, groupUserName, @[memberUserName], scene);
        } @catch (NSException *exception) {
            NeoWCLog(@"移出群成员失败：%@", exception.reason ?: exception.name);
        }
        NeoWCShowTransientMessage(accepted ? @"已提交移出请求" : @"移出成员失败", accepted);
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static void NeoWCOpenProfileInfoCard(id controller) {
    id contact = objc_getAssociatedObject(controller, &NeoWCProfileContactKey);
    BOOL group = [objc_getAssociatedObject(controller, &NeoWCProfileIsGroupKey) boolValue];
    NSString *userName = NeoWCRawProfileValue(contact, @[@"m_nsUsrName", @"userName", @"username"]);
    if (userName.length == 0) userName = objc_getAssociatedObject(controller, &NeoWCRawContactIDKey);
    if (userName.length == 0) return;
    UIViewController *owner = NeoWCProfileOwnerViewController(controller);
    UIViewController *officialController = !group ? NeoWCCreateOfficialSocialInformation(contact) : nil;
    NSString *name = NeoWCRawProfileValue(contact, @[@"getContactDisplayName", @"m_nsRemark", @"m_nsNickName"]);
    id imageValue = NeoWCRawProfileValue(contact, @[@"getContactHeadImage"]);
    UIImage *avatar = [imageValue isKindOfClass:UIImage.class] ? imageValue : nil;
    NSString *chatRoomUserName = objc_getAssociatedObject(controller, &NeoWCProfileChatRoomKey);
    NSMutableArray *rows = [NeoWCProfileInfoRows(contact, group) mutableCopy];
    if (!group && [chatRoomUserName hasSuffix:@"@chatroom"]) {
        [rows addObject:@{ @"title": @"所在群聊", @"value": chatRoomUserName }];
        [rows addObjectsFromArray:NeoWCGroupMemberInfoRows(contact,
            NeoWCContactForUserName(chatRoomUserName), userName)];
    }
    NSArray *baseRows = [rows copy];
    NSArray *displayRows = NeoWCMergeInfoCardRows(baseRows,
        officialController ? NeoWCOfficialSocialInformationRows(officialController) : @[]);
    NeoWCContactInfoCardViewController *card = [[NeoWCContactInfoCardViewController alloc]
        initWithTitle:(!group && [chatRoomUserName hasSuffix:@"@chatroom"]) ? @"群成员详细信息" : @"详细信息"
               avatar:avatar
                 name:name ?: userName
             userName:userName
             rows:displayRows];
    if (officialController) {
        NeoWCWeakObjectBox *box = [NeoWCWeakObjectBox new];
        box.object = card;
        objc_setAssociatedObject(officialController, &NeoWCOfficialInfoCardBoxKey,
                                 box, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(officialController, &NeoWCOfficialInfoBaseRowsKey,
                                 baseRows, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(card, &NeoWCInfoCardOfficialControllerKey,
                                 officialController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NeoWCRefreshInfoCardFromOfficialController(officialController);
    }
    NeoWCConfigureInfoCardSwitches(card, userName, group);
    id detailGroupContact = group ? contact : ([chatRoomUserName hasSuffix:@"@chatroom"]
        ? NeoWCContactForUserName(chatRoomUserName) : nil);
    NeoWCConfigureInfoCardDetailActions(card, contact, detailGroupContact,
                                        userName, officialController);
    if (owner.navigationController) [owner.navigationController pushViewController:card animated:YES];
    else if (owner) [owner presentViewController:[[UINavigationController alloc] initWithRootViewController:card]
                                         animated:YES completion:nil];
}

static void NeoWCInjectRawIDCell(id controller, BOOL group) {
    if (!NeoWCEnhancementEnabled(NeoWCShowRawContactIDEnabledKey) || !controller) return;
    NSArray<NSString *> *contactNames = group ?
        @[@"m_chatRoomContact", @"chatRoomContact", @"contact", @"m_contact"] :
        @[@"m_contact", @"contact", @"contactInfo", @"m_contactInfo"];
    id contact = NeoWCRawProfileValue(controller, contactNames);
    NSString *rawID = NeoWCRawProfileValue(contact, @[@"m_nsUsrName", @"userName", @"username"]);
    if (![rawID isKindOfClass:NSString.class] || rawID.length == 0) return;

    id tableInfo = NeoWCRawProfileValue(controller,
                                        @[@"m_tableViewInfo", @"tableViewInfo", @"m_tableViewMgr", @"tableViewMgr"]);
    NSUInteger sectionCount = NeoWCCallUnsignedSelector(tableInfo, @"getSectionCount");
    if (sectionCount == 0) sectionCount = NeoWCTableSections(tableInfo).count;
    if (!tableInfo || sectionCount == 0) return;
    objc_setAssociatedObject(controller, &NeoWCProfileContactKey, contact, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(controller, &NeoWCProfileIsGroupKey, @(group), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSString *chatRoomUserName = group ? rawID : NeoWCRawProfileValue(controller,
        @[@"m_nsChatRoomUserName", @"sessionUserName"]);
    if (![chatRoomUserName hasSuffix:@"@chatroom"]) {
        chatRoomUserName = NeoWCRawProfileValue(contact, @[@"m_nsChatRoomUserName", @"sessionUserName"]);
    }
    objc_setAssociatedObject(controller, &NeoWCProfileChatRoomKey,
                             [chatRoomUserName hasSuffix:@"@chatroom"] ? chatRoomUserName : nil,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    NSString *title = @"详细信息";
    id targetSection = nil;
    NSUInteger targetIndex = NSNotFound;
    NSInteger targetScore = NSIntegerMin;
    for (NSUInteger sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++) {
        id section = NeoWCTableSectionAtIndex(tableInfo, sectionIndex);
        if (!section) continue;
        if (NeoWCSectionContainsRawIDCell(section, title)) return;
        NSUInteger cellCount = NeoWCTableCellCount(section);
        NSInteger sectionScore = -((NSInteger)sectionIndex);
        NSUInteger sectionTargetIndex = cellCount;
        for (NSUInteger cellIndex = 0; cellIndex < cellCount; cellIndex++) {
            NSString *cellTitle = NeoWCTableCellTitle(NeoWCTableCellAtIndex(section, cellIndex));
            if (cellTitle.length == 0) continue;
            if ([cellTitle containsString:@"微信号"] || [cellTitle containsString:@"群聊名称"]) {
                sectionScore += 100;
                sectionTargetIndex = cellIndex + 1;
            } else if ([cellTitle containsString:@"朋友资料"] || [cellTitle containsString:@"群聊"] ||
                       [cellTitle containsString:@"设置备注"] || [cellTitle containsString:@"备注"]) {
                sectionScore += 30;
            } else if ([cellTitle containsString:@"朋友圈"] || [cellTitle containsString:@"添加到通讯录"]) {
                sectionScore += 10;
            }
        }
        if (!targetSection || sectionScore > targetScore) {
            targetSection = section;
            targetIndex = sectionTargetIndex;
            targetScore = sectionScore;
        }
    }
    if (!targetSection) {
        targetSection = NeoWCTableSectionAtIndex(tableInfo, 0);
        targetIndex = NeoWCTableCellCount(targetSection);
    }
    id cell = NeoWCCreateRawIDCell(controller, title, rawID);
    if (!cell || !targetSection) return;
    objc_setAssociatedObject(cell, &NeoWCRawContactIDCellMarkerKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!NeoWCInsertRawIDCell(targetSection, cell, targetIndex)) return;
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

static id NeoWCHomeActionOwner(id owner, UITableView *tableView) {
    if ([owner isKindOfClass:UIViewController.class]) return owner;
    UIResponder *responder = tableView;
    while ((responder = responder.nextResponder)) {
        if ([responder isKindOfClass:UIViewController.class]) return responder;
    }
    return owner;
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

static NSMutableSet *NeoWCRetainedHomeSessionControllers(void) {
    static NSMutableSet *controllers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controllers = [NSMutableSet set];
    });
    return controllers;
}

static void NeoWCRetainHomeSessionController(id controller) {
    if (!controller) return;
    NSMutableSet *controllers = NeoWCRetainedHomeSessionControllers();
    [controllers addObject:controller];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [controllers removeObject:controller];
    });
}

static void NeoWCRefreshHomeSessionTable(UITableView *tableView) {
    if (!tableView) return;
    __weak UITableView *weakTableView = tableView;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [weakTableView reloadData];
    });
}

static void NeoWCSetHomeContactBoolean(id contact, NSString *selectorName, BOOL enabled) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!contact || ![contact respondsToSelector:selector]) return;
    @try {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(contact, selector, enabled);
    } @catch (__unused NSException *exception) {
    }
}

static void NeoWCCommitHomeSessionToggle(id contact, BOOL group, NSString *selectorName, BOOL enabled) {
    id controller = NeoWCHomeSessionInfoController(contact, group);
    SEL selector = NSSelectorFromString(selectorName);
    if (!controller || ![controller respondsToSelector:selector]) return;
    @try {
        NeoWCRetainHomeSessionController(controller);
        // Loading the native settings controller lets WeChat initialize its
        // backing state before the private setting action is dispatched.
        (void)((id (*)(id, SEL))objc_msgSend)(controller, @selector(view));
        ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, selector, enabled);
        SEL willDisappear = @selector(viewWillDisappear:);
        SEL didDisappear = @selector(viewDidDisappear:);
        if ([controller respondsToSelector:willDisappear]) ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, willDisappear, YES);
        if ([controller respondsToSelector:didDisappear]) ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, didDisappear, YES);
    } @catch (__unused NSException *exception) {
    }
}

static void NeoWCCommitHomeMuteToggle(id contact, BOOL group, BOOL muted) {
    BOOL desiredMuted = !muted;
    BOOL notifyOpen = !desiredMuted;
    NeoWCSetHomeContactBoolean(contact, @"setChatStatusNotifyOpen:", notifyOpen);
    NeoWCSetHomeContactBoolean(contact, @"setChatRoomNotify:", notifyOpen);
    NeoWCCommitHomeSessionToggle(contact, group, @"setUpdateNotifyMuted:", desiredMuted);
}

typedef UISwipeActionsConfiguration *(*NeoWCHomeLeadingSwipeIMP)(id, SEL, UITableView *, NSIndexPath *);

static NSMutableDictionary<NSString *, NSValue *> *NeoWCHomeLeadingSwipeOriginalIMPs(void) {
    static NSMutableDictionary<NSString *, NSValue *> *implementations;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        implementations = [NSMutableDictionary dictionary];
    });
    return implementations;
}

static NeoWCHomeLeadingSwipeIMP NeoWCOriginalHomeLeadingSwipeForOwner(id owner) {
    for (Class candidate = object_getClass(owner); candidate; candidate = class_getSuperclass(candidate)) {
        NSValue *value = NeoWCHomeLeadingSwipeOriginalIMPs()[NSStringFromClass(candidate)];
        if (value) return (NeoWCHomeLeadingSwipeIMP)value.pointerValue;
    }
    return NULL;
}

static UISwipeActionsConfiguration *NeoWCHomeLeadingSwipe(id owner, SEL selector,
                                                           UITableView *tableView,
                                                           NSIndexPath *indexPath) {
    NeoWCHomeLeadingSwipeIMP original = NeoWCOriginalHomeLeadingSwipeForOwner(owner);
    if (!NeoWCEnhancementEnabled(NeoWCHomeSwipeActionsEnabledKey)) {
        return original ? original(owner, selector, tableView, indexPath) : nil;
    }
    id data = NeoWCHomeSessionCellData(owner, tableView, indexPath);
    NSString *userName = NeoWCHomeSessionUserName(data);
    if (userName.length == 0) {
        NeoWCLog(@"主页右滑：未取得会话数据，owner=%@ delegate=%@ row=%ld",
                 NSStringFromClass([owner class]),
                 NSStringFromClass([tableView.delegate class]),
                 (long)indexPath.row);
        return original ? original(owner, selector, tableView, indexPath) : nil;
    }
    id contact = NeoWCContactForUserName(userName) ?: data;
    id actionOwner = NeoWCHomeActionOwner(owner, tableView);
    BOOL group = [userName hasSuffix:@"@chatroom"];
    BOOL supportsMoments = !group &&
                           ![userName hasPrefix:@"gh_"] &&
                           ![userName isEqualToString:@"filehelper"] &&
                           ![userName isEqualToString:@"weixin"];
    id sessionInfo = NeoWCTweakValueForSelectorNames(data, @[@"m_sessionInfo", @"sessionInfo"]) ?: data;
    BOOL muted = NeoWCHomeSessionMuted(contact);
    BOOL top = NeoWCHomeBooleanValue(sessionInfo, @[@"m_bIsTop", @"isTop"]);
    __weak UITableView *weakTableView = tableView;

    UIContextualAction *remark = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                          title:@"备注"
                                                                        handler:^(__unused UIContextualAction *action,
                                                                                  __unused UIView *sourceView,
                                                                                  void (^completionHandler)(BOOL)) {
        NeoWCOpenHomeRemark(actionOwner, contact, group);
        completionHandler(YES);
    }];
    remark.backgroundColor = UIColor.systemGrayColor;

    UIContextualAction *mute = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                        title:muted ? @"取消勿扰" : @"勿扰"
                                                                      handler:^(__unused UIContextualAction *action,
                                                                                __unused UIView *sourceView,
                                                                                void (^completionHandler)(BOOL)) {
        NeoWCCommitHomeMuteToggle(contact, group, muted);
        NeoWCRefreshHomeSessionTable(weakTableView);
        completionHandler(YES);
    }];
    mute.backgroundColor = UIColor.systemOrangeColor;

    UIContextualAction *pin = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                       title:top ? @"取消置顶" : @"置顶"
                                                                     handler:^(__unused UIContextualAction *action,
                                                                               __unused UIView *sourceView,
                                                                               void (^completionHandler)(BOOL)) {
        NeoWCCommitHomeSessionToggle(contact, group, @"onTopSession:", !top);
        NeoWCRefreshHomeSessionTable(weakTableView);
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
            NeoWCRefreshHomeSessionTable(weakTableView);
            completionHandler(YES);
        }];
        fold.backgroundColor = UIColor.systemPurpleColor;
        [actions insertObject:fold atIndex:1];
    } else if (supportsMoments) {
        UIContextualAction *moments = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                               title:@"朋友圈"
                                                                             handler:^(__unused UIContextualAction *action,
                                                                                       __unused UIView *sourceView,
                                                                                       void (^completionHandler)(BOOL)) {
            NeoWCOpenHomeMoments(actionOwner, contact);
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

static void NeoWCInstallHomeLeadingSwipeOnClass(Class controllerClass) {
    SEL selector = NSSelectorFromString(@"tableView:leadingSwipeActionsConfigurationForRowAtIndexPath:");
    if (!controllerClass) return;
    Method method = class_getInstanceMethod(controllerClass, selector);
    const char *types = "@@:@@";
    IMP currentImplementation = method ? method_getImplementation(method) : NULL;
    if (currentImplementation == (IMP)NeoWCHomeLeadingSwipe) return;
    if (method) {
        types = method_getTypeEncoding(method) ?: types;
        NeoWCHomeLeadingSwipeOriginalIMPs()[NSStringFromClass(controllerClass)] =
            [NSValue valueWithPointer:(const void *)currentImplementation];
    }
    // class_addMethod also handles an inherited implementation without mutating
    // the superclass. Only replace directly when this class already owns it.
    if (class_addMethod(controllerClass, selector, (IMP)NeoWCHomeLeadingSwipe, types)) {
        return;
    }
    Method ownedMethod = class_getInstanceMethod(controllerClass, selector);
    if (!ownedMethod) return;
    method_setImplementation(ownedMethod, (IMP)NeoWCHomeLeadingSwipe);
}

static void NeoWCTryInstallHomeLeadingSwipe(void) {
    NeoWCInstallHomeLeadingSwipeOnClass(objc_getClass("NewMainFrameViewController"));
}

static UITableView *NeoWCHomeTableViewForController(id controller) {
    id tableView = NeoWCTweakValueForSelectorNames(controller,
                                                    @[@"tableView", @"m_tableView", @"mainTableView", @"m_mainTableView"]);
    if ([tableView isKindOfClass:UITableView.class]) return tableView;
    UIView *rootView = [controller isKindOfClass:UIViewController.class] ? [controller view] : nil;
    if (!rootView) return nil;
    NSMutableArray<UIView *> *pending = [NSMutableArray arrayWithObject:rootView];
    while (pending.count > 0) {
        UIView *candidate = pending.lastObject;
        [pending removeLastObject];
        if ([candidate isKindOfClass:UITableView.class] &&
            ([NSStringFromClass(candidate.class) containsString:@"MainFrame"] || !tableView)) {
            tableView = candidate;
            if ([NSStringFromClass(candidate.class) containsString:@"MainFrame"]) break;
        }
        [pending addObjectsFromArray:candidate.subviews];
    }
    return [tableView isKindOfClass:UITableView.class] ? tableView : nil;
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

%hook NewMainFrameViewController

- (void)viewDidLoad {
    // Install before WeChat creates/assigns the table delegate. UIKit may cache
    // whether the delegate implements leading swipe actions during setup.
    NeoWCInstallHomeLeadingSwipeOnClass(object_getClass(self));
    %orig;
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    UITableView *tableView = NeoWCHomeTableViewForController(self);
    NeoWCInstallHomeLeadingSwipeOnClass(object_getClass(self));
    if (tableView.delegate) NeoWCInstallHomeLeadingSwipeOnClass(object_getClass(tableView.delegate));
}

%end

%hook NewMainFrameCell

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (NeoWCEnhancementEnabled(NeoWCHomeSwipeActionsEnabledKey) &&
        [gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:gestureRecognizer.view];
        // NewMainFrameCell owns a horizontal pan recognizer that can win before
        // UITableView's leading-swipe recognizer. Yield only for a deliberate
        // rightward horizontal gesture; vertical scrolling and native left
        // swipe actions continue through WeChat's original decision.
        if (velocity.x > 0.0 && fabs(velocity.x) > fabs(velocity.y)) return NO;
    }
    return %orig;
}

%end

%hook MainFrameTableView

- (void)setDelegate:(id<UITableViewDelegate>)delegate {
    // UITableView caches optional delegate capabilities inside setDelegate:.
    // Install the leading-swipe selector before passing the delegate to WeChat,
    // otherwise the method works only when startup timing happens to be lucky.
    if (delegate) NeoWCInstallHomeLeadingSwipeOnClass(object_getClass(delegate));
    %orig(delegate);
}

%end

%hook WeixinContactInfoAssist

- (void)initData {
    %orig;
    NeoWCInjectRawIDCell(self, NO);
    if (!NeoWCEnhancementEnabled(NeoWCShowRawContactIDEnabledKey)) {
        NeoWCInjectProfileConversationSwitches(self, NO);
    }
}

- (void)reloadTableView {
    %orig;
    NeoWCInjectRawIDCell(self, NO);
    if (!NeoWCEnhancementEnabled(NeoWCShowRawContactIDEnabledKey)) {
        NeoWCInjectProfileConversationSwitches(self, NO);
    }
}

%new
- (void)neowc_copyRawContactID {
    NSString *rawID = objc_getAssociatedObject(self, &NeoWCRawContactIDKey);
    if (rawID.length > 0) UIPasteboard.generalPasteboard.string = rawID;
}

%new
- (void)neowc_openInfoCard {
    NeoWCOpenProfileInfoCard(self);
}

%new
- (void)neowc_toggleProfileMessageBlock:(UISwitch *)sender {
    NeoWCSetProfileMessageBlocked(objc_getAssociatedObject(self, &NeoWCRawContactIDKey), sender.isOn);
}

%new
- (void)neowc_openProfileMessageBlockTypes {
    NSString *username = objc_getAssociatedObject(self, &NeoWCRawContactIDKey);
    UIViewController *controller = NeoWCMessageBlockTypeController(username);
    UIViewController *owner = NeoWCProfileOwnerViewController(self);
    if (controller && owner) {
        if (owner.navigationController) [owner.navigationController pushViewController:controller animated:YES];
        else [owner presentViewController:controller animated:YES completion:nil];
    }
}

%new
- (void)neowc_toggleProfileSendConfirmation:(UISwitch *)sender {
    NeoWCSendConfirmationSetProtected(objc_getAssociatedObject(self, &NeoWCRawContactIDKey), sender.isOn);
}

%end

%hook SocialInfomationViewController

- (void)onCRGDataUpdated {
    %orig;
    if (NeoWCEnhancementEnabled(NeoWCShowRawContactIDEnabledKey)) {
        NeoWCInjectProfileConversationSwitches(self, NO);
    }
    NeoWCRefreshInfoCardFromOfficialController(self);
}

- (void)reloadTableView {
    %orig;
    if (NeoWCEnhancementEnabled(NeoWCShowRawContactIDEnabledKey)) {
        NeoWCInjectProfileConversationSwitches(self, NO);
    }
    if (objc_getAssociatedObject(self, &NeoWCOfficialInfoCardBoxKey)) {
        NeoWCRefreshInfoCardFromOfficialController(self);
    }
}

%new
- (void)neowc_toggleProfileMessageBlock:(UISwitch *)sender {
    NeoWCSetProfileMessageBlocked(objc_getAssociatedObject(self, &NeoWCRawContactIDKey), sender.isOn);
}

%new
- (void)neowc_openProfileMessageBlockTypes {
    NSString *username = objc_getAssociatedObject(self, &NeoWCRawContactIDKey);
    UIViewController *controller = NeoWCMessageBlockTypeController(username);
    if (controller) [self.navigationController pushViewController:controller animated:YES];
}

%new
- (void)neowc_toggleProfileSendConfirmation:(UISwitch *)sender {
    NeoWCSendConfirmationSetProtected(objc_getAssociatedObject(self, &NeoWCRawContactIDKey), sender.isOn);
}

%end

%hook ChatRoomInfoViewController

- (void)initData {
    %orig;
    NeoWCInjectRawIDCell(self, YES);
    NeoWCInjectProfileConversationSwitches(self, YES);
}

- (void)reloadTableData {
    %orig;
    NeoWCInjectRawIDCell(self, YES);
    NeoWCInjectProfileConversationSwitches(self, YES);
}

- (void)reloadProfileTableData {
    %orig;
    NeoWCInjectRawIDCell(self, YES);
    NeoWCInjectProfileConversationSwitches(self, YES);
}

%new
- (void)neowc_copyRawContactID {
    NSString *rawID = objc_getAssociatedObject(self, &NeoWCRawContactIDKey);
    if (rawID.length > 0) UIPasteboard.generalPasteboard.string = rawID;
}

%new
- (void)neowc_openInfoCard {
    NeoWCOpenProfileInfoCard(self);
}

%new
- (void)neowc_toggleProfileMessageBlock:(UISwitch *)sender {
    NeoWCSetProfileMessageBlocked(objc_getAssociatedObject(self, &NeoWCRawContactIDKey), sender.isOn);
}

%new
- (void)neowc_openProfileMessageBlockTypes {
    NSString *username = objc_getAssociatedObject(self, &NeoWCRawContactIDKey);
    UIViewController *controller = NeoWCMessageBlockTypeController(username);
    UIViewController *owner = NeoWCProfileOwnerViewController(self);
    if (controller && owner) {
        if (owner.navigationController) [owner.navigationController pushViewController:controller animated:YES];
        else [owner presentViewController:controller animated:YES completion:nil];
    }
}

%new
- (void)neowc_toggleProfileSendConfirmation:(UISwitch *)sender {
    NeoWCSendConfirmationSetProtected(objc_getAssociatedObject(self, &NeoWCRawContactIDKey), sender.isOn);
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

%new
- (void)neowc_openChatSearch:(id)sender {
    if (!NeoWCOpenOfficialChatSearch(self, sender)) {
        NeoWCShowTransientMessage(@"当前微信版本暂不支持聊天记录搜索", NO);
    }
}

%new
- (void)neowc_handleChatSearchEdgePan:(UIScreenEdgePanGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateEnded ||
        ![objc_getAssociatedObject(self, &NeoWCChatSearchActiveKey) boolValue]) return;
    UIView *gestureView = recognizer.view ?: self.view;
    CGPoint translation = [recognizer translationInView:gestureView];
    CGPoint velocity = [recognizer velocityInView:gestureView];
    if (translation.x > 44.0 || velocity.x > 260.0) {
        NeoWCCleanupOfficialChatSearch(self);
    }
}

- (void)msgSearchBarCancel {
    if ([objc_getAssociatedObject(self, &NeoWCChatSearchActiveKey) boolValue]) {
        NeoWCCleanupOfficialChatSearch(self);
        return;
    }
    %orig;
}

%new
- (void)neowc_toggleSendConfirmation:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) return;
    if (!NeoWCEnhancementEnabled(NeoWCSendConfirmationEnabledKey)) {
        NeoWCShowTransientMessage(@"请先在 NeoWC 设置中开启发送前确认", NO);
        return;
    }
    NSString *username = NeoWCChatUserName(self);
    if (username.length == 0) {
        NeoWCShowTransientMessage(@"无法识别当前会话", NO);
        return;
    }
    BOOL protectedConversation = NeoWCSendConfirmationIsProtectedConversation(username);
    NeoWCSendConfirmationSetProtected(username, !protectedConversation);
    NeoWCShowTransientMessage(protectedConversation ? @"已关闭当前会话发送确认" : @"已开启当前会话发送确认", YES);
}

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
    NeoWCCleanupOfficialChatSearch(self);
    objc_setAssociatedObject(self, &NeoWCChatSearchTransitionKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCVisibleChatController = self;
    NeoWCSendConfirmationChatController = self;
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
    BOOL hasNeoWCActions = NeoWCChatMultiSelectActions((UIViewController *)self).count > 0;
    if (!hasNeoWCActions) {
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
    for (NSDictionary *action in NeoWCChatMultiSelectActions((UIViewController *)self)) {
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
    BOOL enteringOfficialSearch = [objc_getAssociatedObject(self, &NeoWCChatSearchTransitionKey) boolValue];
    if (NeoWCEnhancementEnabled(NeoWCChatTopBarCapsuleEnabledKey) && !enteringOfficialSearch) {
        NeoWCApplyTransparentChatTopAppearance(self);
        NeoWCApplyChatNavigationBackground(self, YES);
        id<UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
        if (coordinator) {
            __weak BaseMsgContentViewController *weakController = self;
            __weak UINavigationController *weakNavigation = self.navigationController;
            [coordinator animateAlongsideTransition:nil
                                         completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                BaseMsgContentViewController *strongController = weakController;
                UINavigationController *navigationController = weakNavigation;
                if (!strongController) return;
                if (context.isCancelled) {
                    NeoWCUpdateChatTopBar(strongController);
                } else {
                    NeoWCRestoreChatNavigationPresentationWithNavigation(strongController,
                                                                         navigationController);
                }
            }];
        }
    }
    UIViewController *controller = (UIViewController *)self;
    if (controller.isMovingFromParentViewController || controller.isBeingDismissed) {
        if (NeoWCSendConfirmationChatController == self) NeoWCSendConfirmationChatController = nil;
        NeoWCCancelPendingSendConfirmations();
        NeoWCClearImageJokerOverrides();
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    objc_setAssociatedObject(self, &NeoWCChatSearchTransitionKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NeoWCVisibleChatController = self;
    NeoWCSendConfirmationChatController = self;
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
    NeoWCRestoreChatNavigationPresentation(self);
    if (NeoWCVisibleChatController == self) NeoWCVisibleChatController = nil;
}

- (void)dealloc {
    NeoWCRemoveChatSearchEdgePan(self);
    if (NeoWCSendConfirmationChatController == self) NeoWCSendConfirmationChatController = nil;
    NeoWCClearImageJokerOverrides();
    %orig;
}

%end

%hook MMScrollActionSheet

- (void)showInView:(UIView *)view {
    id delegate = NeoWCTweakSafeValue(self, @"delegate");
    BOOL isExportMenu = [objc_getAssociatedObject(delegate, &NeoWCChatExportBuildingMenuKey) boolValue];
    if (isExportMenu && NeoWCChatMultiSelectActions((UIViewController *)delegate).count > 0) {
        NSArray *originalRows = NeoWCTweakSafeValue(self, @"itemArray");
        if ([originalRows isKindOfClass:[NSArray class]] && originalRows.count > 0) {
            NSMutableArray *rows = [NSMutableArray arrayWithCapacity:originalRows.count];
            for (id originalRow in originalRows) {
                NSMutableArray *row = [originalRow isKindOfClass:[NSArray class]] ? [originalRow mutableCopy] : [NSMutableArray array];
                [rows addObject:row];
            }
            for (NSDictionary *action in NeoWCChatMultiSelectActions((UIViewController *)delegate)) {
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
    id message = NeoWCMessageWrapForCell(self);
    if (NeoWCMessageIsMusicCard(message)) {
        filteredItems = NeoWCOperationMenuItemsWithMediaToVoice(self, filteredItems, NeoWCMediaToVoiceKindMusic);
    } else if (NeoWCMessageIsConvertibleAudioFile(message)) {
        filteredItems = NeoWCOperationMenuItemsWithMediaToVoice(self, filteredItems, NeoWCMediaToVoiceKindAudioFile);
    }
    if (NeoWCEnhancementEnabled(NeoWCLongPressMenuEnabledKey)) {
        NeoWCCompatibilityMarkTriggered(@"long-press-menu");
    }
    return NeoWCManagedLongPressMenuItems(filteredItems);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(neowc_convertMusicToVoice:)) {
        return NeoWCMediaToVoiceKindEnabled(NeoWCMediaToVoiceKindMusic) &&
               NeoWCMessageIsMusicCard(NeoWCMessageWrapForCell(self));
    }
    if (action == @selector(neowc_convertAudioFileToVoice:)) {
        return NeoWCMediaToVoiceKindEnabled(NeoWCMediaToVoiceKindAudioFile) &&
               NeoWCMessageIsConvertibleAudioFile(NeoWCMessageWrapForCell(self));
    }
    return %orig;
}

%new
- (void)neowc_convertMusicToVoice:(id)sender {
    (void)sender;
    NeoWCPresentMediaToVoiceConfirmation(self, NeoWCMediaToVoiceKindMusic);
}

%new
- (void)neowc_convertAudioFileToVoice:(id)sender {
    (void)sender;
    NeoWCPresentMediaToVoiceConfirmation(self, NeoWCMediaToVoiceKindAudioFile);
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
    items = NeoWCOperationMenuItemsWithImageJoker(self, items);
    return NeoWCOperationMenuItemsWithQuickReply(self, items);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(joker_handleImageMenuItem:)) {
        return NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey) && NeoWCMessageWrapForCell(self) != nil;
    }
    if (action == @selector(neowc_addToQuickReply:)) return NeoWCMessageCanAddToQuickReply(NeoWCMessageWrapForCell(self));
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

%new
- (void)neowc_addToQuickReply:(id)sender {
    (void)sender;
    NeoWCAddMessageToQuickReply(self);
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

%hook MMNewUploadVoiceMgr

- (void)AddNewPart:(id)part
           LocalID:(unsigned int)localID
          n64SvrID:(long long)serverID
            Offset:(unsigned int)offset
               Len:(unsigned int)length
         VoiceTime:(unsigned int)voiceTime
        CreateTime:(unsigned int)createTime
           EndFlag:(unsigned int)endFlag
        CancelFlag:(unsigned int)cancelFlag
       VoiceFormat:(unsigned int)voiceFormat
       ForwardFlag:(unsigned int)forwardFlag
         msgSource:(id)msgSource
          chatName:(id)chatName {
    %orig(part,
          localID,
          serverID,
          offset,
          length,
          voiceTime,
          createTime,
          endFlag,
          cancelFlag,
          voiceFormat,
          NeoWCVoiceRepeatUploadIsActive() ? 1 : forwardFlag,
          msgSource,
          chatName);
}

%end

%hook UploadVoiceCDNMgr

- (void)AddNewPart:(id)part
           LocalID:(unsigned int)localID
          n64SvrID:(long long)serverID
            Offset:(unsigned int)offset
               Len:(unsigned int)length
         VoiceTime:(unsigned int)voiceTime
        CreateTime:(unsigned int)createTime
           EndFlag:(unsigned int)endFlag
        CancelFlag:(unsigned int)cancelFlag
       VoiceFormat:(unsigned int)voiceFormat
       ForwardFlag:(unsigned int)forwardFlag
         msgSource:(id)msgSource
          chatName:(id)chatName {
    %orig(part,
          localID,
          serverID,
          offset,
          length,
          voiceTime,
          createTime,
          endFlag,
          cancelFlag,
          voiceFormat,
          NeoWCVoiceRepeatUploadIsActive() ? 1 : forwardFlag,
          msgSource,
          chatName);
}

%end

static BOOL NeoWCSetNativeRichTextContent(id richTextView, NSString *plainText) {
    if (!richTextView || ![plainText isKindOfClass:NSString.class] || plainText.length == 0) return NO;
    SEL contentSelector = NSSelectorFromString(@"setContent:");
    if (![richTextView respondsToSelector:contentSelector]) return NO;
    ((void (*)(id, SEL, id))objc_msgSend)(richTextView, contentSelector, plainText);
    if ([richTextView isKindOfClass:UIView.class]) {
        ((UIView *)richTextView).hidden = NO;
        ((UIView *)richTextView).alpha = 1.0;
        [(UIView *)richTextView setNeedsDisplay];
    }
    return YES;
}

static NSString *NeoWCDecryptedPlainTextForCell(id cell) {
    if (!cell || !NeoWCEnhancementEnabled(NeoWCEncryptedMessageEnabledKey)) return nil;
    id message = NeoWCMessageWrapForCell(cell);
    NSString *wireText = NeoWCTweakSafeValue(message, @"m_nsContent");
    if (![wireText isKindOfClass:NSString.class] || !NeoWCIsEncryptedTextWireString(wireText)) return nil;
    NSString *plainText = objc_getAssociatedObject(message, &NeoWCEncryptedTextManualPlainKey);
    if ([plainText isKindOfClass:NSString.class] && plainText.length > 0) return plainText;
    if (![NSUserDefaults.standardUserDefaults boolForKey:NeoWCEncryptedMessageAutoDecryptKey]) return nil;
    return NeoWCDecryptTextWireString(wireText, nil);
}

static BOOL NeoWCApplyDecryptedTextToTranslationView(id cell, NSString *plainText) {
    if (!cell || ![plainText isKindOfClass:NSString.class] || plainText.length == 0) return NO;
    id translateRichTextView = NeoWCTweakSafeValue(cell, @"m_translateRichTextView");
    if (!NeoWCSetNativeRichTextContent(translateRichTextView, plainText)) return NO;
    if ([translateRichTextView isKindOfClass:UIView.class]) {
        ((UIView *)translateRichTextView).hidden = NO;
        ((UIView *)translateRichTextView).alpha = 1.0;
    }
    id successLabel = NeoWCTweakSafeValue(cell, @"m_translateSuccessLabel");
    if ([successLabel respondsToSelector:@selector(setText:)]) {
        ((void (*)(id, SEL, id))objc_msgSend)(successLabel, @selector(setText:), @"NeoWC 解密");
        if ([successLabel isKindOfClass:UIView.class]) {
            ((UIView *)successLabel).hidden = NO;
            ((UIView *)successLabel).alpha = 1.0;
        }
    }
    if ([cell isKindOfClass:UIView.class]) [(UIView *)cell setNeedsLayout];
    return YES;
}

static BOOL NeoWCApplyDecryptedTextToCurrentCellViews(id cell, NSString *plainText) {
    BOOL applied = NO;
    SEL richTextSelector = NSSelectorFromString(@"getRichTextViewForDelegate");
    if ([cell respondsToSelector:richTextSelector]) {
        id richTextView = ((id (*)(id, SEL))objc_msgSend)(cell, richTextSelector);
        applied = NeoWCSetNativeRichTextContent(richTextView, plainText);
    }
    BOOL translated = NeoWCApplyDecryptedTextToTranslationView(cell, plainText);
    if ((applied || translated) && [cell isKindOfClass:UIView.class]) {
        [(UIView *)cell setNeedsLayout];
    }
    return translated || applied;
}

static NSArray *NeoWCOperationMenuItemsWithEncryptedTextDecrypt(id target, NSArray *originalItems) {
    if (![originalItems isKindOfClass:NSArray.class] ||
        !NeoWCEnhancementEnabled(NeoWCEncryptedMessageEnabledKey)) return originalItems;
    id message = NeoWCMessageWrapForCell(target);
    NSString *wireText = NeoWCTweakSafeValue(message, @"m_nsContent");
    if (![wireText isKindOfClass:NSString.class] || !NeoWCIsEncryptedTextWireString(wireText)) {
        return originalItems;
    }
    for (id item in originalItems) {
        if ([[NeoWCTweakSafeValue(item, @"title") description] isEqualToString:@"解密"]) return originalItems;
    }
    Class itemClass = NSClassFromString(@"MMMenuItem");
    if (![itemClass instancesRespondToSelector:@selector(initWithTitle:icon:target:action:)]) {
        return originalItems;
    }
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration
        configurationWithPointSize:18.0 weight:UIImageSymbolWeightRegular];
    UIImage *icon = [UIImage systemImageNamed:@"lock.open.fill" withConfiguration:configuration];
    icon = [icon imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    MMMenuItem *decryptItem = [[itemClass alloc] initWithTitle:@"解密" icon:icon
                                                       target:target
                                                       action:@selector(neowc_decryptEncryptedText:)];
    NSMutableArray *items = [originalItems mutableCopy];
    [items insertObject:decryptItem atIndex:0];
    return items;
}

%hook TextMessageCellView

- (NSString *)getTextString {
    NSString *plainText = objc_getAssociatedObject(self, &NeoWCEncryptedTextDisplayOverrideKey);
    if (![plainText isKindOfClass:NSString.class] || plainText.length == 0) {
        plainText = NeoWCDecryptedPlainTextForCell(self);
        if (plainText.length > 0) {
            objc_setAssociatedObject(self, &NeoWCEncryptedTextDisplayOverrideKey, plainText,
                                     OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
    }
    return ([plainText isKindOfClass:NSString.class] && plainText.length > 0) ? plainText : %orig;
}

- (id)getRichTextViewForDelegate {
    id richTextView = %orig;
    NSString *plainText = objc_getAssociatedObject(self, &NeoWCEncryptedTextDisplayOverrideKey);
    if (![plainText isKindOfClass:NSString.class] || plainText.length == 0) {
        plainText = NeoWCDecryptedPlainTextForCell(self);
        if (plainText.length > 0) {
            objc_setAssociatedObject(self, &NeoWCEncryptedTextDisplayOverrideKey, plainText,
                                     OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
    }
    if ([plainText isKindOfClass:NSString.class] && plainText.length > 0) {
        // PKC uses this callback to re-establish encrypted-display state each
        // time WeChat rebuilds a recycled text cell.
        NeoWCSetNativeRichTextContent(richTextView, plainText);
        NeoWCApplyDecryptedTextToTranslationView(self, plainText);
    }
    return richTextView;
}

- (void)updateTranslateSuccessView {
    %orig;
    // PKC re-reads getCurrentMessageWrap here instead of trusting stale cell
    // state.  Do the same so recycled cells still bind to the right message.
    NSString *plainText = NeoWCDecryptedPlainTextForCell(self);
    if (![plainText isKindOfClass:NSString.class] || plainText.length == 0) return;
    objc_setAssociatedObject(self, &NeoWCEncryptedTextDisplayOverrideKey, plainText,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    __weak TextMessageCellView *weakCell = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        TextMessageCellView *cell = weakCell;
        if (!cell) return;
        NSString *currentPlainText = objc_getAssociatedObject(cell, &NeoWCEncryptedTextDisplayOverrideKey);
        if (![currentPlainText isEqualToString:plainText]) return;
        NeoWCApplyDecryptedTextToTranslationView(cell, currentPlainText);
        objc_setAssociatedObject(cell, &NeoWCEncryptedTextRefreshInFlightKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NeoWCCompatibilityMarkTriggered(@"encrypted-text-display");
    });
}

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    items = NeoWCOperationMenuItemsWithEncryptedTextDecrypt(self, items);
    items = NeoWCOperationMenuItemsWithJoker(self, items, NO);
    return NeoWCOperationMenuItemsWithQuickReply(self, items);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(neowc_decryptEncryptedText:)) {
        id message = NeoWCMessageWrapForCell(self);
        NSString *wireText = NeoWCTweakSafeValue(message, @"m_nsContent");
        return NeoWCEnhancementEnabled(NeoWCEncryptedMessageEnabledKey) &&
               [wireText isKindOfClass:NSString.class] && NeoWCIsEncryptedTextWireString(wireText);
    }
    if (action == @selector(joker_handleMenuItem:)) {
        return NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey) && NeoWCMessageCanJokerEdit(NeoWCMessageWrapForCell(self));
    }
    if (action == @selector(neowc_addToQuickReply:)) return NeoWCMessageCanAddToQuickReply(NeoWCMessageWrapForCell(self));
    return %orig;
}

%new
- (void)neowc_decryptEncryptedText:(id)sender {
    (void)sender;
    id message = NeoWCMessageWrapForCell(self);
    NSString *wireText = NeoWCTweakSafeValue(message, @"m_nsContent");
    if (![wireText isKindOfClass:NSString.class] || !NeoWCIsEncryptedTextWireString(wireText)) return;
    NSError *error = nil;
    NSString *plainText = NeoWCDecryptTextWireString(wireText, &error);
    if (plainText.length == 0) {
        NeoWCShowTransientMessage(error.localizedDescription ?: @"密文解密失败", NO);
        return;
    }
    objc_setAssociatedObject(self, &NeoWCEncryptedTextDisplayOverrideKey, plainText,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(message, &NeoWCEncryptedTextManualPlainKey, plainText,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &NeoWCEncryptedTextRefreshInFlightKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // PKC's confirmed display chain is current native cell -> translateMsg ->
    // updateTranslateSuccessView -> m_translateRichTextView setContent:.
    SEL translateSelector = NSSelectorFromString(@"translateMsg");
    if ([self respondsToSelector:translateSelector]) {
        ((void (*)(id, SEL))objc_msgSend)(self, translateSelector);
    } else {
        NeoWCApplyDecryptedTextToCurrentCellViews(self, plainText);
    }
    NeoWCCompatibilityMarkTriggered(@"encrypted-text-manual-decrypt");
}

%new
- (void)joker_handleMenuItem:(id)sender {
    NeoWCCompatibilityMarkTriggered(@"chat-joker");
    NeoWCPresentJokerEditorForCell(self, NO);
}

%new
- (void)neowc_addToQuickReply:(id)sender {
    (void)sender;
    NeoWCAddMessageToQuickReply(self);
}

%end

%hook AppMessageCellView

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    items = NeoWCOperationMenuItemsWithJoker(self, items, NO);
    items = NeoWCOperationMenuItemsWithMediaToVoice(self, items, NeoWCMediaToVoiceKindMusic);
    return NeoWCOperationMenuItemsWithQuickReply(self, items);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(joker_handleMenuItem:)) {
        return NeoWCEnhancementEnabled(NeoWCChatJokerEnabledKey) && NeoWCMessageCanJokerEdit(NeoWCMessageWrapForCell(self));
    }
    if (action == @selector(neowc_addToQuickReply:)) return NeoWCMessageCanAddToQuickReply(NeoWCMessageWrapForCell(self));
    if (action == @selector(neowc_convertMusicToVoice:)) {
        return NeoWCMediaToVoiceKindEnabled(NeoWCMediaToVoiceKindMusic) &&
               NeoWCMessageIsMusicCard(NeoWCMessageWrapForCell(self));
    }
    return %orig;
}

%new
- (void)joker_handleMenuItem:(id)sender {
    NeoWCCompatibilityMarkTriggered(@"chat-joker");
    NeoWCPresentJokerEditorForCell(self, NO);
}

%new
- (void)neowc_addToQuickReply:(id)sender {
    (void)sender;
    NeoWCAddMessageToQuickReply(self);
}

%new
- (void)neowc_convertMusicToVoice:(id)sender {
    (void)sender;
    NeoWCPresentMediaToVoiceConfirmation(self, NeoWCMediaToVoiceKindMusic);
}

%end

%hook VideoMessageCellView

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    return NeoWCOperationMenuItemsWithMediaToVoice(self, items, NeoWCMediaToVoiceKindVideo);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(neowc_convertVideoToVoice:)) {
        return NeoWCMediaToVoiceKindEnabled(NeoWCMediaToVoiceKindVideo) && NeoWCMessageWrapForCell(self) != nil;
    }
    return %orig;
}

%new
- (void)neowc_convertVideoToVoice:(id)sender {
    (void)sender;
    NeoWCPresentMediaToVoiceConfirmation(self, NeoWCMediaToVoiceKindVideo);
}

%end

%hook AppFileMessageCellViewV2

- (NSArray *)operationMenuItems {
    NSArray *items = %orig;
    items = NeoWCOperationMenuItemsWithMediaToVoice(self, items, NeoWCMediaToVoiceKindAudioFile);
    items = NeoWCOperationMenuItemsWithQuickReply(self, items);
    return NeoWCOperationMenuItemsWithEncryptedPreview(self, items);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(neowc_addToQuickReply:)) return NeoWCMessageCanAddToQuickReply(NeoWCMessageWrapForCell(self));
    if (action == @selector(neowc_previewEncryptedMedia:)) {
        return NeoWCMessageLooksLikeEncryptedMedia(NeoWCMessageWrapForCell(self));
    }
    if (action == @selector(neowc_convertAudioFileToVoice:)) {
        return NeoWCMediaToVoiceKindEnabled(NeoWCMediaToVoiceKindAudioFile) &&
               NeoWCMessageIsConvertibleAudioFile(NeoWCMessageWrapForCell(self));
    }
    return %orig;
}

%new
- (void)neowc_addToQuickReply:(id)sender {
    (void)sender;
    NeoWCAddMessageToQuickReply(self);
}

%new
- (void)neowc_convertAudioFileToVoice:(id)sender {
    (void)sender;
    NeoWCPresentMediaToVoiceConfirmation(self, NeoWCMediaToVoiceKindAudioFile);
}

%new
- (void)neowc_previewEncryptedMedia:(id)sender {
    (void)sender;
    NeoWCPresentEncryptedMediaPreview(self);
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
    BOOL shouldReplaceOperateButton = NeoWCEnhancementEnabled(NeoWCMomentsQuickCommentKey) &&
                                      !NeoWCMomentsIsNativeDetailContext(self);
    if (shouldReplaceOperateButton) {
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
    if (!NeoWCEnhancementEnabled(NeoWCMomentsDoubleTapLikeKey) ||
        NeoWCMomentsIsNativeDetailContext(self)) return;
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

%new
- (void)neowc_handleMomentsSaveImages:(id)sender {
    (void)sender;
    id dataItem = NeoWCMomentsObjectForName(self, @"m_dataItem");
    UIViewController *presenter = NeoWCJokerPresenterForCell(self);
    if (!NeoWCMomentCanSaveMedia(dataItem) || !presenter) return;
    NeoWCSaveMomentMedia(dataItem, presenter);
}

- (id)operateBtnImage:(BOOL)spring isSpringStyle:(BOOL)springStyle {
    if (NeoWCEnhancementEnabled(NeoWCMomentsQuickCommentKey) &&
        !NeoWCMomentsIsNativeDetailContext(self)) {
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:16.0 weight:UIImageSymbolWeightMedium];
        return [[UIImage systemImageNamed:@"bubble.middle.bottom" withConfiguration:configuration] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return %orig;
}

%end

%hook WCTimeLineOperateButtonView

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (NeoWCEnhancementEnabled(NeoWCMomentsQuickCommentKey) &&
        !NeoWCMomentsIsNativeDetailContext(self)) {
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
    UIButton *saveButton = objc_getAssociatedObject(self, &NeoWCMomentsFloatSaveButtonKey);
    button.hidden = YES;
    saveButton.hidden = YES;
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

%new
- (void)neowc_handleMomentsSaveImages:(id)sender {
    (void)sender;
    id dataItem = objc_getAssociatedObject(self, &NeoWCMomentsFloatDataItemKey);
    UIViewController *presenter = NeoWCJokerPresenterForCell(self);
    if (!dataItem || !presenter) return;
    [self hide];
    NeoWCSaveMomentMedia(dataItem, presenter);
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

%hook BaseMsgContentLogicController

- (void)SendTextMessage:(id)text {
    %orig(text);
}

- (void)SendTextMessage:(id)text replyingMessage:(id)replyingMessage isPasted:(BOOL)isPasted {
    %orig(text, replyingMessage, isPasted);
}

- (void)SendImageMessageByMMAsset:(id)asset {
    NSString *target = [self getCurrentChatName];
    if (NeoWCConsumeRepeatSendConfirmationBypass(target, 3, YES)) {
        %orig(asset);
        return;
    }
    UIViewController *presenter = NeoWCSendConfirmationPresenterForTarget(target);
    if (!presenter) {
        %orig(asset);
        return;
    }
    id retainedAsset = asset;
    BOOL held = NeoWCPresentSendConfirmationIfNeeded(presenter, target, @"图片：1 张", ^BOOL{
        return NeoWCSendConfirmationValidateTarget(target);
    }, ^{
        NeoWCArmImageSendConfirmationBypass(target);
        %orig(retainedAsset);
    });
    if (!held) %orig(asset);
}

%end

%hook WeixinContentLogicController

- (void)AddMsg:(id)message MsgWrap:(id)wrap {
    if ([objc_getAssociatedObject(wrap, &NeoWCSendConfirmationNativeBypassKey) boolValue]) {
        objc_setAssociatedObject(wrap, &NeoWCSendConfirmationNativeBypassKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        %orig(message, wrap);
        return;
    }
    NSUInteger messageType = [NeoWCTweakSafeValue(wrap, @"m_uiMessageType") unsignedIntegerValue];
    NSString *target = NeoWCTweakSafeValue(wrap, @"m_nsToUsr");
    if (messageType != 3 || ![target isKindOfClass:NSString.class] ||
        NeoWCConsumeImageSendConfirmationBypass(target) ||
        NeoWCConsumeRepeatSendConfirmationBypass(target, 3, NO)) {
        %orig(message, wrap);
        return;
    }
    UIViewController *presenter = NeoWCSendConfirmationPresenterForTarget(target);
    if (!presenter) {
        %orig(message, wrap);
        return;
    }
    id retainedMessage = message;
    id retainedWrap = wrap;
    BOOL held = NeoWCPresentSendConfirmationIfNeeded(presenter, target, @"图片：1 张", ^BOOL{
        return NeoWCSendConfirmationValidateTarget(target);
    }, ^{
        %orig(retainedMessage, retainedWrap);
    });
    if (!held) %orig(message, wrap);
}

%end

%hook CMessageMgr

- (void)AddMsg:(NSString *)target MsgWrap:(CMessageWrap *)wrap {
    NSInteger messageType = [NeoWCTweakSafeValue(wrap, @"m_uiMessageType") integerValue];
    if (messageType == 1 && NeoWCEnhancementEnabled(NeoWCEncryptedMessageEnabledKey)) {
        NSString *content = NeoWCTweakSafeValue(wrap, @"m_nsContent");
        if ([content isKindOfClass:NSString.class] && [content hasPrefix:@"#加密"]) {
            NSString *plainText = [[content substringFromIndex:@"#加密".length]
                stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (plainText.length == 0) {
                NeoWCShowTransientMessage(@"请在“#加密”后输入要发送的文字", NO);
                return;
            }
            NSError *error = nil;
            NSString *wireText = NeoWCEncryptedTextWireString(plainText, &error);
            if (wireText.length == 0) {
                NeoWCShowTransientMessage(error.localizedDescription ?: @"生成密文失败", NO);
                return;
            }
            NeoWCTweakSetValue(wrap, @"m_nsContent", wireText);
            NeoWCCompatibilityMarkTriggered(@"encrypted-text-send");
        }
    }
    if ([objc_getAssociatedObject(wrap, &NeoWCSendConfirmationNativeBypassKey) boolValue]) {
        objc_setAssociatedObject(wrap, &NeoWCSendConfirmationNativeBypassKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        %orig(target, wrap);
        return;
    }
    BOOL appEmoticon = NeoWCSendConfirmationMessageIsAppEmoticon(wrap);
    if (![target isKindOfClass:NSString.class] || (messageType != 1 && !appEmoticon)) {
        %orig(target, wrap);
        return;
    }
    if (NeoWCConsumeRepeatSendConfirmationBypass(target, messageType, NO)) {
        %orig(target, wrap);
        return;
    }
    UIViewController *presenter = NeoWCSendConfirmationPresenterForTarget(target);
    if (!presenter) {
        %orig(target, wrap);
        return;
    }
    NSString *summary = appEmoticon ? @"表情：1 个" : NeoWCSendConfirmationTextSummary(wrap);
    NSString *retainedTarget = [target copy];
    CMessageWrap *retainedWrap = wrap;
    BOOL held = NeoWCPresentSendConfirmationIfNeeded(presenter, target, summary, ^BOOL{
        return NeoWCSendConfirmationValidateTarget(retainedTarget);
    }, ^{
        %orig(retainedTarget, retainedWrap);
    });
    if (!held) %orig(target, wrap);
}

- (id)AddVideoMsg:(id)message ToUsr:(NSString *)target VideoInfo:(id)videoInfo {
    if (![target isKindOfClass:NSString.class] || NeoWCConsumeVideoSendConfirmationBypass(target) ||
        NeoWCConsumeRepeatSendConfirmationBypass(target, 43, NO)) {
        return %orig(message, target, videoInfo);
    }
    UIViewController *presenter = NeoWCSendConfirmationPresenterForTarget(target);
    if (!presenter) return %orig(message, target, videoInfo);
    id retainedMessage = message;
    NSString *retainedTarget = [target copy];
    id retainedVideoInfo = videoInfo;
    BOOL held = NeoWCPresentSendConfirmationIfNeeded(presenter, target, @"视频：1 个", ^BOOL{
        return NeoWCSendConfirmationValidateTarget(retainedTarget);
    }, ^{
        id ignoredResult = %orig(retainedMessage, retainedTarget, retainedVideoInfo);
        (void)ignoredResult;
    });
    return held ? nil : %orig(message, target, videoInfo);
}

- (void)AsyncOnAddMsg:(NSString *)sessionUserName MsgWrap:(CMessageWrap *)wrap {
    %orig;
    if (NeoWCDeleteBlockedIncomingMessage(self, sessionUserName, wrap)) {
        NeoWCCompatibilityMarkTriggered(@"message-block");
    }
}

- (void)AsyncOnAddMsgForSession:(NSString *)sessionUserName MsgWrap:(CMessageWrap *)wrap {
    %orig;
    if (NeoWCDeleteBlockedIncomingMessage(self, sessionUserName, wrap)) {
        NeoWCCompatibilityMarkTriggered(@"message-block");
    }
}

- (void)AsyncOnAddMsgForSession:(NSString *)sessionUserName
                        MsgWrap:(CMessageWrap *)wrap
             NewMsgArriveNotify:(BOOL)notify {
    %orig;
    if (NeoWCDeleteBlockedIncomingMessage(self, sessionUserName, wrap)) {
        NeoWCCompatibilityMarkTriggered(@"message-block");
    }
}

- (void)HandleMsgList:(NSString *)sessionUserName MsgList:(NSArray *)messages {
    %orig;
    if (![messages isKindOfClass:NSArray.class]) return;
    for (id message in messages) {
        if (NeoWCDeleteBlockedIncomingMessage(self, sessionUserName, message)) {
            NeoWCCompatibilityMarkTriggered(@"message-block");
        }
    }
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
    BOOL repeatBypass = NeoWCConsumeRepeatSendConfirmationBypass(message, 47, NO);
    if (repeatBypass) {
        %orig(message, wrap);
        return;
    }
    BOOL confirmationBypass = [objc_getAssociatedObject(wrap, &NeoWCSendConfirmationNativeBypassKey) boolValue];
    if (confirmationBypass) {
        objc_setAssociatedObject(wrap, &NeoWCSendConfirmationNativeBypassKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        UIViewController *confirmationPresenter = NeoWCSendConfirmationPresenterForTarget(message);
        if (confirmationPresenter) {
            NSString *retainedTarget = [message copy];
            CMessageWrap *retainedWrap = wrap;
            __weak typeof(self) weakManager = self;
            BOOL held = NeoWCPresentSendConfirmationIfNeeded(confirmationPresenter,
                                                              retainedTarget,
                                                              @"表情：1 个",
                                                              ^BOOL{
                return NeoWCSendConfirmationValidateTarget(retainedTarget);
            }, ^{
                id manager = weakManager;
                if (!manager) return;
                objc_setAssociatedObject(retainedWrap, &NeoWCSendConfirmationNativeBypassKey, @YES,
                                         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                ((void (*)(id, SEL, id, id))objc_msgSend)(manager,
                                                          @selector(AddEmoticonMsg:MsgWrap:),
                                                          retainedTarget,
                                                          retainedWrap);
            });
            if (held) return;
        }
    }
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

%hook MMNewSessionMgr

- (void)OnAddMsg:(NSString *)sessionUserName MsgWrap:(CMessageWrap *)wrap {
    if (NeoWCShouldBlockIncomingMessage(sessionUserName, wrap)) {
        NeoWCCompatibilityMarkTriggered(@"message-block");
        return;
    }
    %orig;
}

- (void)OnMsgNotAddDBNotify:(NSString *)sessionUserName MsgWrap:(CMessageWrap *)wrap {
    if (NeoWCShouldBlockIncomingMessage(sessionUserName, wrap)) {
        NeoWCCompatibilityMarkTriggered(@"message-block");
        return;
    }
    %orig;
}

%end

%hook CContactMgr

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
    id directContent = NeoWCTweakSafeValue(viewModel, @"m_nsContent");
    if ([directContent isKindOfClass:NSString.class]) return viewModel;
    for (NSString *key in @[@"getCurrentMessageWrap", @"currentMessageWrap",
                            @"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap",
                            @"message", @"m_message"]) {
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

static void NeoWCTriggerNativeTextRefresh(id cell) {
    if (!cell) return;
    SEL translateSelector = NSSelectorFromString(@"translateMsg");
    if (![cell respondsToSelector:translateSelector]) return;
    @try {
        ((void (*)(id, SEL))objc_msgSend)(cell, translateSelector);
    } @catch (NSException *exception) {
        (void)exception;
    }
}

%hook CommonMessageCellView

- (void)onHeadImageLongPressed:(id)sender {
    if (NeoWCPerformingNativeAvatarLongPress) {
        %orig(sender);
        return;
    }
    NSInteger mode = [NSUserDefaults.standardUserDefaults integerForKey:NeoWCAvatarQuickMenuGestureKey];
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCAvatarQuickMenuGestureKey) &&
                   mode == NeoWCAvatarQuickMenuGestureLongPress;
    if (enabled && self.window) {
        UIView *headView = NeoWCAvatarHeadViewForCell(self);
        if (!headView && [sender isKindOfClass:UIView.class]) headView = sender;
        if (!headView && [sender isKindOfClass:UIGestureRecognizer.class]) {
            headView = ((UIGestureRecognizer *)sender).view;
        }
        if (headView.window && NeoWCPresentAvatarQuickMenu(self, headView)) return;
    }
    %orig(sender);
}

- (void)setViewModel:(id)viewModel {
    id message = NeoWCMessageForCellViewModel(viewModel);
    NSString *wireText = NeoWCTweakSafeValue(message, @"m_nsContent");
    NSString *plainText = nil;
    BOOL textCell = [self isKindOfClass:NSClassFromString(@"TextMessageCellView")];
    if (textCell && NeoWCEnhancementEnabled(NeoWCEncryptedMessageEnabledKey) &&
        [wireText isKindOfClass:NSString.class] && NeoWCIsEncryptedTextWireString(wireText)) {
        NSString *manualPlainText = objc_getAssociatedObject(message, &NeoWCEncryptedTextManualPlainKey);
        if ([manualPlainText isKindOfClass:NSString.class] && manualPlainText.length > 0) {
            plainText = manualPlainText;
        } else if ([NSUserDefaults.standardUserDefaults boolForKey:NeoWCEncryptedMessageAutoDecryptKey]) {
            plainText = NeoWCDecryptTextWireString(wireText, nil);
        }
    }
    NSString *previousPlainText = objc_getAssociatedObject(self, &NeoWCEncryptedTextDisplayOverrideKey);
    if (![previousPlainText isEqualToString:plainText]) {
        objc_setAssociatedObject(self, &NeoWCEncryptedTextRefreshInFlightKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(self, &NeoWCEncryptedTextDisplayOverrideKey,
                             plainText.length > 0 ? plainText : nil,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (plainText.length > 0) {
        NeoWCTweakSetValue(message, @"m_nsContent", plainText);
        @try {
            %orig;
        } @finally {
            NeoWCTweakSetValue(message, @"m_nsContent", wireText);
        }
        // Updating the ordinary rich-text view is only an immediate visual
        // fallback.  WeChat rebuilds it during layout.  The durable PKC path
        // is the native translation view, so only that view counts as ready.
        NeoWCApplyDecryptedTextToCurrentCellViews(self, plainText);
        BOOL translated = NeoWCApplyDecryptedTextToTranslationView(self, plainText);
        BOOL refreshing = [objc_getAssociatedObject(self, &NeoWCEncryptedTextRefreshInFlightKey) boolValue];
        if (!translated && !refreshing) {
            objc_setAssociatedObject(self, &NeoWCEncryptedTextRefreshInFlightKey, @YES,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            NeoWCTriggerNativeTextRefresh(self);
            __weak CommonMessageCellView *weakCell = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                CommonMessageCellView *cell = weakCell;
                if (cell) objc_setAssociatedObject(cell, &NeoWCEncryptedTextRefreshInFlightKey, nil,
                                                   OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            });
        }
        NeoWCCompatibilityMarkTriggered(@"encrypted-text-display");
    } else {
        objc_setAssociatedObject(self, &NeoWCEncryptedTextRefreshInFlightKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        %orig;
        // Some WeChat builds do not expose the wrap through the incoming view
        // model.  After the native binding completes, resolve it from the real
        // cell exactly as PKC does and start the same translation refresh.
        if (textCell) {
            NSString *boundPlainText = NeoWCDecryptedPlainTextForCell(self);
            if (boundPlainText.length > 0) {
                objc_setAssociatedObject(self, &NeoWCEncryptedTextDisplayOverrideKey,
                                         boundPlainText, OBJC_ASSOCIATION_COPY_NONATOMIC);
                NeoWCApplyDecryptedTextToCurrentCellViews(self, boundPlainText);
                BOOL translated = NeoWCApplyDecryptedTextToTranslationView(self, boundPlainText);
                if (!translated) {
                    objc_setAssociatedObject(self, &NeoWCEncryptedTextRefreshInFlightKey, @YES,
                                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    NeoWCTriggerNativeTextRefresh(self);
                }
                NeoWCCompatibilityMarkTriggered(@"encrypted-text-display");
            }
        }
    }
    NeoWCHideMessageTimeLabels(self);
    NeoWCScheduleMessageTimeRefresh(self);
    NeoWCSynchronizeReplyGesture(self);
    NeoWCSynchronizeAvatarQuickGesture(self);
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
    NeoWCSynchronizeAvatarQuickGesture(self);
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
        objc_setAssociatedObject(self,
                                 &NeoWCReplyTransformSnapshotsKey,
                                 NeoWCReplyTransformSnapshots(self),
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
    NSArray<NeoWCReplyTransformSnapshot *> *snapshots = objc_getAssociatedObject(self, &NeoWCReplyTransformSnapshotsKey);

    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat distance = MAX(0.0, rightward ? translation.x : -translation.x);
        if (distance > triggerDistance) {
            distance = triggerDistance + MIN(10.0, (distance - triggerDistance) * 0.18);
        }
        CGFloat offset = rightward ? distance : -distance;
        if (snapshots.count) NeoWCApplyReplyTransform(snapshots, offset);
        else self.transform = CGAffineTransformTranslate(originalTransform, offset, 0.0);
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
                         if (snapshots.count) NeoWCRestoreReplyTransforms(snapshots);
                         else weakCell.transform = originalTransform;
                     }
                     completion:^(BOOL finished) {
                         (void)finished;
                          CommonMessageCellView *cell = weakCell;
                          if (!cell) return;
                          objc_setAssociatedObject(cell, &NeoWCReplyOriginalTransformKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                          objc_setAssociatedObject(cell, &NeoWCReplyTransformSnapshotsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    UIColor *promptColor = NeoWCDynamicColorForDefaultsKeys(NeoWCAntiRevokeSideLightTextColorKey,
                                                            NeoWCAntiRevokeSideDarkTextColorKey,
                                                            NeoWCAntiRevokeSideTextColorKey,
                                                            UIColor.tertiaryLabelColor,
                                                            UIColor.tertiaryLabelColor);
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
        ? NeoWCDynamicColorForDefaultsKeys(NeoWCAntiRevokeLocalLightTextColorKey,
                                           NeoWCAntiRevokeLocalDarkTextColorKey,
                                           NeoWCAntiRevokeLocalTextColorKey,
                                           UIColor.secondaryLabelColor,
                                           UIColor.secondaryLabelColor)
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
        NeoWCShowTransientHUD(@"已自动确认设备登录", @"desktopcomputer");
    });
}

%end

static id (*NeoWCOriginalRedEnvelopeInitWithData)(id, SEL, id) = NULL;
static id (*NeoWCOriginalRedEnvelopeInitWithDataSceneType)(id, SEL, id, NSUInteger, NSUInteger) = NULL;
static void (*NeoWCOriginalRedEnvelopeSetupWithData)(id, SEL, id) = NULL;
static void (*NeoWCOriginalRedEnvelopeRefreshWithData)(id, SEL, id) = NULL;
static NSInteger (*NeoWCOriginalRedEnvelopeSetupCurrentMode)(id, SEL) = NULL;
static void (*NeoWCOriginalRedEnvelopeViewDidLoad)(id, SEL) = NULL;

static void NeoWCApplyExclusiveRedEnvelopeContact(id controller, id data) {
    id contact = objc_getAssociatedObject(data, &NeoWCExclusiveRedEnvelopeContactKey);
    if (!controller || !data || !contact) return;
    objc_setAssociatedObject(controller, &NeoWCExclusiveRedEnvelopeViewContactKey,
                             contact, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(controller, &NeoWCExclusiveRedEnvelopeViewDataKey,
                             data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    SEL selector = NSSelectorFromString(@"setSelectedMemberContact:");
    if ([data respondsToSelector:selector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(data, selector, contact);
    }
}

static BOOL NeoWCRedEnvelopeControllerIsExclusive(id controller) {
    SEL selector = NSSelectorFromString(@"isExclusiveHbMode");
    return [controller respondsToSelector:selector] &&
           ((BOOL (*)(id, SEL))objc_msgSend)(controller, selector);
}

static void NeoWCSetRedEnvelopeControllerMode(id controller, NSInteger mode) {
    SEL selector = NSSelectorFromString(@"setCurrentMode:");
    if ([controller respondsToSelector:selector]) {
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(controller, selector, mode);
    }
}

static void NeoWCSetExclusiveRedEnvelopeData(id data, id contact, NSInteger mode) {
    SEL modeSelector = NSSelectorFromString(@"setCurrentLaunchRedEnvMode:");
    if ([data respondsToSelector:modeSelector]) {
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(data, modeSelector, mode);
    }
    SEL contactSelector = NSSelectorFromString(@"setSelectedMemberContact:");
    if ([data respondsToSelector:contactSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(data, contactSelector, contact);
    }
}

static NSInteger NeoWCSelectExclusiveRedEnvelopeMode(id controller,
                                                      NSInteger originalMode,
                                                      BOOL reloadContent) {
    id contact = objc_getAssociatedObject(controller, &NeoWCExclusiveRedEnvelopeViewContactKey);
    id data = objc_getAssociatedObject(controller, &NeoWCExclusiveRedEnvelopeViewDataKey);
    if (!contact || !data) return originalMode;
    if (reloadContent && NeoWCRedEnvelopeControllerIsExclusive(controller)) return originalMode;

    for (NSInteger mode = 0; mode < 9; mode++) {
        NeoWCSetRedEnvelopeControllerMode(controller, mode);
        if (!NeoWCRedEnvelopeControllerIsExclusive(controller)) continue;
        NeoWCSetRedEnvelopeControllerMode(controller, mode);
        NeoWCSetExclusiveRedEnvelopeData(data, contact, mode);
        if (reloadContent) {
            SEL reloadSelector = NSSelectorFromString(@"reloadContentView");
            if ([controller respondsToSelector:reloadSelector]) {
                ((void (*)(id, SEL))objc_msgSend)(controller, reloadSelector);
            }
        }
        return mode;
    }
    if (!reloadContent) NeoWCSetRedEnvelopeControllerMode(controller, originalMode);
    return originalMode;
}

static id NeoWCRedEnvelopeInitWithData(id self, SEL command, id data) {
    NeoWCPrepareExclusiveRedEnvelopeData(data);
    return NeoWCOriginalRedEnvelopeInitWithData
        ? NeoWCOriginalRedEnvelopeInitWithData(self, command, data) : nil;
}

static id NeoWCRedEnvelopeInitWithDataSceneType(id self,
                                                SEL command,
                                                id data,
                                                NSUInteger scene,
                                                NSUInteger type) {
    NeoWCPrepareExclusiveRedEnvelopeData(data);
    return NeoWCOriginalRedEnvelopeInitWithDataSceneType
        ? NeoWCOriginalRedEnvelopeInitWithDataSceneType(self, command, data, scene, type) : nil;
}

static void NeoWCRedEnvelopeSetupWithData(id self, SEL command, id data) {
    NeoWCApplyExclusiveRedEnvelopeContact(self, data);
    if (NeoWCOriginalRedEnvelopeSetupWithData) {
        NeoWCOriginalRedEnvelopeSetupWithData(self, command, data);
    }
}

static void NeoWCRedEnvelopeRefreshWithData(id self, SEL command, id data) {
    NeoWCApplyExclusiveRedEnvelopeContact(self, data);
    if (NeoWCOriginalRedEnvelopeRefreshWithData) {
        NeoWCOriginalRedEnvelopeRefreshWithData(self, command, data);
    }
}

static NSInteger NeoWCRedEnvelopeSetupCurrentMode(id self, SEL command) {
    NSInteger originalMode = NeoWCOriginalRedEnvelopeSetupCurrentMode
        ? NeoWCOriginalRedEnvelopeSetupCurrentMode(self, command) : 0;
    return NeoWCSelectExclusiveRedEnvelopeMode(self, originalMode, NO);
}

static void NeoWCRedEnvelopeViewDidLoad(id self, SEL command) {
    if (NeoWCOriginalRedEnvelopeViewDidLoad) NeoWCOriginalRedEnvelopeViewDidLoad(self, command);
    (void)NeoWCSelectExclusiveRedEnvelopeMode(self, 0, YES);
}

static const char *NeoWCUnqualifiedMethodType(const char *type) {
    if (!type) return "";
    while (*type && strchr("rnNoORV", *type)) type++;
    return type;
}

static BOOL NeoWCMethodReturnsVoid(Method method) {
    char *type = method ? method_copyReturnType(method) : NULL;
    BOOL matches = type && strcmp(NeoWCUnqualifiedMethodType(type), @encode(void)) == 0;
    if (type) free(type);
    return matches;
}

static BOOL NeoWCMethodArgumentIsObject(Method method, unsigned int index) {
    char *type = method ? method_copyArgumentType(method, index) : NULL;
    BOOL matches = NeoWCUnqualifiedMethodType(type)[0] == '@';
    if (type) free(type);
    return matches;
}

static BOOL NeoWCMethodArgumentIsSelector(Method method, unsigned int index) {
    char *type = method ? method_copyArgumentType(method, index) : NULL;
    BOOL matches = type && strcmp(NeoWCUnqualifiedMethodType(type), @encode(SEL)) == 0;
    if (type) free(type);
    return matches;
}

static BOOL NeoWCMethodReturnsObject(Method method) {
    char *type = method ? method_copyReturnType(method) : NULL;
    BOOL matches = NeoWCUnqualifiedMethodType(type)[0] == '@';
    if (type) free(type);
    return matches;
}

static BOOL NeoWCMethodTypeIsInteger(const char *type) {
    const char value = NeoWCUnqualifiedMethodType(type)[0];
    return value && strchr("cCsSiIlLqQB", value) != NULL;
}

static BOOL NeoWCMethodReturnsInteger(Method method) {
    char *type = method ? method_copyReturnType(method) : NULL;
    BOOL matches = NeoWCMethodTypeIsInteger(type);
    if (type) free(type);
    return matches;
}

static BOOL NeoWCMethodArgumentIsInteger(Method method, unsigned int index) {
    char *type = method ? method_copyArgumentType(method, index) : NULL;
    BOOL matches = NeoWCMethodTypeIsInteger(type);
    if (type) free(type);
    return matches;
}

static void NeoWCInstallExclusiveRedEnvelopeHooks(void) {
    Class logicClass = NSClassFromString(@"WCRedEnvelopesSendControlLogic");
    if (logicClass) {
        SEL selector = NSSelectorFromString(@"initWithData:");
        Method method = class_getInstanceMethod(logicClass, selector);
        if (method && method_getNumberOfArguments(method) == 3 &&
            NeoWCMethodReturnsObject(method) && NeoWCMethodArgumentIsObject(method, 2)) {
            IMP original = NULL;
            MSHookMessageEx(logicClass, selector, (IMP)NeoWCRedEnvelopeInitWithData, &original);
            NeoWCOriginalRedEnvelopeInitWithData =
                (id (*)(id, SEL, id))original;
        }

        selector = NSSelectorFromString(@"initWithData:Scene:RedEnvelopesType:");
        method = class_getInstanceMethod(logicClass, selector);
        if (method && method_getNumberOfArguments(method) == 5 &&
            NeoWCMethodReturnsObject(method) && NeoWCMethodArgumentIsObject(method, 2) &&
            NeoWCMethodArgumentIsInteger(method, 3) && NeoWCMethodArgumentIsInteger(method, 4)) {
            IMP original = NULL;
            MSHookMessageEx(logicClass, selector,
                            (IMP)NeoWCRedEnvelopeInitWithDataSceneType, &original);
            NeoWCOriginalRedEnvelopeInitWithDataSceneType =
                (id (*)(id, SEL, id, NSUInteger, NSUInteger))original;
        }
    }

    Class controllerClass = NSClassFromString(@"WCRedEnvelopesMakeRedEnvelopesViewController");
    if (!controllerClass) return;

    SEL selector = NSSelectorFromString(@"setupWithData:");
    Method method = class_getInstanceMethod(controllerClass, selector);
    if (method && method_getNumberOfArguments(method) == 3 &&
        NeoWCMethodReturnsVoid(method) && NeoWCMethodArgumentIsObject(method, 2)) {
        IMP original = NULL;
        MSHookMessageEx(controllerClass, selector, (IMP)NeoWCRedEnvelopeSetupWithData, &original);
        NeoWCOriginalRedEnvelopeSetupWithData = (void (*)(id, SEL, id))original;
    }

    selector = NSSelectorFromString(@"refreshViewWithData:");
    method = class_getInstanceMethod(controllerClass, selector);
    if (method && method_getNumberOfArguments(method) == 3 &&
        NeoWCMethodReturnsVoid(method) && NeoWCMethodArgumentIsObject(method, 2)) {
        IMP original = NULL;
        MSHookMessageEx(controllerClass, selector, (IMP)NeoWCRedEnvelopeRefreshWithData, &original);
        NeoWCOriginalRedEnvelopeRefreshWithData = (void (*)(id, SEL, id))original;
    }

    selector = NSSelectorFromString(@"setupCurrentMode");
    method = class_getInstanceMethod(controllerClass, selector);
    if (method && method_getNumberOfArguments(method) == 2 && NeoWCMethodReturnsInteger(method)) {
        IMP original = NULL;
        MSHookMessageEx(controllerClass, selector, (IMP)NeoWCRedEnvelopeSetupCurrentMode, &original);
        NeoWCOriginalRedEnvelopeSetupCurrentMode = (NSInteger (*)(id, SEL))original;
    }

    selector = NSSelectorFromString(@"viewDidLoad");
    method = class_getInstanceMethod(controllerClass, selector);
    if (method && method_getNumberOfArguments(method) == 2 && NeoWCMethodReturnsVoid(method)) {
        IMP original = NULL;
        MSHookMessageEx(controllerClass, selector, (IMP)NeoWCRedEnvelopeViewDidLoad, &original);
        NeoWCOriginalRedEnvelopeViewDidLoad = (void (*)(id, SEL))original;
    }
}

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

%ctor {
    %init;
    NeoWCMomentsCommentAntiDeleteInstallHooks();
    NeoWCInstallExclusiveRedEnvelopeHooks();
    if ([CADisplayLink instancesRespondToSelector:@selector(setPreferredFrameRateRange:)]) {
        %init(NeoWCHighRefreshRateRange);
    }
}
