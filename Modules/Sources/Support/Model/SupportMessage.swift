import Foundation

public enum SupportMessage: Identifiable, Sendable, Codable, Equatable {

    case welcome
    case botMessage(BotMessage)
    case humanMessage(Message)
    case transferredToSupport

    public var id: String {
        switch self {
        case .welcome: "welcome"
        case .botMessage(let message): String(message.id)
        case .humanMessage(let message): String(message.id)
        case .transferredToSupport: "transferred-to-support"
        }
    }

    public var isBotMessage: Bool {
        switch self {
        case .botMessage: return true
        default: return false
        }
    }

    public var messageText: String? {
        switch self {
        case .welcome: nil
        case .botMessage(let botMessage): botMessage.text
        case .humanMessage(let message): message.plainTextContent
        case .transferredToSupport: nil
        }
    }

    public var createdAt: Date? {
        switch self {
        case .welcome: nil
        case .botMessage(let botMessage): botMessage.date
        case .humanMessage(let message): message.createdAt
        case .transferredToSupport: nil
        }
    }
}

public extension Collection where Element == SupportMessage {

    func botMessages() -> [BotMessage] {
        self.compactMap {
            switch $0 {
            case .botMessage(let message): return message
            default: return nil
            }
        }
    }

    func supportMessages() -> [Message] {
        self.compactMap {
            switch $0 {
            case .humanMessage(let message): return message
            default: return nil
            }
        }
    }

    func transferredToSupportMessage() -> SupportMessage? {
        self.compactMap {
            if case .transferredToSupport = $0 {
                return $0
            } else {
                return nil
            }
        }.first
    }
}
