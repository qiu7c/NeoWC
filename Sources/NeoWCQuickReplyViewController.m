#import "NeoWCQuickReplyViewController.h"
#import "NeoWCQuickReplyStore.h"
#import "NeoWCSilkDecoder.h"
#import "NeoWCEnhancements.h"
#import "NeoWCRuntimeFeatures.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface NeoWCQuickReplyTextEditorViewController : UIViewController
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, copy) void (^saveHandler)(NSString *title, NSString *text);
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
    self.titleField.placeholder = @"备注（可选）";
    self.titleField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.titleField.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    self.titleField.layer.cornerRadius = 10.0;
    self.titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
    UIView *padding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
    self.titleField.leftView = padding;
    self.titleField.leftViewMode = UITextFieldViewModeAlways;

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
    [self.view addSubview:hint];
    [self.view addSubview:self.textView];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleField.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.titleField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.titleField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.titleField.heightAnchor constraintEqualToConstant:48],
        [hint.topAnchor constraintEqualToAnchor:self.titleField.bottomAnchor constant:18],
        [hint.leadingAnchor constraintEqualToAnchor:self.titleField.leadingAnchor constant:2],
        [self.textView.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:7],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.titleField.leadingAnchor],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.titleField.trailingAnchor],
        [self.textView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
    ]];
    if (self.textView.text.length == 0) [self.textView becomeFirstResponder];
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
    if (self.saveHandler) self.saveHandler(self.titleField.text ?: @"", text);
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
@property (nonatomic, strong) UIButton *voicePlayButton;
@property (nonatomic, strong) UILabel *voiceStatusLabel;
@property (nonatomic, assign) BOOL showsSendButton;
@property (nonatomic, copy) NSString *voiceSourcePath;
@property (nonatomic, copy) NSString *voiceTemporaryWAVPath;
@property (nonatomic, assign) BOOL voiceDecodeInProgress;
@property (nonatomic, assign) NSUInteger voiceDecodeGeneration;
- (instancetype)initWithItem:(NeoWCQuickReplyItem *)item;
@end

@implementation NeoWCQuickReplyMediaPreviewViewController

- (instancetype)initWithItem:(NeoWCQuickReplyItem *)item {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _item = item;
        _showsSendButton = YES;
        self.title = item.type == NeoWCQuickReplyTypeImage ? @"确认图片素材" :
                     (item.type == NeoWCQuickReplyTypeVideo ? @"确认视频素材" : @"确认语音素材");
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    if (self.showsSendButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送"
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(sendTapped)];
    }
    NSString *path = [NeoWCQuickReplyStore.sharedStore absoluteMediaPathForItem:self.item];
    if (self.item.type == NeoWCQuickReplyTypeVoice) {
        self.voiceSourcePath = path;
        NSUInteger voiceTime = [self.item.metadata[@"voiceTime"] unsignedIntegerValue];
        NSUInteger voiceFormat = [self.item.metadata[@"voiceFormat"] unsignedIntegerValue];
        NSError *audioError = nil;
        if (voiceFormat != 4) {
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path ?: @""] error:&audioError];
        }
        UIImageView *waveform = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"waveform.circle.fill"]];
        waveform.translatesAutoresizingMaskIntoConstraints = NO;
        waveform.tintColor = UIColor.whiteColor;
        waveform.contentMode = UIViewContentModeScaleAspectFit;
        UIButton *playButton = [UIButton buttonWithType:UIButtonTypeSystem];
        playButton.translatesAutoresizingMaskIntoConstraints = NO;
        playButton.tintColor = UIColor.whiteColor;
        playButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        BOOL canDecodeSilk = voiceFormat == 4 && path.length > 0;
        [playButton setTitle:(self.audioPlayer || canDecodeSilk) ? @"播放" : @"暂不可预览" forState:UIControlStateNormal];
        playButton.enabled = self.audioPlayer != nil || canDecodeSilk;
        [playButton addTarget:self action:@selector(voicePlayTapped) forControlEvents:UIControlEventTouchUpInside];
        UILabel *statusLabel = [UILabel new];
        statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
        statusLabel.textAlignment = NSTextAlignmentCenter;
        statusLabel.numberOfLines = 0;
        statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        statusLabel.textColor = UIColor.lightGrayColor;
        if (self.audioPlayer) {
            statusLabel.text = voiceTime > 0 ? [NSString stringWithFormat:@"约 %.1f 秒", voiceTime / 1000.0] : @"轻点播放预览";
        } else if (voiceFormat == 4) {
            statusLabel.text = voiceTime > 0 ? [NSString stringWithFormat:@"约 %.1f 秒 · 首次播放将快速解码", voiceTime / 1000.0] : @"首次播放将快速解码";
        } else {
            statusLabel.text = audioError.localizedDescription ?: @"无法读取该语音文件。";
        }
        [self.view addSubview:waveform];
        [self.view addSubview:playButton];
        [self.view addSubview:statusLabel];
        self.voicePlayButton = playButton;
        self.voiceStatusLabel = statusLabel;
        [NSLayoutConstraint activateConstraints:@[
            [waveform.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [waveform.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-54.0],
            [waveform.widthAnchor constraintEqualToConstant:112.0],
            [waveform.heightAnchor constraintEqualToConstant:112.0],
            [playButton.topAnchor constraintEqualToAnchor:waveform.bottomAnchor constant:18.0],
            [playButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [statusLabel.topAnchor constraintEqualToAnchor:playButton.bottomAnchor constant:12.0],
            [statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:32.0],
            [statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-32.0],
        ]];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationDidEnterBackground:)
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];
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

