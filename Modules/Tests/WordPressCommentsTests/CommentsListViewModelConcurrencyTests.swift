import Foundation
import Testing
import WordPressAPI
@testable import WordPressComments

@MainActor
struct CommentsListViewModelConcurrencyTests {
    @Test func staleLoadMoreAfterRefreshIsDiscarded() async {
        let service = BlockingCommentsService()
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        // First load (call 0).
        async let firstLoad: Void = viewModel.onAppear()
        await waitUntil { service.callCount >= 1 }
        service.resolve(callIndex: 0, with: makePage(items: [makeItem(id: 1)], hasNext: true))
        await firstLoad
        #expect(viewModel.items.map(\.id) == [1])

        // Start load-more (call 1); it suspends before appending.
        async let more: Void = viewModel.loadMore()
        await waitUntil { service.callCount >= 2 }

        // A refresh (call 2) lands and completes while load-more is still in
        // flight.
        async let refresh: Void = viewModel.refresh()
        await waitUntil { service.callCount >= 3 }
        service.resolve(callIndex: 2, with: makePage(items: [makeItem(id: 9)], hasNext: false))
        await refresh
        #expect(viewModel.items.map(\.id) == [9])

        // The stale load-more now resumes with a page from the obsolete cursor;
        // it must be dropped rather than appended onto the refreshed list.
        service.resolve(callIndex: 1, with: makePage(items: [makeItem(id: 5)], hasNext: true))
        await more
        #expect(viewModel.items.map(\.id) == [9])
    }

    @Test func inFlightLoadMoreDoesNotResurrectModeratedRow() async {
        let service = BlockingCommentsService()
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        // First load (call 0): rows 1 and 5.
        async let firstLoad: Void = viewModel.onAppear()
        await waitUntil { service.callCount >= 1 }
        service.resolve(callIndex: 0, with: makePage(items: [makeItem(id: 1), makeItem(id: 5)], hasNext: true))
        await firstLoad
        #expect(viewModel.items.map(\.id) == [1, 5])

        // Start load-more (call 1); it suspends before appending.
        async let more: Void = viewModel.loadMore()
        await waitUntil { service.callCount >= 2 }

        // A moderation removes row 5 while the page is in flight.
        viewModel.apply(.deleted(id: 5))
        #expect(viewModel.items.map(\.id) == [1])

        // The in-flight page still contains row 5 (offset paging re-served it).
        // The removal invalidated this fetch, so it must be discarded rather
        // than re-adding row 5 as "fresh" (no longer in seenIDs).
        service.resolve(callIndex: 1, with: makePage(items: [makeItem(id: 5), makeItem(id: 2)], hasNext: false))
        await more
        #expect(viewModel.items.map(\.id) == [1])
    }

    @Test func normalLoadMoreStillAppends() async {
        let service = BlockingCommentsService()
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        async let firstLoad: Void = viewModel.onAppear()
        await waitUntil { service.callCount >= 1 }
        service.resolve(callIndex: 0, with: makePage(items: [makeItem(id: 1)], hasNext: true))
        await firstLoad

        // A load-more with no intervening moderation appends normally.
        async let more: Void = viewModel.loadMore()
        await waitUntil { service.callCount >= 2 }
        service.resolve(callIndex: 1, with: makePage(items: [makeItem(id: 2)], hasNext: false))
        await more

        #expect(viewModel.items.map(\.id) == [1, 2])
    }

    @Test func inFlightRefreshDoesNotResurrectModeratedRow() async {
        let service = BlockingCommentsService()
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        // First load (call 0): rows 1 and 5.
        async let firstLoad: Void = viewModel.onAppear()
        await waitUntil { service.callCount >= 1 }
        service.resolve(callIndex: 0, with: makePage(items: [makeItem(id: 1), makeItem(id: 5)], hasNext: false))
        await firstLoad
        #expect(viewModel.items.map(\.id) == [1, 5])

        // Start a refresh (call 1); it suspends before replacing the list.
        async let refreshing: Void = viewModel.refresh()
        await waitUntil { service.callCount >= 2 }

        // A moderation removes row 5 while the refresh is in flight.
        viewModel.apply(.deleted(id: 5))
        #expect(viewModel.items.map(\.id) == [1])

        // The in-flight refresh page still contains row 5 (pre-mutation). It must
        // be discarded rather than replacing the list and resurrecting the row.
        service.resolve(callIndex: 1, with: makePage(items: [makeItem(id: 1), makeItem(id: 5)], hasNext: false))
        await refreshing
        #expect(viewModel.items.map(\.id) == [1])
    }

    @Test func inFlightPageOneDoesNotOverwriteInPlaceStatusUpdate() async {
        let service = BlockingCommentsService()
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        // First load (call 0): row 1 pending.
        async let firstLoad: Void = viewModel.onAppear()
        await waitUntil { service.callCount >= 1 }
        service.resolve(callIndex: 0, with: makePage(items: [makeItem(id: 1, status: .hold)], hasNext: false))
        await firstLoad
        #expect(viewModel.items.first?.status == .pending)

        // Mark the tab stale (an approved comment that belongs here but is
        // absent can't be placed in a paged list); the tab schedules its own
        // page-one reload (call 1), which suspends.
        viewModel.apply(.statusChanged(id: 99, to: .approved))
        await waitUntil { service.callCount >= 2 }

        // An approve reconciles the row in place while the reload is in flight,
        // invalidating the in-flight page.
        viewModel.apply(.statusChanged(id: 1, to: .approved))
        #expect(viewModel.items.first?.status == .approved)

        // The invalidated page must NOT overwrite the corrected status. Instead
        // the reload refetches (exactly one more request) and converges on fresh
        // authoritative data, without a manual refresh.
        service.resolve(callIndex: 1, with: makePage(items: [makeItem(id: 1, status: .hold)], hasNext: false))
        await waitUntil { service.callCount >= 3 }
        service.resolve(callIndex: 2, with: makePage(items: [makeItem(id: 1, status: .approved)], hasNext: false))
        await waitUntil { viewModel.state == .loaded }
        #expect(viewModel.items.first?.status == .approved)
        #expect(viewModel.state == .loaded)
        #expect(service.callCount == 3)
    }

    @Test func inFlightInitialLoadInvalidationConvergesWithoutManualRefresh() async {
        let service = BlockingCommentsService()
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        // Initial load (call 0) is in flight.
        async let load: Void = viewModel.onAppear()
        await waitUntil { service.callCount >= 1 }

        // A moderation event bumps generation mid-flight (invalidating the
        // request) without marking the tab stale or bumping the reload counter,
        // so nothing external would reschedule a reload.
        viewModel.apply(.deleted(id: 99))

        // The invalidated page is discarded, but loading converges on its own
        // (exactly one more fetch) with no manual refresh or lifecycle event.
        service.resolve(callIndex: 0, with: makePage(items: [makeItem(id: 1)], hasNext: false))
        await waitUntil { service.callCount >= 2 }
        service.resolve(callIndex: 1, with: makePage(items: [makeItem(id: 2)], hasNext: false))
        await load

        #expect(viewModel.items.map(\.id) == [2])
        #expect(viewModel.state == .loaded)
        #expect(service.callCount == 2)
    }
}
