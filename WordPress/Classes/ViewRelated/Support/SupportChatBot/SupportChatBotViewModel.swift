import Foundation

struct SupportChatHistory: Decodable {
    let messages: [[String]]
}

struct SupportChatBotViewModel {
    let id = "" // TODO: Update ApiCredentials
    let url = Bundle.main.url(forResource: "support_chat_widget", withExtension: "html")

    func contactSupport(including history: SupportChatHistory, completion: @escaping (Bool) -> ()) {

        let messageHistoryDescription = "DocsBot transcript: \n\n" + history.messages
            .flatMap { $0 }
            .joined(separator: "\n\n")

        ZendeskUtils.sharedInstance.createNewRequest(description: messageHistoryDescription, completion: completion)
    }
}
