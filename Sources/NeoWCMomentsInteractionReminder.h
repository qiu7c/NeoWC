#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void NeoWCMomentsInteractionObserveUnreadCount(id manager, unsigned int count);
FOUNDATION_EXPORT void NeoWCMomentsInteractionObserveLastUnreadMessage(id manager, nullable id message);
FOUNDATION_EXPORT void NeoWCMomentsInteractionReminderTick(void);
FOUNDATION_EXPORT void NeoWCMomentsInteractionReminderSettingsDidChange(void);

NS_ASSUME_NONNULL_END
