import Foundation

struct SupportChatBotViewModel {
    private let zendeskUtils: ZendeskUtilsProtocol

    let id = "" // TODO: Update ApiCredentials
    let url = Bundle.main.url(forResource: "support_chat_widget", withExtension: "html")

    init(zendeskUtils: ZendeskUtilsProtocol = ZendeskUtils.sharedInstance) {
        self.zendeskUtils = zendeskUtils
    }

    func contactSupport(including history: SupportChatHistory, completion: @escaping (Bool) -> ()) {
        let messageHistoryDescription = "Jetpack Mobile Bot transcript:\n>\n" + history.messages
            .map { "Question:\n>\n\($0.question)\n>\nAnswer:\n>\n\($0.answer)" }
            .joined(separator: "\n>\n")

        zendeskUtils.createNewRequest(
            description: messageHistoryDescription,
            tags: ["DocsBot"],
            completion: completion
        )
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
