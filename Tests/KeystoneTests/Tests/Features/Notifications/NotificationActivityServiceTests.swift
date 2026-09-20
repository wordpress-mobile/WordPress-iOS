import Testing
import Foundation
import UIKit
@testable import WordPress

// Serialized: these tests drive the service's internal async tasks to quiescence
// via `settle`, which is unreliable under Swift Testing's default parallel
// execution because interleaved @MainActor tests starve each other's tasks.
@Suite(.serialized)
@MainActor
struct NotificationActivityServiceTests {

    // MARK: - Test doubles

    struct TestError: Error {}

    final class FakeRemote: NotificationActivityRemote {
        /// When set, `fetchHasUnseenNotes` returns this immediately. When nil, it
        /// suspends until `completeFetch` is called, so tests control timing.
        var autoFetchResult: Result<Bool, Error>?
        private var pending: [CheckedContinuation<Bool, Error>] = []
        private(set) var fetchCount = 0
        private(set) var seenTimestamps: [String] = []
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

        func markSeen(timestamp: String) async throws {
            seenTimestamps.append(timestamp)
            if let seenError {
                throw seenError
            }
        }
    }

    final class FakeStore: NotificationActivityStoring {
        var snapshot: NotificationActivitySnapshot?
        private(set) var clearCount = 0

        func load() -> NotificationActivitySnapshot? { snapshot }
        func save(_ snapshot: NotificationActivitySnapshot) { self.snapshot = snapshot }
        func clear() { snapshot = nil; clearCount += 1 }
    }

    final class FakeIconWriter: AppIconBadgeWriting {
        private(set) var counts: [Int] = []
        var last: Int? { counts.last }
        func setBadgeCount(_ count: Int) { counts.append(count) }
    }

    final class FakeResolver: NotificationActivityAccountResolving {
        var account: NotificationActivityAccount?
        func currentAccount() -> NotificationActivityAccount? { account }
    }

    // MARK: - Fixture

    final class ForegroundBox {
        var value = true
    }

    @MainActor
    final class Fixture {
        let remote = FakeRemote()
        let store = FakeStore()
        let icon = FakeIconWriter()
        let resolver = FakeResolver()
        private let foregroundBox = ForegroundBox()
        var foreground: Bool {
            get { foregroundBox.value }
            set { foregroundBox.value = newValue }
        }
        let notificationCenter = NotificationCenter()
        let service: NotificationActivityService

        init(uuid: String = "account-A") {
            resolver.account = NotificationActivityAccount(uuid: uuid, remote: remote)
            let box = foregroundBox
            service = NotificationActivityService(
                resolver: resolver,
                store: store,
                iconBadge: icon,
                notificationCenter: notificationCenter,
                isForeground: { box.value }
            )
        }

        func setAccount(uuid: String?) {
            resolver.account = uuid.map { NotificationActivityAccount(uuid: $0, remote: remote) }
        }
    }

