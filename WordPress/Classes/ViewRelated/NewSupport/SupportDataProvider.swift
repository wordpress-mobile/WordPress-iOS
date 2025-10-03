import Foundation
import AsyncImageKit
import Support
import SwiftUI
import WordPressAPI
import WordPressAPIInternal // Needed for `SupportUserIdentity`
import WordPressData
import WordPressShared
import CocoaLumberjack

extension SupportDataProvider {
    @MainActor
    static let shared = SupportDataProvider(
        applicationLogProvider: WpLogDataProvider(),
        botConversationDataProvider: WpBotConversationDataProvider(
            wpcomClient: WordPressDotComClient()
        ),
        userDataProvider: WpCurrentUserDataProvider(
            wpcomClient: WordPressDotComClient()
        ),
        supportConversationDataProvider: WpSupportConversationDataProvider(
            wpcomClient: WordPressDotComClient()),
        delegate: nil
    )
}

actor WpLogDataProvider: ApplicationLogDataProvider {
    func fetchApplicationLogs() async throws -> [Support.ApplicationLog] {
        try WPLogger.shared().fileLogger
            .logFileManager
            .sortedLogFileInfos
            .compactMap { try ApplicationLog(filePath: $0.filePath) }
    }

    func deleteApplicationLogs(in logs: [Support.ApplicationLog]) async throws {
        for log in logs {
            try FileManager.default.removeItem(at: log.path)
        }
    }

    func deleteAllApplicationLogs() async throws {
        WPLogger.shared().deleteAllLogs()
    }
}

actor WpBotConversationDataProvider: BotConversationDataProvider {

    private let botId = "jetpack-chat-mobile"

    private let wpcomClient: WordPressDotComClient

    private var conversationMessageStore: [UInt64: Support.BotConversation] = [:]

    init(wpcomClient: WordPressDotComClient) {
        self.wpcomClient = wpcomClient
    }

    func loadBotConversations() async throws -> [Support.BotConversation] {
        try await self.wpcomClient
            .api
            .supportBots
            .getBotConverationList(botId: self.botId)
            .data
            .map { $0.asSupportConversation() }
    }

    func loadBotConversation(id: UInt64) async throws -> Support.BotConversation? {
        let params = GetBotConversationParams(
            pageNumber: 1,
            itemsPerPage: 100,
            includeFeedback: false
        )

        let conversation = try await self.wpcomClient
            .api
            .supportBots
            .getBotConversation(botId: self.botId, chatId: ChatId(id), params: params)
            .data

        return conversation.asSupportConversation()
    }

    func delete(conversationIds: [UInt64]) async throws {
        // TODO: Implement this
    }

    func sendMessage(message: String, in conversation: Support.BotConversation?) async throws -> Support.BotConversation {
        if let conversation {
            _ = try await add(message: message, to: conversation)
            return try await loadBotConversation(id: conversation.id) ?? conversation
        } else {
            return try await createConversation(message: message)
        }
    }

    func createConversation(message: String) async throws -> Support.BotConversation {

        guard let accountId = try await ContextManager.shared
            .performQuery({ try WPAccount.lookupDefaultWordPressComAccount(in: $0)?.userID?.int64Value }) else {
                fatalError("Could not get the current user ID – this should never happen because users should be logged in")
            }

        let params: CreateBotConversationParams = CreateBotConversationParams(
            message: message,
            userId: accountId
        )

        let response = try await self.wpcomClient
            .api
            .supportBots
            .createBotConversation(botId: self.botId, params: params)
            .data

        return response.asSupportConversation()
    }

    private func add(message: String, to conversation: Support.BotConversation) async throws -> Support.BotConversation {
        let params: AddMessageToBotConversationParams = AddMessageToBotConversationParams(
            message: message,
            context: [:]
        )

        let response = try await self.wpcomClient
            .api
            .supportBots
            .addMessageToBotConversation(
                botId: self.botId,
                chatId: ChatId(conversation.id),
                params: params
            ).data

        return response.asSupportConversation()
    }
}

actor WpCurrentUserDataProvider: CurrentUserDataProvider {

    private let wpcomClient: WordPressDotComClient
    private var cachedCurrentSupportUser: Support.SupportUser?

    init(wpcomClient: WordPressDotComClient) {
        self.wpcomClient = wpcomClient
    }

    func fetchCurrentSupportUser() async throws -> Support.SupportUser {
        if let cachedCurrentSupportUser {
            return cachedCurrentSupportUser
        }

        let user = try await self.wpcomClient.api.me.get().data.asSupportIdentity()
        cachedCurrentSupportUser = user
        return user
    }
}

