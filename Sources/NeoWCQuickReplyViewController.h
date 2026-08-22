#import <UIKit/UIKit.h>

@class NeoWCQuickReplyItem;

NS_ASSUME_NONNULL_BEGIN

typedef void (^NeoWCQuickReplySelectionHandler)(NeoWCQuickReplyItem *item);
typedef void (^NeoWCQuickReplyDirectSendHandler)(NeoWCQuickReplyItem *item);

@interface NeoWCQuickReplyViewController : UITableViewController

- (instancetype)initWithSelectionHandler:(NeoWCQuickReplySelectionHandler _Nullable)selectionHandler;
- (instancetype)initWithSelectionHandler:(NeoWCQuickReplySelectionHandler _Nullable)selectionHandler
                        directSendHandler:(NeoWCQuickReplyDirectSendHandler _Nullable)directSendHandler;

@end

NS_ASSUME_NONNULL_END
