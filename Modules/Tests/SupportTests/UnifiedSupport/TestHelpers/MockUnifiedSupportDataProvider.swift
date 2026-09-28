import Foundation
import os
import WordPressCoreProtocols
@testable import Support

enum MockError: Error {
    case notStubbed
    case failure
}

enum LocalizedMockError: LocalizedError {
    case somethingSpecific

    var errorDescription: String? {
        "The site is temporarily unavailable."
    }
}

/// A data provider whose responses are configured by each test.
actor MockUnifiedSupportDataProvider: UnifiedSupportDataProvider {

    struct Stubs: Sendable {
        var isOnline = true
        var loadConversationsError: (any Error)?
        var cachedConversations: [UnifiedSupportConversationSummary]?

        /// The results of fetching the conversations, used in order. The last one is used for any further fetches.
        var fetchedConversations: [Result<[UnifiedSupportConversationSummary], any Error>] = []

        var fetchedConversation: Result<UnifiedSupportConversation, any Error> = .failure(MockError.notStubbed)
        var createdConversation: Result<UnifiedSupportConversation, any Error> = .failure(MockError.notStubbed)
        var repliedConversation: Result<UnifiedSupportConversation, any Error> = .failure(MockError.notStubbed)

        fileprivate mutating func nextFetchedConversations() -> Result<[UnifiedSupportConversationSummary], any Error> {
            guard let result = fetchedConversations.first else {
                return .failure(MockError.notStubbed)
            }
            if fetchedConversations.count > 1 {
                fetchedConversations.removeFirst()
            }
            return result
        }
    }

    let maximumUploadSize: UInt64 = 20 * 1024 * 1024

    private let stubs: OSAllocatedUnfairLock<Stubs>
    private let fetchCount = OSAllocatedUnfairLock(initialState: 0)
    private let sentMessagesStore = OSAllocatedUnfairLock<[SentMessage]>(initialState: [])

    init(_ stubs: Stubs = Stubs()) {
        self.stubs = OSAllocatedUnfairLock(initialState: stubs)
    }

    nonisolated func updateStubs(_ update: @Sendable (inout Stubs) -> Void) {
        stubs.withLock(update)
    }

    nonisolated var conversationsFetchCount: Int {
        fetchCount.withLock { $0 }
    }

    nonisolated func isOnline() -> Bool {
        stubs.withLock { $0.isOnline }
    }

    nonisolated func loadConversations() throws -> any CachedAndFetchedResult<[UnifiedSupportConversationSummary]> {
        let (cachedConversations, error) = stubs.withLock { ($0.cachedConversations, $0.loadConversationsError) }
        if let error {
            throw error
        }

        return StubCachedAndFetchedResult(
            cachedResult: { cachedConversations },
            fetchedResult: { [stubs, fetchCount] in
                fetchCount.withLock { $0 += 1 }
                return try stubs.withLock { $0.nextFetchedConversations() }.get()
            }
        )
    }

    /// The messages sent, in order, with the conversation they were sent to. A `nil` id means a new conversation.
    nonisolated var sentMessages: [(conversationId: UInt64?, message: String)] {
        sentMessagesStore.withLock { $0 }
    }

    func fetchConversation(id: UInt64) async throws -> UnifiedSupportConversation {
        try stubs.withLock { $0.fetchedConversation }.get()
    }

    func createBotConversation(message: String) async throws -> UnifiedSupportConversation {
        sentMessagesStore.withLock { $0.append((nil, message)) }
        return try stubs.withLock { $0.createdConversation }.get()
    }

    func reply(
        toConversation id: UInt64,
        message: String,
        attachments: [URL],
        includeApplicationLogs: Bool
    ) async throws -> UnifiedSupportConversation {
        sentMessagesStore.withLock { $0.append((id, message)) }
        return try stubs.withLock { $0.repliedConversation }.get()
    }
}

typealias SentMessage = (conversationId: UInt64?, message: String)

struct StubCachedAndFetchedResult<T: Sendable>: CachedAndFetchedResult {
    let cachedResult: @Sendable () async throws -> T?
    let fetchedResult: @Sendable () async throws -> T
}
