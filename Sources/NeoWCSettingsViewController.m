#import "NeoWCSettingsViewController.h"
#import "NeoWCAccount.h"
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
#import "NeoWCInterfaceTweaks.h"
#import <stdlib.h>

static NSString *const NeoWCVersion = @"0.1.2";
static NSString *const NeoWCEnabledKey = @"com.qiu7c.neowc.enabled";
static NSString *const NeoWCExpandedCategoriesKey = @"com.qiu7c.neowc.ui.expanded-categories";
static NSString *const NeoWCCollapsedFeaturesKey = @"com.qiu7c.neowc.ui.collapsed-features";

static long long NeoWCSettingsLongLongDefaultForKey(NSString *key) {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return [value respondsToSelector:@selector(longLongValue)] ? [value longLongValue] : 0;
}

static NSString *NeoWCSettingsCountText(NSUInteger count) {
    return count > 0 ? [NSString stringWithFormat:@"%lu 项", (unsigned long)count] : @"设置";
}

static void NeoWCSettingsRegenerateDailyStepTarget(NSUserDefaults *defaults) {
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
        [defaults setObject:[NSDate date] forKey:NeoWCStepCountDateKey];
    } else {
        [defaults removeObjectForKey:NeoWCStepDailyTargetKey];
        [defaults removeObjectForKey:NeoWCStepCountDateKey];
    }
}

static UIImage *NeoWCSymbol(NSString *name) {
    UIImage *image = [UIImage systemImageNamed:name];
    return image ?: [UIImage systemImageNamed:@"circle.grid.2x2"];
}

typedef NS_ENUM(NSInteger, NeoWCRowKind) {
    NeoWCRowKindSwitch,
    NeoWCRowKindDetail,
    NeoWCRowKindInfo,
    NeoWCRowKindCopy,
};

@interface NeoWCSettingItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy) NSString *defaultsKey;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, assign) NeoWCRowKind kind;
+ (instancetype)itemWithTitle:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol kind:(NeoWCRowKind)kind key:(NSString *)key value:(NSString *)value;
@end

@implementation NeoWCSettingItem
+ (instancetype)itemWithTitle:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol kind:(NeoWCRowKind)kind key:(NSString *)key value:(NSString *)value {
    NeoWCSettingItem *item = [self new];
    item.title = title;
    item.subtitle = subtitle;
    item.symbol = symbol;
    item.kind = kind;
    item.defaultsKey = key;
    item.value = value;
    return item;
}
@end

@interface NeoWCSettingSection : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy) NSString *footer;
@property (nonatomic, copy) NSArray<NeoWCSettingItem *> *items;
@property (nonatomic, assign, getter=isCollapsible) BOOL collapsible;
+ (instancetype)sectionWithIdentifier:(NSString *)identifier title:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol footer:(NSString *)footer collapsible:(BOOL)collapsible items:(NSArray<NeoWCSettingItem *> *)items;
@end

@implementation NeoWCSettingSection
+ (instancetype)sectionWithIdentifier:(NSString *)identifier title:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol footer:(NSString *)footer collapsible:(BOOL)collapsible items:(NSArray<NeoWCSettingItem *> *)items {
    NeoWCSettingSection *section = [self new];
    section.identifier = identifier;
    section.title = title;
    section.subtitle = subtitle;
    section.symbol = symbol;
    section.footer = footer;
    section.collapsible = collapsible;
    section.items = items;
    return section;
}
@end

@interface NeoWCCardBackgroundView : UIView
@property (nonatomic, assign) BOOL roundsTop;
@property (nonatomic, assign) BOOL roundsBottom;
@property (nonatomic, assign) BOOL drawsDivider;
@property (nonatomic, strong) UIColor *fillColor;
@end

@implementation NeoWCCardBackgroundView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        _fillColor = [UIColor secondarySystemBackgroundColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGRect cardRect = CGRectInset(self.bounds, 16.0, 0.0);
    UIRectCorner corners = 0;
    if (self.roundsTop) corners |= UIRectCornerTopLeft | UIRectCornerTopRight;
    if (self.roundsBottom) corners |= UIRectCornerBottomLeft | UIRectCornerBottomRight;
    UIBezierPath *path = corners ? [UIBezierPath bezierPathWithRoundedRect:cardRect byRoundingCorners:corners cornerRadii:CGSizeMake(11.0, 11.0)] : [UIBezierPath bezierPathWithRect:cardRect];
    [self.fillColor setFill];
    [path fill];

    if (self.drawsDivider) {
        CGFloat pixel = 1.0 / UIScreen.mainScreen.scale;
        [[[UIColor separatorColor] colorWithAlphaComponent:0.28] setFill];
        UIRectFill(CGRectMake(CGRectGetMinX(cardRect) + 48.0, 0.0, CGRectGetWidth(cardRect) - 64.0, pixel));
    }
}

@end

@interface NeoWCLogoView : UIView
@end

@implementation NeoWCLogoView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = @"NeoWC 图标";
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGFloat scale = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect)) / 64.0;
    UIBezierPath *monogram = [UIBezierPath bezierPath];
    [monogram moveToPoint:CGPointMake(16.0 * scale, 44.0 * scale)];
    [monogram addLineToPoint:CGPointMake(16.0 * scale, 20.0 * scale)];
    [monogram addLineToPoint:CGPointMake(48.0 * scale, 44.0 * scale)];
    [monogram addLineToPoint:CGPointMake(48.0 * scale, 20.0 * scale)];
    [monogram moveToPoint:CGPointMake(48.0 * scale, 44.0 * scale)];
    [monogram addLineToPoint:CGPointMake(40.5 * scale, 51.0 * scale)];
    monogram.lineWidth = 4.0 * scale;
    monogram.lineCapStyle = kCGLineCapRound;
    monogram.lineJoinStyle = kCGLineJoinRound;
    [[UIColor labelColor] setStroke];
    [monogram stroke];
}

@end

@interface NeoWCSettingsViewController ()
@property (nonatomic, copy) NSArray<NeoWCSettingSection *> *sections;
@property (nonatomic, strong) NSMutableSet<NSString *> *expandedCategoryIDs;
@property (nonatomic, strong) NSMutableSet<NSString *> *collapsedFeatureKeys;
@end


@implementation NeoWCSettingsViewController

- (instancetype)init {
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) [self buildSections];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
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
        NeoWCChatSearchButtonEnabledKey: @NO,
        NeoWCGroupAtTipsEnabledKey: @NO,
        NeoWCChatMessageTimeEnabledKey: @NO,
        NeoWCChatMessageTimeBelowAvatarKey: @YES,
        NeoWCChatMessageTimeBubbleSideKey: @NO,
        NeoWCChatMessageTimeFormatKey: @"MM-dd HH:mm:ss",
        NeoWCChatMessageTimeFontSizeKey: @10.0,
        NeoWCChatMessageTimeColorKey: @"#8E8E93FF",
        NeoWCMessageBlockEnabledKey: @NO,
        NeoWCMessageBlockUsersKey: @[],
        NeoWCMessageBlockKeywordsKey: @[],
        NeoWCLongPressMenuEnabledKey: @NO,
        NeoWCLongPressMenuHiddenTitlesKey: @[],
        NeoWCLongPressMenuPreferredOrderKey: @[],
        NeoWCLongPressMenuTitleMapKey: @{},
        NeoWCLongPressMenuManualTitlesKey: @[],
        NeoWCGroupMemberReminderEnabledKey: @NO,
        NeoWCKeywordReminderEnabledKey: @NO,
        NeoWCKeywordReminderKeywordsKey: @[],
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
        NeoWCHideChatMuteIconKey: @NO,
        NeoWCExpandedCategoriesKey: @[@"messages"],
        NeoWCCollapsedFeaturesKey: @[],
    }];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:NeoWCChatMessageTimeBelowAvatarKey] &&
        [defaults boolForKey:NeoWCChatMessageTimeBubbleSideKey]) {
        [defaults setBool:NO forKey:NeoWCChatMessageTimeBubbleSideKey];
    }
    NSSet<NSString *> *supportedMeTitles = [NSSet setWithArray:@[@"作品", @"小店与卡包", @"表情"]];
    NSArray<NSString *> *hiddenMeTitles = [defaults arrayForKey:NeoWCMeMenuHiddenTitlesKey] ?: @[];
    NSArray<NSString *> *filteredMeTitles = [hiddenMeTitles filteredArrayUsingPredicate:
        [NSPredicate predicateWithBlock:^BOOL(NSString *title, NSDictionary *bindings) {
            (void)bindings;
            return [supportedMeTitles containsObject:title];
        }]];
    if (![filteredMeTitles isEqualToArray:hiddenMeTitles]) [defaults setObject:filteredMeTitles forKey:NeoWCMeMenuHiddenTitlesKey];
    NSArray *savedCategories = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCExpandedCategoriesKey];
    self.expandedCategoryIDs = [NSMutableSet setWithArray:savedCategories ?: @[]];
    NSArray *collapsedFeatures = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCCollapsedFeaturesKey];
    self.collapsedFeatureKeys = [NSMutableSet setWithArray:collapsedFeatures ?: @[]];
    [self buildSections];

    self.title = @"NeoWC";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.rowHeight = 60.0;
    self.tableView.estimatedRowHeight = 60.0;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 58.0;
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 44.0;
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    self.tableView.tableHeaderView = [self makeHeaderView];
    if (@available(iOS 15.0, *)) self.tableView.sectionHeaderTopPadding = 0.0;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"NeoWCSettingCell"];
    [self applySettingsPageScale];
}

- (void)applySettingsPageScale {
    CGFloat percent = NeoWCEnhancementEnabled(NeoWCPageScaleEnabledKey)
        ? NeoWCScalePercentForDefaultsKey(NeoWCSettingsPageScalePercentKey, 100.0)
        : 100.0;
    CGFloat scale = percent / 100.0;
    self.tableView.rowHeight = MAX(48.0, 60.0 * scale);
    self.tableView.estimatedRowHeight = self.tableView.rowHeight;
    self.tableView.estimatedSectionHeaderHeight = MAX(44.0, 58.0 * scale);
    self.tableView.estimatedSectionFooterHeight = MAX(34.0, 44.0 * scale);
    self.tableView.tableHeaderView = [self makeHeaderView];
}

