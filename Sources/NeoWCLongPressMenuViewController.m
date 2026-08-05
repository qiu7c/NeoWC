#import "NeoWCLongPressMenuViewController.h"

#import "NeoWCEnhancements.h"

#import <objc/runtime.h>

static char NeoWCLongPressMenuTitleAssociationKey;

@interface NeoWCLongPressMenuViewController ()
@property (nonatomic, copy) NSArray<NSString *> *titles;
@end

@implementation NeoWCLongPressMenuViewController

- (instancetype)init { return [self initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"长按菜单";
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTitles)
                                                 name:NeoWCEnhancementDidChangeNotification
                                               object:nil];
    [self reloadTitles];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (void)reloadTitles {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray<NSString *> *known = [defaults arrayForKey:NeoWCLongPressMenuKnownTitlesKey] ?: @[];
    NSArray<NSString *> *preferred = [defaults arrayForKey:NeoWCLongPressMenuPreferredOrderKey] ?: @[];
    NSMutableArray<NSString *> *ordered = [NSMutableArray arrayWithCapacity:known.count];
    for (NSString *title in preferred) if ([known containsObject:title] && ![ordered containsObject:title]) [ordered addObject:title];
    for (NSString *title in known) if (![ordered containsObject:title]) [ordered addObject:title];
    self.titles = ordered;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.titles.count; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @"已自动发现"; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.titles.count > 0
        ? @"关闭“显示”可隐藏菜单项；点按可重命名，编辑状态下可拖动排序。"
        : @"请先在聊天中长按不同类型的消息，微信出现过的原生菜单项会自动加入这里。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"menu-item"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"menu-item"];
    NSString *sourceTitle = self.titles[indexPath.row];
    NSDictionary *mapping = [[NSUserDefaults standardUserDefaults] dictionaryForKey:NeoWCLongPressMenuTitleMapKey];
    NSString *renamedTitle = mapping[sourceTitle];
    cell.textLabel.text = renamedTitle.length > 0 ? renamedTitle : sourceTitle;
    cell.detailTextLabel.text = renamedTitle.length > 0 ? [@"原名称：" stringByAppendingString:sourceTitle] : @"微信原名称";
    UISwitch *toggle = [UISwitch new];
    toggle.onTintColor = UIColor.systemBlueColor;
    toggle.on = ![[[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCLongPressMenuHiddenTitlesKey] containsObject:sourceTitle];
    objc_setAssociatedObject(toggle, &NeoWCLongPressMenuTitleAssociationKey, sourceTitle, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [toggle addTarget:self action:@selector(visibilityChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    cell.showsReorderControl = YES;
    return cell;
}

- (void)visibilityChanged:(UISwitch *)sender {
    NSString *title = objc_getAssociatedObject(sender, &NeoWCLongPressMenuTitleAssociationKey);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *hidden = [[defaults arrayForKey:NeoWCLongPressMenuHiddenTitlesKey] mutableCopy] ?: [NSMutableArray array];
    if (sender.isOn) [hidden removeObject:title];
    else if (title.length > 0 && ![hidden containsObject:title]) [hidden addObject:title];
    [defaults setObject:hidden forKey:NeoWCLongPressMenuHiddenTitlesKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCEnhancementDidChangeNotification object:NeoWCLongPressMenuHiddenTitlesKey];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath { return YES; }

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
      toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSMutableArray *titles = [self.titles mutableCopy];
    NSString *title = titles[sourceIndexPath.row];
    [titles removeObjectAtIndex:sourceIndexPath.row];
    [titles insertObject:title atIndex:destinationIndexPath.row];
    self.titles = titles;
    [[NSUserDefaults standardUserDefaults] setObject:titles forKey:NeoWCLongPressMenuPreferredOrderKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCEnhancementDidChangeNotification object:NeoWCLongPressMenuPreferredOrderKey];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *sourceTitle = self.titles[indexPath.row];
    NSMutableDictionary *mapping = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:NeoWCLongPressMenuTitleMapKey] mutableCopy] ?: [NSMutableDictionary dictionary];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名菜单"
                                                                   message:sourceTitle
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = mapping[sourceTitle];
        field.placeholder = @"留空恢复微信原名称";
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *value = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (value.length > 0) mapping[sourceTitle] = value;
        else [mapping removeObjectForKey:sourceTitle];
        [[NSUserDefaults standardUserDefaults] setObject:mapping forKey:NeoWCLongPressMenuTitleMapKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCEnhancementDidChangeNotification object:NeoWCLongPressMenuTitleMapKey];
        [weakSelf reloadTitles];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
