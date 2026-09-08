#import "NeoWCCallAudio.h"
#import "NeoWCEnhancements.h"
#import "NeoWCLogging.h"
#import "NeoWCQuickReplyStore.h"
#import "NeoWCSilkDecoder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <math.h>
#import <objc/runtime.h>
#import <os/lock.h>
#import <stdbool.h>
#import <stdatomic.h>

extern void MSHookFunction(void *symbol, void *replacement, void **original);
extern void MSHookMessageEx(Class cls, SEL selector, IMP replacement, IMP *original);

static NSString *const NeoWCCallRecordDirectoryName = @"NeoWC/CallRecordings";

typedef struct {
    AudioFileID file;
    SInt64 packet;
    AudioStreamBasicDescription format;
} NeoWCPCMWriter;

typedef struct {
    AudioUnit unit;
    AURenderCallback callback;
    void *refCon;
} NeoWCRenderSlot;

static _Atomic(bool) NeoWCCallActive;
static _Atomic(bool) NeoWCCallRecording;
static _Atomic(bool) NeoWCVoiceActive;
static _Atomic(int) NeoWCVoiceMode; // 0 replace, 1 mix
static _Atomic(uintptr_t) NeoWCVoiceBytes;
static _Atomic(size_t) NeoWCVoiceByteCount;
static _Atomic(uint64_t) NeoWCVoiceFramePosition;
static _Atomic(uint64_t) NeoWCAudioActivityGeneration;
static void *NeoWCRetiredVoiceBuffers[32];
static NSUInteger NeoWCRetiredVoiceBufferCount;
static NeoWCPCMWriter NeoWCMicWriter;
static NeoWCPCMWriter NeoWCPeerWriter;
static os_unfair_lock NeoWCMicWriterLock = OS_UNFAIR_LOCK_INIT;
static os_unfair_lock NeoWCPeerWriterLock = OS_UNFAIR_LOCK_INIT;
static NSString *NeoWCCallSessionPrefix;
static NSString *NeoWCMicRecordingPath;
static NSString *NeoWCPeerRecordingPath;
static NeoWCRenderSlot NeoWCRenderSlots[16];
static dispatch_queue_t NeoWCCallFileQueue;
static void NeoWCCallDidStop(void);
static void NeoWCCallVoiceDidFinish(void);

static OSStatus (*NeoWCOriginalAudioUnitRender)(AudioUnit, AudioUnitRenderActionFlags *,
                                                const AudioTimeStamp *, UInt32, UInt32,
                                                AudioBufferList *);
static OSStatus (*NeoWCOriginalAudioUnitSetProperty)(AudioUnit, AudioUnitPropertyID,
                                                     AudioUnitScope, AudioUnitElement,
                                                     const void *, UInt32);
static OSStatus (*NeoWCOriginalAudioComponentInstanceDispose)(AudioComponentInstance);

static NSURL *NeoWCCallRecordDirectory(void) {
    NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory
                                                             inDomains:NSUserDomainMask].firstObject;
    NSURL *directory = [documents URLByAppendingPathComponent:NeoWCCallRecordDirectoryName
                                                   isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:directory
                           withIntermediateDirectories:YES attributes:nil error:nil];
    return directory;
}

static BOOL NeoWCFormatIsSupportedPCM(AudioStreamBasicDescription format) {
    if (format.mFormatID != kAudioFormatLinearPCM || format.mChannelsPerFrame == 0) return NO;
    BOOL float32 = (format.mFormatFlags & kAudioFormatFlagIsFloat) && format.mBitsPerChannel == 32;
    BOOL int16 = !(format.mFormatFlags & kAudioFormatFlagIsFloat) && format.mBitsPerChannel == 16;
    return float32 || int16;
}

static AudioStreamBasicDescription NeoWCFormatForUnit(AudioUnit unit, AudioUnitScope scope,
                                                       AudioUnitElement element) {
    AudioStreamBasicDescription format = {0};
    UInt32 size = sizeof(format);
    if (!unit || AudioUnitGetProperty(unit, kAudioUnitProperty_StreamFormat, scope, element,
                                      &format, &size) != noErr) return format;
    return format;
}

static void NeoWCCloseWriter(NeoWCPCMWriter *writer) {
    if (!writer || !writer->file) return;
    AudioFileClose(writer->file);
    memset(writer, 0, sizeof(*writer));
}

static void NeoWCOpenWriter(NeoWCPCMWriter *writer, NSString *suffix,
                            AudioStreamBasicDescription sourceFormat) {
    if (!writer || writer->file || !NeoWCFormatIsSupportedPCM(sourceFormat)) return;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyyMMdd-HHmmss";
    NSString *prefix = NeoWCCallSessionPrefix ?: [formatter stringFromDate:NSDate.date];
    NSString *name = [NSString stringWithFormat:@"%@-%@.caf", prefix, suffix];
    NSURL *url = [NeoWCCallRecordDirectory() URLByAppendingPathComponent:name];
    AudioStreamBasicDescription fileFormat = sourceFormat;
    OSStatus status = AudioFileCreateWithURL((__bridge CFURLRef)url, kAudioFileCAFType,
                                             &fileFormat, kAudioFileFlags_EraseFile,
                                             &writer->file);
    if (status == noErr) {
        writer->format = sourceFormat;
        writer->packet = 0;
        if ([suffix isEqualToString:@"mic"]) NeoWCMicRecordingPath = url.path;
        if ([suffix isEqualToString:@"peer"]) NeoWCPeerRecordingPath = url.path;
    } else {
        NeoWCLog(@"通话录音文件创建失败：%@ status=%d", suffix, (int)status);
    }
}

