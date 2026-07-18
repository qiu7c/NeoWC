#import "NeoWCPluginVisibility.h"
#import "NeoWCDebug.h"

#import <objc/runtime.h>

static NSString *const NeoWCKnownPluginsKey = @"com.qiu7c.neowc.plugins.known";
static NSString *const NeoWCHiddenPluginIdentifiersKey = @"com.qiu7c.neowc.plugins.hidden";
static NSString *const NeoWCPluginListDidChangeNotification = @"NeoWCPluginListDidChangeNotification";
static char NeoWCPluginIdentifierAssociationKey;

@interface NeoWCPluginVisibilityManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *records;
@property (nonatomic, strong) NSMutableSet<NSString *> *activeIdentifiers;
@property (nonatomic, strong) NSMutableSet<NSString *> *hiddenIdentifiers;
- (void)recordTitle:(NSString *)title identifier:(NSString *)identifier type:(NSString *)type detail:(NSString *)detail version:(NSString *)version;
- (NSArray<NSDictionary *> *)sortedRecords;
- (BOOL)isActiveIdentifier:(NSString *)identifier;
- (BOOL)isHiddenIdentifier:(NSString *)identifier;
- (void)setHidden:(BOOL)hidden identifier:(NSString *)identifier;
- (NSSet<NSString *> *)hiddenTitles;
@end

@implementation NeoWCPluginVisibilityManager

+ (instancetype)sharedManager {
    static NeoWCPluginVisibilityManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [NeoWCPluginVisibilityManager new]; });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _records = [NSMutableDictionary dictionary];
        NSArray *savedRecords = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCKnownPluginsKey];
        for (NSDictionary *record in savedRecords) {
            NSString *identifier = record[@"identifier"];
            if (identifier.length > 0) _records[identifier] = record;
        }
        _activeIdentifiers = [NSMutableSet set];
        NSArray *hidden = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCHiddenPluginIdentifiersKey];
        _hiddenIdentifiers = [NSMutableSet setWithArray:hidden ?: @[]];
    }
    return self;
}

- (void)recordControllerWithTitle:(NSString *)title version:(NSString *)version controller:(NSString *)controller {
    NSString *identifier = controller.length > 0 ? [@"controller:" stringByAppendingString:controller] : [@"title:" stringByAppendingString:title ?: @""];
    [self recordTitle:title identifier:identifier type:@"设置页面" detail:controller version:version];
}

- (void)recordSwitchWithTitle:(NSString *)title key:(NSString *)key {
    NSString *identifier = key.length > 0 ? [@"switch:" stringByAppendingString:key] : [@"title:" stringByAppendingString:title ?: @""];
    [self recordTitle:title identifier:identifier type:@"独立开关" detail:key version:nil];
}

- (void)recordTitle:(NSString *)title identifier:(NSString *)identifier type:(NSString *)type detail:(NSString *)detail version:(NSString *)version {
    if (title.length == 0 || identifier.length == 0) return;
    NSMutableDictionary *record = [NSMutableDictionary dictionaryWithDictionary:@{
        @"identifier": identifier,
        @"title": title,
        @"type": type ?: @"插件",
        @"detail": detail ?: @"",
    }];
    if (version.length > 0) record[@"version"] = version;
    @synchronized (self) {
        self.records[identifier] = record;
        [self.activeIdentifiers addObject:identifier];
        [[NSUserDefaults standardUserDefaults] setObject:self.records.allValues forKey:NeoWCKnownPluginsKey];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCPluginListDidChangeNotification object:nil];
    NeoWCLog(@"检测到插件注册：%@ (%@)", title, detail ?: type);
}

- (NSArray<NSDictionary *> *)sortedRecords {
    @synchronized (self) {
        return [self.records.allValues sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
            BOOL leftActive = [self.activeIdentifiers containsObject:left[@"identifier"]];
            BOOL rightActive = [self.activeIdentifiers containsObject:right[@"identifier"]];
            if (leftActive != rightActive) return leftActive ? NSOrderedAscending : NSOrderedDescending;
            return [left[@"title"] localizedCompare:right[@"title"]];
        }];
    }
}

- (BOOL)isActiveIdentifier:(NSString *)identifier { @synchronized (self) { return [self.activeIdentifiers containsObject:identifier]; } }
- (BOOL)isHiddenIdentifier:(NSString *)identifier { @synchronized (self) { return [self.hiddenIdentifiers containsObject:identifier]; } }

- (void)setHidden:(BOOL)hidden identifier:(NSString *)identifier {
    if (identifier.length == 0 || [identifier isEqualToString:@"controller:NeoWCSettingsViewController"]) return;
    @synchronized (self) {
        if (hidden) [self.hiddenIdentifiers addObject:identifier];
        else [self.hiddenIdentifiers removeObject:identifier];
        [[NSUserDefaults standardUserDefaults] setObject:self.hiddenIdentifiers.allObjects forKey:NeoWCHiddenPluginIdentifiersKey];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCPluginListDidChangeNotification object:nil];
}

