import Foundation
import UIKit
import WordPressData
import WordPressKit

extension Foundation.Notification.Name {
    /// Posted whenever the in-app Notifications bell state changes. Lets the
    /// legacy Objective-C tab bar observe the state without KVO on the
    /// deprecated `applicationIconBadgeNumber`.
    static let notificationActivityDidChange = Foundation.Notification.Name("NotificationActivityDidChangeNotification")
}

/// Account-bound remote used by ``NotificationActivityService``.
///
/// `markSeen` throws ``NotificationActivityServiceRemote/SeenRejectedError``
/// when the server rejects the timestamp. The service treats any other error as
/// transient.
protocol NotificationActivityRemote {
    func fetchHasUnseenNotes() async throws -> Bool
    func markSeen(timestamp: Date) async throws
}

extension NotificationActivityServiceRemote: NotificationActivityRemote {}

/// The default WordPress.com account, with a remote bound to its credentials.
struct NotificationActivityAccount {
    let uuid: String
    /// `nil` while the account's credentials are unavailable.
    let remote: NotificationActivityRemote?
}

/// Resolves the current default WordPress.com account.
protocol NotificationActivityAccountResolving {
    /// The default account, or `nil` when there is none.
    func defaultAccount() -> NotificationActivityAccount?
}

/// The single owner of the in-app Notifications bell state and the public API
/// for it.
///
/// The bell means "new WordPress activity since Notifications was last marked
/// seen", account-scoped and independent of the home-screen icon badge. This
/// service owns what is app-wide: the default-account lifecycle, list
/// visibility, the home-screen icon, and the change notification. Everything
/// bound to one account (the refresh, the seen submission and retry, and the
/// saved snapshot) lives in a ``NotificationActivityAccountSession``. All
/// state is main-actor isolated.
///
/// A session belongs to one account. Losing that account's credentials pauses
/// its network work but keeps the session and its saved state; only a sign-out
/// or a different default account replaces it.
@MainActor
final class NotificationActivityService: ObservableObject {
    static let shared = NotificationActivityService()

    /// True when there is new WordPress notification activity to surface.
    @Published private(set) var hasNewActivity = false

    // Dependencies
    private let resolver: NotificationActivityAccountResolving
    private let store: NotificationActivityStore
    private let iconBadge: AppIconBadgeWriting
    private let notificationCenter: NotificationCenter
    private let isForeground: @MainActor () -> Bool

    /// The current default account's session; `nil` while signed out.
    private var session: NotificationActivityAccountSession?

    // Visibility. Several lists can be on screen at once (tab, split view,
    // popover), and one can appear before another disappears, so each list
    // holds its own visibility.
    private var visibleLists: Set<ObjectIdentifier> = []
    private var isNotificationsVisible: Bool { !visibleLists.isEmpty }

    private var observers: [NSObjectProtocol] = []

    init(
        resolver: NotificationActivityAccountResolving = DefaultNotificationActivityAccountResolver(),
        store: NotificationActivityStore = NotificationActivityStore(),
        iconBadge: AppIconBadgeWriting = AppIconBadgeController(),
        notificationCenter: NotificationCenter = .default,
        isForeground: @escaping @MainActor () -> Bool = { UIApplication.shared.applicationState != .background }
    ) {
        self.resolver = resolver
        self.store = store
        self.iconBadge = iconBadge
        self.notificationCenter = notificationCenter
        self.isForeground = isForeground
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
    }

    /// Starts the service: restores the current account's snapshot, subscribes to
    /// account, foreground, sync, and PingHub triggers, and refreshes. Call once
    /// at launch.
    func start() {
        observe(.wpAccountDefaultWordPressComAccountChanged) { [weak self] _ in
            self?.defaultAccountDidChange()
        }
        observe(UIApplication.didBecomeActiveNotification) { [weak self] _ in
            // Not gated on an account: a failed sign-out clear must still land.
            self?.iconBadge.retryPendingWrite()
            self?.refresh()
        }
        observe(Foundation.Notification.Name(rawValue: NotificationSyncMediatorDidUpdateNotifications)) {
            [weak self] _ in
            self?.notedPossibleActivity()
        }
        observe(.pingHubActivity) { [weak self] _ in
            self?.notedPossibleActivity()
        }
        configureForCurrentAccount(restore: true)
    }

