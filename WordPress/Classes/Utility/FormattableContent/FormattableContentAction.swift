
/// Protocol to help transition from NotificationBlock to FormattableObject
protocol ActionableObject: AnyObject {
    var notificationID: String? { get }
    var metaSiteID: NSNumber? { get }
    var metaCommentID: NSNumber? { get }
    var isCommentApproved: Bool { get }
    var text: String? { get }
    var textOverride: String? { get set }
    func action(id: Identifier) -> FormattableContentAction?
}

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

extension Identifier: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}


typealias ActionContextRequest = (NotificationDeletionRequest?, Bool) -> Void
struct ActionContext {
    let block: ActionableObject
    let content: String
    let completion: ActionContextRequest?

    init(block: ActionableObject, content: String = "", completion: ActionContextRequest? = nil) {
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

    func execute(context: ActionContext)
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
