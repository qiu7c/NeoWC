#import "NeoWCQuickReplyStore.h"
#import "NeoWCAccount.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

static NSString *const NeoWCQuickReplyErrorDomain = @"com.qiu7c.neowc.quick-reply";

typedef NS_ENUM(NSInteger, NeoWCQuickReplyErrorCode) {
    NeoWCQuickReplyErrorInvalidValue = 1,
    NeoWCQuickReplyErrorStorageUnavailable,
    NeoWCQuickReplyErrorMediaCopyFailed,
};

static NSString *const NeoWCQuickReplyItemsIndexName = @"index.json";
static NSString *const NeoWCQuickReplyItemsBackupName = @"index.backup.json";
static NSString *const NeoWCQuickReplyFoldersIndexName = @"folders.json";
static NSString *const NeoWCQuickReplyFoldersBackupName = @"folders.backup.json";
static NSString *const NeoWCQuickReplyRecoveryDirectoryName = @"QuickReplyRecovery";

static NSError *NeoWCQuickReplyError(NeoWCQuickReplyErrorCode code, NSString *description) {
    return [NSError errorWithDomain:NeoWCQuickReplyErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description ?: @"快捷回复处理失败"}];
}

static void NeoWCQuickReplySetIndexReadError(NSError **error) {
    if (error) {
        *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorStorageUnavailable,
                                      @"消息库索引暂时无法读取，已停止操作以保护现有消息");
    }
}

static NSString *NeoWCQuickReplyTrimmedString(id value) {
    if (![value isKindOfClass:NSString.class]) return @"";
    return [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

@implementation NeoWCQuickReplyItem

- (id)copyWithZone:(NSZone *)zone {
    NeoWCQuickReplyItem *copy = [[[self class] allocWithZone:zone] init];
    copy.identifier = self.identifier;
    copy.type = self.type;
    copy.title = self.title;
    copy.text = self.text;
    copy.folderIdentifier = self.folderIdentifier;
    copy.mediaRelativePath = self.mediaRelativePath;
    copy.thumbnailRelativePath = self.thumbnailRelativePath;
    copy.sortIndex = self.sortIndex;
    copy.pinned = self.pinned;
    copy.createdAt = self.createdAt;
    copy.lastUsedAt = self.lastUsedAt;
    copy.useCount = self.useCount;
    copy.sourceConversation = self.sourceConversation;
    copy.sourceMessageID = self.sourceMessageID;
    copy.sourceAccountIdentifier = self.sourceAccountIdentifier;
    copy.metadata = self.metadata;
    return copy;
}

@end

@implementation NeoWCQuickReplyFolder

- (id)copyWithZone:(NSZone *)zone {
    NeoWCQuickReplyFolder *copy = [[[self class] allocWithZone:zone] init];
    copy.identifier = self.identifier;
    copy.name = self.name;
    copy.sortIndex = self.sortIndex;
    return copy;
}

@end

@interface NeoWCQuickReplyStore ()
@property (nonatomic, copy) NSArray<NeoWCQuickReplyItem *> *lastKnownItems;
@property (nonatomic, copy) NSArray<NeoWCQuickReplyFolder *> *lastKnownFolders;
- (nullable NSURL *)sharedDirectoryCreatingIfNeeded:(BOOL)create error:(NSError **)error;
- (nullable NSURL *)recoveryDirectoryCreatingIfNeeded:(BOOL)create error:(NSError **)error;
@end

@implementation NeoWCQuickReplyStore

+ (instancetype)sharedStore {
    static NeoWCQuickReplyStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ store = [NeoWCQuickReplyStore new]; });
    return store;
}

- (BOOL)isAvailable {
    return [self sharedDirectoryCreatingIfNeeded:YES error:nil] != nil &&
           [self recoveryDirectoryCreatingIfNeeded:YES error:nil] != nil;
}

- (NSURL *)quickRepliesRootURL {
    NSURL *applicationSupport = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory
                                                                     inDomains:NSUserDomainMask].firstObject;
    return applicationSupport ? [[applicationSupport URLByAppendingPathComponent:@"NeoWC" isDirectory:YES]
                                 URLByAppendingPathComponent:@"QuickReplies" isDirectory:YES] : nil;
}

- (NSURL *)recoveryDirectoryCreatingIfNeeded:(BOOL)create error:(NSError **)error {
    NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory
                                                            inDomains:NSUserDomainMask].firstObject;
    if (!documents) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorStorageUnavailable, @"无法访问快捷回复恢复目录");
        return nil;
    }
    NSURL *directory = [[documents URLByAppendingPathComponent:@"NeoWC" isDirectory:YES]
                        URLByAppendingPathComponent:NeoWCQuickReplyRecoveryDirectoryName isDirectory:YES];
    if (!create) return directory;
    NSError *directoryError = nil;
    if (![NSFileManager.defaultManager createDirectoryAtURL:directory
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&directoryError]) {
        if (error) *error = directoryError ?: NeoWCQuickReplyError(NeoWCQuickReplyErrorStorageUnavailable,
                                                                    @"无法创建快捷回复恢复目录");
        return nil;
    }
    for (NSString *component in @[@"media", @"thumbnails"]) {
        NSURL *child = [directory URLByAppendingPathComponent:component isDirectory:YES];
        if (![NSFileManager.defaultManager createDirectoryAtURL:child
                                    withIntermediateDirectories:YES
                                                     attributes:nil
                                                          error:&directoryError]) {
            if (error) *error = directoryError;
            return nil;
        }
    }
    [directory setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    return directory;
}

- (NSURL *)sharedDirectoryCreatingIfNeeded:(BOOL)create error:(NSError **)error {
    NSURL *root = [self quickRepliesRootURL];
    if (!root) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorStorageUnavailable, @"无法访问应用支持目录");
        return nil;
    }
    NSURL *directory = [root URLByAppendingPathComponent:@"Shared" isDirectory:YES];
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
    [self migrateLegacyLibrariesIntoDirectory:directory root:root];
    return directory;
}

