import Foundation
import UIKit

extension FormattableContentKind {
    public static let image = FormattableContentKind("image")
    public static let comment = FormattableContentKind("comment")
    public static let user = FormattableContentKind("user")
    public static let button = FormattableContentKind("button")
}

public protocol FormattableMediaContent {
    var textOverride: String? { get }
    var media: [FormattableMediaItem] { get }
    var imageUrls: [URL] { get }

    func buildRangesToImagesMap(_ mediaMap: [URL: UIImage]) -> [NSValue: UIImage]?
}

extension FormattableMediaContent where Self: FormattableContent {
    public var imageUrls: [URL] {
        return media.compactMap {
            guard $0.kind == .image && $0.mediaURL != nil else {
                return nil
            }

            return $0.mediaURL as URL?
        }
    }

    public func buildRangesToImagesMap(_ mediaMap: [URL: UIImage]) -> [NSValue: UIImage]? {
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

public class NotificationTextContent: FormattableTextContent, FormattableMediaContent {
    public var textOverride: String?
    public let media: [FormattableMediaItem]
    public let parent: Notifiable
    public let meta: [String: AnyObject]?

    public override var text: String? {
        return textOverride ?? super.text
    }

    public override var kind: FormattableContentKind {
        if let firstMedia = media.first, firstMedia.kind == .image || firstMedia.kind == .badge {
            return .image
        }

        if let meta,
           let buttonValue = meta[Constants.MetaKeys.Button] as? Bool,
           buttonValue == true {
            return .button
        }

        return super.kind
    }

    init(dictionary: [String: AnyObject], actions commandActions: [FormattableContentAction], ranges: [FormattableContentRange], parent note: Notifiable) {
        let rawMedia = dictionary[Constants.BlockKeys.Media] as? [[String: AnyObject]]
        let text = dictionary[Constants.BlockKeys.Text] as? String ?? ""

        meta = dictionary[Constants.BlockKeys.Meta] as? [String: AnyObject]
        media = FormattableMediaItem.mediaFromArray(rawMedia)
        parent = note

        super.init(text: text, ranges: ranges, actions: commandActions)
    }

    public func formattableContentRangeWithCommentId(_ commentID: NSNumber) -> NotificationContentRange? {
        for range in ranges.compactMap({ $0 as? NotificationCommentRange }) {
            if let commentID = range.commentID, commentID.isEqual(commentID) {
                return range
            }
        }

        return nil
    }

    private static func rangesFrom(_ rawRanges: [[String: AnyObject]]?) -> [FormattableContentRange] {
        let parsed = rawRanges?.compactMap(NotificationContentRangeFactory.contentRange)
        return parsed ?? []
    }
}

private enum Constants {
    fileprivate enum BlockKeys {
        static let Media = "media"
        static let Text = "text"
        static let Meta = "meta"
    }

    fileprivate enum MetaKeys {
        static let Button = "is_mobile_button"
    }
}