    // MARK: - Account lifecycle

    /// `WPAccount.handleInvalidToken` posts the default-account notification too,
    /// while the account stays the default. That is a credential change, not an
    /// account change: keep the session, including a pending seen write, and
    /// pause or resume network work with the credentials.
    private func defaultAccountDidChange() {
        if let account = resolver.defaultAccount(), let session, account.uuid == session.accountUUID {
            session.remote = account.remote
            session.refresh()
            return
        }
        configureForCurrentAccount(restore: false)
    }

    /// Replaces the session for the current default account and clears
    /// published state.
    ///
    /// Visibility is left alone because it describes the screen, not the
    /// account. A Notifications list that stays visible across an account change
    /// keeps the new account's bell clear, and its callbacks are accepted once it
    /// rebinds to the new account, whichever observer runs first.
    ///
    /// - Parameter restore: When `true` (a process restart), restores a saved
    ///   snapshot if it belongs to the default account. When `false` (a sign-in,
    ///   sign-out, or account change), always starts empty.
    private func configureForCurrentAccount(restore: Bool) {
        session?.invalidate()
        session = nil
        setActivity(false)

        // An explicit sign-out or account change (restore == false) clears the
        // icon; a process restart (restore == true) never does, so a badge iOS is
        // showing from earlier pushes survives a relaunch.
        if !restore {
            iconBadge.setBadgeCount(0)
        }

        guard let account = resolver.defaultAccount() else {
            // A restore before any default account exists keeps saved state; a
            // sign-out wipes it.
            if !restore {
                store.clear()
            }
            return
        }

        let session = NotificationActivityAccountSession(
            account: account,
            store: store,
            restore: restore,
            isForeground: isForeground,
            isNotificationsVisible: { [weak self] in self?.isNotificationsVisible ?? false },
            onActivityChange: { [weak self] in self?.setActivity($0) }
        )
        self.session = session
        setActivity(session.hasActivity)
        session.refresh()
    }

    /// Recovers credentials for the session. A same-account re-auth after a
    /// token invalidation posts nothing this service observes and may not
    /// background the app, so account-gated entry points call this first.
    ///
    /// - Returns: `true` when it started a new session, which already refreshes.
    @discardableResult
    private func resolveAccountIfNeeded() -> Bool {
        guard session?.remote == nil, let account = resolver.defaultAccount(), let resolved = account.remote else {
            return false
        }
        if let session, account.uuid == session.accountUUID {
            session.remote = resolved
            return false
        }
        // An account appeared or changed without a notification reaching this
        // service.
        configureForCurrentAccount(restore: session == nil)
        return true
    }

    /// The session when it belongs to `accountUUID`. A callback bound to another
    /// account is ignored, so a list that has not rebound after an account
    /// change cannot mark the new account seen with the old account's timestamp.
    private func session(for accountUUID: String?) -> NotificationActivityAccountSession? {
        guard let session, let accountUUID, accountUUID == session.accountUUID else {
            return nil
        }
        return session
    }

    // MARK: - Refresh

    /// Refreshes the bell from the backend for the current account.
    func refresh() {
        guard !resolveAccountIfNeeded() else { return }
        session?.refresh()
    }

    /// A push, PingHub event, reconnect, or successful sync signals that state
    /// may have changed. It is a reason to refresh, not proof the bell is `true`.
    func notedPossibleActivity() {
        iconBadge.retryPendingWrite()
        guard !resolveAccountIfNeeded() else { return }
        session?.notedPossibleActivity()
    }

    // MARK: - Opening Notifications and seen updates

    /// The Notifications list `list`, bound to the account identified by
    /// `accountUUID`, became visible: publish the clear, persist it, request an
    /// icon clear, and submit the newest observed timestamp as seen.
    func notificationsBecameVisible(_ list: AnyObject, accountUUID: String?, newestTimestamp: Date?) {
        resolveAccountIfNeeded()
        guard let session = session(for: accountUUID) else { return }
        visibleLists.insert(ObjectIdentifier(list))
        iconBadge.setBadgeCount(0)
        session.listBecameVisible(newestTimestamp: newestTimestamp)
    }