- (void)migrateLegacyLibrariesIntoDirectory:(NSURL *)sharedDirectory root:(NSURL *)root {
    NSURL *marker = [sharedDirectory URLByAppendingPathComponent:@".shared-library-v1"];
    if ([NSFileManager.defaultManager fileExistsAtPath:marker.path]) return;
    NSFileManager *manager = NSFileManager.defaultManager;
    NSError *childrenError = nil;
    NSArray<NSURL *> *children = [manager contentsOfDirectoryAtURL:root
                                       includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                          options:NSDirectoryEnumerationSkipsHiddenFiles
                                                            error:&childrenError];
    if (!children || childrenError) return;
    NSURL *recoveryDirectory = [self recoveryDirectoryCreatingIfNeeded:YES error:nil];
    if (!recoveryDirectory) return;
    NSMutableArray<NSMutableDictionary *> *mergedItems = [NSMutableArray array];
    NSURL *sharedItemsURL = [sharedDirectory URLByAppendingPathComponent:NeoWCQuickReplyItemsIndexName];
    BOOL sharedItemsExist = [manager fileExistsAtPath:sharedItemsURL.path];
    NSData *sharedData = [NSData dataWithContentsOfURL:sharedItemsURL];
    NSError *sharedItemsError = nil;
    id sharedObject = sharedData.length ? [NSJSONSerialization JSONObjectWithData:sharedData options:NSJSONReadingMutableContainers error:&sharedItemsError] : nil;
    if (sharedItemsExist && (![sharedObject isKindOfClass:NSArray.class] || sharedItemsError)) return;
    if (!sharedItemsExist) {
        NSData *recoveryItemsData = [NSData dataWithContentsOfURL:[recoveryDirectory URLByAppendingPathComponent:NeoWCQuickReplyItemsIndexName]];
        id recoveryItemsObject = recoveryItemsData.length
            ? [NSJSONSerialization JSONObjectWithData:recoveryItemsData options:NSJSONReadingMutableContainers error:nil]
            : nil;
        if ([recoveryItemsObject isKindOfClass:NSArray.class]) {
            sharedData = recoveryItemsData;
            sharedObject = recoveryItemsObject;
        }
    }
    if ([sharedObject isKindOfClass:NSArray.class]) {
        for (id value in sharedObject) if ([value isKindOfClass:NSDictionary.class]) [mergedItems addObject:[value mutableCopy]];
    }
    NSMutableArray<NSMutableDictionary *> *folders = [NSMutableArray array];
    NSURL *sharedFoldersURL = [sharedDirectory URLByAppendingPathComponent:NeoWCQuickReplyFoldersIndexName];
    BOOL sharedFoldersExist = [manager fileExistsAtPath:sharedFoldersURL.path];
    NSData *folderData = [NSData dataWithContentsOfURL:sharedFoldersURL];
    NSError *sharedFoldersError = nil;
    id folderObject = folderData.length ? [NSJSONSerialization JSONObjectWithData:folderData options:NSJSONReadingMutableContainers error:&sharedFoldersError] : nil;
    if (sharedFoldersExist && (![folderObject isKindOfClass:NSArray.class] || sharedFoldersError)) return;
    if (!sharedFoldersExist) {
        NSData *recoveryFoldersData = [NSData dataWithContentsOfURL:[recoveryDirectory URLByAppendingPathComponent:NeoWCQuickReplyFoldersIndexName]];
        id recoveryFoldersObject = recoveryFoldersData.length
            ? [NSJSONSerialization JSONObjectWithData:recoveryFoldersData options:NSJSONReadingMutableContainers error:nil]
            : nil;
        if ([recoveryFoldersObject isKindOfClass:NSArray.class]) {
            folderData = recoveryFoldersData;
            folderObject = recoveryFoldersObject;
        }
    }
    if ([folderObject isKindOfClass:NSArray.class]) {
        for (id value in folderObject) if ([value isKindOfClass:NSDictionary.class]) [folders addObject:[value mutableCopy]];
    }
    NSMutableDictionary<NSString *, NSString *> *folderIDByName = [NSMutableDictionary dictionary];
    for (NSDictionary *folder in folders) {
        NSString *name = NeoWCQuickReplyTrimmedString(folder[@"name"]);
        NSString *identifier = NeoWCQuickReplyTrimmedString(folder[@"id"]);
        if (name.length && identifier.length) folderIDByName[name] = identifier;
    }
    NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
    NSMutableSet<NSString *> *migrationOrigins = [NSMutableSet set];
    for (NSDictionary *item in mergedItems) {
        NSString *identifier = NeoWCQuickReplyTrimmedString(item[@"id"]);
        if (identifier.length) [identifiers addObject:identifier];
        NSString *origin = NeoWCQuickReplyTrimmedString(item[@"migrationOrigin"]);
        if (origin.length) [migrationOrigins addObject:origin];
    }
    NSInteger nextSort = mergedItems.count;
    for (NSURL *legacyDirectory in children) {
        NSNumber *isDirectory = nil;
        [legacyDirectory getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        if (!isDirectory.boolValue || [legacyDirectory.lastPathComponent isEqualToString:@"Shared"]) continue;
        NSData *data = [NSData dataWithContentsOfURL:[legacyDirectory URLByAppendingPathComponent:@"index.json"]];
        id object = data.length ? [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] : nil;
        if (![object isKindOfClass:NSArray.class]) continue;
        NSData *categoriesData = [NSData dataWithContentsOfURL:[legacyDirectory URLByAppendingPathComponent:@"categories.json"]];
        id categoriesObject = categoriesData.length ? [NSJSONSerialization JSONObjectWithData:categoriesData options:0 error:nil] : nil;
        if ([categoriesObject isKindOfClass:NSArray.class]) {
            for (id value in (NSArray *)categoriesObject) {
                NSString *categoryName = NeoWCQuickReplyTrimmedString(value);
                if (!categoryName.length || folderIDByName[categoryName]) continue;
                NSString *folderID = NSUUID.UUID.UUIDString.lowercaseString;
                folderIDByName[categoryName] = folderID;
                [folders addObject:[@{@"id": folderID, @"name": categoryName, @"sort": @(folders.count)} mutableCopy]];
            }
        }
        for (NSDictionary *rawItem in (NSArray *)object) {
            if (![rawItem isKindOfClass:NSDictionary.class]) continue;
            NSMutableDictionary *item = [rawItem mutableCopy];
            NSString *oldIdentifier = NeoWCQuickReplyTrimmedString(item[@"id"]);
            NSString *migrationOrigin = [legacyDirectory.lastPathComponent stringByAppendingFormat:@"/%@", oldIdentifier.length ? oldIdentifier : @"unknown"];
            if ([migrationOrigins containsObject:migrationOrigin]) continue;
            NSString *identifier = oldIdentifier;
            if (!identifier.length || [identifiers containsObject:identifier]) identifier = NSUUID.UUID.UUIDString.lowercaseString;
            item[@"id"] = identifier;
            item[@"migrationOrigin"] = migrationOrigin;
            item[@"sourceAccount"] = legacyDirectory.lastPathComponent;
            NSString *category = NeoWCQuickReplyTrimmedString(item[@"category"]);
            if (category.length) {
                NSString *folderID = folderIDByName[category];
                if (!folderID) {
                    folderID = NSUUID.UUID.UUIDString.lowercaseString;
                    folderIDByName[category] = folderID;
                    [folders addObject:[@{@"id": folderID, @"name": category, @"sort": @(folders.count)} mutableCopy]];
                }
                item[@"folder"] = folderID;
            }
            [item removeObjectForKey:@"category"];
            for (NSString *key in @[@"media", @"thumbnail"]) {
                NSString *relativePath = NeoWCQuickReplyTrimmedString(item[key]);
                if (!relativePath.length) continue;
                NSURL *source = [legacyDirectory URLByAppendingPathComponent:relativePath];
                NSString *child = [key isEqualToString:@"media"] ? @"media" : @"thumbnails";
                NSString *extension = source.pathExtension.length ? source.pathExtension : ([key isEqualToString:@"media"] ? @"dat" : @"jpg");
                NSString *newRelativePath = [child stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:extension]];
                NSURL *destination = [sharedDirectory URLByAppendingPathComponent:newRelativePath];
                if (![manager fileExistsAtPath:source.path]) { [item removeObjectForKey:key]; continue; }
                [manager removeItemAtURL:destination error:nil];
                NSError *copyError = nil;
                if (![manager copyItemAtURL:source toURL:destination error:&copyError]) {
                    [item removeObjectForKey:key];
                    continue;
                }
                item[key] = newRelativePath;
            }
            item[@"sort"] = @(nextSort++);
            [mergedItems addObject:item];
            [identifiers addObject:identifier];
            [migrationOrigins addObject:migrationOrigin];
        }
    }
    NSError *serializationError = nil;
    NSData *itemsData = [NSJSONSerialization dataWithJSONObject:mergedItems options:0 error:&serializationError];
    NSData *foldersData = [NSJSONSerialization dataWithJSONObject:folders options:0 error:&serializationError];
    if (!itemsData || !foldersData) return;
    if (sharedData.length) [sharedData writeToURL:[sharedDirectory URLByAppendingPathComponent:NeoWCQuickReplyItemsBackupName] options:NSDataWritingAtomic error:nil];
    if (folderData.length) [folderData writeToURL:[sharedDirectory URLByAppendingPathComponent:NeoWCQuickReplyFoldersBackupName] options:NSDataWritingAtomic error:nil];
    if (![itemsData writeToURL:sharedItemsURL options:NSDataWritingAtomic error:nil]) return;
    if (![foldersData writeToURL:sharedFoldersURL options:NSDataWritingAtomic error:nil]) return;
    if (![itemsData writeToURL:[recoveryDirectory URLByAppendingPathComponent:NeoWCQuickReplyItemsIndexName]
                        options:NSDataWritingAtomic error:nil]) return;
    if (![foldersData writeToURL:[recoveryDirectory URLByAppendingPathComponent:NeoWCQuickReplyFoldersIndexName]
                          options:NSDataWritingAtomic error:nil]) return;
    [[NSData data] writeToURL:marker options:NSDataWritingAtomic error:nil];
}

