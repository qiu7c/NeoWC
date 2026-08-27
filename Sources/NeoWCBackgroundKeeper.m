#import "NeoWCBackgroundKeeper.h"
#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface NeoWCBackgroundKeeper : NSObject
@property (nonatomic, assign) UIBackgroundTaskIdentifier taskIdentifier;
@property (nonatomic, strong, nullable) NSTimer *renewalTimer;
@property (nonatomic, strong, nullable) AVAudioPlayer *silentPlayer;
@property (nonatomic, assign) BOOL audioSessionActivated;
+ (instancetype)sharedKeeper;
- (void)enterBackground;
- (void)leaveBackground;
@end

@implementation NeoWCBackgroundKeeper

+ (instancetype)sharedKeeper {
    static NeoWCBackgroundKeeper *keeper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keeper = [NeoWCBackgroundKeeper new];
        keeper.taskIdentifier = UIBackgroundTaskInvalid;
    });
    return keeper;
}

- (BOOL)enabled {
    return NeoWCEnhancementEnabled(NeoWCBackgroundKeepAliveEnabledKey);
}

- (void)endCurrentTask {
    UIBackgroundTaskIdentifier identifier = self.taskIdentifier;
    if (identifier == UIBackgroundTaskInvalid) return;
    self.taskIdentifier = UIBackgroundTaskInvalid;
    [UIApplication.sharedApplication endBackgroundTask:identifier];
}

- (void)beginFreshTask {
    [self endCurrentTask];
    UIApplication *application = UIApplication.sharedApplication;
    __weak typeof(self) weakSelf = self;
    __block UIBackgroundTaskIdentifier identifier = UIBackgroundTaskInvalid;
    identifier = [application beginBackgroundTaskWithExpirationHandler:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (self.taskIdentifier == identifier) self.taskIdentifier = UIBackgroundTaskInvalid;
        if (identifier != UIBackgroundTaskInvalid) [application endBackgroundTask:identifier];
    }];
    self.taskIdentifier = identifier;
}

static void NeoWCAppendLittleEndian16(NSMutableData *data, uint16_t value) {
    uint16_t encoded = CFSwapInt16HostToLittle(value);
    [data appendBytes:&encoded length:sizeof(encoded)];
}

static void NeoWCAppendLittleEndian32(NSMutableData *data, uint32_t value) {
    uint32_t encoded = CFSwapInt32HostToLittle(value);
    [data appendBytes:&encoded length:sizeof(encoded)];
}

- (NSURL *)silentAudioURL {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *supportURL = [fileManager URLsForDirectory:NSApplicationSupportDirectory
                                            inDomains:NSUserDomainMask].firstObject;
    NSURL *directoryURL = [supportURL URLByAppendingPathComponent:@"NeoWC/Background" isDirectory:YES];
    NSURL *audioURL = [directoryURL URLByAppendingPathComponent:@"silence.wav" isDirectory:NO];
    if ([fileManager fileExistsAtPath:audioURL.path]) return audioURL;

    NSError *directoryError = nil;
    if (![fileManager createDirectoryAtURL:directoryURL
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&directoryError]) {
        NeoWCLog(@"创建后台静音音频目录失败：%@", directoryError.localizedDescription ?: @"未知错误");
        return nil;
    }

    const uint32_t sampleRate = 8000;
    const uint16_t channels = 1;
    const uint16_t bitsPerSample = 16;
    const uint32_t dataSize = sampleRate * channels * (bitsPerSample / 8);
    NSMutableData *wave = [NSMutableData dataWithCapacity:44 + dataSize];
    [wave appendBytes:"RIFF" length:4];
    NeoWCAppendLittleEndian32(wave, 36 + dataSize);
    [wave appendBytes:"WAVEfmt " length:8];
    NeoWCAppendLittleEndian32(wave, 16);
    NeoWCAppendLittleEndian16(wave, 1);
    NeoWCAppendLittleEndian16(wave, channels);
    NeoWCAppendLittleEndian32(wave, sampleRate);
    NeoWCAppendLittleEndian32(wave, sampleRate * channels * (bitsPerSample / 8));
    NeoWCAppendLittleEndian16(wave, channels * (bitsPerSample / 8));
    NeoWCAppendLittleEndian16(wave, bitsPerSample);
    [wave appendBytes:"data" length:4];
    NeoWCAppendLittleEndian32(wave, dataSize);
    [wave increaseLengthBy:dataSize];

    NSError *writeError = nil;
    if (![wave writeToURL:audioURL options:NSDataWritingAtomic error:&writeError]) {
        NeoWCLog(@"写入后台静音音频失败：%@", writeError.localizedDescription ?: @"未知错误");
        return nil;
    }
    return audioURL;
}