    /// Drains queued main-actor work until every piece of observable state the
    /// tests assert on stops changing, so tests do not depend on a fixed number
    /// of task hops. The signature covers the remote call counts, the icon
    /// writes, the published bell, and the persisted snapshot, so a still-pending
    /// `finishFetch`/`finishSeen` keeps the loop running until its effects land.
    /// A fetch suspended on a manual continuation counts as quiescent (its
    /// `fetchCount` already incremented), which is what the timing tests want.
    func settle(_ f: Fixture) async {
        var last = ""
        var stableRounds = 0
        for _ in 0..<800 {
            await Task.yield()
            let snapshot = f.store.snapshot
            let signature = [
                "\(f.remote.fetchCount)",
                "\(f.remote.seenTimestamps.count)",
                "\(f.icon.counts.count)",
                "\(f.service.hasNewActivity)",
                snapshot?.pendingSeen ?? "-",
                snapshot?.acknowledgedSeen ?? "-",
                "\(snapshot?.hasActivity ?? false)"
            ].joined(separator: "|")
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

    /// Builds a fixture, applies the initial fetch result and optional snapshot,
    /// starts the service, and drains to quiescence. Cases that need manual fetch
    /// timing pass `fetch: nil`.
    func started(
        uuid: String = "account-A",
        snapshot: NotificationActivitySnapshot? = nil,
        fetch: Result<Bool, Error>? = .success(false)
    ) async -> Fixture {
        let f = Fixture(uuid: uuid)
        f.store.snapshot = snapshot
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
        f.store.snapshot = .init(accountUUID: "account-A", hasActivity: true, acknowledgedSeen: "t1", pendingSeen: nil)
        f.remote.autoFetchResult = .success(true)
        f.service.start()
        #expect(f.service.hasNewActivity) // restored before any fetch
    }

    @Test func rejectsSnapshotFromDifferentAccount() async {
        let f = Fixture(uuid: "account-A")
        f.store.snapshot = .init(accountUUID: "account-B", hasActivity: true, acknowledgedSeen: nil, pendingSeen: nil)
        f.remote.autoFetchResult = .success(false)
        f.service.start()
        #expect(!f.service.hasNewActivity)
        #expect(f.store.snapshot?.accountUUID == "account-A") // stale snapshot cleared/replaced
    }

    // MARK: - Refresh

    @Test func successfulFetchUpdatesAndPersists() async {
        let f = await started(fetch: .success(true))
        #expect(f.service.hasNewActivity)
        #expect(f.store.snapshot?.hasActivity == true)
    }

    @Test func failedFetchPreservesLastKnownState() async {
        let f = await started(
            snapshot: .init(accountUUID: "account-A", hasActivity: true, acknowledgedSeen: nil, pendingSeen: nil),
            fetch: .failure(TestError())
        )
        #expect(f.service.hasNewActivity) // not reset to false by the failure
    }

    // MARK: - Opening Notifications

    @Test func becomingVisibleClearsBellIconAndSubmitsSeen() async {
        let f = await started(fetch: .success(true))
        #expect(f.service.hasNewActivity)

        f.service.notificationsBecameVisible(newestTimestamp: "2026-09-18T10:00:00+00:00")
        await settle(f)

        #expect(!f.service.hasNewActivity)
        #expect(f.icon.last == 0)
        #expect(f.store.snapshot?.hasActivity == false)
        #expect(f.remote.seenTimestamps.contains("2026-09-18T10:00:00+00:00"))
    }

    @Test func inFlightFetchAfterLocalClearDoesNotRelight() async {
        let f = await started(fetch: nil) // fetch suspends for manual control

        // Local clear happens while the fetch is in flight.
        f.service.notificationsBecameVisible(newestTimestamp: nil)
        #expect(!f.service.hasNewActivity)

        // The stale fetch now resolves true; it must be discarded.
        f.remote.completeFetch(.success(true))
        await settle(f)
        #expect(!f.service.hasNewActivity)
    }

    @Test func serverTrueSuppressedWhilePendingSeen() async {
        let f = Fixture()
        f.remote.autoFetchResult = nil
        f.remote.seenError = TestError() // seen write never succeeds
        f.service.start()
        await settle(f)
        f.remote.completeFetch(.success(false))
        await settle(f)

        // Open the list: local clear + pending seen (which will fail).
        f.service.notificationsBecameVisible(newestTimestamp: "2026-09-18T10:00:00+00:00")
        await settle(f)
        #expect(!f.service.hasNewActivity)

        // A later refresh returning true must not relight while seen is pending.
        f.service.notedPossibleActivity()
        f.remote.completeFetch(.success(true))
        await settle(f)
        #expect(!f.service.hasNewActivity)
    }

    // MARK: - Account isolation

    @Test func accountChangeStartsEmptyAndDiscardsLateOldFetch() async {
        let f = await started(fetch: nil) // A's fetch suspends

        // Switch to account B and notify.
        f.setAccount(uuid: "account-B")
        f.notificationCenter.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
        await settle(f)
        #expect(!f.service.hasNewActivity)
        #expect(f.store.snapshot?.accountUUID == "account-B")

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

        f.setAccount(uuid: "account-B")
        f.notificationCenter.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
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

    @Test func processRestartDoesNotClearIcon() async {
        // A launch (restore: true) must not wipe a badge iOS is showing from
        // earlier pushes.
        let f = await started(
            snapshot: .init(accountUUID: "account-A", hasActivity: true, acknowledgedSeen: nil, pendingSeen: nil),
            fetch: .success(true)
        )
        #expect(f.icon.counts.isEmpty)
    }

    @Test func accountChangeClearsIcon() async {
        let f = await started()
        #expect(f.icon.counts.isEmpty) // launch did not clear

        f.setAccount(uuid: "account-B")
        f.notificationCenter.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
        await settle(f)
        #expect(f.icon.last == 0) // account change clears the icon
    }

    @Test func recoversWhenAccountResolvesOnForeground() async {
        // A launch that cannot resolve an account (e.g. token invalidated) must
        // not latch off: a later foreground re-resolves and refreshes.
        let f = Fixture(uuid: "account-A")
        f.store.snapshot = .init(accountUUID: "account-A", hasActivity: false, acknowledgedSeen: nil, pendingSeen: nil)
        f.setAccount(uuid: nil)
        f.remote.autoFetchResult = .success(true)
        f.service.start()
        await settle(f)
        #expect(!f.service.hasNewActivity)
        #expect(f.store.snapshot != nil) // saved state not wiped on a non-sign-out nil
        #expect(f.icon.counts.isEmpty)    // icon not cleared either

        // Account becomes resolvable again; a foreground recovers the session.
        f.setAccount(uuid: "account-A")
        f.notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await settle(f)
        #expect(f.service.hasNewActivity)
    }

    @Test func recoversWhenAccountResolvesWithoutForeground() async {
        // A same-account re-auth may not background the app, so opening
        // Notifications must itself recover the session, not wait for a foreground.
        let f = Fixture(uuid: "account-A")
        f.remote.autoFetchResult = .success(false)
        f.setAccount(uuid: nil)
        f.service.start()
        await settle(f)

        f.setAccount(uuid: "account-A")
        f.service.notificationsBecameVisible(newestTimestamp: "2026-09-18T10:00:00+00:00")
        await settle(f)
        #expect(f.remote.seenTimestamps.contains("2026-09-18T10:00:00+00:00"))
        #expect(f.icon.last == 0)
    }

    @Test func persistentlyFailingSeenStopsSuppressingBell() async {
        let f = await started()

        f.remote.seenError = TestError()
        f.service.notificationsBecameVisible(newestTimestamp: "2026-09-18T10:00:00+00:00")
        await settle(f)
        #expect(f.store.snapshot?.pendingSeen == "2026-09-18T10:00:00+00:00")

        // Retry until the attempt cap is reached; the pending seen is then dropped.
        for _ in 0..<5 {
            f.service.refresh()
            await settle(f)
        }
        #expect(f.store.snapshot?.pendingSeen == nil)

        // A server `true` now lights the bell instead of being suppressed forever.
        f.remote.seenError = nil
        f.remote.autoFetchResult = .success(true)
        f.service.notificationsResignedVisible()
        await settle(f)
        #expect(f.service.hasNewActivity)
    }

    @Test func foregroundPushRefreshesBell() async {
        // Mirrors pushDidUpdateBadge on a foreground push: apply the icon count
        // and treat the push as a refresh trigger so the bell does not stay stale.
        let f = await started()
        #expect(!f.service.hasNewActivity)
        let fetchesBefore = f.remote.fetchCount

        f.remote.autoFetchResult = .success(true)
        f.service.applyPushBadgeCount(2)
        f.service.notedPossibleActivity()
        await settle(f)
        #expect(f.remote.fetchCount > fetchesBefore)
        #expect(f.service.hasNewActivity)
        #expect(f.icon.last == 2)
    }

    @Test func signOutClearsStateAndIcon() async {
        let f = await started(
            snapshot: .init(accountUUID: "account-A", hasActivity: true, acknowledgedSeen: nil, pendingSeen: nil),
            fetch: .success(true)
        )

        f.setAccount(uuid: nil)
        f.notificationCenter.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
        await settle(f)

        #expect(!f.service.hasNewActivity)
        #expect(f.store.snapshot == nil)
        #expect(f.icon.last == 0)
    }

    // MARK: - Seen retries

    @Test func failedSeenIsRetainedAndRetried() async {
        let f = await started()

        f.remote.seenError = TestError()
        f.service.notificationsBecameVisible(newestTimestamp: "2026-09-18T10:00:00+00:00")
        await settle(f)
        #expect(f.store.snapshot?.pendingSeen == "2026-09-18T10:00:00+00:00")

        // Recover and retry via a foreground refresh.
        f.remote.seenError = nil
        f.service.refresh()
        await settle(f)
        #expect(f.remote.seenTimestamps.filter { $0 == "2026-09-18T10:00:00+00:00" }.count >= 1)
        #expect(f.store.snapshot?.pendingSeen == nil)
        #expect(f.store.snapshot?.acknowledgedSeen == "2026-09-18T10:00:00+00:00")
    }

    @Test func alreadyAcknowledgedTimestampNotResubmitted() async {
        let f = await started(
            snapshot: .init(accountUUID: "account-A", hasActivity: false, acknowledgedSeen: "2026-09-18T10:00:00+00:00", pendingSeen: nil)
        )

        f.service.notificationsBecameVisible(newestTimestamp: "2026-09-18T10:00:00+00:00")
        await settle(f)
        #expect(f.remote.seenTimestamps.isEmpty)
    }

    // MARK: - Home-screen icon

    @Test func pushBadgeAppliedWhenNotVisibleZeroWhenVisible() async {
        let f = await started()

        f.service.applyPushBadgeCount(5)
        #expect(f.icon.last == 5)

        f.service.notificationsBecameVisible(newestTimestamp: nil)
        f.service.applyPushBadgeCount(9) // ignored while visible
        #expect(f.icon.last == 0)
    }

    @Test func supportPushDoesNotChangeBell() async {
        let f = await started()
        #expect(!f.service.hasNewActivity)

        // A support/Zendesk badge write goes only through the icon writer.
        f.service.applyPushBadgeCount(3)
        #expect(!f.service.hasNewActivity)
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
        f.service.notificationsBecameVisible(newestTimestamp: "2026-09-18T10:00:00+00:00")
        await settle(f)
        #expect(f.remote.seenTimestamps.isEmpty)
        #expect(f.store.snapshot?.pendingSeen == "2026-09-18T10:00:00+00:00")

        // Returning to the foreground drains the pending seen and refreshes.
        f.foreground = true
        f.service.refresh()
        await settle(f)
        #expect(f.remote.seenTimestamps.contains("2026-09-18T10:00:00+00:00"))
        #expect(f.remote.fetchCount >= 1)
    }

    @Test func pushBadgeAppliedWhileBackgroundedEvenWhenNotificationsWasVisible() async {
        let f = await started()

        f.service.notificationsBecameVisible(newestTimestamp: nil) // isNotificationsVisible = true
        f.foreground = false // app backgrounded with Notifications on top
        f.service.applyPushBadgeCount(7)
        #expect(f.icon.last == 7) // not suppressed to 0 while backgrounded
    }
}
