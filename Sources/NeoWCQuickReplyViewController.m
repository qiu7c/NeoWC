#import "NeoWCQuickReplyViewController.h"
#import "NeoWCQuickReplyStore.h"
#import "NeoWCEnhancements.h"
#import "NeoWCRuntimeFeatures.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface NeoWCQuickReplyTextEditorViewController : UIViewController
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UITextField *categoryField;
@property (nonatomic, copy) void (^saveHandler)(NSString *title, NSString *text, NSString *category);
- (instancetype)initWithItem:(nullable NeoWCQuickReplyItem *)item;
@end

@implementation NeoWCQuickReplyTextEditorViewController

- (instancetype)initWithItem:(NeoWCQuickReplyItem *)item {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _titleField = [UITextField new];
        _titleField.text = item.title;
        _textView = [UITextView new];
        _textView.text = item.text;
        _categoryField = [UITextField new];
        _categoryField.text = item.category;
        self.title = item ? @"编辑文字素材" : @"新建文字素材";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(save)];
    self.titleField.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleField.placeholder = @"标题（可选）";
    self.titleField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.titleField.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    self.titleField.layer.cornerRadius = 10.0;
    self.titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
    UIView *padding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
    self.titleField.leftView = padding;
    self.titleField.leftViewMode = UITextFieldViewModeAlways;

    self.categoryField.translatesAutoresizingMaskIntoConstraints = NO;
    self.categoryField.placeholder = @"分类（可选）";
    self.categoryField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.categoryField.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    self.categoryField.layer.cornerRadius = 10.0;
    UIView *categoryPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
    self.categoryField.leftView = categoryPadding;
    self.categoryField.leftViewMode = UITextFieldViewModeAlways;
    self.categoryField.userInteractionEnabled = NO;
    UIButton *categoryButton = [UIButton buttonWithType:UIButtonTypeSystem];
    categoryButton.translatesAutoresizingMaskIntoConstraints = NO;
    categoryButton.accessibilityLabel = @"选择分类";
    [categoryButton addTarget:self action:@selector(chooseCategory) forControlEvents:UIControlEventTouchUpInside];

    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.textView.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    self.textView.layer.cornerRadius = 10.0;
    self.textView.textContainerInset = UIEdgeInsetsMake(14, 10, 14, 10);
    self.textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

    UILabel *hint = [UILabel new];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.text = @"文字内容";
    hint.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    hint.textColor = UIColor.secondaryLabelColor;

    [self.view addSubview:self.titleField];
    [self.view addSubview:self.categoryField];
    [self.view addSubview:categoryButton];
    [self.view addSubview:hint];
    [self.view addSubview:self.textView];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleField.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.titleField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.titleField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.titleField.heightAnchor constraintEqualToConstant:48],
        [self.categoryField.topAnchor constraintEqualToAnchor:self.titleField.bottomAnchor constant:10],
        [self.categoryField.leadingAnchor constraintEqualToAnchor:self.titleField.leadingAnchor],
        [self.categoryField.trailingAnchor constraintEqualToAnchor:self.titleField.trailingAnchor],
        [self.categoryField.heightAnchor constraintEqualToConstant:48],
        [categoryButton.topAnchor constraintEqualToAnchor:self.categoryField.topAnchor],
        [categoryButton.bottomAnchor constraintEqualToAnchor:self.categoryField.bottomAnchor],
        [categoryButton.leadingAnchor constraintEqualToAnchor:self.categoryField.leadingAnchor],
        [categoryButton.trailingAnchor constraintEqualToAnchor:self.categoryField.trailingAnchor],
        [hint.topAnchor constraintEqualToAnchor:self.categoryField.bottomAnchor constant:18],
        [hint.leadingAnchor constraintEqualToAnchor:self.titleField.leadingAnchor constant:2],
        [self.textView.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:7],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.titleField.leadingAnchor],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.titleField.trailingAnchor],
        [self.textView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
    ]];
    if (self.textView.text.length == 0) [self.textView becomeFirstResponder];
}

