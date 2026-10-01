import Foundation
import Testing
@testable import Support

@MainActor
struct UnifiedSupportConversationViewModelTests {

    private let tracker = SpyUnifiedSupportTracker()

    // MARK: - Loading

    @Test func loadsAnExistingConversation() async {
        let conversation = UnifiedSupportConversation.make(id: 7, messages: [.make(content: "Hello")])
        let viewModel = makeViewModel(
            .existing(conversation.summary),
            MockUnifiedSupportDataProvider(.init(fetchedConversation: .success(conversation)))
        )

        await viewModel.load()

        #expect(viewModel.conversation == conversation)
        #expect(viewModel.messages.map(\.content) == ["Hello"])
        #expect(!viewModel.isLoading)
    }

    @Test func keepsShowingTheSummaryWhenLoadingFails() async {
        let summary = UnifiedSupportConversationSummary.make(id: 7, title: "Title", status: .closed)
        let viewModel = makeViewModel(
            .existing(summary),
            MockUnifiedSupportDataProvider(.init(fetchedConversation: .failure(MockError.failure)))
        )

        await viewModel.load()

        #expect(viewModel.conversation == nil)
        #expect(viewModel.title == "Title")
        #expect(viewModel.status == .closed)
        #expect(viewModel.notice?.message == UnifiedSupportLocalization.genericErrorMessage)
        #expect(tracker.trackedEvents.contains { if case .failToLoadConversation = $0 { true } else { false } })
    }

