#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WCAtlasPrivateGroupInvitationResult) {
    WCAtlasPrivateGroupInvitationResultUnsupported = 0,
    WCAtlasPrivateGroupInvitationResultRejected,
    WCAtlasPrivateGroupInvitationResultSubmitted,
};

/// Returns a WeChat service through the compatibility-aware service center.
/// @param className WeChat service class name. Empty names are rejected.
/// @return The shared service instance, or nil when the class/service center is unavailable.
/// @discussion Call on the main thread unless the concrete service documents otherwise.
/// Version fallback is handled by `WCAtlasServiceForClass`; no service selector is called here.
FOUNDATION_EXPORT id _Nullable WCAtlasPrivateService(NSString *className);

/// Resolves the currently visible WeChat chat controller.
/// @return A visible `BaseMsgContentViewController`, or nil outside a chat/unavailable versions.
/// @discussion Must be called on the main thread. Searches foreground windows, presented,
/// navigation, tab, and child controller trees; hidden/detached controllers are rejected.
/// The class-name check is the stable fallback when no cached chat controller is available.
FOUNDATION_EXPORT UIViewController * _Nullable WCAtlasPrivateCurrentChatController(void);

/// Resolves the contact object owned by a WeChat chat controller.
/// @param chatController A current or explicitly supplied chat controller.
/// @return The chat contact, or nil when all guarded getters/fields are unavailable.
/// @discussion Call on the main thread. Tries `GetContact`, then `GetCContact`, followed by
/// object fields used by older builds. Every getter must have a no-argument object-return ABI.
FOUNDATION_EXPORT id _Nullable WCAtlasPrivateChatContact(id _Nullable chatController);

/// Resolves the username represented by a WeChat chat controller.
/// @param chatController A current chat controller, or nil to resolve the visible controller.
/// @return A nonempty WeChat username, or nil when the chat/contact fields cannot be read.
/// @discussion Call on the main thread. Uses WCR's `getCurrentChatName` and the WeChatX-evidenced
/// `getChatUserName` direct paths, then `GetContact`/`GetCContact` contact fields, then older fields. Unsupported
/// selectors, ABI mismatches, exceptions, and empty strings fall through to the next version path.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateChatUserName(id _Nullable chatController);

/// Resolves a contact using the known cache and database selectors.
/// @param userName WeChat username, not a display name or alias.
/// @return A contact returned by a supported selector, preferring a result carrying a nonempty
/// remark; otherwise the first valid result, or nil on absence/failure.
/// @discussion Call on the main thread. Database selectors are attempted before cache fallbacks;
/// all supported paths are checked when an earlier result lacks a remark. Unsupported selectors
/// and Objective-C exceptions are treated as nil.
FOUNDATION_EXPORT id _Nullable WCAtlasPrivateContact(NSString *userName);

/// Reads the stable username from a WeChat contact/session object.
/// @param contact Contact-like object returned by WeChat services.
/// @return A trimmed username, or nil when no supported object field is available.
/// @discussion Thread-safe for already-owned objects. Tries current `m_nsUsrName` before older
/// username getters/fields; unsupported object-return ABIs and KVC failures return nil.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateContactUserName(id _Nullable contact);

/// Reads the preferred display name for a WeChat contact.
/// @param contact Contact-like object returned by WeChat services.
/// @param fallback Value returned when every supported name field is empty; may be nil.
/// @return Remark/display name/nickname in version order, then fallback, never an inferred name.
/// @discussion Thread-safe for already-owned objects. Object-return getters are ABI-checked;
/// older fields are KVC fallbacks and failures continue to the next candidate.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateContactDisplayName(id _Nullable contact,
                                                                      NSString * _Nullable fallback);

/// Resolves the user-facing name used in WCAtlas-generated notifications.
/// @param userName Stable WeChat username used only to load the contact and as the final fallback.
/// @param eventFallback Optional nickname supplied by the notification event.
/// @return Current contact remark first, then WeChat display name/nickname, eventFallback, and
/// finally userName. Returns nil only when both inputs and every supported contact field are empty.
/// @discussion Call on the main thread because contact lookup uses the active account service.
/// When direct lookup returns a lightweight object without a remark, the complete contact list is
/// searched by exact username or alias. Nicknames are never used as identity keys, so duplicate
/// display names cannot select the wrong remark. Unsupported paths fall through without guessing.
FOUNDATION_EXPORT NSString * _Nullable
WCAtlasPrivateNotificationDisplayName(NSString * _Nullable userName,
                                    NSString * _Nullable eventFallback);

