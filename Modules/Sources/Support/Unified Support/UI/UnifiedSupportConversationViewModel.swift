import Foundation

@MainActor
final class UnifiedSupportConversationViewModel: ObservableObject {

    enum Source {
        case existing(UnifiedSupportConversationSummary)
        /// A conversation that only exists on the server once its first message is sent.
        case newBotConversation
    }

    @Published private(set) var conversation: UnifiedSupportConversation?
    @Published private(set) var isLoading = false
    @Published private(set) var isSending = false

    /// Messages the user sent that the server hasn't confirmed yet.
    @Published private(set) var pendingMessages: [UnifiedSupportMessage] = []

    @Published var draft = ""
    @Published var notice: UnifiedSupportNotice?

    let currentUser: SupportUser

    private let summary: UnifiedSupportConversationSummary?
    private let dataProvider: any UnifiedSupportDataProvider
    private let tracker: any UnifiedSupportTracker
    private let onConversationUpdated: (UnifiedSupportConversation) -> Void
    private var loadingTask: Task<Void, Never>?
    private(set) var sendingTask: Task<Void, Never>?

    init(
        source: Source,
        dataProvider: any UnifiedSupportDataProvider,
        tracker: any UnifiedSupportTracker,
        currentUser: SupportUser,
        onConversationUpdated: @escaping (UnifiedSupportConversation) -> Void = { _ in }
    ) {
        switch source {
        case .existing(let summary):
            self.summary = summary
        case .newBotConversation:
            self.summary = nil
        }
        self.dataProvider = dataProvider
        self.tracker = tracker
        self.currentUser = currentUser
        self.onConversationUpdated = onConversationUpdated
    }

    /// The conversation's server ID, or `nil` until a new conversation is created by its first message.
    var conversationId: UInt64? {
        conversation?.id ?? summary?.id
    }

    /// A conversation is a chat with the AI Assistant until the server escalates it to the support team.
    var isBot: Bool {
        conversation?.isBot ?? summary?.isBot ?? true
    }

    var title: String {
        conversation?.title ?? summary?.displayTitle ?? ""
    }

    var status: UnifiedSupportConversationStatus {
        conversation?.status ?? summary?.status ?? .bot
    }

    var canAcceptReply: Bool {
        conversation?.canAcceptReply ?? summary?.canAcceptReply ?? true
    }

    var lastActivityAt: Date {
        conversation?.lastActivityAt ?? summary?.updatedAt ?? .now
    }

    var replyAction: UnifiedSupportReplyAction {
        conversation?.replyAction ?? .addMoreInfo
    }

    var messages: [UnifiedSupportMessage] {
        (conversation?.messages ?? []) + pendingMessages
    }

    var isAssistantTyping: Bool {
        isBot && isSending
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending && !isLoading
    }

    func onAppear() {
        if let conversationId {
            tracker.track(.viewConversation(conversationId: conversationId, isBot: isBot))
        } else {
            tracker.track(.startBotConversation)
        }
    }

    /// Loads the messages of an existing conversation.
    ///
    /// The loading isn't tied to the view's lifecycle, so it isn't cancelled when the app leaves the screen.
    func loadIfNeeded() {
        guard loadingTask == nil, conversationId != nil else {
            return
        }
        loadingTask = Task {
            await load()
        }
    }

    func load() async {
        guard let conversationId else {
            return
        }

        isLoading = true
        do {
            conversation = try await dataProvider.fetchConversation(id: conversationId)
        } catch {
            handleFailure(error) {
                self.tracker.track(.failToLoadConversation(conversationId: conversationId, error))
            }
        }
        isLoading = false
    }

    /// Sends the message being written, and shows it as sent while the server answers.
    func sendMessage() {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)

        // The flag is set before any asynchronous work, so a double tap can't send the message twice.
        guard !message.isEmpty, !isSending else {
            return
        }
        isSending = true

        guard dataProvider.isOnline() else {
            isSending = false
            notice = UnifiedSupportNotice(message: UnifiedSupportLocalization.offlineTitle)
            return
        }

        let pendingMessage = UnifiedSupportMessage(
            id: .pending(UUID()),
            content: message,
            authorRole: .user,
            authorName: currentUser.username,
            createdAt: .now
        )
        pendingMessages.append(pendingMessage)
        draft = ""

        let conversationId = self.conversationId
        let wasBot = isBot

        sendingTask = Task {
            do {
                let updated: UnifiedSupportConversation
                if let conversationId {
                    updated = try await dataProvider.reply(
                        toConversation: conversationId,
                        message: message,
                        attachments: [],
                        includeApplicationLogs: false
                    )
                } else {
                    updated = try await dataProvider.createBotConversation(message: message)
                }
                handleSentMessage(updated, wasBot: wasBot)
            } catch {
                handleSendingError(error, message: message, pendingMessageId: pendingMessage.id, wasBot: wasBot)
            }
            isSending = false
        }
    }

    private func handleSentMessage(_ updated: UnifiedSupportConversation, wasBot: Bool) {
        // The server answers with the whole conversation, including the message that was just sent.
        conversation = updated
        pendingMessages.removeAll()

        tracker.track(.sendBotMessage(conversationId: updated.id))
        if wasBot && !updated.isBot {
            tracker.track(.escalateConversation(conversationId: updated.id))
        }

        onConversationUpdated(updated)
    }

    private func handleSendingError(
        _ error: any Error,
        message: String,
        pendingMessageId: UnifiedSupportMessage.ID,
        wasBot: Bool
    ) {
        // The message never reached the server, so take it out of the conversation whatever went wrong.
        pendingMessages.removeAll { $0.id == pendingMessageId }

        // Give the message back, unless the user started writing another one in the meantime.
        if draft.isEmpty {
            draft = message
        }

        handleFailure(error) {
            self.tracker.track(
                .failToSendMessage(conversationId: self.conversationId, isBot: wasBot, error)
            )
        }
    }

    /// Reports a failure to the user, unless the request was cancelled by leaving the screen.
    private func handleFailure(_ error: any Error, then report: () -> Void) {
        guard !Task.isCancelled, !error.isUnifiedSupportCancellation else {
            return
        }

        report()

        let isOffline = (error as? UnifiedSupportError) == .offline || !dataProvider.isOnline()
        notice = UnifiedSupportNotice(
            message: isOffline ? UnifiedSupportLocalization.offlineTitle : error.unifiedSupportMessage
        )
    }
}
