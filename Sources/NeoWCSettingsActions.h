#import <UIKit/UIKit.h>
#import "NeoWCSettingsModels.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^NeoWCSettingsReloadHandler)(BOOL applyScale);

@interface NeoWCSettingsActions : NSObject
- (instancetype)initWithViewController:(UIViewController *)viewController
                         reloadHandler:(NeoWCSettingsReloadHandler)reloadHandler;
- (void)performActionForItem:(NeoWCSettingItem *)item;
@end

NS_ASSUME_NONNULL_END
