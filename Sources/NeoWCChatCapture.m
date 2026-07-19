#import "NeoWCChatCapture.h"
#import "NeoWCEnhancements.h"

#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <math.h>

static NSString *const NeoWCChatCaptureAction = @"com.qiu7c.neowc.chat-capture.action";
static char NeoWCActiveChatCaptureKey;

NSString *NeoWCChatCaptureActionIdentifier(void) {
    return NeoWCChatCaptureAction;
}

static id NeoWCSafeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static id NeoWCCallObject(id object, SEL selector) {
    if (!object || !selector || ![object respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(object, selector);
}

static void NeoWCCallVoid(id object, SEL selector) {
    if (object && selector && [object respondsToSelector:selector]) {
        ((void (*)(id, SEL))objc_msgSend)(object, selector);
    }
}

static UIImage *NeoWCSnapshotView(UIView *view, CGSize size) {
    if (!view || size.width <= 0.0 || size.height <= 0.0) return nil;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = NO;
    format.scale = MAX(1.0, UIScreen.mainScreen.scale);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        CGRect rect = (CGRect){CGPointZero, size};
        BOOL drew = [view drawViewHierarchyInRect:rect afterScreenUpdates:YES];
        if (!drew) [view.layer renderInContext:context.CGContext];
    }];
}

static UIImage *NeoWCSnapshotLayerView(UIView *view, CGSize size) {
    if (!view || size.width <= 0.0 || size.height <= 0.0) return nil;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = NO;
    format.scale = MAX(1.0, UIScreen.mainScreen.scale);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [view.layer renderInContext:context.CGContext];
    }];
}

static UIImage *NeoWCSnapshotRectInView(UIView *view, CGRect rect) {
    if (!view || CGRectIsEmpty(rect)) return nil;
    rect = CGRectIntersection(rect, view.bounds);
    if (CGRectIsEmpty(rect)) return nil;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = YES;
    format.scale = MAX(1.0, UIScreen.mainScreen.scale);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:rect.size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [[UIColor secondarySystemBackgroundColor] setFill];
        UIRectFill((CGRect){CGPointZero, rect.size});
        CGContextTranslateCTM(context.CGContext, -CGRectGetMinX(rect), -CGRectGetMinY(rect));
        BOOL drew = [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
        if (!drew) [view.layer renderInContext:context.CGContext];
    }];
}

static void NeoWCCollectOuterRoundedViews(UIView *view, NSMutableArray<NSDictionary *> *states) {
    if (!view) return;
    if (view.layer.cornerRadius > 0.0 || view.layer.mask) {
        [states addObject:@{
            @"view": view,
            @"radius": @(view.layer.cornerRadius),
            @"masks": @(view.layer.masksToBounds),
            @"mask": view.layer.mask ?: NSNull.null,
        }];
        view.layer.cornerRadius = 0.0;
        view.layer.mask = nil;
    }
    CGFloat width = CGRectGetWidth(view.bounds);
    CGFloat height = CGRectGetHeight(view.bounds);
    for (UIView *subview in view.subviews) {
        if (width > 0.0 && height > 0.0 &&
            CGRectGetWidth(subview.frame) >= width * 0.85 &&
            CGRectGetHeight(subview.frame) >= height * 0.55) {
            NeoWCCollectOuterRoundedViews(subview, states);
        }
    }
}

static UIImage *NeoWCSnapshotFlatFooterView(UIView *view, UIColor *backgroundColor) {
    if (!view) return nil;
    NSMutableArray<NSDictionary *> *states = [NSMutableArray array];
    NeoWCCollectOuterRoundedViews(view, states);
    [view layoutIfNeeded];
    UIImage *snapshot = NeoWCSnapshotView(view, view.bounds.size);
    for (NSDictionary *state in states.reverseObjectEnumerator) {
        UIView *roundedView = state[@"view"];
        roundedView.layer.cornerRadius = [state[@"radius"] doubleValue];
        roundedView.layer.masksToBounds = [state[@"masks"] boolValue];
        id mask = state[@"mask"];
        roundedView.layer.mask = mask == NSNull.null ? nil : mask;
    }
    if (!snapshot) return nil;

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = YES;
    format.scale = MAX(1.0, UIScreen.mainScreen.scale);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:snapshot.size format:format];
    return [renderer imageWithActions:^(__unused UIGraphicsImageRendererContext *context) {
        [(backgroundColor ?: UIColor.systemBackgroundColor) setFill];
        UIRectFill((CGRect){CGPointZero, snapshot.size});
        [snapshot drawAtPoint:CGPointZero];
    }];
}

static void NeoWCCollectNameLabels(UIView *view, NSMutableArray<UIView *> *labels) {
    if (!view) return;
    SEL selector = NSSelectorFromString(@"getNameLabel");
    id label = NeoWCCallObject(view, selector);
    if ([label isKindOfClass:[UIView class]] && ![labels containsObject:label]) [labels addObject:label];
    for (UIView *subview in view.subviews) NeoWCCollectNameLabels(subview, labels);
}

static NSString *NeoWCFirstLabelText(UIView *view) {
    if ([view isKindOfClass:[UILabel class]] && ((UILabel *)view).text.length > 0) return ((UILabel *)view).text;
    for (UIView *subview in view.subviews) {
        NSString *text = NeoWCFirstLabelText(subview);
        if (text.length > 0) return text;
    }
    return nil;
}

static void NeoWCFindBottomToolbar(UIView *view, UIView *host, UIView **bestView, CGFloat *bestScore) {
    if (!view || view.hidden || view.alpha < 0.01 || CGRectIsEmpty(view.bounds)) return;
    CGRect rect = [view convertRect:view.bounds toView:host];
    CGRect visible = CGRectIntersection(rect, host.bounds);
    CGFloat hostWidth = CGRectGetWidth(host.bounds);
    CGFloat hostHeight = CGRectGetHeight(host.bounds);
    CGFloat height = CGRectGetHeight(visible);
    CGFloat width = CGRectGetWidth(visible);
    if (height >= 36.0 && height <= 180.0 && width >= hostWidth * 0.65 && CGRectGetMaxY(visible) >= hostHeight - 180.0) {
        CGFloat score = CGRectGetMaxY(visible) - height * 0.25;
        if (score > *bestScore) {
            *bestScore = score;
            *bestView = view;
        }
    }
    for (UIView *subview in view.subviews) NeoWCFindBottomToolbar(subview, host, bestView, bestScore);
}

typedef NS_ENUM(NSInteger, NeoWCChatCaptureEditMode) {
    NeoWCChatCaptureEditModeNone,
    NeoWCChatCaptureEditModeBlur,
    NeoWCChatCaptureEditModeBlack,
    NeoWCChatCaptureEditModeDraw,
};

