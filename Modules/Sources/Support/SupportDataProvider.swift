import Foundation
import UIKit
import AsyncImageKit
import WordPressCoreProtocols

public enum SupportFormAction {
    case viewApplicationLogList
    case viewApplicationLog(String)
    case deleteApplicationLogs([String])
    case deleteAllApplicationLogs

    case viewSupportBotConversationList
    case startSupportBotConversation
    case viewSupportBotConversation(conversationId: UInt64)
    case replyToSupportBotMessage(conversationId: UInt64)
    case failToCreateBotConversation(Error)
    case failToReplyToBotConversation(Error)

    case viewSupportTicketList
    case viewSupportTicket(ticketId: UInt64)
    case createSupportTicket
    case replyToSupportTicket(ticketId: UInt64)
    case failToCreateSupportTicket(Error)
    case failToReplyToSupportTicket(Error)

    case viewDiagnostics
    case emptyDiskCache(bytesSaved: Int64)
}

@MainActor
public final class SupportDataProvider: ObservableObject, Sendable {

    private let applicationLogProvider: ApplicationLogDataProvider
    private let botConversationDataProvider: BotConversationDataProvider
    private let userDataProvider: CurrentUserDataProvider
    private let supportConversationDataProvider: SupportConversationDataProvider
    private let diagnosticsDataProvider: DiagnosticsDataProvider
    let mediaHost: MediaHostProtocol

    private weak var supportDelegate: SupportDelegate?

    public init(
        applicationLogProvider: ApplicationLogDataProvider,
        botConversationDataProvider: BotConversationDataProvider,
        userDataProvider: CurrentUserDataProvider,
        supportConversationDataProvider: SupportConversationDataProvider,
        diagnosticsDataProvider: DiagnosticsDataProvider,
        mediaHost: MediaHostProtocol,
        delegate: SupportDelegate? = nil
    ) {
        self.applicationLogProvider = applicationLogProvider
        self.botConversationDataProvider = botConversationDataProvider
        self.userDataProvider = userDataProvider
        self.supportConversationDataProvider = supportConversationDataProvider
        self.diagnosticsDataProvider = diagnosticsDataProvider
        self.mediaHost = mediaHost
        self.supportDelegate = delegate
    }

    // Delegate Methods
    public func userDid(_ action: SupportFormAction) {
        self.supportDelegate?.userDid(action)
    }

    public func extensiveLogsViewController() -> UIViewController {
        self.supportDelegate?.extensionLogsViewController() ?? UIViewController()
    }

    // Support Bots Data Source
    public func loadSupportIdentity() throws -> any CachedAndFetchedResult<SupportUser> {
        try self.userDataProvider.fetchCurrentSupportUser()
    }

    // Bot Conversation Data Source
    public func loadConversations() async throws -> any CachedAndFetchedResult<[BotConversation]> {
        try self.botConversationDataProvider.loadBotConversations()
    }

    public func loadConversation(id: UInt64) async throws -> any CachedAndFetchedResult<BotConversation> {
        try self.botConversationDataProvider.loadBotConversation(id: id)
    }

    public func delete(conversationIds: [UInt64]) async throws {
        try await self.botConversationDataProvider.delete(conversationIds: conversationIds)
    }

    public func sendMessage(message: String, in conversation: BotConversation? = nil) async throws -> BotConversation {
        if let conversation {
            self.userDid(.replyToSupportBotMessage(conversationId: conversation.id))
        } else {
            self.userDid(.startSupportBotConversation)
        }

        do {
            return try await self.botConversationDataProvider.sendMessage(message: message, in: conversation)
        } catch {
            if conversation != nil {
                self.userDid(.failToCreateBotConversation(error))
            } else {
                self.userDid(.failToReplyToBotConversation(error))
            }

            throw error
        }
    }

    // Support Conversations Data Source
    public func loadSupportConversations() throws -> any CachedAndFetchedResult<[ConversationSummary]> {
        try self.supportConversationDataProvider.loadSupportConversations()
    }

    public func loadSupportConversation(id: UInt64) throws -> any CachedAndFetchedResult<Conversation> {
        try self.supportConversationDataProvider.loadSupportConversation(id: id)
    }

    public func replyToSupportConversation(
        id: UInt64,
        message: String,
        user: SupportUser,
        attachments: [URL]
    ) async throws -> Conversation {
        self.userDid(.replyToSupportTicket(ticketId: id))

        do {
            return try await self.supportConversationDataProvider.replyToSupportConversation(
                id: id,
                message: message,
                user: user,
                attachments: attachments
            )
        } catch {
            self.userDid(.failToReplyToSupportTicket(error))
            throw error
        }
    }