actor WpSupportConversationDataProvider: SupportConversationDataProvider {

    private let wpcomClient: WordPressDotComClient

    init(wpcomClient: WordPressDotComClient) {
        self.wpcomClient = wpcomClient
    }

    func loadSupportConversations() async throws -> [ConversationSummary] {
        try await self.wpcomClient.api
            .supportTickets
            .getSupportConversationList()
            .data
            .map { $0.asConversationSummary() }
    }

    func loadSupportConversation(id: UInt64) async throws -> Conversation {
        try await self.wpcomClient.api
            .supportTickets
            .getSupportConversation(conversationId: id)
            .data
            .asConversation()
    }

    func createSupportConversation(
        subject: String,
        message: String,
        user: SupportUser,
        attachments: [URL]
    ) async throws -> Conversation {
        let params = CreateSupportTicketParams(
            subject: subject,
            message: message,
            application: "jetpack"
        )

        return try await self.wpcomClient.api
            .supportTickets
            .createSupportTicket(params: params)
            .data
            .asConversation()
    }

    func replyToSupportConversation(
        id: UInt64,
        message: String,
        user: SupportUser,
        attachments: [URL]
    ) async throws -> Conversation {
        let params = AddMessageToSupportConversationParams(
            message: message,
            attachments: attachments.map { $0.path() }
        )

        return try await self.wpcomClient.api
            .supportTickets
            .addMessageToSupportConversation(conversationId: id, params: params)
            .data
            .asConversation()
    }
}

extension WPComApiClient: @retroactive @unchecked Sendable {}

extension WpComUserInfo {
    func asSupportIdentity() async throws -> SupportUser {
        SupportUser(
            userId: self.id,
            username: self.displayName,
            email: self.email,
            avatarUrl: self.getAvatarUrl(),
        )
    }

    func getAvatarUrl() -> URL? {
        guard let urlString = self.avatarUrl, let url = URL(string: urlString) else {
            return nil
        }

        return url
    }
}

extension WordPressAPIInternal.BotConversationSummary {
    func asSupportConversation() -> Support.BotConversation {
        var summary = self.lastMessage.content

        if let preview = summary.components(separatedBy: .newlines).first?.prefix(64) {
            summary = String(preview)
        }

        return BotConversation(
            id: self.chatId,
            title: summary,
            mostRecentMessageDate: self.lastMessage.createdAt,
            messages: []
        )
    }
}

extension WordPressAPIInternal.BotConversation {
    func asSupportConversation() -> Support.BotConversation {
        BotConversation(
            id: self.chatId,
            title: self.messages.first?.content ?? "New Bot Chat",
            mostRecentMessageDate: self.messages.last?.createdAt ?? self.createdAt,
            messages: self.messages.map { $0.asSupportMessage() }
        )
    }
}

extension WordPressAPIInternal.BotMessage {
    func asSupportMessage() -> Support.BotMessage {
        return switch context {

        case .bot(let botContext): Support.BotMessage(
            id: self.messageId,
            text: self.content,
            date: self.createdAt,
            userWantsToTalkToHuman: botContext.userWantsToTalkToAHuman,
            isWrittenByUser: false
        )
        case .user: Support.BotMessage(
            id: self.messageId,
            text: self.content,
            date: self.createdAt,
            userWantsToTalkToHuman: false,
            isWrittenByUser: true
        )
        }
    }
}

extension WordPressAPIInternal.SupportConversationSummary {
    func asConversationSummary() -> Support.ConversationSummary {
        Support.ConversationSummary(
            id: self.id,
            title: self.title,
            description: self.description,
            lastMessageSentAt: self.updatedAt
        )
    }
}

extension SupportConversation {
    func asConversation() -> Conversation {
        Conversation(
            id: self.id,
            title: self.title,
            description: self.description,
            lastMessageSentAt: self.updatedAt,
            messages: self.messages.map { $0.asMessage() }
        )
    }
}

extension SupportMessage {
    func asMessage() -> Message {
        return switch self.author {
        case .user(let user): Message(
            id: self.id,
            content: self.content,
            createdAt: self.createdAt,
            authorName: user.displayName,
            authorIsUser: true,
            attachments: self.attachments.map { $0.asAttachment() }
        )
        case .supportAgent(let agent): Message(
            id: self.id,
            content: self.content,
            createdAt: self.createdAt,
            authorName: agent.name,
            authorIsUser: false,
            attachments: self.attachments.map { $0.asAttachment() }
        )
        }
    }
}

extension SupportAttachment {
    func asAttachment() -> Attachment {
        Attachment(
            id: self.id
        )
    }
}
