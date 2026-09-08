#import "NeoWCCallRecordingsViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface NeoWCCallRecordingsViewController () <AVAudioPlayerDelegate>
@property (nonatomic, copy) NSArray<NSDictionary *> *sessions;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSURL *playingURL;
@end

@implementation NeoWCCallRecordingsViewController

- (instancetype)init { return [self initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"通话录音";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadRecordings)];
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

- (NSString *)prefixForURL:(NSURL *)URL {
    NSString *name = URL.lastPathComponent.stringByDeletingPathExtension;
    for (NSString *suffix in @[@"-mixed", @"-mic", @"-peer"]) {
        if ([name hasSuffix:suffix]) return [name substringToIndex:name.length - suffix.length];
    }
    return nil;
}

- (void)reloadRecordings {
    NSURL *directory = self.recordingDirectory;
    [NSFileManager.defaultManager createDirectoryAtURL:directory
                           withIntermediateDirectories:YES attributes:nil error:nil];
    NSArray<NSURL *> *files = [NSFileManager.defaultManager contentsOfDirectoryAtURL:directory
                                                          includingPropertiesForKeys:@[NSURLFileSizeKey]
                                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                               error:nil] ?: @[];
    NSMutableDictionary<NSString *, NSMutableDictionary *> *groups = [NSMutableDictionary dictionary];
    for (NSURL *URL in files) {
        if (![@[@"m4a", @"caf"] containsObject:URL.pathExtension.lowercaseString]) continue;
        NSString *prefix = [self prefixForURL:URL];
        if (prefix.length == 0) continue;
        NSMutableDictionary *session = groups[prefix];
        if (!session) {
            session = [@{ @"prefix": prefix, @"tracks": [NSMutableDictionary dictionary] } mutableCopy];
            groups[prefix] = session;
        }
        NSString *track = [URL.lastPathComponent containsString:@"-mixed."] ? @"mixed" :
            ([URL.lastPathComponent containsString:@"-mic."] ? @"mic" : @"peer");
        ((NSMutableDictionary *)session[@"tracks"])[track] = URL;
    }
    NSMutableArray *sessions = [NSMutableArray array];
    for (NSMutableDictionary *session in groups.allValues) {
        NSString *prefix = session[@"prefix"];
        NSURL *metadataURL = [directory URLByAppendingPathComponent:[prefix stringByAppendingPathExtension:@"json"]];
        NSData *data = [NSData dataWithContentsOfURL:metadataURL];
        id metadataObject = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSDictionary *metadata = [metadataObject isKindOfClass:NSDictionary.class] ? metadataObject : nil;
        session[@"name"] = [metadata[@"name"] isKindOfClass:NSString.class] ? metadata[@"name"] : @"通话录音";
        NSDateFormatter *parser = [NSDateFormatter new];
        parser.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        parser.dateFormat = @"yyyyMMdd-HHmmss";
        session[@"date"] = [parser dateFromString:prefix] ?: NSDate.distantPast;
        [sessions addObject:session.copy];
    }
    self.sessions = [sessions sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [right[@"date"] compare:left[@"date"]];
    }];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return MAX((NSInteger)self.sessions.count, 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.sessions.count ? @"每次通话只显示一条记录；点按后选择双方混合、本地麦克风或对端声音。"
                               : @"暂无通话录音。开启后会在通话期间自动录制。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"call-session"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"call-session"];
    if (self.sessions.count == 0) {
        cell.textLabel.text = @"暂无录音";
        cell.detailTextLabel.text = @"完成一次启用录音的通话后再查看";
        cell.imageView.image = [UIImage systemImageNamed:@"waveform.slash"];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    NSDictionary *session = self.sessions[indexPath.row];
    NSDictionary *tracks = session[@"tracks"];
    cell.textLabel.text = session[@"name"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %lu 条音轨",
        [NSDateFormatter localizedStringFromDate:session[@"date"] dateStyle:NSDateFormatterMediumStyle
                                       timeStyle:NSDateFormatterShortStyle], (unsigned long)tracks.count];
    cell.imageView.image = [UIImage systemImageNamed:@"waveform.circle"];
    cell.imageView.tintColor = UIColor.systemGreenColor;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)playURL:(NSURL *)URL {
    if ([self.playingURL isEqual:URL] && self.player.isPlaying) { [self.player pause]; return; }
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:&error];
    if (!player) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"无法播放"
            message:error.localizedDescription ?: @"录音文件不可用" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [self.player stop];
    self.player = player;
    self.player.delegate = self;
    self.playingURL = URL;
    [self.player play];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= self.sessions.count) return;
    NSDictionary *tracks = self.sessions[indexPath.row][@"tracks"];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择播放音轨" message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSArray *entry in @[@[@"mixed", @"双方混合"], @[@"mic", @"本地麦克风"], @[@"peer", @"对端声音"]]) {
        NSURL *URL = tracks[entry[0]];
        if (!URL) continue;
        [sheet addAction:[UIAlertAction actionWithTitle:entry[1] style:UIAlertActionStyleDefault
                                                handler:^(__unused UIAlertAction *action) { [self playURL:URL]; }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    sheet.popoverPresentationController.sourceView = cell;
    sheet.popoverPresentationController.sourceRect = cell.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    return indexPath.row < self.sessions.count;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style
 forRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (style != UITableViewCellEditingStyleDelete || indexPath.row >= self.sessions.count) return;
    NSDictionary *session = self.sessions[indexPath.row];
    for (NSURL *URL in [session[@"tracks"] allValues]) {
        if ([self.playingURL isEqual:URL]) { [self.player stop]; self.player = nil; self.playingURL = nil; }
        [NSFileManager.defaultManager removeItemAtURL:URL error:nil];
    }
    NSURL *metadataURL = [self.recordingDirectory URLByAppendingPathComponent:
        [session[@"prefix"] stringByAppendingPathExtension:@"json"]];
    [NSFileManager.defaultManager removeItemAtURL:metadataURL error:nil];
    [self reloadRecordings];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    (void)player; (void)flag;
    self.player = nil;
    self.playingURL = nil;
}

@end