/// Reads the contact nickname, remark, or public WeChat alias respectively.
/// @param contact Contact-like object returned by WeChat services.
/// @return A trimmed value, or nil when the field is empty/unsupported.
/// @discussion Thread-safe for already-owned objects. Current fields are tried before historical
/// selector aliases; exceptions and non-string return values are treated as nil.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateContactNickname(id _Nullable contact);
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateContactRemark(id _Nullable contact);
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateContactAlias(id _Nullable contact);

/// Reads the best available contact avatar URL string.
/// @param contact Contact-like object returned by WeChat services.
/// @return HD/standard avatar URL, or nil when unavailable.
/// @discussion Thread-safe for already-owned objects. This performs no network request and falls
/// back across current and older URL fields.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateContactHeadImageURL(id _Nullable contact);

/// Returns an already-cached contact avatar image without starting a network request.
/// @param contact Contact-like object returned by WeChat services.
/// @return UIImage from `getContactHeadImage`/compatible getters, or nil.
/// @discussion Call on the main thread because UIImage ownership is consumed by UI callers.
/// Unsupported getter ABIs and non-image results return nil without using URL fallbacks.
FOUNDATION_EXPORT UIImage * _Nullable WCAtlasPrivateContactAvatarImage(id _Nullable contact);

/// Builds WeChat's native auto-updating avatar view for a contact.
/// @param contact Contact-like object; may be nil when userName is known.
/// @param userName Username fallback when it cannot be read from contact.
/// @param roundCorner Whether the native helper should apply its own rounded corners.
/// @return A native avatar UIView, a UIImageView for cached images, or nil when unsupported.
/// @discussion Must be called on the main thread. Tries the generic helper, then main-frame and
/// profile helper variants, all with object/object/BOOL/BOOL ABI; cached UIImage is the final
/// fallback. The helper controls asynchronous URL loading when available.
FOUNDATION_EXPORT UIView * _Nullable WCAtlasPrivateContactAvatarView(id _Nullable contact,
                                                                   NSString * _Nullable userName,
                                                                   BOOL roundCorner);

/// Returns WeChat's current contact collection through the unified service center.
/// @return A snapshot array of contact objects, or an empty array when unavailable.
/// @discussion Call on the main thread. The current `getContactList:contactType:` instance
/// selector is invoked only when its object return and two integer arguments match exactly,
/// using the evidenced `(1, 0)` values. Unsupported versions, exceptions, nil, and collections
/// that cannot be enumerated return an empty array rather than a partial guessed result.
FOUNDATION_EXPORT NSArray *WCAtlasPrivateContactList(void);

/// Returns a deduplicated snapshot of known group-chat contact objects.
/// @return Group contacts keyed by their stable `@chatroom` username, possibly empty.
/// @discussion Call on the main thread. Merges the current session list, the compatible contact
/// list, and `ContactsDataLogic.getChatRoomContacts` in that order. No-argument getters must
/// return objects; `isChatroom` is used only with a verified BOOL ABI, while the stable username
/// suffix remains the cross-version fallback. Missing services and failed sources are skipped.
FOUNDATION_EXPORT NSArray *WCAtlasPrivateGroupContactList(void);

#pragma mark - Moments Upload Metadata

/// Builds WeChat's native Moments source-application metadata object.
/// @param appID A nonempty registered WeChat application identifier.
/// @param appName The corresponding nonempty application display name.
/// @return A configured `WCAppInfo` instance, or nil when this WeChat version is unsupported.
/// @discussion May be called on WeChat's upload thread. The current implementation verifies the
/// zero-argument object initializer and the object ABIs of `setAppID:` and `setAppName:` before
/// calling them in that order. Missing classes/selectors, mismatched ABIs, empty fields, and
/// Objective-C exceptions fail closed; older versions receive no fabricated fallback object.
FOUNDATION_EXPORT id _Nullable WCAtlasPrivateCreateMomentsAppInfo(NSString * _Nullable appID,
                                                                NSString * _Nullable appName);