- (void)playSilentAudioIfNeeded {
    if (self.silentPlayer.isPlaying) return;
    NSError *sessionError = nil;
    AVAudioSession *session = AVAudioSession.sharedInstance;
    if (![session setCategory:AVAudioSessionCategoryPlayback
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers
                        error:&sessionError] ||
        ![session setActive:YES error:&sessionError]) {
        NeoWCLog(@"启动后台静音音频会话失败：%@", sessionError.localizedDescription ?: @"未知错误");
        return;
    }
    self.audioSessionActivated = YES;
    NSURL *audioURL = [self silentAudioURL];
    if (!audioURL) return;
    NSError *playerError = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:&playerError];
    if (!player) {
        NeoWCLog(@"创建后台静音播放器失败：%@", playerError.localizedDescription ?: @"未知错误");
        return;
    }
    player.numberOfLoops = -1;
    [player prepareToPlay];
    self.silentPlayer = player;
    if (![player play]) NeoWCLog(@"后台静音音频未能开始播放");
}

- (void)requestMoreTime:(NSTimer *)timer {
    (void)timer;
    if (![self enabled]) {
        [self leaveBackground];
        return;
    }
    UIApplication *application = UIApplication.sharedApplication;
    if (application.applicationState != UIApplicationStateBackground) return;
    if (application.backgroundTimeRemaining < 30.0) {
        [self playSilentAudioIfNeeded];
        [self beginFreshTask];
    }
}

- (void)enterBackground {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self enterBackground]; });
        return;
    }
    if (![self enabled]) return;
    [self.renewalTimer invalidate];
    [self beginFreshTask];
    self.renewalTimer = [NSTimer timerWithTimeInterval:25.0
                                               target:self
                                             selector:@selector(requestMoreTime:)
                                             userInfo:nil
                                              repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:self.renewalTimer forMode:NSRunLoopCommonModes];
    [self.renewalTimer fire];
    NeoWCLog(@"后台保持已启动");
}

- (void)leaveBackground {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self leaveBackground]; });
        return;
    }
    [self.renewalTimer invalidate];
    self.renewalTimer = nil;
    [self endCurrentTask];
    [self.silentPlayer stop];
    self.silentPlayer = nil;
    if (self.audioSessionActivated) {
        [AVAudioSession.sharedInstance setActive:NO
                                     withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                           error:nil];
        self.audioSessionActivated = NO;
    }
}

@end

void NeoWCBackgroundKeeperEnterBackground(void) {
    [[NeoWCBackgroundKeeper sharedKeeper] enterBackground];
}

void NeoWCBackgroundKeeperWillEnterForeground(void) {
    [[NeoWCBackgroundKeeper sharedKeeper] leaveBackground];
}

void NeoWCBackgroundKeeperSettingsDidChange(void) {
    NeoWCBackgroundKeeper *keeper = [NeoWCBackgroundKeeper sharedKeeper];
    if (!NeoWCEnhancementEnabled(NeoWCBackgroundKeepAliveEnabledKey)) {
        [keeper leaveBackground];
    } else if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        [keeper enterBackground];
    }
}