- (void)chooseCategory {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择分类" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"未分类" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        self.categoryField.text = @"";
    }]];
    for (NSString *category in NeoWCQuickReplyStore.sharedStore.categories) {
        [sheet addAction:[UIAlertAction actionWithTitle:category style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            self.categoryField.text = category;
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"新建分类" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self createCategory];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) { popover.sourceView = self.categoryField; popover.sourceRect = self.categoryField.bounds; }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)createCategory {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建分类" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"分类名称"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"创建" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *name = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        NSError *error = nil;
        if ([NeoWCQuickReplyStore.sharedStore addCategory:name error:&error]) self.categoryField.text = name;
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)save {
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (text.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"无法保存"
                                                                       message:@"文字内容不能为空。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if (self.saveHandler) self.saveHandler(self.titleField.text ?: @"", text, self.categoryField.text ?: @"");
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@interface NeoWCQuickReplyPlayerView : UIView
@property (nonatomic, strong, nullable) AVPlayer *player;
@end

@implementation NeoWCQuickReplyPlayerView

+ (Class)layerClass {
    return AVPlayerLayer.class;
}

- (AVPlayer *)player {
    return ((AVPlayerLayer *)self.layer).player;
}

- (void)setPlayer:(AVPlayer *)player {
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.layer;
    playerLayer.player = player;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
}

@end

@interface NeoWCQuickReplyMediaPreviewViewController : UIViewController
@property (nonatomic, strong) NeoWCQuickReplyItem *item;
@property (nonatomic, copy) dispatch_block_t sendHandler;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
- (instancetype)initWithItem:(NeoWCQuickReplyItem *)item;
@end

@implementation NeoWCQuickReplyMediaPreviewViewController

- (instancetype)initWithItem:(NeoWCQuickReplyItem *)item {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _item = item;
        self.title = item.type == NeoWCQuickReplyTypeImage ? @"确认图片素材" :
                     (item.type == NeoWCQuickReplyTypeVideo ? @"确认视频素材" : @"确认语音素材");
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(sendTapped)];
    NSString *path = [NeoWCQuickReplyStore.sharedStore absoluteMediaPathForItem:self.item];
    if (self.item.type == NeoWCQuickReplyTypeVoice) {
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path ?: @""] error:nil];
        UIImageView *waveform = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"waveform.circle.fill"]];
        waveform.translatesAutoresizingMaskIntoConstraints = NO;
        waveform.tintColor = UIColor.whiteColor;
        waveform.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:waveform];
        [NSLayoutConstraint activateConstraints:@[
            [waveform.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [waveform.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
            [waveform.widthAnchor constraintEqualToConstant:112.0],
            [waveform.heightAnchor constraintEqualToConstant:112.0],
        ]];
        [self.audioPlayer play];
    } else if (self.item.type == NeoWCQuickReplyTypeVideo) {
        self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:path ?: @""]];
        NeoWCQuickReplyPlayerView *playerView = [NeoWCQuickReplyPlayerView new];
        playerView.translatesAutoresizingMaskIntoConstraints = NO;
        playerView.player = self.player;
        [self.view addSubview:playerView];
        [NSLayoutConstraint activateConstraints:@[
            [playerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [playerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
            [playerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [playerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        ]];
        [self.player play];
    } else {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:imageView];
        [NSLayoutConstraint activateConstraints:@[
            [imageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [imageView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
            [imageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [imageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        ]];
    }
}

- (void)sendTapped {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (self.sendHandler) self.sendHandler();
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
    [self.audioPlayer stop];
}

@end

@interface NeoWCQuickReplyViewController () <UISearchResultsUpdating, UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, copy, nullable) NeoWCQuickReplySelectionHandler selectionHandler;
@property (nonatomic, copy, nullable) NeoWCQuickReplyDirectSendHandler directSendHandler;
@property (nonatomic, copy) NSArray<NeoWCQuickReplyItem *> *allItems;
@property (nonatomic, copy) NSArray<NeoWCQuickReplyItem *> *visibleItems;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, copy) NSArray<NSString *> *categories;
@property (nonatomic, copy) NSString *selectedCategory;
@end

@implementation NeoWCQuickReplyViewController

- (instancetype)initWithSelectionHandler:(NeoWCQuickReplySelectionHandler)selectionHandler {
    return [self initWithSelectionHandler:selectionHandler directSendHandler:nil];
}

- (instancetype)initWithSelectionHandler:(NeoWCQuickReplySelectionHandler)selectionHandler
                        directSendHandler:(NeoWCQuickReplyDirectSendHandler)directSendHandler {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _selectionHandler = [selectionHandler copy];
        _directSendHandler = [directSendHandler copy];
        _selectedCategory = @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"快捷回复素材库";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.rowHeight = 68.0;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                         target:self
                                                                         action:@selector(addTapped)];
    self.navigationItem.rightBarButtonItem = add;
    if (!self.selectionHandler) {
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
        UIBarButtonItem *cleanup = [[UIBarButtonItem alloc] initWithTitle:@"清理" style:UIBarButtonItemStylePlain
                                                                   target:self action:@selector(cleanupMediaTapped)];
        self.navigationItem.rightBarButtonItems = @[add, cleanup];
    }
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = @"搜索标题或文字";
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
    if (self.directSendHandler) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(itemLongPressed:)];
        longPress.minimumPressDuration = 0.55;
        [self.tableView addGestureRecognizer:longPress];
    }
    if (self.selectionHandler && self.navigationController.presentingViewController) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                                                              target:self
                                                                                              action:@selector(close)];
    }
    [self reloadItems];
}

