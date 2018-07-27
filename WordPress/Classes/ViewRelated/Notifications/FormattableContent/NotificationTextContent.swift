
import Foundation

extension FormattableContentKind {
    static let image = FormattableContentKind("image")
    static let comment = FormattableContentKind("comment")
    static let user = FormattableContentKind("user")
}

protocol FormattableMediaContent {
    var textOverride: String? { get }
    var media: [FormattableMediaItem] { get }
    var imageUrls: [URL] { get }

    func buildRangesToImagesMap(_ mediaMap: [URL: UIImage]) -> [NSValue: UIImage]?
}

extension FormattableMediaContent where Self: FormattableContent {
    var imageUrls: [URL] {
        return media.compactMap {
            guard $0.kind == .image && $0.mediaURL != nil else {
                return nil
            }

            return $0.mediaURL as URL?
        }
    }

    func buildRangesToImagesMap(_ mediaMap: [URL: UIImage]) -> [NSValue: UIImage]? {
        guard textOverride == nil else {
            return nil
        }

        var ranges = [NSValue: UIImage]()

        for theMedia in media {
            guard let mediaURL = theMedia.mediaURL else {
                continue
            }

            if let image = mediaMap[mediaURL as URL] {
                let rangeValue = NSValue(range: theMedia.range)
                ranges[rangeValue] = image
            }
        }

        return ranges
    }
}

class NotificationTextContent: FormattableTextContent, FormattableMediaContent {
    var textOverride: String?
    let media: [FormattableMediaItem]
    let parent: Notification
    let meta: [String: AnyObject]?

    override var text: String? {
        return textOverride ?? super.text
    }

    override var kind: FormattableContentKind {
        if let firstMedia = media.first, (firstMedia.kind == .image || firstMedia.kind == .badge) {
            return .image
        }
        return .text
    }

    init(dictionary: [String: AnyObject], actions commandActions: [FormattableContentAction], ranges: [FormattableContentRange], parent note: Notification) {
        let rawMedia = dictionary[Constants.BlockKeys.Media] as? [[String: AnyObject]]
        let text = dictionary[Constants.BlockKeys.Text] as? String ?? ""

        meta = dictionary[Constants.BlockKeys.Meta] as? [String: AnyObject]
        media = FormattableMediaItem.mediaFromArray(rawMedia)
        parent = note

        super.init(text: text, ranges: ranges, actions: commandActions)
    }

    func formattableContentRangeWithCommentId(_ commentID: NSNumber) -> NotificationContentRange? {
        for range in ranges.compactMap({ $0 as? NotificationCommentRange }) {
            if let commentID = range.commentID, commentID.isEqual(commentID) {
                return range
            }
        }

        return nil
    }
}

private enum Constants {
    fileprivate enum BlockKeys {
        static let Media = "media"
        static let Text = "text"
        static let Meta = "meta"
    }
}
