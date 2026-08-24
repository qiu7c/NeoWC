#import "NeoWCCardTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NeoWCContactInfoCardViewController : NeoWCCardTableViewController
- (instancetype)initWithTitle:(NSString *)title
                       avatar:(nullable UIImage *)avatar
                         name:(NSString *)name
                     userName:(NSString *)userName
                         rows:(NSArray<NSDictionary<NSString *, NSString *> *> *)rows;
- (void)updateRows:(NSArray<NSDictionary<NSString *, NSString *> *> *)rows;
@end

NS_ASSUME_NONNULL_END
