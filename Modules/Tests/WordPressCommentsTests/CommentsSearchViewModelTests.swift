import Combine
import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressComments

@MainActor
struct CommentsSearchViewModelTests {
    @Test(arguments: ["  abc\n", "a", "0", " A  B "])
    func submitsTrimmedQueries(text: String) async {
        let service = FakeCommentsService()
        service.searchResults = [.success(makePage(items: [], hasNext: false))]
        let model = CommentsSearchViewModel(service: service)
        #expect(model.state == .prompt)
        await model.submit(text)
        #expect(service.searchRequests.first?.query == text.trimmingCharacters(in: .whitespacesAndNewlines))
        #expect(model.state == .loaded)
        #expect(model.items.isEmpty)
        #expect(!model.canLoadMore)
    }

    @Test func emptySubmissionsAreIgnoredAndExplicitResubmissionReloads() async {
        let service = FakeCommentsService()
        service.searchResults = [
            .success(makePage(items: [makeItem(id: 1)], hasNext: true)),
            .success(makePage(items: [makeItem(id: 2)], hasNext: false))
        ]
        let model = CommentsSearchViewModel(service: service)
        await model.refresh()
        await model.retry()
        await model.loadMore()
        await model.submit(" \n")
        #expect(service.searchRequests.isEmpty)
        await model.submit("abc")
        #expect(model.items.map(\.id) == [1])
        #expect(model.canLoadMore)
        await model.submit(" ")
        #expect(service.searchRequests.count == 1)
        #expect(model.items.map(\.id) == [1])
        await model.submit("abc")
        #expect(model.items.map(\.id) == [2])
        #expect(service.searchRequests.map(\.query) == ["abc", "abc"])
    }

    @Test func duplicateInFlightSubmissionIsSuppressed() async {
        let service = BlockingCommentsService()
        let model = CommentsSearchViewModel(service: service)
        async let first: Void = model.submit("abc")
        await waitUntil { service.searchRequests.count == 1 }
        #expect(model.state == .loading)
        await model.submit(" abc ")
        #expect(service.searchRequests.count == 1)
        service.resolveSearch(callIndex: 0, with: .success(makePage(items: [makeItem(id: 1)], hasNext: false)))
        await first
        #expect(model.submittedQuery == "abc")
        #expect(model.items.map(\.id) == [1])
    }

    @Test(arguments: [false, true])
    func oldCompletionCannotChangeNewSubmission(fails: Bool) async {
        let service = BlockingCommentsService()
        let model = CommentsSearchViewModel(service: service)
        async let old: Void = model.submit("old")
        await waitUntil { service.searchRequests.count == 1 }
        async let new: Void = model.submit("new")
        await waitUntil { service.searchRequests.count == 2 }
        service.resolveSearch(callIndex: 1, with: .failure(FakeServiceError()))
        await new
        service.resolveSearch(
            callIndex: 0,
            with: fails ? .failure(FakeServiceError()) : .success(makePage(items: [makeItem(id: 1)], hasNext: true))
        )
        await old
        #expect(model.state == .failed)
        #expect(model.items.isEmpty)
        #expect(model.submittedQuery == "new")
        #expect(!model.canLoadMore)
    }

    @Test(arguments: [false, true])
    func cancelInvalidatesLateCompletion(fails: Bool) async {
        let service = BlockingCommentsService()
        let model = CommentsSearchViewModel(service: service)
        async let first: Void = model.submit("abc")
        await waitUntil { service.searchRequests.count == 1 }
        model.cancel()
        service.resolveSearch(
            callIndex: 0,
            with: fails ? .failure(FakeServiceError()) : .success(makePage(items: [makeItem(id: 1)], hasNext: true))
        )
        await first
        #expect(model.submittedQuery == nil)
        #expect(model.state == .prompt)
        #expect(model.items.isEmpty)
        #expect(!model.canLoadMore)
    }

    @Test func paginationDeduplicatesAndRetainsSubmittedQueryAndContinuation() async {
        let service = FakeCommentsService()
        let token = CommentsPageToken(params: .init(page: 7, perPage: 3, search: "abc", order: .desc, status: .all))
        service.searchResults = [
            .success(CommentsPage(items: [makeItem(id: 1), makeItem(id: 1)], nextPage: token)),
            .failure(FakeServiceError()),
            .success(makePage(items: [makeItem(id: 1), makeItem(id: 2), makeItem(id: 2)], hasNext: false))
        ]
        let model = CommentsSearchViewModel(service: service)
        await model.submit("abc")
        await model.loadMore()
        #expect(model.loadMoreFailed)
        #expect(model.items.map(\.id) == [1])
        await model.loadMore()
        #expect(service.searchRequests.count == 2)
        await model.retry()
        #expect(service.searchRequests.map(\.query) == ["abc", "abc", "abc"])
        #expect(service.searchRequests[1].nextPage == token)
        #expect(service.searchRequests[2].nextPage == token)
        #expect(model.items.map(\.id) == [1, 2])
        #expect(!model.canLoadMore)
        await model.loadMore()
        #expect(service.searchRequests.count == 3)
    }

