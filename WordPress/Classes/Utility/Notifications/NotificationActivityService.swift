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
protocol NotificationActivityRemote {
    func fetchHasUnseenNotes() async throws -> Bool
    func markSeen(timestamp: String) async throws
}

extension NotificationActivityServiceRemote: NotificationActivityRemote {}

/// The account whose Notifications state the service currently tracks, with a
/// remote bound to that account's credentials.
struct NotificationActivityAccount {
    let uuid: String
    let remote: NotificationActivityRemote
}

/// Resolves the current default WordPress.com account and a remote for it.
protocol NotificationActivityAccountResolving {
    func currentAccount() -> NotificationActivityAccount?
}

/// The single owner of the in-app Notifications bell state.
///
/// The bell means "new WordPress activity since Notifications was last marked
/// seen", account-scoped and independent of the home-screen icon badge. This
/// service owns the account-wide refresh, the local clear, and the seen
/// submission and retry. All state is main-actor isolated.
///
/// Account isolation relies on a monotonic `generation`: every request captures
/// the generation when it starts, and a result from an old generation is
/// discarded so it can never touch a newer account's UI, storage, or retries.
/// A `revision` guards against a fetch overwriting a newer local clear or
/// activity event that happened while the fetch was in flight.
@MainActor
final class NotificationActivityService: ObservableObject {
    static let shared = NotificationActivityService()

    /// True when there is new WordPress notification activity to surface.
    @Published private(set) var hasNewActivity = false

    // Dependencies
    private let resolver: NotificationActivityAccountResolving
    private let store: NotificationActivityStoring
    private let iconBadge: AppIconBadgeWriting
    private let notificationCenter: NotificationCenter
    private let isForeground: () -> Bool

    // Session state
    private var generation = 0
    private var account: NotificationActivityAccount?

    // Seen state
    private var acknowledgedSeen: String?
    private var pendingSeen: String?
    private var seenAttempts = 0
    private let maxSeenAttempts = 5

    // Refresh coalescing + revision
    private var isFetching = false
    private var needsFollowUpFetch = false
    private var revision = 0

    // Visibility
    private var isNotificationsVisible = false
    private var isSubmittingSeen = false

    private var observers: [NSObjectProtocol] = []

    init(
        resolver: NotificationActivityAccountResolving = DefaultNotificationActivityAccountResolver(),
        store: NotificationActivityStoring = NotificationActivityStore(),
        iconBadge: AppIconBadgeWriting = AppIconBadgeController(),
        notificationCenter: NotificationCenter = .default,
        isForeground: @escaping () -> Bool = { UIApplication.shared.applicationState != .background }
    ) {
        self.resolver = resolver
        self.store = store
        self.iconBadge = iconBadge
        self.notificationCenter = notificationCenter
        self.isForeground = isForeground
    }

    /// Starts the service: restores the current account's snapshot, subscribes to
    /// account, foreground, and sync triggers, and refreshes. Call once at launch.
    func start() {
        observe(.wpAccountDefaultWordPressComAccountChanged) { [weak self] _ in
            self?.configureForCurrentAccount(restore: false)
        }
        observe(UIApplication.didBecomeActiveNotification) { [weak self] _ in
            self?.refresh()
        }
        observe(Foundation.Notification.Name(rawValue: NotificationSyncMediatorDidUpdateNotifications)) { [weak self] _ in
            self?.notedPossibleActivity()
        }
        configureForCurrentAccount(restore: true)
    }

    // MARK: - Account lifecycle

