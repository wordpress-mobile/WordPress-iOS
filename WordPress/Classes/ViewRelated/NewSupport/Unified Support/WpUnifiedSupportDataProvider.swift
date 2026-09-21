import Foundation
import Support
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressCoreProtocols
import WordPressData
import WordPressShared

/// Provides the unified support conversations from WordPress.com.
///
/// Conversations are listed, fetched, and replied to through the unified conversations endpoints. Only a new
/// conversation is created through the AI Assistant endpoint. Every later message goes through the unified reply
/// endpoint, which is where the server escalates conversations to Happiness Engineers.
actor WpUnifiedSupportDataProvider: UnifiedSupportDataProvider {

    /// The AI Assistant that answers new conversations.
    static let botId = "jetpack-workflow-chat_mobile_support"

    let maximumUploadSize: UInt64 = 20 * 1024 * 1024

    private let client: WordPressDotComClient
    private let coreDataStack: CoreDataStack

    init(client: WordPressDotComClient, coreDataStack: CoreDataStack = ContextManager.shared) {
        self.client = client
        self.coreDataStack = coreDataStack
    }

    nonisolated func isOnline() -> Bool {
        ReachabilityUtils.isInternetReachable()
    }

    nonisolated func loadConversations() throws -> any CachedAndFetchedResult<[UnifiedSupportConversationSummary]> {
        let userId = try currentUserId()
        let client = self.client

        return DiskCachedAndFetchedResult(
            fetchedResult: {
                try await Self.performRequest {
                    try await client.api.unifiedConversations
                        .getUnifiedConversationList()
                        .data
                        .map { $0.asUnifiedSupportConversationSummary() }
                }
            },
            // Scoped to the user, so a different account never sees these conversations.
            cacheKey: "unified-support-conversations-\(userId)"
        )
    }

    func fetchConversation(id: UInt64) async throws -> UnifiedSupportConversation {
        try await Self.performRequest {
            try await client.api.unifiedConversations
                .getUnifiedConversation(conversationId: id)
                .data
                .asUnifiedSupportConversation()
        }
    }

    func createBotConversation(message: String) async throws -> UnifiedSupportConversation {
        let userId = try currentUserId()
        let params = CreateBotConversationParams(message: message, userId: userId)
        let createdConversation = try await Self.performRequest {
            try await client.api.supportBots
                .createBotConversation(botId: Self.botId, params: params)
                .data
        }

        // Fetch the conversation to get the same messages as when it's opened later, including the sources of the
        // answer. The conversation exists at this point, so a failure must not fail the send: the user would send
        // the message again and start a duplicate conversation.
        do {
            return try await fetchConversation(id: createdConversation.chatId)
        } catch {
            Loggers.app.warning("Failed to fetch the new support conversation: \(error)")
            return createdConversation.asUnifiedSupportConversation(sentMessage: message)
        }
    }

    func reply(
        toConversation id: UInt64,
        message: String,
        attachments: [URL],
        includeApplicationLogs: Bool
    ) async throws -> UnifiedSupportConversation {
        // TODO: Upload the application logs and send their IDs when `includeApplicationLogs` is `true`.
        let params = ReplyToUnifiedConversationParams(
            message: message,
            // wordpress-rs reads the files from disk, so it needs file system paths without percent-encoding.
            attachments: attachments.map { $0.path(percentEncoded: false) }
        )

        return try await Self.performRequest {
            try await client.api.unifiedConversations
                .replyToUnifiedConversation(conversationId: id, params: params)
                .data
                .asUnifiedSupportConversation()
        }
    }

    private nonisolated func currentUserId() throws -> Int64 {
        let userId = coreDataStack.performQuery { context in
            (try? WPAccount.lookupDefaultWordPressComAccount(in: context))?.userID?.int64Value
        }
        guard let userId else {
            throw UnifiedSupportError.notLoggedIn
        }
        return userId
    }

    /// Translates the transport errors the `Support` module knows about, since it doesn't depend on wordpress-rs.
    private static func performRequest<T>(_ request: () async throws -> T) async throws -> T {
        do {
            return try await request()
        } catch let error as WpApiError {
            if error.isCancellationError {
                throw CancellationError()
            }
            if case .RequestExecutionFailed(_, _, .deviceIsOfflineError, _, _) = error {
                throw UnifiedSupportError.offline
            }
            throw error
        }
    }
}