    @Test(arguments: [false, true])
    func canceledPaginationRemainsRetryable(wrappedError: Bool) async {
        let service = BlockingCommentsService()
        let model = CommentsSearchViewModel(service: service)
        async let first: Void = model.submit("abc")
        await waitUntil { service.searchRequests.count == 1 }
        service.resolveSearch(callIndex: 0, with: .success(makePage(items: [makeItem(id: 1)], hasNext: true)))
        await first
        let token = model.nextPage

        let more = Task { await model.loadMore() }
        await waitUntil { service.searchRequests.count == 2 }
        more.cancel()
        service.resolveSearch(
            callIndex: 1,
            with: .failure(wrappedError ? FakeServiceError() : CancellationError())
        )
        await more.value
        #expect(model.items.map(\.id) == [1])
        #expect(!model.isLoadingMore)
        #expect(!model.loadMoreFailed)
        #expect(model.canLoadMore)
        #expect(model.nextPage == token)

        async let retry: Void = model.loadMore()
        await waitUntil { service.searchRequests.count == 3 }
        #expect(service.searchRequests[2].nextPage == token)
        service.resolveSearch(callIndex: 2, with: .success(makePage(items: [makeItem(id: 2)], hasNext: false)))
        await retry
        #expect(model.items.map(\.id) == [1, 2])
        #expect(!model.canLoadMore)
    }

    @Test func firstPageRetryAndResubmitUseSubmittedAndDraftQueriesRespectively() async {
        let service = FakeCommentsService()
        service.searchResults = [
            .failure(FakeServiceError()), .failure(FakeServiceError()), .success(makePage(items: [], hasNext: false))
        ]
        let model = CommentsSearchViewModel(service: service)
        await model.submit("abc")
        await model.retry()
        #expect(model.state == .failed)
        await model.submit("xyz")
        #expect(service.searchRequests.map(\.query) == ["abc", "abc", "xyz"])
        #expect(model.state == .loaded)
    }

    @Test(arguments: [false, true])
    func refreshInvalidatesPaginationAndRetainsRowsOnFailure(fails: Bool) async {
        let service = BlockingCommentsService()
        let model = CommentsSearchViewModel(service: service)
        async let first: Void = model.submit("abc")
        await waitUntil { service.searchRequests.count == 1 }
        service.resolveSearch(callIndex: 0, with: .success(makePage(items: [makeItem(id: 1)], hasNext: true)))
        await first
        async let more: Void = model.loadMore()
        await waitUntil { service.searchRequests.count == 2 }
        await model.loadMore()
        #expect(service.searchRequests.count == 2)
        async let refresh: Void = model.refresh()
        await waitUntil { service.searchRequests.count == 3 }
        #expect(model.items.map(\.id) == [1])
        #expect(model.state == .refreshing)
        service.resolveSearch(
            callIndex: 1,
            with: fails ? .failure(FakeServiceError()) : .success(makePage(items: [makeItem(id: 2)], hasNext: true))
        )
        await more
        #expect(model.state == .refreshing)
        #expect(!model.isLoadingMore)
        #expect(!model.loadMoreFailed)
        #expect(model.items.map(\.id) == [1])
        service.resolveSearch(callIndex: 2, with: .failure(FakeServiceError()))
        await refresh
        #expect(model.state == .refreshFailed)
        #expect(model.items.map(\.id) == [1])
        await model.loadMore()
        #expect(service.searchRequests.count == 3)
        async let retry: Void = model.retry()
        await waitUntil { service.searchRequests.count == 4 }
        service.resolveSearch(callIndex: 3, with: .success(makePage(items: [makeItem(id: 3)], hasNext: false)))
        await retry
        #expect(model.items.map(\.id) == [3])
        #expect(model.state == .loaded)
        #expect(service.searchRequests.allSatisfy { $0.query == "abc" })
        #expect(service.searchRequests[3].nextPage == nil)
    }

