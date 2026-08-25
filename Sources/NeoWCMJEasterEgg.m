#import "NeoWCMJEasterEgg.h"
#import "NeoWCDebug.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>

extern const unsigned char NeoWCMJDropStart[];
extern const unsigned char NeoWCMJDropEnd[];
extern const unsigned char NeoWCMJSwingStart[];
extern const unsigned char NeoWCMJSwingEnd[];

@interface NeoWCMatteVideoView : MTKView
- (instancetype)initWithFrame:(CGRect)frame URL:(NSURL *)URL completion:(dispatch_block_t)completion;
- (void)start;
- (void)stop;
@end

@interface NeoWCPassthroughOverlayView : UIView
@end

@implementation NeoWCPassthroughOverlayView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    (void)point;
    (void)event;
    return nil;
}

@end

@interface NeoWCMatteVideoView ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItemVideoOutput *videoOutput;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) CIContext *CIContext;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, copy) dispatch_block_t completion;
@property (nonatomic, strong) id endObserver;
@property (nonatomic, strong) id failureObserver;
@property (nonatomic, assign) BOOL completed;
@property (nonatomic, assign) BOOL renderedFirstFrame;
@end

@implementation NeoWCMatteVideoView

- (instancetype)initWithFrame:(CGRect)frame URL:(NSURL *)URL completion:(dispatch_block_t)completion {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device || !URL) {
        NeoWCLogAlways(@"[MJ彩蛋] 无法创建 Metal 播放视图：device=%@ URL=%@", device ? @"YES" : @"NO", URL.path ?: @"-");
        return nil;
    }
    self = [super initWithFrame:frame device:device];
    if (!self) return nil;
    self.opaque = NO;
    self.backgroundColor = UIColor.clearColor;
    self.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.framebufferOnly = NO;
    self.paused = YES;
    self.enableSetNeedsDisplay = NO;
    self.userInteractionEnabled = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentScaleFactor = UIScreen.mainScreen.scale;
    self.drawableSize = CGSizeMake(CGRectGetWidth(frame) * self.contentScaleFactor,
                                   CGRectGetHeight(frame) * self.contentScaleFactor);

    _completion = [completion copy];
    _CIContext = [CIContext contextWithMTLDevice:device options:@{kCIContextWorkingColorSpace: NSNull.null}];
    _commandQueue = [device newCommandQueue];
    NSDictionary *attributes = @{
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferMetalCompatibilityKey: @YES,
    };
    _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:attributes];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:URL];
    [item addOutput:_videoOutput];
    _player = [AVPlayer playerWithPlayerItem:item];
    _player.muted = NO;
    __weak typeof(self) weakSelf = self;
    _endObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                                    object:item
                                                                     queue:NSOperationQueue.mainQueue
                                                                usingBlock:^(__unused NSNotification *note) {
        [weakSelf finish];
    }];
    _failureObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVPlayerItemFailedToPlayToEndTimeNotification
                                                                         object:item
                                                                          queue:NSOperationQueue.mainQueue
                                                                     usingBlock:^(__unused NSNotification *note) {
        NSError *error = weakSelf.player.currentItem.error;
        NeoWCLogAlways(@"[MJ彩蛋] 视频播放失败：%@", error.localizedDescription ?: @"未知错误");
        [weakSelf finish];
    }];
    return self;
}

- (void)start {
    if (self.completed) return;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkFired:)];
    if (@available(iOS 15.0, *)) {
        self.displayLink.preferredFrameRateRange = CAFrameRateRangeMake(30.0, 30.0, 30.0);
    } else {
        self.displayLink.preferredFramesPerSecond = 30;
    }
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    [self.player play];
    NeoWCLogAlways(@"[MJ彩蛋] 开始播放：%@", self.player.currentItem.asset);
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf && !weakSelf.completed && !weakSelf.renderedFirstFrame) {
            NeoWCLogAlways(@"[MJ彩蛋] 播放器已启动，但一秒内没有取得视频帧");
        }
    });
}

