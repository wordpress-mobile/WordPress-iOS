import Foundation
import Testing
@testable import WordPressComments

@MainActor
struct CommentsListViewModelConcurrencyTests {
    @Test func staleLoadMoreAfterRefreshIsDiscarded() async {
        let service = BlockingCommentsService()
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        // First load (call 0).
        async let firstLoad: Void = viewModel.onAppear()
        while service.callCount < 1 { await Task.yield() }
        service.resolve(callIndex: 0, with: makePage(items: [makeItem(id: 1)], hasNext: true))
        await firstLoad
        #expect(viewModel.items.map(\.id) == [1])

        // Start load-more (call 1); it suspends before appending.
        async let more: Void = viewModel.loadMore()
        while service.callCount < 2 { await Task.yield() }

        // A refresh (call 2) lands and completes while load-more is still in
        // flight.
        async let refresh: Void = viewModel.refresh()
        while service.callCount < 3 { await Task.yield() }
        service.resolve(callIndex: 2, with: makePage(items: [makeItem(id: 9)], hasNext: false))
        await refresh
        #expect(viewModel.items.map(\.id) == [9])

        // The stale load-more now resumes with a page from the obsolete cursor;
        // it must be dropped rather than appended onto the refreshed list.
        service.resolve(callIndex: 1, with: makePage(items: [makeItem(id: 5)], hasNext: true))
        await more
        #expect(viewModel.items.map(\.id) == [9])
    }
}
