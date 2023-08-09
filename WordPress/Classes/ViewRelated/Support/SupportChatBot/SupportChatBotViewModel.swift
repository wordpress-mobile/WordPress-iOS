import Foundation

struct SupportChatHistory: Decodable {
    let messages: [[String]]
}

struct SupportChatBotViewModel {
    let id = "" // TODO: Update ApiCredentials
    let url = Bundle.main.url(forResource: "support_chat_widget", withExtension: "html")

    func contactSupport(including history: SupportChatHistory, completion: @escaping () -> ()) {
        // TODO: Format descriptions
        let messageHistoryDescription = history.messages
            .flatMap { $0 }
            .joined(separator: "\n")

        // TODO: Handle errors
        ZendeskUtils.sharedInstance.createNewRequest(description: messageHistoryDescription, completion: completion)
    }
}
