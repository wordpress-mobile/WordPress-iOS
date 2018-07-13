
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
    var parent: FormattableContentParent?
    var actions: [FormattableContentAction]?
    var meta: [String: AnyObject]?

    private let internalText: String?

    required init(dictionary: [String: AnyObject], actions commandActions: [FormattableContentAction], ranges: [FormattableContentRange], parent note: FormattableContentParent) {

        actions = commandActions
        self.ranges = ranges
        parent = note
        internalText = dictionary[Constants.BlockKeys.Text] as? String
        meta = dictionary[Constants.BlockKeys.Meta] as? [String: AnyObject]
    }

    init(text: String, ranges: [NotificationContentRange]) {
        self.internalText = text
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

private enum Constants {
    fileprivate enum BlockKeys {
        static let Meta         = "meta"
        static let Ranges       = "ranges"
        static let Text         = "text"
    }
}
