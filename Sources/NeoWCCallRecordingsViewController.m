#import "NeoWCCallRecordingsViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface NeoWCCallRecordingsViewController () <AVAudioPlayerDelegate>
@property (nonatomic, copy) NSArray<NSURL *> *recordings;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSURL *playingURL;
@end

@implementation NeoWCCallRecordingsViewController

- (instancetype)init {
    return [self initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"通话录音";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
        target:self action:@selector(reloadRecordings)];
    [self reloadRecordings];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player stop];
    self.player = nil;
    self.playingURL = nil;
}

- (NSURL *)recordingDirectory {
    NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory
                                                             inDomains:NSUserDomainMask].firstObject;
    return [documents URLByAppendingPathComponent:@"NeoWC/CallRecordings" isDirectory:YES];
}

- (void)reloadRecordings {
    NSURL *directory = [self recordingDirectory];
    [NSFileManager.defaultManager createDirectoryAtURL:directory
                           withIntermediateDirectories:YES attributes:nil error:nil];
    NSArray<NSURL *> *files = [NSFileManager.defaultManager contentsOfDirectoryAtURL:directory
                                                          includingPropertiesForKeys:@[
        NSURLContentModificationDateKey, NSURLFileSizeKey, NSURLIsRegularFileKey
    ] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil] ?: @[];
    NSPredicate *audioPredicate = [NSPredicate predicateWithBlock:^BOOL(NSURL *url,
                                                                         NSDictionary *bindings) {
        (void)bindings;
        return [@[@"m4a", @"caf"] containsObject:url.pathExtension.lowercaseString];
    }];
    self.recordings = [[files filteredArrayUsingPredicate:audioPredicate]
        sortedArrayUsingComparator:^NSComparisonResult(NSURL *first, NSURL *second) {
        NSDate *firstDate = nil;
        NSDate *secondDate = nil;
        [first getResourceValue:&firstDate forKey:NSURLContentModificationDateKey error:nil];
        [second getResourceValue:&secondDate forKey:NSURLContentModificationDateKey error:nil];
        return [secondDate ?: NSDate.distantPast compare:firstDate ?: NSDate.distantPast];
    }];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return MAX((NSInteger)self.recordings.count, 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.recordings.count > 0
        ? @"点按播放或暂停。mixed 是双方混合录音，mic 和 peer 是本地、对端原始音轨。"
        : @"暂无通话录音。开启通话录音后，文件将在通话结束时保存。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"call-recording"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:@"call-recording"];
    if (self.recordings.count == 0) {
        cell.textLabel.text = @"暂无录音";
        cell.detailTextLabel.text = @"完成一次启用录音的通话后再查看";
        cell.imageView.image = [UIImage systemImageNamed:@"waveform.slash"];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    NSURL *url = self.recordings[indexPath.row];
    NSNumber *size = nil;
    NSDate *date = nil;
    [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
    [url getResourceValue:&date forKey:NSURLContentModificationDateKey error:nil];
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    });
    NSString *track = [url.lastPathComponent containsString:@"-mixed."] ? @"双方混合" :
        ([url.lastPathComponent containsString:@"-mic."] ? @"本地麦克风" : @"对端声音");
    cell.textLabel.text = url.lastPathComponent;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@ · %.1f MB", track,
                                 date ? [formatter stringFromDate:date] : @"未知时间",
                                 size.longLongValue / 1048576.0];
    cell.imageView.image = [UIImage systemImageNamed:[self.playingURL isEqual:url] && self.player.isPlaying
                                                     ? @"pause.circle.fill" : @"play.circle"];
    cell.imageView.tintColor = UIColor.systemGreenColor;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= self.recordings.count) return;
    NSURL *url = self.recordings[indexPath.row];
    if ([self.playingURL isEqual:url] && self.player.isPlaying) {
        [self.player pause];
        [self.tableView reloadData];
        return;
    }
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (!player) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"无法播放"
                                                                       message:error.localizedDescription ?: @"录音文件不可用"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [self.player stop];
    self.player = player;
    self.player.delegate = self;
    self.playingURL = url;
    [self.player play];
    [self.tableView reloadData];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    (void)player;
    (void)flag;
    self.playingURL = nil;
    self.player = nil;
    [self.tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    return indexPath.row < self.recordings.count;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style
 forRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (style != UITableViewCellEditingStyleDelete || indexPath.row >= self.recordings.count) return;
    NSURL *url = self.recordings[indexPath.row];
    if ([self.playingURL isEqual:url]) {
        [self.player stop];
        self.player = nil;
        self.playingURL = nil;
    }
    [NSFileManager.defaultManager removeItemAtURL:url error:nil];
    [self reloadRecordings];
}

@end
