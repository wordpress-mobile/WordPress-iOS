import Combine
import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("Site menu custom post types observation", .timeLimit(.minutes(1)))
struct SiteMenuCustomPostTypesObservationTests {
    private let contextManager = ContextManager.forTesting()
    private let notificationCenter = NotificationCenter()
    private let sources = FakeSources()

    private let book = PostTypeDetailsWithEditContext.fixture(slug: "book", name: "Books")
    private let movie = PostTypeDetailsWithEditContext.fixture(slug: "movie", name: "Movies")
    private let song = PostTypeDetailsWithEditContext.fixture(slug: "song", name: "Songs")

    // MARK: - Observation contract

    @Test("reads once on start without any update")
    func seedsOnStart() async throws {
        let viewModel = makeViewModel(blog: makeBlog())
        let source = try await sources.waitForSource(at: 0)

        try await source.waitForReads(1)
        source.completeRead(with: [book])

        try await waitUntil { slugs(viewModel) == ["book"] }
        try await Task.sleep(for: .milliseconds(100))
        #expect(source.readCount == 1)
    }

    @Test("reads again on each update")
    func readsOnUpdate() async throws {
        let viewModel = makeViewModel(blog: makeBlog())
        let source = try await sources.waitForSource(at: 0)
        try await source.waitForReads(1)
        source.completeRead(with: [book])
        try await waitUntil { slugs(viewModel) == ["book"] }

        source.updates.send()
        try await source.waitForReads(2)
        source.completeRead(with: [book, movie])

        try await waitUntil { slugs(viewModel) == ["book", "movie"] }
    }

    @Test("reads again when an update arrives during a read")
    func readsAgainAfterUpdateDuringRead() async throws {
        let viewModel = makeViewModel(blog: makeBlog())
        let source = try await sources.waitForSource(at: 0)
        try await source.waitForReads(1)

        source.updates.send()
        source.completeRead(with: [book])

        try await source.waitForReads(2)
        source.completeRead(with: [book, movie])
        try await waitUntil { slugs(viewModel) == ["book", "movie"] }
    }

    @Test("coalesces updates that arrive during one read into one more read")
    func coalescesUpdates() async throws {
        let viewModel = makeViewModel(blog: makeBlog())
        let source = try await sources.waitForSource(at: 0)
        try await source.waitForReads(1)

        source.updates.send()
        source.updates.send()
        source.updates.send()
        source.completeRead(with: [book])

        try await source.waitForReads(2)
        source.completeRead(with: [movie])
        try await waitUntil { slugs(viewModel) == ["movie"] }
        try await Task.sleep(for: .milliseconds(100))
        #expect(source.readCount == 2)
    }

    // MARK: - Site switch

    @Test("ignores the previous site's read after a site switch")
    func ignoresPreviousSiteAfterSwitch() async throws {
        let blogA = makeBlog()
        let blogB = makeBlog()
        let viewModel = makeViewModel(blog: blogA)
        let sourceA = try await sources.waitForSource(at: 0)
        try await sourceA.waitForReads(1)

        viewModel.blog = blogB
        #expect(viewModel.customPostTypes.isEmpty)

        let sourceB = try await sources.waitForSource(at: 1)
        #expect(sources.blogs[1] == blogB)
        try await sourceB.waitForReads(1)
        #expect(viewModel.customPostTypes.isEmpty)
        sourceB.completeRead(with: [movie])
        try await waitUntil { slugs(viewModel) == ["movie"] }

        sourceA.completeRead(with: [book])
        try await Task.sleep(for: .milliseconds(100))
        #expect(slugs(viewModel) == ["movie"])
    }

    @Test("shows only the latest observation after switching back and forth")
    func switchesBackAndForth() async throws {
        let blogA = makeBlog()
        let blogB = makeBlog()
        let viewModel = makeViewModel(blog: blogA)
        let firstA = try await sources.waitForSource(at: 0)
        try await firstA.waitForReads(1)

        viewModel.blog = blogB
        viewModel.blog = blogA
        let secondA = try await sources.waitForSource(at: 2)
        try await secondA.waitForReads(1)
        secondA.completeRead(with: [movie])
        try await waitUntil { slugs(viewModel) == ["movie"] }

        firstA.completeRead(with: [book])
        try await Task.sleep(for: .milliseconds(100))
        #expect(slugs(viewModel) == ["movie"])
        try await sources.waitForSource(at: 1).completeAllReads()
    }

