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

    /// The conversations that changed while the list was off screen.
    private var updatedConversations: [UnifiedSupportConversation] = []

    init(dataProvider: any UnifiedSupportDataProvider, tracker: any UnifiedSupportTracker) {
        self.dataProvider = dataProvider
        self.tracker = tracker
    }

    /// Shows the conversations the user created or replied to since the last time the list was on screen.
    func onAppear() {
        tracker.track(.viewConversationList)
        applyUpdatedConversations()
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

    /// Takes note of a conversation the user created or replied to, to show it when the list comes back on screen.
    ///
    /// The list isn't updated right away on purpose: adding the first conversation replaces the empty state with the
    /// list, and the empty state owns the link to the conversation the user is writing in, so SwiftUI closes it.
    func upsert(_ conversation: UnifiedSupportConversation) {
        updatedConversations.removeAll { $0.id == conversation.id }
        updatedConversations.append(conversation)
    }

    /// Adds the new conversations at the top of the list, and updates the ones already in it in place.
    private func applyUpdatedConversations() {
        guard !updatedConversations.isEmpty else {
            return
        }

        var conversations: [UnifiedSupportConversationSummary]
        if case .loaded(let loadedConversations) = state {
            conversations = loadedConversations
        } else {
            conversations = []
        }

        for summary in updatedConversations.map(\.summary) {
            if let index = conversations.firstIndex(where: { $0.id == summary.id }) {
                conversations[index] = summary
            } else {
                conversations.insert(summary, at: 0)
            }
        }

        updatedConversations = []
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