    /// The visible `list` bound to `accountUUID` received newer content: submit
    /// the newer timestamp.
    func notificationsListDidUpdate(_ list: AnyObject, accountUUID: String?, newestTimestamp: Date?) {
        guard visibleLists.contains(ObjectIdentifier(list)), let session = session(for: accountUUID),
            let newestTimestamp
        else {
            return
        }
        session.enqueueSeen(newestTimestamp)
    }

    /// `list` left the screen. Once no list is visible, the visibility
    /// suppression ends and a refresh follows any pending seen write. A pre-open
    /// response cannot relight the bell because the revision advanced when the
    /// list opened.
    ///
    /// This takes no account: clearing visibility cannot attribute one account's
    /// content to another.
    func notificationsResignedVisible(_ list: AnyObject) {
        guard visibleLists.remove(ObjectIdentifier(list)) != nil else { return }
        refresh()
    }

    // MARK: - Home-screen icon

    /// Applies a WordPress push badge count. A push processed while Notifications
    /// is visible in the foreground keeps the icon at zero. When the app is not
    /// in the foreground the push count is applied as-is, so backgrounding with
    /// Notifications on screen does not clear a badge iOS just set.
    func applyPushBadgeCount(_ count: Int) {
        let suppress = isForeground() && isNotificationsVisible
        iconBadge.setBadgeCount(suppress ? 0 : count)
    }

    /// Requests an icon count of zero (sign-out, disabling notifications, or a
    /// welcome-notification clear).
    func requestIconClear() {
        iconBadge.setBadgeCount(0)
    }

    /// Re-evaluates indicators that also depend on inputs outside this service,
    /// such as the welcome-notification-seen flag on the legacy tab bar. Posting
    /// the change notification makes those observers re-render.
    func refreshIndicators() {
        notificationCenter.post(name: .notificationActivityDidChange, object: nil)
    }

    // MARK: - Helpers

    private func setActivity(_ value: Bool) {
        guard value != hasNewActivity else { return }
        hasNewActivity = value
        notificationCenter.post(name: .notificationActivityDidChange, object: nil)
    }

    private func observe(
        _ name: Foundation.Notification.Name,
        using block: @escaping (Foundation.Notification) -> Void
    ) {
        let token = notificationCenter.addObserver(forName: name, object: nil, queue: .main) { note in
            MainActor.assumeIsolated { block(note) }
        }
        observers.append(token)
    }
}

// MARK: - Non-isolated entry points for legacy callers

extension NotificationActivityService {
    /// A WordPress push updated the badge. Applies the icon count and treats the
    /// push as a reason to refresh the bell (a foreground push otherwise triggers
    /// no sync, so the indicator would stay stale). Safe to call from
    /// non-main-actor code.
    ///
    /// On the main thread the count applies before returning: a tapped push opens
    /// Notifications right after this call, and a deferred write would land after
    /// the list's icon clear.
    nonisolated static func pushDidUpdateBadge(count: Int) {
        let apply: @MainActor () -> Void = {
            shared.applyPushBadgeCount(count)
            shared.notedPossibleActivity()
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated(apply)
        } else {
            Task { @MainActor in apply() }
        }
    }

    /// Clears the home-screen icon badge. Safe to call from non-main-actor code.
    nonisolated static func clearAppIconBadge() {
        Task { @MainActor in shared.requestIconClear() }
    }
}

// MARK: - Account session

/// Bell state and network work for one signed-in WordPress.com account.
///
/// ``NotificationActivityService`` creates one session per default account and
/// drops it on sign-out or account change. Its Tasks hold it weakly, so a
/// dropped session normally deallocates and its in-flight results go nowhere.
/// ``invalidate()`` covers the session that is still on the stack when the
/// owner replaces it: it drops the credentials so no new request starts, and
/// it stops reporting and persisting.
///
/// A `revision` guards against a fetch overwriting a newer local clear or
/// activity event that happened while the fetch was in flight.
///
/// Visibility belongs to the screen, not the account, so the owner supplies
/// `isNotificationsVisible`; the session reads it when a fetch starts.
@MainActor
private final class NotificationActivityAccountSession {
    let accountUUID: String

