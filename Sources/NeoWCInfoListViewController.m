#import "NeoWCInfoListViewController.h"

@interface NeoWCInfoListViewController ()
@property (nonatomic, copy) NSString *listTitle;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *rows;
@end

@implementation NeoWCInfoListViewController

- (instancetype)initWithTitle:(NSString *)title
                         rows:(NSArray<NSDictionary<NSString *,NSString *> *> *)rows {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _listTitle = [title copy] ?: @"详细名单";
        _rows = [rows copy] ?: @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.listTitle;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.rowHeight = 58.0;
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 20.0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"NeoWCInfoListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    NSDictionary<NSString *, NSString *> *row = self.rows[indexPath.row];
    cell.textLabel.text = row[@"title"] ?: @"未知联系人";
    cell.detailTextLabel.text = row[@"value"] ?: @"";
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *value = self.rows[indexPath.row][@"value"];
    if (value.length > 0) UIPasteboard.generalPasteboard.string = value;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return [NSString stringWithFormat:@"共 %lu 项；点击可复制原始号码。", (unsigned long)self.rows.count];
}

@end
