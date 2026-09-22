import Foundation
import Support
import WordPressAPIInternal

// Maps the wordpress-rs unified support types to the `Support` module models.

extension UnifiedConversationSummary {
    func asUnifiedSupportConversationSummary() -> UnifiedSupportConversationSummary {
        UnifiedSupportConversationSummary(
            id: id,
            title: title,
            description: description,
            status: UnifiedSupportConversationStatus(serverValue: status),
            canAcceptReply: canAcceptReply,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension UnifiedConversation {
    func asUnifiedSupportConversation() -> UnifiedSupportConversation {
        UnifiedSupportConversation(
            id: id,
            title: title,
            description: description,
            status: UnifiedSupportConversationStatus(serverValue: status),
            canAcceptReply: canAcceptReply,
            createdAt: createdAt,
            updatedAt: updatedAt,
            messages: messages.map { $0.asUnifiedSupportMessage() }
        )
    }
}

extension UnifiedMessage {
    func asUnifiedSupportMessage() -> UnifiedSupportMessage {
        UnifiedSupportMessage(
            id: .remote(id),
            content: message,
            authorRole: UnifiedSupportMessage.AuthorRole(serverValue: authorRole),
            authorName: authorName,
            createdAt: createdAt,
            attachments: attachments.compactMap { $0.asUnifiedSupportAttachment() }
        )
    }
}

extension UnifiedAttachment {
    /// Returns `nil` if the attachment URL is invalid.
    func asUnifiedSupportAttachment() -> UnifiedSupportAttachment? {
        guard let url = URL(string: url) else {
            return nil
        }

        return UnifiedSupportAttachment(
            id: id,
            filename: filename,
            contentType: contentType,
            fileSize: size,
            url: url,
            matchScore: metadata["score"]?.doubleValue
        )
    }
}

extension WordPressAPIInternal.BotConversation {
    /// Maps the response of creating an AI Assistant conversation.
    ///
    /// The response isn't guaranteed to include the user's message, so `sentMessage` is added when it's missing. Like
    /// on the server, the first message is the title and description of the conversation.
    func asUnifiedSupportConversation(sentMessage: String) -> UnifiedSupportConversation {
        var messages = self.messages.map { $0.asUnifiedSupportMessage() }
        if !messages.contains(where: { $0.authorRole == .user }) {
            let userMessage = UnifiedSupportMessage(
                id: .pending(UUID()),
                content: sentMessage,
                authorRole: .user,
                authorName: "",
                createdAt: createdAt
            )
            messages.insert(userMessage, at: 0)
        }

        return UnifiedSupportConversation(
            id: chatId,
            title: sentMessage,
            description: sentMessage,
            status: .bot,
            canAcceptReply: true,
            createdAt: createdAt,
            updatedAt: messages.last?.createdAt ?? createdAt,
            messages: messages
        )
    }
}

extension WordPressAPIInternal.BotMessage {
    func asUnifiedSupportMessage() -> UnifiedSupportMessage {
        UnifiedSupportMessage(
            id: .remote(messageId),
            content: content,
            authorRole: role == "user" ? .user : .bot,
            authorName: "",
            createdAt: createdAt
        )
    }
}

private extension JsonValue {
    var doubleValue: Double? {
        switch self {
        case .float(let value): value
        case .int(let value): Double(value)
        default: nil
        }
    }
}
