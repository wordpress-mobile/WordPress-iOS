import Testing
@testable import WordPressComments

@MainActor
struct CommentReviewBatchTests {
    @Test func provisionalSeedCannotEnableReview() async {
        let service = BlockingCommentsService()
        let list = CommentsListViewModel(filter: .pending, service: service, seedItems: { [makeItem(status: .hold)] })
        #expect(list.reviewBatch.isEmpty)
        let load = Task { await list.onAppear() }
        await waitUntil { service.callCount == 1 }
        #expect(list.items.count == 1)
        #expect(list.reviewBatch.isEmpty)
        service.resolve(callIndex: 0, with: makePage(items: [makeItem(status: .hold)], hasNext: false))
        await load.value
        #expect(list.reviewBatch.count == 1)
    }

    @Test func failedEmptyAndOtherTabsCannotEnableReview() async {
        let service = FakeCommentsService()
        let failed = CommentsListViewModel(filter: .pending, service: service, seedItems: { [makeItem(status: .hold)] })
        await failed.onAppear()
        #expect(failed.reviewBatch.isEmpty)
        for filter in CommentsListFilter.allCases {
            service.queuedResults = [
                .success(makePage(items: filter == .pending ? [] : [makeItem(status: .hold)], hasNext: false))
            ]
            let list = CommentsListViewModel(filter: filter, service: service)
            await list.onAppear()
            #expect(list.reviewBatch.isEmpty)
        }
    }

    @Test func batchIncludesLoadedPagesBeyondOneHundredAndIgnoresLaterPaginationAndRefresh() async {
        let service = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: service)
        let list = CommentsListViewModel(
            filter: .pending,
            service: service,
            changeEvents: coordinator.events.eraseToAnyPublisher()
        )
        let pageOne = (1...100).map { makeItem(id: Int64($0), status: .hold) }
        let pageTwo = (101...150).map { makeItem(id: Int64($0), status: .hold) }
        let first = Task { await list.onAppear() }
        await waitUntil { service.callCount == 1 }
        service.resolve(callIndex: 0, with: makePage(items: pageOne, hasNext: true))
        await first.value
        let second = Task { await list.loadMore() }
        await waitUntil { service.callCount == 2 }
        service.resolve(callIndex: 1, with: makePage(items: pageTwo, hasNext: true))
        await second.value
        let third = Task { await list.loadMore() }
        await waitUntil { service.callCount == 3 }
        let session = CommentReviewViewModel(
            batch: list.reviewBatch,
            coordinator: coordinator,
            noticePresenter: FakeNoticePresenter()
        ) { item in
            makeVM(commentID: item.id, seed: item, service: service, coordinator: coordinator)
        }
        #expect(session.batch.map(\.id) == (1...150).map(Int64.init))
        #expect(service.callCount == 3)
        service.resolve(callIndex: 2, with: makePage(items: [makeItem(id: 151, status: .hold)], hasNext: false))
        await third.value
        #expect(list.items.count == 151)
        coordinator.noteExternalStatus(id: 2, to: .spam)
        session.skip(id: 1)
        #expect(session.position == 2)
        #expect(session.detail?.commentID == 3)
        #expect(session.batch.count == 150)
        let refresh = Task { await list.refresh() }
        await waitUntil { service.callCount == 4 }
        #expect(!list.reviewBatch.isEmpty)
        service.resolve(callIndex: 3, with: makePage(items: [makeItem(id: 152, status: .hold)], hasNext: false))
        await refresh.value
        #expect(session.batch.map(\.id) == (1...150).map(Int64.init))
        #expect(session.position == 2)
        #expect(service.callCount == 4)
    }
}
