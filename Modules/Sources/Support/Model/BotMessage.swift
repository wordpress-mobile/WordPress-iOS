import Foundation

public struct BotMessage: Identifiable, Codable, Sendable, Hashable {
    public let id: UInt64

    public let text: String
    public let attributedText: AttributedString

    public let date: Date

    public let userWantsToTalkToHuman: Bool
    public let isWrittenByUser: Bool

    public init(id: UInt64, text: String, date: Date, userWantsToTalkToHuman: Bool, isWrittenByUser: Bool) {
        self.id = id
        self.text = text
        self.attributedText = convertMarkdownTextToAttributedString(text)

        self.date = date
        self.userWantsToTalkToHuman = userWantsToTalkToHuman
        self.isWrittenByUser = isWrittenByUser
    }

    var formattedTime: String {
        if self.date.isToday {
            DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        } else {
            DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
        }
    }
}