/// Adds the native “发圈尾巴” row to a Moments composer.
/// @param composer A live `WCNewCommitViewController` instance.
/// @param action No-argument action implemented by the composer class.
/// @param rightValue Current source application name, or “无小尾巴”.
/// @return YES after a native cell is created and appended to section zero.
/// @discussion Main-thread only. Verifies the table-manager getters, integer section ABI, native
/// cell factory, and object `addCell:` ABI before preserving WeChat's manager/section/reload order.
/// Current long-form factory is preferred; the evidenced five-argument factory is the only
/// fallback. Unsupported layouts, missing section zero, duplicate installation, and exceptions
/// return NO without creating a UIKit replacement row.
FOUNDATION_EXPORT BOOL WCAtlasPrivateInstallMomentsTailCell(id _Nullable composer,
                                                          SEL action,
                                                          NSString *rightValue);

/// Updates and reloads a previously installed native Moments-tail row.
/// @param composer The composer passed to `WCAtlasPrivateInstallMomentsTailCell`.
/// @param rightValue New source application name, or “无小尾巴”.
/// @discussion Main-thread only. Updates only the retained native cell manager and reloads its
/// owning table. Missing fields and version-specific KVC failures are ignored; no new row is added.
FOUNDATION_EXPORT void WCAtlasPrivateReloadMomentsTailCell(id _Nullable composer,
                                                         NSString *rightValue);

/// Asks a Moments composer to dismiss its native text input before presenting another page.
/// @discussion Main-thread only. Calls the verified no-argument void `resignInput` selector.
/// Unsupported WeChat versions and exceptions are treated as a no-op.
FOUNDATION_EXPORT void WCAtlasPrivateResignMomentsComposerInput(id _Nullable composer);

/// Builds and pushes WeChat's native profile controller.
/// @param source Visible source controller whose navigation controller performs the push.
/// @param userName WeChat username to resolve and inject into the native controller.
/// @return YES only after a controller was constructed, injected, and pushed.
/// @discussion Must be called on the main thread. Uses `setM_contact:` when its object ABI is
/// available and falls back to KVC; missing contacts/controllers/navigation return NO.
FOUNDATION_EXPORT BOOL WCAtlasPushPrivateContactProfile(UIViewController *source,
                                                      NSString *userName);

