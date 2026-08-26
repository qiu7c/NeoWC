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
@property (nonatomic, copy, nullable) NSString *folderIdentifier;
@property (nonatomic, copy, nullable) NSString *mediaRelativePath;
@property (nonatomic, copy, nullable) NSString *thumbnailRelativePath;
@property (nonatomic, assign) NSInteger sortIndex;
@property (nonatomic, assign, getter=isPinned) BOOL pinned;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong, nullable) NSDate *lastUsedAt;
@property (nonatomic, assign) NSUInteger useCount;
@property (nonatomic, copy, nullable) NSString *sourceConversation;
@property (nonatomic, copy, nullable) NSString *sourceMessageID;
@property (nonatomic, copy, nullable) NSString *sourceAccountIdentifier;
@property (nonatomic, copy) NSDictionary<NSString *, id> *metadata;
@end

@interface NeoWCQuickReplyFolder : NSObject <NSCopying>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger sortIndex;
@end

@interface NeoWCQuickReplyStore : NSObject

+ (instancetype)sharedStore;

@property (nonatomic, readonly, getter=isAvailable) BOOL available;

- (NSArray<NeoWCQuickReplyItem *> *)items;
- (NSArray<NeoWCQuickReplyFolder *> *)folders;
- (nullable NeoWCQuickReplyItem *)addText:(NSString *)text
                                    title:(nullable NSString *)title
                        folderIdentifier:(nullable NSString *)folderIdentifier
                       sourceConversation:(nullable NSString *)sourceConversation
                          sourceMessageID:(nullable NSString *)sourceMessageID
                                    error:(NSError **)error;
- (nullable NeoWCQuickReplyItem *)addMediaAtURL:(NSURL *)sourceURL
                                           type:(NeoWCQuickReplyType)type
                                          title:(nullable NSString *)title
                              folderIdentifier:(nullable NSString *)folderIdentifier
                             sourceConversation:(nullable NSString *)sourceConversation
                                sourceMessageID:(nullable NSString *)sourceMessageID
                                          error:(NSError **)error;
- (BOOL)updateItem:(NeoWCQuickReplyItem *)item error:(NSError **)error;
- (BOOL)setPinned:(BOOL)pinned forIdentifier:(NSString *)identifier error:(NSError **)error;
- (BOOL)recordUsageForIdentifier:(NSString *)identifier error:(NSError **)error;
- (BOOL)applyOrderedIdentifiers:(NSArray<NSString *> *)identifiers error:(NSError **)error;
- (BOOL)deleteItemWithIdentifier:(NSString *)identifier error:(NSError **)error;
- (nullable NeoWCQuickReplyFolder *)createFolderWithName:(NSString *)name error:(NSError **)error;
- (BOOL)renameFolderWithIdentifier:(NSString *)identifier toName:(NSString *)name error:(NSError **)error;
- (BOOL)deleteFolderWithIdentifier:(NSString *)identifier error:(NSError **)error;
- (BOOL)moveItemWithIdentifier:(NSString *)identifier
            toFolderIdentifier:(nullable NSString *)folderIdentifier
                         error:(NSError **)error;
- (nullable NSString *)absoluteMediaPathForItem:(NeoWCQuickReplyItem *)item;
- (nullable NSString *)absoluteThumbnailPathForItem:(NeoWCQuickReplyItem *)item;
- (unsigned long long)managedMediaSize;
- (nullable NSURL *)createExportPackageWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
