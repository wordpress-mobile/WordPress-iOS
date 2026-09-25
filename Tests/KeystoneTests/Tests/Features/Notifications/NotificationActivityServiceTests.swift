import Testing
import Foundation
import UIKit
import WordPressKit
@testable import WordPress

// Serialized: these tests drive the service's internal async tasks to quiescence
// via `settle`, which is unreliable under Swift Testing's default parallel
// execution because interleaved @MainActor tests starve each other's tasks.
@Suite(.serialized)
@MainActor
struct NotificationActivityServiceTests {

    // MARK: - Test doubles

    /// `2026-09-17T09:00:00+00:00`, `2026-09-18T10:00:00+00:00`, and
    /// `2026-09-18T11:00:00+00:00`.
    static let nineOClockYesterday = Date(timeIntervalSince1970: 1_789_635_600)
    static let tenOClock = Date(timeIntervalSince1970: 1_789_725_600)
    static let elevenOClock = Date(timeIntervalSince1970: 1_789_729_200)

    /// Main-actor isolated so an auto-completing call finishes in the same
    /// main-actor slice as the service's `finishFetch`/`finishSeen`. A
    /// nonisolated async method hops off the main actor first, and `settle` can
    /// see a stable signature while that write is still in flight.
    @MainActor
    final class FakeRemote: NotificationActivityRemote {
        /// When set, `fetchHasUnseenNotes` returns this immediately. When nil, it
        /// suspends until `completeFetch` is called, so tests control timing.
        var autoFetchResult: Result<Bool, Error>?
        private var pending: [CheckedContinuation<Bool, Error>] = []
        private(set) var fetchCount = 0
        private(set) var seenTimestamps: [Date] = []
        var seenError: Error?

        func fetchHasUnseenNotes() async throws -> Bool {
            fetchCount += 1
            if let autoFetchResult {
                return try autoFetchResult.get()
            }
            return try await withCheckedThrowingContinuation { pending.append($0) }
        }

        func completeFetch(_ result: Result<Bool, Error>) {
            guard !pending.isEmpty else { return }
            pending.removeFirst().resume(with: result)
        }

        /// When false, `markSeen` suspends until `completeSeen` is called.
        var autoSeen = true
        private var pendingSeenWrites: [CheckedContinuation<Void, Error>] = []

        func markSeen(timestamp: Date) async throws {
            seenTimestamps.append(timestamp)
            if !autoSeen {
                try await withCheckedThrowingContinuation { pendingSeenWrites.append($0) }
                return
            }
            if let seenError {
                throw seenError
            }
        }

        func completeSeen(_ result: Result<Void, Error>) {
            guard !pendingSeenWrites.isEmpty else { return }
            pendingSeenWrites.removeFirst().resume(with: result)
        }
    }

    final class FakeResolver: NotificationActivityAccountResolving {
        /// The default account's UUID; `nil` means signed out.
        var defaultUUID: String?
        /// `false` models a token invalidation: the account stays the default.
        var hasCredentials = true
        /// Per-account remotes. Accounts without one share `fallbackRemote`.
        var remotes: [String: FakeRemote] = [:]
        let fallbackRemote: FakeRemote

        init(fallbackRemote: FakeRemote) {
            self.fallbackRemote = fallbackRemote
        }

        func defaultAccount() -> NotificationActivityAccount? {
            guard let defaultUUID else { return nil }
            return NotificationActivityAccount(
                uuid: defaultUUID,
                remote: hasCredentials ? remotes[defaultUUID] ?? fallbackRemote : nil
            )
        }
    }

    // MARK: - Fixture

    final class ForegroundBox {
        var value = true
    }

    @MainActor
    final class Fixture {
        let remote = FakeRemote()
        /// Backs `store`. Share it between fixtures to model a process restart.
        let defaults: InMemoryUserDefaults
        let store: NotificationActivityStore
        let resolver: FakeResolver
        private let foregroundBox = ForegroundBox()
        var foreground: Bool {
            get { foregroundBox.value }
            set { foregroundBox.value = newValue }
        }
        let notificationCenter = NotificationCenter()
        let service: NotificationActivityService
        /// Stands in for a Notifications list.
        let list = NSObject()

