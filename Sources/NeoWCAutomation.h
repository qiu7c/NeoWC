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

typedef NS_ENUM(NSInteger, NeoWCAutomationTriggerMode) {
    NeoWCAutomationTriggerModeScheduled = 0,
    NeoWCAutomationTriggerModeKeyword = 1,
};

@interface NeoWCAutomationTask : NSObject <NSCopying>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *targetUserName;
@property (nonatomic, copy) NSArray<NSString *> *targetUserNames;
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (nonatomic, assign) NeoWCAutomationSourceType sourceType;
@property (nonatomic, copy) NSString *fixedText;
@property (nonatomic, copy, nullable) NSString *libraryItemIdentifier;
@property (nonatomic, copy) NSString *script;
@property (nonatomic, strong) NSDate *nextFireDate;
@property (nonatomic, assign) NeoWCAutomationRepeatMode repeatMode;
@property (nonatomic, assign) NeoWCAutomationTriggerMode triggerMode;
@property (nonatomic, copy) NSString *triggerKeyword;
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
/// Executes one message-library JavaScript in the supplied conversation without creating a task.
/// The script uses the same HTTP helpers, result schema, media download/conversion, and unified
/// private send adapters as scheduled/keyword automation. Completion is delivered on the main thread.
- (void)runJavaScript:(NSString *)script
       targetUserName:(NSString *)targetUserName
            completion:(void (^ _Nullable)(NSString *result))completion;
@end

/// Starts the in-process automation scheduler. Safe to call repeatedly.
FOUNDATION_EXPORT void NeoWCAutomationStart(void);

/// Delivers one incoming WeChat message wrapper to enabled keyword automations.
/// The wrapper is read-only; unsupported/non-text/self messages are ignored.
FOUNDATION_EXPORT void NeoWCAutomationHandleIncomingMessage(id _Nullable message);

NS_ASSUME_NONNULL_END