- (BOOL)isManagedRelativePath:(NSString *)relativePath {
    if (relativePath.length == 0 || relativePath.isAbsolutePath) return NO;
    NSArray<NSString *> *components = relativePath.pathComponents;
    if (components.count != 2 || [components containsObject:@".."]) return NO;
    return [components.firstObject isEqualToString:@"media"] ||
           [components.firstObject isEqualToString:@"thumbnails"];
}

- (void)synchronizeRecoveryFileForRelativePath:(NSString *)relativePath
                               sharedDirectory:(NSURL *)sharedDirectory
                             recoveryDirectory:(NSURL *)recoveryDirectory {
    if (![self isManagedRelativePath:relativePath] || !sharedDirectory || !recoveryDirectory) return;
    NSFileManager *manager = NSFileManager.defaultManager;
    NSURL *primaryURL = [sharedDirectory URLByAppendingPathComponent:relativePath];
    NSURL *recoveryURL = [recoveryDirectory URLByAppendingPathComponent:relativePath];
    BOOL primaryExists = [manager fileExistsAtPath:primaryURL.path];
    BOOL recoveryExists = [manager fileExistsAtPath:recoveryURL.path];
    if (primaryExists == recoveryExists) return;
    NSURL *sourceURL = primaryExists ? primaryURL : recoveryURL;
    NSURL *destinationURL = primaryExists ? recoveryURL : primaryURL;
    NSError *linkError = nil;
    if (![manager linkItemAtURL:sourceURL toURL:destinationURL error:&linkError]) {
        [manager copyItemAtURL:sourceURL toURL:destinationURL error:nil];
    }
}

