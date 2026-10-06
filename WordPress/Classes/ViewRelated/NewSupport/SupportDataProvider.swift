import Foundation
import FoundationModels
import AsyncImageKit
import Support
import SwiftUI
import WordPressAPI
import WordPressAPIInternal // Needed for `SupportUserIdentity`
import WordPressCore
import WordPressCoreProtocols
import WordPressData
import WordPressShared
import WordPressIntelligence
import CocoaLumberjack
import PulseUI

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
        diagnosticsDataProvider: WpDiagnosticsDataProvider(),
        mediaHost: WordPressDotComClient(),
        delegate: WpSupportDelegate()
    )
}

actor WpLogDataProvider: ApplicationLogDataProvider {
    /// Logs are only uploaded when the user shares crash reports: `EventLoggingDelegate` won't send a queued log
    /// otherwise, so a form that offered them would promise what it can't deliver.
    nonisolated var canShareApplicationLogs: Bool {
        !UserSettings.userHasOptedOutOfCrashLogging
    }

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

class WpSupportDelegate: NSObject, SupportDelegate {
    func userDid(_ action: Support.SupportFormAction) {

        switch action {
        case .viewApplicationLogList:
            WPAnalytics.track(.applicationLog, properties: [
                "subaction": "view-list"
            ])
        case .viewApplicationLog(let id):
            WPAnalytics.track(.applicationLog, properties: [
                "subaction": "view-single",
                "log_id": id
            ])
        case .deleteApplicationLogs(let ids):
            for id in ids {
                WPAnalytics.track(.applicationLog, properties: [
                    "subaction": "delete-log",
                    "log_id": id
                ])
            }
        case .deleteAllApplicationLogs:
            WPAnalytics.track(.applicationLog, properties: [
                "subaction": "delete-all"
            ])

        case .viewSupportBotConversationList:
            WPAnalytics.track(.supportChatbot, properties: [
                "subaction": "view-list"
            ])
        case .startSupportBotConversation:
            WPAnalytics.track(.supportChatbot, properties: [
                "subaction": "start-conversation"
            ])
        case .failToCreateBotConversation(let error):
            WPAnalytics.track(.supportChatbot, properties: [
                "subaction": "error-starting-conversation",
                "error": error.localizedDescription
            ])
        case .viewSupportBotConversation(let id):
            WPAnalytics.track(.supportChatbot, properties: [
                "subaction": "view-conversation",
                "conversation_id": id
            ])
        case .replyToSupportBotMessage(let id):
            WPAnalytics.track(.supportChatbot, properties: [
                "subaction": "reply-to-conversation",
                "conversation_id": id
            ])
        case .failToReplyToBotConversation(let error):
            WPAnalytics.track(.supportChatbot, properties: [
                "subaction": "error-replying-to-conversation",
                "error": error.localizedDescription
            ])
        case .viewDiagnostics:
            WPAnalytics.track(.diagnostics, properties: [
                "subaction": "view-list"
            ])
        case .emptyDiskCache(bytesSaved: let bytesSaved):
            WPAnalytics.track(.diagnostics, properties: [
                "subaction": "empty-disk-cache",
                "bytes-saved": bytesSaved
            ])
        }
    }

    func extensionLogsViewController() -> UIViewController {
        PulseUI.MainViewController()
    }
}

actor WpBotConversationDataProvider: BotConversationDataProvider {

    private let botId = "jetpack-chat-mobile"

    private let wpcomClient: WordPressDotComClient

    private var conversationMessageStore: [UInt64: Support.BotConversation] = [:]

    init(wpcomClient: WordPressDotComClient) {
        self.wpcomClient = wpcomClient
    }

    nonisolated func loadBotConversations() throws -> any CachedAndFetchedResult<[Support.BotConversation]> {
        DiskCachedAndFetchedResult(fetchedResult: {
            try await self.wpcomClient
                .api
                .supportBots
                .getBotConversationList(
                    botId: self.botId,
                    params: ListBotConversationsParams(summaryMethod: .firstMessage)
                )
                .data
                .asyncMap { try await $0.asSupportConversation() }
        }, cacheKey: "bot-conversation-list")
    }

    nonisolated func loadBotConversation(id: UInt64) throws -> any CachedAndFetchedResult<Support.BotConversation> {
        return DiskCachedAndFetchedResult(fetchedResult: {
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

            return try await conversation.asSupportConversation()
        }, cacheKey: "bot-conversation-\(id)")
    }

    func delete(conversationIds: [UInt64]) async throws {
        // TODO: Implement this
    }

    func sendMessage(message: String, in conversation: Support.BotConversation?) async throws -> Support.BotConversation {
        if let conversation {
            _ = try await add(message: message, to: conversation)
            return try await loadBotConversation(id: conversation.id).fetchedResult()
        } else {
            return try await createConversation(message: message)
        }
    }

    func createConversation(message: String) async throws -> Support.BotConversation {

        guard let accountId = try await ContextManager.shared
            .performQuery({ try WPAccount.lookupDefaultWordPressComAccount(in: $0)?.userID?.int64Value }) else {
                fatalError("Could not get the current user ID – this should never happen because users should be logged in")
            }

        let params = CreateBotConversationParams(
            message: message,
            userId: accountId
        )

        let response = try await self.wpcomClient
            .api
            .supportBots
            .createBotConversation(botId: self.botId, params: params)
            .data

        return try await response.asSupportConversation()
    }

    private func add(message: String, to conversation: Support.BotConversation) async throws -> Support.BotConversation {
        let params = AddMessageToBotConversationParams(
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

        return try await response.asSupportConversation()
    }
}

actor WpCurrentUserDataProvider: CurrentUserDataProvider {

    private let wpcomClient: WordPressDotComClient

    init(wpcomClient: WordPressDotComClient) {
        self.wpcomClient = wpcomClient
    }

    nonisolated func fetchCurrentSupportUser() throws -> any CachedAndFetchedResult<Support.SupportUser> {
        DiskCachedAndFetchedResult(fetchedResult: {
            async let user = try await self.wpcomClient.api.me.get().data.asSupportIdentity()
            async let eligibility = try await self.wpcomClient.api.supportEligibility.getSupportEligibility().data

            let supportUser = try await user.applyingSupportEligibility(eligibility)
            return supportUser
        }, cacheKey: "current-support-user")
    }
}

actor WpDiagnosticsDataProvider: DiagnosticsDataProvider {
    func fetchDiskCacheUsage() async throws -> WordPressCoreProtocols.DiskCacheUsage {
        try await DiskCache.shared.diskUsage()
    }

    func clearDiskCache(progress: @escaping @Sendable (WordPressCoreProtocols.CacheDeletionProgress) async throws -> Void) async throws {
        try await DiskCache.shared.removeAll(progress: progress)
    }
}

extension WpComUserInfo {
    func asSupportIdentity() async throws -> SupportUser {
        SupportUser(
            userId: self.id,
            username: self.displayName,
            email: self.email,
            avatarUrl: self.getAvatarUrl()
        )
    }

    func getAvatarUrl() -> URL? {
        guard let urlString = self.avatarUrl, let url = URL(string: urlString) else {
            return nil
        }

        return url
    }
}

extension SupportUser {
    func applyingSupportEligibility(_ eligiblity: SupportEligibility) -> SupportUser {
        var permissions = [SupportUserPermission]()

        if eligiblity.isUserEligible {
            permissions = [.createSupportRequest, .createChatConversation]
        }

        return SupportUser(
            userId: self.userId,
            username: self.username,
            email: self.email,
            permissions: permissions,
            avatarUrl: self.avatarUrl,
        )
    }
}

extension WordPressAPIInternal.BotConversationSummary {
    func asSupportConversation() async throws -> Support.BotConversation {

        let summary = try await cacheOnDisk(key: "conversation-title-\(self.chatId)", computation: {
            await summarize(self.summaryMessage.content)
        })

        return BotConversation(
            id: self.chatId,
            title: summary,
            createdAt: self.createdAt,
            messages: []
        )
    }
}

extension WordPressAPIInternal.BotConversation {
    func asSupportConversation() async throws -> Support.BotConversation {
        let title: String

        if let firstMessageText = self.messages.first?.content {
            title = try await cacheOnDisk(key: "conversation-title-\(self.chatId)") {
                await summarize(firstMessageText)
            }
        } else {
            title = NSLocalizedString(
                "com.jetpack.support.new-bot-chat",
                value: "New Bot Chat",
                comment: "The title of a new bot chat in the support area of the app"
            )
        }

        return BotConversation(
            id: self.chatId,
            title: title,
            createdAt: self.createdAt,
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

fileprivate func summarize(_ text: String) async -> String {
    if #available(iOS 26.0, *) {
        do {
            return try await SupportTicketSummaryGenerator.execute(content: text)
        } catch {
            return text
        }
    } else {
        if let preview = text.components(separatedBy: .newlines).first?.prefix(64) {
            return String(preview)
        } else {
            return text
        }
    }
}
