import Foundation

struct SupportChatHistory: Decodable {
    let messages: [[String]]
}

struct SupportChatBotViewModel {
    let id = "" // TODO: Update ApiCredentials
    let url = Bundle.main.url(forResource: "support_chat_widget", withExtension: "html")

    func contactSupport(including history: SupportChatHistory) {
        // TODO: Pass history to Zendesk
        DDLogInfo("Chat history: \(history)")
    }
}
