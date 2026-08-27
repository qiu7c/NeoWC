#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSArray<NSString *> *NeoWCMomentsReminderUsers(void);
FOUNDATION_EXPORT void NeoWCMomentsReminderSetUserSelected(NSString *username, BOOL selected);
FOUNDATION_EXPORT void NeoWCMomentsReminderTick(void);
FOUNDATION_EXPORT void NeoWCMomentsReminderSettingsDidChange(void);

NS_ASSUME_NONNULL_END