        init(uuid: String = "account-A", defaults: InMemoryUserDefaults = InMemoryUserDefaults()) {
            self.defaults = defaults
            store = NotificationActivityStore(repository: defaults)
            resolver = FakeResolver(fallbackRemote: remote)
            resolver.defaultUUID = uuid
            let box = foregroundBox
            service = NotificationActivityService(
                resolver: resolver,
                store: store,
                notificationCenter: notificationCenter,
                isForeground: { box.value }
            )
        }

        /// Makes `uuid` the default account (`nil` signs out) and posts the
        /// default-account notification, as `AccountService` does.
        func switchAccount(to uuid: String?) {
            resolver.defaultUUID = uuid
            notificationCenter.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
        }

        /// Invalidates the token as `WPAccount.handleInvalidToken` does: the
        /// account stays the default, and the notification is posted.
        func invalidateToken() {
            resolver.hasCredentials = false
            notificationCenter.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
        }

        var allRemotes: [FakeRemote] { [remote] + resolver.remotes.values }
    }

    /// Drains queued main-actor work until every piece of observable state the
    /// tests assert on stops changing, so tests do not depend on a fixed number
    /// of task hops. The signature covers the remote call counts, the published
    /// bell, and the persisted snapshot, so a still-pending
    /// `finishFetch`/`finishSeen` keeps the loop running until its effects land.
    /// A fetch suspended on a manual continuation counts as quiescent (its
    /// `fetchCount` already incremented), which is what the timing tests want.
    func settle(_ f: Fixture) async {
        var last = ""
        var stableRounds = 0
        for _ in 0..<800 {
            await Task.yield()
            let snapshot = f.store.load()
            let signature = [
                "\(f.allRemotes.map(\.fetchCount).reduce(0, +))",
                "\(f.allRemotes.map(\.seenTimestamps.count).reduce(0, +))",
                "\(f.service.hasNewActivity)",
                "\(snapshot?.pendingSeen?.timeIntervalSince1970 ?? 0)",
                "\(snapshot?.acknowledgedSeen?.timeIntervalSince1970 ?? 0)",
                "\(snapshot?.hasActivity ?? false)"
            ]
            .joined(separator: "|")
            if signature == last {
                stableRounds += 1
                if stableRounds >= 5 {
                    return
                }
            } else {
                stableRounds = 0
                last = signature
            }
        }
    }

    /// Opens a Notifications list bound to `accountUUID` showing `newestTimestamp`.
    func openList(
        _ f: Fixture,
        accountUUID: String = "account-A",
        newestTimestamp: Date? = tenOClock
    ) {
        f.service.notificationsBecameVisible(f.list, accountUUID: accountUUID, newestTimestamp: newestTimestamp)
    }

    /// Builds a fixture, applies the initial fetch result and optional snapshot,
    /// starts the service, and drains to quiescence. Cases that need manual fetch
    /// timing pass `fetch: nil`.
    func started(
        uuid: String = "account-A",
        snapshot: NotificationActivitySnapshot? = nil,
        fetch: Result<Bool, Error>? = .success(false)
    ) async -> Fixture {
        let f = Fixture(uuid: uuid)
        if let snapshot {
            f.store.save(snapshot)
        }
        f.remote.autoFetchResult = fetch
        f.service.start()
        await settle(f)
        return f
    }

    // MARK: - Restoration and account identity

    @Test func plainBellWhenNoSnapshot() async {
        let f = await started()
        #expect(!f.service.hasNewActivity)
    }

    @Test func restoresSnapshotForMatchingAccount() async {
        let f = Fixture(uuid: "account-A")
        f.store.save(
            .init(accountUUID: "account-A", hasActivity: true, acknowledgedSeen: Self.tenOClock, pendingSeen: nil)
        )
        f.remote.autoFetchResult = .success(true)
        f.service.start()
        #expect(f.service.hasNewActivity) // restored before any fetch
    }

