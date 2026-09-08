#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NeoWCAutomationSourceType) {
    NeoWCAutomationSourceTypeFixedText = 0,
    NeoWCAutomationSourceTypeLibraryText = 1,
    NeoWCAutomationSourceTypeJavaScript = 2,
};

typedef NS_ENUM(NSInteger, NeoWCAutomationRepeatMode) {
    NeoWCAutomationRepeatModeOnce = 0,
    NeoWCAutomationRepeatModeDaily = 1,
};

@interface NeoWCAutomationTask : NSObject <NSCopying>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *targetUserName;
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (nonatomic, assign) NeoWCAutomationSourceType sourceType;
@property (nonatomic, copy) NSString *fixedText;
@property (nonatomic, copy, nullable) NSString *libraryItemIdentifier;
@property (nonatomic, copy) NSString *script;
@property (nonatomic, strong) NSDate *nextFireDate;
@property (nonatomic, assign) NeoWCAutomationRepeatMode repeatMode;
@property (nonatomic, strong, nullable) NSDate *lastRunDate;
@property (nonatomic, copy, nullable) NSString *lastResult;
@end

@interface NeoWCAutomationManager : NSObject
+ (instancetype)sharedManager;
- (NSArray<NeoWCAutomationTask *> *)tasks;
- (void)start;
- (void)saveTask:(NeoWCAutomationTask *)task;
- (void)deleteTaskWithIdentifier:(NSString *)identifier;
- (void)runTaskNow:(NeoWCAutomationTask *)task;
@end

/// Starts the in-process automation scheduler. Safe to call repeatedly.
FOUNDATION_EXPORT void NeoWCAutomationStart(void);

NS_ASSUME_NONNULL_END
