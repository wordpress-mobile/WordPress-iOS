import Testing
import Foundation
import WordPressKit
@testable import JetpackStats

private actor MockPostLikesStore: PostLikesStore {
    private(set) var storedCalls: [(postID: Int, totalCount: Int, likes: [PostLikeSeed])] = []

    func storeLikes(_ likes: [PostLikeSeed], totalCount: Int, forPost postID: Int) async {
        storedCalls.append((postID, totalCount, likes))
    }
}

private actor DoneFlag {
    private(set) var isDone = false
    func markDone() { isDone = true }
}

/// A store whose `storeLikes` blocks on an explicit gate, so tests can observe
/// whether the caller awaited it.
private actor GatedMockPostLikesStore: PostLikesStore {
    private(set) var completed = false
    private var startedFlag = false
    private var gate: CheckedContinuation<Void, Never>?
    private var startedWaiter: CheckedContinuation<Void, Never>?

    func storeLikes(_ likes: [PostLikeSeed], totalCount: Int, forPost postID: Int) async {
        startedFlag = true
        startedWaiter?.resume()
        startedWaiter = nil
        await withCheckedContinuation { gate = $0 }
        completed = true
    }

    func waitUntilStarted() async {
        if startedFlag { return }
        await withCheckedContinuation { startedWaiter = $0 }
    }

    func open() {
        gate?.resume()
        gate = nil
    }
}

@Suite
struct StatsServicePostLikesStoreTests {
    private let seeds = [
        PostLikeSeed(
            userID: 1,
            displayName: "Test Name",
            username: "testlogin",
            avatarURL: nil,
            dateLikedString: "2026-01-24T04:02:42+0000"
        )
    ]

    private func makeService(store: (any PostLikesStore)?) -> StatsService {
        StatsService(
            siteID: 20,
            api: WordPressComRestApi(oAuthToken: "fake-token", userAgent: "test"),
            timeZone: .current,
            postLikesStore: store
        )
    }

    @Test func forwardsSeedsAndTotalCountToInjectedStore() async {
        let store = MockPostLikesStore()
        let service = makeService(store: store)

        let task = await service.storeSeedsIfNeeded(seeds, totalCount: 42, postID: 55)
        await task?.value

        let calls = await store.storedCalls
        #expect(calls.count == 1)
        #expect(calls.first?.postID == 55)
        #expect(calls.first?.totalCount == 42)
        #expect(calls.first?.likes == seeds)
    }

    @Test func forwardsConfirmedZeroTotalToInjectedStore() async {
        let store = MockPostLikesStore()
        let service = makeService(store: store)

        let task = await service.storeSeedsIfNeeded([], totalCount: 0, postID: 55)
        await task?.value

        let calls = await store.storedCalls
        #expect(calls.count == 1)
        #expect(calls.first?.totalCount == 0)
        #expect(calls.first?.likes.isEmpty == true)
    }

    @Test func skipsSilentlyWithoutStore() async {
        let service = makeService(store: nil)

        let task = await service.storeSeedsIfNeeded(seeds, totalCount: 1, postID: 55)

        #expect(task == nil)
    }

    @Test func awaitsPurgeForConfirmedZero() async {
        let store = GatedMockPostLikesStore()
        let service = makeService(store: store)
        let flag = DoneFlag()

        async let call: Void = {
            await service.storeSeeds([], totalCount: 0, postID: 55)
            await flag.markDone()
        }()

        // storeLikes has entered but is blocked on the gate.
        await store.waitUntilStarted()
        // Because `storeSeeds` awaits a confirmed-zero purge, the call has not
        // returned while the store is still blocked.
        #expect(await flag.isDone == false)

        await store.open()
        await call

        #expect(await flag.isDone == true)
        #expect(await store.completed == true)
    }

    @Test func doesNotAwaitSeedingForPositiveTotal() async {
        let store = GatedMockPostLikesStore()
        let service = makeService(store: store)

        // A positive total seeds fire-and-forget: this returns without waiting
        // for the gated store. If it awaited, the test would deadlock.
        await service.storeSeeds(seeds, totalCount: 5, postID: 55)

        // Release the background seeding task so it does not leak.
        await store.waitUntilStarted()
        await store.open()
    }
}
