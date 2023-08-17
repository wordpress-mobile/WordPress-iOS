import Foundation

struct SupportChatBotViewModel {
    private let zendeskUtils: ZendeskUtilsProtocol

    let id = ApiCredentials.docsBotId
    let url = Bundle.main.url(forResource: "support_chat_widget", withExtension: "html")

    init(zendeskUtils: ZendeskUtilsProtocol = ZendeskUtils.sharedInstance) {
        self.zendeskUtils = zendeskUtils
    }

    func contactSupport(including history: SupportChatHistory, completion: @escaping (Bool) -> ()) {
        zendeskUtils.createNewRequest(
            description: formattedMessageHistory(from: history),
            tags: ["DocsBot"],
            completion: completion
        )
    }

    private func formattedMessageHistory(from history: SupportChatHistory) -> String {
        let transcript = NSLocalizedString("support.chatBot.zendesk.transcript",
                                           value: "Jetpack Mobile Bot transcript",
                                           comment: "A title for a text that displays a transcript from a conversation between Jetpack Mobile Bot (chat bot) and a user")

        let question = NSLocalizedString("support.chatBot.zendesk.question",
                                         value: "Question",
                                         comment: "A title for a text that displays a transcript of user's question in a support chat")

        let answer = NSLocalizedString("support.chatBot.zendesk.answer",
                                       value: "Answer",
                                       comment: "A title for a text that displays a transcript of an answer in a support chat")

        let messageHistoryDescription = "\(transcript):\n>\n" + history.messages
            .map { "\(question):\n>\n\($0.question)\n>\n\(answer):\n>\n\($0.answer)" }
            .joined(separator: "\n>\n")

        return messageHistoryDescription
    }
}

// MARK: - SupportChatHistory

struct SupportChatHistory {
    struct Message {
        let question: String
        let answer: String
    }

    let messages: [Message]

    init(messageHistory: [[String]]) {
        var messages: [Message] = []
        for message in messageHistory {
            messages.append(Message(
                question: message.first ?? "",
                answer: message.last ?? ""
            ))
        }

        self.messages = messages
    }

    init(messages: [Message]) {
        self.messages = messages
    }
}