    /// Bound to the account's credentials; `nil` while they are unavailable.
    /// Network work pauses while `nil` and resumes when the owner rebinds it.
    var remote: NotificationActivityRemote?

    /// Bell state for this account.
    private(set) var hasActivity = false

    private let store: NotificationActivityStore
    private let isForeground: @MainActor () -> Bool
    private let isNotificationsVisible: @MainActor () -> Bool
    /// Not called for the restored value; read `hasActivity` after init.
    private let onActivityChange: @MainActor (Bool) -> Void
    private var isInvalidated = false

    // Seen state
    private var acknowledgedSeen: Date?
    private var pendingSeen: Date?
    private var isSubmittingSeen = false

    // Refresh coalescing + revision
    private var isFetching = false
    private var needsFollowUpFetch = false
    private var revision = 0

    /// - Parameter restore: When `true` (a process restart), restores the saved
    ///   snapshot if it belongs to this account. Otherwise starts with a plain
    ///   bell and overwrites any stale snapshot.
    init(
        account: NotificationActivityAccount,
        store: NotificationActivityStore,
        restore: Bool,
        isForeground: @escaping @MainActor () -> Bool,
        isNotificationsVisible: @escaping @MainActor () -> Bool,
        onActivityChange: @escaping @MainActor (Bool) -> Void
    ) {
        accountUUID = account.uuid
        remote = account.remote
        self.store = store
        self.isForeground = isForeground
        self.isNotificationsVisible = isNotificationsVisible
        self.onActivityChange = onActivityChange

        if restore, let snapshot = store.load(), snapshot.accountUUID == account.uuid {
            acknowledgedSeen = snapshot.acknowledgedSeen
            pendingSeen = snapshot.pendingSeen
            hasActivity = snapshot.hasActivity
        } else {
            persist()
        }
    }

    func invalidate() {
        isInvalidated = true
        remote = nil
    }

    // MARK: - Refresh

    /// Refreshes the bell from the backend. Coalesces concurrent requests, runs
    /// only in the foreground with credentials, no visible list, and no pending
    /// seen write, and first drains any pending seen retry.
    func refresh() {
        guard isForeground(), let remote else {
            return
        }
        submitPendingSeenIfNeeded()

        // A visible list keeps the bell clear, and while a seen write is pending
        // the server can still report the pre-visit `true`, so a fetch result
        // would be discarded either way. The owner refreshes once the list
        // leaves, and `finishSeen` refreshes once the write lands.
        guard !isNotificationsVisible(), pendingSeen == nil else {
            return
        }
        guard !isFetching else {
            needsFollowUpFetch = true
            return
        }
        isFetching = true
        let startRevision = revision
        Task { @MainActor [weak self] in
            do {
                let hasUnseen = try await remote.fetchHasUnseenNotes()
                self?.finishFetch(startRevision: startRevision, result: .success(hasUnseen))
            } catch {
                self?.finishFetch(startRevision: startRevision, result: .failure(error))
            }
        }
    }

    private func finishFetch(startRevision: Int, result: Result<Bool, Error>) {
        isFetching = false
        let coalescedRefresh = needsFollowUpFetch
        needsFollowUpFetch = false
        var staleNeedsRefetch = false

        switch result {
        case .success(let hasUnseen):
            if revision != startRevision {
                // A newer local clear or activity event happened during the
                // fetch; its result is stale. Re-fetch.
                staleNeedsRefetch = true
            } else if hasUnseen != hasActivity {
                setActivity(hasUnseen)
                persist()
            }
        case .failure:
            // Transport/auth/decoding error: preserve the last known state.
            break
        }

        if coalescedRefresh || staleNeedsRefetch {
            refresh()
        }
    }

    /// A push, PingHub event, reconnect, or successful sync signals that state
    /// may have changed. It is a reason to refresh, not proof the bell is `true`.
    func notedPossibleActivity() {
        guard remote != nil else { return }
        revision &+= 1
        refresh()
    }

