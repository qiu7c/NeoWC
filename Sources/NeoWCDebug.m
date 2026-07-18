#import "NeoWCDebug.h"

#import <objc/runtime.h>
#import <mach-o/dyld.h>

NSString *const NeoWCDebugFloatingEnabledKey = @"com.qiu7c.neowc.debug.floating-enabled";

static NSString *const NeoWCDebugLogDidChangeNotification = @"NeoWCDebugLogDidChangeNotification";

@interface NeoWCDebugLogStore : NSObject
@property (nonatomic, strong) NSMutableArray<NSString *> *entries;
+ (instancetype)sharedStore;
- (void)appendMessage:(NSString *)message;
- (NSArray<NSString *> *)snapshot;
- (void)clear;
@end

@implementation NeoWCDebugLogStore

+ (instancetype)sharedStore {
    static NeoWCDebugLogStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [NeoWCDebugLogStore new];
        store.entries = [NSMutableArray array];
    });
    return store;
}

- (void)appendMessage:(NSString *)message {
    if (!message) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.dateFormat = @"HH:mm:ss.SSS";
        NSString *line = [NSString stringWithFormat:@"[%@] %@", [formatter stringFromDate:[NSDate date]], message];
        [self.entries addObject:line];
        if (self.entries.count > 500) {
            [self.entries removeObjectsInRange:NSMakeRange(0, self.entries.count - 500)];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCDebugLogDidChangeNotification object:nil];
    });
}

- (NSArray<NSString *> *)snapshot {
    return [self.entries copy];
}

- (void)clear {
    [self.entries removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCDebugLogDidChangeNotification object:nil];
}

@end

void NeoWCLog(NSString *format, ...) {
    if (!format) return;
    va_list arguments;
    va_start(arguments, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    [[NeoWCDebugLogStore sharedStore] appendMessage:message];
}

@interface NeoWCDebugWindow : UIWindow
@end
@implementation NeoWCDebugWindow
@end

@interface NeoWCPassthroughView : UIView
@end
@implementation NeoWCPassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    return hitView == self ? nil : hitView;
}
@end

static UIWindowScene *NeoWCActiveWindowScene(void) {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                return (UIWindowScene *)scene;
            }
        }
    }
    return nil;
}

static UIWindow *NeoWCMainWindow(void) {
    NSArray<UIWindow *> *windows = nil;
    UIWindowScene *scene = NeoWCActiveWindowScene();
    if (@available(iOS 13.0, *)) {
        windows = scene.windows;
    }
    if (windows.count == 0) windows = UIApplication.sharedApplication.windows;

    UIWindow *fallback = nil;
    for (UIWindow *window in [windows reverseObjectEnumerator]) {
        if ([window isKindOfClass:[NeoWCDebugWindow class]] || window.hidden || window.alpha <= 0.01) continue;
        if (window.windowLevel == UIWindowLevelNormal && window.rootViewController) {
            if (window.isKeyWindow) return window;
            fallback = window;
        }
    }
    return fallback;
}

static UIViewController *NeoWCTopViewController(UIViewController *controller) {
    if (!controller) return nil;
    if (controller.presentedViewController) return NeoWCTopViewController(controller.presentedViewController);
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return NeoWCTopViewController(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return NeoWCTopViewController(((UITabBarController *)controller).selectedViewController);
    }
    return controller;
}

static UIViewController *NeoWCViewControllerForView(UIView *view) {
    UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) return (UIViewController *)responder;
        responder = responder.nextResponder;
    }
    return nil;
}

@interface NeoWCObjectInspectorViewController : UIViewController
- (instancetype)initWithObject:(id)object inspectedClass:(Class)inspectedClass;
@end

@interface NeoWCRuntimeSearchViewController : UITableViewController <UISearchResultsUpdating>
@end

@interface NeoWCLogViewController : UITableViewController
@end

@interface NeoWCDebugDashboardViewController : UITableViewController
@property (nonatomic, copy) void (^closeHandler)(void);
@end

@interface NeoWCViewPickerController : UIViewController <UIGestureRecognizerDelegate>
@end

