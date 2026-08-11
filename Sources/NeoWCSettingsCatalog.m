#import "NeoWCSettingsCatalog.h"
#import "NeoWCAccount.h"
#import "NeoWCEnhancements.h"
#import "NeoWCInterfaceTweaks.h"
#import "NeoWCDebug.h"
#import "NeoWCPluginShortcuts.h"
#import <stdlib.h>

NSString *const NeoWCEnabledKey = @"com.qiu7c.neowc.enabled";
NSString *const NeoWCCollapsedFeaturesKey = @"com.qiu7c.neowc.ui.collapsed-features";
static NSString *const NeoWCExpandedCategoriesKey = @"com.qiu7c.neowc.ui.expanded-categories";

NSString *const NeoWCDisplayVersion = @"0.1.2 beta34";

static NeoWCSettingItem *NeoWCItem(NSString *title, NSString *subtitle, NSString *symbol,
                                  NeoWCSettingRowKind kind, NSString *key, NSString *value,
                                  NeoWCSettingAction action) {
    NSString *identifier = key.length > 0 ? key : [NSString stringWithFormat:@"action-%ld", (long)action];
    return [NeoWCSettingItem itemWithIdentifier:identifier title:title subtitle:subtitle symbol:symbol
                                           kind:kind key:key value:value action:action];
}