@interface NeoWCChatCapturePreviewViewController : UIViewController <UIScrollViewDelegate>
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, copy) NSString *chatName;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *annotations;
@property (nonatomic, strong) UIImage *renderedImageCache;
@property (nonatomic, strong) UIView *selectionView;
@property (nonatomic, assign) CGPoint selectionStart;
@property (nonatomic, assign) NeoWCChatCaptureEditMode editMode;
@property (nonatomic, strong) UIToolbar *editToolbar;
@property (nonatomic, strong) UIPanGestureRecognizer *selectionPan;
@property (nonatomic, strong) UIBarButtonItem *blurItem;
@property (nonatomic, strong) UIBarButtonItem *blackItem;
@property (nonatomic, strong) UIBarButtonItem *drawItem;
@property (nonatomic, strong) UIView *blurControlView;
@property (nonatomic, strong) UISlider *blurSlider;
@property (nonatomic, strong) CAShapeLayer *drawingLayer;
@property (nonatomic, strong) NSMutableArray<NSValue *> *currentDrawPoints;
@property (nonatomic, weak) UIViewController *sourceController;
@property (nonatomic, strong) id forwardController;
@property (nonatomic, assign) BOOL didAnimateAppearance;
- (instancetype)initWithImage:(UIImage *)image chatName:(NSString *)chatName sourceController:(UIViewController *)sourceController;
- (void)closePreview;
- (void)shareImage;
- (void)shareToContact;
- (void)forwardImageToContacts:(NSArray *)contacts;
- (void)sendToCurrentConversation;
- (void)saveImage;
- (void)selectBlur;
- (void)selectBlack;
- (void)selectDraw;
- (void)blurStrengthChanged:(UISlider *)slider;
- (void)undoEdit;
- (void)finishEditing;
- (void)centerPreviewImage;
- (void)handleSelectionPan:(UIPanGestureRecognizer *)gesture;
- (UIImage *)renderedImage;
- (void)applyEditMode:(NeoWCChatCaptureEditMode)mode;
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
@end

@implementation NeoWCChatCapturePreviewViewController

