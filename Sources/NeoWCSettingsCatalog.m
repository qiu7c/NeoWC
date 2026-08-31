#import "NeoWCSettingsCatalog.h"
#import "NeoWCAntiRevoke.h"
#import "NeoWCEnhancements.h"
#import "NeoWCInterfaceTweaks.h"
#import "NeoWCLogging.h"
#import "NeoWCQuickReplyStore.h"
#import "NeoWCMessageBlock.h"
#import "NeoWCSendConfirmation.h"
#import "NeoWCBackgroundKeeper.h"
#import "NeoWCMomentsInteractionReminder.h"
#import "NeoWCMomentsReminder.h"
#import "NeoWCInAppNotification.h"
#import <stdlib.h>

NSString *const NeoWCEnabledKey = @"com.qiu7c.neowc.enabled";
NSString *const NeoWCCollapsedFeaturesKey = @"com.qiu7c.neowc.ui.collapsed-features";
static NSString *const NeoWCExpandedCategoriesKey = @"com.qiu7c.neowc.ui.expanded-categories";

NSString *const NeoWCDisplayVersion = @"0.1.7";

static NeoWCSettingItem *NeoWCItem(NSString *title, NSString *subtitle, NSString *symbol,
                                  NeoWCSettingRowKind kind, NSString *key, NSString *value,
                                  NeoWCSettingAction action) {
    NSString *identifier = key.length > 0 ? key : [NSString stringWithFormat:@"action-%ld", (long)action];
    return [NeoWCSettingItem itemWithIdentifier:identifier title:title subtitle:subtitle symbol:symbol
                                           kind:kind key:key value:value action:action];
}

static void NeoWCAddFeature(NSMutableArray<NeoWCSettingItem *> *items,
                            NeoWCSettingItem *parent,
                            NSArray<NeoWCSettingItem *> *children,
                            NSUserDefaults *defaults,
                            NSSet<NSString *> *collapsedFeatureKeys) {
    parent.hasChildren = children.count > 0;
    [items addObject:parent];
    if (parent.defaultsKey.length > 0 && [defaults boolForKey:parent.defaultsKey] &&
        ![collapsedFeatureKeys containsObject:parent.defaultsKey]) {
        for (NeoWCSettingItem *child in children) child.child = YES;
        [items addObjectsFromArray:children];
    }
}

static NSString *NeoWCCountText(NSUInteger count) {
    return count > 0 ? [NSString stringWithFormat:@"%lu 项", (unsigned long)count] : @"设置";
}

static NSString *NeoWCCurrentSelection(NSString *value) {
    return [NSString stringWithFormat:@"当前选择：%@", value ?: @"未设置"];
}

static NSString *NeoWCSendConfirmationPauseDurationText(NSInteger seconds) {
    seconds = seconds > 0 ? seconds : 60;
    return seconds % 60 == 0 ? [NSString stringWithFormat:@"%ld 分钟", (long)(seconds / 60)] :
                               [NSString stringWithFormat:@"%ld 秒", (long)seconds];
}

static long long NeoWCLongLongForKey(NSString *key) {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:key];
    return [value respondsToSelector:@selector(longLongValue)] ? [value longLongValue] : 0;
}

void NeoWCSettingsRegenerateDailyStepTarget(NSUserDefaults *defaults) {
    NeoWCStepMode mode = (NeoWCStepMode)[defaults integerForKey:NeoWCStepModeKey];
    NSInteger target = 0;
    if (mode == NeoWCStepModeDailyRandom) {
        NSInteger minimum = MIN(100000, MAX(1, [defaults integerForKey:NeoWCStepRandomMinimumKey]));
        NSInteger maximum = MIN(100000, MAX(minimum, [defaults integerForKey:NeoWCStepRandomMaximumKey]));
        target = minimum + (NSInteger)arc4random_uniform((uint32_t)(maximum - minimum + 1));
    } else {
        target = MIN(100000, MAX(0, [defaults integerForKey:NeoWCStepCountKey]));
    }
    if (target > 0) {
        [defaults setInteger:target forKey:NeoWCStepDailyTargetKey];
        [defaults setObject:NSDate.date forKey:NeoWCStepCountDateKey];
    } else {
        [defaults removeObjectForKey:NeoWCStepDailyTargetKey];
        [defaults removeObjectForKey:NeoWCStepCountDateKey];
    }
}

