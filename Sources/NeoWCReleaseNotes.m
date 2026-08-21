#import "NeoWCReleaseNotes.h"
#import "NeoWCSettingsCatalog.h"

static NSString *const NeoWCLastShownReleaseNotesVersionKey = @"com.qiu7c.neowc.ui.last-shown-release-notes-version";

@interface NeoWCReleaseNoteItem ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *detail;
@end

@implementation NeoWCReleaseNoteItem

+ (instancetype)itemWithTitle:(NSString *)title detail:(NSString *)detail {
    NeoWCReleaseNoteItem *item = [self new];
    item.title = title;
    item.detail = detail;
    return item;
}

@end

@interface NeoWCReleaseNote ()
@property (nonatomic, copy, readwrite) NSString *version;
@property (nonatomic, copy, readwrite) NSString *headline;
@property (nonatomic, copy, readwrite) NSArray<NeoWCReleaseNoteItem *> *items;
@end

@implementation NeoWCReleaseNote

+ (instancetype)noteWithVersion:(NSString *)version
                       headline:(NSString *)headline
                          items:(NSArray<NeoWCReleaseNoteItem *> *)items {
    NeoWCReleaseNote *note = [self new];
    note.version = version;
    note.headline = headline;
    note.items = items;
    return note;
}

@end

NSArray<NeoWCReleaseNote *> *NeoWCReleaseNotes(void) {
    static NSArray<NeoWCReleaseNote *> *notes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notes = @[
            [NeoWCReleaseNote noteWithVersion:NeoWCDisplayVersion
                                     headline:@"朋友圈、交互与流畅度全面升级"
                                        items:@[
                [NeoWCReleaseNoteItem itemWithTitle:@"朋友圈高清发布"
                                              detail:@"新增高清图片和原视频入口，减少发布过程中的画质损失。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"保存朋友圈媒体"
                                              detail:@"支持保存朋友圈图片、视频和实况照片，并提供保存结果提示。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"锁定屏幕刷新率"
                                              detail:@"前台锁定为设备支持的最高刷新率，120 Hz 与 60 Hz 屏幕分别使用对应上限。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"主页右滑扩展"
                                              detail:@"增加备注、朋友圈、折叠群聊、勿扰和置顶等快捷操作。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"流畅度与手势优化"
                                              detail:@"减少多处卡顿，并解决消息手势与页面返回手势之间的冲突。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"编辑图片快捷发送"
                                              detail:@"优化图片和当前会话识别，编辑后可通过确认页发送到当前聊天。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"语音转发"
                                              detail:@"在语音长按菜单中新增转发入口，补齐语音消息转发流程。"],
            ]],
        ];
    });
    return notes;
}

BOOL NeoWCShouldPresentCurrentReleaseNotes(void) {
    NSString *shownVersion = [NSUserDefaults.standardUserDefaults stringForKey:NeoWCLastShownReleaseNotesVersionKey];
    return ![shownVersion isEqualToString:NeoWCDisplayVersion];
}

void NeoWCMarkCurrentReleaseNotesPresented(void) {
    [NSUserDefaults.standardUserDefaults setObject:NeoWCDisplayVersion forKey:NeoWCLastShownReleaseNotesVersionKey];
}

@interface NeoWCReleaseNotesViewController ()
@property (nonatomic, strong) UIControl *backdropView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, assign) BOOL appeared;
@property (nonatomic, assign) BOOL closing;
@end

@implementation NeoWCReleaseNotesViewController