static void NeoWCExportMixedRecording(NSString *micPath, NSString *peerPath, NSString *prefix) {
    if (micPath.length == 0 || peerPath.length == 0 || prefix.length == 0) return;
    AVURLAsset *micAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:micPath] options:nil];
    AVURLAsset *peerAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:peerPath] options:nil];
    AVAssetTrack *micSource = [micAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    AVAssetTrack *peerSource = [peerAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    if (!micSource || !peerSource) return;
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSError *error = nil;
    AVMutableCompositionTrack *micTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                    preferredTrackID:kCMPersistentTrackID_Invalid];
    [micTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, micAsset.duration)
                      ofTrack:micSource atTime:kCMTimeZero error:&error];
    AVMutableCompositionTrack *peerTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
    [peerTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, peerAsset.duration)
                       ofTrack:peerSource atTime:kCMTimeZero error:&error];
    if (error) {
        NeoWCLog(@"通话录音混音轨构造失败：%@", error.localizedDescription);
        return;
    }
    NSURL *outputURL = [NeoWCCallRecordDirectory()
        URLByAppendingPathComponent:[NSString stringWithFormat:@"%@-mixed.m4a", prefix]];
    [NSFileManager.defaultManager removeItemAtURL:outputURL error:nil];
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
        initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    exporter.outputURL = outputURL;
    exporter.outputFileType = AVFileTypeAppleM4A;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            NeoWCLog(@"通话录音混合文件已生成：%@", outputURL.path);
        } else {
            NeoWCLog(@"通话录音混合导出失败：%@", exporter.error.localizedDescription);
        }
    }];
}

static void NeoWCWriteBuffers(NeoWCPCMWriter *writer, NSString *suffix,
                              os_unfair_lock *writerLock,
                              AudioStreamBasicDescription format, UInt32 frames,
                              AudioBufferList *buffers) {
    if (!atomic_load(&NeoWCCallRecording) || !buffers || frames == 0 ||
        !NeoWCFormatIsSupportedPCM(format)) return;
    os_unfair_lock_lock(writerLock);
    NeoWCOpenWriter(writer, suffix, format);
    if (!writer->file) {
        os_unfair_lock_unlock(writerLock);
        return;
    }
    UInt32 packets = frames;
    OSStatus status = AudioFileWritePackets(writer->file, false, buffers->mBuffers[0].mDataByteSize,
                                             NULL, writer->packet, &packets,
                                             buffers->mBuffers[0].mData);
    if (status == noErr) writer->packet += packets;
    os_unfair_lock_unlock(writerLock);
}

static inline BOOL NeoWCVoiceSample(uint64_t sourceFrame, UInt32 targetChannel,
                                    float *sample) {
    const SInt16 *samples = (const SInt16 *)atomic_load(&NeoWCVoiceBytes);
    size_t bytes = atomic_load(&NeoWCVoiceByteCount);
    size_t frameCount = bytes / sizeof(SInt16);
    if (!samples || frameCount == 0 || !sample) return NO;
    if (sourceFrame >= frameCount) {
        if (atomic_exchange(&NeoWCVoiceActive, false)) {
            dispatch_async(dispatch_get_main_queue(), ^{ NeoWCCallVoiceDidFinish(); });
        }
        return NO;
    }
    (void)targetChannel;
    *sample = (float)samples[sourceFrame] / 32768.0f;
    return YES;
}

static void NeoWCApplyVoice(AudioStreamBasicDescription format, UInt32 frames,
                            AudioBufferList *buffers) {
    if (!atomic_load(&NeoWCVoiceActive) || !buffers || !NeoWCFormatIsSupportedPCM(format)) return;
    uint64_t start = atomic_fetch_add(&NeoWCVoiceFramePosition, frames);
    double ratio = 48000.0 / MAX(1.0, format.mSampleRate);
    BOOL mix = atomic_load(&NeoWCVoiceMode) == 1;
    BOOL nonInterleaved = (format.mFormatFlags & kAudioFormatFlagIsNonInterleaved) != 0;
    UInt32 channelCount = MAX(1, format.mChannelsPerFrame);
    for (UInt32 bufferIndex = 0; bufferIndex < buffers->mNumberBuffers; bufferIndex++) {
        AudioBuffer *buffer = &buffers->mBuffers[bufferIndex];
        UInt32 reportedChannels = buffer->mNumberChannels > 0 ? buffer->mNumberChannels : channelCount;
        UInt32 channels = nonInterleaved ? 1 : MAX(1, reportedChannels);
        if (format.mBitsPerChannel == 16) {
            SInt16 *values = buffer->mData;
            if (!values) continue;
            UInt32 availableFrames = buffer->mDataByteSize / (sizeof(SInt16) * channels);
            for (UInt32 frame = 0; frame < MIN(frames, availableFrames); frame++) {
                float voice = 0;
                if (!NeoWCVoiceSample((uint64_t)((start + frame) * ratio), bufferIndex, &voice)) break;
                for (UInt32 channel = 0; channel < channels; channel++) {
                    UInt32 index = frame * channels + channel;
                    float original = (float)values[index] / 32768.0f;
                    float result = mix ? original * 0.45f + voice * 0.75f : voice;
                    result = fmaxf(-1.0f, fminf(1.0f, result));
                    values[index] = (SInt16)lrintf(result * 32767.0f);
                }
            }
        } else if (format.mBitsPerChannel == 32 && (format.mFormatFlags & kAudioFormatFlagIsFloat)) {
            float *values = buffer->mData;
            if (!values) continue;
            UInt32 availableFrames = buffer->mDataByteSize / (sizeof(float) * channels);
            for (UInt32 frame = 0; frame < MIN(frames, availableFrames); frame++) {
                float voice = 0;
                if (!NeoWCVoiceSample((uint64_t)((start + frame) * ratio), bufferIndex, &voice)) break;
                for (UInt32 channel = 0; channel < channels; channel++) {
                    UInt32 index = frame * channels + channel;
                    float result = mix ? values[index] * 0.45f + voice * 0.75f : voice;
                    values[index] = fmaxf(-1.0f, fminf(1.0f, result));
                }
            }
        }
    }
}