void NeoWCSettingsHandleSwitchChange(NSString *key, BOOL enabled) {
    if (key.length == 0) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([key isEqualToString:NeoWCStepOverrideEnabledKey] && enabled) {
        NeoWCSettingsRegenerateDailyStepTarget(defaults);
    }
    if ([key isEqualToString:NeoWCAntiRevokePersistRecordsKey]) {
        NeoWCAntiRevokeSetPersistenceEnabled(enabled);
    }
    if ([key hasPrefix:@"com.qiu7c.neowc."]) {
        [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification object:key];
    }
    if ([key isEqualToString:NeoWCAntiRevokeKey]) {
        [NSNotificationCenter.defaultCenter postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    }
    if ([key isEqualToString:NeoWCBackgroundKeepAliveEnabledKey]) {
        NeoWCBackgroundKeeperSettingsDidChange();
    }
    if ([key isEqualToString:NeoWCMomentsInteractionReminderEnabledKey]) {
        NeoWCMomentsInteractionReminderSettingsDidChange();
    }
    if ([key isEqualToString:NeoWCMomentsReminderEnabledKey] ||
        [key isEqualToString:NeoWCMomentsReminderUsersKey] ||
        [key isEqualToString:NeoWCMomentsReminderIntervalKey] ||
        [key isEqualToString:NeoWCMomentsReminderForwardEnabledKey] ||
        [key isEqualToString:NeoWCMomentsReminderForwardTargetKey] ||
        [key isEqualToString:NeoWCMomentsReminderForwardImagesKey] ||
        [key isEqualToString:NeoWCMomentsReminderForwardVideosKey]) {
        NeoWCMomentsReminderSettingsDidChange();
    }
}

void NeoWCSettingsRegisterDefaults(void) {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"com.qiu7c.neowc.chat.top-bar-capsule.effect-style"];
    [NSUserDefaults.standardUserDefaults registerDefaults:@{
        NeoWCEnabledKey: @YES,
        NeoWCAntiRevokeKey: @YES,
        NeoWCAntiRevokeNotifySenderKey: @NO,
        NeoWCAntiRevokeTimeFilterKey: @300.0,
        NeoWCAntiRevokePromptStyleKey: @0,
        NeoWCAntiRevokeSideTextKey: @"已拦截撤回",
        NeoWCAntiRevokeSideOffsetXKey: @0.0,
        NeoWCAntiRevokeSideOffsetYKey: @10.0,
        NeoWCAntiRevokePersistRecordsKey: @NO,
        NeoWCImageEditQuickSendEnabledKey: @NO,
        NeoWCMediaToVoiceEnabledKey: @YES,
        NeoWCAudioFileToVoiceEnabledKey: @YES,
        NeoWCVideoToVoiceEnabledKey: @YES,
        NeoWCMusicToVoiceEnabledKey: @YES,
        NeoWCChatJokerEnabledKey: @NO,
        NeoWCChatMessageTimeEnabledKey: @NO,
        NeoWCChatMessageTimeBelowAvatarKey: @YES,
        NeoWCChatMessageTimeBubbleSideKey: @NO,
        NeoWCChatMessageTimeFormatKey: @"MM-dd HH:mm:ss",
        NeoWCChatMessageTimeFontSizeKey: @10.0,
        NeoWCChatMessageTimeColorKey: @"#8E8E93FF",
        NeoWCChatMessageTimeBubbleVerticalPositionKey: @2,
        NeoWCChatMessageTimeAvatarSpacingKey: @-2.0,
        NeoWCChatMessageTimeBoldKey: @NO,
        NeoWCEmoticonToSelfieEnabledKey: @NO,
        NeoWCMomentsForwardEnabledKey: @NO,
        NeoWCMomentsSaveImagesEnabledKey: @NO,
        NeoWCMomentsOriginalMediaPostEnabledKey: @NO,
        NeoWCReplySwipeEnabledKey: @NO,
        NeoWCReplySwipeSelfActionKey: @(NeoWCReplySwipeActionQuote),
        NeoWCReplySwipeOtherActionKey: @(NeoWCReplySwipeActionQuote),
        NeoWCReplySwipeRightSelfActionKey: @(NeoWCReplySwipeActionNone),
        NeoWCReplySwipeRightOtherActionKey: @(NeoWCReplySwipeActionNone),
        NeoWCReplySwipeTriggerDistanceKey: @56.0,
        NeoWCMessageDoubleTapSelfActionKey: @(NeoWCReplySwipeActionNone),
        NeoWCMessageDoubleTapOtherActionKey: @(NeoWCReplySwipeActionNone),
        NeoWCMessageTripleTapSelfActionKey: @(NeoWCReplySwipeActionNone),
        NeoWCMessageTripleTapOtherActionKey: @(NeoWCReplySwipeActionNone),
        NeoWCAvatarQuickMenuGestureKey: @(NeoWCAvatarQuickMenuGestureOff),
        NeoWCQuoteJumpEnabledKey: @NO,
        NeoWCQuoteJumpImageEnabledKey: @YES,
        NeoWCQuoteJumpVideoEnabledKey: @YES,
        NeoWCChatSearchButtonEnabledKey: @NO,
        NeoWCChatTopBarCapsuleEnabledKey: @NO,
        NeoWCChatGlassStyleKey: @0,
        NeoWCChatGlassBlurIntensityKey: @100.0,
        NeoWCChatTopBarAvatarSizeKey: @30.0,
        NeoWCChatTopBarNicknameSizeKey: @15.0,
        NeoWCMessageBlockEnabledKey: @NO,
        NeoWCMessageBlockUsersKey: @[],
        NeoWCMessageBlockKeywordsKey: @[],
        NeoWCMessageBlockRulesKey: @{},
        NeoWCMessageBlockProfileSwitchEnabledKey: @YES,
        NeoWCSendConfirmationProfileSwitchEnabledKey: @YES,
        NeoWCLongPressMenuEnabledKey: @NO,
        NeoWCLongPressMenuHiddenTitlesKey: @[],
        NeoWCLongPressMenuPreferredOrderKey: @[],
        NeoWCLongPressMenuTitleMapKey: @{},
        NeoWCLongPressMenuManualTitlesKey: @[],
        NeoWCGroupMemberReminderEnabledKey: @NO,
        NeoWCRedEnvelopeDetailEnabledKey: @NO,
        NeoWCRedEnvelopeDetailCenterKey: @NO,
        NeoWCRedEnvelopeDetailFontSizeKey: @14.0,
        NeoWCCallConfirmEnabledKey: @NO,
        NeoWCAutoSpeakerphoneEnabledKey: @NO,
        NeoWCQRCodeCameraSourceEnabledKey: @NO,
        NeoWCAutoOriginalImageEnabledKey: @NO,
        NeoWCAutoCombineSendEnabledKey: @NO,
        NeoWCNotificationDirectChatEnabledKey: @NO,
        NeoWCWalletBalanceEnabledKey: @NO,
        NeoWCWalletBalanceFenKey: @0,
        NeoWCContactsCountEnabledKey: @NO,
        NeoWCContactsCountKey: @0,
        NeoWCStepModeKey: @(NeoWCStepModeDailyFixed),
        NeoWCStepRandomMinimumKey: @5000,
        NeoWCStepRandomMaximumKey: @10000,
        NeoWCStepGradualEnabledKey: @NO,
        NeoWCStepDailyTargetKey: @0,
        NeoWCMeMenuKnownTitlesKey: @[],
        NeoWCMeMenuHiddenTitlesKey: @[],
        NeoWCAutoVoiceTranscriptionEnabledKey: @NO,
        NeoWCVoiceForwardEnabledKey: @NO,
        NeoWCAutoVoiceTranscriptionIgnoreGroupKey: @NO,
        NeoWCAutoVoiceTranscriptionIgnorePrivateKey: @NO,
        NeoWCAutoVoiceTranscriptionIgnoreSelfKey: @YES,
        NeoWCMultiSelectLimitEnabledKey: @NO,
        NeoWCShowRawContactIDEnabledKey: @NO,
        NeoWCHomeSwipeActionsEnabledKey: @NO,
        NeoWCHideScreenshotForwardKey: @NO,
        NeoWCInputSwipeActionsEnabledKey: @NO,
        NeoWCQuickReplyEnabledKey: @NO,
        NeoWCQuickReplyInstantSendEnabledKey: @NO,
        NeoWCSendConfirmationEnabledKey: @NO,
        NeoWCSendConfirmationUsersKey: @{},
        NeoWCSendConfirmationPauseSecondsKey: @60,
        NeoWCMomentsLikeHapticEnabledKey: @NO,
        NeoWCMomentsLikeHapticIntensityKey: @0.65,
        NeoWCMomentsQuickPermissionsKey: @NO,
        NeoWCMomentsPreciseTimeKey: @NO,
        NeoWCMomentsPreciseTimeFormatKey: NeoWCMomentsPreciseTimeDefaultFormat,
        NeoWCBackgroundKeepAliveEnabledKey: @NO,
        NeoWCMomentsInteractionReminderEnabledKey: @NO,
        NeoWCMomentsInteractionReminderDetailsEnabledKey: @YES,
        NeoWCMomentsCommentAntiDeleteEnabledKey: @NO,
        NeoWCMomentsCommentAntiDeleteTextKey: @"←该评论已删除",
        NeoWCMomentsCommentAntiDeleteFontSizeKey: @12.0,
        NeoWCMomentsCommentAntiDeleteColorKey: @"#8E8E93FF",
        NeoWCMomentsReminderEnabledKey: @NO,
        NeoWCMomentsReminderUsersKey: @[],
        NeoWCMomentsReminderIntervalKey: @60,
        NeoWCMomentsReminderForwardEnabledKey: @NO,
        NeoWCMomentsReminderForwardTargetKey: @0,
        NeoWCMomentsReminderForwardImagesKey: @NO,
        NeoWCMomentsReminderForwardVideosKey: @NO,
        NeoWCPageScaleEnabledKey: @NO,
        NeoWCPageScaleGlobalPercentKey: @100.0,
        NeoWCSettingsPageScalePercentKey: @100.0,
        NeoWCMultiSelectExportEnabledKey: @NO,
        NeoWCMultiSelectExportTextKey: @YES,
        NeoWCMultiSelectSaveImagesKey: @YES,
        NeoWCMultiSelectShareCardKey: @YES,
        NeoWCLoggingEnabledKey: @YES,
        NeoWCChatInputRoundingEnabledKey: @NO,
        NeoWCChatInputInnerRoundingKey: @YES,
        NeoWCChatInputOuterRoundingKey: @YES,
        NeoWCChatInputInnerRadiusKey: @18.0,
        NeoWCChatInputOuterRadiusKey: @22.0,
        NeoWCHideChatMuteIconKey: @NO,
        NeoWCScrollHighRefreshRateEnabledKey: @NO,
        NeoWCGlobalAvatarRoundingEnabledKey: @NO,
        NeoWCGlobalAvatarCornerPercentKey: @100.0,
        NeoWCInAppNotificationSymbolKey: @"automatic",
        NeoWCInAppNotificationHeightKey: @60.0,
        NeoWCInAppNotificationBlurIntensityKey: @0.85,
        NeoWCExpandedCategoriesKey: @[@"messages"],
        NeoWCCollapsedFeaturesKey: @[],
    }];
}

