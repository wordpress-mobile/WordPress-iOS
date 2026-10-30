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

    case viewDiagnostics
    case emptyDiskCache(bytesSaved: Int64)
}

@MainActor
public final class SupportDataProvider: ObservableObject, Sendable {

    private let applicationLogProvider: ApplicationLogDataProvider
    private let botConversationDataProvider: BotConversationDataProvider
    private let userDataProvider: CurrentUserDataProvider
    private let diagnosticsDataProvider: DiagnosticsDataProvider
    let mediaHost: MediaHostProtocol

    private weak var supportDelegate: SupportDelegate?

    public init(
        applicationLogProvider: ApplicationLogDataProvider,
        botConversationDataProvider: BotConversationDataProvider,
        userDataProvider: CurrentUserDataProvider,
        diagnosticsDataProvider: DiagnosticsDataProvider,
        mediaHost: MediaHostProtocol,
        delegate: SupportDelegate? = nil
    ) {
        self.applicationLogProvider = applicationLogProvider
        self.botConversationDataProvider = botConversationDataProvider
        self.userDataProvider = userDataProvider
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

    // Application Logs
    public var canShareApplicationLogs: Bool {
        self.applicationLogProvider.canShareApplicationLogs
    }

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
    /// Whether the application logs can reach the support team.
    ///
    /// The user can opt out of sharing them, and logs queued while they're opted out are never uploaded. The
    /// support forms don't offer logs they can't deliver.
    nonisolated var canShareApplicationLogs: Bool { get }

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
