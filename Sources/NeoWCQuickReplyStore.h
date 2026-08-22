#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NeoWCQuickReplyType) {
    NeoWCQuickReplyTypeText = 0,
    NeoWCQuickReplyTypeImage = 1,
    NeoWCQuickReplyTypeVideo = 2,
    NeoWCQuickReplyTypeVoice = 3,
};

@interface NeoWCQuickReplyItem : NSObject <NSCopying>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) NeoWCQuickReplyType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy, nullable) NSString *mediaRelativePath;
@property (nonatomic, copy, nullable) NSString *thumbnailRelativePath;
@property (nonatomic, assign) NSInteger sortIndex;
@property (nonatomic, assign, getter=isPinned) BOOL pinned;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, copy, nullable) NSString *sourceConversation;
@property (nonatomic, copy, nullable) NSString *sourceMessageID;
@property (nonatomic, copy) NSDictionary<NSString *, id> *metadata;
@end

@interface NeoWCQuickReplyStore : NSObject

+ (instancetype)sharedStore;

@property (nonatomic, readonly, getter=isAvailable) BOOL available;
@property (nonatomic, copy, readonly, nullable) NSString *accountIdentifier;

- (NSArray<NeoWCQuickReplyItem *> *)items;
- (NSArray<NSString *> *)categories;
- (nullable NeoWCQuickReplyItem *)addText:(NSString *)text
                                    title:(nullable NSString *)title
                                 category:(nullable NSString *)category
                       sourceConversation:(nullable NSString *)sourceConversation
                          sourceMessageID:(nullable NSString *)sourceMessageID
                                    error:(NSError **)error;
- (nullable NeoWCQuickReplyItem *)addMediaAtURL:(NSURL *)sourceURL
                                           type:(NeoWCQuickReplyType)type
                                          title:(nullable NSString *)title
                             sourceConversation:(nullable NSString *)sourceConversation
                                sourceMessageID:(nullable NSString *)sourceMessageID
                                          error:(NSError **)error;
- (BOOL)updateItem:(NeoWCQuickReplyItem *)item error:(NSError **)error;
- (BOOL)setPinned:(BOOL)pinned forIdentifier:(NSString *)identifier error:(NSError **)error;
- (BOOL)applyOrderedIdentifiers:(NSArray<NSString *> *)identifiers error:(NSError **)error;
- (BOOL)deleteItemWithIdentifier:(NSString *)identifier error:(NSError **)error;
- (BOOL)addCategory:(NSString *)category error:(NSError **)error;
- (BOOL)renameCategory:(NSString *)category toName:(NSString *)newName error:(NSError **)error;
- (BOOL)deleteCategory:(NSString *)category error:(NSError **)error;
- (nullable NSString *)absoluteMediaPathForItem:(NeoWCQuickReplyItem *)item;
- (nullable NSString *)absoluteThumbnailPathForItem:(NeoWCQuickReplyItem *)item;
- (unsigned long long)managedMediaSize;

@end

NS_ASSUME_NONNULL_END
