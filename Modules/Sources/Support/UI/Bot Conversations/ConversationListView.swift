import SwiftUI

public struct ConversationListView: View {

    enum ViewState {
        case loading
        case partiallyLoaded([BotConversation])
        case loaded([BotConversation], ViewSubstate?)
        case loadingConversationsError(Error)

        var conversations: [BotConversation]? {
            return switch self {
            case .partiallyLoaded(let conversations): conversations
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

    enum ViewSubstate {
        case deletingConversations(Task<Void, Never>)
        case deletingConversationsError(Error)
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @State
    var state: ViewState = .loading

    @State
    var selectedConversations = Set<String>()

    private let currentUser: SupportUser

    public init(currentUser: SupportUser) {
        self.currentUser = currentUser
    }

    public var body: some View {
        VStack {
            switch self.state {
            case .loading:
                ProgressView("Loading Bot Conversations")
            case .partiallyLoaded(let conversations): self.conversationList(conversations)
            case .loaded(let conversations, _): self.conversationList(conversations)
            case .loadingConversationsError(let error):
                ErrorView(
                    title: "Unable to load conversations",
                    message: error.localizedDescription
                )
            }
        }
        .navigationTitle("Conversations")
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
                Label("No Conversations", systemImage: "message")
            } description: {
                Text("Start a new conversation using the button above")
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
        do {
            let fetch = try await dataProvider.loadConversations()

            if let cachedConversations = try await fetch.cachedResult() {
                await MainActor.run {
                    self.state = .partiallyLoaded(cachedConversations)
                }
            }

            let fetchedConversations = try await fetch.fetchedResult()

            await MainActor.run {
                self.state = .loaded(fetchedConversations, .none)
            }

        } catch {
            debugPrint("🚩 Load conversations error: \(error.localizedDescription)")
            await MainActor.run {
                self.state = .loadingConversationsError(error)
            }
        }
    }

    private func reloadConversations() async {
        do {
            let conversationList = try await self.dataProvider.loadConversations().fetchedResult()
            await MainActor.run {
                self.state = .loaded(conversationList, .none)
            }
        } catch {
            await MainActor.run {
                self.state = .loadingConversationsError(error)
            }
        }
    }

    private func deleteConversations(at indexSet: IndexSet) {
        guard let conversationIds = self.state.conversations?.map({ $0.id }) else {
            return
        }

        self.state = self.state.addSubstate(.deletingConversations(Task {
            do {
                try await self.dataProvider.delete(conversationIds: conversationIds)
                await MainActor.run {
                    self.state = self.state.clearSubstate()
                }
            }
            catch {
                await MainActor.run {
                    self.state = self.state.updateSubstate(.deletingConversationsError(error))
                }
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
                .font(.headline)

            if let lastMessage = conversation.messages.last {
                Text(lastMessage.text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text(lastMessage.formattedTime)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("No messages")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {

    NavigationStack {
        ConversationListView(
            currentUser: SupportDataProvider.supportUser
        )
        ConversationView(
            conversation: SupportDataProvider.botConversation,
            currentUser: SupportDataProvider.supportUser
        )
    }
    .environmentObject(SupportDataProvider.testing)
}