static OSStatus NeoWCAudioUnitRender(AudioUnit unit, AudioUnitRenderActionFlags *flags,
                                     const AudioTimeStamp *timestamp, UInt32 bus,
                                     UInt32 frames, AudioBufferList *buffers) {
    OSStatus status = NeoWCOriginalAudioUnitRender
        ? NeoWCOriginalAudioUnitRender(unit, flags, timestamp, bus, frames, buffers) : -1;
    if (status != noErr || !atomic_load(&NeoWCCallActive)) return status;
    atomic_fetch_add(&NeoWCAudioActivityGeneration, 1);
    AudioStreamBasicDescription format = NeoWCFormatForUnit(unit, kAudioUnitScope_Output, bus);
    NeoWCApplyVoice(format, frames, buffers);
    NeoWCWriteBuffers(&NeoWCMicWriter, @"mic", &NeoWCMicWriterLock, format, frames, buffers);
    return status;
}

static NeoWCRenderSlot *NeoWCSlotForUnit(AudioUnit unit, BOOL create) {
    for (NSUInteger index = 0; index < 16; index++) {
        if (NeoWCRenderSlots[index].unit == unit) return &NeoWCRenderSlots[index];
    }
    if (!create) return NULL;
    for (NSUInteger index = 0; index < 16; index++) {
        if (!NeoWCRenderSlots[index].unit) {
            NeoWCRenderSlots[index].unit = unit;
            return &NeoWCRenderSlots[index];
        }
    }
    return NULL;
}

static OSStatus NeoWCRenderCallback(void *refCon, AudioUnitRenderActionFlags *flags,
                                    const AudioTimeStamp *timestamp, UInt32 bus,
                                    UInt32 frames, AudioBufferList *buffers) {
    NeoWCRenderSlot *slot = refCon;
    if (!slot || !slot->callback) return noErr;
    OSStatus status = slot->callback(slot->refCon, flags, timestamp, bus, frames, buffers);
    if (status == noErr && atomic_load(&NeoWCCallActive)) {
        atomic_fetch_add(&NeoWCAudioActivityGeneration, 1);
        AudioStreamBasicDescription format = NeoWCFormatForUnit(slot->unit, kAudioUnitScope_Input, bus);
        NeoWCWriteBuffers(&NeoWCPeerWriter, @"peer", &NeoWCPeerWriterLock,
                          format, frames, buffers);
    }
    return status;
}

static OSStatus NeoWCAudioUnitSetProperty(AudioUnit unit, AudioUnitPropertyID property,
                                          AudioUnitScope scope, AudioUnitElement element,
                                          const void *data, UInt32 size) {
    if (!NeoWCOriginalAudioUnitSetProperty) return kAudio_ParamError;
    if (property == kAudioUnitProperty_SetRenderCallback && data &&
        size == sizeof(AURenderCallbackStruct)) {
        const AURenderCallbackStruct *original = data;
        NeoWCRenderSlot *slot = NeoWCSlotForUnit(unit, YES);
        if (slot && original->inputProc != NeoWCRenderCallback) {
            slot->callback = original->inputProc;
            slot->refCon = original->inputProcRefCon;
            AURenderCallbackStruct wrapped = { NeoWCRenderCallback, slot };
            return NeoWCOriginalAudioUnitSetProperty(unit, property, scope, element,
                                                     &wrapped, sizeof(wrapped));
        }
    }
    return NeoWCOriginalAudioUnitSetProperty(unit, property, scope, element, data, size);
}

static OSStatus NeoWCAudioComponentInstanceDispose(AudioComponentInstance instance) {
    OSStatus status = NeoWCOriginalAudioComponentInstanceDispose
        ? NeoWCOriginalAudioComponentInstanceDispose(instance) : kAudio_ParamError;
    if (status == noErr) {
        NeoWCRenderSlot *slot = NeoWCSlotForUnit((AudioUnit)instance, NO);
        if (slot) {
            memset(slot, 0, sizeof(*slot));
            uint64_t generation = atomic_load(&NeoWCAudioActivityGeneration);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                if (atomic_load(&NeoWCCallActive) &&
                    atomic_load(&NeoWCAudioActivityGeneration) == generation) {
                    NeoWCCallDidStop();
                }
            });
        }
    }
    return status;
}

@class NeoWCCallAudioPanel;

@interface NeoWCCallVoiceLibraryViewController : UITableViewController
@property (nonatomic, copy) NSArray<NeoWCQuickReplyItem *> *voiceItems;
@property (nonatomic, weak) NeoWCCallAudioPanel *audioPanel;
@end

@interface NeoWCCallAudioPanel : NSObject
@property (nonatomic, strong) UIView *controlView;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIView *recordingDot;
@property (nonatomic, weak) UIViewController *hostController;
@property (nonatomic, weak) UIViewController *voiceLibraryController;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, assign) BOOL menuExpanded;
- (void)loadVoiceItem:(NeoWCQuickReplyItem *)item;
- (void)voiceDidFinish;
@end

static void NeoWCCallCollectLabels(UIView *view, NSMutableArray<UILabel *> *labels) {
    if (!view || view.hidden || view.alpha <= 0.01) return;
    if ([view isKindOfClass:UILabel.class]) {
        UILabel *label = (UILabel *)view;
        if (label.text.length > 0) [labels addObject:label];
    }
    for (UIView *subview in view.subviews) NeoWCCallCollectLabels(subview, labels);
}