    /// Rebuilds session state for the current default account. Invalidates the
    /// old session generation so in-flight work from the previous account is
    /// discarded, clears published and saved state, then starts fresh.
    ///
    /// - Parameter restore: When `true` (a process restart), restores a saved
    ///   snapshot if it belongs to the current account. When `false` (a sign-in
    ///   or account change), always starts empty.
    private func configureForCurrentAccount(restore: Bool) {
        generation &+= 1
        isFetching = false
        needsFollowUpFetch = false
        isSubmittingSeen = false
        isNotificationsVisible = false
        pendingSeen = nil
        acknowledgedSeen = nil
        setActivity(false)

        // An explicit sign-out or account change (restore == false) clears the
        // icon; a process restart (restore == true) never does, so a badge iOS is
        // showing from earlier pushes survives a relaunch.
        if !restore {
            iconBadge.setBadgeCount(0)
        }

        guard let account = resolver.currentAccount() else {
            self.account = nil
            // A restore that cannot resolve an account yet (launch before the
            // account loads, or a transient token invalidation) keeps saved state
            // for a later foreground to recover; a sign-out or account change wipes it.
            if !restore {
                store.clear()
            }
            return
        }
        self.account = account

        if restore, let snapshot = store.load(), snapshot.accountUUID == account.uuid {
            acknowledgedSeen = snapshot.acknowledgedSeen
            pendingSeen = snapshot.pendingSeen
            setActivity(snapshot.hasActivity)
        } else {
            // A mismatch, missing snapshot, or fresh sign-in starts with a plain
            // bell; persist overwrites any stale snapshot for this account.
            persist()
        }

        refresh()
    }

    /// Recovers from an unresolved account. A same-account re-auth (after a token
    /// invalidation) posts nothing this service observes and may not background
    /// the app, so account-gated entry points call this to rebuild the session
    /// once an account is available again, rather than relying on a foreground
    /// transition.
    private func resolveAccountIfNeeded() {
        guard account == nil, resolver.currentAccount() != nil else {
            return
        }
        configureForCurrentAccount(restore: true)
    }

    // MARK: - Refresh

    /// Refreshes the bell from the backend. Coalesces concurrent requests, runs
    /// only with a foreground authenticated account, and first drains any pending
    /// seen retry.
    func refresh() {
        resolveAccountIfNeeded()
        guard isForeground(), let account else {
            return
        }
        submitPendingSeenIfNeeded()

        guard !isFetching else {
            needsFollowUpFetch = true
            return
        }
        isFetching = true
        let gen = generation
        let startRevision = revision
        let remote = account.remote
        Task { @MainActor [weak self] in
            do {
                let hasUnseen = try await remote.fetchHasUnseenNotes()
                self?.finishFetch(gen: gen, startRevision: startRevision, result: .success(hasUnseen))
            } catch {
                self?.finishFetch(gen: gen, startRevision: startRevision, result: .failure(error))
            }
        }
    }