- (void)voicePlayTapped {
    if (!self.audioPlayer) {
        if ([self.item.metadata[@"voiceFormat"] unsignedIntegerValue] == 4) [self decodeSilkVoiceAndPlay];
        return;
    }
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer pause];
        [self.voicePlayButton setTitle:@"继续播放" forState:UIControlStateNormal];
        self.voiceStatusLabel.text = @"已暂停";
    } else {
        if (self.audioPlayer.currentTime >= self.audioPlayer.duration) self.audioPlayer.currentTime = 0;
        if ([self.audioPlayer play]) {
            [self.voicePlayButton setTitle:@"暂停" forState:UIControlStateNormal];
            self.voiceStatusLabel.text = @"正在播放";
        } else {
            self.voicePlayButton.enabled = NO;
            [self.voicePlayButton setTitle:@"暂不可预览" forState:UIControlStateNormal];
            self.voiceStatusLabel.text = @"系统播放器无法播放该语音文件。";
        }
    }
}

- (void)decodeSilkVoiceAndPlay {
    if (self.voiceDecodeInProgress || self.voiceSourcePath.length == 0) return;
    self.voiceDecodeInProgress = YES;
    NSUInteger generation = ++self.voiceDecodeGeneration;
    self.voicePlayButton.enabled = NO;
    [self.voicePlayButton setTitle:@"正在准备…" forState:UIControlStateNormal];
    self.voiceStatusLabel.text = @"正在解码 Silk 语音";
    NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"NeoWCVoicePreviews"];
    NSError *directoryError = nil;
    if (![NSFileManager.defaultManager createDirectoryAtPath:directory
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&directoryError]) {
        self.voiceDecodeInProgress = NO;
        self.voicePlayButton.enabled = YES;
        [self.voicePlayButton setTitle:@"重试" forState:UIControlStateNormal];
        self.voiceStatusLabel.text = directoryError.localizedDescription ?: @"无法创建语音预览缓存";
        return;
    }
    NSString *destination = [directory stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"wav"]];
    NSString *source = self.voiceSourcePath;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *decodeError = nil;
        BOOL decoded = NeoWCSilkDecodeFileToWAV(source, destination, &decodeError);
        dispatch_async(dispatch_get_main_queue(), ^{
            NeoWCQuickReplyMediaPreviewViewController *strongSelf = weakSelf;
            if (!strongSelf || generation != strongSelf.voiceDecodeGeneration || !strongSelf.viewIfLoaded.window) {
                [NSFileManager.defaultManager removeItemAtPath:destination error:nil];
                return;
            }
            strongSelf.voiceDecodeInProgress = NO;
            if (!decoded) {
                strongSelf.voicePlayButton.enabled = YES;
                [strongSelf.voicePlayButton setTitle:@"重试" forState:UIControlStateNormal];
                strongSelf.voiceStatusLabel.text = decodeError.localizedDescription ?: @"Silk 语音解码失败";
                return;
            }
            NSError *audioError = nil;
            AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:destination]
                                                                           error:&audioError];
            if (!player) {
                [NSFileManager.defaultManager removeItemAtPath:destination error:nil];
                strongSelf.voicePlayButton.enabled = YES;
                [strongSelf.voicePlayButton setTitle:@"重试" forState:UIControlStateNormal];
                strongSelf.voiceStatusLabel.text = audioError.localizedDescription ?: @"无法播放解码后的语音";
                return;
            }
            strongSelf.voiceTemporaryWAVPath = destination;
            strongSelf.audioPlayer = player;
            [player prepareToPlay];
            strongSelf.voicePlayButton.enabled = YES;
            [strongSelf.voicePlayButton setTitle:@"播放" forState:UIControlStateNormal];
            strongSelf.voiceStatusLabel.text = @"准备完成";
            [strongSelf voicePlayTapped];
        });
    });
}