static UILabel *NeoWCCallNameLabel(UIViewController *controller) {
    if (!controller.viewIfLoaded.window) return nil;
    NSMutableArray<UILabel *> *labels = [NSMutableArray array];
    NeoWCCallCollectLabels(controller.view, labels);
    UILabel *best = nil;
    CGFloat bestScore = -CGFLOAT_MAX;
    CGFloat width = CGRectGetWidth(controller.view.bounds);
    CGFloat height = CGRectGetHeight(controller.view.bounds);
    for (UILabel *label in labels) {
        CGRect rect = [label convertRect:label.bounds toView:controller.view];
        CGFloat centerX = CGRectGetMidX(rect);
        CGFloat centerY = CGRectGetMidY(rect);
        if (CGRectIsEmpty(rect) || centerY < height * 0.18 || centerY > height * 0.58 ||
            fabs(centerX - width * 0.5) > width * 0.3) continue;
        NSString *text = [label.text stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (text.length == 0 || [text containsString:@":"] || [text containsString:@"录音"] ||
            [text containsString:@"语音包"]) continue;
        CGFloat score = label.font.pointSize * 12.0 - fabs(centerX - width * 0.5) -
            fabs(centerY - height * 0.36) * 0.08;
        if (score > bestScore) {
            best = label;
            bestScore = score;
        }
    }
    return best;
}

static UIViewController *NeoWCCallTopViewController(UIViewController *controller) {
    if (!controller) return nil;
    UIViewController *presented = controller.presentedViewController;
    if (presented && !presented.isBeingDismissed) return NeoWCCallTopViewController(presented);
    if ([controller isKindOfClass:UINavigationController.class]) {
        return NeoWCCallTopViewController(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:UITabBarController.class]) {
        return NeoWCCallTopViewController(((UITabBarController *)controller).selectedViewController);
    }
    for (UIViewController *child in controller.childViewControllers.reverseObjectEnumerator) {
        if (child.viewIfLoaded.window) return NeoWCCallTopViewController(child);
    }
    return controller;
}

static BOOL NeoWCCallClassNameLooksLikeCallUI(id object) {
    if (!object) return NO;
    NSString *name = NSStringFromClass([object class]).lowercaseString;
    if ([name hasPrefix:@"neowc"] || [name hasPrefix:@"wcallrecorder"]) return NO;
    return [name containsString:@"voip"] || [name containsString:@"multitalk"] ||
           [name containsString:@"callview"] || [name containsString:@"calling"];
}

static UIViewController *NeoWCCallVisibleInterfaceController(void) {
    NSMutableArray<UIWindow *> *windows = [NSMutableArray array];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class] ||
            (scene.activationState != UISceneActivationStateForegroundActive &&
             scene.activationState != UISceneActivationStateForegroundInactive)) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (!window.hidden && window.alpha > 0.01 && window.rootViewController) [windows addObject:window];
        }
    }
    [windows sortUsingComparator:^NSComparisonResult(UIWindow *first, UIWindow *second) {
        if (first.windowLevel > second.windowLevel) return NSOrderedAscending;
        if (first.windowLevel < second.windowLevel) return NSOrderedDescending;
        if (first.isKeyWindow != second.isKeyWindow) {
            return first.isKeyWindow ? NSOrderedAscending : NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    UIViewController *fallback = nil;
    for (UIWindow *window in windows) {
        UIViewController *candidate = NeoWCCallTopViewController(window.rootViewController);
        if (!candidate.viewIfLoaded.window) continue;
        if (NeoWCCallClassNameLooksLikeCallUI(window) || NeoWCCallClassNameLooksLikeCallUI(candidate)) {
            return candidate;
        }
        for (UIViewController *parent = candidate.parentViewController; parent; parent = parent.parentViewController) {
            if (NeoWCCallClassNameLooksLikeCallUI(parent)) return candidate;
        }
        if (!fallback && window.windowLevel < UIWindowLevelAlert) fallback = candidate;
    }
    return fallback;
}

static NSData *NeoWCCallPCMDataAtPath(NSString *path, NSError **error) {
    if (path.length == 0) return nil;
    AVAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    AVAssetReader *reader = track ? [[AVAssetReader alloc] initWithAsset:asset error:error] : nil;
    NSDictionary *settings = @{ AVFormatIDKey: @(kAudioFormatLinearPCM),
                                AVSampleRateKey: @48000,
                                AVNumberOfChannelsKey: @1,
                                AVLinearPCMBitDepthKey: @16,
                                AVLinearPCMIsFloatKey: @NO,
                                AVLinearPCMIsBigEndianKey: @NO,
                                AVLinearPCMIsNonInterleaved: @NO };
    AVAssetReaderTrackOutput *output = track ? [[AVAssetReaderTrackOutput alloc] initWithTrack:track
                                                                                outputSettings:settings] : nil;
    if (!reader || !output || ![reader canAddOutput:output]) return nil;
    [reader addOutput:output];
    if (![reader startReading]) return nil;
    NSMutableData *pcm = [NSMutableData data];
    CMSampleBufferRef sample = NULL;
    while ((sample = [output copyNextSampleBuffer])) {
        CMBlockBufferRef block = CMSampleBufferGetDataBuffer(sample);
        size_t length = block ? CMBlockBufferGetDataLength(block) : 0;
        if (length > 0) {
            NSUInteger oldLength = pcm.length;
            [pcm increaseLengthBy:length];
            CMBlockBufferCopyDataBytes(block, 0, length, (uint8_t *)pcm.mutableBytes + oldLength);
        }
        CFRelease(sample);
    }
    return reader.status == AVAssetReaderStatusCompleted && pcm.length > 0 ? pcm : nil;
}

@implementation NeoWCCallVoiceLibraryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择通话语音包";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
    NSMutableArray<NeoWCQuickReplyItem *> *items = [NSMutableArray array];
    NeoWCQuickReplyStore *store = NeoWCQuickReplyStore.sharedStore;
    for (NeoWCQuickReplyItem *item in store.items) {
        if (item.type != NeoWCQuickReplyTypeVoice) continue;
        NSString *path = [store absoluteMediaPathForItem:item];
        if (path.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:path]) [items addObject:item];
    }
    self.voiceItems = items;
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return MAX((NSInteger)self.voiceItems.count, 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.voiceItems.count ? @"只显示消息库中已有本地音频文件的语音素材。"
                                 : @"消息库中暂无可用语音素材。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"call-voice-item"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:@"call-voice-item"];
    if (indexPath.row >= self.voiceItems.count) {
        cell.textLabel.text = @"暂无语音包";
        cell.detailTextLabel.text = @"先将语音或音频保存到消息库";
        cell.imageView.image = [UIImage systemImageNamed:@"waveform.slash"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    NeoWCQuickReplyItem *item = self.voiceItems[indexPath.row];
    cell.textLabel.text = item.title.length ? item.title : @"语音素材";
    cell.detailTextLabel.text = item.createdAt
        ? [NSDateFormatter localizedStringFromDate:item.createdAt
                                         dateStyle:NSDateFormatterShortStyle
                                         timeStyle:NSDateFormatterShortStyle] : nil;
    cell.imageView.image = [UIImage systemImageNamed:@"waveform"];
    cell.imageView.tintColor = UIColor.systemGreenColor;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= self.voiceItems.count) return;
    NeoWCQuickReplyItem *item = self.voiceItems[indexPath.row];
    [self dismissViewControllerAnimated:YES completion:^{ [self.audioPanel loadVoiceItem:item]; }];
}

@end

@implementation NeoWCCallAudioPanel

+ (instancetype)sharedPanel {
    static NeoWCCallAudioPanel *panel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ panel = [[self alloc] init]; });
    return panel;
}

