import SwiftUI

/// The unified support conversations list.
///
/// Shows AI bot chats and Happiness Engineer tickets in a single combined list
/// (backed by the `unifiedConversations` endpoint) and routes each row into the
/// matching detail experience, branched on ``UnifiedConversationItem/isBot``:
/// the chat-style bot conversation, or the ticket-style HE conversation.
@MainActor
public struct UnifiedConversationListView: View {

    enum ViewState: Equatable {
        case start
        case loading(Task<Void, Never>)
        case partiallyLoaded([UnifiedConversationItem], Task<Void, Never>)
        case loaded([UnifiedConversationItem])
        case error(String)

        var isPartiallyLoaded: Bool {
            guard case .partiallyLoaded = self else { return false }
            return true
        }
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @State
    private var state: ViewState = .start

    private let currentUser: SupportUser

    public init(currentUser: SupportUser) {
        self.currentUser = currentUser
    }

    public var body: some View {
        Group {
            switch self.state {
            case .start, .loading:
                FullScreenProgressView(Localization.loadingConversations)
            case .partiallyLoaded(let conversations, _), .loaded(let conversations):
                self.conversationsList(conversations)
            case .error(let error):
                FullScreenErrorView(
                    title: Localization.unableToLoadConversations,
                    message: error
                )
            }
        }
        .navigationTitle(Localization.getHelp)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    ConversationView(conversation: nil, currentUser: currentUser)
                        .environmentObject(dataProvider)
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(!currentUser.permissions.contains(.createChatConversation))
            }
        }
        .overlay {
            OverlayProgressView(shouldBeVisible: self.state.isPartiallyLoaded)
        }
        .task(self.loadConversations)
        .refreshable(action: self.reloadConversations)
    }

    @ViewBuilder
    private func conversationsList(_ conversations: [UnifiedConversationItem]) -> some View {
        if case .loaded = self.state, conversations.isEmpty {
            ContentUnavailableView {
                Label(Localization.noConversations, systemImage: "message")
            } description: {
                Text(Localization.startNewConversation)
            }
        } else {
            List {
                ForEach(conversations) { conversation in
                    NavigationLink {
                        destination(for: conversation)
                    } label: {
                        UnifiedConversationRow(conversation: conversation)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .listRowInsets(.zero)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private func destination(for conversation: UnifiedConversationItem) -> some View {
        if conversation.isBot {
            ConversationView(
                conversation: BotConversation(
                    id: conversation.id,
                    title: conversation.displayTitle,
                    createdAt: conversation.lastMessageSentAt,
                    messages: []
                ),
                currentUser: currentUser
            )
            .environmentObject(dataProvider)
        } else {
            SupportConversationView(
                conversation: ConversationSummary(
                    id: conversation.id,
                    title: conversation.displayTitle,
                    description: conversation.description,
                    status: conversation.status,
                    lastMessageSentAt: conversation.lastMessageSentAt
                ),
                currentUser: currentUser
            )
            .environmentObject(dataProvider)
        }
    }

    @Sendable
    private func loadConversations() async {
        guard case .start = self.state else { return }
        self.state = .loading(self.cacheTask)
    }

    @Sendable
    private func reloadConversations() async {
        guard case .loaded(let conversations) = state else { return }
        self.state = .partiallyLoaded(conversations, self.fetchTask)
    }

    private var cacheTask: Task<Void, Never> {
        Task {
            do {
                let fetch = try dataProvider.loadUnifiedConversations()
                if let cachedResults = try await fetch.cachedResult() {
                    self.state = .partiallyLoaded(cachedResults, self.fetchTask)
                }
                let fetchedResults = try await fetch.fetchedResult()
                self.state = .loaded(fetchedResults)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    private var fetchTask: Task<Void, Never> {
        Task {
            do {
                let conversations = try await dataProvider.loadUnifiedConversations().fetchedResult()
                self.state = .loaded(conversations)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }
}

extension UnifiedConversationItem {
    /// A non-empty title for display. Bot conversations can have an empty
    /// server title, so fall back to the (markdown-stripped) description.
    var displayTitle: String {
        title.isEmpty ? plainTextDescription : title
    }
}

// MARK: - Row

struct UnifiedConversationRow: View {

    @Environment(\.sizeCategory)
    private var sizeCategory

    let conversation: UnifiedConversationItem

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                header
                HStack {
                    TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                        Text(formatTimestamp(conversation.lastMessageSentAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .padding(.bottom, 2)

            Text(conversation.plainTextDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    private var header: some View {
        if sizeCategory.isAccessibilityCategory {
            VStack(alignment: .leading) {
                titleText
                badge
            }
        } else {
            HStack {
                titleText
                Spacer()
                badge
            }
        }
    }

    private var titleText: some View {
        Text(conversation.displayTitle)
            .font(.headline)
            .foregroundColor(.primary)
            .lineLimit(sizeCategory.isAccessibilityCategory ? 2 : 1)
    }

    @ViewBuilder
    private var badge: some View {
        if conversation.isBot {
            ChipView(string: Localization.botBadge, color: .blue)
                .controlSize(.mini)
        } else {
            ChipView(string: conversation.status.title, color: conversation.status.color)
                .controlSize(.mini)
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        UnifiedConversationListView(currentUser: SupportDataProvider.supportUser)
    }
    .environmentObject(SupportDataProvider.testing)
}