- (void)cleanupVoicePreview {
    self.voiceDecodeGeneration++;
    self.voiceDecodeInProgress = NO;
    [self.audioPlayer stop];
    if (self.voiceTemporaryWAVPath.length > 0) {
        [NSFileManager.defaultManager removeItemAtPath:self.voiceTemporaryWAVPath error:nil];
        self.voiceTemporaryWAVPath = nil;
        self.audioPlayer = nil;
    }
    if ([self.item.metadata[@"voiceFormat"] unsignedIntegerValue] == 4 && self.voicePlayButton) {
        self.voicePlayButton.enabled = self.voiceSourcePath.length > 0;
        [self.voicePlayButton setTitle:@"播放" forState:UIControlStateNormal];
        NSUInteger voiceTime = [self.item.metadata[@"voiceTime"] unsignedIntegerValue];
        self.voiceStatusLabel.text = voiceTime > 0
            ? [NSString stringWithFormat:@"约 %.1f 秒 · 首次播放将快速解码", voiceTime / 1000.0]
            : @"首次播放将快速解码";
    }
}

- (void)applicationDidEnterBackground:(__unused NSNotification *)notification {
    [self cleanupVoicePreview];
}

- (void)sendTapped {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (self.sendHandler) self.sendHandler();
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
    [self cleanupVoicePreview];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end

@interface NeoWCQuickReplyViewController () <UISearchResultsUpdating, UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, copy, nullable) NeoWCQuickReplySelectionHandler selectionHandler;
@property (nonatomic, copy, nullable) NeoWCQuickReplyDirectSendHandler directSendHandler;
@property (nonatomic, copy) NSArray<NeoWCQuickReplyItem *> *allItems;
@property (nonatomic, copy) NSArray<NeoWCQuickReplyItem *> *visibleItems;
@property (nonatomic, copy) NSArray<NeoWCQuickReplyFolder *> *folders;
@property (nonatomic, copy) NSArray<NeoWCQuickReplyFolder *> *visibleFolders;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, copy, nullable) NSString *currentFolderIdentifier;
@property (nonatomic, copy, nullable) NSString *currentFolderName;
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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.currentFolderName.length ? self.currentFolderName : @"快捷回复素材库";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.rowHeight = 56.0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 56.0, 0.0, 16.0);
    self.tableView.sectionHeaderHeight = 0.01;
    if (@available(iOS 15.0, *)) self.tableView.sectionHeaderTopPadding = 0.0;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                         target:self
                                                                         action:@selector(addTapped)];
    self.navigationItem.rightBarButtonItem = add;
    if (!self.selectionHandler) {
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
        if (!self.currentFolderIdentifier.length) {
            UIBarButtonItem *cleanup = [[UIBarButtonItem alloc] initWithTitle:@"清理" style:UIBarButtonItemStylePlain
                                                                       target:self action:@selector(cleanupMediaTapped)];
            self.navigationItem.rightBarButtonItems = @[add, cleanup];
        }
    }
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = @"搜索备注或文字";
    self.searchController.searchBar.backgroundImage = [UIImage new];
    self.searchController.searchBar.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.searchController.searchBar.barTintColor = UIColor.clearColor;
    self.searchController.searchBar.searchTextField.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    UIView *searchHeader = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 56.0)];
    searchHeader.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.searchController.searchBar.frame = searchHeader.bounds;
    self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [searchHeader addSubview:self.searchController.searchBar];
    self.tableView.tableHeaderView = searchHeader;
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
    if (!indexPath) return;
    NSInteger itemIndex = indexPath.row - (NSInteger)self.visibleFolders.count;
    if (itemIndex < 0 || itemIndex >= (NSInteger)self.visibleItems.count) return;
    NeoWCQuickReplyItem *item = self.visibleItems[itemIndex];
    if (NeoWCEnhancementEnabled(NeoWCQuickReplyInstantSendEnabledKey)) [self useItemNormally:item];
    else [self sendItemDirectly:item];
}