- (void)itemLongPressed:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan || !self.directSendHandler) return;
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[recognizer locationInView:self.tableView]];
    if (!indexPath || indexPath.row >= (NSInteger)self.visibleItems.count) return;
    NeoWCQuickReplyItem *item = self.visibleItems[indexPath.row];
    if (NeoWCEnhancementEnabled(NeoWCQuickReplyInstantSendEnabledKey)) [self useItemNormally:item];
    else [self sendItemDirectly:item];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.selectionHandler) return;
    NSString *account = NeoWCQuickReplyStore.sharedStore.accountIdentifier;
    if (account.length == 0) return;
    NSString *key = [@"com.qiu7c.neowc.quick-reply.import-tip." stringByAppendingString:account];
    if ([NSUserDefaults.standardUserDefaults boolForKey:key]) return;
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:key];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"从文件传输助手加入素材"
                                                                   message:@"长按单条文字、图片、视频文件或语音可加入；也可进入微信多选后批量加入。媒体需先下载到本机。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"前往文件传输助手" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NeoWCOpenChatForUserName(@"filehelper");
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)reloadItems {
    self.allItems = NeoWCQuickReplyStore.sharedStore.items;
    self.categories = NeoWCQuickReplyStore.sharedStore.categories;
    NSMutableArray<NSString *> *scopes = [NSMutableArray arrayWithObject:@"全部"];
    [scopes addObjectsFromArray:self.categories];
    self.searchController.searchBar.scopeButtonTitles = scopes;
    self.searchController.searchBar.showsScopeBar = self.categories.count > 0;
    NSUInteger selectedIndex = self.selectedCategory.length > 0 ? [self.categories indexOfObject:self.selectedCategory] : NSNotFound;
    self.searchController.searchBar.selectedScopeButtonIndex = selectedIndex == NSNotFound ? 0 : selectedIndex + 1;
    if (selectedIndex == NSNotFound) self.selectedCategory = @"";
    [self applySearchText:self.searchController.searchBar.text];
}

