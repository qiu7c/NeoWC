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
            [NeoWCReleaseNote noteWithVersion:@"0.1.7"
                                     headline:@"通知、胶囊顶栏、好友检测与消息库重构"
                                        items:@[
                [NeoWCReleaseNoteItem itemWithTitle:@"检测单删好友"
                                               detail:@"复用微信支付转账前置校验，按好友串行检测并随机等待；选择页支持全选和反选，检测时显示当前好友、完成进度、正常、疑似单删和待复查数量，并支持暂停、后台保护、断点恢复和结果复检。修复兼容判断导致请求未发出却立即显示完成的问题；网络与解析异常不会误判为单删。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"微信风格应用内通知"
                                               detail:@"朋友圈特别关注、点赞和评论在微信前台使用非阻塞横幅提醒；支持自定义左侧图标、56–90 pt 高度和背景模糊度，并复用于自动登录与游戏授权结果提示。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"聊天胶囊顶栏"
                                               detail:@"隐藏微信整条顶栏背景，左右按钮改为独立玻璃胶囊；本次更新统一迁移为伪液态与 20% 强度，之后仍可自行调整。置顶消息独立锁定磨砂玻璃并严格裁入固定胶囊边界，同时修复返回手势、前后台切换、头像缩放偏移及展开时的背景溢出。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"原生聊天记录搜索"
                                               detail:@"从聊天顶栏进入微信原生 MsgSearchHelper/WCSearcher 搜索链路，使用官方结果页；补齐取消、返回按钮、右滑退出和搜索框清理，减少残留顶栏与重复退出。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"非好友资料与精确添加时间"
                                               detail:@"非好友详细资料页增加共同群聊，并可进入对应群聊列表；好友添加时间改用微信详细资料来源，显示更完整的精确时间。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"群成员历史聊天记录"
                                               detail:@"在群聊中通过头像快捷手势打开指定成员的历史聊天记录，直接查看该成员在当前群里的既往消息。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"移出群成员"
                                               detail:@"头像快捷菜单增加移出群聊操作；自己邀请入群的成员可直接移出，其他成员继续遵循微信原生群管理权限。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"消息库真实存储"
                                               detail:@"快捷回复改为直接枚举 Documents 中的真实分类目录和条目文件，搜索索引仅作为可重建缓存；旧版数据首次无损迁移。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"通话自动免提"
                                               detail:@"新增独立开关，在微信通话音频设备启动并确认处于语音模式后自动切换扬声器；保留微信原始启动顺序。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"插件入口与分类样式"
                                               detail:@"插件管理分类切换改为内容自适应胶囊，缩短无效留白；升级时自动清理旧版 NeoWC 调试快捷入口，同时保留其他插件、自定义分类、排序和快捷开关。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"媒体菜单与深色模式修复"
                                               detail:@"音频文件转语音只对真实可转换音频显示，避免所有文件误出现入口；防撤回预览在深色模式使用黑色背景，并修复多处通知、模糊动画和界面生命周期问题。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"移除未稳定的加密发送"
                                               detail:@"完整移除实验性的文字密文、图片和视频加密发送、解密预览及相关设置，恢复微信原生相册选择、预览和发送链路；该功能将在重新验证兼容性后再设计。"],
            ]],
            [NeoWCReleaseNote noteWithVersion:@"0.1.6"
                                     headline:@"朋友圈提醒、设置重组与稳定性更新"
                                        items:@[
                [NeoWCReleaseNoteItem itemWithTitle:@"朋友圈特别关注提醒"
                                               detail:@"支持选择特别关注好友、调整检测间隔，并可把文字转发到自己的聊天框或文件传输助手；图片和视频按需单独开启。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"朋友圈互动提醒"
                                               detail:@"补充点赞和评论提醒、系统通知与进入朋友圈初始化；可关闭详细信息，仅显示收到新的评论或点赞。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"朋友圈评论防删除"
                                               detail:@"保留本次微信运行中已加载后被删除的评论，并支持调整删除标识文字、字号和颜色。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"好友与群聊信息卡片"
                                               detail:@"优化昵称、备注、原始账号、添加时间、添加天数和共同群聊顺序；共同群聊和群内好友支持进入对应页面与长按复制。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"快捷回复与媒体转语音修复"
                                               detail:@"加强素材持久化、导出、侧滑和面板布局，修正搜索框背景；补齐视频、音频文件和音乐卡片转语音菜单入口。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"设置重新分类"
                                               detail:@"按聊天、朋友圈、界面禁用、界面优化、常用增强和插件设置重新整理；日志与配置集中到插件设置，作者主页和历史更新记录保留在设置首页底部。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"精简用户版本"
                                               detail:@"开发调试工具迁移到独立 WCDebug，并自动清理 NeoWC 旧调试快捷入口；同时移除未开放的快捷收款链接、视频解析和音乐点歌代码。"],
            ]],
            [NeoWCReleaseNote noteWithVersion:@"0.1.5"
                                     headline:@"快捷回复与防误发"
                                        items:@[
                [NeoWCReleaseNoteItem itemWithTitle:@"快捷回复"
                                               detail:@"支持文字、图片、视频和语音消息，全账号共享，并提供备注、文件夹、搜索、置顶、自定义/最近使用/使用频率排序与清理；Silk 语音可按需解码预览。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"文件传输助手导入"
                                              detail:@"可通过单条长按或微信多选，把已下载的文字、图片、视频文件和语音加入消息库，并在导入时设置备注与文件夹。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"聊天页快捷入口"
                                               detail:@"长按聊天输入栏的加号打开快捷回复；可切换点击秒发送，点击与长按在四种消息上保持一致。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"指定会话发送前确认"
                                              detail:@"按好友和群聊分区显示头像并勾选受保护会话，发送按钮与已证实文字入口双层拦截，并在会话失效或进入后台时取消发送。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"朋友圈实况保存优化"
                                              detail:@"调整冷缓存下载完成后的媒体路径获取顺序，继续由微信原生实况配对流程保存。"],
            ]],
            [NeoWCReleaseNote noteWithVersion:@"0.1.4"
                                     headline:@"朋友圈、交互与流畅度全面升级"
                                        items:@[
                [NeoWCReleaseNoteItem itemWithTitle:@"朋友圈高清发布" detail:@"新增高清图片和原视频入口，减少发布过程中的画质损失。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"保存朋友圈媒体" detail:@"支持保存朋友圈图片、视频和实况照片，并提供保存结果提示。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"滑动屏幕高刷" detail:@"前台滑动时使用设备支持的最高刷新率，浏览更加顺滑。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"主页右滑扩展" detail:@"增加备注、朋友圈、折叠群聊、勿扰和置顶等快捷操作。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"流畅度与手势优化" detail:@"减少多处卡顿，并解决消息手势与页面返回手势之间的冲突。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"编辑图片快捷发送" detail:@"优化图片和当前会话识别，编辑后可通过确认页发送到当前聊天。"],
                [NeoWCReleaseNoteItem itemWithTitle:@"语音转发" detail:@"在语音长按菜单中新增转发入口，补齐语音消息转发流程。"],
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

@implementation NeoWCReleaseNotesHistoryViewController

- (instancetype)init {
    return [self initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"更新日志";
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 84.0;
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return NeoWCReleaseNotes().count;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return NeoWCReleaseNotes()[section].items.count;
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NeoWCReleaseNote *note = NeoWCReleaseNotes()[section];
    return [NSString stringWithFormat:@"V %@ · %@", note.version, note.headline];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NeoWCReleaseHistoryCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"NeoWCReleaseHistoryCell"];
    NeoWCReleaseNoteItem *item = NeoWCReleaseNotes()[indexPath.section].items[indexPath.row];
    cell.textLabel.text = item.title;
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.detailTextLabel.text = item.detail;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

@end

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
    self.cardView.layer.cornerRadius = 26.0;
    self.cardView.layer.cornerCurve = kCACornerCurveContinuous;
    self.cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.cardView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.cardView.layer.shadowOpacity = 0.12;
    self.cardView.layer.shadowRadius = 20.0;
    self.cardView.layer.shadowOffset = CGSizeMake(0.0, -4.0);
    [self.view addSubview:self.cardView];

    UIVisualEffectView *materialView = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]];
    materialView.translatesAutoresizingMaskIntoConstraints = NO;
    materialView.userInteractionEnabled = NO;
    materialView.clipsToBounds = YES;
    materialView.layer.cornerRadius = 26.0;
    materialView.layer.cornerCurve = kCACornerCurveContinuous;
    materialView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.cardView addSubview:materialView];

    UIView *grabberView = [UIView new];
    grabberView.translatesAutoresizingMaskIntoConstraints = NO;
    grabberView.backgroundColor = UIColor.tertiaryLabelColor;
    grabberView.layer.cornerRadius = 2.5;
    grabberView.userInteractionEnabled = NO;
    grabberView.accessibilityElementsHidden = YES;
    [self.cardView addSubview:grabberView];

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

    [NSLayoutConstraint activateConstraints:@[
        [self.backdropView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backdropView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backdropView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backdropView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [materialView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
        [materialView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
        [materialView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
        [materialView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],
        [self.cardView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.cardView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.cardView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.cardView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.58],
        [grabberView.centerXAnchor constraintEqualToAnchor:self.cardView.centerXAnchor],
        [grabberView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:10.0],
        [grabberView.widthAnchor constraintEqualToConstant:38.0],
        [grabberView.heightAnchor constraintEqualToConstant:5.0],
        [headingStack.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:22.0],
        [headingStack.topAnchor constraintEqualToAnchor:grabberView.bottomAnchor constant:12.0],
        [headingStack.trailingAnchor constraintLessThanOrEqualToAnchor:closeButton.leadingAnchor constant:-8.0],
        [closeButton.centerYAnchor constraintEqualToAnchor:headingStack.topAnchor constant:17.0],
        [closeButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-17.0],
        [closeButton.widthAnchor constraintEqualToConstant:44.0],
        [closeButton.heightAnchor constraintEqualToConstant:34.0],
        [versionLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:22.0],
        [versionLabel.topAnchor constraintEqualToAnchor:headingStack.bottomAnchor constant:14.0],
        [versionLabel.widthAnchor constraintGreaterThanOrEqualToConstant:62.0],
        [versionLabel.heightAnchor constraintEqualToConstant:26.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:22.0],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-22.0],
        [scrollView.topAnchor constraintEqualToAnchor:versionLabel.bottomAnchor constant:14.0],
        [scrollView.heightAnchor constraintGreaterThanOrEqualToConstant:72.0],
        [itemsStack.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [itemsStack.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [itemsStack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [itemsStack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [itemsStack.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],
        [doneButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:22.0],
        [doneButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-22.0],
        [doneButton.topAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:14.0],
        [doneButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12.0],
        [doneButton.heightAnchor constraintEqualToConstant:50.0],
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.appeared) return;
    self.backdropView.alpha = 0.0;
    self.cardView.transform = CGAffineTransformMakeTranslation(0.0, CGRectGetHeight(UIScreen.mainScreen.bounds));
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
        self.cardView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)closeTapped {
    if (self.closing || self.isBeingDismissed) return;
    self.closing = YES;
    NSTimeInterval duration = UIAccessibilityIsReduceMotionEnabled() ? 0.01 : 0.2;
    [UIView animateWithDuration:duration animations:^{
        self.backdropView.alpha = 0.0;
        self.cardView.transform = CGAffineTransformMakeTranslation(0.0, CGRectGetHeight(UIScreen.mainScreen.bounds));
    } completion:^(__unused BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

@end
