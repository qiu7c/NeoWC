#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NeoWCSettingsCategory) {
    NeoWCSettingsCategoryRoot,
    NeoWCSettingsCategoryMessages,
    NeoWCSettingsCategoryMoments,
    NeoWCSettingsCategoryInterfaceDisabled,
    NeoWCSettingsCategoryEnhancements,
    NeoWCSettingsCategoryInterface,
    NeoWCSettingsCategoryPlugin,
};

typedef NS_ENUM(NSInteger, NeoWCSettingRowKind) {
    NeoWCSettingRowKindSwitch,
    NeoWCSettingRowKindDetail,
    NeoWCSettingRowKindInfo,
    NeoWCSettingRowKindCopy,
};

typedef NS_ENUM(NSInteger, NeoWCSettingAction) {
    NeoWCSettingActionNone,
    NeoWCSettingActionOpenMessages,
    NeoWCSettingActionOpenMoments,
    NeoWCSettingActionOpenInterfaceDisabled,
    NeoWCSettingActionOpenEnhancements,
    NeoWCSettingActionOpenInterface,
    NeoWCSettingActionOpenPlugin,
    NeoWCSettingActionConfigManager,
    NeoWCSettingActionAuthorProfile,
    NeoWCSettingActionFindFriend,
    NeoWCSettingActionOpenChatByID,
    NeoWCSettingActionFriendRelationCheck,
    NeoWCSettingActionReleaseNotes,
    NeoWCSettingActionLogRecords,
    NeoWCSettingActionBlockUsers,
    NeoWCSettingActionBlockKeywords,
    NeoWCSettingActionLongPressMenus,
    NeoWCSettingActionMeMenu,
    NeoWCSettingActionRevokePromptStyle,
    NeoWCSettingActionRevokeAppearance,
    NeoWCSettingActionRevokeRecords,
    NeoWCSettingActionRevokeFilter,
    NeoWCSettingActionRevokeLocalTemplate,
    NeoWCSettingActionRevokeReplyTemplate,
    NeoWCSettingActionGlobalScale,
    NeoWCSettingActionSettingsScale,
    NeoWCSettingActionInnerRadius,
    NeoWCSettingActionOuterRadius,
    NeoWCSettingActionMomentsDateFormat,
    NeoWCSettingActionMessageTimeFormat,
    NeoWCSettingActionMessageTimeFontSize,
    NeoWCSettingActionMessageTimeMode,
    NeoWCSettingActionMessageTimeColor,
    NeoWCSettingActionMessageTimePosition,
    NeoWCSettingActionMessageTimeAvatarSpacing,
    NeoWCSettingActionPluginManager,
    NeoWCSettingActionHapticIntensity,
    NeoWCSettingActionStepMode,
    NeoWCSettingActionFixedSteps,
    NeoWCSettingActionRandomStepRange,
    NeoWCSettingActionRegenerateRandomSteps,
    NeoWCSettingActionWalletBalance,
    NeoWCSettingActionContactsCount,
    NeoWCSettingActionRedEnvelopeFontSize,
    NeoWCSettingActionChatTopAvatarSize,
    NeoWCSettingActionChatTopNicknameSize,
    NeoWCSettingActionChatGlassStyle,
    NeoWCSettingActionChatGlassBlurIntensity,
    NeoWCSettingActionMessageGestureAction,
    NeoWCSettingActionAvatarQuickMenuGesture,
    NeoWCSettingActionReplySwipeTriggerDistance,
    NeoWCSettingActionGlobalAvatarCornerPercent,
    NeoWCSettingActionQuickReplyLibrary,
    NeoWCSettingActionSendConfirmationConversations,
    NeoWCSettingActionSendConfirmationPauseDuration,
    NeoWCSettingActionMomentsReminderUsers,
    NeoWCSettingActionMomentsReminderInterval,
    NeoWCSettingActionMomentsReminderForwardTarget,
    NeoWCSettingActionMomentsCommentAntiDeleteText,
    NeoWCSettingActionMomentsCommentAntiDeleteFontSize,
    NeoWCSettingActionInAppNotificationAppearance,
};

@interface NeoWCSettingItem : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *subtitle;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy, nullable) NSString *defaultsKey;
@property (nonatomic, copy, nullable) NSString *value;
@property (nonatomic, assign) NeoWCSettingRowKind kind;
@property (nonatomic, assign) NeoWCSettingAction action;
@property (nonatomic, assign) BOOL hasChildren;
@property (nonatomic, assign) BOOL child;
+ (instancetype)itemWithIdentifier:(NSString *)identifier
                              title:(NSString *)title
                           subtitle:(nullable NSString *)subtitle
                             symbol:(NSString *)symbol
                               kind:(NeoWCSettingRowKind)kind
                                key:(nullable NSString *)key
                              value:(nullable NSString *)value
                             action:(NeoWCSettingAction)action;
@end

@interface NeoWCSettingSection : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *footer;
@property (nonatomic, copy) NSArray<NeoWCSettingItem *> *items;
+ (instancetype)sectionWithIdentifier:(NSString *)identifier
                                  title:(nullable NSString *)title
                                 footer:(nullable NSString *)footer
                                  items:(NSArray<NeoWCSettingItem *> *)items;
@end

NS_ASSUME_NONNULL_END
