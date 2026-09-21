import Foundation
import Testing
@testable import Support

@MainActor
struct UnifiedSupportListViewModelTests {

    private let tracker = SpyUnifiedSupportTracker()

    @Test func showsFetchedConversations() async {
        let conversations: [UnifiedSupportConversationSummary] = [.make(id: 1), .make(id: 2)]
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(.init(fetchedConversations: [.success(conversations)]))
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded(conversations))
        #expect(!viewModel.isUpdatingCachedConversations)
        #expect(viewModel.notice == nil)
    }

    @Test func replacesCachedConversationsWithFetchedOnes() async {
        let fetchedConversations: [UnifiedSupportConversationSummary] = [.make(id: 2), .make(id: 1)]
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(
                .init(cachedConversations: [.make(id: 1)], fetchedConversations: [.success(fetchedConversations)])
            )
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded(fetchedConversations))
        #expect(!viewModel.isUpdatingCachedConversations)
    }

    @Test func keepsCachedConversationsWhenFetchingFails() async {
        let cachedConversations: [UnifiedSupportConversationSummary] = [.make(id: 1)]
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(
                .init(cachedConversations: cachedConversations, fetchedConversations: [.failure(MockError.failure)])
            )
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded(cachedConversations))
        #expect(!viewModel.isUpdatingCachedConversations)
        #expect(viewModel.notice?.message == UnifiedSupportLocalization.genericErrorMessage)
    }

    @Test func showsEmptyList() async {
        let viewModel = makeViewModel(MockUnifiedSupportDataProvider(.init(fetchedConversations: [.success([])])))

        await viewModel.load()

        #expect(viewModel.state == .loaded([]))
    }

    @Test func showsOfflineWhenTheRequestFailsBecauseTheDeviceIsOffline() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(.init(fetchedConversations: [.failure(UnifiedSupportError.offline)]))
        )

        await viewModel.load()

        #expect(viewModel.state == .offline)
    }

    @Test func showsOfflineWhenTheRequestFailsWithoutNetwork() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(.init(isOnline: false, fetchedConversations: [.failure(MockError.failure)]))
        )

        await viewModel.load()

        #expect(viewModel.state == .offline)
    }

    @Test func showsErrorWhenTheRequestFails() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(.init(fetchedConversations: [.failure(MockError.failure)]))
        )

        await viewModel.load()

        #expect(viewModel.state == .failed(MockError.failure))
    }

    @Test func showsErrorWhenTheConversationsCannotBeLoaded() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(.init(loadConversationsError: UnifiedSupportError.notLoggedIn))
        )

        await viewModel.load()

        #expect(viewModel.state == .failed(UnifiedSupportError.notLoggedIn))
    }

    @Test func ignoresCancelledRequests() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(.init(fetchedConversations: [.failure(CancellationError())]))
        )

        await viewModel.load()

        #expect(viewModel.state == .loading)
        #expect(viewModel.notice == nil)
        #expect(tracker.trackedEvents.isEmpty)
    }

    @Test func tracksLoadingFailures() async throws {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(.init(fetchedConversations: [.failure(MockError.failure)]))
        )

        await viewModel.load()

        let event = try #require(tracker.trackedEvents.first)
        guard case .failToLoadConversations(let error) = event else {
            Issue.record("Unexpected event: \(event)")
            return
        }
        #expect(error as? MockError == .failure)
    }

    @Test func tracksViewingTheList() throws {
        let viewModel = makeViewModel(MockUnifiedSupportDataProvider())

        viewModel.onAppear()

        let event = try #require(tracker.trackedEvents.first)
        guard case .viewConversationList = event else {
            Issue.record("Unexpected event: \(event)")
            return
        }
    }

    @Test func refreshShowsTheLatestConversations() async {
        let provider = MockUnifiedSupportDataProvider(
            .init(fetchedConversations: [.success([.make(id: 1)]), .success([.make(id: 2), .make(id: 1)])])
        )
        let viewModel = makeViewModel(provider)
        await viewModel.load()

        await viewModel.refresh()

        #expect(viewModel.state == .loaded([.make(id: 2), .make(id: 1)]))
        #expect(provider.conversationsFetchCount == 2)
    }

    @Test func refreshKeepsTheConversationsWhenItFails() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(
                .init(fetchedConversations: [.success([.make(id: 1)]), .failure(UnifiedSupportError.offline)])
            )
        )
        await viewModel.load()

        await viewModel.refresh()

        #expect(viewModel.state == .loaded([.make(id: 1)]))
        #expect(viewModel.notice?.message == UnifiedSupportLocalization.offlineTitle)
    }

    @Test func refreshShowsTheErrorMessageWhenItFails() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(
                .init(fetchedConversations: [.success([.make(id: 1)]), .failure(LocalizedMockError.somethingSpecific)])
            )
        )
        await viewModel.load()

        await viewModel.refresh()

        #expect(viewModel.notice?.message == LocalizedMockError.somethingSpecific.errorDescription)
    }

    @Test func retryLoadsTheConversationsAfterAFailure() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(
                .init(fetchedConversations: [.failure(MockError.failure), .success([.make(id: 1)])])
            )
        )
        await viewModel.load()

        await viewModel.retry()

        #expect(viewModel.state == .loaded([.make(id: 1)]))
    }

    @Test func loadsOnlyOnce() async {
        let provider = MockUnifiedSupportDataProvider(.init(fetchedConversations: [.success([.make(id: 1)])]))
        let viewModel = makeViewModel(provider)

        viewModel.loadIfNeeded()
        viewModel.loadIfNeeded()
        await viewModel.loadingTask?.value

        #expect(provider.conversationsFetchCount == 1)
    }

    @Test func insertsNewConversationsAtTheTop() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(.init(fetchedConversations: [.success([.make(id: 1)])]))
        )
        await viewModel.load()

        viewModel.upsert(.make(id: 2, status: .bot))

        #expect(viewModel.state == .loaded([.make(id: 2, status: .bot), .make(id: 1)]))
    }

    @Test func updatesExistingConversationsInPlace() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(
                .init(fetchedConversations: [.success([.make(id: 1), .make(id: 2, status: .bot)])])
            )
        )
        await viewModel.load()

        viewModel.upsert(.make(id: 2, status: .ongoing))

        #expect(viewModel.state == .loaded([.make(id: 1), .make(id: 2, status: .ongoing)]))
    }

    @Test func showsANewConversationWhenTheListFailedToLoad() async {
        let viewModel = makeViewModel(
            MockUnifiedSupportDataProvider(.init(fetchedConversations: [.failure(MockError.failure)]))
        )
        await viewModel.load()

        viewModel.upsert(.make(id: 1, status: .bot))

        #expect(viewModel.state == .loaded([.make(id: 1, status: .bot)]))
    }

    private func makeViewModel(_ dataProvider: MockUnifiedSupportDataProvider) -> UnifiedSupportListViewModel {
        UnifiedSupportListViewModel(dataProvider: dataProvider, tracker: tracker)
    }
}
