#import "NeoWCQuickReplyStore.h"
#import "NeoWCAccount.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

static NSString *const NeoWCQuickReplyErrorDomain = @"com.qiu7c.neowc.quick-reply";

typedef NS_ENUM(NSInteger, NeoWCQuickReplyErrorCode) {
    NeoWCQuickReplyErrorAccountUnavailable = 1,
    NeoWCQuickReplyErrorInvalidValue,
    NeoWCQuickReplyErrorStorageUnavailable,
    NeoWCQuickReplyErrorMediaCopyFailed,
};

static NSError *NeoWCQuickReplyError(NeoWCQuickReplyErrorCode code, NSString *description) {
    return [NSError errorWithDomain:NeoWCQuickReplyErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description ?: @"快捷回复素材处理失败"}];
}

static NSString *NeoWCQuickReplyTrimmedString(id value) {
    if (![value isKindOfClass:NSString.class]) return @"";
    return [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

static NSString *NeoWCQuickReplyEncodedAccount(NSString *account) {
    NSData *data = [account dataUsingEncoding:NSUTF8StringEncoding];
    NSString *encoded = [data base64EncodedStringWithOptions:0];
    encoded = [encoded stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    encoded = [encoded stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    return [encoded stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

@implementation NeoWCQuickReplyItem

- (id)copyWithZone:(NSZone *)zone {
    NeoWCQuickReplyItem *copy = [[[self class] allocWithZone:zone] init];
    copy.identifier = self.identifier;
    copy.type = self.type;
    copy.title = self.title;
    copy.text = self.text;
    copy.category = self.category;
    copy.mediaRelativePath = self.mediaRelativePath;
    copy.thumbnailRelativePath = self.thumbnailRelativePath;
    copy.sortIndex = self.sortIndex;
    copy.pinned = self.pinned;
    copy.createdAt = self.createdAt;
    copy.sourceConversation = self.sourceConversation;
    copy.sourceMessageID = self.sourceMessageID;
    return copy;
}

@end

@interface NeoWCQuickReplyStore ()
- (nullable NSURL *)accountDirectoryCreatingIfNeeded:(BOOL)create error:(NSError **)error;
@end

@implementation NeoWCQuickReplyStore

+ (instancetype)sharedStore {
    static NeoWCQuickReplyStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ store = [NeoWCQuickReplyStore new]; });
    return store;
}

- (NSString *)accountIdentifier {
    NSString *account = NeoWCCurrentUserWXID();
    return NeoWCQuickReplyTrimmedString(account).length > 0 ? account : nil;
}

- (BOOL)isAvailable {
    return self.accountIdentifier.length > 0;
}

- (NSURL *)accountDirectoryCreatingIfNeeded:(BOOL)create error:(NSError **)error {
    NSString *account = self.accountIdentifier;
    if (account.length == 0) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorAccountUnavailable, @"尚未取得当前微信账号，请进入 NeoWC 设置后重试");
        return nil;
    }
    NSURL *applicationSupport = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory
                                                                     inDomains:NSUserDomainMask].firstObject;
    if (!applicationSupport) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorStorageUnavailable, @"无法访问应用支持目录");
        return nil;
    }
    NSURL *directory = [[[applicationSupport URLByAppendingPathComponent:@"NeoWC" isDirectory:YES]
                         URLByAppendingPathComponent:@"QuickReplies" isDirectory:YES]
                        URLByAppendingPathComponent:NeoWCQuickReplyEncodedAccount(account) isDirectory:YES];
    if (!create) return directory;
    NSFileManager *manager = NSFileManager.defaultManager;
    for (NSString *component in @[@"media", @"thumbnails"]) {
        NSURL *child = [directory URLByAppendingPathComponent:component isDirectory:YES];
        NSError *directoryError = nil;
        if (![manager createDirectoryAtURL:child withIntermediateDirectories:YES attributes:nil error:&directoryError]) {
            if (error) *error = directoryError ?: NeoWCQuickReplyError(NeoWCQuickReplyErrorStorageUnavailable, @"无法创建快捷回复目录");
            return nil;
        }
    }
    return directory;
}

