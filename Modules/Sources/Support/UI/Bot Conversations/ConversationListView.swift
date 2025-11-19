import SwiftUI

public struct ConversationListView: View {

    enum ViewState: Equatable {
        case start
        case loading(Task<Void, Never>)
        case partiallyLoaded([BotConversation], fetchTask: Task<Void, Never>)
        case loaded([BotConversation], ViewSubstate?)
        case loadingConversationsError(String)

        var conversations: [BotConversation]? {
            return switch self {
            case .partiallyLoaded(let conversations, _): conversations
            case .loaded(let conversations, _): conversations
            default: nil
            }
        }

        var canDeleteConversations: Bool {
            switch self {
            case .loaded: true
            default: false
            }
        }

        func addSubstate(_ newValue: ViewSubstate) -> Self {
            guard case .loaded(let conversations, let oldValue) = self else {
                preconditionFailure("You cannot transition to a substate unless the current state is `loaded`")
            }

            guard case .none = oldValue else {
                preconditionFailure("You cannot add a substate – one already exists")
            }

            return .loaded(conversations, newValue)
        }

        func updateSubstate(_ newValue: ViewSubstate) -> Self {
            guard case .loaded(let conversations, let oldValue) = self else {
                preconditionFailure("You cannot transition to a substate unless the current state is `loaded`")
            }

            guard oldValue != nil else {
                preconditionFailure("You cannot update to a new substate – none exists")
            }

            return .loaded(conversations, newValue)
        }

        func clearSubstate() -> Self {
            guard case .loaded(let conversations, let oldValue) = self else {
                preconditionFailure("You cannot clear substate unless the current state is `loaded`")
            }

            guard oldValue != nil else {
                preconditionFailure("You cannot clear substate – none exists")
            }

            return .loaded(conversations, nil)
        }

        var isPartiallyLoaded: Bool {
            guard case .partiallyLoaded = self else {
                return false
            }

            return true
        }
    }

    enum ViewSubstate: Equatable {
        case deletingConversations(Task<Void, Never>)
        case deletingConversationsError(String)
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @State
    var state: ViewState = .start

    @State
    var selectedConversations = Set<String>()

    private let currentUser: SupportUser

    public init(currentUser: SupportUser) {
        self.currentUser = currentUser
    }

    public var body: some View {
        VStack {
            switch self.state {
            case .start, .loading:
                FullScreenProgressView(Localization.loadingBotConversations)
            case .partiallyLoaded(let conversations, _), .loaded(let conversations, _):
                self.conversationList(conversations)
            case .loadingConversationsError(let error):
                FullScreenErrorView(
                    title: Localization.unableToLoadConversations,
                    message: error
                )
            }
        }
        .navigationTitle(Localization.conversations)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    ConversationView(
                        conversation: nil,
                        currentUser: currentUser
                    ).environmentObject(dataProvider)
                }
                label: {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(!currentUser.permissions.contains(.createChatConversation))
            }
        }
        .overlay {
            OverlayProgressView(shouldBeVisible: state.isPartiallyLoaded)
        }
        .onAppear {
            self.dataProvider.userDid(.viewSupportBotConversationList)
        }
        .task(self.loadConversations)
        .refreshable(action: self.reloadConversations)
    }

    @ViewBuilder
    private func conversationList(_ conversations: [BotConversation]) -> some View {
        if case .loaded = self.state, conversations.isEmpty {
            ContentUnavailableView {
                Label(Localization.noConversations, systemImage: "message")
            } description: {
                Text(Localization.startNewConversation)
            }
        } else {
            List(conversations) { conversation in
                NavigationLink(destination: ConversationView(
                    conversation: conversation,
                    currentUser: currentUser
                ).environmentObject(dataProvider)) {
                    ConversationRow(conversation: conversation)
                }
            }
        }
    }

    private func loadConversations() async {
        guard case .start = state else {
            return
        }

        self.state = .loading(self.cacheTask)
    }

    private func reloadConversations() async {
        guard case .loaded(let conversations, _) = state else {
            return
        }

        self.state = .partiallyLoaded(conversations, fetchTask: self.fetchTask)
    }

    private var cacheTask: Task<Void, Never> {
        Task {
            do {
                if let cachedResult = try await dataProvider.loadConversations().cachedResult() {
                    self.state = .partiallyLoaded(cachedResult, fetchTask: self.fetchTask)
                } else {
                    await self.fetchTask.value
                }
            } catch {
                self.state = .loadingConversationsError(error.localizedDescription)
            }
        }
    }

    private var fetchTask: Task<Void, Never> {
        Task {
            do {
                let fetchedConversations = try await dataProvider.loadConversations().fetchedResult()
                self.state = .loaded(fetchedConversations, .none)
            } catch {
                self.state = .loadingConversationsError(error.localizedDescription)
            }
        }
    }

    @MainActor
    private func deleteConversations(at indexSet: IndexSet) {
        guard let conversationIds = self.state.conversations?.map({ $0.id }) else {
            return
        }

        self.state = self.state.addSubstate(.deletingConversations(Task {
            do {
                try await self.dataProvider.delete(conversationIds: conversationIds)
                self.state = self.state.clearSubstate()
            }
            catch {
                self.state = self.state.updateSubstate(
                    .deletingConversationsError(error.localizedDescription)
                )
            }
        }))
    }
}

// MARK: - ConversationRow
struct ConversationRow: View {
    let conversation: BotConversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.body)
                .padding(.bottom, 4)

            Text(conversation.formattedCreationDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {

    NavigationStack {
        ConversationListView(
            currentUser: SupportDataProvider.supportUser
        )
    }
    .environmentObject(SupportDataProvider.testing)
}