- (CGFloat)settingsPageScale {
    if (!NeoWCEnhancementEnabled(NeoWCPageScaleEnabledKey)) return 1.0;
    return NeoWCScalePercentForDefaultsKey(NeoWCSettingsPageScalePercentKey, 100.0) / 100.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGPoint offset = self.tableView.contentOffset;
    [self applySettingsPageScale];
    [self buildSections];
    [UIView performWithoutAnimation:^{
        [self.tableView reloadData];
        [self.tableView setContentOffset:offset animated:NO];
    }];
}

- (void)reloadSettingsPreservingPosition {
    CGPoint offset = self.tableView.contentOffset;
    [self buildSections];
    [UIView performWithoutAnimation:^{
        [self.tableView reloadData];
        [self.tableView setContentOffset:offset animated:NO];
    }];
}

- (BOOL)featureHasChildrenForKey:(NSString *)key {
    if (key.length == 0) return NO;
    static NSSet<NSString *> *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = [NSSet setWithArray:@[
            NeoWCAntiRevokeKey,
            NeoWCAntiRevokeNotifySenderKey,
            NeoWCMomentsDoubleTapLikeKey,
            NeoWCMomentsLikeHapticEnabledKey,
            NeoWCMomentsPreciseTimeKey,
            NeoWCPageScaleEnabledKey,
            NeoWCStepOverrideEnabledKey,
            NeoWCContactsCountEnabledKey,
            NeoWCMultiSelectExportEnabledKey,
            NeoWCMessageBlockEnabledKey,
            NeoWCKeywordReminderEnabledKey,
            NeoWCChatMessageTimeEnabledKey,
            NeoWCRedEnvelopeDetailEnabledKey,
            NeoWCLongPressMenuEnabledKey,
            NeoWCWalletBalanceEnabledKey,
            NeoWCPluginShortcutsEnabledKey,
            NeoWCPluginShortcutCustomPageKey,
            NeoWCChatInputRoundingEnabledKey,
            NeoWCAutoVoiceTranscriptionEnabledKey,
        ]];
    });
    return [keys containsObject:key];
}

- (BOOL)isFeatureExpandedForKey:(NSString *)key {
    return ![self.collapsedFeatureKeys containsObject:key];
}

- (void)saveCollapsedFeatureKeys {
    [[NSUserDefaults standardUserDefaults] setObject:self.collapsedFeatureKeys.allObjects forKey:NeoWCCollapsedFeaturesKey];
}