- (instancetype)initWithImage:(UIImage *)image chatName:(NSString *)chatName sourceController:(UIViewController *)sourceController {
    self = [super init];
    if (self) {
        _image = image;
        _chatName = [chatName copy];
        _sourceController = sourceController;
        _annotations = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"长截图预览";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(closePreview)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareImage)];

    self.scrollView = [UIScrollView new];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.delegate = self;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 4.0;
    self.scrollView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    [self.view addSubview:self.scrollView];

    self.imageView = [[UIImageView alloc] initWithImage:self.image];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.alpha = 0.0;
    UIPanGestureRecognizer *selectionPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSelectionPan:)];
    selectionPan.minimumNumberOfTouches = 1;
    selectionPan.maximumNumberOfTouches = 1;
    selectionPan.enabled = NO;
    [self.imageView addGestureRecognizer:selectionPan];
    self.selectionPan = selectionPan;
    [self.scrollView addSubview:self.imageView];

    UIToolbar *toolbar = [UIToolbar new];
    self.blurItem = [[UIBarButtonItem alloc] initWithTitle:@"模糊" style:UIBarButtonItemStylePlain target:self action:@selector(selectBlur)];
    self.blackItem = [[UIBarButtonItem alloc] initWithTitle:@"涂黑" style:UIBarButtonItemStylePlain target:self action:@selector(selectBlack)];
    self.drawItem = [[UIBarButtonItem alloc] initWithTitle:@"画笔" style:UIBarButtonItemStylePlain target:self action:@selector(selectDraw)];
    UIBarButtonItem *undo = [[UIBarButtonItem alloc] initWithTitle:@"撤销" style:UIBarButtonItemStylePlain target:self action:@selector(undoEdit)];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(finishEditing)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    toolbar.items = @[self.blurItem, space, self.blackItem, space, self.drawItem, space, undo, space, done];
    self.editToolbar = toolbar;

    UIView *blurControl = [UIView new];
    UILabel *blurLabel = [UILabel new];
    blurLabel.text = @"模糊度";
    blurLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    blurLabel.translatesAutoresizingMaskIntoConstraints = NO;
    UISlider *blurSlider = [UISlider new];
    blurSlider.minimumValue = 3.0;
    blurSlider.maximumValue = 36.0;
    blurSlider.value = 14.0;
    blurSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [blurSlider addTarget:self action:@selector(blurStrengthChanged:) forControlEvents:UIControlEventValueChanged];
    [blurControl addSubview:blurLabel];
    [blurControl addSubview:blurSlider];
    [NSLayoutConstraint activateConstraints:@[
        [blurLabel.leadingAnchor constraintEqualToAnchor:blurControl.leadingAnchor constant:16.0],
        [blurLabel.centerYAnchor constraintEqualToAnchor:blurControl.centerYAnchor],
        [blurLabel.widthAnchor constraintEqualToConstant:52.0],
        [blurSlider.leadingAnchor constraintEqualToAnchor:blurLabel.trailingAnchor constant:8.0],
        [blurSlider.trailingAnchor constraintEqualToAnchor:blurControl.trailingAnchor constant:-16.0],
        [blurSlider.centerYAnchor constraintEqualToAnchor:blurControl.centerYAnchor],
        [blurControl.heightAnchor constraintEqualToConstant:44.0],
    ]];
    blurControl.hidden = YES;
    self.blurControlView = blurControl;
    self.blurSlider = blurSlider;

    UIStackView *bottomStack = [[UIStackView alloc] initWithArrangedSubviews:@[blurControl, toolbar]];
    bottomStack.axis = UILayoutConstraintAxisVertical;
    bottomStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bottomStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:bottomStack.topAnchor],
        [bottomStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [bottomStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [bottomStack.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
    self.renderedImageCache = [self renderedImage];
    self.imageView.image = self.renderedImageCache;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = CGRectGetWidth(self.scrollView.bounds);
    if (width <= 0.0 || self.image.size.width <= 0.0) return;
    CGFloat height = width * self.image.size.height / self.image.size.width;
    self.imageView.frame = CGRectMake(0.0, 0.0, width, height);
    self.scrollView.contentSize = CGSizeMake(MAX(width, CGRectGetWidth(self.scrollView.bounds)), MAX(height, CGRectGetHeight(self.scrollView.bounds)));
    [self centerPreviewImage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.didAnimateAppearance) return;
    self.didAnimateAppearance = YES;
    self.imageView.layer.transform = CATransform3DMakeScale(0.985, 0.985, 1.0);
    [UIView animateWithDuration:0.28
                          delay:0.02
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.imageView.alpha = 1.0;
        self.imageView.layer.transform = CATransform3DIdentity;
    } completion:nil];
}

- (UIView *)viewForZoomingInScrollView:(__unused UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(__unused UIScrollView *)scrollView {
    [self centerPreviewImage];
}

- (void)centerPreviewImage {
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect frame = self.imageView.frame;
    frame.origin.x = frame.size.width < boundsSize.width ? (boundsSize.width - frame.size.width) * 0.5 : 0.0;
    frame.origin.y = frame.size.height < boundsSize.height ? (boundsSize.height - frame.size.height) * 0.5 : 0.0;
    self.imageView.frame = frame;
}

- (void)closePreview {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)shareImage {
    UIImage *output = self.renderedImageCache ?: [self renderedImage];
    if (!output) return;

    Class sheetClass = NSClassFromString(@"WCActionSheet");
    if (!sheetClass) return;
    id sheet = ((id (*)(id, SEL, id, id))objc_msgSend)([sheetClass alloc], NSSelectorFromString(@"initWithTitle:cancelButtonTitle:"), nil, @"取消");
    if (!sheet) return;
    __weak typeof(self) weakSelf = self;
    SEL addSelector = NSSelectorFromString(@"addButtonWithTitle:eventAction:");
    ((id (*)(id, SEL, id, id))objc_msgSend)(sheet, addSelector, @"保存到相册", ^{ [weakSelf saveImage]; });
    ((id (*)(id, SEL, id, id))objc_msgSend)(sheet, addSelector, @"分享给联系人", ^{ [weakSelf shareToContact]; });
    ((id (*)(id, SEL, id, id))objc_msgSend)(sheet, addSelector, @"发送到当前会话", ^{ [weakSelf sendToCurrentConversation]; });
    ((void (*)(id, SEL, id))objc_msgSend)(sheet, NSSelectorFromString(@"showInView:"), self.view);
}

- (void)shareToContact {
    UIImage *output = self.renderedImageCache ?: [self renderedImage];
    Class providerClass = NSClassFromString(@"PasteboardMsgProvider");
    Class forwardClass = NSClassFromString(@"ForwardMessageLogicController");
    if (!output || !providerClass || !forwardClass) return;

    id contact = NeoWCCallObject(self.sourceController, NSSelectorFromString(@"getChatContact"));
    if (!contact) contact = NeoWCCallObject(self.sourceController, NSSelectorFromString(@"GetContact"));
    id message = ((id (*)(id, SEL, id, id))objc_msgSend)(providerClass, NSSelectorFromString(@"GetMessageFromImage:contact:"), output, contact);
    if (!message) return;

    id logic = [[forwardClass alloc] init];
    self.forwardController = logic;
    ((void (*)(id, SEL, id))objc_msgSend)(logic, NSSelectorFromString(@"setDelegate:"), self);
    ((void (*)(id, SEL, BOOL))objc_msgSend)(logic, NSSelectorFromString(@"setBShowSendSuccessView:"), NO);
    ((void (*)(id, SEL, BOOL))objc_msgSend)(logic, NSSelectorFromString(@"setBHiddenSendSuccessToastView:"), NO);
    ((void (*)(id, SEL, id))objc_msgSend)(logic, NSSelectorFromString(@"setFromAppName:"), @"NeoWC");
    ((void (*)(id, SEL, id))objc_msgSend)(logic, NSSelectorFromString(@"setTitle:"), @"选择联系人");
    ((void (*)(id, SEL, id))objc_msgSend)(logic, NSSelectorFromString(@"forwardMessage:"), message);
}

- (void)sendToCurrentConversation {
    id contact = NeoWCCallObject(self.sourceController, NSSelectorFromString(@"getChatContact"));
    if (!contact) contact = NeoWCCallObject(self.sourceController, NSSelectorFromString(@"GetContact"));
    if (!contact) return;
    [self forwardImageToContacts:@[contact]];
}

- (void)forwardImageToContacts:(NSArray *)contacts {
    UIImage *output = self.renderedImageCache ?: [self renderedImage];
    id contact = contacts.firstObject;
    Class providerClass = NSClassFromString(@"PasteboardMsgProvider");
    Class forwardClass = NSClassFromString(@"ForwardMessageLogicController");
    if (!output || !contact || !providerClass || !forwardClass) return;
    id message = ((id (*)(id, SEL, id, id))objc_msgSend)(providerClass, NSSelectorFromString(@"GetMessageFromImage:contact:"), output, contact);
    if (!message) return;

    id logic = [[forwardClass alloc] init];
    self.forwardController = logic;
    ((void (*)(id, SEL, id))objc_msgSend)(logic, NSSelectorFromString(@"setDelegate:"), self);
    ((void (*)(id, SEL, BOOL))objc_msgSend)(logic, NSSelectorFromString(@"setBShowSendSuccessView:"), NO);
    ((void (*)(id, SEL, BOOL))objc_msgSend)(logic, NSSelectorFromString(@"setBHiddenSendSuccessToastView:"), NO);
    ((void (*)(id, SEL, id))objc_msgSend)(logic, NSSelectorFromString(@"setFromAppName:"), @"NeoWC");
    NSArray *messages = @[message];
    ((void (*)(id, SEL, id, id))objc_msgSend)(logic, NSSelectorFromString(@"forwardMsgList:toContacts:"), messages, contacts);
}

- (UIViewController *)getCurrentViewController {
    return self;
}

- (BOOL)shouldShowSendSuccessView:(__unused id)logic {
    return YES;
}

- (void)OnForwardMessageSend:(__unused id)logic {
    self.forwardController = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:NeoWCChatCaptureCloseAfterShareKey]) [self closePreview];
}

- (void)OnForwardMessageConfirmCanceled:(__unused id)logic {
    self.forwardController = nil;
}