- (void)applySearchText:(NSString *)query {
    NSString *trimmed = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    self.visibleItems = [self.allItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NeoWCQuickReplyItem *item, NSDictionary *bindings) {
            (void)bindings;
            BOOL categoryMatches = self.selectedCategory.length == 0 || [item.category isEqualToString:self.selectedCategory];
            BOOL textMatches = trimmed.length == 0 || [item.title localizedCaseInsensitiveContainsString:trimmed] ||
                               [item.text localizedCaseInsensitiveContainsString:trimmed];
            return categoryMatches && textMatches;
    }]];
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    self.selectedCategory = selectedScope > 0 && selectedScope - 1 < (NSInteger)self.categories.count
        ? self.categories[selectedScope - 1] : @"";
    [self applySearchText:searchBar.text];
}

- (void)cleanupMediaTapped {
    NSUInteger mediaCount = 0;
    for (NeoWCQuickReplyItem *item in self.allItems) if (item.type != NeoWCQuickReplyTypeText) mediaCount++;
    if (mediaCount == 0) {
        [self showError:[NSError errorWithDomain:@"NeoWC" code:3 userInfo:@{NSLocalizedDescriptionKey: @"素材库中没有媒体素材。"}]];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"清理全部媒体素材？"
                                                                   message:[NSString stringWithFormat:@"将删除 NeoWC 管理的 %lu 个图片、视频或语音副本；文字素材、聊天消息和系统相册不受影响。", (unsigned long)mediaCount]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"清理" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        NSError *lastError = nil;
        for (NeoWCQuickReplyItem *item in weakSelf.allItems) {
            if (item.type != NeoWCQuickReplyTypeText) {
                NSError *error = nil;
                [NeoWCQuickReplyStore.sharedStore deleteItemWithIdentifier:item.identifier error:&error];
                if (error) lastError = error;
            }
        }
        [weakSelf reloadItems];
        if (lastError) [weakSelf showError:lastError];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)editMediaItem:(NeoWCQuickReplyItem *)item {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"编辑媒体素材" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"修改标题" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改标题" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"标题（可选）"; field.text = item.title; }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *saveAction) {
            item.title = alert.textFields.firstObject.text ?: @"";
            NSError *error = nil;
            [NeoWCQuickReplyStore.sharedStore updateItem:item error:&error];
            if (error) [self showError:error];
            [self reloadItems];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"选择分类" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self chooseCategoryForItem:item];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) { popover.sourceView = self.view; popover.sourceRect = self.view.bounds; }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)chooseCategoryForItem:(NeoWCQuickReplyItem *)item {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择分类" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSMutableArray<NSString *> *options = [NSMutableArray arrayWithObject:@""];
    [options addObjectsFromArray:NeoWCQuickReplyStore.sharedStore.categories];
    for (NSString *category in options) {
        NSString *title = category.length > 0 ? category : @"未分类";
        if ([item.category isEqualToString:category]) title = [title stringByAppendingString:@" ✓"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            item.category = category;
            NSError *error = nil;
            [NeoWCQuickReplyStore.sharedStore updateItem:item error:&error];
            if (error) [self showError:error];
            [self reloadItems];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"新建分类" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建分类" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"分类名称"; }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"创建并选择" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *saveAction) {
            NSString *name = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            NSError *error = nil;
            if ([NeoWCQuickReplyStore.sharedStore addCategory:name error:&error]) {
                item.category = name;
                [NeoWCQuickReplyStore.sharedStore updateItem:item error:&error];
            }
            if (error) [self showError:error];
            [self reloadItems];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) { popover.sourceView = self.view; popover.sourceRect = self.view.bounds; }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self applySearchText:searchController.searchBar.text];
}