- (void)buildSections {
    NeoWCSettingItem *(^item)(NSString *, NSString *, NSString *, NeoWCRowKind, NSString *, NSString *) =
    ^NeoWCSettingItem *(NSString *title, NSString *subtitle, NSString *symbol, NeoWCRowKind kind, NSString *key, NSString *value) {
        return [NeoWCSettingItem itemWithTitle:title subtitle:subtitle symbol:symbol kind:kind key:key value:value];
    };
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger configuredStepCount = [defaults integerForKey:NeoWCStepCountKey];
    NSInteger effectiveStepCount = [defaults integerForKey:NeoWCStepDailyTargetKey];
    NSDate *effectiveStepDate = [defaults objectForKey:NeoWCStepCountDateKey];
    BOOL hasTodayStepCount = effectiveStepCount > 0 && [effectiveStepDate isKindOfClass:[NSDate class]] && [[NSCalendar currentCalendar] isDateInToday:effectiveStepDate];
    NSString *stepValue = hasTodayStepCount ? [NSString stringWithFormat:@"%ld 步", (long)effectiveStepCount] : @"待生成";
    NeoWCStepMode stepMode = (NeoWCStepMode)[defaults integerForKey:NeoWCStepModeKey];
    if (stepMode != NeoWCStepModeDailyRandom) stepMode = NeoWCStepModeDailyFixed;
    NSString *stepModeText = stepMode == NeoWCStepModeDailyRandom ? @"每日随机" : @"每日固定";
    NSInteger contactsCount = [defaults integerForKey:NeoWCContactsCountKey];
    NSString *contactsValue = contactsCount > 0 ? [NSString stringWithFormat:@"%ld 个", (long)contactsCount] : @"设置";
    NSTimeInterval revokeFilter = [defaults doubleForKey:NeoWCAntiRevokeTimeFilterKey];
    NSString *revokeFilterValue = @"不限制";
    if (revokeFilter >= 86400.0) revokeFilterValue = @"24 小时";
    else if (revokeFilter >= 3600.0) revokeFilterValue = @"1 小时";
    else if (revokeFilter >= 1800.0) revokeFilterValue = @"30 分钟";
    else if (revokeFilter >= 300.0) revokeFilterValue = @"5 分钟";
    else if (revokeFilter >= 60.0) revokeFilterValue = @"1 分钟";
    NSInteger revokePromptStyleValue = [defaults integerForKey:NeoWCAntiRevokePromptStyleKey];
    id antiRevokeValue = [defaults objectForKey:NeoWCAntiRevokeKey];
    BOOL antiRevokeEnabled = antiRevokeValue ? [antiRevokeValue boolValue] : YES;
    BOOL notifySenderEnabled = [defaults boolForKey:NeoWCAntiRevokeNotifySenderKey];
    BOOL stepOverrideEnabled = [defaults boolForKey:NeoWCStepOverrideEnabledKey];
    BOOL momentsLikeEnabled = [defaults boolForKey:NeoWCMomentsDoubleTapLikeKey];
    BOOL momentsHapticEnabled = [defaults boolForKey:NeoWCMomentsLikeHapticEnabledKey];
    BOOL momentsPreciseTimeEnabled = [defaults boolForKey:NeoWCMomentsPreciseTimeKey];
    NSString *momentsDateFormat = NeoWCNormalizedMomentsDateFormat([defaults stringForKey:NeoWCMomentsPreciseTimeFormatKey]) ?: NeoWCMomentsPreciseTimeDefaultFormat;
    BOOL pageScaleEnabled = [defaults boolForKey:NeoWCPageScaleEnabledKey];
    CGFloat globalScalePercent = NeoWCScalePercentForDefaultsKey(NeoWCPageScaleGlobalPercentKey, 100.0);
    CGFloat settingsScalePercent = NeoWCScalePercentForDefaultsKey(NeoWCSettingsPageScalePercentKey, 100.0);
    BOOL multiSelectExportEnabled = [defaults boolForKey:NeoWCMultiSelectExportEnabledKey];
    BOOL contactsCountEnabled = [defaults boolForKey:NeoWCContactsCountEnabledKey];
    BOOL messageBlockEnabled = [defaults boolForKey:NeoWCMessageBlockEnabledKey];
    BOOL keywordReminderEnabled = [defaults boolForKey:NeoWCKeywordReminderEnabledKey];
    BOOL longPressMenuEnabled = [defaults boolForKey:NeoWCLongPressMenuEnabledKey];
    BOOL walletBalanceEnabled = [defaults boolForKey:NeoWCWalletBalanceEnabledKey];
    NSUInteger blockedUserCount = [defaults arrayForKey:NeoWCMessageBlockUsersKey].count;
    NSUInteger blockedKeywordCount = [defaults arrayForKey:NeoWCMessageBlockKeywordsKey].count;
    NSUInteger reminderKeywordCount = [defaults arrayForKey:NeoWCKeywordReminderKeywordsKey].count;
    NSMutableSet<NSString *> *managedMenuTitles = [NSMutableSet setWithArray:[defaults arrayForKey:NeoWCLongPressMenuKnownTitlesKey] ?: @[]];
    [managedMenuTitles addObjectsFromArray:[defaults arrayForKey:NeoWCLongPressMenuManualTitlesKey] ?: @[]];
    NSUInteger discoveredMenuCount = managedMenuTitles.count;
    BOOL pluginShortcutsEnabled = [defaults boolForKey:NeoWCPluginShortcutsEnabledKey];
    BOOL inputRoundingEnabled = [defaults boolForKey:NeoWCChatInputRoundingEnabledKey];
    NSString *revokePromptStyle = revokePromptStyleValue == 1 ? @"气泡旁" : @"消息下方";
    NSString *sidePromptText = [defaults stringForKey:NeoWCAntiRevokeSideTextKey] ?: @"已拦截撤回";
    id storedSideOffsetX = [defaults objectForKey:NeoWCAntiRevokeSideOffsetXKey];
    id storedSideOffsetY = [defaults objectForKey:NeoWCAntiRevokeSideOffsetYKey];
    NSString *sideOffsetX = [NSString stringWithFormat:@"%.0f", storedSideOffsetX ? [storedSideOffsetX doubleValue] : 0.0];
    NSString *sideOffsetY = [NSString stringWithFormat:@"%.0f", storedSideOffsetY ? [storedSideOffsetY doubleValue] : 10.0];
    NSString *currentWXID = NeoWCCurrentUserWXID();

    NSMutableArray<NeoWCSettingItem *> *messageItems = [NSMutableArray array];
    [messageItems addObject:item(@"防撤回", @"保留好友撤回的消息并显示提示", @"arrow.uturn.backward.circle", NeoWCRowKindSwitch, NeoWCAntiRevokeKey, nil)];
    if (antiRevokeEnabled && [self isFeatureExpandedForKey:NeoWCAntiRevokeKey]) {
        [messageItems addObject:item(@"防撤回提示方案", [NSString stringWithFormat:@"当前方案：%@", revokePromptStyle], @"text.bubble.fill", NeoWCRowKindDetail, nil, revokePromptStyle)];
        if (revokePromptStyleValue == 1) {
            NSString *appearanceValue = [NSString stringWithFormat:@"%@ · X %@ / Y %@", sidePromptText, sideOffsetX, sideOffsetY];
            [messageItems addObject:item(@"提示外观预览", @"调整文字、颜色，并拖动或输入 X / Y", @"cursorarrow.motionlines", NeoWCRowKindDetail, nil, appearanceValue)];
        } else {
            [messageItems addObject:item(@"本地提示模板", @"编辑完整提示内容与文字颜色", @"text.bubble", NeoWCRowKindDetail, nil, @"编辑")];
        }
        [messageItems addObject:item(@"回复撤回者", @"自动发送提示，默认关闭", @"paperplane", NeoWCRowKindSwitch, NeoWCAntiRevokeNotifySenderKey, nil)];
        if (notifySenderEnabled && [self isFeatureExpandedForKey:NeoWCAntiRevokeNotifySenderKey]) {
            [messageItems addObject:item(@"回复时间限制", @"避免响应很久以前的撤回事件", @"timer", NeoWCRowKindDetail, nil, revokeFilterValue)];
            [messageItems addObject:item(@"回复消息模板", @"设置发送给撤回者的提示", @"text.quote", NeoWCRowKindDetail, nil, @"编辑")];
        }
        [messageItems addObject:item(@"防撤回记录中心", @"搜索本次运行期间拦截的撤回消息", @"tray.full", NeoWCRowKindDetail, nil, @"查看")];
        [messageItems addObject:item(@"本地保存撤回记录", @"默认关闭；仅保存摘要和分类", @"internaldrive", NeoWCRowKindSwitch, NeoWCAntiRevokePersistRecordsKey, nil)];
    }
    [messageItems addObject:item(@"小游戏结果选择", @"支持骰子与猜拳跨类型彩蛋", @"die.face.5", NeoWCRowKindSwitch, NeoWCGameSelectorKey, nil)];
    [messageItems addObject:item(@"聊天记录小丑", @"长按文字、应用、图片或转账消息，本地修改当前页面显示", @"square.and.pencil", NeoWCRowKindSwitch, NeoWCChatJokerEnabledKey, nil)];
    [messageItems addObject:item(@"表情存入自拍", @"长按表情，在微信原生菜单中存入自拍表情", @"camera", NeoWCRowKindSwitch, NeoWCEmoticonToSelfieEnabledKey, nil)];
    [messageItems addObject:item(@"语音自动转文字", @"语音气泡出现后调用微信原生转文字", @"waveform.and.mic", NeoWCRowKindSwitch, NeoWCAutoVoiceTranscriptionEnabledKey, nil)];
    if ([defaults boolForKey:NeoWCAutoVoiceTranscriptionEnabledKey] &&
        [self isFeatureExpandedForKey:NeoWCAutoVoiceTranscriptionEnabledKey]) {
        [messageItems addObject:item(@"忽略群聊语音", @"群聊中的语音保持原样", @"person.3", NeoWCRowKindSwitch, NeoWCAutoVoiceTranscriptionIgnoreGroupKey, nil)];
        [messageItems addObject:item(@"忽略私聊语音", @"私聊中的语音保持原样", @"person", NeoWCRowKindSwitch, NeoWCAutoVoiceTranscriptionIgnorePrivateKey, nil)];
        [messageItems addObject:item(@"忽略自己发送", @"不自动转换自己发出的语音", @"person.crop.circle", NeoWCRowKindSwitch, NeoWCAutoVoiceTranscriptionIgnoreSelfKey, nil)];
    }
    [messageItems addObject:item(@"引用回复手势", @"左滑消息气泡直接进入微信原生引用回复", @"arrowshape.turn.up.left", NeoWCRowKindSwitch, NeoWCReplySwipeEnabledKey, nil)];
    [messageItems addObject:item(@"引用消息定位", @"点击文字、图片或视频引用，调用微信原生定位入口", @"arrow.up.and.down.text.horizontal", NeoWCRowKindSwitch, NeoWCQuoteJumpEnabledKey, nil)];
    [messageItems addObject:item(@"聊天搜索按钮", @"在聊天页右上角加入微信原生聊天记录搜索", @"magnifyingglass", NeoWCRowKindSwitch, NeoWCChatSearchButtonEnabledKey, nil)];
    [messageItems addObject:item(@"消息时间标签", @"按消息创建时间显示在头像下方或气泡旁", @"clock", NeoWCRowKindSwitch, NeoWCChatMessageTimeEnabledKey, nil)];
    if ([defaults boolForKey:NeoWCChatMessageTimeEnabledKey] && [self isFeatureExpandedForKey:NeoWCChatMessageTimeEnabledKey]) {
        [messageItems addObject:item(@"头像下方时间", @"以消息头像为锚点显示时间", @"person.crop.circle.badge.clock", NeoWCRowKindSwitch, NeoWCChatMessageTimeBelowAvatarKey, nil)];
        [messageItems addObject:item(@"气泡旁时间", @"以消息气泡为锚点显示时间", @"message.badge", NeoWCRowKindSwitch, NeoWCChatMessageTimeBubbleSideKey, nil)];
        [messageItems addObject:item(@"时间标签格式", @"NSDateFormatter 格式，例如 MM-dd HH:mm:ss", @"textformat", NeoWCRowKindDetail, nil, [defaults stringForKey:NeoWCChatMessageTimeFormatKey])];
    }
    [messageItems addObject:item(@"消息屏蔽", @"按会话账号或关键词忽略新收到的普通文字消息", @"eye.slash", NeoWCRowKindSwitch, NeoWCMessageBlockEnabledKey, nil)];
    if (messageBlockEnabled && [self isFeatureExpandedForKey:NeoWCMessageBlockEnabledKey]) {
        [messageItems addObject:item(@"屏蔽会话账号", @"每行一个 wxid 或群聊账号", @"person.crop.circle.badge.xmark", NeoWCRowKindDetail, nil, NeoWCSettingsCountText(blockedUserCount))];
        [messageItems addObject:item(@"屏蔽关键词", @"命中后不加入本地聊天记录", @"text.badge.xmark", NeoWCRowKindDetail, nil, NeoWCSettingsCountText(blockedKeywordCount))];
    }
    [messageItems addObject:item(@"长按菜单管理", @"统一管理聊天消息的原生长按菜单", @"list.bullet.rectangle", NeoWCRowKindSwitch, NeoWCLongPressMenuEnabledKey, nil)];
    if (longPressMenuEnabled && [self isFeatureExpandedForKey:NeoWCLongPressMenuEnabledKey]) {
        [messageItems addObject:item(@"管理已发现菜单", @"自动获取或手动添加，可隐藏、排序和重命名", @"slider.horizontal.3", NeoWCRowKindDetail, nil, NeoWCSettingsCountText(discoveredMenuCount))];
    }
    [messageItems addObject:item(@"群成员进退群提醒", @"根据群成员列表变化显示本地提醒", @"person.2.badge.gearshape", NeoWCRowKindSwitch, NeoWCGroupMemberReminderEnabledKey, nil)];
    [messageItems addObject:item(@"群聊艾特提示", @"汇总群聊中提到我的消息并使用原生边缘提示", @"at", NeoWCRowKindSwitch, NeoWCGroupAtTipsEnabledKey, nil)];
    [messageItems addObject:item(@"关键词提醒", @"新收到的普通文字命中关键词时提醒", @"bell.badge", NeoWCRowKindSwitch, NeoWCKeywordReminderEnabledKey, nil)];
    if (keywordReminderEnabled && [self isFeatureExpandedForKey:NeoWCKeywordReminderEnabledKey]) {
        [messageItems addObject:item(@"提醒关键词", @"每行一个关键词，不区分大小写", @"text.magnifyingglass", NeoWCRowKindDetail, nil, NeoWCSettingsCountText(reminderKeywordCount))];
    }
    [messageItems addObject:item(@"红包详情显示", @"在红包详情页显示总额、领取和剩余统计", @"envelope.open", NeoWCRowKindSwitch, NeoWCRedEnvelopeDetailEnabledKey, nil)];
    if ([defaults boolForKey:NeoWCRedEnvelopeDetailEnabledKey] && [self isFeatureExpandedForKey:NeoWCRedEnvelopeDetailEnabledKey]) {
        [messageItems addObject:item(@"红包详情居中", @"将补充统计信息居中显示", @"text.aligncenter", NeoWCRowKindSwitch, NeoWCRedEnvelopeDetailCenterKey, nil)];
    }
    [messageItems addObject:item(@"通话二次确认", @"从聊天气泡发起语音或视频通话前确认", @"phone.badge.checkmark", NeoWCRowKindSwitch, NeoWCCallConfirmEnabledKey, nil)];
    [messageItems addObject:item(@"输入框滑动操作", @"左滑清空，右滑从剪贴板粘贴", @"hand.draw", NeoWCRowKindSwitch, NeoWCInputSwipeActionsEnabledKey, nil)];
    [messageItems addObject:item(@"图片编辑快捷发送", @"在官方图片编辑完成菜单中增加发送到当前会话", @"photo.badge.arrow.down", NeoWCRowKindSwitch, NeoWCImageEditQuickSendEnabledKey, nil)];
    [messageItems addObject:item(@"自动选择原图", @"选择和预览图片时自动勾选微信原图", @"photo.badge.checkmark", NeoWCRowKindSwitch, NeoWCAutoOriginalImageEnabledKey, nil)];
    [messageItems addObject:item(@"通知直达聊天", @"点击通知后直接进入通知对应的会话", @"bubble.left.and.arrow.forward", NeoWCRowKindSwitch, NeoWCNotificationDirectChatEnabledKey, nil)];
    [messageItems addObject:item(@"多选消息导出", @"控制多选菜单中的复制、保存和分享功能", @"square.and.arrow.up.on.square", NeoWCRowKindSwitch, NeoWCMultiSelectExportEnabledKey, nil)];
    if (multiSelectExportEnabled && [self isFeatureExpandedForKey:NeoWCMultiSelectExportEnabledKey]) {
        [messageItems addObject:item(@"复制纯文本", @"只复制消息正文到剪贴板", @"doc.on.clipboard", NeoWCRowKindSwitch, NeoWCMultiSelectExportTextKey, nil)];
        [messageItems addObject:item(@"批量保存图片", @"保存所选且已下载到本机的图片", @"photo.on.rectangle.angled", NeoWCRowKindSwitch, NeoWCMultiSelectSaveImagesKey, nil)];
        [messageItems addObject:item(@"生成分享卡片", @"可选择极简、对话或深色样式", @"rectangle.on.rectangle", NeoWCRowKindSwitch, NeoWCMultiSelectShareCardKey, nil)];
    }

    NSMutableArray<NeoWCSettingItem *> *enhancementItems = [NSMutableArray arrayWithArray:@[
        item(@"设备扫码自动登录", @"自动确认电脑、平板等设备登录", @"desktopcomputer", NeoWCRowKindSwitch, NeoWCAutoDeviceLoginKey, nil),
        item(@"游戏授权自动允许", @"自动点击游戏扫码授权页面的允许按钮", @"gamecontroller", NeoWCRowKindSwitch, NeoWCAutoGameAuthorizeKey, nil),
        item(@"伪装扫码来源", @"将相册二维码识别结果按相机扫码来源处理", @"qrcode.viewfinder", NeoWCRowKindSwitch, NeoWCQRCodeCameraSourceEnabledKey, nil),
        item(@"朋友圈双击点赞", @"双击好友朋友圈内容直接点赞", @"hand.thumbsup", NeoWCRowKindSwitch, NeoWCMomentsDoubleTapLikeKey, nil),
        item(@"朋友圈操作按钮替换为评论", @"点击后直接进入评论，不再展开操作菜单", @"bubble.middle.bottom", NeoWCRowKindSwitch, NeoWCMomentsQuickCommentKey, nil),
        item(@"朋友圈转发", @"评论快捷按钮开启时独立显示，否则加入原操作菜单", @"arrowshape.turn.up.right", NeoWCRowKindSwitch, NeoWCMomentsForwardEnabledKey, nil),
        item(@"朋友圈头像快捷权限", @"长按头像，在微信原菜单中直接切换朋友权限", @"person.crop.circle.badge.checkmark", NeoWCRowKindSwitch, NeoWCMomentsQuickPermissionsKey, nil),
        item(@"朋友圈精确发布时间", @"显示完整发布时间，展开可自定义日期格式", @"calendar.badge.clock", NeoWCRowKindSwitch, NeoWCMomentsPreciseTimeKey, nil),
        item(@"自定义微信运动步数", @"支持固定或随机目标，并可在当天逐步递增", @"figure.walk", NeoWCRowKindSwitch, NeoWCStepOverrideEnabledKey, nil),
        item(@"钱包余额本地显示", @"开启后长按钱包入口或余额数字设置，仅修改本机文字", @"creditcard", NeoWCRowKindSwitch, NeoWCWalletBalanceEnabledKey, nil),
        item(@"好友数量本地显示", @"替换“个朋友”等好友数量文案", @"person.2", NeoWCRowKindSwitch, NeoWCContactsCountEnabledKey, nil),
    ]];
    if (momentsPreciseTimeEnabled && [self isFeatureExpandedForKey:NeoWCMomentsPreciseTimeKey]) {
        NSUInteger preciseTimeIndex = [enhancementItems indexOfObjectPassingTest:^BOOL(NeoWCSettingItem *entry, NSUInteger index, BOOL *stop) {
            return [entry.defaultsKey isEqualToString:NeoWCMomentsPreciseTimeKey];
        }];
        if (preciseTimeIndex != NSNotFound) [enhancementItems insertObject:item(@"朋友圈日期格式", @"支持 yyyy、MM、dd、E、HH、mm、ss，区分大小写", @"textformat", NeoWCRowKindDetail, nil, momentsDateFormat) atIndex:preciseTimeIndex + 1];
    }
    if (walletBalanceEnabled && [self isFeatureExpandedForKey:NeoWCWalletBalanceEnabledKey]) {
        NSUInteger walletIndex = [enhancementItems indexOfObjectPassingTest:^BOOL(NeoWCSettingItem *entry, NSUInteger index, BOOL *stop) {
            return [entry.defaultsKey isEqualToString:NeoWCWalletBalanceEnabledKey];
        }];
        NSString *walletValue = NeoWCSettingsLongLongDefaultForKey(NeoWCWalletBalanceFenKey) > 0 ? @"已设置" : @"设置";
        if (walletIndex != NSNotFound) [enhancementItems insertObject:item(@"设置钱包余额", @"金额按分保存，仅作用于钱包余额组件", @"number", NeoWCRowKindDetail, nil, walletValue) atIndex:walletIndex + 1];
    }
    if (momentsLikeEnabled && [self isFeatureExpandedForKey:NeoWCMomentsDoubleTapLikeKey]) {
        NSUInteger hapticIndex = MIN((NSUInteger)3, enhancementItems.count);
        [enhancementItems insertObject:item(@"点赞震动", @"双击点赞成功时提供触感反馈", @"waveform", NeoWCRowKindSwitch, NeoWCMomentsLikeHapticEnabledKey, nil) atIndex:hapticIndex];
        if (momentsHapticEnabled && [self isFeatureExpandedForKey:NeoWCMomentsLikeHapticEnabledKey]) {
            CGFloat intensity = [defaults doubleForKey:NeoWCMomentsLikeHapticIntensityKey];
            NSString *intensityText = intensity < 0.34 ? @"轻" : (intensity < 0.75 ? @"中" : @"强");
            [enhancementItems insertObject:item(@"点赞震动力度", @"调整双击点赞时的震动反馈", @"slider.horizontal.3", NeoWCRowKindDetail, nil, intensityText) atIndex:MIN(hapticIndex + 1, enhancementItems.count)];
        }
    }
    if (stepOverrideEnabled && [self isFeatureExpandedForKey:NeoWCStepOverrideEnabledKey]) {
        [enhancementItems addObject:item(@"每日目标模式", @"固定目标，或每天随机生成一次", @"arrow.triangle.2.circlepath", NeoWCRowKindDetail, nil, stepModeText)];
        if (stepMode == NeoWCStepModeDailyRandom) {
            NSInteger minimum = MAX(1, [defaults integerForKey:NeoWCStepRandomMinimumKey]);
            NSInteger maximum = MAX(minimum, [defaults integerForKey:NeoWCStepRandomMaximumKey]);
            NSString *rangeValue = [NSString stringWithFormat:@"%ld–%ld 步", (long)minimum, (long)maximum];
            [enhancementItems addObject:item(@"设置随机范围", @"每天在范围内生成一次", @"dice", NeoWCRowKindDetail, nil, rangeValue)];
        } else {
            NSString *fixedValue = configuredStepCount > 0 ? [NSString stringWithFormat:@"%ld 步", (long)configuredStepCount] : @"设置";
            [enhancementItems addObject:item(@"设置固定步数", @"每天保持同一个设定值", @"number", NeoWCRowKindDetail, nil, fixedValue)];
        }
        [enhancementItems addObject:item(@"当天逐步递增", @"按早晚活动节奏缓慢增加到今日目标", @"chart.line.uptrend.xyaxis", NeoWCRowKindSwitch, NeoWCStepGradualEnabledKey, nil)];
        NSString *targetSubtitle = stepMode == NeoWCStepModeDailyRandom
            ? @"随机目标生成后当天保持不变"
            : @"固定目标每天保持一致";
        [enhancementItems addObject:item(@"今日目标步数", targetSubtitle, @"figure.walk.motion", NeoWCRowKindInfo, nil, stepValue)];
    }
    if (contactsCountEnabled && [self isFeatureExpandedForKey:NeoWCContactsCountEnabledKey]) [enhancementItems addObject:item(@"设置好友数量", @"输入本机显示的好友数量", @"number", NeoWCRowKindDetail, nil, contactsValue)];
    [enhancementItems addObject:item(@"广告净化", @"完整拦截广告链路，并启用 Web 调试与环境检测绕过", @"rectangle.badge.xmark", NeoWCRowKindSwitch, NeoWCAdBlockerKey, nil)];

    NSMutableArray<NeoWCSettingItem *> *interfaceItems = [NSMutableArray arrayWithArray:@[
        item(@"页面缩放", @"按微信字体规则缩放页面，不修改窗口 transform", @"textformat.size", NeoWCRowKindSwitch, NeoWCPageScaleEnabledKey, nil),
        item(@"聊天输入栏圆角", @"分别控制输入框内部与外部工具栏", @"rectangle.roundedtop", NeoWCRowKindSwitch, NeoWCChatInputRoundingEnabledKey, nil),
    ]];
    if (pageScaleEnabled && [self isFeatureExpandedForKey:NeoWCPageScaleEnabledKey]) {
        [interfaceItems insertObject:item(@"全局页面缩放比例", @"作用于微信字体规则与网页文字", @"rectangle.compress.vertical", NeoWCRowKindDetail, nil, [NSString stringWithFormat:@"%.0f%%", globalScalePercent]) atIndex:1];
        [interfaceItems insertObject:item(@"NeoWC 设置页缩放比例", @"仅调整本设置页的列表与页眉尺寸", @"list.bullet.rectangle", NeoWCRowKindDetail, nil, [NSString stringWithFormat:@"%.0f%%", settingsScalePercent]) atIndex:2];
    }
    if (inputRoundingEnabled && [self isFeatureExpandedForKey:NeoWCChatInputRoundingEnabledKey]) {
        [interfaceItems addObject:item(@"输入框内部圆角", @"调整文字输入区域的圆角", @"text.cursor", NeoWCRowKindSwitch, NeoWCChatInputInnerRoundingKey, nil)];
        if ([defaults boolForKey:NeoWCChatInputInnerRoundingKey]) {
            CGFloat innerRadius = [defaults doubleForKey:NeoWCChatInputInnerRadiusKey];
            [interfaceItems addObject:item(@"内部圆角程度", @"输入 0 到 40，数值越大越圆", @"slider.horizontal.3", NeoWCRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", innerRadius])];
        }
        [interfaceItems addObject:item(@"外部工具栏圆角", @"调整聊天底部工具栏的圆角", @"rectangle.bottomhalf.filled", NeoWCRowKindSwitch, NeoWCChatInputOuterRoundingKey, nil)];
        if ([defaults boolForKey:NeoWCChatInputOuterRoundingKey]) {
            CGFloat outerRadius = [defaults doubleForKey:NeoWCChatInputOuterRadiusKey];
            [interfaceItems addObject:item(@"外部圆角程度", @"输入 0 到 40，数值越大越圆", @"slider.horizontal.3", NeoWCRowKindDetail, nil, [NSString stringWithFormat:@"%.0f", outerRadius])];
        }
    }
    [interfaceItems addObject:item(@"隐藏群标题尾部", @"隐藏群人数和免打扰标记，并让群名称自动居中", @"bell.slash", NeoWCRowKindSwitch, NeoWCHideChatMuteIconKey, nil)];
    NSUInteger hiddenMeCount = [[defaults arrayForKey:NeoWCMeMenuHiddenTitlesKey] count];
    [interfaceItems addObject:item(@"我的页面入口管理", @"选择隐藏作品、小店与卡包或表情入口", @"person.crop.rectangle.stack", NeoWCRowKindDetail, nil, NeoWCSettingsCountText(hiddenMeCount))];
    [interfaceItems addObject:item(@"隐藏截屏分享按钮", @"不显示微信右下角的截图转发浮层", @"rectangle.on.rectangle.slash", NeoWCRowKindSwitch, NeoWCHideScreenshotForwardKey, nil)];
    [interfaceItems addObject:item(@"全局去除分割线", @"按参考插件规则隐藏列表分割线与页面细线", @"rectangle.split.1x2", NeoWCRowKindSwitch, NeoWCHideSeparatorLinesKey, nil)];
    [interfaceItems addObject:item(@"插件显示管理", @"隐藏其他插件入口并检测加载状态", @"square.stack.3d.up", NeoWCRowKindDetail, nil, @"管理")];

    self.sections = @[
        [NeoWCSettingSection sectionWithIdentifier:@"general" title:@"总开关" subtitle:nil symbol:@"switch.2" footer:@"关闭后仅保留设置入口，所有增强功能停止生效。" collapsible:NO items:@[
            item(@"启用 NeoWC", @"插件功能总开关", @"power", NeoWCRowKindSwitch, NeoWCEnabledKey, nil),
        ]],
        [NeoWCSettingSection sectionWithIdentifier:@"messages" title:@"聊天增强" subtitle:@"消息、编辑与多选工具" symbol:@"bubble.left.and.bubble.right" footer:@"" collapsible:YES items:messageItems],
        [NeoWCSettingSection sectionWithIdentifier:@"enhancements" title:@"常用增强" subtitle:@"快捷操作与自动授权" symbol:@"bolt" footer:@"自动登录和授权会跳过手动确认，请只在可信设备和可信游戏中开启。" collapsible:YES items:enhancementItems],
        [NeoWCSettingSection sectionWithIdentifier:@"interface" title:@"界面优化" subtitle:@"聊天页面与插件入口外观" symbol:@"paintbrush" footer:@"界面调整只作用于聊天页面，关闭后恢复微信原始样式。" collapsible:YES items:interfaceItems],
        [NeoWCSettingSection sectionWithIdentifier:@"developer" title:@"开发者功能" subtitle:@"界面检查与运行诊断" symbol:@"hammer" footer:@"快捷入口启用后会立即尝试注册；关闭或移除入口后，重启微信即可从插件管理页面彻底消失。" collapsible:YES items:({
            NSMutableArray<NeoWCSettingItem *> *items = [NSMutableArray arrayWithArray:@[
                item(@"调试悬浮按钮", @"仅由此开关控制，不监听全局手势", @"wrench.and.screwdriver", NeoWCRowKindSwitch, NeoWCDebugFloatingEnabledKey, nil),
                item(@"记录调试日志", @"记录 NeoWC 运行事件，关闭后停止新增", @"text.alignleft", NeoWCRowKindSwitch, NeoWCDebugLoggingEnabledKey, nil),
                item(@"调试中心", @"视图检查、Runtime 搜索与日志", @"ladybug", NeoWCRowKindDetail, nil, @"打开"),
                item(@"功能兼容性", @"检查类、Selector 与本次运行触发状态", @"checklist", NeoWCRowKindDetail, nil, @"检查"),
                item(@"插件管理快捷入口", @"把常用开关或页面注册到插件管理页", @"bolt.badge.clock", NeoWCRowKindSwitch, NeoWCPluginShortcutsEnabledKey, nil),
            ]];
            if (pluginShortcutsEnabled && [self isFeatureExpandedForKey:NeoWCPluginShortcutsEnabledKey]) {
                [items addObject:item(@"快捷日志开关", @"在插件管理页直接开关 NeoWC 日志", @"text.alignleft", NeoWCRowKindSwitch, NeoWCPluginShortcutLoggingKey, nil)];
                [items addObject:item(@"快捷悬浮窗开关", @"在插件管理页直接开关调试悬浮窗", @"wrench.and.screwdriver", NeoWCRowKindSwitch, NeoWCPluginShortcutFloatingDebugKey, nil)];
                [items addObject:item(@"直达调试中心", @"在插件管理页增加独立页面入口", @"ladybug", NeoWCRowKindSwitch, NeoWCPluginShortcutDebugCenterKey, nil)];
                [items addObject:item(@"直达防撤回记录", @"在插件管理页增加撤回记录入口", @"tray.full", NeoWCRowKindSwitch, NeoWCPluginShortcutRevokeRecordsKey, nil)];
                [items addObject:item(@"自定义页面入口", @"输入 Controller 或 View 类名快速跳转", @"rectangle.and.hand.point.up.left", NeoWCRowKindSwitch, NeoWCPluginShortcutCustomPageKey, nil)];
                if ([defaults boolForKey:NeoWCPluginShortcutCustomPageKey] &&
                    [self isFeatureExpandedForKey:NeoWCPluginShortcutCustomPageKey]) {
                    NSString *customTitle = [defaults stringForKey:NeoWCPluginShortcutCustomTitleKey] ?: @"快捷页面";
                    NSString *customClass = [defaults stringForKey:NeoWCPluginShortcutCustomClassKey] ?: @"";
                    [items addObject:item(@"自定义入口名称", @"显示在插件管理页面中的名称", @"textformat", NeoWCRowKindDetail, nil, customTitle)];
                    [items addObject:item(@"页面 Runtime 类名", @"支持 UIViewController 或 UIView 子类", @"chevron.left.forwardslash.chevron.right", NeoWCRowKindDetail, nil, customClass.length > 0 ? customClass : @"输入")];
                }
            }
            items;
        })],
        [NeoWCSettingSection sectionWithIdentifier:@"about" title:@"关于" subtitle:nil symbol:@"info.circle" footer:@"NeoWC · Designed for WeChat" collapsible:NO items:@[
            item(@"配置管理", @"导入、导出或重置 NeoWC 配置", @"externaldrive", NeoWCRowKindDetail, nil, @"管理"),
            item(@"版本", @"NeoWC", @"shippingbox", NeoWCRowKindInfo, nil, NeoWCVersion),
            item(@"当前用户 wxid", currentWXID ?: @"未获取", @"person.crop.circle", NeoWCRowKindCopy, nil, currentWXID),
        ]],
    ];
}

- (UIView *)makeHeaderView {
    CGFloat scale = [self settingsPageScale];
    CGFloat width = MAX(CGRectGetWidth(self.view.bounds), CGRectGetWidth([UIScreen mainScreen].bounds));
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 132.0 * scale)];
    container.backgroundColor = [UIColor systemBackgroundColor];

    NeoWCLogoView *logo = [NeoWCLogoView new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.layer.shadowOpacity = 0.0;
    [container addSubview:logo];

    UILabel *name = [UILabel new];
    name.translatesAutoresizingMaskIntoConstraints = NO;
    name.text = @"NeoWC";
    name.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    name.adjustsFontForContentSizeCategory = YES;
    [container addSubview:name];

    UILabel *version = [UILabel new];
    version.translatesAutoresizingMaskIntoConstraints = NO;
    version.text = [NSString stringWithFormat:@"v%@ · DEVELOPMENT", NeoWCVersion];
    version.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    version.adjustsFontForContentSizeCategory = YES;
    version.textColor = [UIColor secondaryLabelColor];
    [container addSubview:version];

    UILabel *tagline = [UILabel new];
    tagline.translatesAutoresizingMaskIntoConstraints = NO;
    tagline.text = @"轻量、清晰、原生的微信增强体验";
    tagline.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    tagline.adjustsFontForContentSizeCategory = YES;
    tagline.textColor = [UIColor secondaryLabelColor];
    [container addSubview:tagline];

    [NSLayoutConstraint activateConstraints:@[
        [logo.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:24.0 * scale],
        [logo.topAnchor constraintEqualToAnchor:container.topAnchor constant:12.0 * scale],
        [logo.widthAnchor constraintEqualToConstant:62.0 * scale],
        [logo.heightAnchor constraintEqualToConstant:62.0 * scale],
        [name.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:12.0 * scale],
        [name.trailingAnchor constraintLessThanOrEqualToAnchor:container.trailingAnchor constant:-24.0 * scale],
        [name.topAnchor constraintEqualToAnchor:logo.topAnchor constant:3.0 * scale],
        [version.leadingAnchor constraintEqualToAnchor:name.leadingAnchor],
        [version.topAnchor constraintEqualToAnchor:name.bottomAnchor constant:4.0 * scale],
        [tagline.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:24.0 * scale],
        [tagline.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-24.0 * scale],
        [tagline.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-18.0 * scale],
    ]];
    return container;
}

- (BOOL)isSectionExpanded:(NeoWCSettingSection *)section {
    return !section.isCollapsible || [self.expandedCategoryIDs containsObject:section.identifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    NeoWCSettingSection *section = self.sections[sectionIndex];
    return [self isSectionExpanded:section] ? section.items.count : 0;
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForHeaderInSection:(__unused NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NeoWCSettingSection *model = self.sections[section];
    CGFloat scale = [self settingsPageScale];
    return MAX(40.0, (model.subtitle.length > 0 ? 62.0 : 46.0) * scale);
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex {
    NeoWCSettingSection *section = self.sections[sectionIndex];
    UIControl *header = [UIControl new];
    header.tag = sectionIndex;
    header.backgroundColor = UIColor.clearColor;
    if (section.isCollapsible) [header addTarget:self action:@selector(sectionHeaderTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *icon = [[UIImageView alloc] initWithImage:section.symbol.length > 0 ? NeoWCSymbol(section.symbol) : nil];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = [UIColor secondaryLabelColor];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [header addSubview:icon];

    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = section.title;
    title.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    title.textColor = [UIColor labelColor];
    [header addSubview:title];

    UILabel *subtitle = [UILabel new];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.text = section.subtitle;
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    subtitle.textColor = [UIColor tertiaryLabelColor];
    subtitle.hidden = section.subtitle.length == 0;
    [header addSubview:subtitle];

    UIImageView *chevron = [[UIImageView alloc] initWithImage:section.isCollapsible ? [UIImage systemImageNamed:@"chevron.down"] : nil];
    chevron.translatesAutoresizingMaskIntoConstraints = NO;
    chevron.tintColor = [UIColor tertiaryLabelColor];
    chevron.contentMode = UIViewContentModeScaleAspectFit;
    chevron.tag = 7401;
    chevron.transform = [self isSectionExpanded:section] ? CGAffineTransformIdentity : CGAffineTransformMakeRotation((CGFloat)-M_PI_2);
    [header addSubview:chevron];

    CGFloat titleLeading = section.symbol.length > 0 ? 46.0 : 18.0;
    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:18.0],
        [icon.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:18.0],
        [icon.heightAnchor constraintEqualToConstant:18.0],
        [title.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:titleLeading],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:chevron.leadingAnchor constant:-10.0],
        [title.topAnchor constraintEqualToAnchor:header.topAnchor constant:section.subtitle.length > 0 ? 12.0 : 17.0],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [subtitle.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor constant:-36.0],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2.0],
        [chevron.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20.0],
        [chevron.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [chevron.widthAnchor constraintEqualToConstant:12.0],
        [chevron.heightAnchor constraintEqualToConstant:16.0],
    ]];
    header.isAccessibilityElement = YES;
    header.accessibilityLabel = section.subtitle.length > 0 ? [NSString stringWithFormat:@"%@，%@", section.title, section.subtitle] : section.title;
    if (section.isCollapsible) header.accessibilityHint = [self isSectionExpanded:section] ? @"轻点折叠" : @"轻点展开";
    return header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NeoWCSettingSection *model = self.sections[section];
    if (model.isCollapsible && ![self isSectionExpanded:model]) return nil;
    return model.footer.length > 0 ? model.footer : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    NSString *footer = [self tableView:tableView titleForFooterInSection:section];
    return footer.length > 0 ? UITableViewAutomaticDimension : 10.0 * [self settingsPageScale];
}

- (NeoWCSettingItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCSettingSection *section = self.sections[indexPath.section];
    NSInteger itemIndex = indexPath.row;
    if (itemIndex < 0 || itemIndex >= section.items.count) return nil;
    return section.items[itemIndex];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return MAX(48.0, 60.0 * [self settingsPageScale]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCSettingSection *section = self.sections[indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NeoWCSettingCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.layer.shadowOpacity = 0.0;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessibilityHint = nil;
    NSInteger visibleRows = [tableView numberOfRowsInSection:indexPath.section];
    BOOL firstRow = indexPath.row == 0;
    BOOL lastRow = indexPath.row == visibleRows - 1;
    if (section.isCollapsible) {
        NeoWCCardBackgroundView *background = [NeoWCCardBackgroundView new];
        background.roundsTop = firstRow;
        background.roundsBottom = lastRow;
        background.drawsDivider = NO;
        cell.backgroundView = background;
        NeoWCCardBackgroundView *selectedBackground = [NeoWCCardBackgroundView new];
        selectedBackground.roundsTop = firstRow;
        selectedBackground.roundsBottom = lastRow;
        selectedBackground.drawsDivider = NO;
        selectedBackground.fillColor = [UIColor tertiarySystemFillColor];
        cell.selectedBackgroundView = selectedBackground;
    } else {
        UIView *plainBackground = [UIView new];
        plainBackground.backgroundColor = UIColor.clearColor;
        cell.backgroundView = plainBackground;
        UIView *plainSelectedBackground = [UIView new];
        plainSelectedBackground.backgroundColor = [UIColor tertiarySystemFillColor];
        cell.selectedBackgroundView = plainSelectedBackground;
    }
    cell.layoutMargins = UIEdgeInsetsMake(0.0, 22.0, 0.0, 22.0);

    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = item.title;
    content.secondaryText = item.subtitle;
    content.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    content.secondaryTextProperties.color = [UIColor secondaryLabelColor];
    content.image = NeoWCSymbol(item.symbol);
    content.imageProperties.tintColor = [UIColor secondaryLabelColor];
    content.imageProperties.maximumSize = CGSizeMake(20.0, 20.0);
    content.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0.0, 22.0, 0.0, 22.0);
    cell.contentConfiguration = content;

    if (item.kind == NeoWCRowKindSwitch) {
        UISwitch *toggle = [UISwitch new];
        toggle.onTintColor = [UIColor systemBlueColor];
        toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:item.defaultsKey];
        toggle.accessibilityLabel = item.title;
        toggle.tag = indexPath.section * 1000 + indexPath.row;
        [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        BOOL masterEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCEnabledKey];
        toggle.enabled = [item.defaultsKey isEqualToString:NeoWCEnabledKey] || masterEnabled;
        if ([self featureHasChildrenForKey:item.defaultsKey]) {
            UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down"]];
            chevron.tintColor = [UIColor tertiaryLabelColor];
            chevron.contentMode = UIViewContentModeScaleAspectFit;
            chevron.hidden = NO;
            chevron.alpha = toggle.isOn ? 1.0 : 0.0;
            chevron.transform = [self isFeatureExpandedForKey:item.defaultsKey] ? CGAffineTransformIdentity : CGAffineTransformMakeRotation((CGFloat)-M_PI_2);
            [chevron.widthAnchor constraintEqualToConstant:11.0].active = YES;
            [chevron.heightAnchor constraintEqualToConstant:15.0].active = YES;
            UIStackView *accessory = [[UIStackView alloc] initWithArrangedSubviews:@[chevron, toggle]];
            accessory.axis = UILayoutConstraintAxisHorizontal;
            accessory.alignment = UIStackViewAlignmentCenter;
            accessory.spacing = 10.0;
            accessory.frame = CGRectMake(0.0, 0.0, 72.0, 32.0);
            cell.accessoryView = accessory;
            cell.selectionStyle = toggle.isOn ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.accessibilityHint = toggle.isOn ? ([self isFeatureExpandedForKey:item.defaultsKey] ? @"轻点卡片收起子选项" : @"轻点卡片展开子选项") : nil;
        } else {
            cell.accessoryView = toggle;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    } else if (item.kind == NeoWCRowKindDetail) {
        UILabel *valueLabel = [UILabel new];
        valueLabel.text = item.value ?: @"";
        valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        valueLabel.textColor = [UIColor tertiaryLabelColor];
        UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        chevron.tintColor = [UIColor quaternaryLabelColor];
        chevron.contentMode = UIViewContentModeScaleAspectFit;
        [chevron.widthAnchor constraintEqualToConstant:8.0].active = YES;
        UIStackView *accessory = [[UIStackView alloc] initWithArrangedSubviews:@[valueLabel, chevron]];
        accessory.axis = UILayoutConstraintAxisHorizontal;
        accessory.alignment = UIStackViewAlignmentCenter;
        accessory.spacing = 7.0;
        cell.accessoryView = accessory;
    } else if (item.kind == NeoWCRowKindCopy) {
        UIImageView *copyIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"doc.on.doc"]];
        copyIcon.tintColor = item.value.length > 0 ? [UIColor secondaryLabelColor] : [UIColor quaternaryLabelColor];
        copyIcon.contentMode = UIViewContentModeScaleAspectFit;
        [copyIcon.widthAnchor constraintEqualToConstant:17.0].active = YES;
        [copyIcon.heightAnchor constraintEqualToConstant:17.0].active = YES;
        cell.accessoryView = copyIcon;
        cell.selectionStyle = item.value.length > 0 ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
        cell.accessibilityHint = item.value.length > 0 ? @"轻点复制 wxid" : @"当前未获取到 wxid";
    } else if (item.value.length > 0) {
        UILabel *valueLabel = [UILabel new];
        valueLabel.text = item.value;
        valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        valueLabel.textColor = [UIColor secondaryLabelColor];
        cell.accessoryView = valueLabel;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void)switchChanged:(UISwitch *)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag % 1000 inSection:sender.tag / 1000];
    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    if (item.defaultsKey.length == 0) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:item.defaultsKey];
    BOOL timePositionChanged = [item.defaultsKey isEqualToString:NeoWCChatMessageTimeBelowAvatarKey] ||
                               [item.defaultsKey isEqualToString:NeoWCChatMessageTimeBubbleSideKey];
    if (timePositionChanged) {
        NSString *otherKey = [item.defaultsKey isEqualToString:NeoWCChatMessageTimeBelowAvatarKey]
            ? NeoWCChatMessageTimeBubbleSideKey
            : NeoWCChatMessageTimeBelowAvatarKey;
        [defaults setBool:!sender.isOn forKey:otherKey];
    }
    if (sender.isOn && [self featureHasChildrenForKey:item.defaultsKey]) {
        [self.collapsedFeatureKeys removeObject:item.defaultsKey];
        [self saveCollapsedFeatureKeys];
    }
    if ([item.defaultsKey isEqualToString:NeoWCStepOverrideEnabledKey] && sender.isOn) {
        NeoWCSettingsRegenerateDailyStepTarget([NSUserDefaults standardUserDefaults]);
    }
    if ([item.defaultsKey isEqualToString:NeoWCAntiRevokePersistRecordsKey]) NeoWCAntiRevokeSetPersistenceEnabled(sender.isOn);
    if ([item.defaultsKey hasPrefix:@"com.qiu7c.neowc."]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCEnhancementDidChangeNotification object:item.defaultsKey];
    }
    if ([item.defaultsKey isEqualToString:NeoWCDebugFloatingEnabledKey]) {
        [[NeoWCDebugManager sharedManager] setFloatingEnabled:sender.isOn];
    }
    if ([item.defaultsKey hasPrefix:@"com.qiu7c.neowc.plugin-shortcuts."]) {
        NeoWCRegisterPluginShortcutsIfAvailable();
    }
    if ([item.defaultsKey isEqualToString:NeoWCAntiRevokeKey]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    }
    BOOL changesVisibleRows = [item.defaultsKey isEqualToString:NeoWCAntiRevokeKey] ||
                              [item.defaultsKey isEqualToString:NeoWCAntiRevokeNotifySenderKey] ||
                              [item.defaultsKey isEqualToString:NeoWCStepOverrideEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCContactsCountEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMomentsDoubleTapLikeKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMomentsLikeHapticEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMomentsPreciseTimeKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMultiSelectExportEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCMessageBlockEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCKeywordReminderEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCChatMessageTimeEnabledKey] ||
                              timePositionChanged ||
                              [item.defaultsKey isEqualToString:NeoWCRedEnvelopeDetailEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCLongPressMenuEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCAutoVoiceTranscriptionEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCWalletBalanceEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCPluginShortcutsEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCPluginShortcutCustomPageKey] ||
                              [item.defaultsKey isEqualToString:NeoWCPageScaleEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCChatInputRoundingEnabledKey] ||
                              [item.defaultsKey isEqualToString:NeoWCChatInputInnerRoundingKey] ||
                              [item.defaultsKey isEqualToString:NeoWCChatInputOuterRoundingKey];
    if ([item.defaultsKey isEqualToString:NeoWCPageScaleEnabledKey]) [self applySettingsPageScale];
    if (changesVisibleRows) [self buildSections];
    if ([item.defaultsKey isEqualToString:NeoWCEnabledKey] || changesVisibleRows) {
        CGPoint offset = self.tableView.contentOffset;
        [UIView performWithoutAnimation:^{
            [self.tableView reloadData];
            [self.tableView setContentOffset:offset animated:NO];
        }];
    }
}

