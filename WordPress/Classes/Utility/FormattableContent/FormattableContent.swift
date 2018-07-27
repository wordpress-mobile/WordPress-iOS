import Foundation

protocol FormattableContent {
    var text: String? { get }
    var ranges: [FormattableContentRange] { get }
    var actions: [FormattableContentAction]? { get }
    var meta: [String: AnyObject]? { get }
    var kind: FormattableContentKind { get }

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

    func range(with url: URL) -> FormattableContentRange? {
        let linkRanges = ranges.compactMap { $0 as? LinkContentRange }
        for range in linkRanges {
            if range.url == url {
                return range as? FormattableContentRange
            }
        }

        return nil
    }
}