- (NeoWCQuickReplyItem *)itemFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:NSDictionary.class]) return nil;
    NSString *identifier = NeoWCQuickReplyTrimmedString(dictionary[@"id"]);
    NSNumber *typeValue = dictionary[@"type"];
    if (identifier.length == 0 || ![typeValue respondsToSelector:@selector(integerValue)]) return nil;
    NSInteger type = typeValue.integerValue;
    if (type < NeoWCQuickReplyTypeText || type > NeoWCQuickReplyTypeVoice) return nil;
    NeoWCQuickReplyItem *item = [NeoWCQuickReplyItem new];
    item.identifier = identifier;
    item.type = (NeoWCQuickReplyType)type;
    item.title = [dictionary[@"title"] isKindOfClass:NSString.class] ? dictionary[@"title"] : @"";
    item.text = [dictionary[@"text"] isKindOfClass:NSString.class] ? dictionary[@"text"] : @"";
    item.folderIdentifier = [dictionary[@"folder"] isKindOfClass:NSString.class] ? dictionary[@"folder"] : nil;
    item.mediaRelativePath = [dictionary[@"media"] isKindOfClass:NSString.class] ? dictionary[@"media"] : nil;
    item.thumbnailRelativePath = [dictionary[@"thumbnail"] isKindOfClass:NSString.class] ? dictionary[@"thumbnail"] : nil;
    item.sortIndex = [dictionary[@"sort"] respondsToSelector:@selector(integerValue)] ? [dictionary[@"sort"] integerValue] : 0;
    item.pinned = [dictionary[@"pinned"] respondsToSelector:@selector(boolValue)] && [dictionary[@"pinned"] boolValue];
    NSTimeInterval timestamp = [dictionary[@"createdAt"] respondsToSelector:@selector(doubleValue)] ? [dictionary[@"createdAt"] doubleValue] : 0;
    item.createdAt = timestamp > 0 ? [NSDate dateWithTimeIntervalSince1970:timestamp] : NSDate.date;
    NSTimeInterval lastUsedTimestamp = [dictionary[@"lastUsedAt"] respondsToSelector:@selector(doubleValue)]
        ? [dictionary[@"lastUsedAt"] doubleValue] : 0;
    item.lastUsedAt = lastUsedTimestamp > 0 ? [NSDate dateWithTimeIntervalSince1970:lastUsedTimestamp] : nil;
    item.useCount = [dictionary[@"useCount"] respondsToSelector:@selector(unsignedIntegerValue)]
        ? [dictionary[@"useCount"] unsignedIntegerValue] : 0;
    item.sourceConversation = [dictionary[@"sourceConversation"] isKindOfClass:NSString.class] ? dictionary[@"sourceConversation"] : nil;
    item.sourceMessageID = [dictionary[@"sourceMessageID"] isKindOfClass:NSString.class] ? dictionary[@"sourceMessageID"] : nil;
    item.sourceAccountIdentifier = [dictionary[@"sourceAccount"] isKindOfClass:NSString.class] ? dictionary[@"sourceAccount"] : nil;
    item.metadata = [dictionary[@"metadata"] isKindOfClass:NSDictionary.class] ? dictionary[@"metadata"] : @{};
    return item;
}

- (NSDictionary *)dictionaryForItem:(NeoWCQuickReplyItem *)item {
    NSMutableDictionary *dictionary = [@{
        @"id": item.identifier ?: @"",
        @"type": @(item.type),
        @"title": item.title ?: @"",
        @"text": item.text ?: @"",
        @"sort": @(item.sortIndex),
        @"pinned": @(item.isPinned),
        @"createdAt": @((item.createdAt ?: NSDate.date).timeIntervalSince1970),
        @"useCount": @(item.useCount),
    } mutableCopy];
    if (item.lastUsedAt) dictionary[@"lastUsedAt"] = @(item.lastUsedAt.timeIntervalSince1970);
    if (item.mediaRelativePath.length > 0) dictionary[@"media"] = item.mediaRelativePath;
    if (item.thumbnailRelativePath.length > 0) dictionary[@"thumbnail"] = item.thumbnailRelativePath;
    if (item.folderIdentifier.length > 0) dictionary[@"folder"] = item.folderIdentifier;
    if (item.sourceConversation.length > 0) dictionary[@"sourceConversation"] = item.sourceConversation;
    if (item.sourceMessageID.length > 0) dictionary[@"sourceMessageID"] = item.sourceMessageID;
    if (item.sourceAccountIdentifier.length > 0) dictionary[@"sourceAccount"] = item.sourceAccountIdentifier;
    if (item.metadata.count > 0) dictionary[@"metadata"] = item.metadata;
    return dictionary;
}

- (NSArray<NSDictionary *> *)loadJSONArrayAtURL:(NSURL *)primaryURL
                                       backupURL:(NSURL *)backupURL
                                     recoveryURL:(NSURL *)recoveryURL
                                           error:(NSError **)error {
    NSFileManager *manager = NSFileManager.defaultManager;
    BOOL primaryExists = [manager fileExistsAtPath:primaryURL.path];
    NSData *primaryData = [NSData dataWithContentsOfURL:primaryURL options:0 error:nil];
    NSError *primaryParseError = nil;
    id primaryObject = primaryData.length
        ? [NSJSONSerialization JSONObjectWithData:primaryData options:0 error:&primaryParseError]
        : nil;
    NSData *recoveryData = [NSData dataWithContentsOfURL:recoveryURL options:0 error:nil];
    NSError *recoveryParseError = nil;
    id recoveryObject = recoveryData.length
        ? [NSJSONSerialization JSONObjectWithData:recoveryData options:0 error:&recoveryParseError]
        : nil;
    BOOL recoveryValid = [recoveryObject isKindOfClass:NSArray.class] && !recoveryParseError;
    if ([primaryObject isKindOfClass:NSArray.class] && !primaryParseError) {
        if ([(NSArray *)primaryObject count] == 0 && recoveryValid && [(NSArray *)recoveryObject count] > 0) {
            [recoveryData writeToURL:primaryURL options:NSDataWritingAtomic error:nil];
            return recoveryObject;
        }
        [primaryData writeToURL:recoveryURL options:NSDataWritingAtomic error:nil];
        return primaryObject;
    }

    if (recoveryValid) {
        [recoveryData writeToURL:primaryURL options:NSDataWritingAtomic error:nil];
        return recoveryObject;
    }

    BOOL backupExists = [manager fileExistsAtPath:backupURL.path];
    NSData *backupData = [NSData dataWithContentsOfURL:backupURL options:0 error:nil];
    NSError *backupParseError = nil;
    id backupObject = backupData.length
        ? [NSJSONSerialization JSONObjectWithData:backupData options:0 error:&backupParseError]
        : nil;
    if ([backupObject isKindOfClass:NSArray.class] && !backupParseError) {
        [backupData writeToURL:primaryURL options:NSDataWritingAtomic error:nil];
        [backupData writeToURL:recoveryURL options:NSDataWritingAtomic error:nil];
        return backupObject;
    }
    BOOL recoveryExists = [manager fileExistsAtPath:recoveryURL.path];
    if (!primaryExists && !backupExists && !recoveryExists) return @[];
    if (error) {
        *error = primaryParseError ?: recoveryParseError ?: backupParseError ?:
            NeoWCQuickReplyError(NeoWCQuickReplyErrorStorageUnavailable,
                                 @"消息库索引暂时无法读取，已停止写入以避免清空");
    }
    return nil;
}

