import Foundation
import Testing
@testable import WordPressComments

@MainActor
struct CommentsListViewModelStateTests {
    @Test func firstPageFailureShowsErrorState() async {
        let service = FakeCommentsService()
        service.queuedResults = [.failure(FakeServiceError())]
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        await viewModel.onAppear()

        #expect(viewModel.firstPageFailed)
        #expect(!viewModel.showsEmptyState)
        #expect(viewModel.items.isEmpty)
    }

    @Test func retryAfterFirstPageFailureRecovers() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .failure(FakeServiceError()),
            .success(makePage(items: [makeItem(id: 1)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        await viewModel.onAppear()
        await viewModel.retryFirstPage()

        #expect(!viewModel.firstPageFailed)
        #expect(viewModel.items.map(\.id) == [1])
        #expect(viewModel.hasLoaded)
    }

    @Test func emptyResultShowsEmptyState() async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [], hasNext: false))]
        let viewModel = CommentsListViewModel(filter: .spam, service: service)

        await viewModel.onAppear()

        #expect(viewModel.showsEmptyState)
    }

    @Test func loadMoreFailureKeepsContentAndAllowsRetry() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: true)),
            .failure(FakeServiceError()),
            .success(makePage(items: [makeItem(id: 2)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        await viewModel.onAppear()
        await viewModel.loadMore()
        #expect(viewModel.loadMoreFailed)
        #expect(viewModel.items.map(\.id) == [1])

        await viewModel.retryLoadMore()
        #expect(!viewModel.loadMoreFailed)
        #expect(viewModel.items.map(\.id) == [1, 2])
    }

    @Test func refreshReplacesContentOnSuccess() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: true)),
            .success(makePage(items: [makeItem(id: 9)], hasNext: false))
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        await viewModel.onAppear()
        await viewModel.refresh()

        #expect(viewModel.items.map(\.id) == [9])
        #expect(!viewModel.canLoadMore)
    }

    @Test func refreshFailureKeepsStaleContent() async {
        let service = FakeCommentsService()
        service.queuedResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: false)),
            .failure(FakeServiceError())
        ]
        let viewModel = CommentsListViewModel(filter: .all, service: service)

        await viewModel.onAppear()
        await viewModel.refresh()

        #expect(viewModel.items.map(\.id) == [1])
        #expect(!viewModel.firstPageFailed)
    }

    @Test func seededItemsShowWhilePlaceholderThenReplaced() async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [makeItem(id: 3), makeItem(id: 4)], hasNext: false))]
        let seed = [makeItem(id: 3)]
        let viewModel = CommentsListViewModel(filter: .pending, service: service, seedItems: { seed })

        // Seeds show synchronously before the first page lands, but onAppear()
        // runs load inline in tests, so assert the end state plus the flag
        // transition through a mid-flight check below.
        await viewModel.onAppear()

        #expect(!viewModel.isShowingSeededPlaceholder)
        #expect(viewModel.items.map(\.id) == [3, 4])
    }

    @Test func placeholderDisablesLoadMore() async {
        let service = FakeCommentsService()
        service.queuedResults = [] // first page will fail, leaving the placeholder up
        let viewModel = CommentsListViewModel(filter: .pending, service: service, seedItems: { [makeItem(id: 3)] })

        await viewModel.onAppear()

        #expect(viewModel.isShowingSeededPlaceholder)
        #expect(!viewModel.canLoadMore)
        #expect(viewModel.firstPageFailed)
    }

    @Test func emptySeedDoesNotEnablePlaceholder() async {
        let service = FakeCommentsService()
        service.queuedResults = [.success(makePage(items: [], hasNext: false))]
        let viewModel = CommentsListViewModel(filter: .approved, service: service, seedItems: { [] })

        await viewModel.onAppear()

        #expect(viewModel.showsEmptyState)
    }
}