- (void)displayLinkFired:(CADisplayLink *)displayLink {
    CFTimeInterval hostTime = displayLink.targetTimestamp > 0.0 ? displayLink.targetTimestamp : displayLink.timestamp;
    CMTime itemTime = [self.videoOutput itemTimeForHostTime:hostTime];
    if (![self.videoOutput hasNewPixelBufferForItemTime:itemTime]) return;
    CVPixelBufferRef pixelBuffer = [self.videoOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
    if (!pixelBuffer) return;
    [self renderPixelBuffer:pixelBuffer];
    CVPixelBufferRelease(pixelBuffer);
}

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    id<CAMetalDrawable> drawable = self.currentDrawable;
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    if (!drawable || !commandBuffer) return;

    CIImage *frame = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CGRect extent = frame.extent;
    CGFloat halfWidth = floor(CGRectGetWidth(extent) * 0.5);
    if (halfWidth < 1.0 || CGRectGetHeight(extent) < 1.0) return;
    CGRect matteRect = CGRectMake(CGRectGetMinX(extent), CGRectGetMinY(extent),
                                  halfWidth, CGRectGetHeight(extent));
    CGRect colorRect = CGRectMake(CGRectGetMinX(extent) + halfWidth, CGRectGetMinY(extent),
                                  halfWidth, CGRectGetHeight(extent));
    CIImage *matte = [frame imageByCroppingToRect:matteRect];
    CIImage *color = [[frame imageByCroppingToRect:colorRect]
        imageByApplyingTransform:CGAffineTransformMakeTranslation(-halfWidth, 0.0)];
    CIColor *transparentColor = [CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    CIImage *clear = [[CIImage imageWithColor:transparentColor] imageByCroppingToRect:matteRect];
    CIFilter *blend = [CIFilter filterWithName:@"CIBlendWithMask"];
    [blend setValue:color forKey:kCIInputImageKey];
    [blend setValue:clear forKey:kCIInputBackgroundImageKey];
    [blend setValue:matte forKey:kCIInputMaskImageKey];
    CIImage *composited = blend.outputImage;
    if (!composited) return;

    CGRect drawableBounds = CGRectMake(0.0, 0.0, self.drawableSize.width, self.drawableSize.height);
    CGFloat scale = MIN(CGRectGetWidth(drawableBounds) / halfWidth,
                        CGRectGetHeight(drawableBounds) / CGRectGetHeight(extent));
    CGFloat renderedWidth = halfWidth * scale;
    CGFloat renderedHeight = CGRectGetHeight(extent) * scale;
    CGFloat offsetX = (CGRectGetWidth(drawableBounds) - renderedWidth) * 0.5;
    // Core Image uses a bottom-left origin, so this places the rendered top edge
    // at the drawable's top while retaining horizontal centering.
    CGFloat offsetY = CGRectGetHeight(drawableBounds) - renderedHeight;
    composited = [composited imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    composited = [composited imageByApplyingTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
    CIImage *canvas = [[CIImage imageWithColor:transparentColor] imageByCroppingToRect:drawableBounds];
    composited = [composited imageByCompositingOverImage:canvas];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    [self.CIContext render:composited
                toMTLTexture:drawable.texture
        commandBuffer:commandBuffer
               bounds:drawableBounds
           colorSpace:colorSpace];
    CGColorSpaceRelease(colorSpace);
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    if (!self.renderedFirstFrame) {
        self.renderedFirstFrame = YES;
        NeoWCLogAlways(@"[MJ彩蛋] 已取得并提交首帧");
    }
}

- (void)finish {
    if (self.completed) return;
    self.completed = YES;
    dispatch_block_t completion = self.completion;
    [self stop];
    if (completion) completion();
}

- (void)stop {
    [self.player pause];
    [self.displayLink invalidate];
    self.displayLink = nil;
    if (self.endObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:self.endObserver];
        self.endObserver = nil;
    }
    if (self.failureObserver) {
        [NSNotificationCenter.defaultCenter removeObserver:self.failureObserver];
        self.failureObserver = nil;
    }
}

- (void)dealloc {
    [self stop];
}

@end

static NSString *NeoWCMJEasterEggDataDirectory(void) {
    NSURL *applicationSupport = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory
                                                                     inDomains:NSUserDomainMask].firstObject;
    return applicationSupport ? [[[applicationSupport URLByAppendingPathComponent:@"NeoWC" isDirectory:YES]
                                  URLByAppendingPathComponent:@"MJ" isDirectory:YES] path] : nil;
}

static BOOL NeoWCWriteEmbeddedMJAsset(NSString *path,
                                      const unsigned char *start,
                                      const unsigned char *end,
                                      NSError **error) {
    if (path.length == 0 || !start || !end || end <= start) return NO;
    NSUInteger length = (NSUInteger)(end - start);
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:path error:nil];
    if ([attributes[NSFileSize] unsignedIntegerValue] == length) return YES;
    NSData *data = [NSData dataWithBytes:start length:length];
    return [data writeToFile:path options:NSDataWritingAtomic error:error];
}