    @Test func rejectsSnapshotFromDifferentAccount() async {
        let f = Fixture(uuid: "account-A")
        f.store.save(.init(accountUUID: "account-B", hasActivity: true, acknowledgedSeen: nil, pendingSeen: nil))
        f.remote.autoFetchResult = .success(false)
        f.service.start()
        #expect(!f.service.hasNewActivity)
        #expect(f.store.load()?.accountUUID == "account-A") // stale snapshot cleared/replaced
    }

    // MARK: - Refresh

    @Test func successfulFetchUpdatesAndPersists() async {
        let f = await started(fetch: .success(true))
        #expect(f.service.hasNewActivity)
        #expect(f.store.load()?.hasActivity == true)
    }

    @Test func failedFetchPreservesLastKnownState() async {
        let f = await started(
            snapshot: .init(accountUUID: "account-A", hasActivity: true, acknowledgedSeen: nil, pendingSeen: nil),
            fetch: .failure(testError())
        )
        #expect(f.service.hasNewActivity) // not reset to false by the failure
    }

    // MARK: - Opening Notifications

    @Test func becomingVisibleClearsBellAndSubmitsSeen() async {
        let f = await started(fetch: .success(true))
        #expect(f.service.hasNewActivity)

        openList(f)
        await settle(f)

        #expect(!f.service.hasNewActivity)
        #expect(f.store.load()?.hasActivity == false)
        #expect(f.remote.seenTimestamps.contains(Self.tenOClock))
    }

    @Test func inFlightFetchAfterLocalClearDoesNotRelight() async {
        let f = await started(fetch: nil) // fetch suspends for manual control

        // Local clear happens while the fetch is in flight.
        openList(f, newestTimestamp: nil)
        #expect(!f.service.hasNewActivity)

        // The stale fetch now resolves true; it must be discarded.
        f.remote.completeFetch(.success(true))
        await settle(f)
        #expect(!f.service.hasNewActivity)
    }

    @Test func noFetchWhileSeenWriteIsPending() async {
        let f = await started()
        f.remote.seenError = testError() // seen write keeps failing
        openList(f)
        f.service.notificationsResignedVisible(f.list)
        await settle(f)
        #expect(!f.service.hasNewActivity)
        let fetchesBefore = f.remote.fetchCount

        // The server still reports the pre-visit `true` until the seen write
        // lands, so nothing fetches while it is pending.
        f.remote.autoFetchResult = .success(true)
        f.service.notedPossibleActivity()
        await settle(f)
        #expect(f.remote.fetchCount == fetchesBefore)
        #expect(!f.service.hasNewActivity)

        // Once the write lands, the fetch runs and its result counts.
        f.remote.seenError = nil
        f.service.refresh()
        await settle(f)
        #expect(f.remote.fetchCount > fetchesBefore)
        #expect(f.service.hasNewActivity)
    }

    // MARK: - Account isolation

    @Test func accountChangeStartsEmptyAndDiscardsLateOldFetch() async {
        let f = await started(fetch: nil) // A's fetch suspends

        // Switch to account B and notify.
        f.switchAccount(to: "account-B")
        await settle(f)
        #expect(!f.service.hasNewActivity)
        #expect(f.store.load()?.accountUUID == "account-B")

        // A's late fetch resolves true; it belongs to the old generation.
        f.remote.completeFetch(.success(true))
        await settle(f)
        #expect(!f.service.hasNewActivity)
    }

    @Test func lateOldAccountFetchDoesNotOpenLatchForNewAccount() async {
        // A stale-generation completion must not reset the in-flight latch, or the
        // next refresh starts a duplicate concurrent fetch.
        let f = await started(fetch: nil) // A's fetch suspends
        #expect(f.remote.fetchCount == 1)

        f.switchAccount(to: "account-B")
        await settle(f)
        #expect(f.remote.fetchCount == 2) // B's fetch started and suspended

        // A's late fetch (old generation) resolves; the latch must stay closed.
        f.remote.completeFetch(.success(true))
        await settle(f)
        f.service.refresh() // would start a duplicate B fetch if the latch reopened
        await settle(f)
        #expect(f.remote.fetchCount == 2)
        #expect(!f.service.hasNewActivity)
    }

