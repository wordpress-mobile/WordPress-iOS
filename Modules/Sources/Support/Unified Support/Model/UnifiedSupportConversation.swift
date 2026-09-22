import Foundation
import SwiftUI

/// The status of a unified support conversation.
///
/// A conversation starts as an AI Assistant chat (`bot`). When the server escalates it to a Happiness Engineer, it
/// takes the status of the linked Zendesk ticket.
public enum UnifiedSupportConversationStatus: String, Sendable, Codable, Hashable {
    case bot
    case ongoing
    case solved
    case closed
    case unknown

    public init(serverValue: String) {
        switch serverValue.lowercased() {
        case "bot": self = .bot
        // Zendesk's internal ticket states are deliberately collapsed into a single status for users.
        case "new", "open", "hold", "pending": self = .ongoing
        case "solved": self = .solved
        case "closed": self = .closed
        default: self = .unknown
        }
    }

    var title: String {
        switch self {
        case .bot: UnifiedSupportLocalization.statusAIAssistant
        case .ongoing: UnifiedSupportLocalization.statusOngoing
        case .solved: UnifiedSupportLocalization.statusSolved
        case .closed: UnifiedSupportLocalization.statusClosed
        case .unknown: UnifiedSupportLocalization.statusUnknown
        }
    }

    var color: Color {
        switch self {
        case .bot: .purple
        case .ongoing: .blue
        case .solved: .green
        case .closed: .gray
        case .unknown: .orange
        }
    }
}

/// A conversation in the conversations list, without its messages.
public struct UnifiedSupportConversationSummary: Identifiable, Hashable, Sendable, Codable {
    public let id: UInt64
    public let title: String
    public let description: String
    public let status: UnifiedSupportConversationStatus
    public let canAcceptReply: Bool
    public let createdAt: Date
    public let updatedAt: Date

    /// The `description` with any markdown formatting stripped out.
    public let plainTextDescription: String

    public init(
        id: UInt64,
        title: String,
        description: String,
        status: UnifiedSupportConversationStatus,
        canAcceptReply: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.canAcceptReply = canAcceptReply
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.plainTextDescription = NSAttributedString(convertMarkdownTextToAttributedString(description)).string
    }

    var isBot: Bool {
        status == .bot
    }

    /// The title to display, falling back to the description when the title is blank.
    var displayTitle: String {
        title.isBlank ? plainTextDescription : title
    }

    /// The description to display under the title, or `nil` when the title or the description is blank.
    var displayDescription: String? {
        guard !title.isBlank, !plainTextDescription.isBlank else {
            return nil
        }
        return plainTextDescription
    }
}

/// A conversation with all its messages.
public struct UnifiedSupportConversation: Identifiable, Sendable, Equatable {
    public let id: UInt64
    public let title: String
    public let description: String
    public let status: UnifiedSupportConversationStatus
    public let canAcceptReply: Bool
    public let createdAt: Date
    public let updatedAt: Date
    public let messages: [UnifiedSupportMessage]

    public init(
        id: UInt64,
        title: String,
        description: String,
        status: UnifiedSupportConversationStatus,
        canAcceptReply: Bool,
        createdAt: Date,
        updatedAt: Date,
        messages: [UnifiedSupportMessage]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.canAcceptReply = canAcceptReply
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }

    var isBot: Bool {
        status == .bot
    }

    /// The conversation as it appears in the conversations list.
    var summary: UnifiedSupportConversationSummary {
        UnifiedSupportConversationSummary(
            id: id,
            title: title,
            description: description,
            status: status,
            canAcceptReply: canAcceptReply,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// The action offered to reply to a ticket.
    ///
    /// When the last message comes from support, they're waiting for the user to reply. Otherwise, the user is the one
    /// waiting, so they can only add more information.
    var replyAction: UnifiedSupportReplyAction {
        guard let lastMessage = messages.last else {
            return .addMoreInfo
        }

        switch lastMessage.authorRole {
        case .user, .bot: return .addMoreInfo
        case .support, .system, .unknown: return .reply
        }
    }

    /// The date of the most recent activity in the conversation.
    ///
    /// For an escalated conversation, `updatedAt` is the date of the last AI Assistant message, so it can be older than
    /// the latest messages from support.
    var lastActivityAt: Date {
        max(updatedAt, messages.map(\.createdAt).max() ?? updatedAt)
    }
}

enum UnifiedSupportReplyAction: Sendable {
    case reply
    case addMoreInfo

    var title: String {
        switch self {
        case .reply: UnifiedSupportLocalization.reply
        case .addMoreInfo: UnifiedSupportLocalization.addMoreInfo
        }
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
