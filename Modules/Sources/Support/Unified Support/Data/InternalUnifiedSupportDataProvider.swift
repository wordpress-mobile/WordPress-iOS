import Foundation
import WordPressCoreProtocols

// This file is all module-internal and provides sample data for SwiftUI previews.

extension UnifiedSupportContext {
    static let testing = UnifiedSupportContext(
        dataProvider: InternalUnifiedSupportDataProvider(),
        tracker: InternalUnifiedSupportTracker(),
        mediaHost: InternalMediaHost()
    )

    static func testing(dataProvider: InternalUnifiedSupportDataProvider) -> UnifiedSupportContext {
        UnifiedSupportContext(
            dataProvider: dataProvider,
            tracker: InternalUnifiedSupportTracker(),
            mediaHost: InternalMediaHost()
        )
    }
}

struct InternalUnifiedSupportTracker: UnifiedSupportTracker {
    func track(_ event: UnifiedSupportEvent) {
        // Previews don't track events
    }
}

/// A data provider that simulates the server with sample conversations.
///
/// Mentioning "human" in a reply to an AI Assistant conversation escalates it to a Happiness Engineer.
actor InternalUnifiedSupportDataProvider: UnifiedSupportDataProvider {

    let maximumUploadSize: UInt64 = 20 * 1024 * 1024

    private var conversations: [UnifiedSupportConversation]
    private let loadingError: (any Error)?
    private let responseDelay: Duration

    init(
        conversations: [UnifiedSupportConversation] = UnifiedSupportConversation.previewConversations,
        loadingError: (any Error)? = nil,
        responseDelay: Duration = .seconds(1)
    ) {
        self.conversations = conversations
        self.loadingError = loadingError
        self.responseDelay = responseDelay
    }

    nonisolated func isOnline() -> Bool {
        true
    }

    nonisolated func loadConversations() throws -> any CachedAndFetchedResult<[UnifiedSupportConversationSummary]> {
        UncachedResult {
            try await self.summaries()
        }
    }

    func fetchConversation(id: UInt64) async throws -> UnifiedSupportConversation {
        try await Task.sleep(for: responseDelay)
        return try conversation(withId: id)
    }

    func createBotConversation(message: String) async throws -> UnifiedSupportConversation {
        try await Task.sleep(for: responseDelay)

        let now = Date()
        let conversation = UnifiedSupportConversation(
            id: (conversations.map(\.id).max() ?? 0) + 1,
            title: message,
            description: message,
            status: .bot,
            canAcceptReply: true,
            createdAt: now,
            updatedAt: now,
            messages: [
                .preview(content: message, authorRole: .user, createdAt: now),
                .preview(content: Self.botAnswer, authorRole: .bot, createdAt: now)
            ]
        )
        conversations.insert(conversation, at: 0)
        return conversation
    }

    func reply(
        toConversation id: UInt64,
        message: String,
        attachments: [URL],
        includeApplicationLogs: Bool
    ) async throws -> UnifiedSupportConversation {
        try await Task.sleep(for: responseDelay)

        let conversation = try conversation(withId: id)
        let now = Date()
        var status = conversation.status
        var messages = conversation.messages + [.preview(content: message, authorRole: .user, createdAt: now)]

        if conversation.isBot {
            if message.localizedCaseInsensitiveContains("human") {
                status = .ongoing
                messages += [
                    .preview(content: "I'll connect you with a Happiness Engineer.", authorRole: .bot, createdAt: now),
                    .preview(content: "Transferred to human support", authorRole: .system, createdAt: now)
                ]
            } else {
                messages.append(.preview(content: Self.botAnswer, authorRole: .bot, createdAt: now))
            }
        }

        let updated = UnifiedSupportConversation(
            id: conversation.id,
            title: conversation.title,
            description: conversation.description,
            status: status,
            canAcceptReply: conversation.canAcceptReply,
            createdAt: conversation.createdAt,
            updatedAt: now,
            messages: messages
        )
        conversations.removeAll { $0.id == id }
        conversations.insert(updated, at: 0)
        return updated
    }

    private func summaries() async throws -> [UnifiedSupportConversationSummary] {
        try await Task.sleep(for: responseDelay)
        if let loadingError {
            throw loadingError
        }
        return conversations.map(\.summary)
    }

    private func conversation(withId id: UInt64) throws -> UnifiedSupportConversation {
        guard let conversation = conversations.first(where: { $0.id == id }) else {
            throw URLError(.fileDoesNotExist)
        }
        return conversation
    }

    private static let botAnswer = """
        Great question! You can find step-by-step instructions in our **support guides**. \
        Let me know if there's anything else I can help you with.
        """
}

extension UnifiedSupportConversation {