- (void)addTapped {
    if (!NeoWCQuickReplyStore.sharedStore.isAvailable) {
        [self showError:[NSError errorWithDomain:@"NeoWC" code:1 userInfo:@{NSLocalizedDescriptionKey: @"尚未识别当前微信账号，无法创建素材。"}]];
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"添加素材" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"新建文字" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self presentTextEditorForItem:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"从相册选择图片或视频" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self presentMediaPicker];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"前往文件传输助手" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NeoWCOpenChatForUserName(@"filehelper");
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"管理分类" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self manageCategories];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    popover.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)manageCategories {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"管理分类" message:@"选择分类可重命名或删除" preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *category in NeoWCQuickReplyStore.sharedStore.categories) {
        [sheet addAction:[UIAlertAction actionWithTitle:category style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self editCategory:category];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"新建分类" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self createManagedCategory];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) { popover.sourceView = self.view; popover.sourceRect = self.view.bounds; }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)createManagedCategory {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建分类" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"分类名称"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"创建" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSError *error = nil;
        [NeoWCQuickReplyStore.sharedStore addCategory:alert.textFields.firstObject.text error:&error];
        if (error) [weakSelf showError:error];
        [weakSelf reloadItems];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)editCategory:(NSString *)category {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:category message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"重命名" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名分类" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.text = category; }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *saveAction) {
            NSError *error = nil;
            [NeoWCQuickReplyStore.sharedStore renameCategory:category toName:alert.textFields.firstObject.text error:&error];
            if (error) [self showError:error];
            [self reloadItems];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"删除分类" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        NSError *error = nil;
        [NeoWCQuickReplyStore.sharedStore deleteCategory:category error:&error];
        if (error) [self showError:error];
        [self reloadItems];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) { popover.sourceView = self.view; popover.sourceRect = self.view.bounds; }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentTextEditorForItem:(NeoWCQuickReplyItem *)item {
    NeoWCQuickReplyTextEditorViewController *editor = [[NeoWCQuickReplyTextEditorViewController alloc] initWithItem:item];
    __weak typeof(self) weakSelf = self;
    __weak NeoWCQuickReplyItem *weakItem = item;
    editor.saveHandler = ^(NSString *title, NSString *text, NSString *category) {
        NSError *error = nil;
        NeoWCQuickReplyItem *strongItem = weakItem;
        if (strongItem) {
            strongItem.title = title;
            strongItem.text = text;
            strongItem.category = category;
            [NeoWCQuickReplyStore.sharedStore updateItem:strongItem error:&error];
        } else {
            [NeoWCQuickReplyStore.sharedStore addText:text title:title category:category sourceConversation:nil sourceMessageID:nil error:&error];
        }
        if (error) [weakSelf showError:error];
        [weakSelf reloadItems];
    };
    [self.navigationController pushViewController:editor animated:YES];
}

- (void)presentMediaPicker {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) return;
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[@"public.image", @"public.movie"];
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    NSURL *URL = info[UIImagePickerControllerMediaURL];
    NeoWCQuickReplyType type = [mediaType isEqualToString:@"public.movie"] ? NeoWCQuickReplyTypeVideo : NeoWCQuickReplyTypeImage;
    NSString *temporaryImagePath = nil;
    if (type == NeoWCQuickReplyTypeImage) {
        URL = info[UIImagePickerControllerImageURL];
        if (!URL) {
            UIImage *image = info[UIImagePickerControllerOriginalImage];
            NSData *data = image ? UIImageJPEGRepresentation(image, 0.96) : nil;
            temporaryImagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"jpg"]];
            if (data.length > 0 && [data writeToFile:temporaryImagePath options:NSDataWritingAtomic error:nil]) {
                URL = [NSURL fileURLWithPath:temporaryImagePath];
            }
        }
    }
    NSError *error = nil;
    if (URL) {
        [NeoWCQuickReplyStore.sharedStore addMediaAtURL:URL type:type title:nil sourceConversation:nil sourceMessageID:nil error:&error];
    } else {
        error = [NSError errorWithDomain:@"NeoWC" code:2 userInfo:@{NSLocalizedDescriptionKey: @"无法读取所选媒体文件。"}];
    }
    if (temporaryImagePath.length > 0) [NSFileManager.defaultManager removeItemAtPath:temporaryImagePath error:nil];
    __weak typeof(self) weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        if (error) [weakSelf showError:error];
        [weakSelf reloadItems];
    }];
}

