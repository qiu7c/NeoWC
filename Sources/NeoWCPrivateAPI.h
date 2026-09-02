#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NeoWCPrivateGroupInvitationResult) {
    NeoWCPrivateGroupInvitationResultUnsupported = 0,
    NeoWCPrivateGroupInvitationResultRejected,
    NeoWCPrivateGroupInvitationResultSubmitted,
};

/// Returns a WeChat service through the compatibility-aware service center.
/// @param className WeChat service class name. Empty names are rejected.
/// @return The shared service instance, or nil when the class/service center is unavailable.
/// @discussion Call on the main thread unless the concrete service documents otherwise.
/// Version fallback is handled by `NeoWCServiceForClass`; no service selector is called here.
FOUNDATION_EXPORT id _Nullable NeoWCPrivateService(NSString *className);

/// Resolves the currently visible WeChat chat controller.
/// @return A visible `BaseMsgContentViewController`, or nil outside a chat/unavailable versions.
/// @discussion Must be called on the main thread. Searches foreground windows, presented,
/// navigation, tab, and child controller trees; hidden/detached controllers are rejected.
/// The class-name check is the stable fallback when no cached chat controller is available.
FOUNDATION_EXPORT UIViewController * _Nullable NeoWCPrivateCurrentChatController(void);

/// Resolves the contact object owned by a WeChat chat controller.
/// @param chatController A current or explicitly supplied chat controller.
/// @return The chat contact, or nil when all guarded getters/fields are unavailable.
/// @discussion Call on the main thread. Tries `GetContact`, then `GetCContact`, followed by
/// object fields used by older builds. Every getter must have a no-argument object-return ABI.
FOUNDATION_EXPORT id _Nullable NeoWCPrivateChatContact(id _Nullable chatController);

/// Resolves the username represented by a WeChat chat controller.
/// @param chatController A current chat controller, or nil to resolve the visible controller.
/// @return A nonempty WeChat username, or nil when the chat/contact fields cannot be read.
/// @discussion Call on the main thread. Uses the WeChatX-evidenced `getChatUserName` direct path,
/// then `GetContact`/`GetCContact` contact fields, then older controller fields. Unsupported
/// selectors, ABI mismatches, exceptions, and empty strings fall through to the next version path.
FOUNDATION_EXPORT NSString * _Nullable NeoWCPrivateChatUserName(id _Nullable chatController);

/// Resolves a contact using the known cache and database selectors.
/// @param userName WeChat username, not a display name or alias.
/// @return The first contact returned by a supported selector, or nil on absence/failure.
/// @discussion Call on the main thread. Database selectors are attempted before cache fallbacks;
/// unsupported selectors and Objective-C exceptions are treated as nil.
FOUNDATION_EXPORT id _Nullable NeoWCPrivateContact(NSString *userName);

/// Reads the stable username from a WeChat contact/session object.
/// @param contact Contact-like object returned by WeChat services.
/// @return A trimmed username, or nil when no supported object field is available.
/// @discussion Thread-safe for already-owned objects. Tries current `m_nsUsrName` before older
/// username getters/fields; unsupported object-return ABIs and KVC failures return nil.
FOUNDATION_EXPORT NSString * _Nullable NeoWCPrivateContactUserName(id _Nullable contact);

/// Reads the preferred display name for a WeChat contact.
/// @param contact Contact-like object returned by WeChat services.
/// @param fallback Value returned when every supported name field is empty; may be nil.
/// @return Remark/display name/nickname in version order, then fallback, never an inferred name.
/// @discussion Thread-safe for already-owned objects. Object-return getters are ABI-checked;
/// older fields are KVC fallbacks and failures continue to the next candidate.
FOUNDATION_EXPORT NSString * _Nullable NeoWCPrivateContactDisplayName(id _Nullable contact,
                                                                      NSString * _Nullable fallback);

/// Reads the contact nickname, remark, or public WeChat alias respectively.
/// @param contact Contact-like object returned by WeChat services.
/// @return A trimmed value, or nil when the field is empty/unsupported.
/// @discussion Thread-safe for already-owned objects. Current fields are tried before historical
/// selector aliases; exceptions and non-string return values are treated as nil.
FOUNDATION_EXPORT NSString * _Nullable NeoWCPrivateContactNickname(id _Nullable contact);
FOUNDATION_EXPORT NSString * _Nullable NeoWCPrivateContactRemark(id _Nullable contact);
FOUNDATION_EXPORT NSString * _Nullable NeoWCPrivateContactAlias(id _Nullable contact);

/// Reads the best available contact avatar URL string.
/// @param contact Contact-like object returned by WeChat services.
/// @return HD/standard avatar URL, or nil when unavailable.
/// @discussion Thread-safe for already-owned objects. This performs no network request and falls
/// back across current and older URL fields.
FOUNDATION_EXPORT NSString * _Nullable NeoWCPrivateContactHeadImageURL(id _Nullable contact);

/// Returns an already-cached contact avatar image without starting a network request.
/// @param contact Contact-like object returned by WeChat services.
/// @return UIImage from `getContactHeadImage`/compatible getters, or nil.
/// @discussion Call on the main thread because UIImage ownership is consumed by UI callers.
/// Unsupported getter ABIs and non-image results return nil without using URL fallbacks.
FOUNDATION_EXPORT UIImage * _Nullable NeoWCPrivateContactAvatarImage(id _Nullable contact);

