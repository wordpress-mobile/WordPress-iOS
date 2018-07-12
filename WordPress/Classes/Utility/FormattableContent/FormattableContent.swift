import Foundation

protocol FormattableContent {
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

struct FormattableContentKind: Equatable, Hashable {
    let rawValue: String
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension FormattableContent {
    func isActionEnabled(id: Identifier) -> Bool {
        return action(id: id)?.enabled ?? false
    }

    func isActionOn(id: Identifier) -> Bool {
        return action(id: id)?.on ?? false
    }

    func action(id: Identifier) -> FormattableContentAction? {
        return actions?.filter {
            $0.identifier == id
        }.first
    }
}
