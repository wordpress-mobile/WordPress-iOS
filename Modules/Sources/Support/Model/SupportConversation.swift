import Foundation

public struct ConversationSummary: Identifiable, Hashable, Sendable, Codable {
    public let id: UInt64
    public let title: String
    public let description: String
    public let attributedDescription: AttributedString

    /// The `description` with any markdown formatting stripped out
    public let plainTextDescription: String
    public let lastMessageSentAt: Date

    public init(
        id: UInt64,
        title: String,
        description: String,
        lastMessageSentAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.attributedDescription = convertMarkdownTextToAttributedString(description)
        self.plainTextDescription = NSAttributedString(attributedDescription).string
        self.lastMessageSentAt = lastMessageSentAt
    }
}

public struct Conversation: Identifiable, Sendable, Codable {
    public let id: UInt64
    public let title: String
    public let description: String
    public let lastMessageSentAt: Date
    public let messages: [Message]

    public init(
        id: UInt64,
        title: String,
        description: String,
        lastMessageSentAt: Date,
        messages: [Message]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.lastMessageSentAt = lastMessageSentAt
        self.messages = messages
    }

    func addingMessage(_ message: Message) -> Conversation {
        return Conversation(
            id: self.id,
            title: self.title,
            description: self.description,
            lastMessageSentAt: message.createdAt,
            messages: self.messages + [message]
        )
    }
}

public struct Message: Identifiable, Sendable, Codable {
    public let id: UInt64
    public let content: String

    /// The `content` with any markdown formatting applied to make Rich Text
    public let attributedContent: AttributedString
    public let createdAt: Date
    public let authorName: String
    public let authorIsUser: Bool
    public let attachments: [Attachment]

    public init(
        id: UInt64,
        content: String,
        createdAt: Date,
        authorName: String,
        authorIsUser: Bool,
        attachments: [Attachment]
    ) {
        self.id = id
        self.content = content
        self.attributedContent = convertMarkdownTextToAttributedString(content)
        self.createdAt = createdAt
        self.authorName = authorName
        self.authorIsUser = authorIsUser
        self.attachments = attachments
    }

    /// The `content` with any markdown formatting stripped out
    var plainTextContent: String {
        NSAttributedString(attributedContent).string
    }
}

public struct Attachment: Identifiable, Sendable, Codable {
    public let id: UInt64

    public init(id: UInt64) {
        self.id = id
    }
}
