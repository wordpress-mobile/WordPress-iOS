import Foundation

@MainActor
final class UnifiedSupportListViewModel: ObservableObject {

    enum State {
        case loading
        case loaded([UnifiedSupportConversationSummary])
        case offline
        case failed(any Error)
    }

    @Published private(set) var state: State = .loading

    /// Whether cached conversations are shown while the latest ones are fetched.
    @Published private(set) var isUpdatingCachedConversations = false

    @Published var notice: UnifiedSupportNotice?

    private let dataProvider: any UnifiedSupportDataProvider
    private let tracker: any UnifiedSupportTracker
    private(set) var loadingTask: Task<Void, Never>?

    init(dataProvider: any UnifiedSupportDataProvider, tracker: any UnifiedSupportTracker) {
        self.dataProvider = dataProvider
        self.tracker = tracker
    }

    func onAppear() {
        tracker.track(.viewConversationList)
    }

    /// Loads the conversations the first time the list appears.
    ///
    /// The loading isn't tied to the view's lifecycle, so it isn't cancelled when the user opens a conversation.
    func loadIfNeeded() {
        guard loadingTask == nil else {
            return
        }
        loadingTask = Task {
            await load()
        }
    }

    /// Shows the cached conversations, if any, while the latest ones are fetched.
    func load() async {
        state = .loading

        do {
            let result = try dataProvider.loadConversations()

            // A cache that can't be read is a cache miss
            if let cachedConversations = try? await result.cachedResult() {
                state = .loaded(cachedConversations)
                isUpdatingCachedConversations = true
            }

            let conversations = try await result.fetchedResult()
            isUpdatingCachedConversations = false
            state = .loaded(conversations)
        } catch {
            isUpdatingCachedConversations = false
            handleLoadingError(error)
        }
    }

    /// Fetches the latest conversations, keeping the current ones if that fails.
    func refresh() async {
        do {
            let conversations = try await dataProvider.loadConversations().fetchedResult()
            state = .loaded(conversations)
        } catch {
            handleLoadingError(error)
        }
    }

    func retry() async {
        state = .loading
        await refresh()
    }

    /// Adds a new conversation at the top of the list, or updates an existing one in place.
    func upsert(_ conversation: UnifiedSupportConversation) {
        let summary = conversation.summary

        guard case .loaded(var conversations) = state else {
            state = .loaded([summary])
            return
        }

        if let index = conversations.firstIndex(where: { $0.id == summary.id }) {
            conversations[index] = summary
        } else {
            conversations.insert(summary, at: 0)
        }
        state = .loaded(conversations)
    }

    private func handleLoadingError(_ error: any Error) {
        // Leaving the screen during pull to refresh cancels the request, which isn't an error for the user
        guard !Task.isCancelled, !error.isUnifiedSupportCancellation else {
            return
        }

        tracker.track(.failToLoadConversations(error))

        let isOffline = (error as? UnifiedSupportError) == .offline || !dataProvider.isOnline()

        if case .loaded = state {
            notice = UnifiedSupportNotice(
                message: isOffline ? UnifiedSupportLocalization.offlineTitle : error.unifiedSupportMessage
            )
        } else {
            state = isOffline ? .offline : .failed(error)
        }
    }
}