    @Test func eventsReconcileLoadedAndDelayedRowsWithoutRefetching() async {
        let service = BlockingCommentsService()
        let events = PassthroughSubject<CommentChangeEvent, Never>()
        let model = CommentsSearchViewModel(service: service, changeEvents: events.eraseToAnyPublisher())
        async let first: Void = model.submit("abc")
        await waitUntil { service.searchRequests.count == 1 }
        events.send(.statusChanged(id: 1, to: .pending))
        events.send(.contentChanged(id: 1, contentHTML: "<p>Edited</p>", contentRaw: nil))
        events.send(.deleted(id: 2))
        service.resolveSearch(
            callIndex: 0,
            with: .success(makePage(items: [makeItem(id: 1), makeItem(id: 2)], hasNext: true))
        )
        await first
        #expect(model.items.map(\.id) == [1])
        #expect(model.items.first?.status == .pending)
        #expect(model.items.first?.snippet == "Edited")
        async let more: Void = model.loadMore()
        await waitUntil { service.searchRequests.count == 2 }
        events.send(.statusChanged(id: 1, to: .approved))
        events.send(.statusChanged(id: 3, to: .spam))
        events.send(.statusChanged(id: 3, to: .approved))
        events.send(.statusChanged(id: 4, to: .trash))
        events.send(.statusChanged(id: 5, to: .other("post-trashed")))
        events.send(.replyCreated(parentID: 1, replyStatus: .approved))
        service.resolveSearch(
            callIndex: 1,
            with: .success(makePage(items: (1...6).map { makeItem(id: Int64($0)) }, hasNext: true))
        )
        await more
        #expect(model.items.map(\.id) == [1, 6])
        #expect(model.items.first?.status == .approved)
        #expect(model.items.first?.snippet == "Edited")
        #expect(service.searchRequests.count == 2)
        events.send(.deleted(id: 6))
        #expect(model.items.map(\.id) == [1])
        async let refresh: Void = model.refresh()
        await waitUntil { service.searchRequests.count == 3 }
        events.send(.contentChanged(id: 1, contentHTML: "Fresh edit", contentRaw: nil))
        events.send(.statusChanged(id: 3, to: .trash))
        service.resolveSearch(
            callIndex: 2,
            with: .success(makePage(items: [makeItem(id: 1), makeItem(id: 2), makeItem(id: 3)], hasNext: false))
        )
        await refresh
        #expect(model.items.map(\.id) == [1, 2])
        #expect(model.items.first?.snippet == "Fresh edit")
    }

    @Test(arguments: [false, true])
    func refreshDuringFirstLoadDiscardsOldResponseAndExposesRefreshFailure(fails: Bool) async {
        let service = BlockingCommentsService()
        let model = CommentsSearchViewModel(service: service)
        async let first: Void = model.submit("abc")
        await waitUntil { service.searchRequests.count == 1 }
        async let refresh: Void = model.refresh()
        await waitUntil { service.searchRequests.count == 2 }
        service.resolveSearch(callIndex: 1, with: .failure(FakeServiceError()))
        await refresh
        service.resolveSearch(
            callIndex: 0,
            with: fails ? .failure(FakeServiceError()) : .success(makePage(items: [makeItem(id: 1)], hasNext: true))
        )
        await first
        #expect(model.state == .refreshFailed)
        #expect(model.items.isEmpty)
        #expect(!model.canLoadMore)
    }

    @Test func emptyPageWithContinuationDoesNotEndPagination() async {
        let service = FakeCommentsService()
        service.searchResults = [
            .success(makePage(items: [], hasNext: true)),
            .success(makePage(items: [makeItem(id: 1)], hasNext: false))
        ]
        let model = CommentsSearchViewModel(service: service)
        await model.submit("abc")
        #expect(model.canLoadMore)
        await model.loadMore()
        #expect(model.items.map(\.id) == [1])
        #expect(!model.canLoadMore)
    }

    @Test func detailFetch404KeepsResultButModeration404RemovesIt() async {
        let service = FakeCommentsService()
        service.searchResults = [.success(makePage(items: [makeItem(id: 1)], hasNext: false))]
        service.fetchCommentResult = .failure(WpApiError.stub(statusCode: 404))
        service.setStatusResult = .failure(WpApiError.stub(statusCode: 404))
        let coordinator = CommentsModerationCoordinator(service: service)
        let model = CommentsSearchViewModel(service: service, changeEvents: coordinator.events.eraseToAnyPublisher())
        await model.submit("abc")
        let detail = makeVM(service: service, coordinator: coordinator)
        await detail.onAppear()
        #expect(model.items.map(\.id) == [1])
        _ = try? await coordinator.perform(.approve, on: makeDetail(status: .hold))
        #expect(model.items.isEmpty)
        #expect(service.searchRequests.count == 1)
    }

    @Test func searchParametersUseCoreApprovedAndPendingScope() {
        let params = CommentsListFilter.all.firstPageParams(search: "A  B")
        #expect(params.search == "A  B")
        #expect(params.status == .all)
        #expect(params.perPage == 20)
        #expect(params.order == .desc)
        #expect(params.orderby == .dateGmt)
    }
}
