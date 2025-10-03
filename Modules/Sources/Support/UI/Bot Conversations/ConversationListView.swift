import SwiftUI

public struct ConversationListView: View {

    enum ViewState {
        case loadingConversations
        case loadingConversationsError(Error)
        case ready
        case deletingConversations(Task<Void, Never>)
        case deletingConversationsError(Error)
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @State
    var conversations: [BotConversation] = []

    @State
    var state: ViewState = .loadingConversations

    @State
    var selectedConversations = Set<String>()

    @State
    private var deletionTask: Task<Void, Error>? = nil

    private let currentUser: SupportUser

    public init(currentUser: SupportUser) {
        self.currentUser = currentUser
    }

    public var body: some View {
        List(selection: $selectedConversations) {

            if case .loadingConversationsError(let error) = self.state {
                ErrorView(
                    title: "Unable to load conversations",
                    message: error.localizedDescription
                )
            }

            ForEach(self.conversations) { conversation in
                NavigationLink(destination: ConversationView(
                    conversation: conversation,
                    currentUser: currentUser
                ).environmentObject(dataProvider)) {
                    ConversationRow(conversation: conversation)
                }
            }
            .onDelete { indexSet in
                self.deleteConversations(at: indexSet)
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
            }
        }
        .overlay {
            if case .ready = state, self.conversations.isEmpty {
                ContentUnavailableView {
                    Label("No Conversations", systemImage: "message")
                } description: {
                    Text("Start a new conversation using the button above")
                }
            }
        }
        .refreshable {
            await self.reloadConversations()
        }
        .task {
            await self.reloadConversations()
        }
    }

    private func reloadConversations() async {
        self.state = .loadingConversations

        do {
            self.conversations = try await self.dataProvider.loadConversations()
            self.state = .ready
        } catch {
            self.state = .loadingConversationsError(error)
        }
    }

    private func deleteConversations(at indexSet: IndexSet) {
        let conversationIds = indexSet.map { conversations[$0].id }

        self.state = .deletingConversations(Task {
            do {
                try await self.dataProvider.delete(conversationIds: conversationIds)
                self.state = .ready
            }
            catch {
                self.state = .deletingConversationsError(error)
            }
        })
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

    NavigationView {
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
