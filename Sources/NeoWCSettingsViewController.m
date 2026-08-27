#import "NeoWCSettingsViewController.h"
#import "NeoWCAccount.h"
#import "NeoWCSettingsActions.h"
#import "NeoWCSettingsCatalog.h"
#import "NeoWCSettingsModels.h"
#import "NeoWCSettingsUI.h"
#import "NeoWCAntiRevoke.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import "NeoWCInterfaceTweaks.h"
#import "NeoWCPluginManager.h"
#import "NeoWCReleaseNotes.h"
#import <math.h>

@interface NeoWCSettingsViewController ()
@property (nonatomic, assign) NeoWCSettingsCategory category;
@property (nonatomic, copy) NSArray<NeoWCSettingSection *> *sections;
@property (nonatomic, strong) NSMutableSet<NSString *> *collapsedFeatureKeys;
@property (nonatomic, strong) NeoWCSettingsActions *actions;
@property (nonatomic, strong) NeoWCSettingsProfileHeaderView *profileHeader;
@property (nonatomic, assign) BOOL attemptedReleaseNotes;
- (instancetype)initWithCategory:(NeoWCSettingsCategory)category;
- (void)presentReleaseNotesIfNeeded;
- (void)quickSwitchLongPressed:(UILongPressGestureRecognizer *)gesture;
- (void)showQuickSwitchToast:(NSString *)message;
@end

@implementation NeoWCSettingsViewController

- (instancetype)init {
    return [self initWithCategory:NeoWCSettingsCategoryRoot];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    (void)style;
    return [self initWithCategory:NeoWCSettingsCategoryRoot];
}

- (instancetype)initWithCategory:(NeoWCSettingsCategory)category {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) _category = category;
    return self;
}

- (NSString *)titleForCategory:(NeoWCSettingsCategory)category {
    switch (category) {
        case NeoWCSettingsCategoryMessages: return @"聊天增强";
        case NeoWCSettingsCategoryEnhancements: return @"常用增强";
        case NeoWCSettingsCategoryInterface: return @"界面优化";
        case NeoWCSettingsCategoryDeveloper: return @"开发者功能";
        case NeoWCSettingsCategoryRoot:
        default: return @"NeoWC";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NeoWCSettingsRegisterDefaults();
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSSet<NSString *> *supportedMeTitles = [NSSet setWithArray:@[@"作品", @"小店与卡包", @"表情"]];
    NSArray<NSString *> *hiddenMeTitles = [defaults arrayForKey:NeoWCMeMenuHiddenTitlesKey] ?: @[];
    NSArray<NSString *> *filteredMeTitles = [hiddenMeTitles filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *title, NSDictionary *bindings) {
        (void)bindings;
        return [supportedMeTitles containsObject:title];
    }]];
    if (![filteredMeTitles isEqualToArray:hiddenMeTitles]) [defaults setObject:filteredMeTitles forKey:NeoWCMeMenuHiddenTitlesKey];
    [self collapseFeaturesForInitialEntry];
    self.title = [self titleForCategory:self.category];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 56.0;
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [self.tableView registerClass:NeoWCSettingsCell.class forCellReuseIdentifier:@"NeoWCSettingsCell"];
    UILongPressGestureRecognizer *quickSwitchGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(quickSwitchLongPressed:)];
    quickSwitchGesture.minimumPressDuration = 0.55;
    [self.tableView addGestureRecognizer:quickSwitchGesture];

    __weak typeof(self) weakSelf = self;
    self.actions = [[NeoWCSettingsActions alloc] initWithViewController:self reloadHandler:^(BOOL applyScale) {
        [weakSelf reloadSettingsPreservingPositionApplyScale:applyScale];
    }];
    if (self.category == NeoWCSettingsCategoryRoot) {
        self.profileHeader = [[NeoWCSettingsProfileHeaderView alloc] initWithFrame:CGRectZero];
        [self.profileHeader addTarget:self action:@selector(profileHeaderTapped) forControlEvents:UIControlEventTouchUpInside];
        UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = UIColor.systemGroupedBackgroundColor;
        appearance.shadowColor = UIColor.clearColor;
        self.navigationItem.standardAppearance = appearance;
        self.navigationItem.scrollEdgeAppearance = appearance;
        self.navigationItem.compactAppearance = appearance;
    }
    [self applySettingsPageScale];
    [self rebuildSections];
}

- (CGFloat)settingsPageScale {
    if (!NeoWCEnhancementEnabled(NeoWCPageScaleEnabledKey)) return 1.0;
    return NeoWCScalePercentForDefaultsKey(NeoWCSettingsPageScalePercentKey, 100.0) / 100.0;
}