    private func finishFetch(gen: Int, startRevision: Int, result: Result<Bool, Error>) {
        guard gen == generation else {
            // Result from a previous account; discard. Leave `isFetching` alone:
            // it belongs to the current generation's in-flight fetch, if any.
            return
        }
        isFetching = false
        let coalescedRefresh = needsFollowUpFetch
        needsFollowUpFetch = false
        var staleNeedsRefetch = false

        switch result {
        case .success(let hasUnseen):
            if revision != startRevision {
                // A newer local clear or activity happened during the fetch; its
                // result is stale. Re-fetch once pending seen work settles.
                staleNeedsRefetch = true
            } else if isNotificationsVisible || (hasUnseen && pendingSeen != nil) {
                // Keep the indicator clear while the list is visible, and don't
                // overwrite a local clear with a stale server `true` while its
                // seen write is pending.
                break
            } else {
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

    /// A push, PingHub, or successful sync signals that state may have changed.
    /// It is a reason to refresh, not proof the bell is `true`.
    func notedPossibleActivity() {
        resolveAccountIfNeeded()
        guard account != nil else { return }
        revision &+= 1
        refresh()
    }

    // MARK: - Opening Notifications and seen updates

    /// Notifications became visible: publish the clear, persist it, request an
    /// icon clear, and submit the newest observed timestamp as seen.
    func notificationsBecameVisible(newestTimestamp: String?) {
        resolveAccountIfNeeded()
        guard account != nil else { return }
        isNotificationsVisible = true
        revision &+= 1
        setActivity(false)
        iconBadge.setBadgeCount(0)
        if let newestTimestamp {
            enqueueSeen(newestTimestamp)
        }
        persist()
    }

    /// The visible list received newer content: submit the newer timestamp.
    func notificationsListDidUpdate(newestTimestamp: String?) {
        guard isNotificationsVisible, let newestTimestamp else { return }
        enqueueSeen(newestTimestamp)
    }

    /// Leaving Notifications removes the visibility suppression and requests a
    /// refresh after any pending seen write. A pre-open response cannot relight
    /// the bell because the revision advanced when the list opened.
    func notificationsResignedVisible() {
        isNotificationsVisible = false
        refresh()
    }

    private func enqueueSeen(_ timestamp: String) {
        // Skip an already acknowledged timestamp and keep only the newest pending.
        if timestamp == acknowledgedSeen {
            return
        }
        if let pendingSeen, pendingSeen >= timestamp {
            return
        }
        pendingSeen = timestamp
        seenAttempts = 0 // A newer timestamp gets a fresh attempt budget.
        persist()
        submitPendingSeenIfNeeded()
    }

    private func submitPendingSeenIfNeeded() {
        guard isForeground(), !isSubmittingSeen, let account, let timestamp = pendingSeen else {
            return
        }
        isSubmittingSeen = true
        let gen = generation
        let remote = account.remote
        Task { @MainActor [weak self] in
            do {
                try await remote.markSeen(timestamp: timestamp)
                self?.finishSeen(gen: gen, submitted: timestamp, success: true)
            } catch {
                self?.finishSeen(gen: gen, submitted: timestamp, success: false)
            }
        }
    }

    private func finishSeen(gen: Int, submitted: String, success: Bool) {
        guard gen == generation else {
            // Old account; discard. Leave `isSubmittingSeen` for the current
            // generation's in-flight write, if any.
            return
        }
        isSubmittingSeen = false
        guard success else {
            seenAttempts += 1
            if seenAttempts >= maxSeenAttempts {
                // A persistently rejected timestamp would otherwise suppress every
                // server `true` forever (and survive relaunch via the snapshot).
                // Give up this seen write and trust the server flag from here.
                Loggers.app.error("Giving up notifications/seen after \(seenAttempts) failed attempts")
                pendingSeen = nil
                seenAttempts = 0
                persist()
                refresh()
            }
            // Otherwise retain the local clear and pending timestamp; retry on the
            // next foreground, reconnect, or activity trigger.
            return
        }
        seenAttempts = 0
        acknowledgedSeen = submitted
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

    private func persist() {
        guard let account else { return }
        store.save(NotificationActivitySnapshot(
            accountUUID: account.uuid,
            hasActivity: hasNewActivity,
            acknowledgedSeen: acknowledgedSeen,
            pendingSeen: pendingSeen
        ))
    }

    private func observe(_ name: Foundation.Notification.Name, using block: @escaping (Foundation.Notification) -> Void) {
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
    nonisolated static func pushDidUpdateBadge(count: Int) {
        Task { @MainActor in
            shared.applyPushBadgeCount(count)
            shared.notedPossibleActivity()
        }
    }

    /// Clears the home-screen icon badge. Safe to call from non-main-actor code.
    nonisolated static func clearAppIconBadge() {
        Task { @MainActor in shared.requestIconClear() }
    }
}

// MARK: - Default account resolver

struct DefaultNotificationActivityAccountResolver: NotificationActivityAccountResolving {
    func currentAccount() -> NotificationActivityAccount? {
        // Runs on the main actor, matching `mainContext`'s queue.
        let context = ContextManager.shared.mainContext
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context),
              let uuid = account.uuid,
              let authToken = account.authToken, !authToken.isEmpty else {
            // Read `authToken` directly. The `wordPressComRestApi` getter has side
            // effects when the token is missing: it posts the notification that
            // presents a sign-in screen. Guarding on the token first avoids
            // presenting sign-in as a side effect of a badge refresh (same rule as
            // DashboardCard).
            return nil
        }
        guard let api = account.wordPressComRestApi else {
            return nil
        }
        return NotificationActivityAccount(
            uuid: uuid,
            remote: NotificationActivityServiceRemote(wordPressComRestApi: api)
        )
    }
}
