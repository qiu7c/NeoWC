#import <UIKit/UIKit.h>
#import "NeoWCSettingsModels.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^NeoWCSettingsSwitchHandler)(NeoWCSettingItem *item, BOOL enabled);

@interface NeoWCSettingsCell : UITableViewCell
- (void)configureWithItem:(NeoWCSettingItem *)item
            masterEnabled:(BOOL)masterEnabled
                 expanded:(BOOL)expanded
                     scale:(CGFloat)scale
            switchHandler:(NeoWCSettingsSwitchHandler)switchHandler;
@end

@interface NeoWCSettingsProfileHeaderView : UIControl
@property (nonatomic, copy, readonly, nullable) NSString *wxid;
- (void)refreshProfile;
- (void)showCopyConfirmation;
- (CGFloat)preferredHeightForWidth:(CGFloat)width scale:(CGFloat)scale;
@end

NS_ASSUME_NONNULL_END