@interface NeoWCDebugManager ()
@property (nonatomic, strong) NeoWCDebugWindow *floatingWindow;
@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) NeoWCDebugWindow *pickerWindow;
@end

@implementation NeoWCDebugManager

+ (instancetype)sharedManager {
    static NeoWCDebugManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [NeoWCDebugManager new]; });
    return manager;
}

- (void)applySavedState {
    BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCDebugFloatingEnabledKey];
    [self setFloatingEnabled:enabled];
}

- (NeoWCDebugWindow *)newDebugWindowAtLevel:(UIWindowLevel)level {
    NeoWCDebugWindow *window = nil;
    UIWindowScene *scene = NeoWCActiveWindowScene();
    if (@available(iOS 13.0, *)) {
        if (scene) window = [[NeoWCDebugWindow alloc] initWithWindowScene:scene];
    }
    if (!window) window = [[NeoWCDebugWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    window.frame = UIScreen.mainScreen.bounds;
    window.windowLevel = level;
    window.backgroundColor = UIColor.clearColor;
    return window;
}

- (void)setFloatingEnabled:(BOOL)enabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:NeoWCDebugFloatingEnabledKey];
        if (!enabled) {
            self.floatingWindow.hidden = YES;
            self.floatingWindow = nil;
            self.floatingButton = nil;
            NeoWCLog(@"调试悬浮入口已关闭");
            return;
        }
        if (self.floatingWindow) {
            self.floatingWindow.hidden = NO;
            return;
        }

        NeoWCDebugWindow *window = [self newDebugWindowAtLevel:UIWindowLevelAlert + 8.0];
        UIViewController *root = [UIViewController new];
        NeoWCPassthroughView *passthroughView = [[NeoWCPassthroughView alloc] initWithFrame:window.bounds];
        passthroughView.backgroundColor = UIColor.clearColor;
        root.view = passthroughView;
        window.rootViewController = root;

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.backgroundColor = [UIColor secondarySystemBackgroundColor];
        button.tintColor = [UIColor labelColor];
        button.layer.cornerRadius = 24.0;
        button.layer.cornerCurve = kCACornerCurveContinuous;
        button.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
        button.layer.borderColor = UIColor.separatorColor.CGColor;
        button.accessibilityLabel = @"打开 NeoWC 调试中心";
        UIImage *image = [UIImage systemImageNamed:@"wrench.and.screwdriver"] ?: [UIImage systemImageNamed:@"wrench"];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(floatingButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [passthroughView addSubview:button];
        [NSLayoutConstraint activateConstraints:@[
            [button.widthAnchor constraintEqualToConstant:48.0],
            [button.heightAnchor constraintEqualToConstant:48.0],
            [button.trailingAnchor constraintEqualToAnchor:passthroughView.safeAreaLayoutGuide.trailingAnchor constant:-16.0],
            [button.bottomAnchor constraintEqualToAnchor:passthroughView.safeAreaLayoutGuide.bottomAnchor constant:-86.0],
        ]];

        self.floatingWindow = window;
        self.floatingButton = button;
        window.hidden = NO;
        NeoWCLog(@"调试悬浮入口已开启（无全局手势）");
    });
}

- (void)floatingButtonTapped {
    UIWindow *mainWindow = NeoWCMainWindow();
    UIViewController *top = NeoWCTopViewController(mainWindow.rootViewController);
    [self presentDashboardFromViewController:top];
}

- (void)presentDashboardFromViewController:(UIViewController *)viewController {
    if (!viewController) return;
    self.floatingWindow.hidden = YES;
    NeoWCDebugDashboardViewController *dashboard = [[NeoWCDebugDashboardViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
    __weak typeof(self) weakSelf = self;
    dashboard.closeHandler = ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:NeoWCDebugFloatingEnabledKey]) {
            weakSelf.floatingWindow.hidden = NO;
        }
    };
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:dashboard];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)beginViewPicking {
    NeoWCDebugWindow *window = [self newDebugWindowAtLevel:UIWindowLevelAlert + 20.0];
    NeoWCViewPickerController *picker = [NeoWCViewPickerController new];
    window.rootViewController = picker;
    self.pickerWindow = window;
    window.hidden = NO;
    NeoWCLog(@"视图选择器已启动");
}

