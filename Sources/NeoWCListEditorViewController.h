#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NeoWCListEditorMode) {
    NeoWCListEditorModeList,
    NeoWCListEditorModeMapping,
};

@interface NeoWCListEditorViewController : UIViewController

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                  defaultsKey:(NSString *)defaultsKey
                         mode:(NeoWCListEditorMode)mode;

@end