- (nullable NeoWCQuickReplyFolder *)folderAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row >= 0 && indexPath.row < (NSInteger)self.visibleFolders.count
        ? self.visibleFolders[indexPath.row] : nil;
}

- (nullable NeoWCQuickReplyItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.row - (NSInteger)self.visibleFolders.count;
    return index >= 0 && index < (NSInteger)self.visibleItems.count ? self.visibleItems[index] : nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.selectionHandler) return;
    NSString *key = @"com.qiu7c.neowc.quick-reply.import-tip.shared";
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
    self.folders = NeoWCQuickReplyStore.sharedStore.folders;
    [self applySearchText:self.searchController.searchBar.text];
}

- (void)applySearchText:(NSString *)query {
    NSString *trimmed = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    BOOL searching = trimmed.length > 0;
    self.visibleFolders = !self.currentFolderIdentifier.length && !searching ? self.folders : @[];
    self.visibleItems = [self.allItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NeoWCQuickReplyItem *item, NSDictionary *bindings) {
            (void)bindings;
            BOOL folderMatches = searching && !self.currentFolderIdentifier.length
                ? YES
                : (self.currentFolderIdentifier.length
                    ? [item.folderIdentifier isEqualToString:self.currentFolderIdentifier]
                    : item.folderIdentifier.length == 0);
            BOOL textMatches = trimmed.length == 0 || [item.title localizedCaseInsensitiveContainsString:trimmed] ||
                               [item.text localizedCaseInsensitiveContainsString:trimmed];
            return folderMatches && textMatches;
    }]];
    [self.tableView reloadData];
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
    [sheet addAction:[UIAlertAction actionWithTitle:@"重命名备注" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名备注" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"备注（可选）"; field.text = item.title; }];
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
    [sheet addAction:[UIAlertAction actionWithTitle:@"移动到文件夹" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self chooseFolderForItem:item];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) { popover.sourceView = self.view; popover.sourceRect = self.view.bounds; }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)renameItem:(NeoWCQuickReplyItem *)item {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名备注" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"备注（可选）";
        field.text = item.title;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        item.title = alert.textFields.firstObject.text ?: @"";
        NSError *error = nil;
        [NeoWCQuickReplyStore.sharedStore updateItem:item error:&error];
        if (error) [self showError:error];
        [self reloadItems];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)chooseFolderForItem:(NeoWCQuickReplyItem *)item {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"移动到文件夹" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSString *rootTitle = item.folderIdentifier.length ? @"素材库根目录" : @"素材库根目录 ✓";
    [sheet addAction:[UIAlertAction actionWithTitle:rootTitle style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSError *error = nil;
        [NeoWCQuickReplyStore.sharedStore moveItemWithIdentifier:item.identifier toFolderIdentifier:nil error:&error];
        if (error) [self showError:error];
        [self reloadItems];
    }]];
    for (NeoWCQuickReplyFolder *folder in NeoWCQuickReplyStore.sharedStore.folders) {
        NSString *title = [item.folderIdentifier isEqualToString:folder.identifier]
            ? [folder.name stringByAppendingString:@" ✓"] : folder.name;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSError *error = nil;
            [NeoWCQuickReplyStore.sharedStore moveItemWithIdentifier:item.identifier toFolderIdentifier:folder.identifier error:&error];
            if (error) [self showError:error];
            [self reloadItems];
        }]];
    }
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
        [self showError:[NSError errorWithDomain:@"NeoWC" code:1 userInfo:@{NSLocalizedDescriptionKey: @"共享素材库暂时无法读写。"}]];
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
    if (!self.currentFolderIdentifier.length) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"新建文件夹" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self createFolder];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    popover.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)createFolder {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建文件夹" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"文件夹名称"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"创建" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSError *error = nil;
        [NeoWCQuickReplyStore.sharedStore createFolderWithName:alert.textFields.firstObject.text error:&error];
        if (error) [weakSelf showError:error];
        [weakSelf reloadItems];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)editFolder:(NeoWCQuickReplyFolder *)folder {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:folder.name message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"重命名" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名文件夹" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.text = folder.name; }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *saveAction) {
            NSError *error = nil;
            [NeoWCQuickReplyStore.sharedStore renameFolderWithIdentifier:folder.identifier toName:alert.textFields.firstObject.text error:&error];
            if (error) [self showError:error];
            [self reloadItems];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"删除文件夹" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        NSError *error = nil;
        [NeoWCQuickReplyStore.sharedStore deleteFolderWithIdentifier:folder.identifier error:&error];
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
    editor.saveHandler = ^(NSString *title, NSString *text) {
        NSError *error = nil;
        NeoWCQuickReplyItem *strongItem = weakItem;
        if (strongItem) {
            strongItem.title = title;
            strongItem.text = text;
            [NeoWCQuickReplyStore.sharedStore updateItem:strongItem error:&error];
        } else {
            [NeoWCQuickReplyStore.sharedStore addText:text title:title
                                     folderIdentifier:weakSelf.currentFolderIdentifier
                                    sourceConversation:nil sourceMessageID:nil error:&error];
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
        [NeoWCQuickReplyStore.sharedStore addMediaAtURL:URL type:type title:nil
                                      folderIdentifier:self.currentFolderIdentifier
                                     sourceConversation:nil sourceMessageID:nil error:&error];
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
    return self.visibleFolders.count + self.visibleItems.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    if (!NeoWCQuickReplyStore.sharedStore.isAvailable) return @"共享素材库暂时无法读写。";
    NSByteCountFormatter *formatter = [NSByteCountFormatter new];
    formatter.countStyle = NSByteCountFormatterCountStyleFile;
    NSString *size = [formatter stringFromByteCount:(long long)NeoWCQuickReplyStore.sharedStore.managedMediaSize];
    return [NSString stringWithFormat:@"全部账号共享，共 %lu 项，媒体占用 %@。素材文件独立保存，不依赖聊天缓存。", (unsigned long)self.allItems.count, size];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"QuickReplyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    NeoWCQuickReplyFolder *folder = [self folderAtIndexPath:indexPath];
    if (folder) {
        NSUInteger count = 0;
        for (NeoWCQuickReplyItem *candidate in self.allItems) if ([candidate.folderIdentifier isEqualToString:folder.identifier]) count++;
        cell.textLabel.text = folder.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu 项素材", (unsigned long)count];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:20.0 weight:UIImageSymbolWeightRegular];
        cell.imageView.image = [[UIImage systemImageNamed:@"folder" withConfiguration:configuration]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.imageView.tintColor = UIColor.labelColor;
        return cell;
    }
    NeoWCQuickReplyItem *item = [self itemAtIndexPath:indexPath];
    if (!item) return cell;
    NSString *fallbackTitle = item.type == NeoWCQuickReplyTypeText ? item.text :
        (item.type == NeoWCQuickReplyTypeImage ? @"图片素材" : (item.type == NeoWCQuickReplyTypeVideo ? @"视频素材" : @"语音素材"));
    cell.textLabel.text = item.title.length > 0 ? item.title : fallbackTitle;
    cell.textLabel.numberOfLines = 1;
    NSString *typeName = item.type == NeoWCQuickReplyTypeText ? @"文字" :
        (item.type == NeoWCQuickReplyTypeImage ? @"图片" : (item.type == NeoWCQuickReplyTypeVideo ? @"视频" : @"语音"));
    NSMutableArray<NSString *> *details = [NSMutableArray arrayWithObject:typeName];
    if (item.isPinned) [details addObject:@"已置顶"];
    cell.detailTextLabel.text = [details componentsJoinedByString:@" · "];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSString *symbol = item.type == NeoWCQuickReplyTypeText ? @"text.bubble" :
        (item.type == NeoWCQuickReplyTypeImage ? @"photo" :
         (item.type == NeoWCQuickReplyTypeVideo ? @"video" : @"waveform"));
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:20.0
                                                                                                   weight:UIImageSymbolWeightRegular];
    cell.imageView.image = [[UIImage systemImageNamed:symbol withConfiguration:configuration]
        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.imageView.tintColor = UIColor.labelColor;
    cell.imageView.contentMode = UIViewContentModeCenter;
    cell.imageView.clipsToBounds = NO;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView; (void)indexPath;
    return !self.selectionHandler && self.visibleFolders.count == 0 && self.searchController.searchBar.text.length == 0;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    (void)tableView;
    NSMutableArray *ordered = [self.visibleItems mutableCopy];
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
    NeoWCQuickReplyFolder *folder = [self folderAtIndexPath:indexPath];
    if (folder) {
        NeoWCQuickReplyViewController *controller = [[NeoWCQuickReplyViewController alloc]
            initWithSelectionHandler:self.selectionHandler directSendHandler:self.directSendHandler];
        controller.currentFolderIdentifier = folder.identifier;
        controller.currentFolderName = folder.name;
        [self.navigationController pushViewController:controller animated:YES];
        return;
    }
    NeoWCQuickReplyItem *item = [self itemAtIndexPath:indexPath];
    if (!item) return;
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
    if (item.type == NeoWCQuickReplyTypeVoice && path.length > 0) {
        NeoWCQuickReplyMediaPreviewViewController *preview = [[NeoWCQuickReplyMediaPreviewViewController alloc] initWithItem:item];
        preview.showsSendButton = NO;
        [self.navigationController pushViewController:preview animated:YES];
        return;
    }
    [self editMediaItem:item];
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
    NeoWCQuickReplyFolder *folder = [self folderAtIndexPath:indexPath];
    if (folder) {
        __weak typeof(self) weakSelf = self;
        UIContextualAction *deleteFolder = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"删除" handler:^(__unused UIContextualAction *action, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
            NSError *error = nil;
            BOOL deleted = [NeoWCQuickReplyStore.sharedStore deleteFolderWithIdentifier:folder.identifier error:&error];
            if (error) [weakSelf showError:error];
            [weakSelf reloadItems];
            completionHandler(deleted);
        }];
        return [UISwipeActionsConfiguration configurationWithActions:@[deleteFolder]];
    }
    NeoWCQuickReplyItem *item = [self itemAtIndexPath:indexPath];
    if (!item) return nil;
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
    NeoWCQuickReplyFolder *folder = [self folderAtIndexPath:indexPath];
    if (folder) {
        __weak typeof(self) weakSelf = self;
        UIContextualAction *renameFolder = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"重命名" handler:^(__unused UIContextualAction *action, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
            [weakSelf editFolder:folder];
            completionHandler(YES);
        }];
        renameFolder.backgroundColor = UIColor.systemBlueColor;
        return [UISwipeActionsConfiguration configurationWithActions:@[renameFolder]];
    }
    NeoWCQuickReplyItem *item = [self itemAtIndexPath:indexPath];
    if (!item) return nil;
    __weak typeof(self) weakSelf = self;
    UIContextualAction *rename = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                        title:@"重命名"
                                                                      handler:^(__unused UIContextualAction *action, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
        [weakSelf renameItem:item];
        completionHandler(YES);
    }];
    rename.backgroundColor = UIColor.systemBlueColor;
    UIContextualAction *move = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                          title:@"移动"
                                                                        handler:^(__unused UIContextualAction *action, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
        [weakSelf chooseFolderForItem:item];
        completionHandler(YES);
    }];
    move.backgroundColor = UIColor.systemTealColor;
    return [UISwipeActionsConfiguration configurationWithActions:@[rename, move]];
}

@end
