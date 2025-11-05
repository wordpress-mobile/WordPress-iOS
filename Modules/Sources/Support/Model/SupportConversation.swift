import Foundation
import SwiftUI

public enum ConversationStatus: Sendable, Codable {
    case waitingForSupport
    case waitingForUser
    case resolved
    case closed
    case unknown // Handles future server updates

    var title: String {
        switch self {
        case .waitingForSupport: "Waiting for support"
        case .waitingForUser: "Waiting for you"
        case .resolved: "Solved"
        case .closed: "Closed"
        case .unknown: "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .waitingForSupport: Color.blue
        case .waitingForUser: Color.orange
        case .resolved: Color.green
        case .closed: Color.gray
        case .unknown: Color.orange
        }
    }
}

public struct ConversationSummary: Identifiable, Hashable, Sendable, Codable, Equatable {

    public let id: UInt64
    public let title: String
    public let description: String
    public let attributedDescription: AttributedString
    public let status: ConversationStatus

    /// The `description` with any markdown formatting stripped out
    public let plainTextDescription: String
    public let lastMessageSentAt: Date

    public init(
        id: UInt64,
        title: String,
        description: String,
        status: ConversationStatus,
        lastMessageSentAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.attributedDescription = convertMarkdownTextToAttributedString(description)
        self.plainTextDescription = NSAttributedString(attributedDescription).string
        self.status = status
        self.lastMessageSentAt = lastMessageSentAt
    }
}

public struct Conversation: Identifiable, Sendable, Codable, Equatable {
    public let id: UInt64
    public let title: String
    public let description: String
    public let lastMessageSentAt: Date
    public let status: ConversationStatus
    public let messages: [Message]

    public init(
        id: UInt64,
        title: String,
        description: String,
        lastMessageSentAt: Date,
        status: ConversationStatus,
        messages: [Message]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.lastMessageSentAt = lastMessageSentAt
        self.status = status
        self.messages = messages
    }

    func addingMessage(_ message: Message) -> Conversation {
        return Conversation(
            id: self.id,
            title: self.title,
            description: self.description,
            lastMessageSentAt: message.createdAt,
            status: self.status,
            messages: self.messages + [message]
        )
    }

    /// Will the server accept a reply to this conversation?
    ///
    /// Unrelated to whether the user is eligible for support.
    var canAcceptReply: Bool {
        status != .closed
    }
}

public struct Message: Identifiable, Sendable, Codable, Equatable {
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

public struct Attachment: Identifiable, Sendable, Codable, Equatable {

    public struct Dimensions: Sendable, Codable, Equatable {
        let width: UInt64
        let height: UInt64

        public init(width: UInt64, height: UInt64) {
            self.width = width
            self.height = height
        }
    }

    public let id: UInt64
    public let filename: String
    public let contentType: String
    public let fileSize: UInt64
    public let url: URL

    public let dimensions: Dimensions?

    public init(
        id: UInt64,
        filename: String,
        contentType: String,
        fileSize: UInt64,
        url: URL,
        dimensions: Dimensions? = nil
    ) {
        self.id = id
        self.filename = filename
        self.contentType = contentType
        self.fileSize = fileSize
        self.url = url
        self.dimensions = dimensions
    }

    var isImage: Bool {
        contentType.hasPrefix("image/")
    }

    var isVideo: Bool {
        contentType.hasPrefix("video/")
    }

    var isPdf: Bool {
        contentType == "application/pdf"
    }

    var icon: String {
        if isVideo {
            return "film"
        }

        if isPdf {
            return "text.document"
        }

        return "doc"
    }
}