    @Test func recoversWhenCredentialsReturnOnForeground() async {
        // A launch without credentials (token invalidated) must not latch off: a
        // later foreground picks up the credentials and refreshes.
        let f = Fixture(uuid: "account-A")
        f.store.save(.init(accountUUID: "account-A", hasActivity: false, acknowledgedSeen: nil, pendingSeen: nil))
        f.resolver.hasCredentials = false
        f.remote.autoFetchResult = .success(true)
        f.service.start()
        await settle(f)
        #expect(!f.service.hasNewActivity)
        #expect(f.store.load() != nil) // saved state kept without credentials

        f.resolver.hasCredentials = true
        f.notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await settle(f)
        #expect(f.service.hasNewActivity)
    }

    @Test func recoversWhenCredentialsReturnWithoutForeground() async {
        // A same-account re-auth may not background the app, so opening
        // Notifications must itself recover the session, not wait for a foreground.
        let f = Fixture(uuid: "account-A")
        f.remote.autoFetchResult = .success(false)
        f.resolver.hasCredentials = false
        f.service.start()
        await settle(f)

        f.resolver.hasCredentials = true
        openList(f)
        await settle(f)
        #expect(f.remote.seenTimestamps.contains(Self.tenOClock))
    }

    @Test func rejectedSeenIsDroppedAndStopsSuppressingBell() async {
        let f = await started()

        f.remote.seenError = NotificationActivityServiceRemote.SeenRejectedError()
        openList(f)
        await settle(f)
        #expect(f.remote.seenTimestamps == [Self.tenOClock])
        #expect(f.store.load()?.pendingSeen == nil)

        // A server `true` now lights the bell instead of being suppressed forever.
        f.remote.seenError = nil
        f.remote.autoFetchResult = .success(true)
        f.service.notificationsResignedVisible(f.list)
        await settle(f)
        #expect(f.service.hasNewActivity)
    }

    @Test func foregroundPushRefreshesBell() async {
        // Mirrors pushDidArrive on a foreground push: treat the push as a refresh
        // trigger so the bell does not stay stale.
        let f = await started()
        #expect(!f.service.hasNewActivity)
        let fetchesBefore = f.remote.fetchCount

        f.remote.autoFetchResult = .success(true)
        f.service.notedPossibleActivity()
        await settle(f)
        #expect(f.remote.fetchCount > fetchesBefore)
        #expect(f.service.hasNewActivity)
    }

    @Test func signOutClearsState() async {
        let f = await started(
            snapshot: .init(accountUUID: "account-A", hasActivity: true, acknowledgedSeen: nil, pendingSeen: nil),
            fetch: .success(true)
        )

        f.switchAccount(to: nil)
        await settle(f)

        #expect(!f.service.hasNewActivity)
        #expect(f.store.load() == nil)
    }

    // MARK: - Seen retries

    @Test func failedSeenIsRetainedAndRetried() async {
        let f = await started()

        f.remote.seenError = testError()
        openList(f)
        await settle(f)
        #expect(f.store.load()?.pendingSeen == Self.tenOClock)

        // Recover and retry via a foreground refresh.
        f.remote.seenError = nil
        f.service.refresh()
        await settle(f)
        #expect(f.remote.seenTimestamps.filter { $0 == Self.tenOClock }.count >= 1)
        #expect(f.store.load()?.pendingSeen == nil)
        #expect(f.store.load()?.acknowledgedSeen == Self.tenOClock)
    }