- (NSSet<NSString *> *)hiddenTitles {
    NSMutableSet<NSString *> *titles = [NSMutableSet set];
    @synchronized (self) {
        for (NSString *identifier in self.hiddenIdentifiers) {
            NSString *title = self.records[identifier][@"title"];
            if (title.length > 0 && ![title isEqualToString:@"NeoWC"]) [titles addObject:title];
        }
    }
    return titles;
}

@end

static NSString *NeoWCPluginModelTitle(id model) {
    if ([model isKindOfClass:[NSDictionary class]]) {
        id title = model[@"title"];
        return [title isKindOfClass:[NSString class]] ? title : nil;
    }
    @try {
        id title = [model valueForKey:@"title"];
        return [title isKindOfClass:[NSString class]] ? title : nil;
    } @catch (__unused NSException *exception) { return nil; }
}

void NeoWCFilterPluginListController(id controller) {
    NSSet<NSString *> *hiddenTitles = [[NeoWCPluginVisibilityManager sharedManager] hiddenTitles];
    if (hiddenTitles.count == 0 || !controller) return;
    @try {
        NSMutableArray *dataSource = [controller valueForKey:@"dataSource"];
        if (![dataSource isKindOfClass:[NSMutableArray class]]) return;
        NSIndexSet *indexes = [dataSource indexesOfObjectsPassingTest:^BOOL(id model, NSUInteger index, BOOL *stop) {
            return [hiddenTitles containsObject:NeoWCPluginModelTitle(model)];
        }];
        if (indexes.count == 0) return;
        [dataSource removeObjectsAtIndexes:indexes];
        UITableView *tableView = nil;
        @try { tableView = [controller valueForKey:@"tableView"]; } @catch (__unused NSException *exception) {}
        if (![tableView isKindOfClass:[UITableView class]]) {
            for (NSString *managerKey in @[@"tableViewManager", @"tableViewMgr"]) {
                @try {
                    id manager = [controller valueForKey:managerKey];
                    id candidate = [manager valueForKey:@"tableView"];
                    if ([candidate isKindOfClass:[UITableView class]]) { tableView = candidate; break; }
                } @catch (__unused NSException *exception) {}
            }
        }
        if ([tableView isKindOfClass:[UITableView class]]) [tableView reloadData];
        NeoWCLog(@"插件管理页面已隐藏 %lu 项", (unsigned long)indexes.count);
    } @catch (NSException *exception) {
        NeoWCLog(@"插件列表过滤失败：%@", exception.reason);
    }
}

@interface NeoWCPluginVisibilityViewController ()
@property (nonatomic, copy) NSArray<NSDictionary *> *plugins;
@end


@implementation NeoWCPluginVisibilityViewController

- (instancetype)init { return [self initWithStyle:UITableViewStyleInsetGrouped]; }
- (instancetype)initWithStyle:(UITableViewStyle)style { return [super initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"插件显示管理";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPlugins) name:NeoWCPluginListDidChangeNotification object:nil];
    [self reloadPlugins];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)reloadPlugins { self.plugins = [[NeoWCPluginVisibilityManager sharedManager] sortedRecords]; [self.tableView reloadData]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.plugins.count; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @"已发现的插件"; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section { return @"关闭“显示”只会从插件管理页面隐藏入口，不会停止插件运行；本次没有注册的插件会标记为未加载。"; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PluginCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"PluginCell"];
    NSDictionary *plugin = self.plugins[indexPath.row];
    NSString *identifier = plugin[@"identifier"];
    BOOL active = [[NeoWCPluginVisibilityManager sharedManager] isActiveIdentifier:identifier];
    BOOL locked = [identifier isEqualToString:@"controller:NeoWCSettingsViewController"];
    cell.textLabel.text = plugin[@"title"];
    NSString *version = plugin[@"version"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@ · %@", plugin[@"type"], version.length ? [@" v" stringByAppendingString:version] : @"", active ? @"已加载" : @"本次未加载"];
    cell.textLabel.textColor = active ? [UIColor labelColor] : [UIColor secondaryLabelColor];
    UISwitch *toggle = [UISwitch new];
    toggle.onTintColor = [UIColor systemBlueColor];
    toggle.on = ![[NeoWCPluginVisibilityManager sharedManager] isHiddenIdentifier:identifier];
    toggle.enabled = !locked;
    objc_setAssociatedObject(toggle, &NeoWCPluginIdentifierAssociationKey, identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [toggle addTarget:self action:@selector(visibilityChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)visibilityChanged:(UISwitch *)sender {
    NSString *identifier = objc_getAssociatedObject(sender, &NeoWCPluginIdentifierAssociationKey);
    [[NeoWCPluginVisibilityManager sharedManager] setHidden:!sender.isOn identifier:identifier];
}

@end