- (UIButton *)button:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)installRecordingIndicatorInController:(UIViewController *)controller {
    [self.recordingDot removeFromSuperview];
    self.recordingDot = nil;
    if (!atomic_load(&NeoWCCallRecording)) return;
    UILabel *nameLabel = NeoWCCallNameLabel(controller);
    if (!nameLabel) return;
    UIView *dot = [UIView new];
    dot.backgroundColor = UIColor.systemRedColor;
    dot.layer.cornerRadius = 4.0;
    dot.layer.zPosition = 10000.0;
    dot.translatesAutoresizingMaskIntoConstraints = NO;
    [controller.view addSubview:dot];
    CGFloat textWidth = ceil([nameLabel.text sizeWithAttributes:
        @{ NSFontAttributeName: nameLabel.font }].width);
    textWidth = MIN(textWidth, CGRectGetWidth(nameLabel.bounds));
    [NSLayoutConstraint activateConstraints:@[
        [dot.centerXAnchor constraintEqualToAnchor:nameLabel.centerXAnchor
                                          constant:textWidth * 0.5 + 11.0],
        [dot.centerYAnchor constraintEqualToAnchor:nameLabel.centerYAnchor],
        [dot.widthAnchor constraintEqualToConstant:8.0],
        [dot.heightAnchor constraintEqualToConstant:8.0],
    ]];
    self.recordingDot = dot;
}

- (void)toggleMenu {
    self.menuExpanded = !self.menuExpanded;
    if (self.menuExpanded) self.menuView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.menuView.alpha = self.menuExpanded ? 1.0 : 0.0;
        self.menuView.transform = self.menuExpanded
            ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.92, 0.92);
    } completion:^(BOOL finished) {
        (void)finished;
        if (!self.menuExpanded) self.menuView.hidden = YES;
    }];
}