- (void)saveImage {
    UIImage *output = self.renderedImageCache ?: [self renderedImage];
    if (!output) return;
    UIImageWriteToSavedPhotosAlbum(output, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image:(__unused UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(__unused void *)contextInfo {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:error ? @"保存失败" : @"已保存到相册"
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)applyEditMode:(NeoWCChatCaptureEditMode)mode {
    self.editMode = self.editMode == mode ? NeoWCChatCaptureEditModeNone : mode;
    self.selectionPan.enabled = self.editMode == NeoWCChatCaptureEditModeBlur || self.editMode == NeoWCChatCaptureEditModeBlack || self.editMode == NeoWCChatCaptureEditModeDraw;
    self.scrollView.scrollEnabled = self.editMode == NeoWCChatCaptureEditModeNone;
    self.blurControlView.hidden = self.editMode != NeoWCChatCaptureEditModeBlur;
    self.blurItem.title = self.editMode == NeoWCChatCaptureEditModeBlur ? @"✓模糊" : @"模糊";
    self.blackItem.title = self.editMode == NeoWCChatCaptureEditModeBlack ? @"✓涂黑" : @"涂黑";
    self.drawItem.title = self.editMode == NeoWCChatCaptureEditModeDraw ? @"✓画笔" : @"画笔";
    if (self.editMode == NeoWCChatCaptureEditModeNone) self.title = @"长截图预览";
    else if (self.editMode == NeoWCChatCaptureEditModeDraw) self.title = @"在图片上自由绘制";
    else self.title = @"拖动框选区域";
}

- (void)selectBlur {
    [self applyEditMode:NeoWCChatCaptureEditModeBlur];
}

- (void)selectBlack {
    [self applyEditMode:NeoWCChatCaptureEditModeBlack];
}

- (void)selectDraw {
    [self applyEditMode:NeoWCChatCaptureEditModeDraw];
}

- (void)blurStrengthChanged:(__unused UISlider *)slider {
}

- (void)finishEditing {
    self.editMode = NeoWCChatCaptureEditModeNone;
    self.selectionPan.enabled = NO;
    self.scrollView.scrollEnabled = YES;
    self.blurControlView.hidden = YES;
    self.blurItem.title = @"模糊";
    self.blackItem.title = @"涂黑";
    self.drawItem.title = @"画笔";
    self.title = @"长截图预览";
    [self.selectionView removeFromSuperview];
    self.selectionView = nil;
    [self.drawingLayer removeFromSuperlayer];
    self.drawingLayer = nil;
    self.currentDrawPoints = nil;
}

- (void)undoEdit {
    if (self.annotations.count == 0) return;
    [self.annotations removeLastObject];
    self.renderedImageCache = [self renderedImage];
    self.imageView.image = self.renderedImageCache;
}

- (void)handleSelectionPan:(UIPanGestureRecognizer *)gesture {
    if (self.editMode == NeoWCChatCaptureEditModeNone) return;
    CGPoint point = [gesture locationInView:self.imageView];
    point.x = MIN(CGRectGetWidth(self.imageView.bounds), MAX(0.0, point.x));
    point.y = MIN(CGRectGetHeight(self.imageView.bounds), MAX(0.0, point.y));

    if (self.editMode == NeoWCChatCaptureEditModeDraw) {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            self.currentDrawPoints = [NSMutableArray arrayWithObject:[NSValue valueWithCGPoint:point]];
            CAShapeLayer *layer = [CAShapeLayer layer];
            layer.fillColor = UIColor.clearColor.CGColor;
            layer.strokeColor = UIColor.systemRedColor.CGColor;
            layer.lineWidth = 4.0;
            layer.lineCap = kCALineCapRound;
            layer.lineJoin = kCALineJoinRound;
            [self.imageView.layer addSublayer:layer];
            self.drawingLayer = layer;
        } else if (gesture.state == UIGestureRecognizerStateChanged) {
            [self.currentDrawPoints addObject:[NSValue valueWithCGPoint:point]];
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:self.currentDrawPoints.firstObject.CGPointValue];
            for (NSUInteger index = 1; index < self.currentDrawPoints.count; index++) [path addLineToPoint:self.currentDrawPoints[index].CGPointValue];
            self.drawingLayer.path = path.CGPath;
        } else if (gesture.state == UIGestureRecognizerStateEnded) {
            [self.currentDrawPoints addObject:[NSValue valueWithCGPoint:point]];
            CGFloat scaleX = self.image.size.width / MAX(1.0, CGRectGetWidth(self.imageView.bounds));
            CGFloat scaleY = self.image.size.height / MAX(1.0, CGRectGetHeight(self.imageView.bounds));
            NSMutableArray<NSValue *> *imagePoints = [NSMutableArray arrayWithCapacity:self.currentDrawPoints.count];
            for (NSValue *value in self.currentDrawPoints) {
                CGPoint displayPoint = value.CGPointValue;
                [imagePoints addObject:[NSValue valueWithCGPoint:CGPointMake(displayPoint.x * scaleX, displayPoint.y * scaleY)]];
            }
            if (imagePoints.count > 1) [self.annotations addObject:@{ @"type": @"draw", @"points": imagePoints, @"width": @(4.0 * scaleX) }];
            [self.drawingLayer removeFromSuperlayer];
            self.drawingLayer = nil;
            self.currentDrawPoints = nil;
            self.renderedImageCache = [self renderedImage];
            self.imageView.image = self.renderedImageCache;
        } else if (gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed) {
            [self.drawingLayer removeFromSuperlayer];
            self.drawingLayer = nil;
            self.currentDrawPoints = nil;
        }
        return;
    }

    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.selectionStart = point;
        UIView *selection = [UIView new];
        selection.userInteractionEnabled = NO;
        selection.backgroundColor = self.editMode == NeoWCChatCaptureEditModeBlack
            ? [[UIColor blackColor] colorWithAlphaComponent:0.38]
            : [[UIColor systemBlueColor] colorWithAlphaComponent:0.20];
        selection.layer.cornerRadius = 4.0;
        [self.imageView addSubview:selection];
        self.selectionView = selection;
    }
    if (gesture.state == UIGestureRecognizerStateChanged || gesture.state == UIGestureRecognizerStateEnded) {
        CGFloat x = MIN(self.selectionStart.x, point.x);
        CGFloat y = MIN(self.selectionStart.y, point.y);
        CGFloat width = fabs(point.x - self.selectionStart.x);
        CGFloat height = fabs(point.y - self.selectionStart.y);
        self.selectionView.frame = CGRectMake(x, y, width, height);
    }
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGRect displayRect = self.selectionView.frame;
        [self.selectionView removeFromSuperview];
        self.selectionView = nil;
        if (displayRect.size.width < 6.0 || displayRect.size.height < 6.0) return;
        CGFloat scaleX = self.image.size.width / MAX(1.0, CGRectGetWidth(self.imageView.bounds));
        CGFloat scaleY = self.image.size.height / MAX(1.0, CGRectGetHeight(self.imageView.bounds));
        CGRect imageRect = CGRectMake(displayRect.origin.x * scaleX, displayRect.origin.y * scaleY,
                                      displayRect.size.width * scaleX, displayRect.size.height * scaleY);
        NSString *type = self.editMode == NeoWCChatCaptureEditModeBlack ? @"black" : @"blur";
        NSMutableDictionary *annotation = [@{ @"type": type, @"rect": [NSValue valueWithCGRect:imageRect] } mutableCopy];
        if (self.editMode == NeoWCChatCaptureEditModeBlur) annotation[@"radius"] = @(self.blurSlider.value);
        [self.annotations addObject:annotation];
        self.renderedImageCache = [self renderedImage];
        self.imageView.image = self.renderedImageCache;
    } else if (gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed) {
        [self.selectionView removeFromSuperview];
        self.selectionView = nil;
    }
}

