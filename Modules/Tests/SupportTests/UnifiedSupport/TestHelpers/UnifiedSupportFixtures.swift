import Foundation
@testable import Support

extension UnifiedSupportConversationSummary {
    static func make(
        id: UInt64 = 1,
        title: String = "Title",
        description: String = "Description",
        status: UnifiedSupportConversationStatus = .ongoing,
        canAcceptReply: Bool = true,
        createdAt: Date = Date(timeIntervalSince1970: 1_000),
        updatedAt: Date = Date(timeIntervalSince1970: 2_000)
    ) -> UnifiedSupportConversationSummary {
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
}

extension UnifiedSupportConversation {
    static func make(
        id: UInt64 = 1,
        title: String = "Title",
        description: String = "Description",
        status: UnifiedSupportConversationStatus = .ongoing,
        canAcceptReply: Bool = true,
        createdAt: Date = Date(timeIntervalSince1970: 1_000),
        updatedAt: Date = Date(timeIntervalSince1970: 2_000),
        messages: [UnifiedSupportMessage] = []
    ) -> UnifiedSupportConversation {
        UnifiedSupportConversation(
            id: id,
            title: title,
            description: description,
            status: status,
            canAcceptReply: canAcceptReply,
            createdAt: createdAt,
            updatedAt: updatedAt,
            messages: messages
        )
    }
}

extension UnifiedSupportMessage {
    static func make(
        id: UInt64 = 1,
        content: String = "Hello",
        authorRole: AuthorRole = .user,
        authorName: String = "Author",
        createdAt: Date = Date(timeIntervalSince1970: 1_500),
        attachments: [UnifiedSupportAttachment] = []
    ) -> UnifiedSupportMessage {
        UnifiedSupportMessage(
            id: .remote(id),
            content: content,
            authorRole: authorRole,
            authorName: authorName,
            createdAt: createdAt,
            attachments: attachments
        )
    }
}

extension UnifiedSupportAttachment {
    static func makeLink(
        filename: String = "Migrate your site",
        url: String = "https://jetpack.com/support/"
    ) -> UnifiedSupportAttachment {
        UnifiedSupportAttachment(
            remoteId: 0,
            filename: filename,
            contentType: "text/html",
            fileSize: 0,
            url: URL(string: url)!
        )
    }

    static func makeImage(filename: String = "screenshot.png") -> UnifiedSupportAttachment {
        UnifiedSupportAttachment(
            remoteId: 1,
            filename: filename,
            contentType: "image/png",
            fileSize: 1_024,
            url: URL(string: "https://example.com/\(filename)")!
        )
    }
}
