
import Foundation

extension FormattableContentKind {
    static let text = FormattableContentKind("text")
}

class FormattableTextContent: FormattableContent {
    var kind: FormattableContentKind {
        return .text
    }

    var text: String? {
        return internalText
    }

    let ranges: [FormattableContentRange]
    var actions: [FormattableContentAction]?

    private let internalText: String?

    init(text: String, ranges: [FormattableContentRange], actions commandActions: [FormattableContentAction]? = nil) {
        internalText = text
        actions = commandActions
        self.ranges = ranges
    }
}