- (void)applySettingsPageScale {
    CGFloat scale = [self settingsPageScale];
    self.tableView.estimatedRowHeight = MAX(48.0, 56.0 * scale);
    self.tableView.estimatedSectionHeaderHeight = MAX(28.0, 36.0 * scale);
    self.tableView.estimatedSectionFooterHeight = MAX(28.0, 36.0 * scale);
    if (self.profileHeader) {
        CGFloat width = CGRectGetWidth(self.tableView.bounds);
        CGFloat height = [self.profileHeader preferredHeightForWidth:width scale:scale];
        self.profileHeader.frame = CGRectMake(0.0, 0.0, width, height);
        self.tableView.tableHeaderView = self.profileHeader;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadSettingsPreservingPositionApplyScale:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.category == NeoWCSettingsCategoryRoot) NeoWCRefreshCachedCurrentUserContact();
    [self.profileHeader refreshProfile];
    if (self.category != NeoWCSettingsCategoryRoot) return;
    [self presentReleaseNotesIfNeeded];
}

- (void)presentReleaseNotesIfNeeded {
    if (self.attemptedReleaseNotes || self.category != NeoWCSettingsCategoryRoot || !self.view.window) return;
    self.attemptedReleaseNotes = YES;
    if (!NeoWCShouldPresentCurrentReleaseNotes()) return;
    [self presentViewController:[NeoWCReleaseNotesViewController new]
                       animated:NO
                     completion:^{ NeoWCMarkCurrentReleaseNotesPresented(); }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!self.profileHeader) return;
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    if (fabs(CGRectGetWidth(self.profileHeader.frame) - width) < 0.5) return;
    CGFloat height = [self.profileHeader preferredHeightForWidth:width scale:[self settingsPageScale]];
    self.profileHeader.frame = CGRectMake(0.0, 0.0, width, height);
    self.tableView.tableHeaderView = self.profileHeader;
}

- (void)rebuildSections {
    self.sections = NeoWCSettingsBuildSections(self.category, self.collapsedFeatureKeys);
}

- (void)reloadSettingsPreservingPositionApplyScale:(BOOL)applyScale {
    CGPoint offset = self.tableView.contentOffset;
    if (applyScale) [self applySettingsPageScale];
    [self rebuildSections];
    [UIView performWithoutAnimation:^{
        [self.tableView reloadData];
        [self.tableView setContentOffset:offset animated:NO];
    }];
}

- (void)collapseFeaturesForInitialEntry {
    NSMutableSet<NSString *> *collapsedKeys = [NSMutableSet set];
    NSArray<NeoWCSettingSection *> *expandedSections = NeoWCSettingsBuildSections(self.category, [NSSet set]);
    for (NeoWCSettingSection *section in expandedSections) {
        for (NeoWCSettingItem *item in section.items) {
            if (item.hasChildren && item.defaultsKey.length > 0) [collapsedKeys addObject:item.defaultsKey];
        }
    }
    self.collapsedFeatureKeys = collapsedKeys;
}

- (void)saveCollapsedFeatureKeys {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSArray<NSString *> *savedKeys = [self.collapsedFeatureKeys.allObjects sortedArrayUsingSelector:@selector(compare:)];
    [defaults setObject:savedKeys forKey:NeoWCCollapsedFeaturesKey];
}

- (NeoWCSettingItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 0 || indexPath.section >= self.sections.count) return nil;
    NSArray *items = self.sections[indexPath.section].items;
    return indexPath.row >= 0 && indexPath.row < items.count ? items[indexPath.row] : nil;
}

- (void)profileHeaderTapped {
    if (self.profileHeader.wxid.length == 0) return;
    UIPasteboard.generalPasteboard.string = self.profileHeader.wxid;
    [self.profileHeader showCopyConfirmation];
}

- (void)toggleFeature:(NeoWCSettingItem *)item {
    if (!item.hasChildren || ![NSUserDefaults.standardUserDefaults boolForKey:item.defaultsKey]) return;
    if ([self.collapsedFeatureKeys containsObject:item.defaultsKey]) {
        [self.collapsedFeatureKeys removeObject:item.defaultsKey];
    } else {
        [self.collapsedFeatureKeys addObject:item.defaultsKey];
    }
    [self saveCollapsedFeatureKeys];
    [self reloadSettingsPreservingPositionApplyScale:NO];
}

- (void)switchItem:(NeoWCSettingItem *)item changedTo:(BOOL)enabled {
    if (item.defaultsKey.length == 0) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setBool:enabled forKey:item.defaultsKey];
    if (enabled && item.hasChildren) {
        [self.collapsedFeatureKeys removeObject:item.defaultsKey];
        [self saveCollapsedFeatureKeys];
    }
    NeoWCSettingsHandleSwitchChange(item.defaultsKey, enabled);
    if (enabled && [item.defaultsKey isEqualToString:NeoWCMomentsReminderEnabledKey] &&
        ![defaults boolForKey:NeoWCBackgroundKeepAliveEnabledKey]) {
        UIAlertController *recommendation = [UIAlertController alertControllerWithTitle:@"建议开启保持后台运行"
                                                                                 message:@"未开启时，朋友圈提醒可能只有在微信前台活跃期间才能检测。两个功能仍保持独立，可暂不启用后台保持。"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [recommendation addAction:[UIAlertAction actionWithTitle:@"暂不开启" style:UIAlertActionStyleCancel handler:nil]];
        __weak typeof(self) weakSelf = self;
        [recommendation addAction:[UIAlertAction actionWithTitle:@"开启后台保持" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [defaults setBool:YES forKey:NeoWCBackgroundKeepAliveEnabledKey];
            NeoWCSettingsHandleSwitchChange(NeoWCBackgroundKeepAliveEnabledKey, YES);
            [weakSelf reloadSettingsPreservingPositionApplyScale:NO];
        }]];
        [self presentViewController:recommendation animated:YES completion:nil];
    }
    BOOL applyScale = [item.defaultsKey isEqualToString:NeoWCPageScaleEnabledKey];
    if (item.hasChildren || [item.defaultsKey isEqualToString:NeoWCEnabledKey] || applyScale) {
        [self reloadSettingsPreservingPositionApplyScale:applyScale];
    }
}