- (BOOL)writeJSONArrayData:(NSData *)data
                primaryURL:(NSURL *)primaryURL
                 backupURL:(NSURL *)backupURL
               recoveryURL:(NSURL *)recoveryURL
                     error:(NSError **)error {
    NSFileManager *manager = NSFileManager.defaultManager;
    NSData *previousRecoveryData = [NSData dataWithContentsOfURL:recoveryURL options:0 error:nil];
    BOOL recoveryPreviouslyExisted = [manager fileExistsAtPath:recoveryURL.path];
    NSData *currentData = nil;
    if ([manager fileExistsAtPath:primaryURL.path]) {
        currentData = [NSData dataWithContentsOfURL:primaryURL options:0 error:nil];
        id currentObject = currentData.length ? [NSJSONSerialization JSONObjectWithData:currentData options:0 error:nil] : nil;
        if (![currentObject isKindOfClass:NSArray.class]) {
            if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorStorageUnavailable,
                                                      @"消息库索引异常，已拒绝覆盖原数据");
            return NO;
        }
        if (![currentData writeToURL:backupURL options:NSDataWritingAtomic error:error]) return NO;
    }
    if (![data writeToURL:recoveryURL options:NSDataWritingAtomic error:error]) return NO;
    BOOL written = [data writeToURL:primaryURL options:NSDataWritingAtomic error:error];
    if (!written) {
        if (recoveryPreviouslyExisted && previousRecoveryData.length) {
            [previousRecoveryData writeToURL:recoveryURL options:NSDataWritingAtomic error:nil];
        } else {
            [manager removeItemAtURL:recoveryURL error:nil];
        }
        return NO;
    }
    if (written && ![manager fileExistsAtPath:backupURL.path]) {
        [data writeToURL:backupURL options:NSDataWritingAtomic error:nil];
    }
    return written;
}

- (NSMutableArray<NeoWCQuickReplyItem *> *)loadItemsLocked {
    NSURL *directory = [self sharedDirectoryCreatingIfNeeded:YES error:nil];
    NSURL *recoveryDirectory = [self recoveryDirectoryCreatingIfNeeded:YES error:nil];
    if (!directory || !recoveryDirectory) return nil;
    NSArray *object = [self loadJSONArrayAtURL:[directory URLByAppendingPathComponent:NeoWCQuickReplyItemsIndexName]
                                     backupURL:[directory URLByAppendingPathComponent:NeoWCQuickReplyItemsBackupName]
                                   recoveryURL:[recoveryDirectory URLByAppendingPathComponent:NeoWCQuickReplyItemsIndexName]
                                         error:nil];
    if (!object) return nil;
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *dictionary in object) {
        NeoWCQuickReplyItem *item = [self itemFromDictionary:dictionary];
        if (!item) return nil;
        [self synchronizeRecoveryFileForRelativePath:item.mediaRelativePath
                                     sharedDirectory:directory
                                   recoveryDirectory:recoveryDirectory];
        [self synchronizeRecoveryFileForRelativePath:item.thumbnailRelativePath
                                     sharedDirectory:directory
                                   recoveryDirectory:recoveryDirectory];
        [items addObject:item];
    }
    return items;
}

- (BOOL)saveItemsLocked:(NSArray<NeoWCQuickReplyItem *> *)items error:(NSError **)error {
    NSURL *directory = [self sharedDirectoryCreatingIfNeeded:YES error:error];
    NSURL *recoveryDirectory = [self recoveryDirectoryCreatingIfNeeded:YES error:error];
    if (!directory || !recoveryDirectory) return NO;
    NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:items.count];
    for (NeoWCQuickReplyItem *item in items) [dictionaries addObject:[self dictionaryForItem:item]];
    NSError *serializationError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionaries options:0 error:&serializationError];
    if (!data) {
        if (error) *error = serializationError;
        return NO;
    }
    NSError *writeError = nil;
    BOOL written = [self writeJSONArrayData:data
                                 primaryURL:[directory URLByAppendingPathComponent:NeoWCQuickReplyItemsIndexName]
                                  backupURL:[directory URLByAppendingPathComponent:NeoWCQuickReplyItemsBackupName]
                                recoveryURL:[recoveryDirectory URLByAppendingPathComponent:NeoWCQuickReplyItemsIndexName]
                                      error:&writeError];
    if (!written && error) *error = writeError;
    return written;
}

- (NSArray<NeoWCQuickReplyItem *> *)items {
    @synchronized (self) {
        NSArray *loadedItems = [self loadItemsLocked];
        if (!loadedItems) {
            NSMutableArray *cachedCopies = [NSMutableArray arrayWithCapacity:self.lastKnownItems.count];
            for (NeoWCQuickReplyItem *item in self.lastKnownItems) [cachedCopies addObject:item.copy];
            return cachedCopies;
        }
        NSArray *items = [loadedItems sortedArrayUsingComparator:^NSComparisonResult(NeoWCQuickReplyItem *left, NeoWCQuickReplyItem *right) {
            if (left.isPinned != right.isPinned) return left.isPinned ? NSOrderedAscending : NSOrderedDescending;
            if (left.sortIndex != right.sortIndex) return left.sortIndex < right.sortIndex ? NSOrderedAscending : NSOrderedDescending;
            return [right.createdAt compare:left.createdAt];
        }];
        NSMutableArray *copies = [NSMutableArray arrayWithCapacity:items.count];
        for (NeoWCQuickReplyItem *item in items) [copies addObject:item.copy];
        self.lastKnownItems = copies;
        return copies;
    }
}

