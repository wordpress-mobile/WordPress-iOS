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
    private(set) var silentRefreshTask: Task<Void, Never>?

    /// The conversations that changed while the list was off screen.
    private var updatedConversations: [UnifiedSupportConversation] = []

    /// The conversations the user started here, which the list endpoint can take a while to report.
    private var locallyAddedConversations: [UInt64: UnifiedSupportConversationSummary] = [:]

    /// Whether a fetch the user can see is running, so a silent refresh doesn't get in its way.
    private var isFetching = false

    private var isRefreshingSilently = false

    init(dataProvider: any UnifiedSupportDataProvider, tracker: any UnifiedSupportTracker) {
        self.dataProvider = dataProvider
        self.tracker = tracker
    }

    /// Shows the conversations the user created or replied to since the last time the list was on screen, and picks
    /// up what changed on the server meanwhile.
    func onAppear() {
        tracker.track(.viewConversationList)
        applyUpdatedConversations()

        // The first appearance is followed by `loadIfNeeded()`, which fetches the conversations anyway.
        guard loadingTask != nil else {
            return
        }
        silentRefreshTask = Task {
            await refreshSilently()
        }
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
        isFetching = true
        defer { isFetching = false }

        do {
            let result = try dataProvider.loadConversations()

            // A cache that can't be read is a cache miss
            if let cachedConversations = try? await result.cachedResult() {
                state = .loaded(cachedConversations)
                isUpdatingCachedConversations = true
            }

            let conversations = try await result.fetchedResult()
            isUpdatingCachedConversations = false
            show(conversations)
        } catch {
            isUpdatingCachedConversations = false
            handleLoadingError(error)
        }
    }

    /// Fetches the latest conversations, keeping the current ones if that fails.
    func refresh() async {
        isFetching = true
        defer { isFetching = false }

        do {
            show(try await dataProvider.loadConversations().fetchedResult())
        } catch {
            handleLoadingError(error)
        }
    }

    func retry() async {
        state = .loading
        await refresh()
    }

    /// Fetches the latest conversations without showing that it's happening.
    ///
    /// Nothing is reported when it fails: the user didn't ask for it, and the conversations already on screen stay
    /// as they are.
    func refreshSilently() async {
        guard !isFetching, !isRefreshingSilently, dataProvider.isOnline() else {
            return
        }
        isRefreshingSilently = true
        defer { isRefreshingSilently = false }

        guard let conversations = try? await dataProvider.loadConversations().fetchedResult() else {
            return
        }

        // A load the user can see may have started in the meantime, and its result is the newer one.
        guard !isFetching else {
            return
        }
        show(conversations)
    }

    /// Shows the conversations the server sent, with whatever it hasn't caught up with yet.
    ///
    /// A conversation the user just wrote in is known here before the list endpoint reports it. It can be missing
    /// from the list altogether, or listed from a snapshot taken before the reply — an escalated chat still shown
    /// as a chat, say. Either way the row the user was just shown would go back the way it was, which reads as the
    /// reply having been lost.
    private func show(_ conversations: [UnifiedSupportConversationSummary]) {
        var listed = conversations
        var missing: [UnifiedSupportConversationSummary] = []

        for local in locallyAddedConversations.values.sorted(by: { $0.updatedAt > $1.updatedAt }) {
            guard let index = listed.firstIndex(where: { $0.id == local.id }) else {
                missing.append(local)
                continue
            }

            // The server lists it now, so from the next answer on it's the one that knows better: holding on any
            // longer would keep a ticket the support team has closed meanwhile looking like it's still open.
            locallyAddedConversations[local.id] = nil

            if listed[index].updatedAt <= local.updatedAt {
                listed[index] = local
            }
        }

        state = .loaded(missing + listed)
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
            locallyAddedConversations[summary.id] = summary

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
