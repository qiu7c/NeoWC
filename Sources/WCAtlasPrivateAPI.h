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

/// Resolves the owning chat controller from a WeChat `MMInputToolView` instance.
/// @param inputToolView The live input toolbar receiving the gesture or send callback.
/// @return Its visible `BaseMsgContentViewController`, or the global current-chat fallback.
/// @discussion Main-thread only. Tries the current no-argument object-return selectors
/// `getViewController` and `GetCurrentViewController`, then guarded delegate/parent fields and
/// the UIKit responder chain. Every candidate must resolve to a visible chat controller;
/// unsupported selectors and incompatible return ABIs are skipped without invocation.
FOUNDATION_EXPORT UIViewController * _Nullable WCAtlasPrivateChatControllerForInputToolView(
    id _Nullable inputToolView);

/// Resolves the exact friend/group username represented by a live WeChat input toolbar.
/// @param inputToolView The `MMInputToolView` associated with the active conversation.
/// @return A trimmed username such as a wxid or `...@chatroom`, or nil when unavailable.
/// @discussion Main-thread only. Uses the verified no-argument object-return paths
/// `getChatName`, `currentChatId`, and `currentSessionId`, then the toolbar contact and owning
/// controller. Empty values and unsupported versions fall through to the global chat adapter.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateChatUserNameForInputToolView(
    id _Nullable inputToolView);

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

/// Resolves a member's display name inside a specific WeChat group.
/// @param groupContact Group contact that owns the member-card naming context.
/// @param memberContact Contact whose room alias/display name is requested.
/// @return The room-specific display name, then unified contact display name, or nil.
/// @discussion Call on the main thread. Tries the verified object/object display-name selectors
/// on the contact service and group contact. Missing selectors, incompatible ABI, nil contacts,
/// and exceptions fall back to the unified remark/nickname reader without changing either object.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateGroupMemberDisplayName(id _Nullable groupContact,
                                                                           id _Nullable memberContact);

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

/// Resolves WeChat's native homepage session model for a table row.
/// @param owner Main-frame controller or its active table delegate.
/// @param tableView Native homepage table containing the row.
/// @param indexPath Native, unmodified index path supplied by WeChat.
/// @return The native session/contact model, or nil for non-session and unsupported rows.
/// @discussion Main-thread only. Tries the verified main-frame accessors first, then the reused
/// cell and active delegate. Object return/argument ABI is checked; exceptions and unavailable
/// selectors fall through without modifying the table or session database.
FOUNDATION_EXPORT id _Nullable WCAtlasPrivateHomeSessionData(id _Nullable owner,
                                                             UITableView * _Nullable tableView,
                                                             NSIndexPath * _Nullable indexPath);

/// Reads the stable wxid/chatroom identifier from a native homepage session model.
/// @param sessionData Object returned by `WCAtlasPrivateHomeSessionData`.
/// @return A non-empty wxid/chatroom identifier, or nil when the row is not a session.
/// @discussion Thread-safe for an already-owned model. Uses the unified contact field reader and
/// recursively checks native cell-data, session-info, and contact wrappers with a bounded depth;
/// unsupported layouts and cycles return nil.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateHomeSessionUserName(id _Nullable sessionData);

/// Replaces WCAtlas's synthetic category sessions in WeChat's native homepage session array.
/// @param sessionManager A live `MainSessionMgr` instance received by its update hooks.
/// @param hiddenUserNames Stable chatroom usernames that should be removed from the native root list.
/// @param categoryEntries Ordered dictionaries containing nonempty `userName` and `title` strings,
/// an optional `subtitle` string, and an optional `sessionUserNames` string array. The array names
/// the real conversations whose native unread counts should be aggregated into the category row.
/// One native `MMSessionInfo` is created for each valid entry.
/// @return YES after a compatible mutable `normalSessions` snapshot was filtered and written back;
/// NO leaves WeChat's original session array untouched.
/// @discussion Main-thread only. Existing WCAtlas synthetic sessions are removed first, assigned
/// chatrooms are hidden, and replacement sessions are inserted immediately after native pinned
/// sessions. The adapter verifies object getter/setter ABIs and uses guarded KVC only for scalar
/// fields whose concrete widths vary between WeChat versions. Member sessions are resolved through
/// the service-center `MMNewSessionMgr` and `GetSessionByUserName:`; unread getters accept either
/// integer or NSNumber return ABIs, then guarded KVC is the older-version fallback. Missing classes,
/// malformed entries, incompatible accessors, or exceptions fail closed; no database rows are
/// created or modified.
FOUNDATION_EXPORT BOOL WCAtlasPrivateReplaceHomeCategorySessions(
    id _Nullable sessionManager,
    NSSet<NSString *> *hiddenUserNames,
    NSArray<NSDictionary *> *categoryEntries);

/// Returns the in-memory native synthetic session for a WCAtlas category username.
/// @param userName Exact synthetic username previously supplied in a category entry.
/// @return The current `MMSessionInfo`, or nil when disabled, stale, or unsupported.
/// @discussion Main-thread only. This is an in-memory bridge for `MMNewSessionMgr` lookup hooks;
/// it never queries or writes WeChat's session database and has no older-version fallback.
FOUNDATION_EXPORT id _Nullable WCAtlasPrivateHomeCategorySession(NSString * _Nullable userName);