static NSArray<NeoWCSettingSection *> *NeoWCRootSections(void) {
    return @[
        [NeoWCSettingSection sectionWithIdentifier:@"master" title:nil
                                             footer:@"关闭后仅保留设置入口，所有增强功能停止生效。"
                                              items:@[NeoWCItem(@"启用 NeoWC", @"插件功能总开关", @"power", NeoWCSettingRowKindSwitch, NeoWCEnabledKey, nil, NeoWCSettingActionNone)]],
        [NeoWCSettingSection sectionWithIdentifier:@"categories" title:@"功能"
                                             footer:nil items:@[
            NeoWCItem(@"聊天增强", @"消息、编辑、提醒与导出", @"bubble.left.and.bubble.right", NeoWCSettingRowKindDetail, nil, nil, NeoWCSettingActionOpenMessages),
            NeoWCItem(@"朋友圈增强", @"提醒、互动、发布和媒体操作", @"photo.on.rectangle.angled", NeoWCSettingRowKindDetail, nil, nil, NeoWCSettingActionOpenMoments),
            NeoWCItem(@"界面禁用", @"隐藏不需要的界面元素和广告", @"eye.slash", NeoWCSettingRowKindDetail, nil, nil, NeoWCSettingActionOpenInterfaceDisabled),
            NeoWCItem(@"界面优化", @"头像、胶囊、缩放与输入栏样式", @"paintbrush", NeoWCSettingRowKindDetail, nil, nil, NeoWCSettingActionOpenInterface),
            NeoWCItem(@"常用增强", @"自动化、扫码、资料和本地显示", @"bolt", NeoWCSettingRowKindDetail, nil, nil, NeoWCSettingActionOpenEnhancements),
            NeoWCItem(@"插件设置", @"通知样式、日志、配置与插件入口", @"gearshape.2", NeoWCSettingRowKindDetail, nil, nil, NeoWCSettingActionOpenPlugin),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"about" title:@"关于"
                                             footer:[NSString stringWithFormat:@"NeoWC · %@", NeoWCDisplayVersion]
                                              items:@[
            NeoWCItem(@"作者主页", @"在微信中查看作者资料", @"person.crop.circle", NeoWCSettingRowKindDetail, nil, @"查看", NeoWCSettingActionAuthorProfile),
            NeoWCItem(@"版本与更新日志", @"查看当前版本和历史版本记录", @"shippingbox", NeoWCSettingRowKindDetail, nil, NeoWCDisplayVersion, NeoWCSettingActionReleaseNotes),
        ]],
    ];
}

static NSArray<NeoWCSettingSection *> *NeoWCMessageSections(NSUserDefaults *defaults, NSSet<NSString *> *collapsed) {
    NSMutableArray *protection = [NSMutableArray array];
    NSInteger promptStyleValue = [defaults integerForKey:NeoWCAntiRevokePromptStyleKey];
    NSString *promptStyle = promptStyleValue == 1 ? @"气泡旁" : @"消息下方";
    NSTimeInterval filter = [defaults doubleForKey:NeoWCAntiRevokeTimeFilterKey];
    NSString *filterValue = @"不限制";
    if (filter >= 86400) filterValue = @"24 小时"; else if (filter >= 3600) filterValue = @"1 小时";
    else if (filter >= 1800) filterValue = @"30 分钟"; else if (filter >= 300) filterValue = @"5 分钟"; else if (filter >= 60) filterValue = @"1 分钟";
    NSMutableArray *revokeChildren = [NSMutableArray arrayWithObjects:
        NeoWCItem(@"防撤回提示方案", @"选择提示显示在消息下方或气泡旁", @"text.bubble", NeoWCSettingRowKindDetail, nil, NeoWCCurrentSelection(promptStyle), NeoWCSettingActionRevokePromptStyle),
        promptStyleValue == 1
            ? NeoWCItem(@"提示外观预览", @"调整文字、颜色和 X / Y 位置", @"cursorarrow.motionlines", NeoWCSettingRowKindDetail, nil, @"编辑", NeoWCSettingActionRevokeAppearance)
            : NeoWCItem(@"本地提示模板", @"编辑完整提示内容；浅色和深色颜色分别设置", @"text.quote", NeoWCSettingRowKindDetail, nil, @"编辑", NeoWCSettingActionRevokeLocalTemplate),
        nil];
    if (promptStyleValue == 1) {
        NSString *light = [defaults stringForKey:NeoWCAntiRevokeSideLightTextColorKey] ?: @"#8E8E93FF";
        NSString *dark = [defaults stringForKey:NeoWCAntiRevokeSideDarkTextColorKey] ?: @"#98989DFF";
        [revokeChildren addObject:NeoWCItem(@"浅色模式提示颜色", @"气泡旁提示在浅色模式下使用", @"sun.max",
                                              NeoWCSettingRowKindDetail, NeoWCAntiRevokeSideLightTextColorKey,
                                              light.uppercaseString, NeoWCSettingActionMessageTimeColor)];
        [revokeChildren addObject:NeoWCItem(@"深色模式提示颜色", @"气泡旁提示在深色模式下使用", @"moon",
                                              NeoWCSettingRowKindDetail, NeoWCAntiRevokeSideDarkTextColorKey,
                                              dark.uppercaseString, NeoWCSettingActionMessageTimeColor)];
    } else {
        NSString *light = [defaults stringForKey:NeoWCAntiRevokeLocalLightTextColorKey] ?: @"#8E8E93FF";
        NSString *dark = [defaults stringForKey:NeoWCAntiRevokeLocalDarkTextColorKey] ?: @"#98989DFF";
        [revokeChildren addObject:NeoWCItem(@"浅色模式提示颜色", @"消息下方提示在浅色模式下使用", @"sun.max",
                                              NeoWCSettingRowKindDetail, NeoWCAntiRevokeLocalLightTextColorKey,
                                              light.uppercaseString, NeoWCSettingActionMessageTimeColor)];
        [revokeChildren addObject:NeoWCItem(@"深色模式提示颜色", @"消息下方提示在深色模式下使用", @"moon",
                                              NeoWCSettingRowKindDetail, NeoWCAntiRevokeLocalDarkTextColorKey,
                                              dark.uppercaseString, NeoWCSettingActionMessageTimeColor)];
    }
    NeoWCSettingItem *notify = NeoWCItem(@"回复撤回者", @"自动发送提示，默认关闭", @"paperplane", NeoWCSettingRowKindSwitch, NeoWCAntiRevokeNotifySenderKey, nil, NeoWCSettingActionNone);
    NSArray *notifyChildren = @[
        NeoWCItem(@"回复时间限制", @"避免响应很久以前的撤回事件", @"timer", NeoWCSettingRowKindDetail, nil, NeoWCCurrentSelection(filterValue), NeoWCSettingActionRevokeFilter),
        NeoWCItem(@"回复消息模板", @"设置发送给撤回者的提示", @"text.quote", NeoWCSettingRowKindDetail, nil, @"编辑", NeoWCSettingActionRevokeReplyTemplate),
    ];
    notify.hasChildren = YES;
    [revokeChildren addObject:notify];
    if ([defaults boolForKey:NeoWCAntiRevokeNotifySenderKey] && ![collapsed containsObject:NeoWCAntiRevokeNotifySenderKey]) [revokeChildren addObjectsFromArray:notifyChildren];
    [revokeChildren addObjectsFromArray:@[
        NeoWCItem(@"防撤回记录中心", @"搜索本次运行期间拦截的撤回消息", @"tray.full", NeoWCSettingRowKindDetail, nil, @"查看", NeoWCSettingActionRevokeRecords),
        NeoWCItem(@"本地保存撤回记录", @"仅保存摘要和分类", @"internaldrive", NeoWCSettingRowKindSwitch, NeoWCAntiRevokePersistRecordsKey, nil, NeoWCSettingActionNone),
    ]];
    NeoWCAddFeature(protection, NeoWCItem(@"防撤回", @"保留好友撤回的消息并显示提示", @"arrow.uturn.backward.circle", NeoWCSettingRowKindSwitch, NeoWCAntiRevokeKey, nil, NeoWCSettingActionNone), revokeChildren, defaults, collapsed);

    NSArray *blockChildren = @[
        NeoWCItem(@"管理屏蔽会话", @"按好友或群聊选择需要屏蔽的消息类型", @"person.crop.circle.badge.xmark", NeoWCSettingRowKindDetail, nil, NeoWCCountText(NeoWCMessageBlockedConversations().count), NeoWCSettingActionBlockUsers),
        NeoWCItem(@"屏蔽关键词", @"命中后不加入本地聊天记录", @"text.badge.xmark", NeoWCSettingRowKindDetail, nil, NeoWCCountText([defaults arrayForKey:NeoWCMessageBlockKeywordsKey].count), NeoWCSettingActionBlockKeywords),
        NeoWCItem(@"资料页显示屏蔽开关", @"好友、非好友和群聊资料页均可快速设置", @"person.text.rectangle", NeoWCSettingRowKindSwitch, NeoWCMessageBlockProfileSwitchEnabledKey, nil, NeoWCSettingActionNone),
    ];
    NeoWCAddFeature(protection, NeoWCItem(@"消息屏蔽", @"账号屏蔽全部收到的消息，关键词只匹配文字", @"eye.slash", NeoWCSettingRowKindSwitch, NeoWCMessageBlockEnabledKey, nil, NeoWCSettingActionNone), blockChildren, defaults, collapsed);
    NeoWCAddFeature(protection,
                    NeoWCItem(@"发送前确认", @"仅保护指定会话，默认关闭", @"checkmark.shield", NeoWCSettingRowKindSwitch, NeoWCSendConfirmationEnabledKey, nil, NeoWCSettingActionNone),
                    @[
                        NeoWCItem(@"临时暂停时长", @"确认后可暂时放行当前会话", @"timer", NeoWCSettingRowKindDetail, nil,
                                  NeoWCSendConfirmationPauseDurationText([defaults integerForKey:NeoWCSendConfirmationPauseSecondsKey]),
                                  NeoWCSettingActionSendConfirmationPauseDuration),
                        NeoWCItem(@"资料页显示确认开关", @"好友、非好友和群聊资料页均可快速设置", @"person.text.rectangle",
                                  NeoWCSettingRowKindSwitch, NeoWCSendConfirmationProfileSwitchEnabledKey, nil,
                                  NeoWCSettingActionNone),
                        NeoWCItem(@"管理受保护会话", @"只保存 username，名称运行时读取", @"person.crop.circle.badge.checkmark", NeoWCSettingRowKindDetail, nil,
                                  NeoWCCountText(NeoWCSendConfirmationProtectedConversations().count), NeoWCSettingActionSendConfirmationConversations),
                    ],
                    defaults,
                    collapsed);
    NSMutableSet *menuTitles = [NSMutableSet setWithArray:[defaults arrayForKey:NeoWCLongPressMenuKnownTitlesKey] ?: @[]];
    [menuTitles addObjectsFromArray:[defaults arrayForKey:NeoWCLongPressMenuManualTitlesKey] ?: @[]];
    NeoWCAddFeature(protection, NeoWCItem(@"长按菜单管理", @"管理聊天消息的长按菜单", @"list.bullet.rectangle", NeoWCSettingRowKindSwitch, NeoWCLongPressMenuEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"管理已发现菜单", @"隐藏、排序和重命名已发现菜单", @"slider.horizontal.3", NeoWCSettingRowKindDetail, nil, NeoWCCountText(menuTitles.count), NeoWCSettingActionLongPressMenus)
    ], defaults, collapsed);

    NSMutableArray *interaction = [NSMutableArray arrayWithArray:@[
        NeoWCItem(@"聊天记录搜索", @"在聊天顶栏打开微信原生聊天记录搜索", @"magnifyingglass", NeoWCSettingRowKindSwitch, NeoWCChatSearchButtonEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"小游戏结果选择", @"支持骰子与猜拳跨类型彩蛋", @"die.face.5", NeoWCSettingRowKindSwitch, NeoWCGameSelectorKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"聊天记录小丑", @"长按消息，仅修改当前页面本机显示", @"square.and.pencil", NeoWCSettingRowKindSwitch, NeoWCChatJokerEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"表情存入自拍", @"在表情菜单中存入自拍表情", @"camera", NeoWCSettingRowKindSwitch, NeoWCEmoticonToSelfieEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"语音转发", @"在语音长按菜单中显示转发", @"waveform.badge.plus", NeoWCSettingRowKindSwitch, NeoWCVoiceForwardEnabledKey, nil, NeoWCSettingActionNone),
    ]];
    NeoWCAddFeature(interaction,
                    NeoWCItem(@"媒体转语音", @"把音频文件、聊天视频和音乐卡片转成真正的微信语音", @"waveform", NeoWCSettingRowKindSwitch, NeoWCMediaToVoiceEnabledKey, nil, NeoWCSettingActionNone),
                    @[
                        NeoWCItem(@"音频文件转语音", @"音频文件下载完成后，长按转为语音发送", @"doc", NeoWCSettingRowKindSwitch, NeoWCAudioFileToVoiceEnabledKey, nil, NeoWCSettingActionNone),
                        NeoWCItem(@"视频转语音", @"视频下载完成后，长按提取音轨并发送", @"video", NeoWCSettingRowKindSwitch, NeoWCVideoToVoiceEnabledKey, nil, NeoWCSettingActionNone),
                        NeoWCItem(@"音乐转语音", @"长按音乐卡片，下载播放音频后转为语音发送", @"music.note", NeoWCSettingRowKindSwitch, NeoWCMusicToVoiceEnabledKey, nil, NeoWCSettingActionNone),
                    ],
                    defaults,
                    collapsed);
    NeoWCAddFeature(interaction,
                    NeoWCItem(@"快捷回复", @"长按聊天“+”使用文字、图片、视频和语音消息", @"tray.full", NeoWCSettingRowKindSwitch, NeoWCQuickReplyEnabledKey, nil, NeoWCSettingActionNone),
                    @[NeoWCItem(@"点击秒发送", @"开启后点击直接发送，长按进入编辑或预览", @"bolt.fill", NeoWCSettingRowKindSwitch, NeoWCQuickReplyInstantSendEnabledKey, nil, NeoWCSettingActionNone),
                      NeoWCItem(@"管理消息库", @"全账号共享，支持文件夹、搜索、编辑、置顶和清理", @"square.grid.2x2", NeoWCSettingRowKindDetail, nil,
                                NeoWCCountText(NeoWCQuickReplyStore.sharedStore.items.count), NeoWCSettingActionQuickReplyLibrary)],
                    defaults,
                    collapsed);
    NeoWCAddFeature(interaction, NeoWCItem(@"语音自动转文字", @"收到语音后自动转成文字", @"waveform.and.mic", NeoWCSettingRowKindSwitch, NeoWCAutoVoiceTranscriptionEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"忽略群聊语音", @"群聊中的语音保持原样", @"person.3", NeoWCSettingRowKindSwitch, NeoWCAutoVoiceTranscriptionIgnoreGroupKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"忽略私聊语音", @"私聊中的语音保持原样", @"person", NeoWCSettingRowKindSwitch, NeoWCAutoVoiceTranscriptionIgnorePrivateKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"忽略自己发送", @"不转换自己发出的语音", @"person.crop.circle", NeoWCSettingRowKindSwitch, NeoWCAutoVoiceTranscriptionIgnoreSelfKey, nil, NeoWCSettingActionNone),
    ], defaults, collapsed);
    NSInteger avatarGesture = [defaults integerForKey:NeoWCAvatarQuickMenuGestureKey];
    NSString *avatarGestureName = avatarGesture == NeoWCAvatarQuickMenuGestureDoubleTap
        ? @"双击头像"
        : (avatarGesture == NeoWCAvatarQuickMenuGestureLongPress ? @"长按头像" : @"关闭");
    [interaction addObject:NeoWCItem(@"头像快捷面板",
                                     [NSString stringWithFormat:@"呼出方式：%@", avatarGestureName],
                                     @"person.crop.circle.badge.ellipsis",
                                     NeoWCSettingRowKindDetail,
                                     NeoWCAvatarQuickMenuGestureKey,
                                     avatarGestureName,
                                     NeoWCSettingActionAvatarQuickMenuGesture)];
    NSString *messageTimeFormat = [defaults stringForKey:NeoWCChatMessageTimeFormatKey];
    if (messageTimeFormat.length == 0) messageTimeFormat = @"MM-dd HH:mm:ss";
    BOOL messageTimeBubbleMode = [defaults boolForKey:NeoWCChatMessageTimeBubbleSideKey];
    NSInteger messageTimePosition = MIN(2, MAX(0, [defaults integerForKey:NeoWCChatMessageTimeBubbleVerticalPositionKey]));
    NSArray<NSString *> *messageTimePositionNames = @[@"顶部", @"中间", @"底部"];
    NSString *messageTimeLightColor = [defaults stringForKey:NeoWCChatMessageTimeLightColorKey] ?: @"#8E8E93FF";
    NSString *messageTimeDarkColor = [defaults stringForKey:NeoWCChatMessageTimeDarkColorKey] ?: @"#98989DFF";
    NSString *messageTimeModeName = messageTimeBubbleMode ? @"消息右侧" : @"头像下方";
    NSMutableArray<NeoWCSettingItem *> *messageTimeChildren = [NSMutableArray arrayWithObject:
        NeoWCItem(@"时间显示位置", @"头像下方与消息右侧严格二选一", @"rectangle.2.swap", NeoWCSettingRowKindDetail, nil, messageTimeModeName, NeoWCSettingActionMessageTimeMode)];
    if (messageTimeBubbleMode) {
        [messageTimeChildren addObject:NeoWCItem(@"消息旁垂直位置", @"调整时间位于消息顶部、中间或底部", @"arrow.up.and.down.text.horizontal", NeoWCSettingRowKindDetail, nil, messageTimePositionNames[messageTimePosition], NeoWCSettingActionMessageTimePosition)];
    } else {
        [messageTimeChildren addObject:NeoWCItem(@"头像时间间距", @"负值向上、正值向下，范围 -6 到 8", @"arrow.up.and.down", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", [defaults doubleForKey:NeoWCChatMessageTimeAvatarSpacingKey]], NeoWCSettingActionMessageTimeAvatarSpacing)];
    }
    [messageTimeChildren addObjectsFromArray:@[
        NeoWCItem(@"时间格式", @"支持 yyyy、MM、dd、E、HH、mm、ss", @"textformat", NeoWCSettingRowKindDetail, nil, messageTimeFormat, NeoWCSettingActionMessageTimeFormat),
        NeoWCItem(@"时间字号", @"限制在 8 到 18 点", @"textformat.size", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", [defaults doubleForKey:NeoWCChatMessageTimeFontSizeKey]], NeoWCSettingActionMessageTimeFontSize),
        NeoWCItem(@"时间文字加粗", @"头像下方与消息右侧共同生效", @"bold", NeoWCSettingRowKindSwitch, NeoWCChatMessageTimeBoldKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"浅色模式时间颜色", @"仅在浅色模式下使用", @"sun.max", NeoWCSettingRowKindDetail, NeoWCChatMessageTimeLightColorKey, messageTimeLightColor.uppercaseString, NeoWCSettingActionMessageTimeColor),
        NeoWCItem(@"深色模式时间颜色", @"仅在深色模式下使用", @"moon", NeoWCSettingRowKindDetail, NeoWCChatMessageTimeDarkColorKey, messageTimeDarkColor.uppercaseString, NeoWCSettingActionMessageTimeColor),
    ]];
    NeoWCAddFeature(interaction, NeoWCItem(@"消息时间显示", [NSString stringWithFormat:@"当前：%@", messageTimeModeName], @"clock", NeoWCSettingRowKindSwitch, NeoWCChatMessageTimeEnabledKey, nil, NeoWCSettingActionNone), messageTimeChildren, defaults, collapsed);
    NSInteger selfSwipeAction = [defaults integerForKey:NeoWCReplySwipeSelfActionKey];
    NSInteger otherSwipeAction = [defaults integerForKey:NeoWCReplySwipeOtherActionKey];
    NSInteger selfRightSwipeAction = [defaults integerForKey:NeoWCReplySwipeRightSelfActionKey];
    NSInteger otherRightSwipeAction = [defaults integerForKey:NeoWCReplySwipeRightOtherActionKey];
    NSArray<NSString *> *swipeActionNames = @[@"不设置", @"引用", @"撤回", @"复制", @"删除", @"复读"];
    NSString *(^gestureActionName)(NSInteger, BOOL) = ^NSString *(NSInteger action, BOOL selfMessage) {
        if (action < 0 || action >= (NSInteger)swipeActionNames.count || (!selfMessage && action == NeoWCReplySwipeActionRevoke)) return @"不设置";
        return swipeActionNames[action];
    };
    NSString *selfSwipeName = gestureActionName(selfSwipeAction, YES);
    NSString *otherSwipeName = gestureActionName(otherSwipeAction, NO);
    NSString *selfRightSwipeName = gestureActionName(selfRightSwipeAction, YES);
    NSString *otherRightSwipeName = gestureActionName(otherRightSwipeAction, NO);
    NSInteger selfDoubleAction = [defaults integerForKey:NeoWCMessageDoubleTapSelfActionKey];
    NSInteger otherDoubleAction = [defaults integerForKey:NeoWCMessageDoubleTapOtherActionKey];
    NSInteger selfTripleAction = [defaults integerForKey:NeoWCMessageTripleTapSelfActionKey];
    NSInteger otherTripleAction = [defaults integerForKey:NeoWCMessageTripleTapOtherActionKey];
    NeoWCAddFeature(interaction,
                    NeoWCItem(@"消息手势", [NSString stringWithFormat:@"左滑 %@/%@ · 右滑 %@/%@", selfSwipeName, otherSwipeName, selfRightSwipeName, otherRightSwipeName], @"hand.draw", NeoWCSettingRowKindSwitch, NeoWCReplySwipeEnabledKey, nil, NeoWCSettingActionNone),
                    @[
        NeoWCItem(@"左滑 · 自己", [NSString stringWithFormat:@"当前状态：%@", selfSwipeName], @"arrow.left", NeoWCSettingRowKindDetail, NeoWCReplySwipeSelfActionKey, nil, NeoWCSettingActionMessageGestureAction),
        NeoWCItem(@"左滑 · 对方", [NSString stringWithFormat:@"当前状态：%@", otherSwipeName], @"arrow.left", NeoWCSettingRowKindDetail, NeoWCReplySwipeOtherActionKey, nil, NeoWCSettingActionMessageGestureAction),
        NeoWCItem(@"右滑 · 自己", [NSString stringWithFormat:@"当前状态：%@", selfRightSwipeName], @"arrow.right", NeoWCSettingRowKindDetail, NeoWCReplySwipeRightSelfActionKey, nil, NeoWCSettingActionMessageGestureAction),
        NeoWCItem(@"右滑 · 对方", [NSString stringWithFormat:@"当前状态：%@", otherRightSwipeName], @"arrow.right", NeoWCSettingRowKindDetail, NeoWCReplySwipeRightOtherActionKey, nil, NeoWCSettingActionMessageGestureAction),
        NeoWCItem(@"触发距离", @"限制在 36 到 100 点，越小越灵敏", @"arrow.left.and.right", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", [defaults doubleForKey:NeoWCReplySwipeTriggerDistanceKey]], NeoWCSettingActionReplySwipeTriggerDistance),
        NeoWCItem(@"双击 · 自己", [NSString stringWithFormat:@"当前状态：%@", gestureActionName(selfDoubleAction, YES)], @"hand.tap", NeoWCSettingRowKindDetail, NeoWCMessageDoubleTapSelfActionKey, nil, NeoWCSettingActionMessageGestureAction),
        NeoWCItem(@"双击 · 对方", [NSString stringWithFormat:@"当前状态：%@", gestureActionName(otherDoubleAction, NO)], @"hand.tap", NeoWCSettingRowKindDetail, NeoWCMessageDoubleTapOtherActionKey, nil, NeoWCSettingActionMessageGestureAction),
        NeoWCItem(@"三击 · 自己", [NSString stringWithFormat:@"当前状态：%@", gestureActionName(selfTripleAction, YES)], @"hand.tap", NeoWCSettingRowKindDetail, NeoWCMessageTripleTapSelfActionKey, nil, NeoWCSettingActionMessageGestureAction),
        NeoWCItem(@"三击 · 对方", [NSString stringWithFormat:@"当前状态：%@", gestureActionName(otherTripleAction, NO)], @"hand.tap", NeoWCSettingRowKindDetail, NeoWCMessageTripleTapOtherActionKey, nil, NeoWCSettingActionMessageGestureAction),
    ], defaults, collapsed);
    NeoWCAddFeature(interaction, NeoWCItem(@"引用消息定位", @"点击引用定位原消息", @"arrow.up.and.down.text.horizontal", NeoWCSettingRowKindSwitch, NeoWCQuoteJumpEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"定位图片引用", @"允许点击图片引用定位", @"photo", NeoWCSettingRowKindSwitch, NeoWCQuoteJumpImageEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"定位视频引用", @"允许点击视频引用定位", @"video", NeoWCSettingRowKindSwitch, NeoWCQuoteJumpVideoEnabledKey, nil, NeoWCSettingActionNone),
    ], defaults, collapsed);
    [interaction addObject:NeoWCItem(@"输入框滑动操作", @"左滑清空，右滑粘贴", @"hand.draw", NeoWCSettingRowKindSwitch, NeoWCInputSwipeActionsEnabledKey, nil, NeoWCSettingActionNone)];

    NSMutableArray *reminders = [NSMutableArray arrayWithArray:@[
        NeoWCItem(@"群成员进退群提醒", @"根据群成员列表变化显示本地提醒", @"person.2.badge.gearshape", NeoWCSettingRowKindSwitch, NeoWCGroupMemberReminderEnabledKey, nil, NeoWCSettingActionNone)
    ]];
    NeoWCAddFeature(reminders, NeoWCItem(@"红包详情显示", @"显示总额、领取和剩余统计", @"envelope.open", NeoWCSettingRowKindSwitch, NeoWCRedEnvelopeDetailEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"红包详情居中", @"将补充统计信息居中显示", @"text.aligncenter", NeoWCSettingRowKindSwitch, NeoWCRedEnvelopeDetailCenterKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"红包详情字号", @"输入 10 到 24", @"textformat.size", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", [defaults doubleForKey:NeoWCRedEnvelopeDetailFontSizeKey]], NeoWCSettingActionRedEnvelopeFontSize)
    ], defaults, collapsed);
    [reminders addObjectsFromArray:@[
        NeoWCItem(@"通话二次确认", @"发起语音或视频通话前确认", @"phone.badge.checkmark", NeoWCSettingRowKindSwitch, NeoWCCallConfirmEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"通话自动免提", @"通话音频设备启动成功后自动切换扬声器", @"speaker.wave.2", NeoWCSettingRowKindSwitch, NeoWCAutoSpeakerphoneEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"通知直达聊天", @"点击通知后进入对应会话", @"bubble.left.and.arrow.forward", NeoWCSettingRowKindSwitch, NeoWCNotificationDirectChatEnabledKey, nil, NeoWCSettingActionNone),
    ]];

    NSMutableArray *media = [NSMutableArray arrayWithArray:@[
        NeoWCItem(@"图片编辑快捷发送", @"编辑图片后可发送到当前聊天", @"photo.badge.arrow.down", NeoWCSettingRowKindSwitch, NeoWCImageEditQuickSendEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"自动选择原图", @"选择和预览照片、视频时自动勾选原图", @"photo.badge.checkmark", NeoWCSettingRowKindSwitch, NeoWCAutoOriginalImageEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"自动勾选合并发送", @"开启自动选择原图后，多选达到要求时自动勾选", @"rectangle.3.group", NeoWCSettingRowKindSwitch, NeoWCAutoCombineSendEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"突破多选限制", @"放宽消息、转发目标与拍摄视频限制", @"checklist.unchecked", NeoWCSettingRowKindSwitch, NeoWCMultiSelectLimitEnabledKey, nil, NeoWCSettingActionNone),
    ]];
    NeoWCAddFeature(media, NeoWCItem(@"多选消息导出", @"控制复制、保存和分享功能", @"square.and.arrow.up.on.square", NeoWCSettingRowKindSwitch, NeoWCMultiSelectExportEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"复制纯文本", @"只复制消息正文", @"doc.on.clipboard", NeoWCSettingRowKindSwitch, NeoWCMultiSelectExportTextKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"批量保存图片", @"保存已下载到本机的图片", @"photo.on.rectangle.angled", NeoWCSettingRowKindSwitch, NeoWCMultiSelectSaveImagesKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"生成分享卡片", @"极简、对话或深色样式", @"rectangle.on.rectangle", NeoWCSettingRowKindSwitch, NeoWCMultiSelectShareCardKey, nil, NeoWCSettingActionNone),
    ], defaults, collapsed);

    return @[
        [NeoWCSettingSection sectionWithIdentifier:@"message-protection" title:@"消息保护" footer:nil items:protection],
        [NeoWCSettingSection sectionWithIdentifier:@"chat-interaction" title:@"聊天操作" footer:nil items:interaction],
        [NeoWCSettingSection sectionWithIdentifier:@"message-reminders" title:@"提醒与详情" footer:nil items:reminders],
        [NeoWCSettingSection sectionWithIdentifier:@"media-export" title:@"图片与导出" footer:@"快捷发送会先显示微信确认页，不影响普通转发。" items:media],
    ];
}

static NSArray<NeoWCSettingSection *> *NeoWCEnhancementSections(NSUserDefaults *defaults,
                                                                 NSSet<NSString *> *collapsed,
                                                                 BOOL momentsOnly) {
    NSMutableArray *automation = [NSMutableArray arrayWithArray:@[
        NeoWCItem(@"保持后台运行", @"尽量维持微信后台活跃，供朋友圈提醒等周期功能使用", @"moon.zzz", NeoWCSettingRowKindSwitch, NeoWCBackgroundKeepAliveEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"设备扫码自动登录", @"自动确认电脑、平板等设备登录", @"desktopcomputer", NeoWCSettingRowKindSwitch, NeoWCAutoDeviceLoginKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"游戏授权自动允许", @"自动确认游戏扫码授权", @"gamecontroller", NeoWCSettingRowKindSwitch, NeoWCAutoGameAuthorizeKey, nil, NeoWCSettingActionNone),
    ]];
    NSArray<NeoWCSettingItem *> *scan = @[
        NeoWCItem(@"伪装扫码来源", @"将相册识别结果按相机扫码处理", @"qrcode.viewfinder", NeoWCSettingRowKindSwitch, NeoWCQRCodeCameraSourceEnabledKey, nil, NeoWCSettingActionNone),
    ];
    NSMutableArray *moments = [NSMutableArray array];
    NSUInteger reminderUserCount = [[defaults arrayForKey:NeoWCMomentsReminderUsersKey] count];
    NSInteger reminderInterval = MAX(30, MIN(3600, [defaults integerForKey:NeoWCMomentsReminderIntervalKey]));
    BOOL backgroundEnabled = [defaults boolForKey:NeoWCBackgroundKeepAliveEnabledKey];
    NSString *forwardTarget = [defaults integerForKey:NeoWCMomentsReminderForwardTargetKey] == 1
        ? @"文件传输助手" : @"自己的聊天框";
    NSString *reminderSubtitle = backgroundEnabled
        ? @"周期检测特别关注好友的新朋友圈"
        : @"建议开启“保持后台运行”，否则可能只在前台检测";
    NSString *interactionSubtitle = backgroundEnabled
        ? @"检测新的朋友圈点赞或评论并发送提醒"
        : @"建议开启“保持后台运行”，否则可能只在前台检测";
    NeoWCSettingItem *forwardToChat = NeoWCItem(@"转发到聊天", @"开启后默认只转发文字", @"paperplane",
                                                NeoWCSettingRowKindSwitch, NeoWCMomentsReminderForwardEnabledKey,
                                                nil, NeoWCSettingActionNone);
    forwardToChat.hasChildren = YES;
    NSMutableArray<NeoWCSettingItem *> *reminderChildren = [NSMutableArray arrayWithArray:@[
        NeoWCItem(@"特别关注好友", @"选择需要检测朋友圈更新的好友", @"person.crop.circle.badge.checkmark", NeoWCSettingRowKindDetail, nil,
                  reminderUserCount > 0 ? [NSString stringWithFormat:@"%lu 位", (unsigned long)reminderUserCount] : @"未选择",
                  NeoWCSettingActionMomentsReminderUsers),
        NeoWCItem(@"检测间隔", @"支持 30–3600 秒；间隔越短耗电越高", @"timer", NeoWCSettingRowKindDetail, nil,
                  [NSString stringWithFormat:@"%ld 秒", (long)reminderInterval], NeoWCSettingActionMomentsReminderInterval),
        forwardToChat,
    ]];
    if ([defaults boolForKey:NeoWCMomentsReminderForwardEnabledKey] &&
        ![collapsed containsObject:NeoWCMomentsReminderForwardEnabledKey]) {
        [reminderChildren addObjectsFromArray:@[
            NeoWCItem(@"转发目标", @"选择接收朋友圈内容的会话", @"person.crop.circle.badge.arrow.forward", NeoWCSettingRowKindDetail, nil,
                      forwardTarget, NeoWCSettingActionMomentsReminderForwardTarget),
            NeoWCItem(@"同时转发图片", @"默认关闭，开启后下载并发送朋友圈图片", @"photo", NeoWCSettingRowKindSwitch,
                      NeoWCMomentsReminderForwardImagesKey, nil, NeoWCSettingActionNone),
            NeoWCItem(@"同时转发视频", @"默认关闭，开启后下载并发送朋友圈视频", @"video", NeoWCSettingRowKindSwitch,
                      NeoWCMomentsReminderForwardVideosKey, nil, NeoWCSettingActionNone),
        ]];
    }
    NeoWCAddFeature(moments,
                    NeoWCItem(@"朋友圈提醒", reminderSubtitle, @"bell.badge", NeoWCSettingRowKindSwitch, NeoWCMomentsReminderEnabledKey, nil, NeoWCSettingActionNone),
                    reminderChildren, defaults, collapsed);
    NSMutableArray<NeoWCSettingItem *> *interactionRows = [NSMutableArray array];
    NeoWCAddFeature(interactionRows,
                    NeoWCItem(@"朋友圈互动提醒", interactionSubtitle, @"bubble.left.and.exclamationmark.bubble.right",
                              NeoWCSettingRowKindSwitch, NeoWCMomentsInteractionReminderEnabledKey,
                              nil, NeoWCSettingActionNone),
                    @[
                        NeoWCItem(@"显示详细信息", @"关闭后仅提示收到新的评论或点赞", @"text.bubble",
                                  NeoWCSettingRowKindSwitch, NeoWCMomentsInteractionReminderDetailsEnabledKey,
                                  nil, NeoWCSettingActionNone),
                    ], defaults, collapsed);
    [moments insertObjects:interactionRows
                 atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, interactionRows.count)]];
    NSString *antiDeleteText = [defaults stringForKey:NeoWCMomentsCommentAntiDeleteTextKey] ?: @"←该评论已删除";
    CGFloat antiDeleteFontSize = [defaults doubleForKey:NeoWCMomentsCommentAntiDeleteFontSizeKey];
    antiDeleteFontSize = MIN(24.0, MAX(6.0, antiDeleteFontSize > 0.0 ? antiDeleteFontSize : 12.0));
    NSString *antiDeleteColor = [defaults stringForKey:NeoWCMomentsCommentAntiDeleteColorKey] ?: @"#8E8E93FF";
    NeoWCAddFeature(moments,
                    NeoWCItem(@"朋友圈评论防删除", @"保留本次微信运行中已加载后被删除的评论", @"bubble.left.and.text.bubble.right",
                              NeoWCSettingRowKindSwitch, NeoWCMomentsCommentAntiDeleteEnabledKey, nil, NeoWCSettingActionNone),
                    @[
                        NeoWCItem(@"删除标识文字", @"追加在已删除评论末尾", @"textformat", NeoWCSettingRowKindDetail,
                                  nil, antiDeleteText, NeoWCSettingActionMomentsCommentAntiDeleteText),
                        NeoWCItem(@"删除标识字号", @"限制在 6 到 24 之间", @"textformat.size", NeoWCSettingRowKindDetail,
                                  nil, [NSString stringWithFormat:@"%.0f", antiDeleteFontSize], NeoWCSettingActionMomentsCommentAntiDeleteFontSize),
                        NeoWCItem(@"删除标识颜色", @"只改变追加标识的颜色", @"paintpalette", NeoWCSettingRowKindDetail,
                                  NeoWCMomentsCommentAntiDeleteColorKey, antiDeleteColor.uppercaseString, NeoWCSettingActionMessageTimeColor),
                    ], defaults, collapsed);
    CGFloat intensity = [defaults doubleForKey:NeoWCMomentsLikeHapticIntensityKey];
    NSString *intensityText = intensity < 0.34 ? @"轻" : (intensity < 0.75 ? @"中" : @"强");
    NeoWCSettingItem *haptic = NeoWCItem(@"点赞震动", @"点赞成功时提供触感反馈", @"waveform", NeoWCSettingRowKindSwitch, NeoWCMomentsLikeHapticEnabledKey, nil, NeoWCSettingActionNone);
    haptic.hasChildren = YES;
    NSMutableArray *likeChildren = [NSMutableArray arrayWithObject:haptic];
    if ([defaults boolForKey:NeoWCMomentsLikeHapticEnabledKey] && ![collapsed containsObject:NeoWCMomentsLikeHapticEnabledKey]) {
        [likeChildren addObject:NeoWCItem(@"点赞震动力度", @"调整双击点赞时的震动反馈", @"slider.horizontal.3", NeoWCSettingRowKindDetail, nil, NeoWCCurrentSelection(intensityText), NeoWCSettingActionHapticIntensity)];
    }
    NeoWCAddFeature(moments, NeoWCItem(@"朋友圈双击点赞", @"双击好友朋友圈内容直接点赞", @"hand.thumbsup", NeoWCSettingRowKindSwitch, NeoWCMomentsDoubleTapLikeKey, nil, NeoWCSettingActionNone), likeChildren, defaults, collapsed);
    [moments addObjectsFromArray:@[
        NeoWCItem(@"朋友圈操作按钮替换为评论", @"点击后直接进入评论", @"bubble.middle.bottom", NeoWCSettingRowKindSwitch, NeoWCMomentsQuickCommentKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"朋友圈转发", @"点击进入朋友圈转发发布页", @"arrowshape.turn.up.right", NeoWCSettingRowKindSwitch, NeoWCMomentsForwardEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"保存朋友圈媒体", @"在朋友圈操作菜单中保存图片、视频和实况照片", @"square.and.arrow.down", NeoWCSettingRowKindSwitch, NeoWCMomentsSaveImagesEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"朋友圈高清发送", @"从相机菜单选择高清图片或原视频", @"photo.badge.checkmark", NeoWCSettingRowKindSwitch, NeoWCMomentsOriginalMediaPostEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"朋友圈头像快捷权限", @"长按头像切换朋友权限", @"person.crop.circle.badge.checkmark", NeoWCSettingRowKindSwitch, NeoWCMomentsQuickPermissionsKey, nil, NeoWCSettingActionNone),
    ]];
    NSString *dateFormat = NeoWCNormalizedMomentsDateFormat([defaults stringForKey:NeoWCMomentsPreciseTimeFormatKey]) ?: NeoWCMomentsPreciseTimeDefaultFormat;
    NeoWCAddFeature(moments, NeoWCItem(@"朋友圈精确发布时间", @"显示完整发布时间", @"calendar.badge.clock", NeoWCSettingRowKindSwitch, NeoWCMomentsPreciseTimeKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"朋友圈日期格式", @"支持 yyyy、MM、dd、E、HH、mm、ss", @"textformat", NeoWCSettingRowKindDetail, nil, dateFormat, NeoWCSettingActionMomentsDateFormat)
    ], defaults, collapsed);

    NSMutableArray *local = [NSMutableArray array];
    [local addObject:NeoWCItem(@"查找好友", @"输入微信号或原始号码打开指定账号资料", @"person.crop.circle.badge.magnifyingglass", NeoWCSettingRowKindDetail, nil, @"查找", NeoWCSettingActionFindFriend)];
    [local addObject:NeoWCItem(@"显示信息卡片", @"在好友、群聊和群成员资料中集中显示账号信息", @"person.text.rectangle", NeoWCSettingRowKindSwitch, NeoWCShowRawContactIDEnabledKey, nil, NeoWCSettingActionNone)];
    NeoWCStepMode stepMode = [defaults integerForKey:NeoWCStepModeKey] == NeoWCStepModeDailyRandom ? NeoWCStepModeDailyRandom : NeoWCStepModeDailyFixed;
    NSInteger configuredSteps = MIN(100000, MAX(0, [defaults integerForKey:NeoWCStepCountKey]));
    NSInteger effectiveSteps = [defaults integerForKey:NeoWCStepDailyTargetKey];
    NSDate *stepDate = [defaults objectForKey:NeoWCStepCountDateKey];
    BOOL today = effectiveSteps > 0 && [stepDate isKindOfClass:NSDate.class] && [NSCalendar.currentCalendar isDateInToday:stepDate];
    if ([defaults boolForKey:NeoWCStepOverrideEnabledKey] && !today) {
        NeoWCSettingsRegenerateDailyStepTarget(defaults);
        effectiveSteps = [defaults integerForKey:NeoWCStepDailyTargetKey];
        stepDate = [defaults objectForKey:NeoWCStepCountDateKey];
        today = effectiveSteps > 0 && [stepDate isKindOfClass:NSDate.class] && [NSCalendar.currentCalendar isDateInToday:stepDate];
    }
    NSString *modeText = stepMode == NeoWCStepModeDailyRandom ? @"每日随机" : @"固定步数";
    NSMutableArray *stepChildren = [NSMutableArray arrayWithObject:NeoWCItem(@"步数模式", @"选择固定数值，或每天随机生成一次", @"arrow.triangle.2.circlepath", NeoWCSettingRowKindDetail, nil, NeoWCCurrentSelection(modeText), NeoWCSettingActionStepMode)];
    if (stepMode == NeoWCStepModeDailyRandom) {
        NSInteger minimum = MAX(1, [defaults integerForKey:NeoWCStepRandomMinimumKey]);
        NSInteger maximum = MAX(minimum, [defaults integerForKey:NeoWCStepRandomMaximumKey]);
        [stepChildren addObject:NeoWCItem(@"随机步数范围", @"每天首次使用时在范围内生成一次", @"dice", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%ld–%ld 步", (long)minimum, (long)maximum], NeoWCSettingActionRandomStepRange)];
        [stepChildren addObject:NeoWCItem(@"今日随机结果", @"当天保持不变；点击可重新生成", @"figure.walk.motion", NeoWCSettingRowKindDetail, nil, today ? [NSString stringWithFormat:@"%ld 步", (long)effectiveSteps] : @"尚未生成", NeoWCSettingActionRegenerateRandomSteps)];
    } else {
        [stepChildren addObject:NeoWCItem(@"固定步数", @"点击输入每天固定显示的步数", @"number", NeoWCSettingRowKindDetail, nil, configuredSteps > 0 ? [NSString stringWithFormat:@"已设置：%ld 步", (long)configuredSteps] : @"尚未设置", NeoWCSettingActionFixedSteps)];
    }
    [stepChildren addObject:NeoWCItem(@"分时段阶段递增", @"每天分阶段更新，18:30 完成今日目标", @"chart.line.uptrend.xyaxis", NeoWCSettingRowKindSwitch, NeoWCStepGradualEnabledKey, nil, NeoWCSettingActionNone)];
    NSString *stepSummary = stepMode == NeoWCStepModeDailyRandom
        ? (today ? [NSString stringWithFormat:@"今日随机：%ld 步", (long)effectiveSteps] : @"每日随机，尚未生成")
        : (configuredSteps > 0 ? [NSString stringWithFormat:@"固定：%ld 步", (long)configuredSteps] : @"固定模式，请先设置步数");
    NeoWCAddFeature(local, NeoWCItem(@"自定义微信运动步数", stepSummary, @"figure.walk", NeoWCSettingRowKindSwitch, NeoWCStepOverrideEnabledKey, nil, NeoWCSettingActionNone), stepChildren, defaults, collapsed);
    NeoWCAddFeature(local, NeoWCItem(@"钱包余额本地显示", @"仅修改本机钱包余额文字", @"creditcard", NeoWCSettingRowKindSwitch, NeoWCWalletBalanceEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"设置钱包余额", @"金额按分保存，仅作用于钱包余额组件", @"number", NeoWCSettingRowKindDetail, nil, NeoWCLongLongForKey(NeoWCWalletBalanceFenKey) > 0 ? @"已设置" : @"设置", NeoWCSettingActionWalletBalance)
    ], defaults, collapsed);
    NSInteger contacts = [defaults integerForKey:NeoWCContactsCountKey];
    NeoWCAddFeature(local, NeoWCItem(@"好友数量本地显示", @"替换明确的好友数量文案", @"person.2", NeoWCSettingRowKindSwitch, NeoWCContactsCountEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"设置好友数量", @"输入本机显示的好友数量", @"number", NeoWCSettingRowKindDetail, nil, contacts > 0 ? [NSString stringWithFormat:@"%ld 个", (long)contacts] : @"设置", NeoWCSettingActionContactsCount)
    ], defaults, collapsed);
    if (momentsOnly) {
        return @[[NeoWCSettingSection sectionWithIdentifier:@"moments" title:nil footer:nil items:moments]];
    }
    return @[
        [NeoWCSettingSection sectionWithIdentifier:@"automation" title:@"自动化" footer:@"保持后台运行可能增加耗电；自动登录和授权会跳过手动确认，请只在可信环境开启。" items:automation],
        [NeoWCSettingSection sectionWithIdentifier:@"scan" title:@"扫码增强" footer:nil items:scan],
        [NeoWCSettingSection sectionWithIdentifier:@"local-display" title:@"资料、运动与本地显示" footer:@"钱包余额和好友数量只修改本机显示。" items:local],
    ];
}