    // MARK: - Cache record change

    @Test("starts observing after a sync when a client becomes available", arguments: Trigger.allCases)
    func startsWhenClientArrives(trigger: Trigger) async throws {
        sources.isAvailable = false
        let viewModel = makeViewModel(blog: makeBlog())
        #expect(viewModel.customPostTypes.isEmpty)

        sources.isAvailable = true
        fire(trigger, on: viewModel)

        let source = try await sources.waitForSource(at: 0)
        try await source.waitForRefreshes(1)
        #expect(source.readCount == 0)
        source.completeRefresh()

        try await source.waitForReads(1)
        source.completeRead(with: [book])
        try await waitUntil { slugs(viewModel) == ["book"] }
    }

    @Test("syncs the new cache record before replacing the rows", arguments: Trigger.allCases)
    func replacesObservationWhenCacheRecordChanges(trigger: Trigger) async throws {
        let viewModel = makeViewModel(blog: makeBlog())
        let sourceA = try await sources.waitForSource(at: 0)
        try await sourceA.waitForReads(1)
        sourceA.completeRead(with: [book])
        try await waitUntil { slugs(viewModel) == ["book"] }
        sourceA.updates.send()
        try await sourceA.waitForReads(2)

        sources.cacheIdentity = directAccess
        fire(trigger, on: viewModel)

        let sourceB = try await sources.waitForSource(at: 1)
        try await sourceB.waitForRefreshes(1)
        #expect(sourceB.readCount == 0)
        #expect(slugs(viewModel) == ["book"])
        sourceB.completeRefresh()

        try await sourceB.waitForReads(1)
        sourceB.completeRead(with: [song])
        try await waitUntil { slugs(viewModel) == ["song"] }

        sourceA.completeRead(with: [movie])
        try await Task.sleep(for: .milliseconds(100))
        #expect(slugs(viewModel) == ["song"])
    }

    @Test("keeps the observation when the cache record is unchanged", arguments: Trigger.allCases)
    func keepsObservationWhenCacheRecordIsUnchanged(trigger: Trigger) async throws {
        let viewModel = makeViewModel(blog: makeBlog())
        let sourceA = try await sources.waitForSource(at: 0)
        try await sourceA.waitForReads(1)
        sourceA.completeRead(with: [book])
        try await waitUntil { slugs(viewModel) == ["book"] }

        fire(trigger, on: viewModel)

        // The trigger built a service, but the observation stays on source A: cancelling it
        // would stop the read below.
        _ = try await sources.waitForSource(at: 1)
        sourceA.updates.send()
        try await sourceA.waitForReads(2)
        sourceA.completeRead(with: [movie])
        try await waitUntil { slugs(viewModel) == ["movie"] }
    }

    @Test("keeps the rows until an update when syncing the new cache record fails")
    func keepsRowsWhenSyncFails() async throws {
        let viewModel = makeViewModel(blog: makeBlog())
        let sourceA = try await sources.waitForSource(at: 0)
        try await sourceA.waitForReads(1)
        sourceA.completeRead(with: [book])
        try await waitUntil { slugs(viewModel) == ["book"] }

        sources.cacheIdentity = directAccess
        viewModel.updateCustomPostTypesObservationIfNeeded()

        let sourceB = try await sources.waitForSource(at: 1)
        try await sourceB.waitForRefreshes(1)
        sourceB.failRefresh()
        try await Task.sleep(for: .milliseconds(100))
        #expect(sourceB.readCount == 0)
        #expect(slugs(viewModel) == ["book"])

        sourceB.updates.send()
        try await sourceB.waitForReads(1)
        sourceB.completeRead(with: [song])
        try await waitUntil { slugs(viewModel) == ["song"] }
    }