/// Builds, injects, and pushes WeChat's native group profile controller.
/// @param source Visible source controller whose navigation controller performs the push.
/// @param groupUserName Stable group username ending in `@chatroom`.
/// @return YES only after the group contact was resolved, injected, and pushed.
/// @discussion Must be called on the main thread. Constructs `ChatRoomInfoViewController`, then
/// injects `m_chatRoomContact` through a verified object setter or KVC before navigation. Older
/// versions without the class, contact, setter/KVC field, or navigation controller return NO.
FOUNDATION_EXPORT BOOL WCAtlasPushPrivateGroupProfile(UIViewController *source,
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
FOUNDATION_EXPORT BOOL WCAtlasPushPrivateChat(UIViewController * _Nullable source,
                                            NSString *userName,
                                            BOOL animated);

/// Sends one plain-text message to a stable WeChat username or group username.
/// @param userName Exact destination username, including an `@chatroom` suffix for groups.
/// @param text Nonempty text content. No display-name lookup or target rewriting is performed.
/// @return YES after a message wrapper was constructed and submitted to WeChat's message manager;
/// NO when input, services, constructors, field injection, or send ABI are unavailable.
/// @discussion Must be called on the main thread. Builds a type-1 `CMessageWrap`, injects the
/// current account, destination, content, status, and timestamp, then invokes the verified
/// `AddMsg:MsgWrap:` object/object ABI. Submission does not imply server delivery. Unsupported
/// WeChat versions and Objective-C exceptions fail closed without trying unrelated selectors.
FOUNDATION_EXPORT BOOL WCAtlasPrivateSendTextMessage(NSString *userName,
                                                   NSString *text);

/// Sends a local image through WeChat's native message-provider and forwarding services.
/// @param userName Exact friend or group username.
/// @param imagePath Readable local image path.
/// @return YES after the native forwarding request is submitted; delivery is asynchronous.
/// @discussion Main-thread only. Uses the class object/object `GetMessageFromImage:contact:` ABI,
/// then instance object/object `forwardNoConfirmForMsgList:toContacts:`. Missing contacts, files,
/// classes, selectors, ABI mismatches, decode failures, and exceptions return NO; no legacy is sent.
FOUNDATION_EXPORT BOOL WCAtlasPrivateSendImageMessage(NSString *userName,
                                                    NSString *imagePath);

/// Sends a local video through WeChat's capture-video builder and message manager.
/// @param userName Exact friend or group username.
/// @param videoPath Existing readable local video path.
/// @return YES after a valid video-info object is built and submitted; delivery is asynchronous.
/// @discussion Main-thread only. Builds a thumbnail, prefers the verified high-bitrate
/// `OpenApiMgrHelper` builder when applicable, falls back to `CaptureVideoInfo`, injects its
/// thumbnail path, then calls `AddVideoMsg:ToUsr:VideoInfo:` with current-user/source/target/video
/// objects in that order. Missing classes, ABI mismatches, invalid media, and exceptions return NO.
FOUNDATION_EXPORT BOOL WCAtlasPrivateSendVideoMessage(NSString *userName,
                                                    NSString *videoPath);

/// Sends a local WeChat/Silk voice payload through the native voice uploader.
/// @param userName Exact friend or group username.
/// @param voicePath Existing local encoded voice file.
/// @param durationMilliseconds Duration written into WeChat's voice metadata.
/// @param voiceFormat WeChat voice format value; use 4 for WCAtlas-generated Silk.
/// @return YES after local insertion, file placement, and uploader submission all succeed.
/// @discussion Main-thread only. The adapter verifies `CMessageWrap`, `CMessageMgr`, and
/// `AudioSender` `ResendVoiceMsg:MsgWrap:` object ABIs and preserves WeChat's required order: construct
/// the wrapper, inject fields, AddLocalMsg, derive the destination path, copy bytes, then upload. Unsupported versions
/// and every partial failure return NO without trying unrelated selectors.
FOUNDATION_EXPORT BOOL WCAtlasPrivateSendVoiceMessage(NSString *userName,
                                                    NSString *voicePath,
                                                    NSUInteger durationMilliseconds,
                                                    NSUInteger voiceFormat);

/// Returns whether the unified voice sender is inside its short native-forward upload window.
/// @discussion Thread-safe; used only by the two verified upload-request setter hooks. It returns
/// NO outside an adapter-owned send and naturally expires on unsupported or interrupted versions.
FOUNDATION_EXPORT BOOL WCAtlasPrivateVoiceUploadCompatibilityActive(void);

/// Reads stable fields from one incoming WeChat message wrapper for automation matching.
/// @param message A `CMessageWrap` received by a message-manager callback; it is never modified.
/// @return A dictionary containing session, sender, content, identifier, and fromSelf, or nil for
/// non-text/empty/malformed wrappers.
/// @discussion Safe on the callback thread. Uses guarded KVC against known wrapper fields. Group
/// session selection prefers an `@chatroom` endpoint; private incoming sessions use the sender.
/// Missing fields and older unsupported layouts fail closed and return nil.
FOUNDATION_EXPORT NSDictionary<NSString *, id> * _Nullable
WCAtlasPrivateIncomingTextMessageInfo(id _Nullable message);

/// Extracts an official masked recipient name from a transfer-verification response.
/// @param response A `WCPayBeforeTransferCgi` response or known nested response container.
/// @return A trimmed masked value such as `**明`, or nil when no value containing `*`/`＊`
/// is present. Full unmasked names are deliberately rejected and never returned.
/// @discussion May run on the callback thread. WCR-confirmed fields are checked first, followed
/// by guarded WeChatX compatibility fields and nested containers to depth three. Missing
/// selectors, KVC failures, unsupported shapes, and empty values return nil.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateMaskedTransferName(id _Nullable response);

/// Returns the final visible composed character of an official masked recipient name.
/// @param maskedName A value previously returned by `WCAtlasPrivateMaskedTransferName`.
/// @return The last non-mask, non-wrapper visible character, or nil for invalid/unmasked input.
/// @discussion Thread-safe and local-only. This never reconstructs hidden characters; malformed
/// values and values without `*`/`＊` return nil on every supported WeChat version.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateMaskedTransferNameSuffix(NSString * _Nullable maskedName);

/// Invites one contact into a saved group through WeChat's native group manager.
/// @param groupUserName Target username ending in `@chatroom`.
/// @param memberUserName Non-group WeChat username to invite.
/// @return Submitted, rejected, or unsupported; submitted does not imply server acceptance.
/// @discussion Call on the main thread. Tries the current six-argument ABI before older
/// two-object invite/add ABIs; a signature mismatch is treated as unsupported.
FOUNDATION_EXPORT WCAtlasPrivateGroupInvitationResult
WCAtlasPrivateInviteGroupMember(NSString *groupUserName, NSString *memberUserName);

NS_ASSUME_NONNULL_END