- (UIImage *)blurredImageForRect:(CGRect)rect radius:(CGFloat)radius context:(CIContext *)context {
    CGRect bounds = CGRectMake(0.0, 0.0, self.image.size.width, self.image.size.height);
    rect = CGRectIntegral(CGRectIntersection(rect, bounds));
    if (CGRectIsEmpty(rect) || !self.image.CGImage) return nil;
    CGFloat imageScale = MAX(1.0, self.image.scale);
    CGRect pixelRect = CGRectMake(rect.origin.x * imageScale, rect.origin.y * imageScale,
                                  rect.size.width * imageScale, rect.size.height * imageScale);
    CGImageRef cropped = CGImageCreateWithImageInRect(self.image.CGImage, pixelRect);
    if (!cropped) return nil;
    CIImage *input = [CIImage imageWithCGImage:cropped];
    CIFilter *clamp = [CIFilter filterWithName:@"CIAffineClamp"];
    [clamp setValue:input forKey:kCIInputImageKey];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:clamp.outputImage forKey:kCIInputImageKey];
    [filter setValue:@(MAX(1.0, radius) * imageScale) forKey:kCIInputRadiusKey];
    CGImageRef output = [context createCGImage:filter.outputImage fromRect:input.extent];
    CGImageRelease(cropped);
    if (!output) return nil;
    UIImage *image = [UIImage imageWithCGImage:output scale:imageScale orientation:UIImageOrientationUp];
    CGImageRelease(output);
    return image;
}

- (NSDictionary<NSAttributedStringKey, id> *)watermarkAttributesWithSize:(CGFloat)size opacity:(CGFloat)opacity {
    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:MIN(0.8, opacity + 0.35)];
    shadow.shadowBlurRadius = 1.0;
    shadow.shadowOffset = CGSizeZero;
    return @{
        NSFontAttributeName: [UIFont systemFontOfSize:size weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: [[UIColor colorWithWhite:0.12 alpha:1.0] colorWithAlphaComponent:opacity],
        NSShadowAttributeName: shadow,
    };
}

- (UIImage *)renderedImage {
    if (!self.image) return nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *watermark = [defaults stringForKey:NeoWCChatCaptureWatermarkTextKey];
    CGFloat opacity = [defaults doubleForKey:NeoWCChatCaptureWatermarkOpacityKey];
    if (opacity <= 0.0) opacity = 0.18;
    opacity = MIN(0.8, MAX(0.05, opacity));
    NSInteger watermarkStyle = [defaults integerForKey:NeoWCChatCaptureWatermarkStyleKey];
    NSMutableArray<NSString *> *metadata = [NSMutableArray array];
    if ([defaults boolForKey:NeoWCChatCaptureShowChatNameKey] && self.chatName.length > 0) [metadata addObject:self.chatName];
    if ([defaults boolForKey:NeoWCChatCaptureShowTimestampKey]) {
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
        [metadata addObject:[formatter stringFromDate:[NSDate date]]];
    }

    CIContext *ciContext = [CIContext contextWithOptions:nil];
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = YES;
    format.scale = MAX(1.0, self.image.scale);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:self.image.size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        [self.image drawAtPoint:CGPointZero];
        for (NSDictionary *annotation in self.annotations) {
            CGRect rect = [annotation[@"rect"] CGRectValue];
            if ([annotation[@"type"] isEqualToString:@"black"]) {
                [[UIColor blackColor] setFill];
                CGContextFillRect(rendererContext.CGContext, rect);
            } else if ([annotation[@"type"] isEqualToString:@"blur"]) {
                UIImage *blurred = [self blurredImageForRect:rect radius:[annotation[@"radius"] doubleValue] context:ciContext];
                [blurred drawInRect:rect];
            } else if ([annotation[@"type"] isEqualToString:@"draw"]) {
                NSArray<NSValue *> *points = annotation[@"points"];
                if (points.count > 1) {
                    CGContextSetStrokeColorWithColor(rendererContext.CGContext, UIColor.systemRedColor.CGColor);
                    CGContextSetLineWidth(rendererContext.CGContext, [annotation[@"width"] doubleValue]);
                    CGContextSetLineCap(rendererContext.CGContext, kCGLineCapRound);
                    CGContextSetLineJoin(rendererContext.CGContext, kCGLineJoinRound);
                    CGContextBeginPath(rendererContext.CGContext);
                    CGPoint first = points.firstObject.CGPointValue;
                    CGContextMoveToPoint(rendererContext.CGContext, first.x, first.y);
                    for (NSUInteger index = 1; index < points.count; index++) {
                        CGPoint next = points[index].CGPointValue;
                        CGContextAddLineToPoint(rendererContext.CGContext, next.x, next.y);
                    }
                    CGContextStrokePath(rendererContext.CGContext);
                }
            }
        }

        if (watermark.length > 0) {
            NSDictionary *attributes = [self watermarkAttributesWithSize:18.0 opacity:opacity];
            CGSize textSize = [watermark sizeWithAttributes:attributes];
            if (watermarkStyle == 2) {
                CGContextSaveGState(rendererContext.CGContext);
                CGContextRotateCTM(rendererContext.CGContext, (CGFloat)-M_PI / 10.0);
                CGFloat stepX = MAX(180.0, textSize.width + 90.0);
                for (CGFloat y = -self.image.size.width; y < self.image.size.height + self.image.size.width; y += 150.0) {
                    for (CGFloat x = -self.image.size.height; x < self.image.size.width + self.image.size.height; x += stepX) {
                        [watermark drawAtPoint:CGPointMake(x, y) withAttributes:attributes];
                    }
                }
                CGContextRestoreGState(rendererContext.CGContext);
            } else {
                CGFloat x = watermarkStyle == 1 ? (self.image.size.width - textSize.width) * 0.5 : self.image.size.width - textSize.width - 14.0;
                CGFloat y = watermarkStyle == 1 ? (self.image.size.height - textSize.height) * 0.5 : self.image.size.height - textSize.height - 14.0 - (metadata.count > 0 ? 28.0 : 0.0);
                [watermark drawAtPoint:CGPointMake(MAX(10.0, x), MAX(10.0, y)) withAttributes:attributes];
            }
        }

        if (metadata.count > 0) {
            NSString *text = [metadata componentsJoinedByString:@"  ·  "];
            NSDictionary *attributes = [self watermarkAttributesWithSize:13.0 opacity:0.62];
            CGSize size = [text sizeWithAttributes:attributes];
            [text drawAtPoint:CGPointMake(12.0, MAX(8.0, self.image.size.height - size.height - 12.0)) withAttributes:attributes];
        }
    }];
}

@end