- (NSMutableArray<NeoWCQuickReplyFolder *> *)loadFoldersLocked {
    NSURL *directory = [self sharedDirectoryCreatingIfNeeded:YES error:nil];
    NSURL *recoveryDirectory = [self recoveryDirectoryCreatingIfNeeded:YES error:nil];
    if (!directory || !recoveryDirectory) return nil;
    NSArray *object = [self loadJSONArrayAtURL:[directory URLByAppendingPathComponent:NeoWCQuickReplyFoldersIndexName]
                                     backupURL:[directory URLByAppendingPathComponent:NeoWCQuickReplyFoldersBackupName]
                                   recoveryURL:[recoveryDirectory URLByAppendingPathComponent:NeoWCQuickReplyFoldersIndexName]
                                         error:nil];
    if (!object) return nil;
    NSMutableArray<NeoWCQuickReplyFolder *> *folders = [NSMutableArray array];
    for (NSDictionary *dictionary in object) {
        if (![dictionary isKindOfClass:NSDictionary.class]) return nil;
        NSString *identifier = NeoWCQuickReplyTrimmedString(dictionary[@"id"]);
        NSString *name = NeoWCQuickReplyTrimmedString(dictionary[@"name"]);
        if (!identifier.length || !name.length) return nil;
        NeoWCQuickReplyFolder *folder = [NeoWCQuickReplyFolder new];
        folder.identifier = identifier;
        folder.name = name;
        folder.sortIndex = [dictionary[@"sort"] respondsToSelector:@selector(integerValue)] ? [dictionary[@"sort"] integerValue] : folders.count;
        [folders addObject:folder];
    }
    return folders;
}

- (BOOL)saveFoldersLocked:(NSArray<NeoWCQuickReplyFolder *> *)folders error:(NSError **)error {
    NSURL *directory = [self sharedDirectoryCreatingIfNeeded:YES error:error];
    NSURL *recoveryDirectory = [self recoveryDirectoryCreatingIfNeeded:YES error:error];
    if (!directory || !recoveryDirectory) return NO;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:folders.count];
    for (NeoWCQuickReplyFolder *folder in folders) {
        [values addObject:@{@"id": folder.identifier ?: @"", @"name": folder.name ?: @"", @"sort": @(folder.sortIndex)}];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:values options:0 error:error];
    return data && [self writeJSONArrayData:data
                                  primaryURL:[directory URLByAppendingPathComponent:NeoWCQuickReplyFoldersIndexName]
                                   backupURL:[directory URLByAppendingPathComponent:NeoWCQuickReplyFoldersBackupName]
                                 recoveryURL:[recoveryDirectory URLByAppendingPathComponent:NeoWCQuickReplyFoldersIndexName]
                                       error:error];
}

- (NSArray<NeoWCQuickReplyFolder *> *)folders {
    @synchronized (self) {
        NSArray *loadedFolders = [self loadFoldersLocked];
        if (!loadedFolders) {
            NSMutableArray *cachedCopies = [NSMutableArray arrayWithCapacity:self.lastKnownFolders.count];
            for (NeoWCQuickReplyFolder *folder in self.lastKnownFolders) [cachedCopies addObject:folder.copy];
            return cachedCopies;
        }
        NSArray *folders = [loadedFolders sortedArrayUsingComparator:^NSComparisonResult(NeoWCQuickReplyFolder *left, NeoWCQuickReplyFolder *right) {
            if (left.sortIndex != right.sortIndex) return left.sortIndex < right.sortIndex ? NSOrderedAscending : NSOrderedDescending;
            return [left.name localizedCompare:right.name];
        }];
        NSMutableArray *copies = [NSMutableArray arrayWithCapacity:folders.count];
        for (NeoWCQuickReplyFolder *folder in folders) [copies addObject:folder.copy];
        self.lastKnownFolders = copies;
        return copies;
    }
}

- (NeoWCQuickReplyFolder *)createFolderWithName:(NSString *)name error:(NSError **)error {
    NSString *trimmed = NeoWCQuickReplyTrimmedString(name);
    if (!trimmed.length) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorInvalidValue, @"文件夹名称不能为空");
        return nil;
    }
    @synchronized (self) {
        NSMutableArray *folders = [self loadFoldersLocked];
        if (!folders) { NeoWCQuickReplySetIndexReadError(error); return nil; }
        for (NeoWCQuickReplyFolder *candidate in folders) {
            if ([candidate.name caseInsensitiveCompare:trimmed] == NSOrderedSame) return candidate.copy;
        }
        NeoWCQuickReplyFolder *folder = [NeoWCQuickReplyFolder new];
        folder.identifier = NSUUID.UUID.UUIDString.lowercaseString;
        folder.name = trimmed;
        folder.sortIndex = folders.count;
        [folders addObject:folder];
        return [self saveFoldersLocked:folders error:error] ? folder.copy : nil;
    }
}

- (BOOL)renameFolderWithIdentifier:(NSString *)identifier toName:(NSString *)name error:(NSError **)error {
    NSString *trimmed = NeoWCQuickReplyTrimmedString(name);
    if (!identifier.length || !trimmed.length) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorInvalidValue, @"文件夹名称不能为空");
        return NO;
    }
    @synchronized (self) {
        NSMutableArray *folders = [self loadFoldersLocked];
        if (!folders) { NeoWCQuickReplySetIndexReadError(error); return NO; }
        for (NeoWCQuickReplyFolder *folder in folders) {
            if ([folder.identifier isEqualToString:identifier]) { folder.name = trimmed; return [self saveFoldersLocked:folders error:error]; }
        }
        return NO;
    }
}

