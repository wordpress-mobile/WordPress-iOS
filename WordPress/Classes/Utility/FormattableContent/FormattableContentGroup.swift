import Foundation

// MARK: - FormattableContentGroup: Adapter to match 1 View <> 1 BlockGroup
//
open class FormattableContentGroup {

    public struct Kind: Equatable {
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
