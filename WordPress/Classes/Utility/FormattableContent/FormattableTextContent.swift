
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


    private static func rangesFrom(_ rawRanges: [[String: AnyObject]]?) -> [FormattableContentRange] {
        let parsed = rawRanges?.compactMap(NotificationContentRangeFactory.contentRange)
        return parsed ?? []
    }
}

extension FormattableMediaItem {
    fileprivate enum MediaKeys {
        static let RawType      = "type"
        static let URL          = "url"
        static let Indices      = "indices"
        static let Width        = "width"
        static let Height       = "height"
    }
}
