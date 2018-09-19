
protocol FormattableContentActionParser {
    func parse(_ dictionary: [String: AnyObject]?) -> [FormattableContentAction]
}

/// Used by both NotificationsViewController and NotificationDetailsViewController.
///
public enum NotificationDeletionKind {
    case spamming
    case deletion

    public var legendText: String {
        switch self {
        case .deletion:
            return NSLocalizedString("Comment has been deleted", comment: "Displayed when a Comment is deleted")
        case .spamming:
            return NSLocalizedString("Comment has been marked as Spam", comment: "Displayed when a Comment is spammed")
        }
    }
}

public struct NotificationDeletionRequest {
    public let kind: NotificationDeletionKind
    public let action: (_ completion: @escaping ((Bool) -> Void)) -> Void
    public init(kind: NotificationDeletionKind, action: @escaping (_ completion: @escaping ((Bool) -> Void)) -> Void) {
        self.kind = kind
        self.action = action
    }
}

public struct Identifier: Equatable, Hashable {
    private let rawValue: String

    public init(value: String) {
        rawValue = value
    }
}

extension Identifier: Comparable {
    public static func < (lhs: Identifier, rhs: Identifier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension Identifier: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}

extension Identifier {
    static func empty() -> Identifier {
        return Identifier(value: "")
    }
}

typealias ActionContextRequest = (NotificationDeletionRequest?, Bool) -> Void
struct ActionContext<ContentType: FormattableContent> {
    let block: ContentType
    let content: String
    let completion: ActionContextRequest?

    init(block: ContentType, content: String = "", completion: ActionContextRequest? = nil) {
        self.block = block
        self.content = content
        self.completion = completion
    }
}

protocol FormattableContentAction: CustomStringConvertible {

    var identifier: Identifier { get }
    var enabled: Bool { get }
    var on: Bool { get }
    var command: FormattableContentActionCommand? { get }

    func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>)
}

extension FormattableContentAction {
    public var description: String {
        return identifier.description + "enabled \(enabled)"
    }
}

extension FormattableContentAction {
    public static func actionIdentifier() -> Identifier {
        return Identifier(value: String(describing: self))
    }
}