    @Test func seenNeverMovesBackward() async {
        let f = await started(
            snapshot: .init(
                accountUUID: "account-A",
                hasActivity: false,
                acknowledgedSeen: Self.tenOClock,
                pendingSeen: nil
            )
        )

        // Equal to, then older than, the acknowledged timestamp.
        openList(f)
        f.service.notificationsListDidUpdate(
            f.list,
            accountUUID: "account-A",
            newestTimestamp: Self.nineOClockYesterday
        )
        await settle(f)
        #expect(f.remote.seenTimestamps.isEmpty)
        #expect(f.store.load()?.acknowledgedSeen == Self.tenOClock)
    }

    @Test func transientSeenFailuresNeverDropPendingSeen() async {
        let f = await started()
        f.remote.seenError = testError() // offline, auth, or server error
        openList(f)
        await settle(f)

        for _ in 0..<8 {
            f.service.refresh()
            await settle(f)
        }
        #expect(f.store.load()?.pendingSeen == Self.tenOClock)
    }

    @Test func fetchWaitsForInFlightSeenWrite() async {
        // A GET that starts while a seen POST is in flight would carry the
        // server's pre-write state, so no GET starts until the POST settles.
        let f = await started()
        f.remote.autoSeen = false
        openList(f)
        await settle(f)
        let fetchesBeforeResign = f.remote.fetchCount

        f.remote.autoFetchResult = nil
        f.service.notificationsResignedVisible(f.list) // would start a GET
        await settle(f)
        #expect(f.remote.fetchCount == fetchesBeforeResign)

        // The write's own follow-up fetch runs, and its result is authoritative.
        f.remote.completeSeen(.success(()))
        await settle(f)
        #expect(f.remote.fetchCount == fetchesBeforeResign + 1)
        f.remote.completeFetch(.success(true))
        await settle(f)
        #expect(f.service.hasNewActivity)
    }

    // MARK: - Visibility and activity triggers

    @Test func notificationsStaysVisibleUntilTheLastListResigns() async {
        // On iPad a new list can appear before the old one disappears.
        let f = await started()
        let other = NSObject()
        f.remote.autoFetchResult = .success(true)

        openList(f, newestTimestamp: nil)
        f.service.notificationsBecameVisible(other, accountUUID: "account-A", newestTimestamp: nil)
        f.service.notificationsResignedVisible(f.list)
        await settle(f)
        #expect(!f.service.hasNewActivity)

        f.service.notificationsListDidUpdate(
            other,
            accountUUID: "account-A",
            newestTimestamp: Self.tenOClock
        )
        await settle(f)
        #expect(f.remote.seenTimestamps == [Self.tenOClock])

        f.service.notificationsResignedVisible(other)
        await settle(f)
        #expect(f.service.hasNewActivity)

        // A list that is no longer visible cannot submit seen.
        f.service.notificationsListDidUpdate(
            other,
            accountUUID: "account-A",
            newestTimestamp: Self.elevenOClock
        )
        await settle(f)
        #expect(f.remote.seenTimestamps == [Self.tenOClock])
    }

    @Test func accountFoundByATriggerFetchesOnce() async {
        // Starting the session already fetches; the trigger must not add another.
        let f = Fixture()
        f.resolver.defaultUUID = nil
        f.remote.autoFetchResult = .success(false)
        f.service.start()
        await settle(f)
        #expect(f.remote.fetchCount == 0)

        f.resolver.defaultUUID = "account-A"
        f.service.notedPossibleActivity()
        await settle(f)
        #expect(f.remote.fetchCount == 1)
    }

    // MARK: - Foreground gating

    @Test func backgroundDefersFetchAndRetainsPendingSeen() async {
        let f = Fixture()
        f.foreground = false
        f.remote.autoFetchResult = .success(true)
        f.service.start()
        await settle(f)
        #expect(f.remote.fetchCount == 0) // no refresh while backgrounded

        // A seen enqueued while backgrounded is retained, not stranded or sent.
        openList(f)
        await settle(f)
        #expect(f.remote.seenTimestamps.isEmpty)
        #expect(f.store.load()?.pendingSeen == Self.tenOClock)

        // Returning to the foreground drains the pending seen. The fetch waits
        // until the list leaves the screen.
        f.foreground = true
        f.service.refresh()
        await settle(f)
        #expect(f.remote.seenTimestamps.contains(Self.tenOClock))
        #expect(f.remote.fetchCount == 0)

        f.service.notificationsResignedVisible(f.list)
        await settle(f)
        #expect(f.remote.fetchCount >= 1)
    }

