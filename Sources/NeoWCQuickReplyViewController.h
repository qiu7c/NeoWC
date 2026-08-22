#import <UIKit/UIKit.h>

@class NeoWCQuickReplyItem;

NS_ASSUME_NONNULL_BEGIN

typedef void (^NeoWCQuickReplySelectionHandler)(NeoWCQuickReplyItem *item);
typedef void (^NeoWCQuickReplyDirectSendHandler)(NeoWCQuickReplyItem *item);

@interface NeoWCQuickReplyViewController : UITableViewController

- (instancetype)initWithSelectionHandler:(nullable NeoWCQuickReplySelectionHandler)selectionHandler;
- (instancetype)initWithSelectionHandler:(nullable NeoWCQuickReplySelectionHandler)selectionHandler
                        directSendHandler:(nullable NeoWCQuickReplyDirectSendHandler)directSendHandler;

@end

NS_ASSUME_NONNULL_END
