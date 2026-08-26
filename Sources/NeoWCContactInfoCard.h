#import "NeoWCCardTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^NeoWCContactInfoCardSwitchHandler)(BOOL enabled);

@interface NeoWCContactInfoCardViewController : NeoWCCardTableViewController
- (instancetype)initWithTitle:(NSString *)title
                       avatar:(nullable UIImage *)avatar
                         name:(NSString *)name
                     userName:(NSString *)userName
                         rows:(NSArray<NSDictionary<NSString *, NSString *> *> *)rows;
- (void)updateRows:(NSArray<NSDictionary<NSString *, NSString *> *> *)rows;
- (void)configureMessageBlockSwitchWithTitle:(NSString *)title
                                      enabled:(BOOL)enabled
                                      handler:(nullable NeoWCContactInfoCardSwitchHandler)handler;
- (void)configureSendConfirmationSwitchWithTitle:(NSString *)title
                                          enabled:(BOOL)enabled
                                          handler:(nullable NeoWCContactInfoCardSwitchHandler)handler;
@end

NS_ASSUME_NONNULL_END