    // MARK: - Visible list and seen updates

    /// A Notifications list for this account became visible: clear the bell,
    /// persist the clear, and submit the newest observed timestamp as seen.
    func listBecameVisible(newestTimestamp: Date?) {
        revision &+= 1
        setActivity(false)
        if let newestTimestamp {
            enqueueSeen(newestTimestamp)
        }
        persist()
    }

    /// Submits `timestamp` as seen once it is newer than anything acknowledged
    /// or pending.
    func enqueueSeen(_ timestamp: Date) {
        // Seen only moves forward: skip anything at or before the acknowledged
        // timestamp, and keep only the newest pending one.
        if let acknowledgedSeen, timestamp <= acknowledgedSeen {
            return
        }
        if let pendingSeen, pendingSeen >= timestamp {
            return
        }
        pendingSeen = timestamp
        persist()
        submitPendingSeenIfNeeded()
    }

    private func submitPendingSeenIfNeeded() {
        guard isForeground(), !isSubmittingSeen, let remote, let timestamp = pendingSeen else {
            return
        }
        isSubmittingSeen = true
        Task { @MainActor [weak self] in
            do {
                try await remote.markSeen(timestamp: timestamp)
                self?.finishSeen(submitted: timestamp, error: nil)
            } catch {
                self?.finishSeen(submitted: timestamp, error: error)
            }
        }
    }

    private func finishSeen(submitted: Date, error: Error?) {
        isSubmittingSeen = false
        if let error {
            handleSeenFailure(error)
            return
        }
        acknowledgedSeen = max(acknowledgedSeen ?? submitted, submitted)
        if let pendingSeen, pendingSeen <= submitted {
            self.pendingSeen = nil
        }
        persist()

        if pendingSeen != nil {
            submitPendingSeenIfNeeded() // Drain a newer pending timestamp first.
        } else {
            // Re-check the bool: activity newer than the visit can light the bell.
            refresh()
        }
    }

    /// Transient failures (offline, authentication, rate limiting, server errors)
    /// keep the local clear and pending timestamp for the next foreground,
    /// reconnect, or activity trigger, with no limit and across restarts. A
    /// server rejection drops the timestamp: retrying the same value cannot
    /// succeed, and a timestamp kept pending would block every fetch forever,
    /// even after a relaunch.
    private func handleSeenFailure(_ error: Error) {
        guard error is NotificationActivityServiceRemote.SeenRejectedError else {
            return
        }
        Loggers.app.error("Dropping rejected notifications/seen timestamp")
        pendingSeen = nil
        persist()
        refresh()
    }

    // MARK: - Helpers

    private func setActivity(_ value: Bool) {
        guard !isInvalidated, value != hasActivity else { return }
        hasActivity = value
        onActivityChange(value)
    }

    private func persist() {
        guard !isInvalidated else { return }
        store.save(
            NotificationActivitySnapshot(
                accountUUID: accountUUID,
                hasActivity: hasActivity,
                acknowledgedSeen: acknowledgedSeen,
                pendingSeen: pendingSeen
            )
        )
    }
}

// MARK: - Default account resolver

struct DefaultNotificationActivityAccountResolver: NotificationActivityAccountResolving {
    func defaultAccount() -> NotificationActivityAccount? {
        // Runs on the main actor, matching `mainContext`'s queue.
        let context = ContextManager.shared.mainContext
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context),
            let uuid = account.uuid
        else {
            return nil
        }
        // Read `authToken` directly. The `wordPressComRestApi` getter has side
        // effects when the token is missing: it posts the notification that
        // presents a sign-in screen. Guarding on the token first avoids
        // presenting sign-in as a side effect of a badge refresh (same rule as
        // DashboardCard).
        guard let authToken = account.authToken, !authToken.isEmpty,
            let api = account.wordPressComRestApi
        else {
            return NotificationActivityAccount(uuid: uuid, remote: nil)
        }
        return NotificationActivityAccount(
            uuid: uuid,
            remote: NotificationActivityServiceRemote(wordPressComRestApi: api)
        )
    }
}
