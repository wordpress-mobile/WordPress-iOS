import Foundation
import Testing
import Support
import WordPressAPIInternal
@testable import WordPress

struct UnifiedSupportMappingTests {

    private let createdAt = Date(timeIntervalSince1970: 1_000)
    private let updatedAt = Date(timeIntervalSince1970: 2_000)

    @Test func mapsConversationSummary() {
        let summary = UnifiedConversationSummary(
            id: 42,
            title: "Title",
            description: "Description",
            status: "open",
            canAcceptReply: true,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        .asUnifiedSupportConversationSummary()

        #expect(summary.id == 42)
        #expect(summary.title == "Title")
        #expect(summary.description == "Description")
        #expect(summary.status == .ongoing)
        #expect(summary.canAcceptReply)
        #expect(summary.createdAt == createdAt)
        #expect(summary.updatedAt == updatedAt)
    }

    @Test func mapsConversationWithMessages() {
        let conversation = UnifiedConversation(
            id: 42,
            title: "Title",
            description: "Description",
            status: "closed",
            canAcceptReply: false,
            createdAt: createdAt,
            updatedAt: updatedAt,
            messages: [
                makeMessage(id: 1, text: "I need help", authorRole: "user"),
                makeMessage(id: 2, text: "Transferred to human support", authorRole: "system"),
                makeMessage(id: 3, text: "Hi, I'm here to help", authorRole: "support", authorName: "Jane")
            ]
        )
        .asUnifiedSupportConversation()

        #expect(conversation.id == 42)
        #expect(conversation.status == .closed)
        #expect(!conversation.canAcceptReply)
        #expect(conversation.messages.map(\.id) == [.remote(1), .remote(2), .remote(3)])
        #expect(
            conversation.messages.map(\.content) == [
                "I need help", "Transferred to human support", "Hi, I'm here to help"
            ]
        )
        #expect(conversation.messages.map(\.authorRole) == [.user, .system, .support])
        #expect(conversation.messages.last?.authorName == "Jane")
    }

    @Test func mapsAttachment() throws {
        let attachment = try #require(
            makeAttachment(url: "https://public-api.wordpress.com/wpcom/v2/mobile-support/attachments/abc")
                .asUnifiedSupportAttachment()
        )

        #expect(attachment.id == 7)
        #expect(attachment.filename == "screenshot.png")
        #expect(attachment.contentType == "image/png")
        #expect(attachment.fileSize == 48_213)
        #expect(
            attachment.url == URL(string: "https://public-api.wordpress.com/wpcom/v2/mobile-support/attachments/abc")
        )
        #expect(attachment.matchScore == nil)
    }

    @Test func dropsAttachmentWithInvalidURL() {
        #expect(makeAttachment(url: "").asUnifiedSupportAttachment() == nil)
    }

    @Test(arguments: [
        (JsonValue.float(0.27), Double?.some(0.27)),
        (.int(1), 1),
        (.string("high"), nil)
    ])
    func readsMatchScoreFromMetadata(score: JsonValue, expected: Double?) {
        let attachment = makeAttachment(metadata: ["score": score]).asUnifiedSupportAttachment()

        #expect(attachment?.matchScore == expected)
    }

    @Test func mapsCreatedBotConversation() {
        let conversation = makeBotConversation(messages: [
            makeBotMessage(id: 1, content: "How do I change my site title?", role: "user"),
            makeBotMessage(id: 2, content: "Go to Settings → General.", role: "bot", createdAt: updatedAt)
        ])
        .asUnifiedSupportConversation(sentMessage: "How do I change my site title?")

        #expect(conversation.id == 5_365_939)
        #expect(conversation.title == "How do I change my site title?")
        #expect(conversation.description == "How do I change my site title?")
        #expect(conversation.status == .bot)
        #expect(conversation.canAcceptReply)
        #expect(conversation.updatedAt == updatedAt)
        #expect(conversation.messages.map(\.id) == [.remote(1), .remote(2)])
        #expect(conversation.messages.map(\.authorRole) == [.user, .bot])
    }

    @Test func addsTheSentMessageWhenTheCreatedBotConversationDoesNotIncludeIt() {
        let conversation = makeBotConversation(messages: [
            makeBotMessage(id: 2, content: "Go to Settings → General.", role: "bot")
        ])
        .asUnifiedSupportConversation(sentMessage: "How do I change my site title?")

        #expect(conversation.messages.map(\.content) == ["How do I change my site title?", "Go to Settings → General."])
        #expect(conversation.messages.map(\.authorRole) == [.user, .bot])
    }

    // MARK: - Helpers

    private func makeMessage(
        id: UInt64,
        text: String,
        authorRole: String,
        authorName: String = "Author"
    ) -> UnifiedMessage {
        UnifiedMessage(
            id: id,
            message: text,
            authorRole: authorRole,
            authorName: authorName,
            createdAt: createdAt,
            attachments: []
        )
    }

    private func makeAttachment(
        url: String = "https://example.com/file",
        metadata: [String: JsonValue] = [:]
    ) -> UnifiedAttachment {
        UnifiedAttachment(
            id: 7,
            filename: "screenshot.png",
            contentType: "image/png",
            size: 48_213,
            url: url,
            metadata: metadata
        )
    }

    private func makeBotConversation(
        messages: [WordPressAPIInternal.BotMessage]
    ) -> WordPressAPIInternal.BotConversation {
        WordPressAPIInternal.BotConversation(
            chatId: 5_365_939,
            wpcomUserId: 158_350_866,
            externalId: nil,
            externalIdProvider: nil,
            sessionId: "session",
            botSlug: WpUnifiedSupportDataProvider.botId,
            botVersion: "1.1.0",
            createdAt: createdAt,
            zendeskTicketId: nil,
            messages: messages
        )
    }

    private func makeBotMessage(
        id: UInt64,
        content: String,
        role: String,
        createdAt: Date? = nil
    ) -> WordPressAPIInternal.BotMessage {
        WordPressAPIInternal.BotMessage(
            messageId: id,
            content: content,
            role: role,
            createdAt: createdAt ?? self.createdAt,
            // The mapping only relies on the role
            context: .bot(BotMessageContext(sources: [], flags: [:]))
        )
    }
}