- (NeoWCQuickReplyItem *)itemFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:NSDictionary.class]) return nil;
    NSString *identifier = NeoWCQuickReplyTrimmedString(dictionary[@"id"]);
    NSNumber *typeValue = dictionary[@"type"];
    if (identifier.length == 0 || ![typeValue respondsToSelector:@selector(integerValue)]) return nil;
    NSInteger type = typeValue.integerValue;
    if (type < NeoWCQuickReplyTypeText || type > NeoWCQuickReplyTypeVideo) return nil;
    NeoWCQuickReplyItem *item = [NeoWCQuickReplyItem new];
    item.identifier = identifier;
    item.type = (NeoWCQuickReplyType)type;
    item.title = [dictionary[@"title"] isKindOfClass:NSString.class] ? dictionary[@"title"] : @"";
    item.text = [dictionary[@"text"] isKindOfClass:NSString.class] ? dictionary[@"text"] : @"";
    item.category = [dictionary[@"category"] isKindOfClass:NSString.class] ? dictionary[@"category"] : @"";
    item.mediaRelativePath = [dictionary[@"media"] isKindOfClass:NSString.class] ? dictionary[@"media"] : nil;
    item.thumbnailRelativePath = [dictionary[@"thumbnail"] isKindOfClass:NSString.class] ? dictionary[@"thumbnail"] : nil;
    item.sortIndex = [dictionary[@"sort"] respondsToSelector:@selector(integerValue)] ? [dictionary[@"sort"] integerValue] : 0;
    item.pinned = [dictionary[@"pinned"] respondsToSelector:@selector(boolValue)] && [dictionary[@"pinned"] boolValue];
    NSTimeInterval timestamp = [dictionary[@"createdAt"] respondsToSelector:@selector(doubleValue)] ? [dictionary[@"createdAt"] doubleValue] : 0;
    item.createdAt = timestamp > 0 ? [NSDate dateWithTimeIntervalSince1970:timestamp] : NSDate.date;
    item.sourceConversation = [dictionary[@"sourceConversation"] isKindOfClass:NSString.class] ? dictionary[@"sourceConversation"] : nil;
    item.sourceMessageID = [dictionary[@"sourceMessageID"] isKindOfClass:NSString.class] ? dictionary[@"sourceMessageID"] : nil;
    return item;
}

- (NSDictionary *)dictionaryForItem:(NeoWCQuickReplyItem *)item {
    NSMutableDictionary *dictionary = [@{
        @"id": item.identifier ?: @"",
        @"type": @(item.type),
        @"title": item.title ?: @"",
        @"text": item.text ?: @"",
        @"category": item.category ?: @"",
        @"sort": @(item.sortIndex),
        @"pinned": @(item.isPinned),
        @"createdAt": @((item.createdAt ?: NSDate.date).timeIntervalSince1970),
    } mutableCopy];
    if (item.mediaRelativePath.length > 0) dictionary[@"media"] = item.mediaRelativePath;
    if (item.thumbnailRelativePath.length > 0) dictionary[@"thumbnail"] = item.thumbnailRelativePath;
    if (item.sourceConversation.length > 0) dictionary[@"sourceConversation"] = item.sourceConversation;
    if (item.sourceMessageID.length > 0) dictionary[@"sourceMessageID"] = item.sourceMessageID;
    return dictionary;
}

- (NSMutableArray<NeoWCQuickReplyItem *> *)loadItemsLocked {
    NSURL *directory = [self accountDirectoryCreatingIfNeeded:NO error:nil];
    if (!directory) return [NSMutableArray array];
    NSData *data = [NSData dataWithContentsOfURL:[directory URLByAppendingPathComponent:@"index.json"]];
    if (data.length == 0) return [NSMutableArray array];
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![object isKindOfClass:NSArray.class]) return [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *dictionary in (NSArray *)object) {
        NeoWCQuickReplyItem *item = [self itemFromDictionary:dictionary];
        if (item) [items addObject:item];
    }
    return items;
}

- (BOOL)saveItemsLocked:(NSArray<NeoWCQuickReplyItem *> *)items error:(NSError **)error {
    NSURL *directory = [self accountDirectoryCreatingIfNeeded:YES error:error];
    if (!directory) return NO;
    NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:items.count];
    for (NeoWCQuickReplyItem *item in items) [dictionaries addObject:[self dictionaryForItem:item]];
    NSError *serializationError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionaries options:0 error:&serializationError];
    if (!data) {
        if (error) *error = serializationError;
        return NO;
    }
    NSError *writeError = nil;
    BOOL written = [data writeToURL:[directory URLByAppendingPathComponent:@"index.json"]
                            options:NSDataWritingAtomic
                              error:&writeError];
    if (!written && error) *error = writeError;
    return written;
}