- (void)quickSwitchLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[gesture locationInView:self.tableView]];
    NeoWCSettingItem *item = indexPath ? [self itemAtIndexPath:indexPath] : nil;
    if (item.kind != NeoWCSettingRowKindSwitch || item.defaultsKey.length == 0 ||
        [item.defaultsKey isEqualToString:NeoWCEnabledKey]) return;

    BOOL registered = NeoWCPluginManagerIsQuickSwitchRegistered(item.defaultsKey);
    NSString *actionTitle = registered ? @"从插件管理移除" : @"添加到插件管理";
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:item.title
                                                                    message:@"快捷开关与设置页使用同一配置"
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:actionTitle
                                             style:registered ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction *action) {
        NeoWCPluginManagerSetQuickSwitchRegistered(item.defaultsKey, item.title, !registered);
        UINotificationFeedbackGenerator *feedback = [UINotificationFeedbackGenerator new];
        [feedback notificationOccurred:UINotificationFeedbackTypeSuccess];
        [self showQuickSwitchToast:registered ? @"已从插件管理移除" : @"已添加到插件管理"];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        popover.sourceView = cell ?: self.tableView;
        popover.sourceRect = (cell ?: self.tableView).bounds;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showQuickSwitchToast:(NSString *)message {
    if (message.length == 0) return;
    const NSInteger toastTag = 0x4E575154;
    [[self.view viewWithTag:toastTag] removeFromSuperview];

    UILabel *toast = [UILabel new];
    toast.tag = toastTag;
    toast.text = message;
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    toast.adjustsFontForContentSizeCategory = YES;
    toast.textColor = UIColor.whiteColor;
    toast.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.88];
    toast.layer.cornerRadius = 12.0;
    toast.layer.cornerCurve = kCACornerCurveContinuous;
    toast.layer.masksToBounds = YES;
    toast.userInteractionEnabled = NO;
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    toast.alpha = 0.0;
    toast.transform = CGAffineTransformMakeTranslation(0.0, 6.0);
    [self.view addSubview:toast];
    [NSLayoutConstraint activateConstraints:@[
        [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-22.0],
        [toast.heightAnchor constraintGreaterThanOrEqualToConstant:36.0],
        [toast.widthAnchor constraintGreaterThanOrEqualToConstant:132.0],
        [toast.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [toast.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24.0]
    ]];

    [UIView animateWithDuration:0.18 animations:^{
        toast.alpha = 1.0;
        toast.transform = CGAffineTransformIdentity;
    } completion:^(__unused BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                toast.alpha = 0.0;
                toast.transform = CGAffineTransformMakeTranslation(0.0, 5.0);
            } completion:^(__unused BOOL hidden) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

- (void)openCategory:(NeoWCSettingsCategory)category {
    [self.navigationController pushViewController:[[NeoWCSettingsViewController alloc] initWithCategory:category] animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section].title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.sections[section].footer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NeoWCSettingsCell" forIndexPath:indexPath];
    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    BOOL masterEnabled = [NSUserDefaults.standardUserDefaults boolForKey:NeoWCEnabledKey];
    BOOL expanded = item.defaultsKey.length == 0 || ![self.collapsedFeatureKeys containsObject:item.defaultsKey];
    __weak typeof(self) weakSelf = self;
    [cell configureWithItem:item masterEnabled:masterEnabled expanded:expanded scale:[self settingsPageScale] switchHandler:^(NeoWCSettingItem *changedItem, BOOL enabled) {
        [weakSelf switchItem:changedItem changedTo:enabled];
    }];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NeoWCSettingItem *item = [self itemAtIndexPath:indexPath];
    if (item.kind == NeoWCSettingRowKindSwitch) {
        [self toggleFeature:item];
        return;
    }
    switch (item.action) {
        case NeoWCSettingActionOpenMessages: [self openCategory:NeoWCSettingsCategoryMessages]; break;
        case NeoWCSettingActionOpenEnhancements: [self openCategory:NeoWCSettingsCategoryEnhancements]; break;
        case NeoWCSettingActionOpenInterface: [self openCategory:NeoWCSettingsCategoryInterface]; break;
        case NeoWCSettingActionOpenDeveloper: [self openCategory:NeoWCSettingsCategoryDeveloper]; break;
        default: [self.actions performActionForItem:item]; break;
    }
}

@end