static NeoWCSettingItem *NeoWCInfoItem(NSString *identifier, NSString *title, NSString *subtitle,
                                      NSString *symbol, NSString *value) {
    return [NeoWCSettingItem itemWithIdentifier:identifier title:title subtitle:subtitle symbol:symbol
                                           kind:NeoWCSettingRowKindInfo key:nil value:value action:NeoWCSettingActionNone];
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

void NeoWCSettingsRegisterDefaults(void) {
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
        NeoWCChatJokerEnabledKey: @NO,
        NeoWCEmoticonToSelfieEnabledKey: @NO,
        NeoWCMomentsForwardEnabledKey: @NO,
        NeoWCReplySwipeEnabledKey: @NO,
        NeoWCQuoteJumpEnabledKey: @NO,
        NeoWCQuoteJumpImageEnabledKey: @YES,
        NeoWCQuoteJumpVideoEnabledKey: @YES,
        NeoWCChatTopBarCapsuleEnabledKey: @NO,
        NeoWCChatTopBarEffectStyleKey: @(NeoWCChatTopBarEffectStyleMaterial),
        NeoWCChatTopBarShadowEnabledKey: @YES,
        NeoWCChatGlassBlurIntensityKey: @100.0,
        NeoWCChatGlassTintOpacityKey: @0.0,
        NeoWCChatTopBarAvatarSizeKey: @30.0,
        NeoWCChatTopBarNicknameSizeKey: @15.0,
        NeoWCMessageBlockEnabledKey: @NO,
        NeoWCMessageBlockUsersKey: @[],
        NeoWCMessageBlockKeywordsKey: @[],
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
        NeoWCQRCodeCameraSourceEnabledKey: @NO,
        NeoWCAutoOriginalImageEnabledKey: @NO,
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
        NeoWCAutoVoiceTranscriptionIgnoreGroupKey: @NO,
        NeoWCAutoVoiceTranscriptionIgnorePrivateKey: @NO,
        NeoWCAutoVoiceTranscriptionIgnoreSelfKey: @YES,
        NeoWCHideScreenshotForwardKey: @NO,
        NeoWCInputSwipeActionsEnabledKey: @NO,
        NeoWCMomentsLikeHapticEnabledKey: @NO,
        NeoWCMomentsLikeHapticIntensityKey: @0.65,
        NeoWCMomentsQuickPermissionsKey: @NO,
        NeoWCMomentsPreciseTimeKey: @NO,
        NeoWCMomentsPreciseTimeFormatKey: NeoWCMomentsPreciseTimeDefaultFormat,
        NeoWCPageScaleEnabledKey: @NO,
        NeoWCPageScaleGlobalPercentKey: @100.0,
        NeoWCSettingsPageScalePercentKey: @100.0,
        NeoWCMultiSelectExportEnabledKey: @NO,
        NeoWCMultiSelectExportTextKey: @YES,
        NeoWCMultiSelectSaveImagesKey: @YES,
        NeoWCMultiSelectShareCardKey: @YES,
        NeoWCDebugLoggingEnabledKey: @YES,
        NeoWCPluginShortcutsEnabledKey: @NO,
        NeoWCPluginShortcutLoggingKey: @YES,
        NeoWCPluginShortcutFloatingDebugKey: @NO,
        NeoWCPluginShortcutDebugCenterKey: @YES,
        NeoWCPluginShortcutRevokeRecordsKey: @NO,
        NeoWCPluginShortcutCustomPageKey: @NO,
        NeoWCPluginShortcutCustomTitleKey: @"快捷页面",
        NeoWCPluginShortcutCustomClassKey: @"",
        NeoWCChatInputRoundingEnabledKey: @NO,
        NeoWCChatInputInnerRoundingKey: @YES,
        NeoWCChatInputOuterRoundingKey: @YES,
        NeoWCChatInputInnerRadiusKey: @18.0,
        NeoWCChatInputOuterRadiusKey: @22.0,
        NeoWCChatInputCapsuleEnabledKey: @NO,
        NeoWCHideChatMuteIconKey: @NO,
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
            NeoWCItem(@"常用增强", @"朋友圈、扫码、运动与本地显示", @"bolt", NeoWCSettingRowKindDetail, nil, nil, NeoWCSettingActionOpenEnhancements),
            NeoWCItem(@"界面优化", @"胶囊、缩放与入口显示", @"paintbrush", NeoWCSettingRowKindDetail, nil, nil, NeoWCSettingActionOpenInterface),
            NeoWCItem(@"开发者功能", @"日志、兼容性与快捷入口", @"hammer", NeoWCSettingRowKindDetail, nil, nil, NeoWCSettingActionOpenDeveloper),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"maintenance" title:@"维护"
                                             footer:[NSString stringWithFormat:@"NeoWC · %@", NeoWCDisplayVersion] items:@[
            NeoWCItem(@"配置管理", @"导入、导出或重置 NeoWC 配置", @"externaldrive", NeoWCSettingRowKindDetail, nil, @"管理", NeoWCSettingActionConfigManager),
            NeoWCInfoItem(@"version", @"版本", @"NeoWC", @"shippingbox", NeoWCDisplayVersion),
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
            : NeoWCItem(@"本地提示模板", @"编辑完整提示内容与文字颜色", @"text.quote", NeoWCSettingRowKindDetail, nil, @"编辑", NeoWCSettingActionRevokeLocalTemplate),
        nil];
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
        NeoWCItem(@"屏蔽会话账号", @"每行一个 wxid 或群聊账号", @"person.crop.circle.badge.xmark", NeoWCSettingRowKindDetail, nil, NeoWCCountText([defaults arrayForKey:NeoWCMessageBlockUsersKey].count), NeoWCSettingActionBlockUsers),
        NeoWCItem(@"屏蔽关键词", @"命中后不加入本地聊天记录", @"text.badge.xmark", NeoWCSettingRowKindDetail, nil, NeoWCCountText([defaults arrayForKey:NeoWCMessageBlockKeywordsKey].count), NeoWCSettingActionBlockKeywords),
    ];
    NeoWCAddFeature(protection, NeoWCItem(@"消息屏蔽", @"按账号或关键词忽略新收到的普通文字", @"eye.slash", NeoWCSettingRowKindSwitch, NeoWCMessageBlockEnabledKey, nil, NeoWCSettingActionNone), blockChildren, defaults, collapsed);
    NSMutableSet *menuTitles = [NSMutableSet setWithArray:[defaults arrayForKey:NeoWCLongPressMenuKnownTitlesKey] ?: @[]];
    [menuTitles addObjectsFromArray:[defaults arrayForKey:NeoWCLongPressMenuManualTitlesKey] ?: @[]];
    NeoWCAddFeature(protection, NeoWCItem(@"长按菜单管理", @"管理聊天消息的原生长按菜单", @"list.bullet.rectangle", NeoWCSettingRowKindSwitch, NeoWCLongPressMenuEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"管理已发现菜单", @"隐藏、排序和重命名已发现菜单", @"slider.horizontal.3", NeoWCSettingRowKindDetail, nil, NeoWCCountText(menuTitles.count), NeoWCSettingActionLongPressMenus)
    ], defaults, collapsed);

    NSMutableArray *interaction = [NSMutableArray arrayWithArray:@[
        NeoWCItem(@"小游戏结果选择", @"支持骰子与猜拳跨类型彩蛋", @"die.face.5", NeoWCSettingRowKindSwitch, NeoWCGameSelectorKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"聊天记录小丑", @"长按消息，仅修改当前页面本机显示", @"square.and.pencil", NeoWCSettingRowKindSwitch, NeoWCChatJokerEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"表情存入自拍", @"在微信原生菜单中存入自拍表情", @"camera", NeoWCSettingRowKindSwitch, NeoWCEmoticonToSelfieEnabledKey, nil, NeoWCSettingActionNone),
    ]];
    NeoWCAddFeature(interaction, NeoWCItem(@"语音自动转文字", @"调用微信原生转文字", @"waveform.and.mic", NeoWCSettingRowKindSwitch, NeoWCAutoVoiceTranscriptionEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"忽略群聊语音", @"群聊中的语音保持原样", @"person.3", NeoWCSettingRowKindSwitch, NeoWCAutoVoiceTranscriptionIgnoreGroupKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"忽略私聊语音", @"私聊中的语音保持原样", @"person", NeoWCSettingRowKindSwitch, NeoWCAutoVoiceTranscriptionIgnorePrivateKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"忽略自己发送", @"不转换自己发出的语音", @"person.crop.circle", NeoWCSettingRowKindSwitch, NeoWCAutoVoiceTranscriptionIgnoreSelfKey, nil, NeoWCSettingActionNone),
    ], defaults, collapsed);
    [interaction addObject:NeoWCItem(@"引用回复手势", @"左滑消息气泡进入微信原生引用回复", @"arrowshape.turn.up.left", NeoWCSettingRowKindSwitch, NeoWCReplySwipeEnabledKey, nil, NeoWCSettingActionNone)];
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
        NeoWCItem(@"通知直达聊天", @"点击通知后进入对应会话", @"bubble.left.and.arrow.forward", NeoWCSettingRowKindSwitch, NeoWCNotificationDirectChatEnabledKey, nil, NeoWCSettingActionNone),
    ]];

    NSMutableArray *media = [NSMutableArray arrayWithArray:@[
        NeoWCItem(@"图片编辑快捷发送", @"在官方图片编辑菜单中发送到当前会话", @"photo.badge.arrow.down", NeoWCSettingRowKindSwitch, NeoWCImageEditQuickSendEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"自动选择原图", @"选择和预览图片时自动勾选原图", @"photo.badge.checkmark", NeoWCSettingRowKindSwitch, NeoWCAutoOriginalImageEnabledKey, nil, NeoWCSettingActionNone),
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
        [NeoWCSettingSection sectionWithIdentifier:@"media-export" title:@"图片与导出" footer:@"图片编辑快捷发送与微信官方转发保持完全隔离。" items:media],
    ];
}

