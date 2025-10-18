import Foundation
import WordPressCore

public enum SupportFormAction {
    case viewSupportForm
}

public enum DiagnosticAction {
    case clearDiskCache
}

public enum DiagnosticActionStatus {
    case running(progress: Float)
    case success
    case error(Error)
}

@MainActor
public final class SupportDataProvider: ObservableObject, Sendable {

    private let applicationLogProvider: ApplicationLogDataProvider
    private let botConversationDataProvider: BotConversationDataProvider
    private let userDataProvider: CurrentUserDataProvider
    private let supportConversationDataProvider: SupportConversationDataProvider

    private weak var supportDelegate: SupportDelegate?

    public init(
        applicationLogProvider: ApplicationLogDataProvider,
        botConversationDataProvider: BotConversationDataProvider,
        userDataProvider: CurrentUserDataProvider,
        supportConversationDataProvider: SupportConversationDataProvider,
        delegate: SupportDelegate? = nil
    ) {
        self.applicationLogProvider = applicationLogProvider
        self.botConversationDataProvider = botConversationDataProvider
        self.userDataProvider = userDataProvider
        self.supportConversationDataProvider = supportConversationDataProvider
        self.supportDelegate = delegate
    }

    // Delegate Methods
    public func userDid(_ action: SupportFormAction) {
        self.supportDelegate?.userDid(action)
    }

    public func userDid(_ action: DiagnosticAction, progress: @escaping (DiagnosticActionStatus) -> Void) {
        self.supportDelegate?.userDid(action, progress: progress)
    }

    // Support Bots Data Source
    public func loadSupportIdentity() async throws -> any CachedAndFetchedResult<SupportUser> {
        try await self.userDataProvider.fetchCurrentSupportUser()
    }

    // Bot Conversation Data Source
    public func loadConversations() async throws -> any CachedAndFetchedResult<[BotConversation]> {
        try await self.botConversationDataProvider.loadBotConversations()
    }

    public func loadConversation(id: UInt64) async throws -> any CachedAndFetchedResult<BotConversation> {
        try await self.botConversationDataProvider.loadBotConversation(id: id)
    }

    public func delete(conversationIds: [UInt64]) async throws {
        try await self.botConversationDataProvider.delete(conversationIds: conversationIds)
    }

    public func sendMessage(message: String, in conversation: BotConversation? = nil) async throws -> BotConversation {
        try await self.botConversationDataProvider.sendMessage(message: message, in: conversation)
    }

    // Support Conversations Data Source
    public func loadSupportConversations() async throws -> any CachedAndFetchedResult<[ConversationSummary]> {
        try await self.supportConversationDataProvider.loadSupportConversations()
    }

    public func loadSupportConversation(id: UInt64) async throws -> any CachedAndFetchedResult<Conversation> {
        try await self.supportConversationDataProvider.loadSupportConversation(id: id)
    }

    public func replyToSupportConversation(
        id: UInt64,
        message: String,
        user: SupportUser,
        attachments: [URL]
    ) async throws -> Conversation {
        try await self.supportConversationDataProvider.replyToSupportConversation(
            id: id,
            message: message,
            user: user,
            attachments: attachments
        )
    }

    public func createSupportConversation(
        subject: String,
        message: String,
        user: SupportUser,
        attachments: [URL]
    ) async throws -> Conversation {
        try await self.supportConversationDataProvider.createSupportConversation(
            subject: subject,
            message: message,
            user: user,
            attachments: attachments
        )
    }

    // Application Logs
    public func fetchApplicationLogs() async throws -> [ApplicationLog] {
        try await self.applicationLogProvider.fetchApplicationLogs()
    }

    public func readApplicationLog(_ log: ApplicationLog) async throws -> String {
        try await self.applicationLogProvider.readApplicationLog(log)
    }

    public func deleteApplicationLogs(in list: [ApplicationLog]) async throws {
        try await self.applicationLogProvider.deleteApplicationLogs(in: list)
    }

    public func deleteAllApplicationLogs() async throws {
        try await self.applicationLogProvider.deleteAllApplicationLogs()
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
    func userDid(_ action: DiagnosticAction, progress: (DiagnosticActionStatus) -> Void)
}

public enum SupportUserPermission: Sendable, Codable {
    case createChatConversation
    case createSupportRequest
}

public protocol CurrentUserDataProvider: Actor {
    func fetchCurrentSupportUser() async throws -> any CachedAndFetchedResult<SupportUser>
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
    func loadBotConversations() async throws -> any CachedAndFetchedResult<[BotConversation]>
    func loadBotConversation(id: UInt64) async throws -> any CachedAndFetchedResult<BotConversation>

    func sendMessage(message: String, in conversation: BotConversation?) async throws -> BotConversation
    func delete(conversationIds: [UInt64]) async throws
}

public protocol SupportConversationDataProvider: Actor {
    func loadSupportConversations() async throws -> any CachedAndFetchedResult<[ConversationSummary]>
    func loadSupportConversation(id: UInt64) async throws -> any CachedAndFetchedResult<Conversation>

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
