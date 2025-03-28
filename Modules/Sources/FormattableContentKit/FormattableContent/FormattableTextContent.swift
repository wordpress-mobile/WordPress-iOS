import Foundation

extension FormattableContentKind {
    public static let text = FormattableContentKind("text")
}

public class FormattableTextContent: FormattableContent {
    public var kind: FormattableContentKind {
        return .text
    }

    public var text: String? {
        return internalText
    }

    public let ranges: [FormattableContentRange]
    public var actions: [FormattableContentAction]?

    private let internalText: String?

    public init(text: String, ranges: [FormattableContentRange], actions commandActions: [FormattableContentAction]? = nil) {
        internalText = text
        actions = commandActions
        self.ranges = ranges
    }
}
