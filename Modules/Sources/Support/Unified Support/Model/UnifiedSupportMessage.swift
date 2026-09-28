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

    var isUser: Bool {
        authorRole == .user
    }

    /// Whether the AI Assistant wrote the message.
    ///
    /// Once a conversation is escalated, its earlier messages come back from the conversations endpoint with the
    /// raw `bot` author, which the author name is checked for as well: that endpoint is the one that leaks it.
    var isBot: Bool {
        authorRole == .bot || authorName.caseInsensitiveCompare("bot") == .orderedSame
    }

    /// The name to show above the message.
    ///
    /// The conversations endpoint labels the author with what the backend stores — `bot` for the AI Assistant and
    /// the WordPress.com login for the user — so both are replaced with the names used before the escalation.
    /// Happiness Engineers keep the name the server sends.
    func authorDisplayName(currentUserName: String) -> String {
        if isUser {
            return currentUserName.isEmpty ? authorName : currentUserName
        }
        if isBot {
            return UnifiedSupportLocalization.statusAIAssistant
        }
        return authorName
    }

    /// Whether the message is answered with pages to read, and nothing else.
    ///
    /// A reply that mixes links with files keeps its plain layout, and a user's own message is never presented as
    /// extra reading.
    var hasOnlyLinkAttachments: Bool {
        !isUser && !attachments.isEmpty && attachments.allSatisfy { $0.kind == .link }
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

    /// The attachment's ID on the server, which is 0 for every page the AI Assistant used as a source.
    public let remoteId: UInt64
    public let filename: String
    public let contentType: String
    public let fileSize: UInt64
    public let url: URL

    /// How closely a source matches the AI Assistant answer, from 0 to 1.
    public let matchScore: Double?

    /// Identifies the attachment within its message.
    ///
    /// The server's ID isn't enough: it's 0 for all of a message's sources, and identical IDs would make a list show
    /// the same source over and over.
    public var id: String {
        "\(remoteId)-\(url.absoluteString)"
    }

    public init(
        remoteId: UInt64,
        filename: String,
        contentType: String,
        fileSize: UInt64,
        url: URL,
        matchScore: Double? = nil
    ) {
        self.remoteId = remoteId
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
