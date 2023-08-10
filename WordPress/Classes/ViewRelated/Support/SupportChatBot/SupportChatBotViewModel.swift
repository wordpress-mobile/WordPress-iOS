import Foundation

struct SupportChatHistory {
    struct SupportChatMessage {
        let question: String
        let answer: String
    }

    let messages: [SupportChatMessage]

    init(messageHistory: [[String]]) {
        var messages: [SupportChatMessage] = []
        for message in messageHistory {
            messages.append(SupportChatMessage(
                question: message.first ?? "",
                answer: message.last ?? ""
            ))
        }

        self.messages = messages
    }
}

struct SupportChatBotViewModel {
    let id = "" // TODO: Update ApiCredentials
    let url = Bundle.main.url(forResource: "support_chat_widget", withExtension: "html")

    func contactSupport(including history: SupportChatHistory, completion: @escaping (Bool) -> ()) {
        let messageHistoryDescription = "Jetpack Mobile Bot transcript:\n>\n" + history.messages
            .map { "Question:\n>\n \($0.question)\n>\nAnswer:\n>\n \($0.answer)" }
            .joined(separator: "\n>\n")

        ZendeskUtils.sharedInstance.createNewRequest(
            description: messageHistoryDescription,
            tags: ["DocsBot"],
            completion: completion
        )
    }
}
