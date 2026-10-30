import Foundation
import Testing
@testable import Support

/// The sample data provider drives the SwiftUI previews, so it needs to behave like the server.
struct InternalUnifiedSupportDataProviderTests {

    @Test func createsBotConversationsAtTheTopOfTheList() async throws {
        let provider = InternalUnifiedSupportDataProvider(
            conversations: [.previewSolvedConversation],
            responseDelay: .zero
        )

        let conversation = try await provider.createBotConversation(message: "Hello")
        let summaries = try await provider.loadConversations().fetchedResult()

        #expect(conversation.isBot)
        #expect(conversation.messages.map(\.authorRole) == [.user, .bot])
        #expect(summaries.map(\.id) == [conversation.id, UnifiedSupportConversation.previewSolvedConversation.id])
    }

    @Test func escalatesBotConversationsWhenTheUserAsksForAHuman() async throws {
        let provider = InternalUnifiedSupportDataProvider(
            conversations: [.previewBotConversation],
            responseDelay: .zero
        )

        let conversation = try await provider.reply(
            toConversation: UnifiedSupportConversation.previewBotConversation.id,
            message: "Can I talk to a human?",
            attachments: [],
            includeApplicationLogs: false
        )

        #expect(conversation.status == .ongoing)
        #expect(conversation.messages.last?.authorRole == .system)
    }

    @Test func keepsBotConversationsWithTheAIAssistant() async throws {
        let provider = InternalUnifiedSupportDataProvider(
            conversations: [.previewBotConversation],
            responseDelay: .zero
        )

        let conversation = try await provider.reply(
            toConversation: UnifiedSupportConversation.previewBotConversation.id,
            message: "Thanks!",
            attachments: [],
            includeApplicationLogs: false
        )

        #expect(conversation.isBot)
        #expect(conversation.messages.suffix(2).map(\.authorRole) == [.user, .bot])
    }

    @Test func failsToLoadConversationsWithTheGivenError() async {
        let provider = InternalUnifiedSupportDataProvider(
            loadingError: UnifiedSupportError.offline,
            responseDelay: .zero
        )

        await #expect(throws: UnifiedSupportError.offline) {
            try await provider.loadConversations().fetchedResult()
        }
    }
}