    static let previewConversations: [UnifiedSupportConversation] = [
        previewEscalatedConversation,
        previewBotConversation,
        previewSolvedConversation,
        previewClosedConversation
    ]

    static let previewBotConversation = UnifiedSupportConversation(
        id: 5_365_939,
        title: "How can I move a self-hosted site to WordPress.com?",
        description: "How can I move a self-hosted site to WordPress.com?",
        status: .bot,
        canAcceptReply: true,
        createdAt: Date(timeIntervalSinceNow: -3 * 3_600),
        updatedAt: Date(timeIntervalSinceNow: -3 * 3_600),
        messages: [
            .preview(
                content: "How can I move a self-hosted site to WordPress.com?",
                authorRole: .user,
                createdAt: Date(timeIntervalSinceNow: -3 * 3_600)
            ),
            .preview(
                content: """
                    You can import your site with the **Jetpack VaultPress Backup** migration tool:

                    1. Install Jetpack on your self-hosted site.
                    2. Go to *Tools → Import* on WordPress.com.
                    3. Follow the steps to copy your content.
                    """,
                authorRole: .bot,
                createdAt: Date(timeIntervalSinceNow: -3 * 3_600 + 10),
                attachments: [
                    .previewLink(id: 1, title: "Import Subscribers", score: 0.82),
                    .previewLink(id: 2, title: "Migrate your site with Jetpack VaultPress Backup", score: 0.64)
                ]
            )
        ]
    )

    static let previewEscalatedConversation = UnifiedSupportConversation(
        id: 4_396_575,
        title: "Would it be possible to chat with a human about this?",
        description: "Would it be possible to chat with a human about this?",
        status: .ongoing,
        canAcceptReply: true,
        createdAt: Date(timeIntervalSinceNow: -2 * 86_400),
        updatedAt: Date(timeIntervalSinceNow: -2 * 86_400 + 60),
        messages: [
            .preview(
                content: "Would it be possible to chat with a human about this?",
                authorRole: .user,
                createdAt: Date(timeIntervalSinceNow: -2 * 86_400)
            ),
            .preview(
                content: "Of course! I'm forwarding your question to our Happiness Engineers.",
                authorRole: .bot,
                createdAt: Date(timeIntervalSinceNow: -2 * 86_400 + 60)
            ),
            .preview(
                content: "Transferred to human support",
                authorRole: .system,
                createdAt: Date(timeIntervalSinceNow: -86_400)
            ),
            .preview(
                content: "Hi! I'm here to help. Could you share a screenshot of the error?",
                authorRole: .support,
                authorName: "Jane (Happiness Engineer)",
                createdAt: Date(timeIntervalSinceNow: -86_400),
                attachments: [
                    UnifiedSupportAttachment(
                        id: 3,
                        filename: "screenshot.png",
                        contentType: "image/png",
                        fileSize: 48_213,
                        url: URL(
                            string: "https://public-api.wordpress.com/wpcom/v2/mobile-support/attachments/preview"
                        )!
                    )
                ]
            )
        ]
    )

    static let previewSolvedConversation = UnifiedSupportConversation(
        id: 11_121_776,
        title: "Custom domain not working",
        description: "My custom domain stopped pointing to my site after I renewed it.",
        status: .solved,
        canAcceptReply: true,
        createdAt: Date(timeIntervalSinceNow: -10 * 86_400),
        updatedAt: Date(timeIntervalSinceNow: -9 * 86_400),
        messages: []
    )

    static let previewClosedConversation = UnifiedSupportConversation(
        id: 11_121_001,
        title: "Billing question",
        description: "I was charged twice for my plan renewal.",
        status: .closed,
        canAcceptReply: false,
        createdAt: Date(timeIntervalSinceNow: -60 * 86_400),
        updatedAt: Date(timeIntervalSinceNow: -45 * 86_400),
        messages: []
    )
}

private extension UnifiedSupportMessage {
    static func preview(
        content: String,
        authorRole: AuthorRole,
        authorName: String = "",
        createdAt: Date,
        attachments: [UnifiedSupportAttachment] = []
    ) -> UnifiedSupportMessage {
        UnifiedSupportMessage(
            id: .remote(UInt64.random(in: 1 ... .max)),
            content: content,
            authorRole: authorRole,
            authorName: authorName,
            createdAt: createdAt,
            attachments: attachments
        )
    }
}

private extension UnifiedSupportAttachment {
    static func previewLink(id: UInt64, title: String, score: Double) -> UnifiedSupportAttachment {
        UnifiedSupportAttachment(
            id: id,
            filename: title,
            contentType: "text/html",
            fileSize: 0,
            url: URL(string: "https://jetpack.com/support/")!,
            matchScore: score
        )
    }
}
