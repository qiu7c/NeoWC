#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const NeoWCLoggingEnabledKey;
FOUNDATION_EXPORT NSNotificationName const NeoWCLogDidChangeNotification;
FOUNDATION_EXPORT void NeoWCLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXPORT void NeoWCLogAlways(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXPORT NSArray<NSString *> *NeoWCLogEntries(void);
FOUNDATION_EXPORT void NeoWCClearLogEntries(void);
