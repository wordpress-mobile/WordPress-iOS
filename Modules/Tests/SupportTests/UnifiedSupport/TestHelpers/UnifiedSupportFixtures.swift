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
        createdAt: Date = Date(timeIntervalSince1970: 1_500)
    ) -> UnifiedSupportMessage {
        UnifiedSupportMessage(
            id: .remote(id),
            content: content,
            authorRole: authorRole,
            authorName: authorName,
            createdAt: createdAt
        )
    }
}