/// Builds WeChat's native auto-updating avatar view for a contact.
/// @param contact Contact-like object; may be nil when userName is known.
/// @param userName Username fallback when it cannot be read from contact.
/// @param roundCorner Whether the native helper should apply its own rounded corners.
/// @return A native avatar UIView, a UIImageView for cached images, or nil when unsupported.
/// @discussion Must be called on the main thread. Tries the generic helper, then main-frame and
/// profile helper variants, all with object/object/BOOL/BOOL ABI; cached UIImage is the final
/// fallback. The helper controls asynchronous URL loading when available.
FOUNDATION_EXPORT UIView * _Nullable NeoWCPrivateContactAvatarView(id _Nullable contact,
                                                                   NSString * _Nullable userName,
                                                                   BOOL roundCorner);

/// Returns WeChat's current contact collection through the unified service center.
/// @return A snapshot array of contact objects, or an empty array when unavailable.
/// @discussion Call on the main thread. The current `getContactList:contactType:` instance
/// selector is invoked only when its object return and two integer arguments match exactly,
/// using the evidenced `(1, 0)` values. Unsupported versions, exceptions, nil, and collections
/// that cannot be enumerated return an empty array rather than a partial guessed result.
FOUNDATION_EXPORT NSArray *NeoWCPrivateContactList(void);

/// Returns a deduplicated snapshot of known group-chat contact objects.
/// @return Group contacts keyed by their stable `@chatroom` username, possibly empty.
/// @discussion Call on the main thread. Merges the current session list, the compatible contact
/// list, and `ContactsDataLogic.getChatRoomContacts` in that order. No-argument getters must
/// return objects; `isChatroom` is used only with a verified BOOL ABI, while the stable username
/// suffix remains the cross-version fallback. Missing services and failed sources are skipped.
FOUNDATION_EXPORT NSArray *NeoWCPrivateGroupContactList(void);

/// Builds and pushes WeChat's native profile controller.
/// @param source Visible source controller whose navigation controller performs the push.
/// @param userName WeChat username to resolve and inject into the native controller.
/// @return YES only after a controller was constructed, injected, and pushed.
/// @discussion Must be called on the main thread. Uses `setM_contact:` when its object ABI is
/// available and falls back to KVC; missing contacts/controllers/navigation return NO.
FOUNDATION_EXPORT BOOL NeoWCPushPrivateContactProfile(UIViewController *source,
                                                      NSString *userName);

/// Builds, injects, and pushes WeChat's native group profile controller.
/// @param source Visible source controller whose navigation controller performs the push.
/// @param groupUserName Stable group username ending in `@chatroom`.
/// @return YES only after the group contact was resolved, injected, and pushed.
/// @discussion Must be called on the main thread. Constructs `ChatRoomInfoViewController`, then
/// injects `m_chatRoomContact` through a verified object setter or KVC before navigation. Older
/// versions without the class, contact, setter/KVC field, or navigation controller return NO.
FOUNDATION_EXPORT BOOL NeoWCPushPrivateGroupProfile(UIViewController *source,
                                                    NSString *groupUserName);

/// Opens WeChat's native chat page through its message-logic service.
/// @param source Optional source used to locate a navigation controller; nil uses WeChat's
/// current navigation-controller class method.
/// @param userName Contact or `@chatroom` username passed to WeChat without rewriting,
/// trimming, suffix checks, or display-name inference.
/// @param animated Whether WeChat should animate the native transition.
/// @return YES when already in the target chat or after the native push selector is invoked.
/// @discussion Must be called on the main thread. Resolves the contact before calling the
/// object/object/BOOL `PushOtherBaseMsgControllerByContact:navigationController:animated:` ABI;
/// an older username variant is the only fallback. Missing/mismatched selectors, services,
/// contacts, navigation, exceptions, and empty usernames return NO. Nonempty content is not
/// format-validated so diagnostic callers can test WeChat's own acceptance behavior.
FOUNDATION_EXPORT BOOL NeoWCPushPrivateChat(UIViewController * _Nullable source,
                                            NSString *userName,
                                            BOOL animated);

/// Extracts an official masked recipient name from a transfer-verification response.
/// @param response A `WCPayBeforeTransferCgi` response or known nested response container.
/// @return A trimmed masked value such as `**明`, or nil when no value containing `*`/`＊`
/// is present. Full unmasked names are deliberately rejected and never returned.
/// @discussion May run on the callback thread. WCR-confirmed fields are checked first, followed
/// by guarded WeChatX compatibility fields and nested containers to depth three. Missing
/// selectors, KVC failures, unsupported shapes, and empty values return nil.
FOUNDATION_EXPORT NSString * _Nullable NeoWCPrivateMaskedTransferName(id _Nullable response);

/// Returns the final visible composed character of an official masked recipient name.
/// @param maskedName A value previously returned by `NeoWCPrivateMaskedTransferName`.
/// @return The last non-mask, non-wrapper visible character, or nil for invalid/unmasked input.
/// @discussion Thread-safe and local-only. This never reconstructs hidden characters; malformed
/// values and values without `*`/`＊` return nil on every supported WeChat version.
FOUNDATION_EXPORT NSString * _Nullable NeoWCPrivateMaskedTransferNameSuffix(NSString * _Nullable maskedName);

/// Invites one contact into a saved group through WeChat's native group manager.
/// @param groupUserName Target username ending in `@chatroom`.
/// @param memberUserName Non-group WeChat username to invite.
/// @return Submitted, rejected, or unsupported; submitted does not imply server acceptance.
/// @discussion Call on the main thread. Tries the current six-argument ABI before older
/// two-object invite/add ABIs; a signature mismatch is treated as unsupported.
FOUNDATION_EXPORT NeoWCPrivateGroupInvitationResult
NeoWCPrivateInviteGroupMember(NSString *groupUserName, NSString *memberUserName);

NS_ASSUME_NONNULL_END
