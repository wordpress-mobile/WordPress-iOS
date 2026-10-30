import Foundation
import Support
import WordPressShared

/// Tracks the unified support events with the existing support events.
///
/// Events about AI Assistant conversations and the conversations list use `supportChatbot`, since every conversation
/// starts with the AI Assistant. Events about tickets use `supportTickets`. All events have a `flow` property set to
/// `unified` to tell them apart from the separate bot and ticket screens.
struct WpUnifiedSupportTracker: UnifiedSupportTracker {

    func track(_ event: UnifiedSupportEvent) {
        switch event {
        case .viewConversationList:
            track(.supportChatbot, subaction: "view-list")
        case .viewConversation(let id, let isBot):
            track(
                isBot ? .supportChatbot : .supportTickets,
                subaction: "view-conversation",
                properties: [
                    "conversation_id": id
                ]
            )
        case .startBotConversation:
            track(.supportChatbot, subaction: "start-conversation")
        case .sendBotMessage(let id):
            track(
                .supportChatbot,
                subaction: "reply-to-conversation",
                properties: [
                    "conversation_id": id
                ]
            )
        case .replyToTicket(let id, let attachmentCount, let includesApplicationLogs):
            track(
                .supportTickets,
                subaction: "reply-to-ticket",
                properties: [
                    "conversation_id": id,
                    "attachment_count": attachmentCount,
                    "includes_application_logs": includesApplicationLogs
                ]
            )
        case .escalateConversation(let id):
            track(
                .supportChatbot,
                subaction: "escalate-conversation",
                properties: [
                    "conversation_id": id
                ]
            )
        case .failToLoadConversations(let error):
            track(
                .supportChatbot,
                subaction: "error-loading-list",
                properties: [
                    "error": error.localizedDescription
                ]
            )
        case .failToLoadConversation(let id, let error):
            track(
                .supportChatbot,
                subaction: "error-loading-conversation",
                properties: [
                    "conversation_id": id,
                    "error": error.localizedDescription
                ]
            )
        case .failToSendMessage(.none, _, let error):
            track(
                .supportChatbot,
                subaction: "error-starting-conversation",
                properties: [
                    "error": error.localizedDescription
                ]
            )
        case .failToSendMessage(.some(let id), let isBot, let error):
            track(
                isBot ? .supportChatbot : .supportTickets,
                subaction: isBot ? "error-replying-to-conversation" : "error-replying-to-ticket",
                properties: [
                    "conversation_id": id,
                    "error": error.localizedDescription
                ]
            )
        }
    }

    private func track(_ event: WPAnalyticsEvent, subaction: String, properties: [String: Any] = [:]) {
        var properties = properties
        properties["subaction"] = subaction
        properties["flow"] = "unified"
        WPAnalytics.track(event, properties: properties)
    }
}