- (void)show {
    if (!NeoWCEnhancementEnabled(NeoWCCallRecordingEnabledKey) &&
        !NeoWCEnhancementEnabled(NeoWCCallVoiceDisguiseEnabledKey)) return;
    UIViewController *controller = NeoWCCallVisibleInterfaceController();
    if (!controller.viewIfLoaded.window) return;
    if ([controller isKindOfClass:NeoWCCallVoiceLibraryViewController.class] ||
        ([controller isKindOfClass:UINavigationController.class] &&
         [((UINavigationController *)controller).topViewController
             isKindOfClass:NeoWCCallVoiceLibraryViewController.class])) return;
    BOOL voiceEnabled = NeoWCEnhancementEnabled(NeoWCCallVoiceDisguiseEnabledKey);
    if (self.hostController == controller) {
        [self installRecordingIndicatorInController:controller];
        if (!voiceEnabled || self.controlView.superview == controller.view) return;
    }
    [self.controlView removeFromSuperview];
    [self.menuView removeFromSuperview];
    [self.recordingDot removeFromSuperview];
    self.hostController = controller;
    [self installRecordingIndicatorInController:controller];
    if (!voiceEnabled) return;

    UIButton *voiceButton = [UIButton buttonWithType:UIButtonTypeSystem];
    voiceButton.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.82];
    voiceButton.tintColor = UIColor.whiteColor;
    voiceButton.layer.cornerRadius = 22.0;
    voiceButton.layer.cornerCurve = kCACornerCurveContinuous;
    voiceButton.layer.zPosition = 10000.0;
    voiceButton.translatesAutoresizingMaskIntoConstraints = NO;
    [voiceButton setImage:[UIImage systemImageNamed:@"waveform"] forState:UIControlStateNormal];
    [voiceButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [controller.view addSubview:voiceButton];

    UIView *menu = [UIView new];
    menu.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.92];
    menu.layer.cornerRadius = 14.0;
    menu.layer.cornerCurve = kCACornerCurveContinuous;
    menu.layer.zPosition = 9999.0;
    menu.translatesAutoresizingMaskIntoConstraints = NO;
    menu.alpha = 0.0;
    menu.hidden = YES;
    menu.transform = CGAffineTransformMakeScale(0.92, 0.92);
    [controller.view insertSubview:menu belowSubview:voiceButton];

    UILabel *label = [[UILabel alloc] init];
    label.text = @"语音包未播放";
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentLeft;
    UIButton *pickButton = [self button:@"选择语音包" action:@selector(pickVoice)];
    UIButton *stopButton = [self button:@"停止播放" action:@selector(stopVoice)];
    UIStackView *buttons = [[UIStackView alloc] initWithArrangedSubviews:@[pickButton, stopButton]];
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.distribution = UIStackViewDistributionFillEqually;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[label, buttons]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 5;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [menu addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [voiceButton.leadingAnchor constraintEqualToAnchor:controller.view.safeAreaLayoutGuide.leadingAnchor constant:12],
        [voiceButton.centerYAnchor constraintEqualToAnchor:controller.view.centerYAnchor],
        [voiceButton.widthAnchor constraintEqualToConstant:44],
        [voiceButton.heightAnchor constraintEqualToConstant:44],
        [menu.leadingAnchor constraintEqualToAnchor:voiceButton.trailingAnchor constant:8],
        [menu.centerYAnchor constraintEqualToAnchor:voiceButton.centerYAnchor],
        [menu.widthAnchor constraintEqualToConstant:190],
        [menu.heightAnchor constraintEqualToConstant:78],
        [stack.leadingAnchor constraintEqualToAnchor:menu.leadingAnchor constant:10],
        [stack.trailingAnchor constraintEqualToAnchor:menu.trailingAnchor constant:-8],
        [stack.topAnchor constraintEqualToAnchor:menu.topAnchor constant:8],
        [stack.bottomAnchor constraintEqualToAnchor:menu.bottomAnchor constant:-8],
    ]];
    self.controlView = voiceButton;
    self.menuView = menu;
    self.statusLabel = label;
    self.menuExpanded = NO;
}

- (void)hide {
    if (self.voiceLibraryController.viewIfLoaded.window) {
        [self.voiceLibraryController dismissViewControllerAnimated:NO completion:nil];
    }
    self.voiceLibraryController = nil;
    [self.controlView removeFromSuperview];
    [self.menuView removeFromSuperview];
    [self.recordingDot removeFromSuperview];
    self.controlView = nil;
    self.menuView = nil;
    self.recordingDot = nil;
    self.hostController = nil;
    self.statusLabel = nil;
    self.menuExpanded = NO;
}

- (void)pickVoice {
    if (!NeoWCEnhancementEnabled(NeoWCCallVoiceDisguiseEnabledKey)) return;
    UIViewController *presenter = self.hostController;
    if (!presenter.viewIfLoaded.window) return;
    NeoWCCallVoiceLibraryViewController *library = [[NeoWCCallVoiceLibraryViewController alloc]
        initWithStyle:UITableViewStyleInsetGrouped];
    library.audioPanel = self;
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:library];
    self.voiceLibraryController = navigation;
    [presenter presentViewController:navigation animated:YES completion:nil];
}

- (void)stopVoice {
    atomic_store(&NeoWCVoiceActive, false);
    atomic_store(&NeoWCVoiceFramePosition, 0);
    self.statusLabel.text = @"语音包已停止";
}

- (void)voiceDidFinish {
    if (atomic_load(&NeoWCVoiceActive)) return;
    self.statusLabel.text = @"语音包已播完";
}

- (void)loadVoiceItem:(NeoWCQuickReplyItem *)item {
    NSString *sourcePath = [NeoWCQuickReplyStore.sharedStore absoluteMediaPathForItem:item];
    if (sourcePath.length == 0) {
        self.statusLabel.text = @"语音包文件不存在";
        return;
    }
    self.statusLabel.text = @"正在准备语音包…";
    NSString *title = item.title.length ? item.title : @"语音素材";
    BOOL mightBeSilk = [item.metadata[@"voiceFormat"] unsignedIntegerValue] == 4 ||
        [@[@"aud", @"silk"] containsObject:sourcePath.pathExtension.lowercaseString];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSData *pcm = NeoWCCallPCMDataAtPath(sourcePath, &error);
        NSString *temporaryPath = nil;
        if (!pcm.length && mightBeSilk) {
            NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"NeoWCCallVoice"];
            [NSFileManager.defaultManager createDirectoryAtPath:directory
                                    withIntermediateDirectories:YES attributes:nil error:nil];
            temporaryPath = [directory stringByAppendingPathComponent:
                [NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"wav"]];
            if (NeoWCSilkDecodeFileToWAV(sourcePath, temporaryPath, &error)) {
                pcm = NeoWCCallPCMDataAtPath(temporaryPath, &error);
            }
        }
        if (temporaryPath.length) [NSFileManager.defaultManager removeItemAtPath:temporaryPath error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!atomic_load(&NeoWCCallActive) || !self.controlView.window) return;
            if (!pcm.length) {
                self.statusLabel.text = error.localizedDescription ?: @"语音包解码失败";
                return;
            }
            void *copy = malloc(pcm.length);
            if (!copy) {
                self.statusLabel.text = @"语音包内存不足";
                return;
            }
            memcpy(copy, pcm.bytes, pcm.length);
            atomic_store(&NeoWCVoiceByteCount, 0);
            void *old = (void *)atomic_exchange(&NeoWCVoiceBytes, (uintptr_t)copy);
            atomic_store(&NeoWCVoiceByteCount, pcm.length);
            atomic_store(&NeoWCVoiceFramePosition, 0);
            atomic_store(&NeoWCVoiceMode,
                [NSUserDefaults.standardUserDefaults integerForKey:NeoWCCallVoiceModeKey] == 1 ? 1 : 0);
            atomic_store(&NeoWCVoiceActive, true);
            if (old && NeoWCRetiredVoiceBufferCount < 32) {
                NeoWCRetiredVoiceBuffers[NeoWCRetiredVoiceBufferCount++] = old;
            }
            [NeoWCQuickReplyStore.sharedStore recordUsageForIdentifier:item.identifier error:nil];
            self.statusLabel.text = [NSString stringWithFormat:@"语音包：%@", title];
        });
    });
}

