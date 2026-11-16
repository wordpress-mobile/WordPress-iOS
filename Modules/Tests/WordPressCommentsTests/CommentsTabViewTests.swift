import Testing
@testable import WordPressComments

@MainActor
struct CommentsTabViewTests {
    @Test func reloadStaleTabsReloadsEveryStaleTabWithoutLoadingNewTabs() async {
        let allService = FakeCommentsService()
        allService.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: false)),
            .failure(FakeServiceError()),
            .success(makePage(items: [makeItem(id: 3)], hasNext: false))
        ]
        let pendingService = FakeCommentsService()
        pendingService.queuedResults = [
            .success(makePage(items: [makeItem(id: 2, status: .hold)], hasNext: false)),
            .failure(FakeServiceError()),
            .success(makePage(items: [makeItem(id: 4, status: .hold)], hasNext: false))
        ]
        let neverLoadedService = FakeCommentsService()
        let staleAllTab = CommentsListViewModel(filter: .all, service: allService)
        let stalePendingTab = CommentsListViewModel(filter: .pending, service: pendingService)
        await staleAllTab.onAppear()
        await stalePendingTab.onAppear()

        // Both loaded tabs become stale and their eager retries fail.
        staleAllTab.apply(.statusChanged(id: 99, to: .pending))
        stalePendingTab.apply(.statusChanged(id: 99, to: .pending))
        await waitUntil {
            staleAllTab.state == .awaitingReload && stalePendingTab.state == .awaitingReload
        }
        let neverLoadedTab = CommentsListViewModel(filter: .spam, service: neverLoadedService)

        let tabView = CommentsTabView(
            viewModels: [.all: staleAllTab, .pending: stalePendingTab, .spam: neverLoadedTab],
            router: makeRouter()
        )
        await tabView.reloadStaleTabs()

        #expect(staleAllTab.state == .loaded)
        #expect(stalePendingTab.state == .loaded)
        #expect(neverLoadedTab.state == .idle)
        #expect(allService.requests.map(\.filter) == [.all, .all, .all])
        #expect(pendingService.requests.map(\.filter) == [.pending, .pending, .pending])
        #expect(neverLoadedService.requests.isEmpty)
    }
}
