import Foundation
import Testing
@testable import WordPressComments

@MainActor
struct CommentsListViewModelEventTests {
    // MARK: - Approve (pending -> approved)

    @Test func approveEventRemovesFromPendingTabAndDropsSeenID() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1, status: .hold)], hasNext: true)),
            .success(makePage(items: [makeItem(id: 1, status: .hold)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .pending, service: service)
        await viewModel.onAppear()
        #expect(viewModel.items.map(\.id) == [1])

        viewModel.apply(.statusChanged(id: 1, to: .approved))
        #expect(viewModel.items.isEmpty)
        #expect(viewModel.state == .loaded)

        // If seenIDs still contained the removed ID, loadMore's dedupe would
        // silently drop this page and items would stay empty.
        await viewModel.loadMore()
        #expect(viewModel.items.map(\.id) == [1])
    }

    @Test func approveEventUpdatesRowInPlaceInAllTab() async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [makeItem(id: 1, status: .hold)], hasNext: false))]
        let viewModel = CommentsListViewModel(filter: .all, service: service)
        await viewModel.onAppear()

        viewModel.apply(.statusChanged(id: 1, to: .approved))

        #expect(viewModel.items.map(\.id) == [1])
        #expect(viewModel.items[0].status == .approved)
        #expect(viewModel.state == .loaded)
    }

    @Test func approveEventMarksApprovedTabStaleWhenMissingAndReloadsOnNextAppear() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 2, status: .approved)], hasNext: false)),
            .success(
                makePage(
                    items: [makeItem(id: 1, status: .approved), makeItem(id: 2, status: .approved)],
                    hasNext: false
                )
            )
        ]
        let viewModel = CommentsListViewModel(filter: .approved, service: service)
        await viewModel.onAppear()
        #expect(viewModel.items.map(\.id) == [2])

        viewModel.apply(.statusChanged(id: 1, to: .approved))
        #expect(viewModel.state == .awaitingReload)
        #expect(viewModel.items.map(\.id) == [2])

        await viewModel.onAppear()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items.map(\.id) == [1, 2])
        #expect(service.requests.count == 2)
    }

    // MARK: - Unapprove (approved -> pending), mirror of approve

    @Test func unapproveEventRemovesFromApprovedTabAndDropsSeenID() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1, status: .approved)], hasNext: true)),
            .success(makePage(items: [makeItem(id: 1, status: .approved)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .approved, service: service)
        await viewModel.onAppear()
        #expect(viewModel.items.map(\.id) == [1])

        viewModel.apply(.statusChanged(id: 1, to: .pending))
        #expect(viewModel.items.isEmpty)
        #expect(viewModel.state == .loaded)

        await viewModel.loadMore()
        #expect(viewModel.items.map(\.id) == [1])
    }

    @Test func unapproveEventUpdatesRowInPlaceInAllTab() async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [makeItem(id: 1, status: .approved)], hasNext: false))]
        let viewModel = CommentsListViewModel(filter: .all, service: service)
        await viewModel.onAppear()

        viewModel.apply(.statusChanged(id: 1, to: .pending))

        #expect(viewModel.items.map(\.id) == [1])
        #expect(viewModel.items[0].status == .pending)
        #expect(viewModel.state == .loaded)
    }

    @Test func unapproveEventMarksPendingTabStaleWhenMissingAndReloadsOnNextAppear() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 2, status: .hold)], hasNext: false)),
            .success(makePage(items: [makeItem(id: 1, status: .hold), makeItem(id: 2, status: .hold)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .pending, service: service)
        await viewModel.onAppear()
        #expect(viewModel.items.map(\.id) == [2])

        viewModel.apply(.statusChanged(id: 1, to: .pending))
        #expect(viewModel.state == .awaitingReload)
        #expect(viewModel.items.map(\.id) == [2])

        await viewModel.onAppear()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items.map(\.id) == [1, 2])
        #expect(service.requests.count == 2)
    }

    // MARK: - Spam / trash: removed from All/Pending/Approved, lands tab goes stale

    @Test(arguments: [CommentsListFilter.all, .pending, .approved])
    func spamEventRemovesFromNonSpamLoadedTabs(filter: CommentsListFilter) async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [makeItem(id: 1)], hasNext: false))]
        let viewModel = CommentsListViewModel(filter: filter, service: service)
        await viewModel.onAppear()

        viewModel.apply(.statusChanged(id: 1, to: .spam))

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.state == .loaded)
    }

    @Test func spamEventMarksSpamTabStaleWhenMissingAndReloadsOnNextAppear() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [], hasNext: false)),
            .success(makePage(items: [makeItem(id: 1, status: .spam)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .spam, service: service)
        await viewModel.onAppear()
        #expect(viewModel.items.isEmpty)

        viewModel.apply(.statusChanged(id: 1, to: .spam))
        #expect(viewModel.state == .awaitingReload)

        await viewModel.onAppear()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items.map(\.id) == [1])
        #expect(service.requests.count == 2)
    }

    @Test(arguments: [CommentsListFilter.all, .pending, .approved])
    func trashEventRemovesFromNonTrashLoadedTabs(filter: CommentsListFilter) async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [makeItem(id: 1)], hasNext: false))]
        let viewModel = CommentsListViewModel(filter: filter, service: service)
        await viewModel.onAppear()

        viewModel.apply(.statusChanged(id: 1, to: .trash))

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.state == .loaded)
    }

    @Test func trashEventMarksTrashTabStaleWhenMissingAndReloadsOnNextAppear() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [], hasNext: false)),
            .success(makePage(items: [makeItem(id: 1, status: .trash)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .trash, service: service)
        await viewModel.onAppear()
        #expect(viewModel.items.isEmpty)

        viewModel.apply(.statusChanged(id: 1, to: .trash))
        #expect(viewModel.state == .awaitingReload)

        await viewModel.onAppear()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items.map(\.id) == [1])
        #expect(service.requests.count == 2)
    }

    // MARK: - Restore landing on pending vs approved: only the landing tab + All go stale

    @Test func restoreToPendingRemovesFromSpamAndOnlyMarksPendingAndAllStale() async {
        let spamService = FakeCommentsService()
        spamService.queuedResults = [.success(makePage(items: [makeItem(id: 1, status: .spam)], hasNext: false))]
        let spamViewModel = CommentsListViewModel(filter: .spam, service: spamService)
        await spamViewModel.onAppear()
        spamViewModel.apply(.statusChanged(id: 1, to: .pending))
        #expect(spamViewModel.items.isEmpty)
        #expect(spamViewModel.state == .loaded)

        let pendingService = FakeCommentsService()
        pendingService.queuedResults = [.success(makePage(items: [], hasNext: false))]
        let pendingViewModel = CommentsListViewModel(filter: .pending, service: pendingService)
        await pendingViewModel.onAppear()
        pendingViewModel.apply(.statusChanged(id: 1, to: .pending))
        #expect(pendingViewModel.state == .awaitingReload)

        let allService = FakeCommentsService()
        allService.queuedResults = [.success(makePage(items: [], hasNext: false))]
        let allViewModel = CommentsListViewModel(filter: .all, service: allService)
        await allViewModel.onAppear()
        allViewModel.apply(.statusChanged(id: 1, to: .pending))
        #expect(allViewModel.state == .awaitingReload)

        let approvedService = FakeCommentsService()
        approvedService.queuedResults = [.success(makePage(items: [], hasNext: false))]
        let approvedViewModel = CommentsListViewModel(filter: .approved, service: approvedService)
        await approvedViewModel.onAppear()
        approvedViewModel.apply(.statusChanged(id: 1, to: .pending))
        #expect(approvedViewModel.state == .loaded)
        #expect(approvedViewModel.items.isEmpty)
    }

    @Test func restoreToApprovedRemovesFromTrashAndOnlyMarksApprovedAndAllStale() async {
        let trashService = FakeCommentsService()
        trashService.queuedResults = [.success(makePage(items: [makeItem(id: 1, status: .trash)], hasNext: false))]
        let trashViewModel = CommentsListViewModel(filter: .trash, service: trashService)
        await trashViewModel.onAppear()
        trashViewModel.apply(.statusChanged(id: 1, to: .approved))
        #expect(trashViewModel.items.isEmpty)
        #expect(trashViewModel.state == .loaded)

        let approvedService = FakeCommentsService()
        approvedService.queuedResults = [.success(makePage(items: [], hasNext: false))]
        let approvedViewModel = CommentsListViewModel(filter: .approved, service: approvedService)
        await approvedViewModel.onAppear()
        approvedViewModel.apply(.statusChanged(id: 1, to: .approved))
        #expect(approvedViewModel.state == .awaitingReload)

        let allService = FakeCommentsService()
        allService.queuedResults = [.success(makePage(items: [], hasNext: false))]
        let allViewModel = CommentsListViewModel(filter: .all, service: allService)
        await allViewModel.onAppear()
        allViewModel.apply(.statusChanged(id: 1, to: .approved))
        #expect(allViewModel.state == .awaitingReload)

        let pendingService = FakeCommentsService()
        pendingService.queuedResults = [.success(makePage(items: [], hasNext: false))]
        let pendingViewModel = CommentsListViewModel(filter: .pending, service: pendingService)
        await pendingViewModel.onAppear()
        pendingViewModel.apply(.statusChanged(id: 1, to: .approved))
        #expect(pendingViewModel.state == .loaded)
        #expect(pendingViewModel.items.isEmpty)
    }

    // MARK: - Custom status (e.g. post-trashed): removed everywhere, never stale

    @Test(arguments: CommentsListFilter.allCases)
    func otherStatusEventRemovesFromEveryLoadedTabWithoutMarkingStale(filter: CommentsListFilter) async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [makeItem(id: 1)], hasNext: false))]
        let viewModel = CommentsListViewModel(filter: filter, service: service)
        await viewModel.onAppear()

        viewModel.apply(.statusChanged(id: 1, to: .other("post-trashed")))

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.state == .loaded)
    }

    // MARK: - Deleted: removed everywhere

    @Test(arguments: CommentsListFilter.allCases)
    func deletedEventRemovesFromEveryLoadedTab(filter: CommentsListFilter) async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [makeItem(id: 1)], hasNext: false))]
        let viewModel = CommentsListViewModel(filter: filter, service: service)
        await viewModel.onAppear()

        viewModel.apply(.deleted(id: 1))

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.state == .loaded)
    }

    // MARK: - Stale reload resets

    @Test func staleReloadReplacesItemsClearsStaleAndResetsPaging() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: false)),
            .success(makePage(items: [makeItem(id: 2)], hasNext: true)),
            .success(makePage(items: [makeItem(id: 3)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)
        await viewModel.onAppear()
        #expect(viewModel.items.map(\.id) == [1])

        viewModel.apply(.statusChanged(id: 99, to: .pending))
        #expect(viewModel.state == .awaitingReload)

        await viewModel.onAppear()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items.map(\.id) == [2])
        #expect(viewModel.canLoadMore)

        await viewModel.loadMore()
        #expect(viewModel.items.map(\.id) == [2, 3])
    }

    @Test func staleReloadFailureKeepsStaleAndRetriesOnNextOnAppear() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: false)),
            .failure(FakeServiceError()),
            .success(makePage(items: [makeItem(id: 2)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)
        await viewModel.onAppear()
        #expect(viewModel.items.map(\.id) == [1])

        viewModel.apply(.statusChanged(id: 99, to: .pending))
        #expect(viewModel.state == .awaitingReload)

        // The reload attempt fails: the tab must stay awaiting a reload (not
        // silently settle as loaded) so it keeps retrying rather than freezing
        // on outdated items with no error state and no path back to fresh data.
        await viewModel.onAppear()
        #expect(viewModel.state == .awaitingReload)
        #expect(viewModel.items.map(\.id) == [1])

        await viewModel.onAppear()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items.map(\.id) == [2])
        #expect(service.requests.count == 3)
    }

    @Test func staleReloadWithSeedItemsReplacesFetchedItemsAndClearsStale() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: false)),
            .success(makePage(items: [makeItem(id: 2)], hasNext: false))
        ]
        var seedCallCount = 0
        let viewModel = CommentsListViewModel(
            filter: .pending,
            service: service,
            seedItems: {
                seedCallCount += 1
                return [makeItem(id: 99)]
            }
        )
        await viewModel.onAppear()
        #expect(viewModel.items.map(\.id) == [1])
        #expect(seedCallCount == 1)

        viewModel.apply(.statusChanged(id: 99, to: .pending))
        #expect(viewModel.state == .awaitingReload)

        // A stale reload must fetch and replace with the real page, not
        // re-seed a placeholder subset over already-loaded (if outdated)
        // items.
        await viewModel.onAppear()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items.map(\.id) == [2])
        #expect(seedCallCount == 1)
    }

    // MARK: - Visible-tab stale reload (FIX-L)

    @Test func staleFlagIsObservableAndClearedByReload() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: false)),
            .success(makePage(items: [makeItem(id: 2)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)
        await viewModel.onAppear()
        #expect(viewModel.state == .loaded)

        // A status change for a comment that belongs here but is absent marks
        // the (visible) tab stale; the view observes this published flag and
        // triggers a reload.
        viewModel.apply(.statusChanged(id: 99, to: .pending))
        #expect(viewModel.state == .awaitingReload)

        // The reload refetches page one and clears the flag (so the view's
        // onChange won't loop).
        await viewModel.onAppear()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items.map(\.id) == [2])
    }

    @Test func successfulRefreshClearsStale() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: false)),
            .success(makePage(items: [makeItem(id: 2)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)
        await viewModel.onAppear()
        viewModel.apply(.statusChanged(id: 99, to: .pending))
        #expect(viewModel.state == .awaitingReload)

        // A fresh full page from pull-to-refresh is authoritative: the tab is no
        // longer stale.
        await viewModel.refresh()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items.map(\.id) == [2])
    }

    @Test func markingStaleReloadsPageOneWithoutReappearing() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: false)),
            .success(makePage(items: [makeItem(id: 1), makeItem(id: 99)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)
        await viewModel.onAppear()

        // A comment that belongs here but is absent can't be placed in a paged
        // list; the tab reloads on its own rather than waiting for a tab switch.
        viewModel.apply(.statusChanged(id: 99, to: .pending))
        #expect(viewModel.state == .awaitingReload)

        await waitUntil { viewModel.state == .loaded }
        #expect(viewModel.items.map(\.id) == [1, 99])
    }

    @Test func failedStaleReloadOnEmptyTabKeepsEmptyStateAndIgnoresRetry() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [], hasNext: false)),
            .failure(FakeServiceError()),
            .success(makePage(items: [makeItem(id: 1, status: .spam)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .spam, service: service)
        await viewModel.onAppear()
        #expect(viewModel.showsEmptyState)

        // A stale reload is app-triggered, so its failure is silent even with
        // no rows to keep: the empty state stays rather than the full-screen
        // error, and retry (the error state's action) is a no-op.
        viewModel.apply(.statusChanged(id: 1, to: .spam))
        await viewModel.onAppear()
        #expect(viewModel.state == .awaitingReload)
        #expect(viewModel.showsEmptyState)
        await viewModel.retryFirstPage()
        #expect(viewModel.state == .awaitingReload)
        #expect(service.requests.count == 2)

        // The next appearance retries.
        await viewModel.onAppear()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.items.map(\.id) == [1])
    }
}