- (void)showError:(NSError *)error {
    if (!self.view.window) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"操作失败"
                                                                   message:error.localizedDescription ?: @"请稍后重试"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.visibleItems.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    if (!NeoWCQuickReplyStore.sharedStore.isAvailable) return @"当前微信账号尚未识别，素材库已暂停读写。";
    NSByteCountFormatter *formatter = [NSByteCountFormatter new];
    formatter.countStyle = NSByteCountFormatterCountStyleFile;
    NSString *size = [formatter stringFromByteCount:(long long)NeoWCQuickReplyStore.sharedStore.managedMediaSize];
    return [NSString stringWithFormat:@"当前账号共 %lu 项，媒体占用 %@。素材文件独立保存，不依赖聊天缓存。", (unsigned long)self.allItems.count, size];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"QuickReplyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    NeoWCQuickReplyItem *item = self.visibleItems[indexPath.row];
    NSString *fallbackTitle = item.type == NeoWCQuickReplyTypeText ? item.text :
        (item.type == NeoWCQuickReplyTypeImage ? @"图片素材" : (item.type == NeoWCQuickReplyTypeVideo ? @"视频素材" : @"语音素材"));
    cell.textLabel.text = item.title.length > 0 ? item.title : fallbackTitle;
    cell.textLabel.numberOfLines = 1;
    NSString *typeName = item.type == NeoWCQuickReplyTypeText ? @"文字" :
        (item.type == NeoWCQuickReplyTypeImage ? @"图片" : (item.type == NeoWCQuickReplyTypeVideo ? @"视频" : @"语音"));
    NSMutableArray<NSString *> *details = [NSMutableArray arrayWithObject:typeName];
    if (item.category.length > 0) [details addObject:item.category];
    if (item.isPinned) [details addObject:@"已置顶"];
    cell.detailTextLabel.text = [details componentsJoinedByString:@" · "];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSString *thumbnailPath = [NeoWCQuickReplyStore.sharedStore absoluteThumbnailPathForItem:item];
    UIImage *image = thumbnailPath.length > 0 ? [UIImage imageWithContentsOfFile:thumbnailPath] : nil;
    if (!image) {
        NSString *symbol = item.type == NeoWCQuickReplyTypeText ? @"text.bubble" :
            (item.type == NeoWCQuickReplyTypeImage ? @"photo" : (item.type == NeoWCQuickReplyTypeVideo ? @"video" : @"waveform"));
        image = [UIImage systemImageNamed:symbol];
    }
    cell.imageView.image = image;
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.imageView.clipsToBounds = YES;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView; (void)indexPath;
    return !self.selectionHandler && self.searchController.searchBar.text.length == 0 && self.selectedCategory.length == 0;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    (void)tableView;
    NSMutableArray *ordered = [self.allItems mutableCopy];
    NeoWCQuickReplyItem *item = ordered[sourceIndexPath.row];
    [ordered removeObjectAtIndex:sourceIndexPath.row];
    [ordered insertObject:item atIndex:destinationIndexPath.row];
    NSMutableArray<NSString *> *identifiers = [NSMutableArray arrayWithCapacity:ordered.count];
    for (NeoWCQuickReplyItem *candidate in ordered) [identifiers addObject:candidate.identifier];
    NSError *error = nil;
    [NeoWCQuickReplyStore.sharedStore applyOrderedIdentifiers:identifiers error:&error];
    if (error) [self showError:error];
    [self reloadItems];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NeoWCQuickReplyItem *item = self.visibleItems[indexPath.row];
    if (self.selectionHandler) {
        if (NeoWCEnhancementEnabled(NeoWCQuickReplyInstantSendEnabledKey)) [self sendItemDirectly:item];
        else [self useItemNormally:item];
        return;
    }
    if (item.type == NeoWCQuickReplyTypeText) {
        [self presentTextEditorForItem:item];
        return;
    }
    NSString *path = [NeoWCQuickReplyStore.sharedStore absoluteMediaPathForItem:item];
    if ((item.type == NeoWCQuickReplyTypeVideo || item.type == NeoWCQuickReplyTypeVoice) && path.length > 0) {
        AVPlayerViewController *player = [AVPlayerViewController new];
        player.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:path]];
        [self presentViewController:player animated:YES completion:^{ [player.player play]; }];
        return;
    }
    UIImage *image = path.length > 0 ? [UIImage imageWithContentsOfFile:path] : nil;
    if (!image) return;
    UIViewController *preview = [UIViewController new];
    preview.view.backgroundColor = UIColor.blackColor;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [preview.view addSubview:imageView];
    [NSLayoutConstraint activateConstraints:@[
        [imageView.topAnchor constraintEqualToAnchor:preview.view.topAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:preview.view.bottomAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:preview.view.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:preview.view.trailingAnchor],
    ]];
    [self presentViewController:preview animated:YES completion:nil];
}

