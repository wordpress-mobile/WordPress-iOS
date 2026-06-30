import Foundation

/// A single entry in the unified support conversations list.
///
/// The unified endpoint returns both AI bot chats and Happiness Engineer
/// tickets in one combined list. ``isBot`` decides which detail experience the
/// row opens into: a chat-style bot conversation, or a ticket-style HE
/// conversation.
public struct UnifiedConversationItem: Identifiable, Hashable, Sendable, Codable, Equatable {

    public let id: UInt64
    public let title: String
    public let description: String

    /// The `description` with markdown formatting applied for rich-text display.
    public let attributedDescription: AttributedString

    /// The `description` with any markdown formatting stripped out.
    public let plainTextDescription: String

    /// Raw server status string (e.g. `"bot"`, `"open"`, `"closed"`, `"pending"`, `"solved"`).
    public let rawStatus: String

    /// The status mapped for badge rendering. Only meaningful for HE conversations.
    public let status: ConversationStatus

    /// Will the server accept a reply to this conversation?
    public let canAcceptReply: Bool

    public let lastMessageSentAt: Date

    public init(
        id: UInt64,
        title: String,
        description: String,
        rawStatus: String,
        canAcceptReply: Bool,
        lastMessageSentAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.attributedDescription = convertMarkdownTextToAttributedString(description)
        self.plainTextDescription = NSAttributedString(self.attributedDescription).string
        self.rawStatus = rawStatus
        self.status = ConversationStatus(serverStatus: rawStatus)
        self.canAcceptReply = canAcceptReply
        self.lastMessageSentAt = lastMessageSentAt
    }

    /// `true` when this conversation is an AI bot chat rather than a Happiness
    /// Engineer ticket.
    public var isBot: Bool {
        rawStatus.caseInsensitiveCompare(Self.botStatus) == .orderedSame
    }

    public static let botStatus = "bot"
}

public extension ConversationStatus {
    /// Maps a raw server status string to a ``ConversationStatus``.
    ///
    /// Mirrors the Android `ConversationStatus.fromStatus` mapping so badges are
    /// consistent across platforms.
    init(serverStatus: String) {
        switch serverStatus.lowercased() {
        case "open", "new", "hold": self = .waitingForSupport
        case "pending": self = .waitingForUser
        case "solved": self = .resolved
        case "closed": self = .closed
        default: self = .unknown
        }
    }
}