- (BOOL)deleteFolderWithIdentifier:(NSString *)identifier error:(NSError **)error {
    if (!identifier.length) return NO;
    @synchronized (self) {
        NSMutableArray *folders = [self loadFoldersLocked];
        if (!folders) { NeoWCQuickReplySetIndexReadError(error); return NO; }
        NSIndexSet *matches = [folders indexesOfObjectsPassingTest:^BOOL(NeoWCQuickReplyFolder *folder, NSUInteger idx, BOOL *stop) {
            (void)idx; (void)stop; return [folder.identifier isEqualToString:identifier];
        }];
        if (!matches.count) return NO;
        [folders removeObjectsAtIndexes:matches];
        NSMutableArray *items = [self loadItemsLocked];
        if (!items) { NeoWCQuickReplySetIndexReadError(error); return NO; }
        for (NeoWCQuickReplyItem *item in items) if ([item.folderIdentifier isEqualToString:identifier]) item.folderIdentifier = nil;
        return [self saveItemsLocked:items error:error] && [self saveFoldersLocked:folders error:error];
    }
}

- (NSInteger)nextSortIndexForItems:(NSArray<NeoWCQuickReplyItem *> *)items {
    NSInteger maximum = -1;
    for (NeoWCQuickReplyItem *item in items) maximum = MAX(maximum, item.sortIndex);
    return maximum + 1;
}

- (NeoWCQuickReplyItem *)existingItemInItems:(NSArray<NeoWCQuickReplyItem *> *)items
                     sourceAccountIdentifier:(NSString *)sourceAccountIdentifier
                           sourceConversation:(NSString *)sourceConversation
                              sourceMessageID:(NSString *)sourceMessageID {
    NSString *conversation = NeoWCQuickReplyTrimmedString(sourceConversation);
    NSString *messageID = NeoWCQuickReplyTrimmedString(sourceMessageID);
    NSString *account = NeoWCQuickReplyTrimmedString(sourceAccountIdentifier);
    if (conversation.length == 0 || messageID.length == 0) return nil;
    for (NeoWCQuickReplyItem *item in items) {
        if ([NeoWCQuickReplyTrimmedString(item.sourceAccountIdentifier) isEqualToString:account] &&
            [item.sourceConversation isEqualToString:conversation] &&
            [item.sourceMessageID isEqualToString:messageID]) return item;
    }
    return nil;
}

- (NeoWCQuickReplyItem *)addText:(NSString *)text
                            title:(NSString *)title
                folderIdentifier:(NSString *)folderIdentifier
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
        if (!items) { NeoWCQuickReplySetIndexReadError(error); return nil; }
        NeoWCQuickReplyItem *existing = [self existingItemInItems:items
                                          sourceAccountIdentifier:NeoWCCurrentUserWXID()
                                               sourceConversation:sourceConversation
                                                  sourceMessageID:sourceMessageID];
        if (existing) return existing.copy;
        NeoWCQuickReplyItem *item = [NeoWCQuickReplyItem new];
        item.identifier = NSUUID.UUID.UUIDString.lowercaseString;
        item.type = NeoWCQuickReplyTypeText;
        item.title = NeoWCQuickReplyTrimmedString(title);
        item.text = trimmed;
        item.folderIdentifier = NeoWCQuickReplyTrimmedString(folderIdentifier).length ? folderIdentifier : nil;
        item.sortIndex = [self nextSortIndexForItems:items];
        item.pinned = NO;
        item.createdAt = NSDate.date;
        item.sourceConversation = NeoWCQuickReplyTrimmedString(sourceConversation).length > 0 ? sourceConversation : nil;
        item.sourceMessageID = NeoWCQuickReplyTrimmedString(sourceMessageID).length > 0 ? sourceMessageID : nil;
        item.sourceAccountIdentifier = NeoWCQuickReplyTrimmedString(NeoWCCurrentUserWXID()).length ? NeoWCCurrentUserWXID() : nil;
        item.metadata = @{};
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
                      folderIdentifier:(NSString *)folderIdentifier
                     sourceConversation:(NSString *)sourceConversation
                        sourceMessageID:(NSString *)sourceMessageID
                                  error:(NSError **)error {
    if (type != NeoWCQuickReplyTypeImage && type != NeoWCQuickReplyTypeVideo && type != NeoWCQuickReplyTypeVoice) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorInvalidValue, @"只支持图片、视频和语音素材");
        return nil;
    }
    NSString *sourcePath = sourceURL.path;
    BOOL isDirectory = NO;
    if (sourcePath.length == 0 || ![NSFileManager.defaultManager fileExistsAtPath:sourcePath isDirectory:&isDirectory] || isDirectory) {
        if (error) *error = NeoWCQuickReplyError(NeoWCQuickReplyErrorInvalidValue, @"所选媒体文件不存在");
        return nil;
    }
    @synchronized (self) {
        NSURL *directory = [self sharedDirectoryCreatingIfNeeded:YES error:error];
        if (!directory) return nil;
        NSMutableArray *items = [self loadItemsLocked];
        if (!items) { NeoWCQuickReplySetIndexReadError(error); return nil; }
        NeoWCQuickReplyItem *existing = [self existingItemInItems:items
                                          sourceAccountIdentifier:NeoWCCurrentUserWXID()
                                               sourceConversation:sourceConversation
                                                  sourceMessageID:sourceMessageID];
        if (existing) return existing.copy;
        NSString *identifier = NSUUID.UUID.UUIDString.lowercaseString;
        NSString *extension = sourceURL.pathExtension.lowercaseString;
        if (extension.length == 0) extension = type == NeoWCQuickReplyTypeImage ? @"jpg" : (type == NeoWCQuickReplyTypeVideo ? @"mp4" : @"aud");
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
        item.folderIdentifier = NeoWCQuickReplyTrimmedString(folderIdentifier).length ? folderIdentifier : nil;
        item.mediaRelativePath = mediaRelativePath;
        item.thumbnailRelativePath = thumbnailRelativePath;
        item.sortIndex = [self nextSortIndexForItems:items];
        item.createdAt = NSDate.date;
        item.sourceConversation = NeoWCQuickReplyTrimmedString(sourceConversation).length > 0 ? sourceConversation : nil;
        item.sourceMessageID = NeoWCQuickReplyTrimmedString(sourceMessageID).length > 0 ? sourceMessageID : nil;
        item.sourceAccountIdentifier = NeoWCQuickReplyTrimmedString(NeoWCCurrentUserWXID()).length ? NeoWCCurrentUserWXID() : nil;
        item.metadata = @{};
        [items addObject:item];
        if ([self saveItemsLocked:items error:error]) {
            NSURL *recoveryDirectory = [self recoveryDirectoryCreatingIfNeeded:YES error:nil];
            [self synchronizeRecoveryFileForRelativePath:mediaRelativePath
                                         sharedDirectory:directory
                                       recoveryDirectory:recoveryDirectory];
            [self synchronizeRecoveryFileForRelativePath:thumbnailRelativePath
                                         sharedDirectory:directory
                                       recoveryDirectory:recoveryDirectory];
            return item.copy;
        }
        [NSFileManager.defaultManager removeItemAtURL:destinationURL error:nil];
        if (thumbnailRelativePath) [NSFileManager.defaultManager removeItemAtURL:[directory URLByAppendingPathComponent:thumbnailRelativePath] error:nil];
        return nil;
    }
}