@end

static void NeoWCCallVoiceDidFinish(void) {
    [[NeoWCCallAudioPanel sharedPanel] voiceDidFinish];
}

static void NeoWCCallDidStart(void) {
    if (atomic_exchange(&NeoWCCallActive, true)) return;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyyMMdd-HHmmss";
    NeoWCCallSessionPrefix = [formatter stringFromDate:NSDate.date];
    NeoWCMicRecordingPath = nil;
    NeoWCPeerRecordingPath = nil;
    atomic_fetch_add(&NeoWCAudioActivityGeneration, 1);
    atomic_store(&NeoWCCallRecording, NeoWCEnhancementEnabled(NeoWCCallRecordingEnabledKey));
    for (NSNumber *delay in @[@0.0, @0.25, @0.75, @1.5]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (atomic_load(&NeoWCCallActive)) [[NeoWCCallAudioPanel sharedPanel] show];
        });
    }
    NeoWCLog(@"通话音频会话开始");
}

void NeoWCCallAudioNotifyAudioDeviceStarted(void) {
    if (NSThread.isMainThread) {
        NeoWCCallDidStart();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{ NeoWCCallDidStart(); });
    }
}

static void NeoWCCallDidStop(void) {
    if (!atomic_exchange(&NeoWCCallActive, false)) return;
    atomic_store(&NeoWCCallRecording, false);
    atomic_store(&NeoWCVoiceActive, false);
    atomic_store(&NeoWCVoiceByteCount, 0);
    void *voiceBytes = (void *)atomic_exchange(&NeoWCVoiceBytes, 0);
    dispatch_async(NeoWCCallFileQueue, ^{
        os_unfair_lock_lock(&NeoWCMicWriterLock);
        NeoWCCloseWriter(&NeoWCMicWriter);
        os_unfair_lock_unlock(&NeoWCMicWriterLock);
        os_unfair_lock_lock(&NeoWCPeerWriterLock);
        NeoWCCloseWriter(&NeoWCPeerWriter);
        os_unfair_lock_unlock(&NeoWCPeerWriterLock);
        NeoWCExportMixedRecording(NeoWCMicRecordingPath, NeoWCPeerRecordingPath,
                                  NeoWCCallSessionPrefix);
    });
    dispatch_async(dispatch_get_main_queue(), ^{ [[NeoWCCallAudioPanel sharedPanel] hide]; });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (voiceBytes) free(voiceBytes);
        for (NSUInteger index = 0; index < NeoWCRetiredVoiceBufferCount; index++) {
            free(NeoWCRetiredVoiceBuffers[index]);
            NeoWCRetiredVoiceBuffers[index] = NULL;
        }
        NeoWCRetiredVoiceBufferCount = 0;
    });
    NeoWCLog(@"通话音频会话结束，录音目录=%@", NeoWCCallRecordDirectory().path);
}

typedef uintptr_t (*NeoWCVoIPNoArgumentIMP)(id, SEL);
typedef uintptr_t (*NeoWCVoIPOneArgumentIMP)(id, SEL, id);
typedef uintptr_t (*NeoWCVoIPTwoArgumentIMP)(id, SEL, id, id);
static NeoWCVoIPNoArgumentIMP NeoWCOriginalStartNoArguments;
static NeoWCVoIPNoArgumentIMP NeoWCOriginalStartMuTalk;
static NeoWCVoIPNoArgumentIMP NeoWCOriginalStartRecovery;
static NeoWCVoIPOneArgumentIMP NeoWCOriginalStartOneArgument;
static NeoWCVoIPTwoArgumentIMP NeoWCOriginalStartTwoArguments;
static NeoWCVoIPNoArgumentIMP NeoWCOriginalStop;
static void (*NeoWCOriginalStopVoid)(id, SEL);

static uintptr_t NeoWCStartNoArguments(id self, SEL selector) {
    uintptr_t result = NeoWCOriginalStartNoArguments ? NeoWCOriginalStartNoArguments(self, selector) : 0;
    if (result != 0) NeoWCCallDidStart();
    return result;
}

static uintptr_t NeoWCStartMuTalk(id self, SEL selector) {
    uintptr_t result = NeoWCOriginalStartMuTalk ? NeoWCOriginalStartMuTalk(self, selector) : 0;
    if (result != 0) NeoWCCallDidStart();
    return result;
}

static uintptr_t NeoWCStartRecovery(id self, SEL selector) {
    uintptr_t result = NeoWCOriginalStartRecovery ? NeoWCOriginalStartRecovery(self, selector) : 0;
    if (result != 0) NeoWCCallDidStart();
    return result;
}

