import Foundation

public struct BotConversation: Identifiable, Codable, Sendable, Hashable {
    public let id: UInt64
    public let title: String
    public let mostRecentMesageDate: Date
    public let userWantsHumanSupport: Bool
    public let messages: [BotMessage]

    public init(id: UInt64, title: String, mostRecentMessageDate: Date, messages: [BotMessage]) {
        self.id = id
        self.title = title
        self.mostRecentMesageDate = mostRecentMessageDate
        self.messages = messages
        self.userWantsHumanSupport = messages.contains(where: { $0.userWantsToTalkToHuman })
    }

    public func appending(messages newMessages: [BotMessage]) -> Self {
        BotConversation(
            id: self.id,
            title: self.title,
            mostRecentMessageDate: self.mostRecentMesageDate,
            messages: (self.messages + newMessages).sorted(by: { lhs, rhs in
                lhs.date < rhs.date
            })
        )
    }
}