- (void)toggleFeatureAtIndexPath:(NSIndexPath *)indexPath item:(NeoWCSettingItem *)item {
    if (![self featureHasChildrenForKey:item.defaultsKey] ||
        ![[NSUserDefaults standardUserDefaults] boolForKey:item.defaultsKey]) return;
    if ([self.collapsedFeatureKeys containsObject:item.defaultsKey]) {
        [self.collapsedFeatureKeys removeObject:item.defaultsKey];
    } else {
        [self.collapsedFeatureKeys addObject:item.defaultsKey];
    }
    [self saveCollapsedFeatureKeys];
    [self buildSections];
    CGPoint offset = self.tableView.contentOffset;
    [UIView performWithoutAnimation:^{
        [self.tableView reloadData];
        [self.tableView setContentOffset:offset animated:NO];
    }];
}

- (void)toggleSection:(NSInteger)sectionIndex {
    NeoWCSettingSection *section = self.sections[sectionIndex];
    if (!section.isCollapsible) return;
    BOOL wasExpanded = [self.expandedCategoryIDs containsObject:section.identifier];
    if (wasExpanded) {
        [self.expandedCategoryIDs removeObject:section.identifier];
    } else {
        [self.expandedCategoryIDs addObject:section.identifier];
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.expandedCategoryIDs.allObjects forKey:NeoWCExpandedCategoriesKey];
    CGPoint offset = self.tableView.contentOffset;
    [UIView performWithoutAnimation:^{
        [self.tableView reloadData];
        [self.tableView setContentOffset:offset animated:NO];
    }];
}