static NSArray<NeoWCSettingSection *> *NeoWCEnhancementSections(NSUserDefaults *defaults, NSSet<NSString *> *collapsed) {
    NSMutableArray *automation = [NSMutableArray arrayWithArray:@[
        NeoWCItem(@"设备扫码自动登录", @"自动确认电脑、平板等设备登录", @"desktopcomputer", NeoWCSettingRowKindSwitch, NeoWCAutoDeviceLoginKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"游戏授权自动允许", @"自动确认游戏扫码授权", @"gamecontroller", NeoWCSettingRowKindSwitch, NeoWCAutoGameAuthorizeKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"伪装扫码来源", @"将相册识别结果按相机扫码处理", @"qrcode.viewfinder", NeoWCSettingRowKindSwitch, NeoWCQRCodeCameraSourceEnabledKey, nil, NeoWCSettingActionNone),
    ]];
    NSMutableArray *moments = [NSMutableArray array];
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
        NeoWCItem(@"朋友圈转发", @"按快捷评论状态选择独立按钮或原菜单", @"arrowshape.turn.up.right", NeoWCSettingRowKindSwitch, NeoWCMomentsForwardEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"朋友圈头像快捷权限", @"长按头像切换朋友权限", @"person.crop.circle.badge.checkmark", NeoWCSettingRowKindSwitch, NeoWCMomentsQuickPermissionsKey, nil, NeoWCSettingActionNone),
    ]];
    NSString *dateFormat = NeoWCNormalizedMomentsDateFormat([defaults stringForKey:NeoWCMomentsPreciseTimeFormatKey]) ?: NeoWCMomentsPreciseTimeDefaultFormat;
    NeoWCAddFeature(moments, NeoWCItem(@"朋友圈精确发布时间", @"显示完整发布时间", @"calendar.badge.clock", NeoWCSettingRowKindSwitch, NeoWCMomentsPreciseTimeKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"朋友圈日期格式", @"支持 yyyy、MM、dd、E、HH、mm、ss", @"textformat", NeoWCSettingRowKindDetail, nil, dateFormat, NeoWCSettingActionMomentsDateFormat)
    ], defaults, collapsed);

    NSMutableArray *local = [NSMutableArray array];
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
    [local addObject:NeoWCItem(@"广告净化", @"拦截朋友圈与小程序启动广告", @"rectangle.badge.xmark", NeoWCSettingRowKindSwitch, NeoWCAdBlockerKey, nil, NeoWCSettingActionNone)];
    return @[
        [NeoWCSettingSection sectionWithIdentifier:@"automation" title:@"自动化" footer:@"自动登录和授权会跳过手动确认，请只在可信环境开启。" items:automation],
        [NeoWCSettingSection sectionWithIdentifier:@"moments" title:@"朋友圈" footer:nil items:moments],
        [NeoWCSettingSection sectionWithIdentifier:@"local-display" title:@"运动与本地显示" footer:@"钱包余额和好友数量只修改本机显示。" items:local],
    ];
}

