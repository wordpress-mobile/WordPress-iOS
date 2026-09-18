import Foundation

/// A message in a unified support conversation, written by the user, the AI Assistant, or a Happiness Engineer.
public struct UnifiedSupportMessage: Identifiable, Sendable, Equatable {

    public enum ID: Hashable, Sendable {
        /// A message stored on the server.
        case remote(UInt64)
        /// A message the user sent that isn't confirmed by the server yet.
        case pending(UUID)
    }

    public enum AuthorRole: Sendable, Equatable {
        case user
        case bot
        /// A Happiness Engineer.
        case support
        /// A message added by the server, like the one marking the transfer to a Happiness Engineer.
        case system
        case unknown

        public init(serverValue: String) {
            switch serverValue.lowercased() {
            case "user": self = .user
            case "bot": self = .bot
            case "support": self = .support
            case "system": self = .system
            default: self = .unknown
            }
        }
    }

    public let id: ID
    public let content: String

    /// The `content` with its markdown formatting applied.
    public let attributedContent: AttributedString
    public let authorRole: AuthorRole
    public let authorName: String
    public let createdAt: Date
    public let attachments: [UnifiedSupportAttachment]

    public init(
        id: ID,
        content: String,
        authorRole: AuthorRole,
        authorName: String,
        createdAt: Date,
        attachments: [UnifiedSupportAttachment] = []
    ) {
        self.id = id
        self.content = content
        self.attributedContent = convertMarkdownTextToAttributedString(content)
        self.authorRole = authorRole
        self.authorName = authorName
        self.createdAt = createdAt
        self.attachments = attachments
    }
}

/// A file attached to a message, or a page the AI Assistant used as a source for its answer.
public struct UnifiedSupportAttachment: Identifiable, Sendable, Equatable {

    enum Kind {
        case image
        case video
        /// A web page, like the sources of an AI Assistant answer.
        case link
        case other
    }

    public let id: UInt64
    public let filename: String
    public let contentType: String
    public let fileSize: UInt64
    public let url: URL

    /// How closely a source matches the AI Assistant answer, from 0 to 1.
    public let matchScore: Double?

    public init(
        id: UInt64,
        filename: String,
        contentType: String,
        fileSize: UInt64,
        url: URL,
        matchScore: Double? = nil
    ) {
        self.id = id
        self.filename = filename
        self.contentType = contentType
        self.fileSize = fileSize
        self.url = url
        self.matchScore = matchScore
    }

    var kind: Kind {
        let contentType = contentType.lowercased()

        if contentType.hasPrefix("image/") {
            return .image
        }
        if contentType.hasPrefix("video/") {
            return .video
        }
        if contentType.hasPrefix("text/html") {
            return .link
        }
        return .other
    }
}
