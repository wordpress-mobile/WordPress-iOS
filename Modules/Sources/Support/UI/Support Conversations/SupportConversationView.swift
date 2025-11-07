import SwiftUI

public struct SupportConversationView: View {

    enum ViewState {
        case loading
        case partiallyLoaded(Conversation)
        case loaded(Conversation)
        case error(Error)

        var isPartiallyLoaded: Bool {
            guard case .partiallyLoaded = self else {
                return false
            }

            return true
        }
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @State
    private var state: ViewState

    @State
    private var isReplying: Bool = false

    private let conversationSummary: ConversationSummary

    private let currentUser: SupportUser

    private var canReply: Bool {
        // Don't enable the new conversation button if the user isn't eligible for it
        guard currentUser.permissions.contains(.createSupportRequest) else {
            return false
        }

        if case .loaded = state {
            return true
        }

        return false
    }

    public init(
        conversation: ConversationSummary,
        currentUser: SupportUser
    ) {
        self.state = .loading
        self.currentUser = currentUser
        self.conversationSummary = conversation
    }

    public var body: some View {
        VStack(spacing: 0) {
            switch self.state {
            case .loading:
                ProgressView(Localization.loadingMessages)
            case .partiallyLoaded(let conversation):
                self.conversationView(conversation)
            case .loaded(let conversation):
                self.conversationView(conversation)
            case .error(let error):
                ErrorView(
                    title: Localization.unableToDisplayConversation,
                    message: error.localizedDescription
                )
            }
        }
        .navigationTitle(self.conversationSummary.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    self.isReplying = true
                } label: {
                    Image(systemName: "arrowshape.turn.up.left")
                }
                .disabled(!canReply)
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
                                self.state = .loaded(conversation)
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
        .task(self.loadConversation)
        .refreshable(action: self.reloadConversation)
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
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: conversation.messages.count) {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func conversationHeader(_ conversation: Conversation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(
                    messageCountString(conversation),
                    systemImage: "bubble.left.and.bubble.right"
                )
                .font(.caption)
                .foregroundColor(.secondary)

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

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard case .loaded(let conversation) = state else {
            return
        }

        if let lastMessage = conversation.messages.last {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
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

    private func loadConversation() async {
        do {
            let conversationId = self.conversationSummary.id

            let fetch = try self.dataProvider.loadSupportConversation(id: conversationId)

            if let cached = try await fetch.cachedResult() {
                await MainActor.run {
                    self.state = .partiallyLoaded(cached)
                }
            }

            let conversation = try await fetch.fetchedResult()
            await MainActor.run {
                self.state = .loaded(conversation)
            }
        } catch {
            self.state = .error(error)
        }
    }

    private func reloadConversation() async {
        guard case .loaded(let conversation) = state else {
            return
        }

        do {
            await MainActor.run {
                self.state = .partiallyLoaded(conversation)
            }

            let conversation = try await self.dataProvider.loadSupportConversation(id: conversation.id).fetchedResult()

            self.state = .loaded(conversation)
        } catch {
            await MainActor.run {
                self.state = .error(error)
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

struct AttachmentListView: View {
    let attachments: [Attachment]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(attachments, id: \.id) { attachment in
                HStack {
                    Image(systemName: "paperclip")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: Localization.attachment, attachment.id))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(Localization.view) {
                        // Handle attachment viewing
                    }
                    .font(.caption)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 4)
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
