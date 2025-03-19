import Foundation

extension FormattableContentGroup.Kind {
    public static let text = FormattableContentGroup.Kind("text")
    public static let image = FormattableContentGroup.Kind("image")
    public static let user = FormattableContentGroup.Kind("user")
    public static let comment = FormattableContentGroup.Kind("comment")
    public static let actions = FormattableContentGroup.Kind("actions")
    public static let subject = FormattableContentGroup.Kind("subject")
    public static let header = FormattableContentGroup.Kind("header")
    public static let footer = FormattableContentGroup.Kind("footer")
    public static let button = FormattableContentGroup.Kind("button")
}

// MARK: - FormattableContentGroup: Adapter to match 1 View <> 1 BlockGroup
//
open class FormattableContentGroup {

    public struct Kind: Equatable, Sendable {
        private var rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// Grouped Blocks
    ///
    public let blocks: [FormattableContent]

    public let kind: Kind

    /// Designated Initializer
    ///
    public init(blocks: [FormattableContent], kind: Kind) {
        self.blocks = blocks
        self.kind = kind
    }
}

// MARK: - Helpers Methods
//
extension FormattableContentGroup {

    public func blockOfKind<ContentType: FormattableContent>(_ kind: FormattableContentKind) -> ContentType? {
        return FormattableContentGroup.blockOfKind(kind, from: blocks)
    }

    /// Returns the First Block of a specified kind.
    ///
    public class func blockOfKind<ContentType: FormattableContent>(_ kind: FormattableContentKind, from blocks: [FormattableContent]) -> ContentType? {
        for block in blocks where block.kind == kind {
            return block as? ContentType
        }
        return nil
    }
}