    // MARK: - Credentials, account binding, and PingHub

    @Test func tokenInvalidationKeepsPendingSeenUntilReauth() async {
        let f = await started()
        f.remote.seenError = testError()
        openList(f)
        await settle(f)

        f.invalidateToken()
        await settle(f)
        #expect(f.store.load()?.accountUUID == "account-A")
        #expect(f.store.load()?.pendingSeen == Self.tenOClock)

        // A same-account re-auth posts nothing; the next trigger resumes the write.
        f.resolver.hasCredentials = true
        f.remote.seenError = nil
        f.service.refresh()
        await settle(f)
        #expect(f.store.load()?.pendingSeen == nil)
        #expect(f.store.load()?.acknowledgedSeen == Self.tenOClock)
    }

    @Test func signOutThenSignInToSameAccountStartsFresh() async {
        let f = await started()
        f.remote.seenError = testError()
        openList(f)
        await settle(f)

        f.switchAccount(to: nil)
        await settle(f)
        #expect(f.store.load() == nil)

        f.remote.seenError = nil
        let writesBefore = f.remote.seenTimestamps.count
        f.switchAccount(to: "account-A")
        await settle(f)
        #expect(f.store.load()?.pendingSeen == nil)
        #expect(f.remote.seenTimestamps.count == writesBefore) // the old pending write is gone
    }

    @Test func callbacksBoundToAnotherAccountAreRejected() async {
        let f = await started()
        let remoteB = FakeRemote()
        remoteB.autoFetchResult = .success(false)
        f.resolver.remotes["account-B"] = remoteB
        f.switchAccount(to: "account-B")
        await settle(f)

        // B's list is visible, then a list still bound to A reports A's content.
        openList(f, accountUUID: "account-B", newestTimestamp: nil)
        openList(f)
        f.service.notificationsListDidUpdate(
            f.list,
            accountUUID: "account-A",
            newestTimestamp: Self.tenOClock
        )
        await settle(f)

        #expect(remoteB.seenTimestamps.isEmpty)
        #expect(f.remote.seenTimestamps.isEmpty)
        #expect(f.store.load()?.pendingSeen == nil)
    }

    @Test func accountChangeUnderVisibleListKeepsBellClearAndMarksNewContentSeen() async {
        let f = await started()
        openList(f, newestTimestamp: nil)
        await settle(f)

        let remoteB = FakeRemote()
        remoteB.autoFetchResult = .success(true) // B has unseen activity
        f.resolver.remotes["account-B"] = remoteB
        f.switchAccount(to: "account-B")
        await settle(f)
        #expect(!f.service.hasNewActivity) // the list is still on screen

        // The list rebinds to B and shows B's content.
        f.service.notificationsListDidUpdate(
            f.list,
            accountUUID: "account-B",
            newestTimestamp: Self.elevenOClock
        )
        await settle(f)
        #expect(remoteB.seenTimestamps == [Self.elevenOClock])
    }

    @Test func pingHubActivityRefreshesAndRetriesPendingSeen() async {
        // A PingHub single-note sync or a reconnect with unchanged notes posts no
        // full-sync update, so the service reacts to PingHub activity directly.
        let f = await started()
        f.remote.seenError = testError()
        openList(f)
        await settle(f)
        f.service.notificationsResignedVisible(f.list)
        await settle(f)
        let fetchesBefore = f.remote.fetchCount

        f.remote.seenError = nil
        f.notificationCenter.post(name: .pingHubActivity, object: nil)
        await settle(f)
        #expect(f.remote.fetchCount > fetchesBefore)
        #expect(f.store.load()?.pendingSeen == nil)
        #expect(f.store.load()?.acknowledgedSeen == Self.tenOClock)
    }
}
