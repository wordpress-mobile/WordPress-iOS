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

    /// The reply being written to the support team, kept while the form is closed.
    @Published var replyDraft = UnifiedSupportReplyDraft()

    @Published var isReplySheetPresented = false

    /// A reply that couldn't be sent. Its draft is kept, so the user can open the form again and send it.
    @Published var replyFailure: UnifiedSupportNotice?

    let currentUser: SupportUser

    private let summary: UnifiedSupportConversationSummary?
    private let dataProvider: any UnifiedSupportDataProvider
    private let tracker: any UnifiedSupportTracker
    private let onConversationUpdated: (UnifiedSupportConversation) -> Void
    private var loadingTask: Task<Void, Never>?
    private(set) var sendingTask: Task<Void, Never>?

    /// Counts the messages sent from this screen, so a refresh that started before one of them can't put the
    /// conversation back the way it was before it.
    private var mutationCount = 0

    private var isRefreshingSilently = false

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

    var canSendReply: Bool {
        replyDraft.canSend && !isSending
    }

    /// The maximum total size of the files that can be sent with a reply, in bytes.
    var maximumUploadSize: UInt64 {
        dataProvider.maximumUploadSize
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
            handleFailure(error, then: .failToLoadConversation(conversationId: conversationId, error))
        }
        isLoading = false
    }

    /// Fetches the conversation again without showing that it's happening, so answers from the support team show up
    /// while the user is reading.
    ///
    /// Only tickets are refreshed: a chat with the AI Assistant only changes when the user writes in it.
    func refreshSilently() async {
        guard
            !isBot,
            let conversationId,
            !isSending,
            !isLoading,
            !isRefreshingSilently,
            dataProvider.isOnline()
        else {
            return
        }
        isRefreshingSilently = true
        defer { isRefreshingSilently = false }

        let mutationCountAtStart = mutationCount
        guard let updated = try? await dataProvider.fetchConversation(id: conversationId) else {
            // The user didn't ask for this, so a failure isn't worth a message.
            return
        }

        // A message sent while this was on its way has already replaced the conversation with a newer one.
        guard mutationCountAtStart == mutationCount, !isSending, updated.id == self.conversationId else {
            return
        }
        conversation = updated
    }

    /// Sends the message being written in the chat, and shows it as sent while the AI Assistant answers.
    func sendMessage() {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, beginSending() else {
            return
        }

        guard dataProvider.isOnline() else {
            isSending = false
            notice = UnifiedSupportNotice(message: UnifiedSupportLocalization.offlineTitle)
            return
        }

        draft = ""
        let wasBot = isBot

        send(message: message) { [weak self] updated in
            self?.tracker.track(.sendBotMessage(conversationId: updated.id))
        } onFailure: { [weak self] error in
            guard let self else {
                return
            }

            // Give the message back, unless the user started writing another one in the meantime.
            if draft.isEmpty {
                draft = message
            }

            report(error, as: .failToSendMessage(conversationId: conversationId, isBot: wasBot, error)) { message in
                self.notice = UnifiedSupportNotice(message: message)
            }
        }
    }

    /// Sends the reply written in the form, which closes as soon as the sending starts.
    ///
    /// The draft is only thrown away once the server has the reply, so nothing the user wrote or attached is lost
    /// when the sending fails.
    func sendTicketReply() {
        let reply = replyDraft
        let message = reply.message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, beginSending() else {
            return
        }
        isReplySheetPresented = false

        guard dataProvider.isOnline() else {
            isSending = false
            replyFailure = UnifiedSupportNotice(message: UnifiedSupportLocalization.offlineTitle)
            return
        }

        // Files that don't fit in the upload limit are left behind, as the form warned.
        let attachments = UnifiedSupportAttachmentValidator(maximumUploadSize: dataProvider.maximumUploadSize)
            .validate(reply.files)
            .accepted
        let wasBot = isBot

        send(
            message: message,
            attachments: attachments.map(\.url),
            includeApplicationLogs: reply.includeApplicationLogs
        ) { [weak self] updated in
            guard let self else {
                return
            }

            tracker.track(
                .replyToTicket(
                    conversationId: updated.id,
                    attachmentCount: attachments.count,
                    includesApplicationLogs: reply.includeApplicationLogs
                )
            )
            discardReplyDraft()
            notice = UnifiedSupportNotice(message: UnifiedSupportLocalization.replySent)
        } onFailure: { [weak self] error in
            guard let self else {
                return
            }

            report(error, as: .failToSendMessage(conversationId: conversationId, isBot: wasBot, error)) { message in
                self.replyFailure = UnifiedSupportNotice(message: message)
            }
        }
    }

    /// Throws the reply away, with the files picked for it.
    func discardReplyDraft() {
        UnifiedSupportAttachmentStorage.delete(replyDraft.files)
        replyDraft = UnifiedSupportReplyDraft()
    }

    /// Marks a message as being sent, unless one already is.
    ///
    /// The flag is set before any asynchronous work, so a double tap can't send the same message twice.
    private func beginSending() -> Bool {
        guard !isSending else {
            return false
        }
        isSending = true
        mutationCount += 1
        return true
    }

    /// Sends a message to the server, showing it in the conversation while it's on its way.
    ///
    /// The message is taken out of the conversation again when it doesn't reach the server.
    private func send(
        message: String,
        attachments: [URL] = [],
        includeApplicationLogs: Bool = false,
        onSuccess: @escaping (UnifiedSupportConversation) -> Void,
        onFailure: @escaping (any Error) -> Void
    ) {
        let pendingMessage = UnifiedSupportMessage(
            id: .pending(UUID()),
            content: message,
            authorRole: .user,
            authorName: currentUser.username,
            createdAt: .now
        )
        pendingMessages.append(pendingMessage)

        let conversationId = self.conversationId
        let wasBot = isBot

        sendingTask = Task {
            do {
                let updated: UnifiedSupportConversation
                if let conversationId {
                    updated = try await dataProvider.reply(
                        toConversation: conversationId,
                        message: message,
                        attachments: attachments,
                        includeApplicationLogs: includeApplicationLogs
                    )
                } else {
                    updated = try await dataProvider.createBotConversation(message: message)
                }
                handleSentMessage(updated, wasBot: wasBot)
                onSuccess(updated)
            } catch {
                pendingMessages.removeAll { $0.id == pendingMessage.id }
                onFailure(error)
            }
            isSending = false
        }
    }

    private func handleSentMessage(_ updated: UnifiedSupportConversation, wasBot: Bool) {
        // The server answers with the whole conversation, including the message that was just sent.
        conversation = updated
        pendingMessages.removeAll()

        if wasBot && !updated.isBot {
            tracker.track(.escalateConversation(conversationId: updated.id))
        }

        onConversationUpdated(updated)
    }

    /// Reports a failure to the user, unless the request was cancelled by leaving the screen.
    private func handleFailure(_ error: any Error, then event: @autoclosure () -> UnifiedSupportEvent) {
        report(error, as: event()) { message in
            self.notice = UnifiedSupportNotice(message: message)
        }
    }

    /// Tracks a failure and hands its message to the caller, unless the request was cancelled by leaving the screen.
    private func report(
        _ error: any Error,
        as event: @autoclosure () -> UnifiedSupportEvent,
        show: (String) -> Void
    ) {
        guard !Task.isCancelled, !error.isUnifiedSupportCancellation else {
            return
        }

        tracker.track(event())

        // Being offline is by far the most common failure, and its own message is clearer than the server's.
        let isOffline = (error as? UnifiedSupportError) == .offline || !dataProvider.isOnline()
        show(isOffline ? UnifiedSupportLocalization.offlineTitle : error.unifiedSupportMessage)
    }
}
