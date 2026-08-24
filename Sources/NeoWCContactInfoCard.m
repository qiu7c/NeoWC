#import "NeoWCContactInfoCard.h"
#import <QuartzCore/QuartzCore.h>

@interface NeoWCContactInfoCardViewController ()
@property (nonatomic, copy) NSString *cardTitle;
@property (nonatomic, strong, nullable) UIImage *avatar;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *rows;
@end

@implementation NeoWCContactInfoCardViewController

- (instancetype)initWithTitle:(NSString *)title
                       avatar:(UIImage *)avatar
                         name:(NSString *)name
                     userName:(NSString *)userName
                         rows:(NSArray<NSDictionary<NSString *,NSString *> *> *)rows {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _cardTitle = [title copy] ?: @"信息卡片";
        _avatar = avatar;
        _displayName = [name copy] ?: @"";
        _userName = [userName copy] ?: @"";
        _rows = [rows copy] ?: @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.cardTitle;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 20.0);

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds), 124.0)];
    header.backgroundColor = UIColor.clearColor;
    UIImageView *avatarView = [[UIImageView alloc] initWithImage:self.avatar ?: [UIImage systemImageNamed:@"person.crop.circle.fill"]];
    avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarView.tintColor = UIColor.tertiaryLabelColor;
    avatarView.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    avatarView.contentMode = UIViewContentModeScaleAspectFill;
    avatarView.layer.cornerRadius = 28.0;
    avatarView.layer.cornerCurve = kCACornerCurveContinuous;
    avatarView.clipsToBounds = YES;
    UILabel *nameLabel = [UILabel new];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = self.displayName.length ? self.displayName : self.userName;
    nameLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold];
    UILabel *idLabel = [UILabel new];
    idLabel.translatesAutoresizingMaskIntoConstraints = NO;
    idLabel.text = self.userName;
    idLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    idLabel.textColor = UIColor.secondaryLabelColor;
    idLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [header addSubview:avatarView];
    [header addSubview:nameLabel];
    [header addSubview:idLabel];
    [NSLayoutConstraint activateConstraints:@[
        [avatarView.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20.0],
        [avatarView.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [avatarView.widthAnchor constraintEqualToConstant:56.0],
        [avatarView.heightAnchor constraintEqualToConstant:56.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarView.trailingAnchor constant:14.0],
        [nameLabel.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20.0],
        [nameLabel.bottomAnchor constraintEqualToAnchor:header.centerYAnchor constant:-2.0],
        [idLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [idLabel.trailingAnchor constraintEqualToAnchor:nameLabel.trailingAnchor],
        [idLabel.topAnchor constraintEqualToAnchor:header.centerYAnchor constant:5.0],
    ]];
    self.tableView.tableHeaderView = header;
}

- (void)updateRows:(NSArray<NSDictionary<NSString *,NSString *> *> *)rows {
    self.rows = [rows copy] ?: @[];
    if (self.isViewLoaded) [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"NeoWCContactInfoCardCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    NSDictionary *row = self.rows[indexPath.row];
    cell.textLabel.text = row[@"title"] ?: @"";
    cell.detailTextLabel.text = row[@"value"] ?: @"";
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *value = self.rows[indexPath.row][@"value"];
    if (value.length == 0 || [value isEqualToString:@"暂无"]) return;
    UIPasteboard.generalPasteboard.string = value;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return @"点击任意一项可复制。资料仅在当前页面实时读取，不会另行上传。";
}

@end