/// Applies category title/subtitle text to a native `MainFrameCellData` object.
/// @param cellData The native cell model after its original formatter has run.
/// @param title Nonempty first-level category title.
/// @param subtitle Optional secondary text; pass an empty string for a title-only category row.
/// @param avatarUserName Optional native conversation username whose avatar should represent the category.
/// @return YES when the three object setters for name, message, and time labels are compatible.
/// @discussion Main-thread only. The adapter writes title, subtitle, and an empty time label in
/// that order, then invokes the optional no-argument `updateWidthForNameLabel`. Missing required
/// object-setter ABI or exceptions return NO and retain WeChat's original formatting.
FOUNDATION_EXPORT BOOL WCAtlasPrivateConfigureHomeCategoryCellData(id _Nullable cellData,
                                                                  NSString *title,
                                                                  NSString *subtitle,
                                                                  NSString * _Nullable avatarUserName);

/// Requests a native homepage-session refresh after WCAtlas category settings change.
/// @return YES after invoking `updateMainSessionListNotify:` or the older
/// `updateMainSessionList` fallback on the service-center `MainSessionMgr` instance.
/// @discussion Main-thread only. The BOOL notification variant is preferred and called with YES;
/// the no-argument void selector is the only fallback. Missing service/classes, mismatched ABI,
/// and Objective-C exceptions return NO without touching the visible table directly.
FOUNDATION_EXPORT BOOL WCAtlasPrivateRefreshHomeSessionList(void);

/// Reads the official ordered mention-user list for a WeChat rich-text message view.
/// @param richTextView Native `RichTextView` currently receiving message styles.
/// @return Ordered wxids from the message's official `m_nsAtUserList`, or an empty array.
/// @discussion Main-thread only. Resolves the native cell through its link delegate/responder
/// chain, then the current message wrap. Missing fields, unsupported view-model layouts, malformed
/// values, and exceptions return an empty array; visible text is never used to guess identities.
FOUNDATION_EXPORT NSArray<NSString *> *WCAtlasPrivateMentionUserNames(id _Nullable richTextView);

/// Resolves the group conversation that owns a native rich-text message view.
/// @param richTextView Native `RichTextView` currently receiving message styles.
/// @return The official chatroom username from the message wrap's from/to/real-chat fields, or nil.
/// @discussion Main-thread only. The message wrap is resolved from WeChat's link/layout delegates,
/// responder chain, and superview hierarchy. Only a value ending in `@chatroom` is returned; the
/// visible controller is not used as identity evidence. Missing fields, unsupported hierarchies,
/// and exceptions return nil, allowing the caller to preserve WeChat's original styles.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateMentionChatUserName(id _Nullable richTextView);

/// Enables native rich-text click dispatch for an injected mention link.
/// @param richTextView Native `RichTextView` receiving the injected `LinkStyle`.
/// @return YES when WeChat's BOOL/integer `setBHandleTextClick:` ABI was verified and invoked.
/// @discussion Main-thread only. This is applied after a valid mention style is created. Missing
/// selectors, non-void return ABI, non-integer argument ABI, or exceptions return NO; visual
/// highlighting may still work while click navigation remains unavailable on that version.
FOUNDATION_EXPORT BOOL WCAtlasPrivateEnableMentionClickHandling(id _Nullable richTextView);

/// Binds a text-message cell's official message wrap to its native rich-text view.
/// @param cell A live `TextMessageCellView` received by the verified `setViewModel:` hook.
/// @param viewModel The exact object passed to WeChat's original setter; may itself be a message wrap.
/// @param refresh Whether to replay the rich view's current styles/content after the original setter.
/// @return YES when a rich-text view and official message wrap were resolved and associated.
/// @discussion Main-thread only. Call once before the original setter with refresh=NO, then once
/// after it with refresh=YES. Message identity comes only from native wrap fields. The refresh path
/// invokes `setArrStyles:withContent:` only after verifying its void/object/object ABI. Unsupported
/// layouts return NO and leave WeChat rendering unchanged; no visible text is used to infer wxids.
FOUNDATION_EXPORT BOOL WCAtlasPrivateBindMentionContext(id _Nullable cell,
                                                        id _Nullable viewModel,
                                                        BOOL refresh);

/// Builds a native WeChat `LinkStyle` for one UTF-16 text range.
/// @param range Range in the exact NSString passed to WeChat's rich-text style method.
/// @param URLString Opaque URL delivered back through WeChat's native link event.
/// @param normalColor Normal foreground/link color.
/// @param highlightedColor Touch-highlight color.
/// @return A fully initialized native style, or nil when the class/fields are unsupported.
/// @discussion Main-thread only. Uses KVC-compatible native fields with ordered version fallbacks;
/// any missing required range/URL field or exception returns nil instead of a partial style.
FOUNDATION_EXPORT id _Nullable WCAtlasPrivateMentionLinkStyle(NSRange range,
                                                              NSString *URLString,
                                                              UIColor *normalColor,
                                                              UIColor *highlightedColor);

/// Extracts the native link URL from a WeChat rich-text click event or style object.
/// @param event String, URL, dictionary, event wrapper, or native link-style object.
/// @return URL text when exposed by a compatible object field, otherwise nil.
/// @discussion Main-thread only. Traversal is cycle-checked and depth-limited. Unsupported event
/// layouts and exceptions return nil and preserve WeChat's original click handling.
FOUNDATION_EXPORT NSString * _Nullable WCAtlasPrivateMentionLinkURLString(id _Nullable event);

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
/// available and falls back to KVC, then best-effort injects `m_chatContact` for group-member
/// context. Missing contacts/controllers/navigation return NO; unavailable secondary context
/// does not prevent the normal profile-page fallback.
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
