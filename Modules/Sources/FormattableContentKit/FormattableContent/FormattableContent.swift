import Foundation

public protocol FormattableContent {
    var text: String? { get }
    var ranges: [FormattableContentRange] { get }
    var actions: [FormattableContentAction]? { get }
    var kind: FormattableContentKind { get }

    func action(id: Identifier) -> FormattableContentAction?
    func isActionEnabled(id: Identifier) -> Bool
    func isActionOn(id: Identifier) -> Bool
}

public struct FormattableContentKind: Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension FormattableContent {
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

    public func range(with url: URL) -> FormattableContentRange? {
        let linkRanges = ranges.compactMap { $0 as? LinkContentRange }
        for range in linkRanges {
            if range.url == url {
                return range as? FormattableContentRange
            }
        }

        return nil
    }
}