- (NSArray<NeoWCQuickReplyItem *> *)items {
    @synchronized (self) {
        NSArray *items = [[self loadItemsLocked] sortedArrayUsingComparator:^NSComparisonResult(NeoWCQuickReplyItem *left, NeoWCQuickReplyItem *right) {
            if (left.isPinned != right.isPinned) return left.isPinned ? NSOrderedAscending : NSOrderedDescending;
            if (left.sortIndex != right.sortIndex) return left.sortIndex < right.sortIndex ? NSOrderedAscending : NSOrderedDescending;
            return [right.createdAt compare:left.createdAt];
        }];
        NSMutableArray *copies = [NSMutableArray arrayWithCapacity:items.count];
        for (NeoWCQuickReplyItem *item in items) [copies addObject:item.copy];
        return copies;
    }
}

- (NSInteger)nextSortIndexForItems:(NSArray<NeoWCQuickReplyItem *> *)items {
    NSInteger maximum = -1;
    for (NeoWCQuickReplyItem *item in items) maximum = MAX(maximum, item.sortIndex);
    return maximum + 1;
}

- (NeoWCQuickReplyItem *)existingItemInItems:(NSArray<NeoWCQuickReplyItem *> *)items
                           sourceConversation:(NSString *)sourceConversation
                              sourceMessageID:(NSString *)sourceMessageID {
    NSString *conversation = NeoWCQuickReplyTrimmedString(sourceConversation);
    NSString *messageID = NeoWCQuickReplyTrimmedString(sourceMessageID);
    if (conversation.length == 0 || messageID.length == 0) return nil;
    for (NeoWCQuickReplyItem *item in items) {
        if ([item.sourceConversation isEqualToString:conversation] &&
            [item.sourceMessageID isEqualToString:messageID]) return item;
    }
    return nil;
}

- (NeoWCQuickReplyItem *)addText:(NSString *)text
                            title:(NSString *)title
                         category:(NSString *)category
               sourceConversation:(NSString *)sourceConversation
                  sourceMessageID:(NSString *)sourceMessageID
                            error:(NSError **)error {
    NSString *trimmed = NeoWCQuickReplyTrimmedString(text);
    if (trimmed.length == 0) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorInvalidValue, @"文字内容不能为空");
        return nil;
    }
    @synchronized (self) {
        NSMutableArray *items = [self loadItemsLocked];
        NeoWCQuickReplyItem *existing = [self existingItemInItems:items
                                               sourceConversation:sourceConversation
                                                  sourceMessageID:sourceMessageID];
        if (existing) return existing.copy;
        NeoWCQuickReplyItem *item = [NeoWCQuickReplyItem new];
        item.identifier = NSUUID.UUID.UUIDString.lowercaseString;
        item.type = NeoWCQuickReplyTypeText;
        item.title = NeoWCQuickReplyTrimmedString(title);
        item.text = trimmed;
        item.category = NeoWCQuickReplyTrimmedString(category);
        item.sortIndex = [self nextSortIndexForItems:items];
        item.pinned = NO;
        item.createdAt = NSDate.date;
        item.sourceConversation = NeoWCQuickReplyTrimmedString(sourceConversation).length > 0 ? sourceConversation : nil;
        item.sourceMessageID = NeoWCQuickReplyTrimmedString(sourceMessageID).length > 0 ? sourceMessageID : nil;
        [items addObject:item];
        return [self saveItemsLocked:items error:error] ? item.copy : nil;
    }
}

- (UIImage *)thumbnailForMediaURL:(NSURL *)URL type:(NeoWCQuickReplyType)type {
    UIImage *image = nil;
    if (type == NeoWCQuickReplyTypeImage) {
        image = [UIImage imageWithContentsOfFile:URL.path];
    } else if (type == NeoWCQuickReplyTypeVideo) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize = CGSizeMake(480.0, 480.0);
        CGImageRef frame = [generator copyCGImageAtTime:CMTimeMakeWithSeconds(0.0, 600) actualTime:NULL error:nil];
        if (frame) {
            image = [UIImage imageWithCGImage:frame];
            CGImageRelease(frame);
        }
    }
    if (!image) return nil;
    CGFloat longest = MAX(image.size.width, image.size.height);
    if (longest <= 480.0) return image;
    CGFloat scale = 480.0 / longest;
    CGSize size = CGSizeMake(MAX(1.0, floor(image.size.width * scale)), MAX(1.0, floor(image.size.height * scale)));
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        (void)context;
        [image drawInRect:(CGRect){CGPointZero, size}];
    }];
}