- (void)sectionHeaderTapped:(UIControl *)sender {
    [self toggleSection:sender.tag];
}

- (void)presentRevokeFilterPicker {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"回复时间限制"
                                                                   message:@"仅影响“回复撤回者”，不会影响本地防撤回"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSDictionary *> *options = @[
        @{@"title": @"不限制", @"value": @0},
        @{@"title": @"1 分钟", @"value": @60},
        @{@"title": @"5 分钟", @"value": @300},
        @{@"title": @"30 分钟", @"value": @1800},
        @{@"title": @"1 小时", @"value": @3600},
        @{@"title": @"24 小时", @"value": @86400},
    ];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        [sheet addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [[NSUserDefaults standardUserDefaults] setDouble:[option[@"value"] doubleValue] forKey:NeoWCAntiRevokeTimeFilterKey];
            [weakSelf buildSections];
            [weakSelf.tableView reloadData];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - 1.0, 1.0, 1.0);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentTemplateEditorWithTitle:(NSString *)title key:(NSString *)key defaultValue:(NSString *)defaultValue {
    NSString *colorKey = [key isEqualToString:NeoWCAntiRevokeLocalTemplateKey] ? NeoWCAntiRevokeLocalTextColorKey : nil;
    NeoWCAntiRevokeTemplateEditorViewController *editor = [[NeoWCAntiRevokeTemplateEditorViewController alloc]
        initWithTitle:title defaultsKey:key defaultValue:defaultValue colorKey:colorKey];
    [self.navigationController pushViewController:editor animated:YES];
}

- (void)presentRevokePromptStylePicker {
    NSInteger currentStyle = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCAntiRevokePromptStyleKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"防撤回提示方案"
                                                                   message:@"“消息下方”显示完整提示；“气泡旁”显示与气泡持平的小字"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSDictionary *> *options = @[
        @{ @"title": currentStyle == 0 ? @"✓  消息下方" : @"消息下方", @"value": @0 },
        @{ @"title": currentStyle == 1 ? @"✓  气泡旁" : @"气泡旁", @"value": @1 },
    ];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *option in options) {
        [sheet addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [[NSUserDefaults standardUserDefaults] setInteger:[option[@"value"] integerValue] forKey:NeoWCAntiRevokePromptStyleKey];
            [weakSelf buildSections];
            [weakSelf.tableView reloadData];
            [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - 1.0, 1.0, 1.0);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentSidePromptTextEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"气泡旁提示文字" message:@"建议使用简短文字，避免覆盖消息气泡" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCAntiRevokeSideTextKey] ?: @"已拦截撤回";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (text.length == 0) text = @"已拦截撤回";
        [[NSUserDefaults standardUserDefaults] setObject:text forKey:NeoWCAntiRevokeSideTextKey];
        [weakSelf buildSections];
        [weakSelf.tableView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentSidePromptOffsetEditorForKey:(NSString *)key title:(NSString *)title defaultValue:(CGFloat)defaultValue {
    id storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    CGFloat value = storedValue ? [storedValue doubleValue] : defaultValue;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:@"请输入 -80 到 80 之间的数值" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [NSString stringWithFormat:@"%.0f", value];
        textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        CGFloat newValue = MIN(80.0, MAX(-80.0, alert.textFields.firstObject.text.doubleValue));
        [[NSUserDefaults standardUserDefaults] setDouble:newValue forKey:key];
        [weakSelf buildSections];
        [weakSelf.tableView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentPluginShortcutTextEditorForKey:(NSString *)key
                                        title:(NSString *)title
                                  placeholder:(NSString *)placeholder {
    BOOL editingClass = [key isEqualToString:NeoWCPluginShortcutCustomClassKey];
    NSString *message = editingClass
        ? @"输入 Objective-C Runtime 类名；支持 UIViewController 或 UIView 子类。修改已注册的类名后建议重启微信。"
        : @"此名称会显示在插件管理页面中。";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        textField.placeholder = placeholder;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *value = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (!editingClass && value.length == 0) value = @"快捷页面";
        [[NSUserDefaults standardUserDefaults] setObject:value ?: @"" forKey:key];
        [weakSelf buildSections];
        [weakSelf.tableView reloadData];
        NeoWCRegisterPluginShortcutsIfAvailable();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentCornerRadiusEditorForKey:(NSString *)key title:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:@"请输入 0 到 40 之间的数值；0 表示直角"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [NSString stringWithFormat:@"%.0f", [[NSUserDefaults standardUserDefaults] doubleForKey:key]];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        CGFloat radius = MIN(40.0, MAX(0.0, alert.textFields.firstObject.text.doubleValue));
        [[NSUserDefaults standardUserDefaults] setDouble:radius forKey:key];
        [weakSelf buildSections];
        [weakSelf.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentScaleEditorForKey:(NSString *)key title:(NSString *)title {
    CGFloat currentValue = NeoWCScalePercentForDefaultsKey(key, 100.0);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:@"请输入 70 到 100 之间的百分比"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [NSString stringWithFormat:@"%.0f", currentValue];
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *rawValue = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        CGFloat value = rawValue.length > 0 ? rawValue.doubleValue : 100.0;
        value = MIN(100.0, MAX(70.0, value));
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setDouble:value forKey:key];
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCEnhancementDidChangeNotification object:key];
        CGPoint offset = weakSelf.tableView.contentOffset;
        if ([key isEqualToString:NeoWCSettingsPageScalePercentKey]) [weakSelf applySettingsPageScale];
        [weakSelf buildSections];
        [UIView performWithoutAnimation:^{
            [weakSelf.tableView reloadData];
            [weakSelf.tableView setContentOffset:offset animated:NO];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentMomentsDateFormatEditor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedFormat = NeoWCNormalizedMomentsDateFormat([defaults stringForKey:NeoWCMomentsPreciseTimeFormatKey]) ?: NeoWCMomentsPreciseTimeDefaultFormat;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"朋友圈日期格式"
                                                                   message:@"仅支持 yyyy、MM、dd、E、HH、mm、ss，区分大小写；留空恢复默认格式"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = savedFormat;
        textField.placeholder = NeoWCMomentsPreciseTimeDefaultFormat;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *rawFormat = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        NSString *normalized = rawFormat.length == 0 ? NeoWCMomentsPreciseTimeDefaultFormat : NeoWCNormalizedMomentsDateFormat(rawFormat);
        if (!normalized) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                UIViewController *controller = weakSelf;
                if (!controller) return;
                UIAlertController *error = [UIAlertController alertControllerWithTitle:@"日期格式不支持"
                                                                               message:@"格式最长 64 个字符，只能使用 yyyy、MM、dd、E、HH、mm、ss 及普通分隔文字。"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [error addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
                [controller presentViewController:error animated:YES completion:nil];
            });
            return;
        }
        [defaults setObject:normalized forKey:NeoWCMomentsPreciseTimeFormatKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCEnhancementDidChangeNotification object:NeoWCMomentsPreciseTimeFormatKey];
        [weakSelf buildSections];
        CGPoint offset = weakSelf.tableView.contentOffset;
        [UIView performWithoutAnimation:^{
            [weakSelf.tableView reloadData];
            [weakSelf.tableView setContentOffset:offset animated:NO];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    if (item.kind == NeoWCRowKindCopy) {
        if (item.value.length == 0) return;
        UIPasteboard.generalPasteboard.string = item.value;
        self.navigationItem.prompt = @"wxid 已复制";
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.navigationItem.prompt = nil;
        });
        return;
    }
    if (item.kind == NeoWCRowKindSwitch && [self featureHasChildrenForKey:item.defaultsKey]) {
        [self toggleFeatureAtIndexPath:indexPath item:item];
        return;
    }
    if (item.kind != NeoWCRowKindDetail) return;
    if ([item.title isEqualToString:@"配置管理"]) {
        [self.navigationController pushViewController:[NeoWCConfigManagerViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"屏蔽会话账号"]) {
        NeoWCListEditorViewController *editor = [[NeoWCListEditorViewController alloc]
            initWithTitle:item.title subtitle:@"每行填写一个 wxid 或以 @chatroom 结尾的群聊账号"
            defaultsKey:NeoWCMessageBlockUsersKey mode:NeoWCListEditorModeList];
        [self.navigationController pushViewController:editor animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"屏蔽关键词"]) {
        NeoWCListEditorViewController *editor = [[NeoWCListEditorViewController alloc]
            initWithTitle:item.title subtitle:@"仅匹配新收到的普通文字消息，每行填写一个关键词"
            defaultsKey:NeoWCMessageBlockKeywordsKey mode:NeoWCListEditorModeList];
        [self.navigationController pushViewController:editor animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"提醒关键词"]) {
        NeoWCListEditorViewController *editor = [[NeoWCListEditorViewController alloc]
            initWithTitle:item.title subtitle:@"命中任意一项即提醒，每行填写一个关键词"
            defaultsKey:NeoWCKeywordReminderKeywordsKey mode:NeoWCListEditorModeList];
        [self.navigationController pushViewController:editor animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"管理已发现菜单"]) {
        [self.navigationController pushViewController:[NeoWCLongPressMenuViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"时间标签格式"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:item.title
                                                                       message:@"例如 MM-dd HH:mm:ss"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCChatMessageTimeFormatKey] ?: @"MM-dd HH:mm:ss";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            (void)action;
            NSString *format = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (format.length == 0 || format.length > 64) return;
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.dateFormat = format;
            if ([formatter stringFromDate:[NSDate date]].length == 0) return;
            [[NSUserDefaults standardUserDefaults] setObject:format forKey:NeoWCChatMessageTimeFormatKey];
            [weakSelf reloadSettingsPreservingPosition];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if ([item.title isEqualToString:@"我的页面入口管理"]) {
        [self.navigationController pushViewController:[NeoWCMeMenuViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"防撤回提示方案"]) {
        [self presentRevokePromptStylePicker];
        return;
    }
    if ([item.title isEqualToString:@"提示外观预览"]) {
        [self.navigationController pushViewController:[NeoWCAntiRevokeAppearanceViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"防撤回记录中心"]) {
        [self.navigationController pushViewController:[NeoWCAntiRevokeRecordsViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"气泡旁提示文字"]) {
        [self presentSidePromptTextEditor];
        return;
    }
    if ([item.title isEqualToString:@"气泡旁横向位置"]) {
        [self presentSidePromptOffsetEditorForKey:NeoWCAntiRevokeSideOffsetXKey title:item.title defaultValue:0.0];
        return;
    }
    if ([item.title isEqualToString:@"气泡旁纵向位置"]) {
        [self presentSidePromptOffsetEditorForKey:NeoWCAntiRevokeSideOffsetYKey title:item.title defaultValue:10.0];
        return;
    }
    if ([item.title isEqualToString:@"回复时间限制"]) {
        [self presentRevokeFilterPicker];
        return;
    }
    if ([item.title isEqualToString:@"本地提示模板"]) {
        [self presentTemplateEditorWithTitle:item.title
                                         key:NeoWCAntiRevokeLocalTemplateKey
                                defaultValue:@"拦截到一条{用户名}撤回的消息\n发送时间：{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}\n内容：{内容}"];
        return;
    }
    if ([item.title isEqualToString:@"回复消息模板"]) {
        [self presentTemplateEditorWithTitle:item.title
                                         key:NeoWCAntiRevokeReplyTemplateKey
                                defaultValue:@"【捕捉到一条撤回消息】\n操作用户：{用户名}\n发送时间：{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}\n撤回内容：{内容}\n\n撤回无效，消息已保存"];
        return;
    }
    if ([item.title isEqualToString:@"调试中心"]) {
        [[NeoWCDebugManager sharedManager] presentDashboardFromViewController:self];
        return;
    }
    if ([item.title isEqualToString:@"功能兼容性"]) {
        [self.navigationController pushViewController:[NeoWCCompatibilityViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"自定义入口名称"]) {
        [self presentPluginShortcutTextEditorForKey:NeoWCPluginShortcutCustomTitleKey title:item.title placeholder:@"快捷页面"];
        return;
    }
    if ([item.title isEqualToString:@"页面 Runtime 类名"]) {
        [self presentPluginShortcutTextEditorForKey:NeoWCPluginShortcutCustomClassKey title:item.title placeholder:@"例如 NewSettingViewController"];
        return;
    }
    if ([item.title isEqualToString:@"全局页面缩放比例"]) {
        [self presentScaleEditorForKey:NeoWCPageScaleGlobalPercentKey title:item.title];
        return;
    }
    if ([item.title isEqualToString:@"NeoWC 设置页缩放比例"]) {
        [self presentScaleEditorForKey:NeoWCSettingsPageScalePercentKey title:item.title];
        return;
    }
    if ([item.title isEqualToString:@"内部圆角程度"]) {
        [self presentCornerRadiusEditorForKey:NeoWCChatInputInnerRadiusKey title:item.title];
        return;
    }
    if ([item.title isEqualToString:@"外部圆角程度"]) {
        [self presentCornerRadiusEditorForKey:NeoWCChatInputOuterRadiusKey title:item.title];
        return;
    }
    if ([item.title isEqualToString:@"朋友圈日期格式"]) {
        [self presentMomentsDateFormatEditor];
        return;
    }
    if ([item.title isEqualToString:@"插件显示管理"]) {
        [self.navigationController pushViewController:[NeoWCPluginVisibilityViewController new] animated:YES];
        return;
    }
    if ([item.title isEqualToString:@"点赞震动力度"]) {
        UIAlertController *picker = [UIAlertController alertControllerWithTitle:@"点赞震动力度" message:@"选择双击点赞时的触感强度" preferredStyle:UIAlertControllerStyleActionSheet];
        NSArray<NSDictionary *> *options = @[
            @{ @"title": @"轻", @"value": @0.25 },
            @{ @"title": @"中", @"value": @0.65 },
            @{ @"title": @"强", @"value": @1.0 },
        ];
        __weak typeof(self) weakSelf = self;
        for (NSDictionary *option in options) {
            [picker addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
                [[NSUserDefaults standardUserDefaults] setDouble:[option[@"value"] doubleValue] forKey:NeoWCMomentsLikeHapticIntensityKey];
                [weakSelf buildSections];
                [weakSelf.tableView reloadData];
            }]];
        }
        [picker addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        UIPopoverPresentationController *popover = picker.popoverPresentationController;
        if (popover) { popover.sourceView = self.view; popover.sourceRect = self.view.bounds; }
        [self presentViewController:picker animated:YES completion:nil];
        return;
    }
    if ([item.title isEqualToString:@"每日目标模式"]) {
        UIAlertController *picker = [UIAlertController alertControllerWithTitle:@"每日目标模式"
                                                                        message:@"随机模式每天只生成一次目标"
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
        NSArray<NSDictionary *> *options = @[
            @{@"title": @"每日固定", @"value": @(NeoWCStepModeDailyFixed)},
            @{@"title": @"每日随机", @"value": @(NeoWCStepModeDailyRandom)},
        ];
        __weak typeof(self) weakSelf = self;
        for (NSDictionary *option in options) {
            [picker addAction:[UIAlertAction actionWithTitle:option[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setInteger:[option[@"value"] integerValue] forKey:NeoWCStepModeKey];
                [defaults setBool:YES forKey:NeoWCStepOverrideEnabledKey];
                NeoWCSettingsRegenerateDailyStepTarget(defaults);
                [weakSelf reloadSettingsPreservingPosition];
            }]];
        }
        [picker addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        UIPopoverPresentationController *popover = picker.popoverPresentationController;
        if (popover) { popover.sourceView = self.view; popover.sourceRect = self.view.bounds; }
        [self presentViewController:picker animated:YES completion:nil];
        return;
    }
    if ([item.title isEqualToString:@"设置固定步数"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置每日固定目标" message:@"请输入 1–100000 之间的数值" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCStepCountKey];
            textField.text = value > 0 ? [NSString stringWithFormat:@"%ld", (long)value] : nil;
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = @"步数";
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSInteger value = [alert.textFields.firstObject.text integerValue];
            value = MIN(100000, MAX(1, value));
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setInteger:value forKey:NeoWCStepCountKey];
            [defaults setInteger:NeoWCStepModeDailyFixed forKey:NeoWCStepModeKey];
            [defaults setBool:YES forKey:NeoWCStepOverrideEnabledKey];
            NeoWCSettingsRegenerateDailyStepTarget(defaults);
            [weakSelf reloadSettingsPreservingPosition];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if ([item.title isEqualToString:@"设置随机范围"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置每日随机目标"
                                                                        message:@"每天在最小值和最大值之间生成一次"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = [NSString stringWithFormat:@"%ld", (long)MAX(1, [defaults integerForKey:NeoWCStepRandomMinimumKey])];
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = @"最小步数";
        }];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = [NSString stringWithFormat:@"%ld", (long)MAX(1, [defaults integerForKey:NeoWCStepRandomMaximumKey])];
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = @"最大步数";
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSInteger minimum = MIN(100000, MAX(1, [alert.textFields.firstObject.text integerValue]));
            NSInteger maximum = MIN(100000, MAX(1, [alert.textFields.lastObject.text integerValue]));
            if (minimum > maximum) { NSInteger value = minimum; minimum = maximum; maximum = value; }
            NSUserDefaults *strongDefaults = [NSUserDefaults standardUserDefaults];
            [strongDefaults setInteger:minimum forKey:NeoWCStepRandomMinimumKey];
            [strongDefaults setInteger:maximum forKey:NeoWCStepRandomMaximumKey];
            [strongDefaults setInteger:NeoWCStepModeDailyRandom forKey:NeoWCStepModeKey];
            [strongDefaults setBool:YES forKey:NeoWCStepOverrideEnabledKey];
            if ([strongDefaults integerForKey:NeoWCStepCountKey] <= 0) [strongDefaults setInteger:minimum forKey:NeoWCStepCountKey];
            NeoWCSettingsRegenerateDailyStepTarget(strongDefaults);
            [weakSelf reloadSettingsPreservingPosition];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if ([item.title isEqualToString:@"设置钱包余额"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置钱包余额"
                                                                       message:@"仅修改本机界面显示；留空或输入 0 可恢复真实显示"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            long long fen = NeoWCSettingsLongLongDefaultForKey(NeoWCWalletBalanceFenKey);
            textField.text = fen > 0 ? [NSString stringWithFormat:@"%.2f", fen / 100.0] : nil;
            textField.keyboardType = UIKeyboardTypeDecimalPad;
            textField.placeholder = @"例如 888.88";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSString *text = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            double value = text.length > 0 ? text.doubleValue : 0.0;
            long long fen = value > 0.0 ? (long long)llround(value * 100.0) : 0;
            [[NSUserDefaults standardUserDefaults] setObject:@(MAX(0LL, fen)) forKey:NeoWCWalletBalanceFenKey];
            [[NSUserDefaults standardUserDefaults] setBool:fen > 0 forKey:NeoWCWalletBalanceEnabledKey];
            [weakSelf buildSections];
            [weakSelf.tableView reloadData];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if ([item.title isEqualToString:@"设置好友数量"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置好友数量"
                                                                       message:@"仅替换本机界面中的好友数量文案"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCContactsCountKey];
            textField.text = value > 0 ? [NSString stringWithFormat:@"%ld", (long)value] : nil;
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = @"好友数量";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSInteger value = MAX(0, [alert.textFields.firstObject.text integerValue]);
            [[NSUserDefaults standardUserDefaults] setInteger:value forKey:NeoWCContactsCountKey];
            [[NSUserDefaults standardUserDefaults] setBool:value > 0 forKey:NeoWCContactsCountEnabledKey];
            [weakSelf buildSections];
            [weakSelf.tableView reloadData];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
}

@end
