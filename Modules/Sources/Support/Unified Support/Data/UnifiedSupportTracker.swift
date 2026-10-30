import Foundation

/// The analytics events of the unified support flow.
public enum UnifiedSupportEvent: Sendable {
    case viewConversationList
    case viewConversation(conversationId: UInt64, isBot: Bool)
    case startBotConversation
    case sendBotMessage(conversationId: UInt64)
    case replyToTicket(conversationId: UInt64, attachmentCount: Int, includesApplicationLogs: Bool)
    case escalateConversation(conversationId: UInt64)
    case failToLoadConversations(any Error)
    case failToLoadConversation(conversationId: UInt64, any Error)
    /// `conversationId` is `nil` when the message was meant to start a new conversation.
    case failToSendMessage(conversationId: UInt64?, isBot: Bool, any Error)
}

public protocol UnifiedSupportTracker: Sendable {
    func track(_ event: UnifiedSupportEvent)
}