- (NeoWCQuickReplyItem *)addMediaAtURL:(NSURL *)sourceURL
                                   type:(NeoWCQuickReplyType)type
                                  title:(NSString *)title
                     sourceConversation:(NSString *)sourceConversation
                        sourceMessageID:(NSString *)sourceMessageID
                                  error:(NSError **)error {
    if (type != NeoWCQuickReplyTypeImage && type != NeoWCQuickReplyTypeVideo) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorInvalidValue, @"只支持图片和视频素材");
        return nil;
    }
    NSString *sourcePath = sourceURL.path;
    BOOL isDirectory = NO;
    if (sourcePath.length == 0 || ![NSFileManager.defaultManager fileExistsAtPath:sourcePath isDirectory:&isDirectory] || isDirectory) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorInvalidValue, @"所选媒体文件不存在");
        return nil;
    }
    @synchronized (self) {
        NSURL *directory = [self accountDirectoryCreatingIfNeeded:YES error:error];
        if (!directory) return nil;
        NSMutableArray *items = [self loadItemsLocked];
        NeoWCQuickReplyItem *existing = [self existingItemInItems:items
                                               sourceConversation:sourceConversation
                                                  sourceMessageID:sourceMessageID];
        if (existing) return existing.copy;
        NSString *identifier = NSUUID.UUID.UUIDString.lowercaseString;
        NSString *extension = sourceURL.pathExtension.lowercaseString;
        if (extension.length == 0) extension = type == NeoWCQuickReplyTypeImage ? @"jpg" : @"mp4";
        NSString *mediaRelativePath = [@"media" stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:extension]];
        NSURL *destinationURL = [directory URLByAppendingPathComponent:mediaRelativePath];
        NSError *copyError = nil;
        if (![NSFileManager.defaultManager copyItemAtURL:sourceURL toURL:destinationURL error:&copyError]) {
            if (error) *error = copyError ?: NeoWCQuickReplyError(NeoWCQuickReplyErrorMediaCopyFailed, @"复制媒体文件失败");
            return nil;
        }
        NSString *thumbnailRelativePath = nil;
        UIImage *thumbnail = [self thumbnailForMediaURL:destinationURL type:type];
        NSData *thumbnailData = thumbnail ? UIImageJPEGRepresentation(thumbnail, 0.82) : nil;
        if (thumbnailData.length > 0) {
            thumbnailRelativePath = [@"thumbnails" stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"jpg"]];
            [thumbnailData writeToURL:[directory URLByAppendingPathComponent:thumbnailRelativePath]
                              options:NSDataWritingAtomic
                                error:nil];
        }
        NeoWCQuickReplyItem *item = [NeoWCQuickReplyItem new];
        item.identifier = identifier;
        item.type = type;
        item.title = NeoWCQuickReplyTrimmedString(title);
        item.text = @"";
        item.category = @"";
        item.mediaRelativePath = mediaRelativePath;
        item.thumbnailRelativePath = thumbnailRelativePath;
        item.sortIndex = [self nextSortIndexForItems:items];
        item.createdAt = NSDate.date;
        item.sourceConversation = NeoWCQuickReplyTrimmedString(sourceConversation).length > 0 ? sourceConversation : nil;
        item.sourceMessageID = NeoWCQuickReplyTrimmedString(sourceMessageID).length > 0 ? sourceMessageID : nil;
        [items addObject:item];
        if ([self saveItemsLocked:items error:error]) return item.copy;
        [NSFileManager.defaultManager removeItemAtURL:destinationURL error:nil];
        if (thumbnailRelativePath) [NSFileManager.defaultManager removeItemAtURL:[directory URLByAppendingPathComponent:thumbnailRelativePath] error:nil];
        return nil;
    }
}

- (BOOL)updateItem:(NeoWCQuickReplyItem *)item error:(NSError **)error {
    if (item.identifier.length == 0) return NO;
    @synchronized (self) {
        NSMutableArray *items = [self loadItemsLocked];
        NSUInteger index = [items indexOfObjectPassingTest:^BOOL(NeoWCQuickReplyItem *candidate, NSUInteger idx, BOOL *stop) {
            (void)idx; (void)stop;
            return [candidate.identifier isEqualToString:item.identifier];
        }];
        if (index == NSNotFound) return NO;
        NeoWCQuickReplyItem *stored = items[index];
        stored.title = NeoWCQuickReplyTrimmedString(item.title);
        stored.category = NeoWCQuickReplyTrimmedString(item.category);
        if (stored.type == NeoWCQuickReplyTypeText) {
            NSString *text = NeoWCQuickReplyTrimmedString(item.text);
            if (text.length == 0) {
                if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorInvalidValue, @"文字内容不能为空");
                return NO;
            }
            stored.text = text;
        }
        stored.sortIndex = item.sortIndex;
        stored.pinned = item.isPinned;
        return [self saveItemsLocked:items error:error];
    }
}

