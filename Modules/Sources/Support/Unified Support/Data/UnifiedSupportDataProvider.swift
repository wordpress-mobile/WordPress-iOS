import Foundation
import WordPressCoreProtocols

/// Provides the conversations of the unified support flow.
///
/// A conversation starts with the AI Assistant. The server can escalate it to a Happiness Engineer at any point, which
/// turns it into a ticket while keeping its ID.
public protocol UnifiedSupportDataProvider: Actor {

    /// The maximum total size of the files attached to a reply, in bytes.
    nonisolated var maximumUploadSize: UInt64 { get }

    /// Whether the device currently has a network connection.
    nonisolated func isOnline() -> Bool

    /// Loads the summaries of the user's conversations, most recently updated first.
    nonisolated func loadConversations() throws -> any CachedAndFetchedResult<[UnifiedSupportConversationSummary]>

    /// Fetches a conversation with all its messages.
    func fetchConversation(id: UInt64) async throws -> UnifiedSupportConversation

    /// Starts a new conversation with the AI Assistant.
    func createBotConversation(message: String) async throws -> UnifiedSupportConversation

    /// Replies to an existing conversation and returns the updated conversation.
    ///
    /// The server sends the reply to the AI Assistant or to the linked ticket. The returned conversation can be
    /// escalated to a Happiness Engineer as a result of the reply.
    func reply(
        toConversation id: UInt64,
        message: String,
        attachments: [URL],
        includeApplicationLogs: Bool
    ) async throws -> UnifiedSupportConversation
}

public enum UnifiedSupportError: Error, LocalizedError {
    /// The device has no network connection.
    case offline
    /// The user isn't logged in to WordPress.com.
    case notLoggedIn

    public var errorDescription: String? {
        switch self {
        case .offline: UnifiedSupportLocalization.offlineTitle
        case .notLoggedIn: UnifiedSupportLocalization.notLoggedInMessage
        }
    }
}