static NSArray<NeoWCSettingSection *> *NeoWCInterfaceSections(NSUserDefaults *defaults,
                                                               NSSet<NSString *> *collapsed,
                                                               BOOL disabledOnly) {
    NSMutableArray *display = [NSMutableArray array];
    NSMutableArray *disabled = [NSMutableArray array];
    NeoWCAddFeature(display,
                    NeoWCItem(@"全局头像圆角", @"统一调整微信头像组件的圆角", @"person.crop.square", NeoWCSettingRowKindSwitch, NeoWCGlobalAvatarRoundingEnabledKey, nil, NeoWCSettingActionNone),
                    @[
        NeoWCItem(@"头像圆角程度", @"0% 为直角，100% 为圆形", @"slider.horizontal.3", NeoWCSettingRowKindDetail, nil,
                  [NSString stringWithFormat:@"%.0f%%", [defaults doubleForKey:NeoWCGlobalAvatarCornerPercentKey]],
                  NeoWCSettingActionGlobalAvatarCornerPercent),
    ], defaults, collapsed);
    CGFloat globalScale = NeoWCScalePercentForDefaultsKey(NeoWCPageScaleGlobalPercentKey, 100.0);
    CGFloat settingsScale = NeoWCScalePercentForDefaultsKey(NeoWCSettingsPageScalePercentKey, 100.0);
    NeoWCAddFeature(display, NeoWCItem(@"页面缩放", @"调整页面中的文字大小", @"textformat.size", NeoWCSettingRowKindSwitch, NeoWCPageScaleEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"全局页面缩放比例", @"同时调整应用界面和网页文字", @"rectangle.compress.vertical", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f%%", globalScale], NeoWCSettingActionGlobalScale),
        NeoWCItem(@"NeoWC 设置页缩放比例", @"仅调整本设置页", @"list.bullet.rectangle", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f%%", settingsScale], NeoWCSettingActionSettingsScale),
    ], defaults, collapsed);
    [disabled addObjectsFromArray:@[
        NeoWCItem(@"隐藏群标题尾部", @"隐藏群人数和免打扰标记并居中群名", @"bell.slash", NeoWCSettingRowKindSwitch, NeoWCHideChatMuteIconKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"隐藏截屏分享按钮", @"不显示右下角截图转发浮层", @"rectangle.on.rectangle.slash", NeoWCSettingRowKindSwitch, NeoWCHideScreenshotForwardKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"隐藏页面分割线", @"不显示列表和页面中的细分割线", @"rectangle.split.1x2", NeoWCSettingRowKindSwitch, NeoWCHideSeparatorLinesKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"广告精简", @"精简朋友圈、视频号、广告推送与小程序启动广告", @"rectangle.badge.xmark", NeoWCSettingRowKindSwitch, NeoWCAdBlockerKey, nil, NeoWCSettingActionNone),
    ]];
    [display addObject:NeoWCItem(@"开启强制高刷", @"前台锁定为设备支持的最高刷新率", @"speedometer", NeoWCSettingRowKindSwitch, NeoWCScrollHighRefreshRateEnabledKey, nil, NeoWCSettingActionNone)];
    [display addObject:NeoWCItem(@"主页右滑扩展", @"增加备注、朋友圈、折叠群聊、勿扰与置顶操作", @"rectangle.and.hand.point.up.left", NeoWCSettingRowKindSwitch, NeoWCHomeSwipeActionsEnabledKey, nil, NeoWCSettingActionNone)];
    NSMutableArray *chatCapsules = [NSMutableArray array];
    NSInteger glassStyle = [defaults integerForKey:NeoWCChatGlassStyleKey];
    NSString *glassStyleName = glassStyle == 1 ? @"伪液态" : @"磨砂玻璃";
    NeoWCAddFeature(chatCapsules,
                    NeoWCItem(@"胶囊顶栏", @"隐藏整条顶栏背景，左右使用玻璃胶囊", @"capsule", NeoWCSettingRowKindSwitch, NeoWCChatTopBarCapsuleEnabledKey, nil, NeoWCSettingActionNone),
                    @[
        NeoWCItem(@"头像大小", @"限制在 24 到 34 之间", @"person.crop.circle", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", [defaults doubleForKey:NeoWCChatTopBarAvatarSizeKey]], NeoWCSettingActionChatTopAvatarSize),
        NeoWCItem(@"昵称字号", @"限制在 12 到 18 之间", @"textformat.size", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", [defaults doubleForKey:NeoWCChatTopBarNicknameSizeKey]], NeoWCSettingActionChatTopNicknameSize),
        NeoWCItem(@"玻璃样式", @"磨砂玻璃或独立的伪液态效果", @"circle.hexagongrid.fill", NeoWCSettingRowKindDetail, NeoWCChatGlassStyleKey, glassStyleName, NeoWCSettingActionChatGlassStyle),
        NeoWCItem(@"模糊强度", @"限制在 20% 到 100%", @"drop.halffull", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f%%", [defaults doubleForKey:NeoWCChatGlassBlurIntensityKey]], NeoWCSettingActionChatGlassBlurIntensity),
    ], defaults, collapsed);
    NSMutableArray *input = [NSMutableArray array];
    NSMutableArray *roundingChildren = [NSMutableArray array];
    NeoWCSettingItem *inner = NeoWCItem(@"输入框内部圆角", @"调整文字输入区域", @"text.cursor", NeoWCSettingRowKindSwitch, NeoWCChatInputInnerRoundingKey, nil, NeoWCSettingActionNone);
    inner.hasChildren = YES;
    [roundingChildren addObject:inner];
    if ([defaults boolForKey:NeoWCChatInputInnerRoundingKey] && ![collapsed containsObject:NeoWCChatInputInnerRoundingKey]) [roundingChildren addObject:NeoWCItem(@"内部圆角程度", @"输入 0 到 40", @"slider.horizontal.3", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", [defaults doubleForKey:NeoWCChatInputInnerRadiusKey]], NeoWCSettingActionInnerRadius)];
    NeoWCSettingItem *outer = NeoWCItem(@"外部工具栏圆角", @"调整聊天底部工具栏", @"rectangle.bottomhalf.filled", NeoWCSettingRowKindSwitch, NeoWCChatInputOuterRoundingKey, nil, NeoWCSettingActionNone);
    outer.hasChildren = YES;
    [roundingChildren addObject:outer];
    if ([defaults boolForKey:NeoWCChatInputOuterRoundingKey] && ![collapsed containsObject:NeoWCChatInputOuterRoundingKey]) [roundingChildren addObject:NeoWCItem(@"外部圆角程度", @"输入 0 到 40", @"slider.horizontal.3", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", [defaults doubleForKey:NeoWCChatInputOuterRadiusKey]], NeoWCSettingActionOuterRadius)];
    NeoWCAddFeature(input, NeoWCItem(@"聊天输入栏圆角", @"分别控制输入框与外部工具栏", @"rectangle.roundedtop", NeoWCSettingRowKindSwitch, NeoWCChatInputRoundingEnabledKey, nil, NeoWCSettingActionNone), roundingChildren, defaults, collapsed);
    NSUInteger hiddenMeCount = [defaults arrayForKey:NeoWCMeMenuHiddenTitlesKey].count;
    [disabled addObject:NeoWCItem(@"我的页面入口管理", @"隐藏作品、小店与卡包或表情入口", @"person.crop.rectangle.stack", NeoWCSettingRowKindDetail, nil, NeoWCCountText(hiddenMeCount), NeoWCSettingActionMeMenu)];
    if (disabledOnly) {
        return @[[NeoWCSettingSection sectionWithIdentifier:@"interface-disabled" title:nil
                                                     footer:@"关闭对应开关后恢复微信原始界面。" items:disabled]];
    }
    return @[
        [NeoWCSettingSection sectionWithIdentifier:@"display" title:@"显示" footer:@"关闭后恢复微信原始样式。" items:display],
        [NeoWCSettingSection sectionWithIdentifier:@"chat-capsules" title:@"聊天顶栏" footer:@"胶囊顶栏与置顶消息同步使用所选玻璃样式；普通磨砂只保留模糊强度。" items:chatCapsules],
        [NeoWCSettingSection sectionWithIdentifier:@"input" title:@"输入栏" footer:nil items:input],
    ];
}

static NSArray<NeoWCSettingSection *> *NeoWCPluginSections(NSUserDefaults *defaults) {
    NSString *notificationSymbol = [defaults stringForKey:NeoWCInAppNotificationSymbolKey] ?: @"automatic";
    NSString *notificationValue = [notificationSymbol isEqualToString:@"automatic"]
        ? @"跟随类型" : @"自定义";
    NSArray<NeoWCSettingItem *> *notifications = @[
        NeoWCItem(@"应用内通知样式", @"调整左侧图标、横幅高度和背景模糊度", @"bell.fill",
                  NeoWCSettingRowKindDetail, nil, notificationValue,
                  NeoWCSettingActionInAppNotificationAppearance),
    ];
    NSArray<NeoWCSettingItem *> *logging = @[
        NeoWCItem(@"记录运行日志", @"关闭后停止新增普通日志，最多保留本次运行 500 条", @"text.alignleft", NeoWCSettingRowKindSwitch, NeoWCLoggingEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"查看运行日志", @"查看、复制或清空本次微信运行记录", @"doc.text.magnifyingglass", NeoWCSettingRowKindDetail, nil,
                  NeoWCCountText(NeoWCLogEntries().count), NeoWCSettingActionLogRecords),
    ];
    NSArray<NeoWCSettingItem *> *management = @[
        NeoWCItem(@"配置管理", @"导入、导出或重置 NeoWC 配置", @"externaldrive", NeoWCSettingRowKindDetail, nil, @"管理", NeoWCSettingActionConfigManager),
        NeoWCItem(@"插件入口管理", @"分类、排序；长按任意开关可添加快捷开关", @"square.stack.3d.up", NeoWCSettingRowKindDetail, nil, @"管理", NeoWCSettingActionPluginManager),
    ];
    (void)defaults;
    return @[
        [NeoWCSettingSection sectionWithIdentifier:@"in-app-notifications" title:@"通知" footer:@"仅影响 NeoWC 在微信前台显示的自绘提醒。" items:notifications],
        [NeoWCSettingSection sectionWithIdentifier:@"logging" title:@"日志" footer:@"运行日志只保存在内存中，退出微信后自动清空。" items:logging],
        [NeoWCSettingSection sectionWithIdentifier:@"plugin-management" title:@"配置与入口" footer:nil items:management],
    ];
}

NSArray<NeoWCSettingSection *> *NeoWCSettingsBuildSections(NeoWCSettingsCategory category,
                                                           NSSet<NSString *> *collapsedFeatureKeys) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSSet *collapsed = collapsedFeatureKeys ?: [NSSet set];
    switch (category) {
        case NeoWCSettingsCategoryMessages: return NeoWCMessageSections(defaults, collapsed);
        case NeoWCSettingsCategoryMoments: return NeoWCEnhancementSections(defaults, collapsed, YES);
        case NeoWCSettingsCategoryInterfaceDisabled: return NeoWCInterfaceSections(defaults, collapsed, YES);
        case NeoWCSettingsCategoryEnhancements: return NeoWCEnhancementSections(defaults, collapsed, NO);
        case NeoWCSettingsCategoryInterface: return NeoWCInterfaceSections(defaults, collapsed, NO);
        case NeoWCSettingsCategoryPlugin: return NeoWCPluginSections(defaults);
        case NeoWCSettingsCategoryRoot:
        default: return NeoWCRootSections();
    }
}