- (void)finishPickingView:(UIView *)view {
    self.pickerWindow.hidden = YES;
    self.pickerWindow = nil;
    if (!view) return;
    NeoWCLog(@"选中视图 %@ (%p)", NSStringFromClass(view.class), view);
    UIViewController *top = NeoWCTopViewController(NeoWCMainWindow().rootViewController);
    NeoWCObjectInspectorViewController *inspector = [[NeoWCObjectInspectorViewController alloc] initWithObject:view inspectedClass:view.class];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:inspector];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [top presentViewController:navigationController animated:YES completion:nil];
}

- (void)cancelPicking {
    self.pickerWindow.hidden = YES;
    self.pickerWindow = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:NeoWCDebugFloatingEnabledKey]) self.floatingWindow.hidden = NO;
    NeoWCLog(@"视图选择器已取消");
}

@end

@implementation NeoWCViewPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.08];

    UILabel *banner = [UILabel new];
    banner.translatesAutoresizingMaskIntoConstraints = NO;
    banner.text = @"点击要检查的视图";
    banner.textAlignment = NSTextAlignmentCenter;
    banner.textColor = UIColor.whiteColor;
    banner.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.92];
    banner.layer.cornerRadius = 12.0;
    banner.layer.cornerCurve = kCACornerCurveContinuous;
    banner.layer.masksToBounds = YES;
    [self.view addSubview:banner];

    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    cancel.translatesAutoresizingMaskIntoConstraints = NO;
    [cancel setTitle:@"取消" forState:UIControlStateNormal];
    cancel.backgroundColor = [UIColor secondarySystemBackgroundColor];
    cancel.layer.cornerRadius = 12.0;
    [cancel addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancel];

    [NSLayoutConstraint activateConstraints:@[
        [banner.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:14.0],
        [banner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [banner.widthAnchor constraintEqualToConstant:180.0],
        [banner.heightAnchor constraintEqualToConstant:42.0],
        [cancel.centerYAnchor constraintEqualToAnchor:banner.centerYAnchor],
        [cancel.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-14.0],
        [cancel.widthAnchor constraintEqualToConstant:62.0],
        [cancel.heightAnchor constraintEqualToConstant:42.0],
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTapped:)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *candidate = touch.view;
    while (candidate && candidate != self.view) {
        if ([candidate isKindOfClass:[UIButton class]]) return NO;
        candidate = candidate.superview;
    }
    return YES;
}

- (void)cancelTapped {
    [[NeoWCDebugManager sharedManager] cancelPicking];
}

- (void)screenTapped:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    if (point.y < CGRectGetMinY(self.view.safeAreaLayoutGuide.layoutFrame) + 64.0) return;
    NeoWCDebugManager *manager = [NeoWCDebugManager sharedManager];
    NeoWCDebugWindow *overlay = manager.pickerWindow;
    overlay.hidden = YES;
    UIWindow *targetWindow = NeoWCMainWindow();
    CGPoint targetPoint = [targetWindow convertPoint:point fromWindow:overlay];
    UIView *view = [targetWindow hitTest:targetPoint withEvent:nil];
    [manager finishPickingView:view];
}

@end

@implementation NeoWCDebugDashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"调试中心";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(closeTapped)];
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:self.closeHandler];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 3 : 3; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return section == 0 ? @"工具" : @"环境"; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DebugCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"DebugCell"];
    cell.imageView.image = nil;
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    if (indexPath.section == 0) {
        NSArray *titles = @[@"视图选择器", @"Runtime 类搜索", @"NeoWC 日志"];
        NSArray *symbols = @[@"viewfinder", @"magnifyingglass", @"doc.text"];
        cell.textLabel.text = titles[indexPath.row];
        cell.imageView.image = [UIImage systemImageNamed:symbols[indexPath.row]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (indexPath.row == 0) { cell.textLabel.text = @"系统"; cell.detailTextLabel.text = UIDevice.currentDevice.systemVersion; }
        if (indexPath.row == 1) { cell.textLabel.text = @"应用"; cell.detailTextLabel.text = NSBundle.mainBundle.bundleIdentifier; }
        if (indexPath.row == 2) { cell.textLabel.text = @"架构"; cell.detailTextLabel.text = @"arm64 / arm64e"; }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 0) return;
    if (indexPath.row == 0) {
        [self dismissViewControllerAnimated:YES completion:^{ [[NeoWCDebugManager sharedManager] beginViewPicking]; }];
    } else if (indexPath.row == 1) {
        [self.navigationController pushViewController:[[NeoWCRuntimeSearchViewController alloc] initWithStyle:UITableViewStylePlain] animated:YES];
    } else {
        [self.navigationController pushViewController:[[NeoWCLogViewController alloc] initWithStyle:UITableViewStylePlain] animated:YES];
    }
}

