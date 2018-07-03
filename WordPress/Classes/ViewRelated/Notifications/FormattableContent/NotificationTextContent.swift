
import Foundation

protocol FormattableMediaContent {
    var textOverride: String? { get }
    var media: [FormattableMediaItem] { get }
    var imageUrls: [URL]  { get }

    func buildRangesToImagesMap(_ mediaMap: [URL: UIImage]) -> [NSValue: UIImage]?
}

extension FormattableMediaContent where Self: FormattableContent {
    var imageUrls: [URL] {
        return media.compactMap {
            guard $0.kind == .Image && $0.mediaURL != nil else {
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
                let rangeValue      = NSValue(range: theMedia.range)
                ranges[rangeValue]  = image
            }
        }

        return ranges
    }
}

class NotificationTextContent: FormattableTextContent, FormattableMediaContent {
    var textOverride: String?
    let media: [FormattableMediaItem]
    override var type: String? {
        if let firstMedia = media.first, (firstMedia.kind == .Image || firstMedia.kind == .Badge) {
            return "image"
        }
        return "text"
    }
    required init(dictionary: [String : AnyObject], actions commandActions: [FormattableContentAction], parent note: FormattableContentParent) {
        let rawMedia = dictionary[Constants.BlockKeys.Media] as? [[String: AnyObject]]
        media = FormattableMediaItem.mediaFromArray(rawMedia)
        super.init(dictionary: dictionary, actions: commandActions, parent: note)
    }
}

class NotificationMediaContent: FormattableTextContent {

    let media: [FormattableMediaItem]
    var textOverride: String?
    var imageUrls: [URL] {
        return media.compactMap {
            guard $0.kind == .Image && $0.mediaURL != nil else {
                return nil
            }

            return $0.mediaURL as URL?
        }
    }

    required init(dictionary: [String : AnyObject], actions commandActions: [FormattableContentAction], parent note: FormattableContentParent) {
        let rawMedia = dictionary[Constants.BlockKeys.Media] as? [[String: AnyObject]]
        media = FormattableMediaItem.mediaFromArray(rawMedia)
        super.init(dictionary: dictionary, actions: commandActions, parent: note)
    }
}

private enum Constants {
    fileprivate enum BlockKeys {
        static let Media = "media"
    }
}
