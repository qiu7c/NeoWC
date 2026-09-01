#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NeoWCPrivateGroupInvitationResult) {
    NeoWCPrivateGroupInvitationResultUnsupported = 0,
    NeoWCPrivateGroupInvitationResultRejected,
    NeoWCPrivateGroupInvitationResultSubmitted,
};

/// Returns a WeChat service through the compatibility-aware service center.
FOUNDATION_EXPORT id _Nullable NeoWCPrivateService(NSString *className);

/// Resolves a contact using the known cache and database selectors.
FOUNDATION_EXPORT id _Nullable NeoWCPrivateContact(NSString *userName);

/// Builds and pushes WeChat's native profile controller.
FOUNDATION_EXPORT BOOL NeoWCPushPrivateContactProfile(UIViewController *source,
                                                      NSString *userName);

/// Invites one contact into a saved group through WeChat's native group manager.
FOUNDATION_EXPORT NeoWCPrivateGroupInvitationResult
NeoWCPrivateInviteGroupMember(NSString *groupUserName, NSString *memberUserName);

NS_ASSUME_NONNULL_END