static NSArray<NSURL *> *NeoWCMJEasterEggMaterializeResources(void) {
    NSString *directory = NeoWCMJEasterEggDataDirectory();
    if (directory.length == 0) {
        NeoWCLogAlways(@"[MJ彩蛋] 无法取得 NeoWC 数据目录");
        return @[];
    }
    NSError *directoryError = nil;
    if (![NSFileManager.defaultManager createDirectoryAtPath:directory
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&directoryError]) {
        NeoWCLogAlways(@"[MJ彩蛋] 无法创建数据目录：%@", directoryError.localizedDescription ?: @"未知错误");
        return @[];
    }

    NSArray<NSString *> *names = @[@"mj-drop.mp4", @"mj-swing.mp4"];
    const unsigned char *starts[] = {NeoWCMJDropStart, NeoWCMJSwingStart};
    const unsigned char *ends[] = {NeoWCMJDropEnd, NeoWCMJSwingEnd};
    NSMutableArray<NSURL *> *URLs = [NSMutableArray arrayWithCapacity:names.count];
    for (NSUInteger index = 0; index < names.count; index++) {
        NSString *path = [directory stringByAppendingPathComponent:names[index]];
        NSError *writeError = nil;
        if (!NeoWCWriteEmbeddedMJAsset(path, starts[index], ends[index], &writeError)) {
            NeoWCLogAlways(@"[MJ彩蛋] 无法释放 %@：%@", names[index], writeError.localizedDescription ?: @"未知错误");
            return @[];
        }
        [URLs addObject:[NSURL fileURLWithPath:path]];
    }
    NeoWCLogAlways(@"[MJ彩蛋] 视频资源已就绪：%@", directory);
    return URLs;
}

static UIWindow *NeoWCMJEasterEggWindow(void) {
    UIWindow *fallback = nil;
    for (UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
        if (![candidate isKindOfClass:UIWindowScene.class]) continue;
        UIWindowScene *scene = (UIWindowScene *)candidate;
        if (scene.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *window in scene.windows) {
            if (window.hidden || window.alpha <= 0.01 || window.windowLevel != UIWindowLevelNormal ||
                !window.rootViewController) continue;
            if (window.isKeyWindow) return window;
            if (!fallback) fallback = window;
        }
    }
    return fallback;
}

@interface NeoWCMJEasterEggSession : NSObject
@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) NeoWCMatteVideoView *videoView;
@property (nonatomic, copy) NSArray<NSURL *> *URLs;
@property (nonatomic, assign) NSUInteger index;
- (void)start;
- (void)playNext;
- (void)stop;
@end

static NeoWCMJEasterEggSession *NeoWCActiveMJEasterEggSession;

@implementation NeoWCMJEasterEggSession

- (void)start {
    UIWindow *window = NeoWCMJEasterEggWindow();
    if (!window || self.URLs.count == 0) {
        NeoWCLogAlways(@"[MJ彩蛋] 无法开始：window=%@ clips=%lu", window ? @"YES" : @"NO", (unsigned long)self.URLs.count);
        return;
    }
    NeoWCLogAlways(@"[MJ彩蛋] 覆盖微信窗口：%@ frame=%@", NSStringFromClass(window.class), NSStringFromCGRect(window.bounds));
    self.overlay = [[NeoWCPassthroughOverlayView alloc] initWithFrame:window.bounds];
    self.overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.overlay.backgroundColor = UIColor.clearColor;
    self.overlay.userInteractionEnabled = NO;
    self.overlay.alpha = 0.0;
    [window addSubview:self.overlay];
    [UIView animateWithDuration:0.12 animations:^{ self.overlay.alpha = 1.0; }];
    [self playNext];
}

- (void)playNext {
    if (self.index >= self.URLs.count) {
        [UIView animateWithDuration:0.18 animations:^{ self.overlay.alpha = 0.0; } completion:^(__unused BOOL finished) {
            [self stop];
        }];
        return;
    }
    NSURL *URL = self.URLs[self.index++];
    __weak typeof(self) weakSelf = self;
    NeoWCMatteVideoView *view = [[NeoWCMatteVideoView alloc] initWithFrame:self.overlay.bounds
                                                                       URL:URL
                                                                completion:^{
        [weakSelf.videoView removeFromSuperview];
        weakSelf.videoView = nil;
        [weakSelf playNext];
    }];
    if (!view) {
        [self playNext];
        return;
    }
    self.videoView = view;
    [self.overlay addSubview:view];
    [view start];
}

- (void)stop {
    [self.videoView stop];
    [self.videoView removeFromSuperview];
    self.videoView = nil;
    [self.overlay removeFromSuperview];
    self.overlay = nil;
    if (NeoWCActiveMJEasterEggSession == self) NeoWCActiveMJEasterEggSession = nil;
}

@end

void NeoWCPlayMJEasterEgg(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NeoWCActiveMJEasterEggSession stop];
        NSArray<NSURL *> *URLs = NeoWCMJEasterEggMaterializeResources();
        if (URLs.count == 0) return;
        NeoWCMJEasterEggSession *session = [NeoWCMJEasterEggSession new];
        session.URLs = URLs;
        NeoWCActiveMJEasterEggSession = session;
        [session start];
    });
}
