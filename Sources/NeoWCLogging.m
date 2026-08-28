#import "NeoWCLogging.h"

NSString *const NeoWCLoggingEnabledKey = @"com.qiu7c.neowc.logging.enabled";
NSNotificationName const NeoWCLogDidChangeNotification = @"NeoWCLogDidChangeNotification";

static NSMutableArray<NSString *> *NeoWCMutableLogEntries(void) {
    static NSMutableArray<NSString *> *entries;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ entries = [NSMutableArray array]; });
    return entries;
}

static NSDateFormatter *NeoWCLogDateFormatter(void) {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
        formatter.dateFormat = @"HH:mm:ss.SSS";
    });
    return formatter;
}

static void NeoWCWriteLog(NSString *format, va_list arguments, BOOL force) {
    if (format.length == 0) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (!force && [defaults objectForKey:NeoWCLoggingEnabledKey] &&
        ![defaults boolForKey:NeoWCLoggingEnabledKey]) return;
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    NSLog(@"[NeoWC] %@", message);
    NSDateFormatter *formatter = NeoWCLogDateFormatter();
    NSString *timestamp = nil;
    @synchronized (formatter) { timestamp = [formatter stringFromDate:NSDate.date]; }
    NSString *entry = [NSString stringWithFormat:@"[%@] %@", timestamp, message];
    NSMutableArray<NSString *> *entries = NeoWCMutableLogEntries();
    @synchronized (entries) {
        [entries addObject:entry];
        if (entries.count > 500) [entries removeObjectsInRange:NSMakeRange(0, entries.count - 500)];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:NeoWCLogDidChangeNotification object:nil];
    });
}

void NeoWCLog(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NeoWCWriteLog(format, arguments, NO);
    va_end(arguments);
}

void NeoWCLogAlways(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NeoWCWriteLog(format, arguments, YES);
    va_end(arguments);
}

NSArray<NSString *> *NeoWCLogEntries(void) {
    NSMutableArray<NSString *> *entries = NeoWCMutableLogEntries();
    @synchronized (entries) { return [entries copy]; }
}

void NeoWCClearLogEntries(void) {
    NSMutableArray<NSString *> *entries = NeoWCMutableLogEntries();
    @synchronized (entries) { [entries removeAllObjects]; }
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:NeoWCLogDidChangeNotification object:nil];
    });
}