- (instancetype)init {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color lines:(NSInteger)lines {
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    label.adjustsFontForContentSizeCategory = YES;
    return label;
}

- (UIView *)releaseRowForItem:(NeoWCReleaseNoteItem *)item {
    UIView *row = [UIView new];
    row.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *titleLabel = [self labelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                       color:UIColor.labelColor
                                       lines:0];
    titleLabel.text = item.title;
    titleLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody]
        scaledFontForFont:[UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold]];
    UILabel *detailLabel = [self labelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]
                                        color:UIColor.secondaryLabelColor
                                        lines:0];
    detailLabel.text = item.detail;
    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, detailLabel]];
    textStack.translatesAutoresizingMaskIntoConstraints = NO;
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.alignment = UIStackViewAlignmentFill;
    textStack.spacing = 3.0;

    [row addSubview:textStack];
    [NSLayoutConstraint activateConstraints:@[
        [textStack.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [textStack.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
        [textStack.topAnchor constraintEqualToAnchor:row.topAnchor],
        [textStack.bottomAnchor constraintEqualToAnchor:row.bottomAnchor],
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:44.0],
    ]];
    return row;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;

    self.backdropView = [UIControl new];
    self.backdropView.translatesAutoresizingMaskIntoConstraints = NO;
    self.backdropView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.16];
    [self.backdropView addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backdropView];

    self.cardView = [UIView new];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.backgroundColor = UIColor.clearColor;
    self.cardView.layer.cornerRadius = 28.0;
    self.cardView.layer.cornerCurve = kCACornerCurveContinuous;
    self.cardView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.cardView.layer.shadowOpacity = 0.08;
    self.cardView.layer.shadowRadius = 18.0;
    self.cardView.layer.shadowOffset = CGSizeMake(0.0, 6.0);
    [self.view addSubview:self.cardView];

    UIVisualEffectView *materialView = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]];
    materialView.translatesAutoresizingMaskIntoConstraints = NO;
    materialView.userInteractionEnabled = NO;
    materialView.clipsToBounds = YES;
    materialView.layer.cornerRadius = 28.0;
    materialView.layer.cornerCurve = kCACornerCurveContinuous;
    [self.cardView addSubview:materialView];

    NeoWCReleaseNote *note = NeoWCReleaseNotes().firstObject;

    UILabel *titleLabel = [self labelWithFont:[[UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle2]
                                                scaledFontForFont:[UIFont systemFontOfSize:22.0 weight:UIFontWeightBold]]
                                       color:UIColor.labelColor
                                       lines:1];
    titleLabel.text = @"NeoWC 更新";
    UILabel *headlineLabel = [self labelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                          color:UIColor.secondaryLabelColor
                                          lines:0];
    headlineLabel.text = note.headline;
    UIStackView *headingStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, headlineLabel]];
    headingStack.translatesAutoresizingMaskIntoConstraints = NO;
    headingStack.axis = UILayoutConstraintAxisVertical;
    headingStack.spacing = 2.0;

    UILabel *versionLabel = [self labelWithFont:[[UIFontMetrics metricsForTextStyle:UIFontTextStyleCaption1]
                                                  scaledFontForFont:[UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold]]
                                         color:UIColor.systemBlueColor
                                         lines:1];
    versionLabel.text = [NSString stringWithFormat:@"V %@", note.version];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.12];
    versionLabel.layer.cornerRadius = 9.0;
    versionLabel.layer.cornerCurve = kCACornerCurveContinuous;
    versionLabel.layer.masksToBounds = YES;

    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton setTitle:@"关闭" forState:UIControlStateNormal];
    closeButton.titleLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleFootnote]
        scaledFontForFont:[UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold]];
    closeButton.tintColor = UIColor.tertiaryLabelColor;
    closeButton.accessibilityLabel = @"关闭更新日志";
    [closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];

    UIScrollView *scrollView = [UIScrollView new];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.alwaysBounceVertical = NO;
    scrollView.showsVerticalScrollIndicator = YES;
    UIStackView *itemsStack = [UIStackView new];
    itemsStack.translatesAutoresizingMaskIntoConstraints = NO;
    itemsStack.axis = UILayoutConstraintAxisVertical;
    itemsStack.alignment = UIStackViewAlignmentFill;
    itemsStack.spacing = 14.0;
    for (NeoWCReleaseNoteItem *item in note.items) [itemsStack addArrangedSubview:[self releaseRowForItem:item]];
    [scrollView addSubview:itemsStack];

    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    doneButton.backgroundColor = UIColor.systemBlueColor;
    doneButton.tintColor = UIColor.whiteColor;
    doneButton.titleLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleHeadline]
        scaledFontForFont:[UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold]];
    [doneButton setTitle:@"开始使用" forState:UIControlStateNormal];
    doneButton.layer.cornerRadius = 15.0;
    doneButton.layer.cornerCurve = kCACornerCurveContinuous;
    [doneButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.cardView addSubview:headingStack];
    [self.cardView addSubview:versionLabel];
    [self.cardView addSubview:closeButton];
    [self.cardView addSubview:scrollView];
    [self.cardView addSubview:doneButton];

    NSLayoutConstraint *preferredCardWidth = [self.cardView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-36.0];
    preferredCardWidth.priority = UILayoutPriorityDefaultHigh;
    NSLayoutConstraint *preferredScrollHeight = [scrollView.heightAnchor constraintEqualToConstant:420.0];
    preferredScrollHeight.priority = UILayoutPriorityDefaultHigh;
    [NSLayoutConstraint activateConstraints:@[
        [self.backdropView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backdropView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backdropView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backdropView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [materialView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
        [materialView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
        [materialView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
        [materialView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],
        [self.cardView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.cardView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.cardView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:18.0],
        [self.cardView.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-18.0],
        [self.cardView.widthAnchor constraintLessThanOrEqualToConstant:430.0],
        preferredCardWidth,
        [self.cardView.topAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:18.0],
        [self.cardView.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-18.0],
        [headingStack.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:22.0],
        [headingStack.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:22.0],
        [headingStack.trailingAnchor constraintLessThanOrEqualToAnchor:closeButton.leadingAnchor constant:-8.0],
        [closeButton.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:17.0],
        [closeButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-17.0],
        [closeButton.widthAnchor constraintEqualToConstant:44.0],
        [closeButton.heightAnchor constraintEqualToConstant:34.0],
        [versionLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:22.0],
        [versionLabel.topAnchor constraintEqualToAnchor:headingStack.bottomAnchor constant:14.0],
        [versionLabel.widthAnchor constraintGreaterThanOrEqualToConstant:62.0],
        [versionLabel.heightAnchor constraintEqualToConstant:26.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:22.0],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-22.0],
        [scrollView.topAnchor constraintEqualToAnchor:versionLabel.bottomAnchor constant:16.0],
        [scrollView.heightAnchor constraintGreaterThanOrEqualToConstant:160.0],
        [scrollView.heightAnchor constraintLessThanOrEqualToConstant:420.0],
        preferredScrollHeight,
        [itemsStack.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [itemsStack.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [itemsStack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [itemsStack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [itemsStack.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],
        [doneButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:22.0],
        [doneButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-22.0],
        [doneButton.topAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:18.0],
        [doneButton.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-20.0],
        [doneButton.heightAnchor constraintEqualToConstant:50.0],
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.appeared) return;
    self.backdropView.alpha = 0.0;
    self.cardView.alpha = 0.0;
    self.cardView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.94, 0.94),
                                                       CGAffineTransformMakeTranslation(0.0, 18.0));
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.appeared) return;
    self.appeared = YES;
    NSTimeInterval duration = UIAccessibilityIsReduceMotionEnabled() ? 0.01 : 0.34;
    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:0.86
          initialSpringVelocity:0.25
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.backdropView.alpha = 1.0;
        self.cardView.alpha = 1.0;
        self.cardView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)closeTapped {
    if (self.closing || self.isBeingDismissed) return;
    self.closing = YES;
    NSTimeInterval duration = UIAccessibilityIsReduceMotionEnabled() ? 0.01 : 0.2;
    [UIView animateWithDuration:duration animations:^{
        self.backdropView.alpha = 0.0;
        self.cardView.alpha = 0.0;
        self.cardView.transform = CGAffineTransformMakeScale(0.97, 0.97);
    } completion:^(__unused BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

@end