- (BOOL)updateItem:(NeoWCQuickReplyItem *)item error:(NSError **)error {
    if (item.identifier.length == 0) return NO;
    @synchronized (self) {
        NSMutableArray *items = [self loadItemsLocked];
        if (!items) { NeoWCQuickReplySetIndexReadError(error); return NO; }
        NSUInteger index = [items indexOfObjectPassingTest:^BOOL(NeoWCQuickReplyItem *candidate, NSUInteger idx, BOOL *stop) {
            (void)idx; (void)stop;
            return [candidate.identifier isEqualToString:item.identifier];
        }];
        if (index == NSNotFound) return NO;
        NeoWCQuickReplyItem *stored = items[index];
        stored.title = NeoWCQuickReplyTrimmedString(item.title);
        stored.folderIdentifier = NeoWCQuickReplyTrimmedString(item.folderIdentifier).length ? item.folderIdentifier : nil;
        stored.metadata = [item.metadata isKindOfClass:NSDictionary.class] ? item.metadata : @{};
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
        if (!items) { NeoWCQuickReplySetIndexReadError(error); return NO; }
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
        if (!items) { NeoWCQuickReplySetIndexReadError(error); return NO; }
        NeoWCQuickReplyItem *item = [items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NeoWCQuickReplyItem *candidate, NSDictionary *bindings) {
            (void)bindings;
            return [candidate.identifier isEqualToString:identifier];
        }]].firstObject;
        if (!item) return NO;
        item.pinned = pinned;
        return [self saveItemsLocked:items error:error];
    }
}

- (BOOL)recordUsageForIdentifier:(NSString *)identifier error:(NSError **)error {
    if (!identifier.length) return NO;
    @synchronized (self) {
        NSMutableArray *items = [self loadItemsLocked];
        if (!items) { NeoWCQuickReplySetIndexReadError(error); return NO; }
        for (NeoWCQuickReplyItem *item in items) {
            if (![item.identifier isEqualToString:identifier]) continue;
            if (item.useCount < NSUIntegerMax) item.useCount++;
            item.lastUsedAt = NSDate.date;
            return [self saveItemsLocked:items error:error];
        }
        return NO;
    }
}

- (BOOL)moveItemWithIdentifier:(NSString *)identifier
            toFolderIdentifier:(NSString *)folderIdentifier
                         error:(NSError **)error {
    if (!identifier.length) return NO;
    NSString *destination = NeoWCQuickReplyTrimmedString(folderIdentifier);
    @synchronized (self) {
        if (destination.length) {
            BOOL folderExists = NO;
            NSArray *folders = [self loadFoldersLocked];
            if (!folders) { NeoWCQuickReplySetIndexReadError(error); return NO; }
            for (NeoWCQuickReplyFolder *folder in folders) {
                if ([folder.identifier isEqualToString:destination]) { folderExists = YES; break; }
            }
            if (!folderExists) return NO;
        }
        NSMutableArray *items = [self loadItemsLocked];
        if (!items) { NeoWCQuickReplySetIndexReadError(error); return NO; }
        for (NeoWCQuickReplyItem *item in items) {
            if (![item.identifier isEqualToString:identifier]) continue;
            item.folderIdentifier = destination.length ? destination : nil;
            return [self saveItemsLocked:items error:error];
        }
        return NO;
    }
}

- (NSString *)safeAbsolutePathForRelativePath:(NSString *)relativePath {
    if (relativePath.length == 0 || relativePath.isAbsolutePath) return nil;
    NSURL *directory = [self sharedDirectoryCreatingIfNeeded:NO error:nil];
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
        if (!items) { NeoWCQuickReplySetIndexReadError(error); return NO; }
        NSUInteger index = [items indexOfObjectPassingTest:^BOOL(NeoWCQuickReplyItem *candidate, NSUInteger idx, BOOL *stop) {
            (void)idx; (void)stop;
            return [candidate.identifier isEqualToString:identifier];
        }];
        if (index == NSNotFound) return NO;
        NeoWCQuickReplyItem *item = items[index];
        [items removeObjectAtIndex:index];
        if (![self saveItemsLocked:items error:error]) return NO;
        NSURL *recoveryDirectory = [self recoveryDirectoryCreatingIfNeeded:NO error:nil];
        for (NSString *relativePath in @[item.mediaRelativePath ?: @"", item.thumbnailRelativePath ?: @""]) {
            if (![self isManagedRelativePath:relativePath]) continue;
            NSString *primaryPath = [self safeAbsolutePathForRelativePath:relativePath];
            if (primaryPath.length) [NSFileManager.defaultManager removeItemAtPath:primaryPath error:nil];
            NSURL *recoveryURL = [recoveryDirectory URLByAppendingPathComponent:relativePath];
            if (recoveryURL.path.length) [NSFileManager.defaultManager removeItemAtURL:recoveryURL error:nil];
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