    // MARK: - Helpers

    enum Trigger: CaseIterable {
        case applicationPasswordUpdated
        case metadataSync
    }

    private let directAccess = CustomPostTypeService.CacheIdentity.direct(
        siteURL: URL(string: "https://example.com")!,
        apiRootURL: "https://example.com/wp-json/"
    )

    private func fire(_ trigger: Trigger, on viewModel: BlogDetailsTableViewModel) {
        switch trigger {
        case .applicationPasswordUpdated:
            notificationCenter.post(name: SelfHostedSiteAuthenticator.applicationPasswordUpdated, object: nil)
        case .metadataSync:
            viewModel.updateCustomPostTypesObservationIfNeeded()
        }
    }

    private func makeBlog() -> Blog {
        BlogBuilder(contextManager.mainContext).build()
    }

    private func makeViewModel(blog: Blog) -> BlogDetailsTableViewModel {
        BlogDetailsTableViewModel(
            blog: blog,
            viewController: BlogDetailsViewController(blog: blog),
            makeCustomPostTypeService: { [sources] in sources.make(for: $0) },
            notificationCenter: notificationCenter
        )
    }

    private func slugs(_ viewModel: BlogDetailsTableViewModel) -> [String] {
        viewModel.customPostTypes.map(\.slug)
    }
}

/// Records every source the view model creates, in creation order.
@MainActor
private final class FakeSources {
    var isAvailable = true
    var cacheIdentity = CustomPostTypeService.CacheIdentity.dotComProxy(siteId: 1)
    private(set) var blogs: [Blog] = []
    private var sources: [FakeSource] = []

    func make(for blog: Blog) -> CustomPostTypeService.SiteMenuService? {
        guard isAvailable else { return nil }
        let source = FakeSource()
        blogs.append(blog)
        sources.append(source)
        return (cacheIdentity, source)
    }

    func waitForSource(at index: Int) async throws -> FakeSource {
        try await waitUntil { sources.count > index }
        return sources[index]
    }
}

@MainActor
private final class FakeSource: CustomPostTypeServiceProtocol {
    let updates = PassthroughSubject<Void, Never>()
    private(set) var readCount = 0
    private(set) var refreshCount = 0
    private var pendingReads: [CheckedContinuation<[PostTypeDetailsWithEditContext], Error>] = []
    private var pendingRefreshes: [CheckedContinuation<Void, Error>] = []

    func refresh() async throws {
        refreshCount += 1
        try await withCheckedThrowingContinuation { pendingRefreshes.append($0) }
    }

    func waitForRefreshes(_ count: Int) async throws {
        try await waitUntil { refreshCount == count && pendingRefreshes.count == 1 }
    }

    func completeRefresh() {
        pendingRefreshes.removeFirst().resume()
    }

    func failRefresh() {
        pendingRefreshes.removeFirst().resume(throwing: URLError(.notConnectedToInternet))
    }

    func customTypesUpdates() async throws -> AnyPublisher<Void, Never> {
        updates.eraseToAnyPublisher()
    }

    func customTypes() async throws -> [PostTypeDetailsWithEditContext] {
        readCount += 1
        return try await withCheckedThrowingContinuation { pendingReads.append($0) }
    }

    func waitForReads(_ count: Int) async throws {
        try await waitUntil { readCount == count && pendingReads.count == 1 }
    }

    func completeRead(with types: [PostTypeDetailsWithEditContext]) {
        pendingReads.removeFirst().resume(returning: types)
    }

    func completeAllReads() {
        let reads = pendingReads
        pendingReads = []
        reads.forEach { $0.resume(returning: []) }
    }
}

/// Waits without a deadline. Other tests share the main actor, so any fixed deadline fails on a
/// busy machine. The suite's time limit catches hangs by cancelling the sleep.
@MainActor
private func waitUntil(_ condition: () -> Bool) async throws {
    while !condition() {
        try await Task.sleep(for: .milliseconds(5))
    }
}
