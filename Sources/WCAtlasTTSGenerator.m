#import "WCAtlasTTSGenerator.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const WCAtlasTTSErrorDomain = @"com.qiu7c.wcatlas.tts";

@interface WCAtlasTTSRequest : NSObject
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) AVAudioFile *audioFile;
@property (nonatomic, strong) NSURL *outputURL;
@property (nonatomic, copy) void (^completion)(NSURL * _Nullable, NSError * _Nullable);
@property (nonatomic, assign) BOOL finished;
- (void)startWithText:(NSString *)text;
@end

static NSMutableSet<WCAtlasTTSRequest *> *WCAtlasTTSActiveRequests(void) {
    static NSMutableSet<WCAtlasTTSRequest *> *requests;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ requests = [NSMutableSet set]; });
    return requests;
}

static NSError *WCAtlasTTSError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:WCAtlasTTSErrorDomain code:code
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"语音生成失败"}];
}

@implementation WCAtlasTTSRequest

- (void)finishWithError:(NSError *)error {
    @synchronized (self) {
        if (self.finished) return;
        self.finished = YES;
        self.audioFile = nil;
    }
    NSURL *URL = error ? nil : self.outputURL;
    if (error && self.outputURL) {
        [NSFileManager.defaultManager removeItemAtURL:self.outputURL error:nil];
    }
    void (^completion)(NSURL *, NSError *) = self.completion;
    self.completion = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) completion(URL, error);
        @synchronized (WCAtlasTTSActiveRequests()) {
            [WCAtlasTTSActiveRequests() removeObject:self];
        }
        self.synthesizer = nil;
    });
}

- (void)startWithText:(NSString *)text {
    NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"WCAtlasTTS"];
    NSError *directoryError = nil;
    if (![NSFileManager.defaultManager createDirectoryAtPath:directory
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&directoryError]) {
        [self finishWithError:directoryError ?: WCAtlasTTSError(1, @"无法创建 TTS 临时目录")];
        return;
    }
    self.outputURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:
        [NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"caf"]]];
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    self.synthesizer.usesApplicationAudioSession = NO;
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92f;
    utterance.pitchMultiplier = 1.0f;
    __weak typeof(self) weakSelf = self;
    [self.synthesizer writeUtterance:utterance toBufferCallback:^(AVAudioBuffer *buffer) {
        WCAtlasTTSRequest *strongSelf = weakSelf;
        if (!strongSelf || strongSelf.finished) return;
        if (![buffer isKindOfClass:AVAudioPCMBuffer.class]) {
            [strongSelf finishWithError:WCAtlasTTSError(2, @"系统返回了不支持的语音缓冲")];
            return;
        }
        AVAudioPCMBuffer *PCMBuffer = (AVAudioPCMBuffer *)buffer;
        if (PCMBuffer.frameLength == 0) {
            if (!strongSelf.audioFile) {
                [strongSelf finishWithError:WCAtlasTTSError(3, @"系统没有生成有效语音")];
            } else {
                [strongSelf finishWithError:nil];
            }
            return;
        }
        NSError *writeError = nil;
        BOOL writeFailed = NO;
        @synchronized (strongSelf) {
            if (strongSelf.finished) return;
            if (!strongSelf.audioFile) {
                strongSelf.audioFile = [[AVAudioFile alloc] initForWriting:strongSelf.outputURL
                                                                  settings:PCMBuffer.format.settings
                                                                     error:&writeError];
            }
            if (!strongSelf.audioFile ||
                ![strongSelf.audioFile writeFromBuffer:PCMBuffer error:&writeError]) {
                writeFailed = YES;
            }
        }
        if (writeFailed) {
            [strongSelf finishWithError:writeError ?: WCAtlasTTSError(4, @"无法写入生成的语音")];
        }
    }];
}

@end

void WCAtlasGenerateLocalSpeech(NSString *text,
                              void (^completion)(NSURL *outputURL, NSError *error)) {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(nil, WCAtlasTTSError(5, @"请输入需要合成的文字"));
        });
        return;
    }
    if (trimmed.length > 500) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(nil, WCAtlasTTSError(6, @"首版 TTS 最多支持 500 个字符"));
        });
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        WCAtlasTTSRequest *request = [WCAtlasTTSRequest new];
        request.completion = completion;
        @synchronized (WCAtlasTTSActiveRequests()) {
            [WCAtlasTTSActiveRequests() addObject:request];
        }
        [request startWithText:trimmed];
    });
}