static uintptr_t NeoWCStartOneArgument(id self, SEL selector, id value) {
    uintptr_t result = NeoWCOriginalStartOneArgument ? NeoWCOriginalStartOneArgument(self, selector, value) : 0;
    if (result != 0) NeoWCCallDidStart();
    return result;
}

static uintptr_t NeoWCStartTwoArguments(id self, SEL selector, id first, id second) {
    uintptr_t result = NeoWCOriginalStartTwoArguments ? NeoWCOriginalStartTwoArguments(self, selector, first, second) : 0;
    if (result != 0) NeoWCCallDidStart();
    return result;
}

static uintptr_t NeoWCStop(id self, SEL selector) {
    uintptr_t result = NeoWCOriginalStop ? NeoWCOriginalStop(self, selector) : 0;
    NeoWCCallDidStop();
    return result;
}

static void NeoWCStopVoid(id self, SEL selector) {
    if (NeoWCOriginalStopVoid) NeoWCOriginalStopVoid(self, selector);
    NeoWCCallDidStop();
}

static void NeoWCInstallLifecycleHook(Class cls, NSString *name, IMP replacement, IMP *original,
                                      unsigned int argumentCount) {
    SEL selector = NSSelectorFromString(name);
    Method method = cls ? class_getInstanceMethod(cls, selector) : NULL;
    if (!method || method_getNumberOfArguments(method) != argumentCount || *original) return;
    char *returnType = method_copyReturnType(method);
    const char *returnCursor = returnType ?: "";
    while (*returnCursor && strchr("rnNoORV", *returnCursor)) returnCursor++;
    BOOL stopMethod = [name isEqualToString:@"StopForVoIP"];
    BOOL supportedReturn = returnCursor[0] == '@' || strchr("cCsSiIlLqQB", returnCursor[0]) ||
        (stopMethod && returnCursor[0] == 'v');
    BOOL supportedArguments = YES;
    for (unsigned int index = 2; index < argumentCount; index++) {
        char *argumentType = method_copyArgumentType(method, index);
        const char *argumentCursor = argumentType ?: "";
        while (*argumentCursor && strchr("rnNoORV", *argumentCursor)) argumentCursor++;
        supportedArguments = supportedArguments && argumentCursor[0] == '@';
        if (argumentType) free(argumentType);
    }
    if (!supportedReturn || !supportedArguments) {
        NeoWCLog(@"通话音频 Hook ABI 不匹配：%@ return=%s args=%u",
                 name, returnCursor, method_getNumberOfArguments(method));
        if (returnType) free(returnType);
        return;
    }
    if (stopMethod && returnCursor[0] == 'v') {
        IMP stopOriginal = NULL;
        MSHookMessageEx(cls, selector, (IMP)NeoWCStopVoid, &stopOriginal);
        NeoWCOriginalStopVoid = (void (*)(id, SEL))stopOriginal;
        if (returnType) free(returnType);
        NeoWCLog(@"通话音频 Hook 已安装：%@ original=%p return=void", name, stopOriginal);
        return;
    }
    if (returnType) free(returnType);
    MSHookMessageEx(cls, selector, replacement, original);
    NeoWCLog(@"通话音频 Hook 已安装：%@ original=%p", name, *original);
}

void NeoWCCallAudioInstallHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NeoWCCallFileQueue = dispatch_queue_create("com.qiu7c.neowc.call-audio-files", DISPATCH_QUEUE_SERIAL);
        MSHookFunction((void *)AudioUnitRender, (void *)NeoWCAudioUnitRender,
                       (void **)&NeoWCOriginalAudioUnitRender);
        MSHookFunction((void *)AudioUnitSetProperty, (void *)NeoWCAudioUnitSetProperty,
                       (void **)&NeoWCOriginalAudioUnitSetProperty);
        MSHookFunction((void *)AudioComponentInstanceDispose,
                       (void *)NeoWCAudioComponentInstanceDispose,
                       (void **)&NeoWCOriginalAudioComponentInstanceDispose);
        Class cls = NSClassFromString(@"AUAudioDevice");
        NeoWCInstallLifecycleHook(cls, @"StartRecordAndPlayForVoIPWithRoomID:roomKey:",
                                 (IMP)NeoWCStartTwoArguments, (IMP *)&NeoWCOriginalStartTwoArguments, 4);
        NeoWCInstallLifecycleHook(cls, @"StartRecordAndPlayForVoIP", (IMP)NeoWCStartNoArguments,
                                 (IMP *)&NeoWCOriginalStartNoArguments, 2);
        NeoWCInstallLifecycleHook(cls, @"StartRecordAndPlayForIlink:", (IMP)NeoWCStartOneArgument,
                                 (IMP *)&NeoWCOriginalStartOneArgument, 3);
        NeoWCInstallLifecycleHook(cls, @"StartRecordAndPlayForMuTalk", (IMP)NeoWCStartMuTalk,
                                 (IMP *)&NeoWCOriginalStartMuTalk, 2);
        NeoWCInstallLifecycleHook(cls, @"StartRecordAndPlayForVoIPInterruptionRecovery",
                                 (IMP)NeoWCStartRecovery,
                                 (IMP *)&NeoWCOriginalStartRecovery, 2);
        NeoWCInstallLifecycleHook(cls, @"StopForVoIP", (IMP)NeoWCStop,
                                 (IMP *)&NeoWCOriginalStop, 2);
        NeoWCLog(@"通话音频 Hook 安装：AUAudioDevice=%@ render=%p setProperty=%p",
                 cls, NeoWCOriginalAudioUnitRender, NeoWCOriginalAudioUnitSetProperty);
    });
}
