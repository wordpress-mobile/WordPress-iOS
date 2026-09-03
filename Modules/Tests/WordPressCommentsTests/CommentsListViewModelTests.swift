import Foundation
import Testing
@testable import WordPressComments

@MainActor
struct CommentsListViewModelTests {
    @Test func firstLoadPopulatesItems() async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [makeItem(id: 1), makeItem(id: 2)], hasNext: true))]
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        await viewModel.onAppear()

        #expect(viewModel.items.map(\.id) == [1, 2])
        #expect(viewModel.state == .loaded)
        #expect(viewModel.canLoadMore)
    }

    @Test func onAppearIsNoOpAfterFirstLoad() async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [makeItem(id: 1)], hasNext: false))]
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        await viewModel.onAppear()
        await viewModel.onAppear()

        #expect(service.requests.count == 1)
    }

    @Test func loadMoreAppendsAndStopsAtEnd() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: true)),
            .success(makePage(items: [makeItem(id: 2)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        await viewModel.onAppear()
        await viewModel.loadMore()

        #expect(viewModel.items.map(\.id) == [1, 2])
        #expect(!viewModel.canLoadMore)

        await viewModel.loadMore()
        #expect(service.requests.count == 2)
    }

    @Test func loadMoreDeduplicatesOverlappingPage() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1), makeItem(id: 2)], hasNext: true)),
            .success(makePage(items: [makeItem(id: 2), makeItem(id: 3)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        await viewModel.onAppear()
        await viewModel.loadMore()

        #expect(viewModel.items.map(\.id) == [1, 2, 3])
    }

    @Test func loadMorePassesNextPageToken() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: true)),
            .success(makePage(items: [makeItem(id: 2)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .pending, service: service)

        await viewModel.onAppear()
        await viewModel.loadMore()

        #expect(service.requests[0].nextPage == nil)
        #expect(service.requests[1].nextPage != nil)
        #expect(service.requests.allSatisfy { $0.filter == .pending })
    }

    @Test func onItemsAppendedFiresPerPage() async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [makeItem(id: 1, post: 5)], hasNext: false))]
        var appended: [[Int64]] = []
        let viewModel = CommentsListViewModel(
            filter: .all,
            service: service,
            onItemsAppended: { items in
                appended.append(items.map(\.postID))
            }
        )

        await viewModel.onAppear()

        #expect(appended == [[5]])
    }
}