@interface NeoWCChatCaptureSession : NSObject
@property (nonatomic, weak) UIViewController *controller;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSIndexPath *> *indexPaths;
@property (nonatomic, strong) NSMutableArray<UIImage *> *cellImages;
@property (nonatomic, assign) CGPoint originalOffset;
@property (nonatomic, assign) CGFloat originalDistanceFromBottom;
@property (nonatomic, assign) BOOL originallyAtBottom;
@property (nonatomic, strong) UIView *loadingOverlay;
@property (nonatomic, strong) UILabel *loadingLabel;
@property (nonatomic, strong) UIImage *headerImage;
@property (nonatomic, strong) UIImage *footerImage;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, assign) NSUInteger captureIndex;
- (instancetype)initWithController:(UIViewController *)controller;
- (void)start;
- (void)captureNextCell;
- (void)finish;
- (void)restoreInterface;
@end

@implementation NeoWCChatCaptureSession

- (instancetype)initWithController:(UIViewController *)controller {
    self = [super init];
    if (self) {
        _controller = controller;
        _cellImages = [NSMutableArray array];
    }
    return self;
}

- (void)showError:(NSString *)message {
    [self restoreInterface];
    UIViewController *controller = self.controller;
    if (!controller) return;
    objc_setAssociatedObject(controller, &NeoWCActiveChatCaptureKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"无法生成长截图" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [controller presentViewController:alert animated:YES completion:nil];
}

- (NSArray<NSIndexPath *> *)selectedIndexPaths {
    id selected = NeoWCCallObject(self.controller, NSSelectorFromString(@"getSelectedMsgs"));
    if (!selected || ![selected conformsToProtocol:@protocol(NSFastEnumeration)] || ![selected respondsToSelector:@selector(count)] || [selected count] == 0) return @[];

    NSMutableSet<NSNumber *> *localIDs = [NSMutableSet setWithCapacity:[selected count]];
    for (id wrap in selected) {
        NSNumber *localID = NeoWCSafeValue(wrap, @"m_uiMesLocalID");
        if ([localID respondsToSelector:@selector(unsignedIntValue)]) [localIDs addObject:@([localID unsignedIntValue])];
    }

    id nodes = NeoWCCallObject(self.controller, NSSelectorFromString(@"getArrMessageNodeData"));
    if (![nodes isKindOfClass:[NSArray class]]) nodes = NeoWCSafeValue(self.controller, @"m_arrMessageNodeData");
    if (![nodes isKindOfClass:[NSArray class]]) return @[];

    NSMutableArray<NSIndexPath *> *paths = [NSMutableArray array];
    NSInteger sectionCount = [self.tableView numberOfSections];
    [(NSArray *)nodes enumerateObjectsUsingBlock:^(id node, NSUInteger section, BOOL *stop) {
        if ((NSInteger)section >= sectionCount) { *stop = YES; return; }
        id wrap = NeoWCCallObject(node, NSSelectorFromString(@"messageWrap"));
        if (!wrap) wrap = NeoWCSafeValue(node, @"messageWrap");
        NSNumber *localID = NeoWCSafeValue(wrap, @"m_uiMesLocalID");
        if (![localID respondsToSelector:@selector(unsignedIntValue)] || ![localIDs containsObject:@([localID unsignedIntValue])]) return;
        NSInteger rows = [self.tableView numberOfRowsInSection:(NSInteger)section];
        for (NSInteger row = 0; row < rows; row++) [paths addObject:[NSIndexPath indexPathForRow:row inSection:(NSInteger)section]];
    }];
    return paths;
}

- (void)installLoadingOverlay {
    UIView *host = self.controller.view;
    UIView *overlay = [UIView new];
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    overlay.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.82];
    overlay.userInteractionEnabled = YES;
    [host addSubview:overlay];

    UIView *card = [UIView new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 18.0;
    card.layer.shadowColor = UIColor.blackColor.CGColor;
    card.layer.shadowOpacity = 0.18;
    card.layer.shadowRadius = 18.0;
    card.layer.shadowOffset = CGSizeMake(0.0, 8.0);
    [overlay addSubview:card];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [spinner startAnimating];
    [card addSubview:spinner];

    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"截图生成中";
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.textColor = [UIColor labelColor];
    [card addSubview:label];
    self.loadingLabel = label;
    self.loadingOverlay = overlay;

    [NSLayoutConstraint activateConstraints:@[
        [overlay.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
        [overlay.topAnchor constraintEqualToAnchor:host.topAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:host.bottomAnchor],
        [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [spinner.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20.0],
        [spinner.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [label.leadingAnchor constraintEqualToAnchor:spinner.trailingAnchor constant:12.0],
        [label.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20.0],
        [label.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [label.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
    ]];
}

- (void)prepareChrome {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id includeChromeValue = [defaults objectForKey:NeoWCChatCaptureIncludeChromeKey];
    BOOL includeChrome = includeChromeValue ? [includeChromeValue boolValue] : YES;
    if (includeChrome) {
        UINavigationBar *bar = self.controller.navigationController.navigationBar;
        if (bar && !bar.hidden && CGRectGetHeight(bar.bounds) > 0.0) {
            UIView *navigationView = self.controller.navigationController.view;
            CGRect barRect = [bar convertRect:bar.bounds toView:navigationView];
            self.headerImage = NeoWCSnapshotRectInView(navigationView, barRect);
            if (!self.headerImage) self.headerImage = NeoWCSnapshotView(bar, bar.bounds.size);
        }
        UIView *toolView = NeoWCCallObject(self.controller, NSSelectorFromString(@"getInputToolView"));
        if (![toolView isKindOfClass:[UIView class]]) toolView = NeoWCSafeValue(self.controller, @"_inputToolView");
        if (![toolView isKindOfClass:[UIView class]]) toolView = NeoWCSafeValue(self.controller, @"m_inputToolView");
        if ([toolView isKindOfClass:[UIView class]]) {
            CGFloat toolHeight = CGRectGetHeight(toolView.bounds);
            CGFloat toolWidth = CGRectGetWidth(toolView.bounds);
            UIView *captureView = toolHeight >= 36.0 && toolHeight <= 180.0 && toolWidth >= CGRectGetWidth(self.controller.view.bounds) * 0.65 ? toolView : nil;
            if (!captureView) {
                CGFloat score = -CGFLOAT_MAX;
                NeoWCFindBottomToolbar(toolView, self.controller.view, &captureView, &score);
            }
            if (captureView && CGRectGetHeight(captureView.bounds) <= 180.0) {
                UIColor *footerBackground = captureView.backgroundColor;
                if (!footerBackground || CGColorGetAlpha(footerBackground.CGColor) < 0.05) footerBackground = captureView.superview.backgroundColor;
                if (!footerBackground || CGColorGetAlpha(footerBackground.CGColor) < 0.05) footerBackground = self.controller.view.backgroundColor;
                self.footerImage = NeoWCSnapshotFlatFooterView(captureView, footerBackground);
            }
        }
    }
    id showBackgroundValue = [defaults objectForKey:NeoWCChatCaptureShowBackgroundKey];
    BOOL showBackground = showBackgroundValue ? [showBackgroundValue boolValue] : YES;
    if (showBackground) {
        UIView *background = NeoWCSafeValue(self.controller, @"m_backgroundView");
        if ([background isKindOfClass:[UIView class]]) self.backgroundImage = NeoWCSnapshotView(background, background.bounds.size);
    }
}

- (void)start {
    id table = NeoWCCallObject(self.controller, NSSelectorFromString(@"getTableView"));
    if (![table isKindOfClass:[UITableView class]]) table = NeoWCSafeValue(self.controller, @"m_tableView");
    if (![table isKindOfClass:[UITableView class]]) {
        [self showError:@"当前微信版本没有找到聊天列表。"];
        return;
    }
    self.tableView = table;
    self.indexPaths = [self selectedIndexPaths];
    if (self.indexPaths.count == 0) {
        [self showError:@"请先在聊天中选择至少一条消息。"];
        return;
    }
    self.originalOffset = self.tableView.contentOffset;
    UIEdgeInsets originalInset = self.tableView.adjustedContentInset;
    CGFloat originalMinimumOffsetY = -originalInset.top;
    CGFloat originalMaximumOffsetY = MAX(originalMinimumOffsetY, self.tableView.contentSize.height - CGRectGetHeight(self.tableView.bounds) + originalInset.bottom);
    self.originalDistanceFromBottom = MAX(0.0, originalMaximumOffsetY - self.originalOffset.y);
    self.originallyAtBottom = self.originalDistanceFromBottom <= 80.0;
    [self installLoadingOverlay];
    NeoWCCallVoid(self.controller, NSSelectorFromString(@"exitMultiSelectMode"));
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.controller.view layoutIfNeeded];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.controller.view layoutIfNeeded];
            [weakSelf prepareChrome];
            [weakSelf captureNextCell];
        });
    });
}