@end

@interface NeoWCObjectInspectorViewController ()
@property (nonatomic, strong) id inspectedObject;
@property (nonatomic, assign) Class inspectedClass;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation NeoWCObjectInspectorViewController

- (instancetype)initWithObject:(id)object inspectedClass:(Class)inspectedClass {
    self = [super init];
    if (self) {
        _inspectedObject = object;
        _inspectedClass = inspectedClass;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSStringFromClass(self.inspectedClass);
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(closeTapped)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"复制 Hook" style:UIBarButtonItemStylePlain target:self action:@selector(copyHook)];

    UITextView *textView = [UITextView new];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.editable = NO;
    textView.alwaysBounceVertical = YES;
    textView.font = [UIFont monospacedSystemFontOfSize:12.0 weight:UIFontWeightRegular];
    textView.textContainerInset = UIEdgeInsetsMake(16.0, 14.0, 24.0, 14.0);
    [self.view addSubview:textView];
    [NSLayoutConstraint activateConstraints:@[
        [textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [textView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    self.textView = textView;
    textView.text = [self inspectionReport];
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:^{
        [[NeoWCDebugManager sharedManager] applySavedState];
    }];
}

- (void)copyHook {
    NSString *className = NSStringFromClass(self.inspectedClass);
    NSString *template = [NSString stringWithFormat:@"%%hook %@\n\n// 在这里添加需要追踪的方法\n\n%%end", className];
    UIPasteboard.generalPasteboard.string = template;
    NeoWCLog(@"已复制 %@ 的 Hook 骨架", className);
    self.navigationItem.prompt = @"Hook 骨架已复制";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ self.navigationItem.prompt = nil; });
}

- (NSString *)inspectionReport {
    NSMutableString *report = [NSMutableString string];
    [report appendFormat:@"CLASS\n%@\n\nADDRESS\n%p\n\n", NSStringFromClass(self.inspectedClass), self.inspectedObject];

    if ([self.inspectedObject isKindOfClass:[UIView class]]) {
        UIView *view = self.inspectedObject;
        UIViewController *controller = NeoWCViewControllerForView(view);
        [report appendFormat:@"VIEW\nframe: %@\nbounds: %@\nalpha: %.3f\nhidden: %@\nwindow: %@\ncontroller: %@\n\n",
         NSStringFromCGRect(view.frame), NSStringFromCGRect(view.bounds), view.alpha, view.hidden ? @"YES" : @"NO",
         NSStringFromClass(view.window.class), NSStringFromClass(controller.class)];
        [report appendString:@"SUPER VIEWS\n"];
        UIView *parent = view;
        NSInteger depth = 0;
        while (parent && depth < 20) {
            [report appendFormat:@"%02ld  %@  %@\n", (long)depth, NSStringFromClass(parent.class), NSStringFromCGRect(parent.frame)];
            parent = parent.superview;
            depth++;
        }
        [report appendString:@"\n"];
    }

    [report appendString:@"CLASS HIERARCHY\n"];
    for (Class cls = self.inspectedClass; cls; cls = class_getSuperclass(cls)) {
        [report appendFormat:@"%@\n", NSStringFromClass(cls)];
    }

    [report appendString:@"\nIVARS\n"];
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(self.inspectedClass, &ivarCount);
    for (unsigned int index = 0; index < ivarCount; index++) {
        [report appendFormat:@"%s  %s\n", ivar_getTypeEncoding(ivars[index]) ?: "?", ivar_getName(ivars[index]) ?: "?"];
    }
    free(ivars);

    [report appendString:@"\nPROPERTIES\n"];
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(self.inspectedClass, &propertyCount);
    for (unsigned int index = 0; index < propertyCount; index++) {
        [report appendFormat:@"%s\n", property_getName(properties[index]) ?: "?"];
    }
    free(properties);

    [report appendString:@"\nMETHODS\n"];
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(self.inspectedClass, &methodCount);
    unsigned int visibleCount = MIN(methodCount, 250);
    for (unsigned int index = 0; index < visibleCount; index++) {
        [report appendFormat:@"- %@\n", NSStringFromSelector(method_getName(methods[index]))];
    }
    if (methodCount > visibleCount) [report appendFormat:@"… 其余 %u 个方法未显示\n", methodCount - visibleCount];
    free(methods);
    return report;
}

@end

@interface NeoWCRuntimeSearchViewController ()
@property (nonatomic, copy) NSArray<NSString *> *allClassNames;
@property (nonatomic, copy) NSArray<NSString *> *results;
@property (nonatomic, strong) UISearchController *searchController;
@end

@implementation NeoWCRuntimeSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Runtime 类搜索";
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    int classCount = objc_getClassList(NULL, 0);
    Class *classes = classCount > 0 ? (__unsafe_unretained Class *)malloc(sizeof(Class) * (NSUInteger)classCount) : NULL;
    classCount = classes ? objc_getClassList(classes, classCount) : 0;
    NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:(NSUInteger)classCount];
    for (int index = 0; index < classCount; index++) {
        NSString *name = NSStringFromClass(classes[index]);
        if (name.length > 0) [names addObject:name];
    }
    free(classes);
    self.allClassNames = [names sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    self.results = @[];

    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.searchBar.placeholder = @"输入微信类名";
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.searchController = searchController;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *query = [searchController.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (query.length == 0) {
        self.results = @[];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSString *name, __unused NSDictionary *bindings) {
            return [name rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound;
        }];
        NSArray *matches = [self.allClassNames filteredArrayUsingPredicate:predicate];
        self.results = matches.count > 300 ? [matches subarrayWithRange:NSMakeRange(0, 300)] : matches;
    }
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.results.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ClassCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ClassCell"];
    NSString *name = self.results[indexPath.row];
    Class cls = NSClassFromString(name);
    cell.textLabel.text = name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"super: %@", NSStringFromClass(class_getSuperclass(cls)) ?: @"-"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Class cls = NSClassFromString(self.results[indexPath.row]);
    NeoWCObjectInspectorViewController *inspector = [[NeoWCObjectInspectorViewController alloc] initWithObject:nil inspectedClass:cls];
    [self.navigationController pushViewController:inspector animated:YES];
}

@end

@interface NeoWCLogViewController ()
@property (nonatomic, copy) NSArray<NSString *> *entries;
@end

@implementation NeoWCLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"NeoWC 日志";
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithTitle:@"复制" style:UIBarButtonItemStylePlain target:self action:@selector(copyLogs)],
        [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clearLogs)],
    ];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadLogs) name:NeoWCDebugLogDidChangeNotification object:nil];
    [self reloadLogs];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)reloadLogs { self.entries = [[NeoWCDebugLogStore sharedStore] snapshot]; [self.tableView reloadData]; }
- (void)copyLogs { UIPasteboard.generalPasteboard.string = [self.entries componentsJoinedByString:@"\n"]; }
- (void)clearLogs { [[NeoWCDebugLogStore sharedStore] clear]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return MAX(self.entries.count, 1); }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LogCell"];
    cell.textLabel.font = [UIFont monospacedSystemFontOfSize:11.0 weight:UIFontWeightRegular];
    cell.textLabel.numberOfLines = 0;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = self.entries.count == 0 ? [UIColor secondaryLabelColor] : [UIColor labelColor];
    cell.textLabel.text = self.entries.count == 0 ? @"暂无 NeoWC 日志" : self.entries[indexPath.row];
    return cell;
}

@end
