#import "NeoWCCardTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NeoWCInfoListViewController : NeoWCCardTableViewController
- (instancetype)initWithTitle:(NSString *)title
                         rows:(NSArray<NSDictionary<NSString *, id> *> *)rows;
@end

NS_ASSUME_NONNULL_END