- (void)useItemNormally:(NeoWCQuickReplyItem *)item {
    if (!self.selectionHandler) return;
    if (item.type == NeoWCQuickReplyTypeText) {
        NeoWCQuickReplySelectionHandler handler = self.selectionHandler;
        [self dismissViewControllerAnimated:YES completion:^{ if (handler) handler(item); }];
        return;
    }
    NeoWCQuickReplyMediaPreviewViewController *preview = [[NeoWCQuickReplyMediaPreviewViewController alloc] initWithItem:item];
    __weak typeof(self) weakSelf = self;
    preview.sendHandler = ^{
        NeoWCQuickReplyViewController *strongSelf = weakSelf;
        if (!strongSelf) return;
        NeoWCQuickReplySelectionHandler handler = strongSelf.selectionHandler;
        [strongSelf dismissViewControllerAnimated:YES completion:^{ if (handler) handler(item); }];
    };
    [self.navigationController pushViewController:preview animated:YES];
}

- (void)sendItemDirectly:(NeoWCQuickReplyItem *)item {
    if (!self.directSendHandler) return;
    NeoWCQuickReplyDirectSendHandler handler = self.directSendHandler;
    [self dismissViewControllerAnimated:YES completion:^{ handler(item); }];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NeoWCQuickReplyItem *item = self.visibleItems[indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                                title:@"删除"
                                                                              handler:^(__unused UIContextualAction *action, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
        NSError *error = nil;
        BOOL deleted = [NeoWCQuickReplyStore.sharedStore deleteItemWithIdentifier:item.identifier error:&error];
        if (error) [weakSelf showError:error];
        [weakSelf reloadItems];
        completionHandler(deleted);
    }];
    UIContextualAction *pinAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                             title:item.isPinned ? @"取消置顶" : @"置顶"
                                                                           handler:^(__unused UIContextualAction *action, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
        NSError *error = nil;
        BOOL changed = [NeoWCQuickReplyStore.sharedStore setPinned:!item.isPinned forIdentifier:item.identifier error:&error];
        if (error) [weakSelf showError:error];
        [weakSelf reloadItems];
        completionHandler(changed);
    }];
    pinAction.backgroundColor = UIColor.systemOrangeColor;
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, pinAction]];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (self.selectionHandler) return nil;
    NeoWCQuickReplyItem *item = self.visibleItems[indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIContextualAction *edit = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                        title:@"编辑"
                                                                      handler:^(__unused UIContextualAction *action, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
        if (item.type == NeoWCQuickReplyTypeText) [weakSelf presentTextEditorForItem:item];
        else [weakSelf editMediaItem:item];
        completionHandler(YES);
    }];
    edit.backgroundColor = UIColor.systemBlueColor;
    return [UISwipeActionsConfiguration configurationWithActions:@[edit]];
}

@end
