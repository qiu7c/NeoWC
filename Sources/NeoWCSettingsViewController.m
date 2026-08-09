#import "NeoWCSettingsViewController.h"
#import "NeoWCSettingsActions.h"
#import "NeoWCSettingsCatalog.h"
#import "NeoWCSettingsModels.h"
#import "NeoWCSettingsUI.h"
#import "NeoWCAntiRevoke.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import "NeoWCInterfaceTweaks.h"
#import "NeoWCPluginShortcuts.h"
#import <math.h>

@interface NeoWCSettingsViewController ()
@property (nonatomic, assign) NeoWCSettingsCategory category;
@property (nonatomic, copy) NSArray<NeoWCSettingSection *> *sections;
@property (nonatomic, strong) NSMutableSet<NSString *> *collapsedFeatureKeys;
@property (nonatomic, strong) NeoWCSettingsActions *actions;
@property (nonatomic, strong) NeoWCSettingsProfileHeaderView *profileHeader;
- (instancetype)initWithCategory:(NeoWCSettingsCategory)category;
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
    self.collapsedFeatureKeys = [NSMutableSet setWithArray:[defaults arrayForKey:NeoWCCollapsedFeaturesKey] ?: @[]];
    self.title = [self titleForCategory:self.category];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 56.0;
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [self.tableView registerClass:NeoWCSettingsCell.class forCellReuseIdentifier:@"NeoWCSettingsCell"];

    __weak typeof(self) weakSelf = self;
    self.actions = [[NeoWCSettingsActions alloc] initWithViewController:self reloadHandler:^(BOOL applyScale) {
        [weakSelf reloadSettingsPreservingPositionApplyScale:applyScale];
    }];
    if (self.category == NeoWCSettingsCategoryRoot) {
        self.profileHeader = [[NeoWCSettingsProfileHeaderView alloc] initWithFrame:CGRectZero];
        [self.profileHeader addTarget:self action:@selector(profileHeaderTapped) forControlEvents:UIControlEventTouchUpInside];
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
    [self.profileHeader refreshProfile];
    [self reloadSettingsPreservingPositionApplyScale:YES];
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

- (void)saveCollapsedFeatureKeys {
    [NSUserDefaults.standardUserDefaults setObject:self.collapsedFeatureKeys.allObjects forKey:NeoWCCollapsedFeaturesKey];
}

- (NeoWCSettingItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 0 || indexPath.section >= self.sections.count) return nil;
    NSArray *items = self.sections[indexPath.section].items;
    return indexPath.row >= 0 && indexPath.row < items.count ? items[indexPath.row] : nil;
}

- (void)profileHeaderTapped {
    if (self.profileHeader.wxid.length == 0) return;
    UIPasteboard.generalPasteboard.string = self.profileHeader.wxid;
    self.navigationItem.prompt = @"wxid 已复制";
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.navigationItem.prompt = nil;
    });
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
    if ([item.defaultsKey isEqualToString:NeoWCStepOverrideEnabledKey] && enabled) NeoWCSettingsRegenerateDailyStepTarget(defaults);
    if ([item.defaultsKey isEqualToString:NeoWCAntiRevokePersistRecordsKey]) NeoWCAntiRevokeSetPersistenceEnabled(enabled);
    if ([item.defaultsKey hasPrefix:@"com.qiu7c.neowc."]) [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification object:item.defaultsKey];
    if ([item.defaultsKey isEqualToString:NeoWCDebugFloatingEnabledKey]) [[NeoWCDebugManager sharedManager] setFloatingEnabled:enabled];
    if ([item.defaultsKey hasPrefix:@"com.qiu7c.neowc.plugin-shortcuts."]) NeoWCRegisterPluginShortcutsIfAvailable();
    if ([item.defaultsKey isEqualToString:NeoWCAntiRevokeKey]) [NSNotificationCenter.defaultCenter postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    BOOL applyScale = [item.defaultsKey isEqualToString:NeoWCPageScaleEnabledKey];
    if (item.hasChildren || [item.defaultsKey isEqualToString:NeoWCEnabledKey] || applyScale) {
        [self reloadSettingsPreservingPositionApplyScale:applyScale];
    }
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
