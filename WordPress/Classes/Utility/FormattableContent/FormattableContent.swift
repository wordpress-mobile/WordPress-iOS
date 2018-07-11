import Foundation

public protocol FormattableContent {
    var text: String? { get }
    var ranges: [FormattableContentRange] { get }
    var parent: FormattableContentParent? { get }
    var actions: [FormattableContentAction]? { get }
    var meta: [String: AnyObject]? { get }
    var kind: FormattableContentKind { get }

    init(dictionary: [String: AnyObject], actions commandActions: [FormattableContentAction], ranges: [FormattableContentRange], parent note: FormattableContentParent)

    func action(id: Identifier) -> FormattableContentAction?
    func isActionEnabled(id: Identifier) -> Bool
    func isActionOn(id: Identifier) -> Bool
}

public struct FormattableContentKind: Equatable, Hashable {
    let rawValue: String
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension FormattableContent {
    public func isActionEnabled(id: Identifier) -> Bool {
        return action(id: id)?.enabled ?? false
    }

    public func isActionOn(id: Identifier) -> Bool {
        return action(id: id)?.on ?? false
    }

    public func action(id: Identifier) -> FormattableContentAction? {
        return actions?.filter {
            $0.identifier == id
        }.first
    }
}
