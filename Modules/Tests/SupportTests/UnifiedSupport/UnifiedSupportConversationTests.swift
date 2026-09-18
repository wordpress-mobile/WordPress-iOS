import Foundation
import Testing
@testable import Support

struct UnifiedSupportConversationStatusTests {

    @Test(arguments: [
        ("bot", UnifiedSupportConversationStatus.bot),
        ("BOT", .bot),
        ("new", .ongoing),
        ("open", .ongoing),
        ("hold", .ongoing),
        ("Pending", .ongoing),
        ("solved", .solved),
        ("closed", .closed),
        ("archived", .unknown),
        ("", .unknown)
    ])
    func mapsServerValue(_ serverValue: String, to expected: UnifiedSupportConversationStatus) {
        #expect(UnifiedSupportConversationStatus(serverValue: serverValue) == expected)
    }
}

struct UnifiedSupportConversationSummaryTests {

    @Test func displaysTitleAndDescription() {
        let summary = UnifiedSupportConversationSummary.make(title: "Title", description: "Description")

        #expect(summary.displayTitle == "Title")
        #expect(summary.displayDescription == "Description")
    }

    @Test func fallsBackToDescriptionWhenTitleIsBlank() {
        let summary = UnifiedSupportConversationSummary.make(title: " \n", description: "Description")

        #expect(summary.displayTitle == "Description")
        #expect(summary.displayDescription == nil)
    }

    @Test func hidesBlankDescription() {
        let summary = UnifiedSupportConversationSummary.make(title: "Title", description: " ")

        #expect(summary.displayDescription == nil)
    }

    @Test func stripsMarkdownFromDescription() {
        let summary = UnifiedSupportConversationSummary.make(description: "Some **bold** text")

        #expect(summary.plainTextDescription == "Some bold text")
    }

    @Test func isBotOnlyForBotStatus() {
        #expect(UnifiedSupportConversationSummary.make(status: .bot).isBot)
        #expect(!UnifiedSupportConversationSummary.make(status: .ongoing).isBot)
    }
}

struct UnifiedSupportConversationTests {

    @Test func offersToAddMoreInfoWithoutMessages() {
        #expect(UnifiedSupportConversation.make(messages: []).replyAction == .addMoreInfo)
    }

    @Test(arguments: [UnifiedSupportMessage.AuthorRole.user, .bot])
    func offersToAddMoreInfoWhenWaitingForSupport(lastAuthorRole: UnifiedSupportMessage.AuthorRole) {
        let conversation = UnifiedSupportConversation.make(messages: [
            .make(id: 1, authorRole: .support),
            .make(id: 2, authorRole: lastAuthorRole)
        ])

        #expect(conversation.replyAction == .addMoreInfo)
    }

    @Test func offersToReplyWhenSupportIsWaitingForTheUser() {
        let conversation = UnifiedSupportConversation.make(messages: [
            .make(id: 1, authorRole: .user),
            .make(id: 2, authorRole: .support)
        ])

        #expect(conversation.replyAction == .reply)
    }

    @Test func lastActivityIsTheNewestMessageWhenNewerThanUpdatedAt() {
        let newestMessageDate = Date(timeIntervalSince1970: 5_000)
        let conversation = UnifiedSupportConversation.make(
            updatedAt: Date(timeIntervalSince1970: 2_000),
            messages: [
                .make(id: 1, createdAt: Date(timeIntervalSince1970: 1_000)),
                .make(id: 2, createdAt: newestMessageDate)
            ]
        )

        #expect(conversation.lastActivityAt == newestMessageDate)
    }

    @Test func lastActivityIsUpdatedAtWhenNewerThanTheMessages() {
        let updatedAt = Date(timeIntervalSince1970: 2_000)
        let conversation = UnifiedSupportConversation.make(
            updatedAt: updatedAt,
            messages: [.make(createdAt: Date(timeIntervalSince1970: 1_000))]
        )

        #expect(conversation.lastActivityAt == updatedAt)
    }

    @Test func summaryMatchesTheConversation() {
        let conversation = UnifiedSupportConversation.make(
            id: 42,
            title: "Title",
            description: "Description",
            status: .closed,
            canAcceptReply: false,
            messages: [.make()]
        )

        #expect(
            conversation.summary
                == .make(id: 42, title: "Title", description: "Description", status: .closed, canAcceptReply: false)
        )
    }
}
