import Foundation

extension FormattableContentGroup.Kind {
    static let text = FormattableContentGroup.Kind("text")
    static let image = FormattableContentGroup.Kind("image")
    static let user = FormattableContentGroup.Kind("user")
    static let comment = FormattableContentGroup.Kind("comment")
    static let actions = FormattableContentGroup.Kind("actions")
    static let subject = FormattableContentGroup.Kind("subject")
    static let header = FormattableContentGroup.Kind("header")
    static let footer = FormattableContentGroup.Kind("footer")
}

// MARK: - FormattableContentGroup: Adapter to match 1 View <> 1 BlockGroup
//
class FormattableContentGroup {

    struct Kind: Equatable {
        private var rawValue: String
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// Grouped Blocks
    ///
    let blocks: [FormattableContent]

    let kind: Kind

    /// Designated Initializer
    ///
    init(blocks: [FormattableContent], kind: Kind) {
        self.blocks = blocks
        self.kind = kind
    }
}

// MARK: - Helpers Methods
//
extension FormattableContentGroup {

    func blockOfKind<ContentType: FormattableContent>(_ kind: FormattableContentKind) -> ContentType? {
        return FormattableContentGroup.blockOfKind(kind, from: blocks)
    }

    /// Returns the First Block of a specified kind.
    ///
    class func blockOfKind<ContentType: FormattableContent>(_ kind: FormattableContentKind, from blocks: [FormattableContent]) -> ContentType? {
        for block in blocks where block.kind == kind {
            return block as? ContentType
        }
        return nil
    }
}