- (void)captureNextCell {
    if (self.captureIndex >= self.indexPaths.count) {
        [self finish];
        return;
    }
    NSIndexPath *path = self.indexPaths[self.captureIndex];
    self.loadingLabel.text = [NSString stringWithFormat:@"正在截取 %lu / %lu", (unsigned long)(self.captureIndex + 1), (unsigned long)self.indexPaths.count];
    [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    [self.tableView layoutIfNeeded];

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    if (!cell) {
        [self showError:@"有一条消息无法渲染，请缩短选择范围后重试。"];
        return;
    }
    CGFloat height = CGRectGetHeight([self.tableView rectForRowAtIndexPath:path]);
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    if (height <= 0.0) height = CGRectGetHeight(cell.bounds);

    NSMutableArray<UIView *> *nameLabels = [NSMutableArray array];
    NSMutableArray<NSNumber *> *hiddenStates = [NSMutableArray array];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:NeoWCChatCaptureHideMemberNamesKey]) {
        NeoWCCollectNameLabels(cell, nameLabels);
        for (UIView *label in nameLabels) {
            [hiddenStates addObject:@(label.hidden)];
            label.hidden = YES;
        }
    }
    [cell layoutIfNeeded];
    UIImage *image = NeoWCSnapshotLayerView(cell, CGSizeMake(width, height));
    if (!image) image = NeoWCSnapshotView(cell, CGSizeMake(width, height));
    [nameLabels enumerateObjectsUsingBlock:^(UIView *label, NSUInteger index, __unused BOOL *stop) {
        label.hidden = hiddenStates[index].boolValue;
    }];
    if (image) [self.cellImages addObject:image];
    self.captureIndex += 1;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf captureNextCell]; });
}

- (UIImage *)composeImage {
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    CGFloat crop = MAX(0.0, [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCChatCaptureCropTopPointsKey]);
    CGFloat headerHeight = self.headerImage ? MAX(0.0, self.headerImage.size.height - crop) : 0.0;
    CGFloat footerHeight = self.footerImage.size.height;
    CGFloat bodyHeight = 0.0;
    for (UIImage *image in self.cellImages) bodyHeight += image.size.height;
    CGFloat totalHeight = headerHeight + bodyHeight + footerHeight;
    if (width <= 0.0 || totalHeight <= 0.0 || totalHeight > 30000.0) return nil;

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = YES;
    CGFloat nativeScale = MAX(1.0, UIScreen.mainScreen.scale);
    CGFloat maximumScaleForDimension = 32760.0 / MAX(width, totalHeight);
    format.scale = MIN(nativeScale, MAX(1.0, maximumScaleForDimension));
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(width, totalHeight) format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [[UIColor systemBackgroundColor] setFill];
        CGContextFillRect(context.CGContext, CGRectMake(0.0, 0.0, width, totalHeight));
        CGFloat y = 0.0;
        if (self.headerImage) {
            [self.headerImage drawInRect:CGRectMake(0.0, -crop, width, self.headerImage.size.height)];
            y += headerHeight;
        }
        if (self.backgroundImage && bodyHeight > 0.0) {
            [self.backgroundImage drawInRect:CGRectMake(0.0, y, width, bodyHeight)];
        }
        for (UIImage *image in self.cellImages) {
            [image drawInRect:CGRectMake(0.0, y, width, image.size.height)];
            y += image.size.height;
        }
        if (self.footerImage) [self.footerImage drawInRect:CGRectMake(0.0, y, width, footerHeight)];
    }];
}

- (void)restoreInterface {
    if (self.tableView) {
        [self.tableView layoutIfNeeded];
        UIEdgeInsets inset = self.tableView.adjustedContentInset;
        CGFloat minimumOffsetY = -inset.top;
        CGFloat maximumOffsetY = MAX(minimumOffsetY, self.tableView.contentSize.height - CGRectGetHeight(self.tableView.bounds) + inset.bottom);
        CGFloat targetOffsetY = self.originallyAtBottom ? maximumOffsetY : maximumOffsetY - self.originalDistanceFromBottom;
        targetOffsetY = MIN(maximumOffsetY, MAX(minimumOffsetY, targetOffsetY));
        [self.tableView setContentOffset:CGPointMake(self.originalOffset.x, targetOffsetY) animated:NO];
        [self.tableView layoutIfNeeded];
    }
    [self.loadingOverlay removeFromSuperview];
    self.loadingOverlay = nil;
}