- (BOOL)applyOrderedIdentifiers:(NSArray<NSString *> *)identifiers error:(NSError **)error {
    @synchronized (self) {
        NSMutableArray *items = [self loadItemsLocked];
        NSMutableDictionary<NSString *, NSNumber *> *order = [NSMutableDictionary dictionary];
        [identifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger index, BOOL *stop) {
            (void)stop;
            if ([identifier isKindOfClass:NSString.class] && identifier.length > 0 && !order[identifier]) {
                order[identifier] = @(index);
            }
        }];
        NSInteger trailingIndex = (NSInteger)order.count;
        for (NeoWCQuickReplyItem *item in items) {
            NSNumber *index = order[item.identifier];
            item.sortIndex = index ? index.integerValue : trailingIndex++;
        }
        return [self saveItemsLocked:items error:error];
    }
}

- (BOOL)setPinned:(BOOL)pinned forIdentifier:(NSString *)identifier error:(NSError **)error {
    @synchronized (self) {
        NSMutableArray *items = [self loadItemsLocked];
        NeoWCQuickReplyItem *item = [items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NeoWCQuickReplyItem *candidate, NSDictionary *bindings) {
            (void)bindings;
            return [candidate.identifier isEqualToString:identifier];
        }]].firstObject;
        if (!item) return NO;
        item.pinned = pinned;
        return [self saveItemsLocked:items error:error];
    }
}

- (NSString *)safeAbsolutePathForRelativePath:(NSString *)relativePath {
    if (relativePath.length == 0 || relativePath.isAbsolutePath) return nil;
    NSURL *directory = [self accountDirectoryCreatingIfNeeded:NO error:nil];
    NSString *root = directory.URLByStandardizingPath.path;
    NSString *candidate = [[directory URLByAppendingPathComponent:relativePath] URLByStandardizingPath].path;
    NSString *prefix = [root stringByAppendingString:@"/"];
    return [candidate hasPrefix:prefix] ? candidate : nil;
}

- (NSString *)absoluteMediaPathForItem:(NeoWCQuickReplyItem *)item {
    return [self safeAbsolutePathForRelativePath:item.mediaRelativePath];
}

- (NSString *)absoluteThumbnailPathForItem:(NeoWCQuickReplyItem *)item {
    return [self safeAbsolutePathForRelativePath:item.thumbnailRelativePath];
}

- (BOOL)deleteItemWithIdentifier:(NSString *)identifier error:(NSError **)error {
    if (identifier.length == 0) return NO;
    @synchronized (self) {
        NSMutableArray *items = [self loadItemsLocked];
        NSUInteger index = [items indexOfObjectPassingTest:^BOOL(NeoWCQuickReplyItem *candidate, NSUInteger idx, BOOL *stop) {
            (void)idx; (void)stop;
            return [candidate.identifier isEqualToString:identifier];
        }];
        if (index == NSNotFound) return NO;
        NeoWCQuickReplyItem *item = items[index];
        [items removeObjectAtIndex:index];
        if (![self saveItemsLocked:items error:error]) return NO;
        for (NSString *path in @[[self absoluteMediaPathForItem:item] ?: @"", [self absoluteThumbnailPathForItem:item] ?: @""]) {
            if (path.length > 0) [NSFileManager.defaultManager removeItemAtPath:path error:nil];
        }
        return YES;
    }
}

- (unsigned long long)managedMediaSize {
    @synchronized (self) {
        unsigned long long total = 0;
        for (NeoWCQuickReplyItem *item in [self loadItemsLocked]) {
            for (NSString *path in @[[self absoluteMediaPathForItem:item] ?: @"", [self absoluteThumbnailPathForItem:item] ?: @""]) {
                if (path.length == 0) continue;
                NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:path error:nil];
                total += [attributes[NSFileSize] unsignedLongLongValue];
            }
        }
        return total;
    }
}

@end
