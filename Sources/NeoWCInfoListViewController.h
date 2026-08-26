#import "NeoWCCardTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^NeoWCInfoListSelectionHandler)(UIViewController *presenter,
                                               NSDictionary<NSString *, id> *row);

@interface NeoWCInfoListViewController : NeoWCCardTableViewController
- (instancetype)initWithTitle:(NSString *)title
                         rows:(NSArray<NSDictionary<NSString *, id> *> *)rows;
- (void)configureSelectionHandler:(nullable NeoWCInfoListSelectionHandler)handler;
@end

NS_ASSUME_NONNULL_END