static NSArray<NeoWCSettingSection *> *NeoWCInterfaceSections(NSUserDefaults *defaults, NSSet<NSString *> *collapsed) {
    NSMutableArray *display = [NSMutableArray array];
    CGFloat globalScale = NeoWCScalePercentForDefaultsKey(NeoWCPageScaleGlobalPercentKey, 100.0);
    CGFloat settingsScale = NeoWCScalePercentForDefaultsKey(NeoWCSettingsPageScalePercentKey, 100.0);
    NeoWCAddFeature(display, NeoWCItem(@"页面缩放", @"按微信字体规则缩放页面", @"textformat.size", NeoWCSettingRowKindSwitch, NeoWCPageScaleEnabledKey, nil, NeoWCSettingActionNone), @[
        NeoWCItem(@"全局页面缩放比例", @"作用于微信字体规则与网页文字", @"rectangle.compress.vertical", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f%%", globalScale], NeoWCSettingActionGlobalScale),
        NeoWCItem(@"NeoWC 设置页缩放比例", @"仅调整本设置页", @"list.bullet.rectangle", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f%%", settingsScale], NeoWCSettingActionSettingsScale),
    ], defaults, collapsed);
    [display addObjectsFromArray:@[
        NeoWCItem(@"隐藏群标题尾部", @"隐藏群人数和免打扰标记并居中群名", @"bell.slash", NeoWCSettingRowKindSwitch, NeoWCHideChatMuteIconKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"隐藏截屏分享按钮", @"不显示右下角截图转发浮层", @"rectangle.on.rectangle.slash", NeoWCSettingRowKindSwitch, NeoWCHideScreenshotForwardKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"全局去除分割线", @"按参考插件规则隐藏页面细线", @"rectangle.split.1x2", NeoWCSettingRowKindSwitch, NeoWCHideSeparatorLinesKey, nil, NeoWCSettingActionNone),
    ]];
    NSMutableArray *chatCapsules = [NSMutableArray array];
    BOOL supportsLiquidGlass = NeoWCSystemSupportsNativeLiquidGlass();
    BOOL usesLiquidGlass = supportsLiquidGlass &&
        [defaults integerForKey:NeoWCChatTopBarEffectStyleKey] == NeoWCChatTopBarEffectStyleLiquid;
    NeoWCAddFeature(chatCapsules,
                    NeoWCItem(@"胶囊顶栏", @"隐藏整条顶栏背景，左右使用玻璃胶囊", @"capsule", NeoWCSettingRowKindSwitch, NeoWCChatTopBarCapsuleEnabledKey, nil, NeoWCSettingActionNone),
                    @[
        NeoWCItem(@"头像大小", @"限制在 24 到 34 之间", @"person.crop.circle", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", [defaults doubleForKey:NeoWCChatTopBarAvatarSizeKey]], NeoWCSettingActionChatTopAvatarSize),
        NeoWCItem(@"昵称字号", @"限制在 12 到 18 之间", @"textformat.size", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", [defaults doubleForKey:NeoWCChatTopBarNicknameSizeKey]], NeoWCSettingActionChatTopNicknameSize),
    ], defaults, collapsed);
    [chatCapsules addObject:NeoWCItem(@"胶囊工具栏", @"语音与输入框、表情与更多分为左右玻璃胶囊", @"capsule", NeoWCSettingRowKindSwitch, NeoWCChatInputCapsuleEnabledKey, nil, NeoWCSettingActionNone)];
    [chatCapsules addObjectsFromArray:@[
        NeoWCItem(@"玻璃类型", supportsLiquidGlass ? @"顶栏与工具栏共同使用" : @"iOS 26 以下仅支持超薄玻璃", @"circle.lefthalf.filled", NeoWCSettingRowKindDetail, nil, NeoWCCurrentSelection(usesLiquidGlass ? @"液态玻璃" : @"超薄玻璃"), NeoWCSettingActionChatTopEffectStyle),
        NeoWCItem(@"模糊强度", @"顶栏与工具栏共同使用，限制在 20% 到 100%", @"drop.halffull", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f%%", [defaults doubleForKey:NeoWCChatGlassBlurIntensityKey]], NeoWCSettingActionChatGlassBlurIntensity),
        NeoWCItem(@"染色强度", @"使用系统背景色轻微统一玻璃明暗，限制在 0% 到 30%", @"paintpalette", NeoWCSettingRowKindDetail, nil, [NSString stringWithFormat:@"%.0f%%", [defaults doubleForKey:NeoWCChatGlassTintOpacityKey]], NeoWCSettingActionChatGlassTintOpacity),
        NeoWCItem(@"胶囊阴影", @"顶栏与工具栏共同使用的轻微环境阴影", @"circle.dotted", NeoWCSettingRowKindSwitch, NeoWCChatTopBarShadowEnabledKey, nil, NeoWCSettingActionNone),
    ]];
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
    NSArray *management = @[
        NeoWCItem(@"我的页面入口管理", @"隐藏作品、小店与卡包或表情入口", @"person.crop.rectangle.stack", NeoWCSettingRowKindDetail, nil, NeoWCCountText(hiddenMeCount), NeoWCSettingActionMeMenu),
        NeoWCItem(@"插件显示管理", @"隐藏其他插件入口并检测加载状态", @"square.stack.3d.up", NeoWCSettingRowKindDetail, nil, @"管理", NeoWCSettingActionPluginVisibility),
    ];
    return @[
        [NeoWCSettingSection sectionWithIdentifier:@"display" title:@"显示" footer:@"关闭后恢复微信原始样式。" items:display],
        [NeoWCSettingSection sectionWithIdentifier:@"chat-capsules" title:@"聊天胶囊" footer:@"玻璃参数由顶栏与工具栏共同使用。" items:chatCapsules],
        [NeoWCSettingSection sectionWithIdentifier:@"input" title:@"输入栏" footer:nil items:input],
        [NeoWCSettingSection sectionWithIdentifier:@"entry-management" title:@"入口管理" footer:nil items:management],
    ];
}

static NSArray<NeoWCSettingSection *> *NeoWCDeveloperSections(NSUserDefaults *defaults, NSSet<NSString *> *collapsed) {
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        NeoWCItem(@"调试悬浮按钮", @"仅由此开关控制，不监听全局手势", @"wrench.and.screwdriver", NeoWCSettingRowKindSwitch, NeoWCDebugFloatingEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"记录调试日志", @"关闭后停止新增运行日志", @"text.alignleft", NeoWCSettingRowKindSwitch, NeoWCDebugLoggingEnabledKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"调试中心", @"视图检查、Runtime 搜索与日志", @"ladybug", NeoWCSettingRowKindDetail, nil, @"打开", NeoWCSettingActionDebugCenter),
        NeoWCItem(@"功能兼容性", @"检查类、Selector 与触发状态", @"checklist", NeoWCSettingRowKindDetail, nil, @"检查", NeoWCSettingActionCompatibility),
    ]];
    NSMutableArray *shortcutChildren = [NSMutableArray arrayWithArray:@[
        NeoWCItem(@"快捷日志开关", @"在插件管理页直接开关日志", @"text.alignleft", NeoWCSettingRowKindSwitch, NeoWCPluginShortcutLoggingKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"快捷悬浮窗开关", @"在插件管理页直接开关悬浮窗", @"wrench.and.screwdriver", NeoWCSettingRowKindSwitch, NeoWCPluginShortcutFloatingDebugKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"直达调试中心", @"增加独立页面入口", @"ladybug", NeoWCSettingRowKindSwitch, NeoWCPluginShortcutDebugCenterKey, nil, NeoWCSettingActionNone),
        NeoWCItem(@"直达防撤回记录", @"增加撤回记录入口", @"tray.full", NeoWCSettingRowKindSwitch, NeoWCPluginShortcutRevokeRecordsKey, nil, NeoWCSettingActionNone),
    ]];
    NeoWCSettingItem *custom = NeoWCItem(@"自定义页面入口", @"输入 Controller 或 View 类名", @"rectangle.and.hand.point.up.left", NeoWCSettingRowKindSwitch, NeoWCPluginShortcutCustomPageKey, nil, NeoWCSettingActionNone);
    custom.hasChildren = YES;
    [shortcutChildren addObject:custom];
    if ([defaults boolForKey:NeoWCPluginShortcutCustomPageKey] && ![collapsed containsObject:NeoWCPluginShortcutCustomPageKey]) {
        NSString *title = [defaults stringForKey:NeoWCPluginShortcutCustomTitleKey] ?: @"快捷页面";
        NSString *className = [defaults stringForKey:NeoWCPluginShortcutCustomClassKey] ?: @"";
        [shortcutChildren addObjectsFromArray:@[
            NeoWCItem(@"自定义入口名称", @"显示在插件管理页面中的名称", @"textformat", NeoWCSettingRowKindDetail, nil, title, NeoWCSettingActionPluginShortcutTitle),
            NeoWCItem(@"页面 Runtime 类名", @"支持 UIViewController 或 UIView 子类", @"chevron.left.forwardslash.chevron.right", NeoWCSettingRowKindDetail, nil, className.length ? className : @"输入", NeoWCSettingActionPluginShortcutClass),
        ]];
    }
    NeoWCAddFeature(items, NeoWCItem(@"插件管理快捷入口", @"注册常用开关或页面", @"bolt.badge.clock", NeoWCSettingRowKindSwitch, NeoWCPluginShortcutsEnabledKey, nil, NeoWCSettingActionNone), shortcutChildren, defaults, collapsed);
    return @[[NeoWCSettingSection sectionWithIdentifier:@"developer" title:nil footer:@"快捷入口关闭或改名后，重启微信即可彻底移除旧入口。" items:items]];
}

NSArray<NeoWCSettingSection *> *NeoWCSettingsBuildSections(NeoWCSettingsCategory category,
                                                           NSSet<NSString *> *collapsedFeatureKeys) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSSet *collapsed = collapsedFeatureKeys ?: [NSSet set];
    switch (category) {
        case NeoWCSettingsCategoryMessages: return NeoWCMessageSections(defaults, collapsed);
        case NeoWCSettingsCategoryEnhancements: return NeoWCEnhancementSections(defaults, collapsed);
        case NeoWCSettingsCategoryInterface: return NeoWCInterfaceSections(defaults, collapsed);
        case NeoWCSettingsCategoryDeveloper: return NeoWCDeveloperSections(defaults, collapsed);
        case NeoWCSettingsCategoryRoot:
        default: return NeoWCRootSections();
    }
}