    @Test func aNewConversationLoadsNothingAndStartsAsAChat() async {
        let provider = MockUnifiedSupportDataProvider()
        let viewModel = makeViewModel(.newBotConversation, provider)

        await viewModel.load()

        #expect(viewModel.isBot)
        #expect(viewModel.conversationId == nil)
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.notice == nil)
    }

    // MARK: - Sending

    @Test func sendsTheMessageToAnExistingConversation() async {
        let conversation = UnifiedSupportConversation.make(id: 7, status: .bot)
        let answered = UnifiedSupportConversation.make(
            id: 7,
            status: .bot,
            messages: [.make(id: 1, content: "Hi", authorRole: .user), .make(id: 2, content: "Hello", authorRole: .bot)]
        )
        let provider = MockUnifiedSupportDataProvider(
            .init(fetchedConversation: .success(conversation), repliedConversation: .success(answered))
        )
        var updatedConversations: [UnifiedSupportConversation] = []
        let viewModel = makeViewModel(.existing(conversation.summary), provider) { updatedConversations.append($0) }
        await viewModel.load()

        viewModel.draft = " Hi "
        viewModel.sendMessage()
        await viewModel.waitForSending()

        #expect(provider.sentMessages.map(\.message) == ["Hi"])
        #expect(provider.sentMessages.map(\.conversationId) == [7])
        #expect(viewModel.conversation == answered)
        #expect(viewModel.draft.isEmpty)
        #expect(!viewModel.isSending)
        #expect(updatedConversations == [answered])
    }

    @Test func createsTheConversationWithTheFirstMessage() async {
        let created = UnifiedSupportConversation.make(id: 42, status: .bot, messages: [.make(content: "Hi")])
        let provider = MockUnifiedSupportDataProvider(.init(createdConversation: .success(created)))
        var updatedConversations: [UnifiedSupportConversation] = []
        let viewModel = makeViewModel(.newBotConversation, provider) { updatedConversations.append($0) }

        viewModel.draft = "Hi"
        viewModel.sendMessage()
        await viewModel.waitForSending()

        #expect(provider.sentMessages.map(\.conversationId) == [nil])
        #expect(viewModel.conversationId == 42)
        #expect(updatedConversations == [created])
    }

    @Test func showsTheMessageWhileItIsBeingSent() async {
        let provider = MockUnifiedSupportDataProvider()
        let viewModel = makeViewModel(.newBotConversation, provider)

        viewModel.draft = "Hi"
        viewModel.sendMessage()

        #expect(viewModel.messages.map(\.content) == ["Hi"])
        #expect(viewModel.messages.first?.authorRole == .user)
        #expect(viewModel.draft.isEmpty)
        #expect(viewModel.isSending)
        #expect(viewModel.isAssistantTyping)

        await viewModel.waitForSending()
    }

    @Test func ignoresBlankMessages() async {
        let provider = MockUnifiedSupportDataProvider()
        let viewModel = makeViewModel(.newBotConversation, provider)

        viewModel.draft = "   "
        viewModel.sendMessage()

        #expect(!viewModel.isSending)
        #expect(provider.sentMessages.isEmpty)
    }

    @Test func sendsOneMessageAtATime() async {
        let created = UnifiedSupportConversation.make(id: 42, status: .bot)
        let provider = MockUnifiedSupportDataProvider(.init(createdConversation: .success(created)))
        let viewModel = makeViewModel(.newBotConversation, provider)

        viewModel.draft = "Hi"
        viewModel.sendMessage()
        viewModel.draft = "Hi again"
        viewModel.sendMessage()
        await viewModel.waitForSending()

        #expect(provider.sentMessages.map(\.message) == ["Hi"])
    }

    @Test func givesTheMessageBackWhenSendingFails() async {
        let provider = MockUnifiedSupportDataProvider(.init(createdConversation: .failure(MockError.failure)))
        let viewModel = makeViewModel(.newBotConversation, provider)

        viewModel.draft = "Hi"
        viewModel.sendMessage()
        await viewModel.waitForSending()

        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.draft == "Hi")
        #expect(viewModel.notice?.message == UnifiedSupportLocalization.genericErrorMessage)
        #expect(tracker.trackedEvents.contains { if case .failToSendMessage = $0 { true } else { false } })
    }

    @Test func givesTheMessageBackWhenSendingIsCancelled() async {
        let provider = MockUnifiedSupportDataProvider(.init(createdConversation: .failure(CancellationError())))
        let viewModel = makeViewModel(.newBotConversation, provider)

        viewModel.draft = "Hi"
        viewModel.sendMessage()
        await viewModel.waitForSending()

        // The message never reached the server, so it can't stay in the conversation looking sent
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.draft == "Hi")
        // Cancelling isn't a failure worth reporting
        #expect(viewModel.notice == nil)
        #expect(tracker.trackedEvents.isEmpty)
    }

    @Test func keepsANewerMessageWhenSendingFails() async {
        let provider = MockUnifiedSupportDataProvider(.init(createdConversation: .failure(MockError.failure)))
        let viewModel = makeViewModel(.newBotConversation, provider)

        viewModel.draft = "Hi"
        viewModel.sendMessage()
        viewModel.draft = "Something else"
        await viewModel.waitForSending()

        #expect(viewModel.draft == "Something else")
    }

    @Test func doesNotSendWhileOffline() async {
        let provider = MockUnifiedSupportDataProvider(.init(isOnline: false))
        let viewModel = makeViewModel(.newBotConversation, provider)

        viewModel.draft = "Hi"
        viewModel.sendMessage()
        await viewModel.waitForSending()

        #expect(provider.sentMessages.isEmpty)
        #expect(viewModel.draft == "Hi")
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.notice?.message == UnifiedSupportLocalization.offlineTitle)
    }

    // MARK: - Escalation

    @Test func turnsIntoATicketWhenTheConversationIsEscalated() async throws {
        let conversation = UnifiedSupportConversation.make(id: 7, status: .bot)
        let escalated = UnifiedSupportConversation.make(
            id: 7,
            status: .ongoing,
            messages: [.make(id: 1, authorRole: .user), .make(id: 2, content: "Transferred", authorRole: .system)]
        )
        let provider = MockUnifiedSupportDataProvider(
            .init(fetchedConversation: .success(conversation), repliedConversation: .success(escalated))
        )
        let viewModel = makeViewModel(.existing(conversation.summary), provider)
        await viewModel.load()
        #expect(viewModel.isBot)

        viewModel.draft = "I want to talk to a human"
        viewModel.sendMessage()
        await viewModel.waitForSending()

        #expect(!viewModel.isBot)
        #expect(viewModel.status == .ongoing)
        #expect(viewModel.replyAction == .reply)
        #expect(tracker.trackedEvents.contains { if case .escalateConversation = $0 { true } else { false } })
    }

    // MARK: - Refreshing silently

    @Test func showsTheAnswersThatArrivedWhileReadingATicket() async {
        let ticket = UnifiedSupportConversation.make(id: 7, status: .ongoing)
        let answered = UnifiedSupportConversation.make(
            id: 7,
            status: .ongoing,
            messages: [.make(id: 1, content: "Hi, I'm Jane", authorRole: .support)]
        )
        let provider = MockUnifiedSupportDataProvider(.init(fetchedConversation: .success(ticket)))
        let viewModel = makeViewModel(.existing(ticket.summary), provider)
        await viewModel.load()

        provider.updateStubs { $0.fetchedConversation = .success(answered) }
        await viewModel.refreshSilently()

        #expect(viewModel.messages.map(\.content) == ["Hi, I'm Jane"])
    }

    /// A chat only changes when the user writes in it, so there is nothing to poll for.
    @Test func doesNotRefreshAChatWithTheAssistant() async {
        let chat = UnifiedSupportConversation.make(id: 7, status: .bot)
        let provider = MockUnifiedSupportDataProvider(.init(fetchedConversation: .success(chat)))
        let viewModel = makeViewModel(.existing(chat.summary), provider)

        await viewModel.refreshSilently()

        #expect(viewModel.conversation == nil)
    }

    @Test func dropsARefreshThatStartedBeforeAReplyWasSent() async {
        let ticket = UnifiedSupportConversation.make(id: 7, status: .ongoing)
        let replied = UnifiedSupportConversation.make(
            id: 7,
            status: .ongoing,
            messages: [.make(id: 2, content: "Any news?", authorRole: .user)]
        )
        let provider = MockUnifiedSupportDataProvider(
            .init(fetchedConversation: .success(ticket), repliedConversation: .success(replied))
        )
        let viewModel = makeViewModel(.existing(ticket.summary), provider)
        await viewModel.load()

        // The reply lands while the refresh is still on its way, so the refresh's older answer must be dropped.
        async let refresh: Void = viewModel.refreshSilently()
        viewModel.replyDraft.message = "Any news?"
        viewModel.sendTicketReply()
        await viewModel.waitForSending()
        await refresh

        #expect(viewModel.messages.map(\.content) == ["Any news?"])
    }

    /// The server can answer a refresh that started after a reply with a snapshot taken before it, and a reply
    /// that disappears reads as a reply that was never sent.
    @Test func keepsTheMessagesAServerSnapshotHasNotCaughtUpWith() async {
        let replied = UnifiedSupportConversation.make(
            id: 7,
            status: .ongoing,
            messages: [.make(id: 1, content: "Any news?", authorRole: .user)]
        )
        let lagging = UnifiedSupportConversation.make(id: 7, status: .ongoing)
        let provider = MockUnifiedSupportDataProvider(.init(fetchedConversation: .success(replied)))
        let viewModel = makeViewModel(.existing(replied.summary), provider)
        await viewModel.load()

        provider.updateStubs { $0.fetchedConversation = .success(lagging) }
        await viewModel.refreshSilently()

        #expect(viewModel.messages.map(\.content) == ["Any news?"])
    }

    /// A refresh that keeps every message and adds one is the answer from support the polling exists for.
    @Test func takesARefreshThatOnlyAddsMessages() async {
        let ticket = UnifiedSupportConversation.make(
            id: 7,
            status: .ongoing,
            messages: [.make(id: 1, content: "Any news?", authorRole: .user)]
        )
        let answered = UnifiedSupportConversation.make(
            id: 7,
            status: .ongoing,
            messages: [
                .make(id: 1, content: "Any news?", authorRole: .user),
                .make(id: 2, content: "Hi, I'm Jane", authorRole: .support)
            ]
        )
        let provider = MockUnifiedSupportDataProvider(.init(fetchedConversation: .success(ticket)))
        let viewModel = makeViewModel(.existing(ticket.summary), provider)
        await viewModel.load()

        provider.updateStubs { $0.fetchedConversation = .success(answered) }
        await viewModel.refreshSilently()

        #expect(viewModel.messages.map(\.content) == ["Any news?", "Hi, I'm Jane"])
    }

    // MARK: - Replying to a ticket

    @Test func sendsTheReplyWithItsAttachmentsAndLogs() async {
        let ticket = UnifiedSupportConversation.make(id: 7, status: .ongoing)
        let provider = MockUnifiedSupportDataProvider(.init(repliedConversation: .success(ticket)))
        let viewModel = makeViewModel(.existing(ticket.summary), provider)
        let file = makeFile(fileSize: 10)

        viewModel.replyDraft = UnifiedSupportReplyDraft(
            message: "  Here is a screenshot  ",
            files: [file],
            includeApplicationLogs: true
        )
        viewModel.sendTicketReply()
        await viewModel.waitForSending()

        #expect(
            provider.sentMessages == [
                SentMessage(
                    conversationId: 7,
                    message: "Here is a screenshot",
                    attachments: [file.url],
                    includesApplicationLogs: true
                )
            ]
        )
    }

    @Test func closesTheFormAndKeepsNothingWhenTheReplyIsSent() async {
        let ticket = UnifiedSupportConversation.make(id: 7, status: .ongoing)
        let provider = MockUnifiedSupportDataProvider(.init(repliedConversation: .success(ticket)))
        let viewModel = makeViewModel(.existing(ticket.summary), provider)

        viewModel.isReplySheetPresented = true
        viewModel.replyDraft.message = "Any news?"
        viewModel.sendTicketReply()
        #expect(!viewModel.isReplySheetPresented)

        await viewModel.waitForSending()

        #expect(viewModel.replyDraft == UnifiedSupportReplyDraft())
        #expect(viewModel.notice?.message == UnifiedSupportLocalization.replySent)
        #expect(viewModel.replyFailure == nil)
    }

    @Test func keepsTheReplyWhenSendingFails() async {
        let ticket = UnifiedSupportConversation.make(id: 7, status: .ongoing)
        let provider = MockUnifiedSupportDataProvider(.init(repliedConversation: .failure(MockError.failure)))
        let viewModel = makeViewModel(.existing(ticket.summary), provider)
        let draft = UnifiedSupportReplyDraft(message: "Any news?", files: [makeFile(fileSize: 10)])

        viewModel.replyDraft = draft
        viewModel.sendTicketReply()
        await viewModel.waitForSending()

        #expect(viewModel.replyDraft == draft)
        #expect(viewModel.replyFailure?.message == UnifiedSupportLocalization.genericErrorMessage)
        #expect(viewModel.messages.isEmpty)
        #expect(tracker.trackedEvents.contains { if case .failToSendMessage = $0 { true } else { false } })
    }

    @Test func keepsTheReplyWhenTheDeviceIsOffline() async {
        let ticket = UnifiedSupportConversation.make(id: 7, status: .ongoing)
        let provider = MockUnifiedSupportDataProvider(.init(isOnline: false))
        let viewModel = makeViewModel(.existing(ticket.summary), provider)

        viewModel.replyDraft.message = "Any news?"
        viewModel.sendTicketReply()
        await viewModel.waitForSending()

        #expect(provider.sentMessages.isEmpty)
        #expect(viewModel.replyDraft.message == "Any news?")
        #expect(viewModel.replyFailure?.message == UnifiedSupportLocalization.offlineTitle)
        #expect(!viewModel.isSending)
    }

    @Test func leavesOutTheAttachmentsThatDoNotFit() async {
        let ticket = UnifiedSupportConversation.make(id: 7, status: .ongoing)
        let provider = MockUnifiedSupportDataProvider(.init(repliedConversation: .success(ticket)))
        let viewModel = makeViewModel(.existing(ticket.summary), provider)
        let fitting = makeFile(fileSize: viewModel.maximumUploadSize)
        let tooLarge = makeFile(fileSize: 1)

        viewModel.replyDraft = UnifiedSupportReplyDraft(message: "Screenshots", files: [fitting, tooLarge])
        viewModel.sendTicketReply()
        await viewModel.waitForSending()

        #expect(provider.sentMessages.map(\.attachments) == [[fitting.url]])
    }

    @Test func doesNotSendABlankReply() async {
        let ticket = UnifiedSupportConversation.make(id: 7, status: .ongoing)
        let provider = MockUnifiedSupportDataProvider(.init(repliedConversation: .success(ticket)))
        let viewModel = makeViewModel(.existing(ticket.summary), provider)

        viewModel.replyDraft.message = "   "
        viewModel.sendTicketReply()
        await viewModel.waitForSending()

        #expect(!viewModel.canSendReply)
        #expect(provider.sentMessages.isEmpty)
    }

    @Test func tracksTheReplyWithWhatItCarries() async throws {
        let ticket = UnifiedSupportConversation.make(id: 7, status: .ongoing)
        let provider = MockUnifiedSupportDataProvider(.init(repliedConversation: .success(ticket)))
        let viewModel = makeViewModel(.existing(ticket.summary), provider)

        viewModel.replyDraft = UnifiedSupportReplyDraft(
            message: "Any news?",
            files: [makeFile(fileSize: 10)],
            includeApplicationLogs: true
        )
        viewModel.sendTicketReply()
        await viewModel.waitForSending()

        let event = try #require(
            tracker.trackedEvents.first { if case .replyToTicket = $0 { true } else { false } }
        )
        guard case .replyToTicket(let conversationId, let attachmentCount, let includesLogs) = event else {
            Issue.record("Unexpected event: \(event)")
            return
        }
        #expect(conversationId == 7)
        #expect(attachmentCount == 1)
        #expect(includesLogs)
    }

    // MARK: - Tracking

    @Test func tracksOpeningAnExistingConversation() throws {
        let summary = UnifiedSupportConversationSummary.make(id: 7, status: .ongoing)
        let viewModel = makeViewModel(.existing(summary), MockUnifiedSupportDataProvider())

        viewModel.onAppear()

        let event = try #require(tracker.trackedEvents.first)
        guard case .viewConversation(let conversationId, let isBot) = event else {
            Issue.record("Unexpected event: \(event)")
            return
        }
        #expect(conversationId == 7)
        #expect(!isBot)
    }

    @Test func tracksStartingANewConversation() throws {
        let viewModel = makeViewModel(.newBotConversation, MockUnifiedSupportDataProvider())

        viewModel.onAppear()

        let event = try #require(tracker.trackedEvents.first)
        guard case .startBotConversation = event else {
            Issue.record("Unexpected event: \(event)")
            return
        }
    }

    // MARK: - Helpers

    private func makeFile(fileSize: UInt64) -> UnifiedSupportPickedFile {
        UnifiedSupportPickedFile(url: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).png"), fileSize: fileSize)
    }

    private func makeViewModel(
        _ source: UnifiedSupportConversationViewModel.Source,
        _ dataProvider: MockUnifiedSupportDataProvider,
        onConversationUpdated: @escaping (UnifiedSupportConversation) -> Void = { _ in }
    ) -> UnifiedSupportConversationViewModel {
        UnifiedSupportConversationViewModel(
            source: source,
            dataProvider: dataProvider,
            tracker: tracker,
            currentUser: SupportUser(userId: 1, username: "Tester", email: "tester@example.com"),
            onConversationUpdated: onConversationUpdated
        )
    }
}
