import SwiftUI
import AsyncImageKit

public struct SupportConversationView: View {

    enum ViewState: Equatable {
        case start
        case loading(cacheLoadTask: Task<Void, Never>)
        case partiallyLoaded(Conversation, fetchTask: Task<Void, Never>)
        case loaded(Conversation)
        case error(String)

        var isPartiallyLoaded: Bool {
            guard case .partiallyLoaded = self else {
                return false
            }

            return true
        }

        var conversation: Conversation? {
            switch self {
            case .start: nil
            case .loading: nil
            case .partiallyLoaded(let conversation, _): conversation
            case .loaded(let conversation): conversation
            case .error: nil
            }
        }

        var canAcceptReply: Bool {
            conversation?.canAcceptReply ?? false
        }
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @State
    private var state: ViewState = .start

    @State
    private var isReplying: Bool = false

    @Namespace
    var bottom

    private let conversationSummary: ConversationSummary

    private let currentUser: SupportUser

    private var canReply: Bool {
        // Don't enable the new conversation button if the user isn't eligible for it
        guard currentUser.permissions.contains(.createSupportRequest) else {
            return false
        }

        // Only allow replying once the conversation is fully loaded
        guard case .loaded(let conversation) = state else {
            return false
        }

        return conversation.canAcceptReply
    }

    public init(
        conversation: ConversationSummary,
        currentUser: SupportUser
    ) {
        self.currentUser = currentUser
        self.conversationSummary = conversation
    }

    public var body: some View {
        VStack(spacing: 0) {
            switch self.state {
            case .start, .loading:
                FullScreenProgressView(Localization.loadingMessages)
            case .partiallyLoaded(let conversation, _), .loaded(let conversation):
                self.conversationView(conversation)
            case .error(let error):
                FullScreenErrorView(
                    title: Localization.unableToDisplayConversation,
                    message: error
                )
            }
        }
        .task(self.loadConversation)
        .navigationTitle(self.conversationSummary.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if self.state.canAcceptReply {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        self.isReplying = true
                    } label: {
                        Image(systemName: "arrowshape.turn.up.left")
                    }
                    .disabled(!canReply)
                }
            }
        }
        .overlay {
            OverlayProgressView(shouldBeVisible: self.state.isPartiallyLoaded)
        }
        .sheet(isPresented: $isReplying) {
            if case .loaded(let conversation) = state {
                NavigationStack {
                    SupportConversationReplyView(
                        conversation: conversation,
                        currentUser: currentUser,
                        conversationDidUpdate: { conversation in
                            withAnimation {
                                self.state = .partiallyLoaded(conversation, fetchTask: self.fetchTask)
                            }
                        }
                    )
                }
                .environmentObject(dataProvider)
            }
        }
        .onAppear {
            self.dataProvider.userDid(.viewSupportTicket(ticketId: conversationSummary.id))
        }
    }

    @ViewBuilder
    private func conversationView(_ conversation: Conversation) -> some View {
        // Conversation header
        conversationHeader(conversation)

        Divider()

        // Messages list
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(conversation.messages, id: \.id) { message in
                        MessageRowView(
                            message: message
                        )
                    }

                    if conversation.canAcceptReply {
                        Button {
                            self.isReplying = true
                        } label: {
                            Spacer()
                            HStack(alignment: .firstTextBaseline) {
                                Image(systemName: "arrowshape.turn.up.left")
                                Text(Localization.reply)
                            }.padding(.vertical, 8)
                            Spacer()
                        }
                        .padding()
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(!canReply)
                    } else {
                        Text(Localization.conversationEnded)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .padding(.top)
                    }

                    Divider()
                        .opacity(0)
                        .id(self.bottom)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: conversation.messages.count) {
                scrollToBottom(proxy: proxy)
            }
            .refreshable(action: self.reloadConversation)
        }
    }

    @ViewBuilder
    private func conversationHeader(_ conversation: Conversation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ChipView(
                    string: conversation.status.title,
                    color: conversation.status.color
                ).controlSize(.small)

                Spacer()

                HStack(spacing: 0) {
                    Text(lastUpdatedString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }

    @MainActor
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard case .loaded = state else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(self.bottom, anchor: .bottom)
        }
    }

    private func messageCountString(_ conversation: Conversation) -> String {
        return String(format: Localization.messagesCount, conversation.messages.count)
    }

    private var lastUpdatedString: String {
        let timestamp = formatTimestamp(conversationSummary.lastMessageSentAt)
        return String(format: Localization.lastUpdated, timestamp)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    @MainActor
    private func loadConversation() async {
        guard case .start = state else {
            return
        }

        self.state = .loading(cacheLoadTask: self.cacheTask)
    }

    @MainActor
    private func reloadConversation() async {
        guard case .loaded(let conversation) = state else {
            return
        }

        self.state = .partiallyLoaded(conversation, fetchTask: fetchTask)
    }

    private var cacheTask: Task<Void, Never> {
        Task {
            do {
                let id = self.conversationSummary.id
                if let conversation = try await self.dataProvider.loadSupportConversation(id: id).cachedResult() {
                    self.state = .partiallyLoaded(conversation, fetchTask: self.fetchTask)
                } else {
                    await self.fetchTask.value
                }
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    private var fetchTask: Task<Void, Never> {
        Task {
            do {
                let id = self.conversationSummary.id
                let conversation = try await self.dataProvider.loadSupportConversation(id: id).fetchedResult()
                self.state = .loaded(conversation)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }
}

struct MessageRowView: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(message.authorName)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(message.authorIsUser ? .accentColor : .secondary)

                        Spacer()

                        Text(message.createdAt, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }.padding(.bottom)

                    // Message content
                    Text(message.attributedContent)
                        .font(.body)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)

                    // Attachments (if any)
                    if !message.attachments.isEmpty {
                        AttachmentListView(attachments: message.attachments)
                    }
                }
                .padding()
                .background(
                    message.authorIsUser ? Color.accentColor.opacity(0.10) :
                        Color(UIColor.systemGray5))
            }
        }
        .id(message.id)
    }
}

#Preview {
    NavigationStack {
        SupportConversationView(
            conversation: SupportDataProvider.supportConversationSummaries.first!,
            currentUser: SupportDataProvider.supportUser
        )
    }
    .environmentObject(SupportDataProvider.testing)
}
