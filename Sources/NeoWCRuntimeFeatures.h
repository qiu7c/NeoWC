#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSArray *NeoWCManagedLongPressMenuItems(NSArray *items);

FOUNDATION_EXPORT BOOL NeoWCShouldBlockIncomingMessage(NSString *sessionUserName, id message);
FOUNDATION_EXPORT BOOL NeoWCDeleteBlockedIncomingMessage(id messageManager,
                                                         NSString *sessionUserName,
                                                         id message);

FOUNDATION_EXPORT id NeoWCCaptureGroupMemberChange(id newContact, id oldContact);
FOUNDATION_EXPORT void NeoWCCompleteGroupMemberChange(id snapshot, id contactManager, id newContact);

FOUNDATION_EXPORT BOOL NeoWCHandleNotificationResponse(id response, void (^completionHandler)(void));
FOUNDATION_EXPORT void NeoWCOpenChatForUserName(NSString *userName);

FOUNDATION_EXPORT UIView *NeoWCWalletHeaderForView(UIView *view);
FOUNDATION_EXPORT BOOL NeoWCViewIsInsideWalletHeader(UIView *view);
FOUNDATION_EXPORT void NeoWCRefreshWalletHeaderBalance(id headerView);