    public func createSupportConversation(
        subject: String,
        message: String,
        user: SupportUser,
        attachments: [URL]
    ) async throws -> Conversation {
        self.userDid(.createSupportTicket)

        do {
            return try await self.supportConversationDataProvider.createSupportConversation(
                subject: subject,
                message: message,
                user: user,
                attachments: attachments
            )
        } catch {
            self.userDid(.failToCreateSupportTicket(error))
            throw error
        }
    }

    var maximumUploadSize: CGFloat {
        CGFloat(self.supportConversationDataProvider.maximumUploadSize)
    }

    // Application Logs
    public func fetchApplicationLogs() async throws -> [ApplicationLog] {
        try await self.applicationLogProvider.fetchApplicationLogs()
    }

    public func readApplicationLog(_ log: ApplicationLog) async throws -> String {
        try await self.applicationLogProvider.readApplicationLog(log)
    }

    public func deleteApplicationLogs(in list: [ApplicationLog]) async throws {
        self.userDid(.deleteApplicationLogs(list.map({ $0.id })))
        try await self.applicationLogProvider.deleteApplicationLogs(in: list)
    }

    public func deleteAllApplicationLogs() async throws {
        self.userDid(.deleteAllApplicationLogs)
        try await self.applicationLogProvider.deleteAllApplicationLogs()
    }

    // Diagnostics
    public func fetchDiskCacheUsage() async throws -> DiskCacheUsage {
        try await self.diagnosticsDataProvider.fetchDiskCacheUsage()
    }

    public func clearDiskCache(
        progress: (@escaping @Sendable (CacheDeletionProgress) async throws -> Void)
    ) async throws {
        try await self.diagnosticsDataProvider.clearDiskCache(progress: progress)
    }
}

public protocol SupportFormDataProvider {
    /// The user-selectable category
    var areas: [SupportFormArea] { get }

    ///
    var areasTitle: String { get }

    var formTitle: String { get }

    var formDescription: String { get }
}

extension SupportFormDataProvider {
    var areasTitle: String {
        NSLocalizedString(
            "I need help with",
            comment: "Text on the support form to refer to what area the user has problem with."
        )
    }

    var formTitle: String {
        NSLocalizedString(
            "Let’s get this sorted",
            comment: "Title to let the user know what do we want on the support screen."
        )
    }

    var formDescription: String {
        NSLocalizedString(
            "Let us know your site address (URL) and tell us as much as you can about the problem, and we will be in touch soon.",
            comment: "Message info on the support screen."
        )
    }
}

public protocol SupportDelegate: NSObject {
    func userDid(_ action: SupportFormAction)

    func extensionLogsViewController() -> UIViewController
}

public enum SupportUserPermission: Sendable, Codable {
    case createChatConversation
    case createSupportRequest
}

public protocol CurrentUserDataProvider: Actor {
    nonisolated func fetchCurrentSupportUser() throws -> any CachedAndFetchedResult<SupportUser>
}

public protocol DiagnosticsDataProvider: Actor {
    func fetchDiskCacheUsage() async throws -> DiskCacheUsage
    func clearDiskCache(progress: (@escaping @Sendable (CacheDeletionProgress) async throws -> Void)) async throws
}

public protocol ApplicationLogDataProvider: Actor {
    func readApplicationLog(_ log: ApplicationLog) async throws -> String
    func fetchApplicationLogs() async throws -> [ApplicationLog]
    func deleteApplicationLogs(in logs: [ApplicationLog]) async throws
    func deleteAllApplicationLogs() async throws
}

public extension ApplicationLogDataProvider {
    func readApplicationLog(_ log: ApplicationLog) async throws -> String {
        try String(contentsOf: log.path, encoding: .utf8)
    }

    func readFiles(in directory: URL) async throws -> [ApplicationLog] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path).compactMap { filePath in
            try ApplicationLog(filePath: filePath)
        }
    }
}

public protocol BotConversationDataProvider: Actor {
    nonisolated func loadBotConversations() throws -> any CachedAndFetchedResult<[BotConversation]>
    nonisolated func loadBotConversation(id: UInt64) throws -> any CachedAndFetchedResult<BotConversation>

    func sendMessage(message: String, in conversation: BotConversation?) async throws -> BotConversation
    func delete(conversationIds: [UInt64]) async throws
}

public protocol SupportConversationDataProvider: Actor {
    nonisolated var maximumUploadSize: UInt64 { get }

    nonisolated func loadSupportConversations() throws -> any CachedAndFetchedResult<[ConversationSummary]>
    nonisolated func loadSupportConversation(id: UInt64) throws -> any CachedAndFetchedResult<Conversation>

    func replyToSupportConversation(
        id: UInt64,
        message: String,
        user: SupportUser,
        attachments: [URL]
    ) async throws -> Conversation

    func createSupportConversation(
        subject: String,
        message: String,
        user: SupportUser,
        attachments: [URL]
    ) async throws -> Conversation
}