- (void)finish {
    UIImage *image = [self composeImage];
    UIViewController *controller = self.controller;
    if (!controller) return;
    if (!image) {
        [self showError:@"截图过长或没有可用画面，请减少选择的消息数量。"];
        return;
    }
    NSString *chatName = controller.navigationItem.title ?: controller.title;
    if (chatName.length == 0) chatName = NeoWCFirstLabelText(controller.navigationItem.titleView);
    NeoWCChatCapturePreviewViewController *preview = [[NeoWCChatCapturePreviewViewController alloc] initWithImage:image chatName:chatName sourceController:controller];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:preview];
    navigation.modalPresentationStyle = UIModalPresentationFullScreen;
    self.loadingLabel.text = @"生成完成";
    [self.loadingOverlay layoutIfNeeded];
    [UIView animateWithDuration:0.20
                          delay:0.06
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.loadingOverlay.alpha = 0.0;
    } completion:^(__unused BOOL finished) {
        [self restoreInterface];
        objc_setAssociatedObject(controller, &NeoWCActiveChatCaptureKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [controller presentViewController:navigation animated:YES completion:nil];
    }];
}

@end

void NeoWCStartChatCapture(UIViewController *controller) {
    if (!controller || !NeoWCEnhancementEnabled(NeoWCChatCaptureEnabledKey)) return;
    if (objc_getAssociatedObject(controller, &NeoWCActiveChatCaptureKey)) return;
    NeoWCChatCaptureSession *session = [[NeoWCChatCaptureSession alloc] initWithController:controller];
    objc_setAssociatedObject(controller, &NeoWCActiveChatCaptureKey, session, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    dispatch_async(dispatch_get_main_queue(), ^{
        [session start];
    });
}

@interface NeoWCChatCaptureSettingsViewController ()
@property (nonatomic, copy) NSArray<NSDictionary *> *rows;
- (void)optionChanged:(UISwitch *)sender;
- (void)watermarkStyleChanged:(UISegmentedControl *)sender;
- (void)watermarkOpacityChanged:(UISlider *)sender;
- (void)presentCropEditor;
- (void)presentWatermarkEditor;
@end

@implementation NeoWCChatCaptureSettingsViewController

- (instancetype)init {
    return [self initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"长截图设置";
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.rows = @[
        @{ @"title": @"包含聊天顶栏与输入栏", @"subtitle": @"在长图首尾保留当前聊天界面", @"key": NeoWCChatCaptureIncludeChromeKey },
        @{ @"title": @"隐藏群成员昵称", @"subtitle": @"截图时隐藏消息气泡上方昵称", @"key": NeoWCChatCaptureHideMemberNamesKey },
        @{ @"title": @"使用聊天背景", @"subtitle": @"将当前聊天背景铺到长图中", @"key": NeoWCChatCaptureShowBackgroundKey },
        @{ @"title": @"分享后关闭预览", @"subtitle": @"系统分享成功后自动返回聊天", @"key": NeoWCChatCaptureCloseAfterShareKey },
        @{ @"title": @"显示聊天对象名称", @"subtitle": @"从当前聊天标题读取，获取失败时自动忽略", @"key": NeoWCChatCaptureShowChatNameKey },
        @{ @"title": @"显示生成时间", @"subtitle": @"在长图底部添加生成时间", @"key": NeoWCChatCaptureShowTimestampKey },
    ];
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView { return 2; }

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.rows.count : 4;
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == 0 ? @"这些选项只在生成截图时读取，不会持续修改聊天界面。" : @"水印、名称与时间在预览和最终导出图片中显示。";
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"截图内容" : @"标记与水印";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"capture-setting"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"capture-setting"];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    if (indexPath.section == 0) {
        NSDictionary *row = self.rows[indexPath.row];
        cell.textLabel.text = row[@"title"];
        cell.detailTextLabel.text = row[@"subtitle"];
        cell.accessoryType = UITableViewCellAccessoryNone;
        UISwitch *toggle = [UISwitch new];
        toggle.onTintColor = [UIColor systemBlueColor];
        toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:row[@"key"]];
        toggle.tag = indexPath.row;
        [toggle addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (indexPath.row == 0) {
        CGFloat points = [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCChatCaptureCropTopPointsKey];
        cell.textLabel.text = @"顶部裁切";
        cell.detailTextLabel.text = @"去除顶栏顶部多余区域";
        UILabel *value = [UILabel new];
        value.text = [NSString stringWithFormat:@"%.0f pt", points];
        value.textColor = [UIColor secondaryLabelColor];
        [value sizeToFit];
        cell.accessoryView = value;
    } else if (indexPath.row == 1) {
        NSString *watermark = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCChatCaptureWatermarkTextKey];
        cell.textLabel.text = @"自定义水印";
        cell.detailTextLabel.text = watermark.length > 0 ? watermark : @"未设置";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"水印样式";
        cell.detailTextLabel.text = @"选择位置或平铺";
        UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"底部", @"居中", @"平铺"]];
        control.selectedSegmentIndex = MIN(2, MAX(0, [[NSUserDefaults standardUserDefaults] integerForKey:NeoWCChatCaptureWatermarkStyleKey]));
        [control addTarget:self action:@selector(watermarkStyleChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = control;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        cell.textLabel.text = @"水印透明度";
        cell.detailTextLabel.text = @"越低越淡";
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 130.0, 32.0)];
        slider.minimumValue = 0.05f;
        slider.maximumValue = 0.60f;
        CGFloat opacity = [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCChatCaptureWatermarkOpacityKey];
        slider.value = opacity > 0.0 ? opacity : 0.18f;
        [slider addTarget:self action:@selector(watermarkOpacityChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = slider;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void)optionChanged:(UISwitch *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)self.rows.count) return;
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:self.rows[sender.tag][@"key"]];
}

- (void)watermarkStyleChanged:(UISegmentedControl *)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:sender.selectedSegmentIndex forKey:NeoWCChatCaptureWatermarkStyleKey];
}

- (void)watermarkOpacityChanged:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults] setDouble:sender.value forKey:NeoWCChatCaptureWatermarkOpacityKey];
}

- (void)presentCropEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"顶部裁切" message:@"输入 0–200 pt，默认 0。" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.text = [NSString stringWithFormat:@"%.0f", [[NSUserDefaults standardUserDefaults] doubleForKey:NeoWCChatCaptureCropTopPointsKey]];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        CGFloat points = MIN(200.0, MAX(0.0, alert.textFields.firstObject.text.doubleValue));
        [[NSUserDefaults standardUserDefaults] setDouble:points forKey:NeoWCChatCaptureCropTopPointsKey];
        [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentWatermarkEditor {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"自定义水印" message:@"留空即可关闭自定义水印。" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCChatCaptureWatermarkTextKey];
        textField.placeholder = @"例如：NeoWC";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length > 0) [[NSUserDefaults standardUserDefaults] setObject:text forKey:NeoWCChatCaptureWatermarkTextKey];
        else [[NSUserDefaults standardUserDefaults] removeObjectForKey:NeoWCChatCaptureWatermarkTextKey];
        [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 1) return;
    if (indexPath.row == 0) [self presentCropEditor];
    else if (indexPath.row == 1) [self presentWatermarkEditor];
}

@end
