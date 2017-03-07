/// Utility extension to track specific data for passing to on to WPAppAnalytics.
public extension WPAppAnalytics {
    /**
     Get a dictionary of tracking properties for a Media object.
     - parameter media: the Media object
     - returns: Dictionary
     */
    public class func properties(for media: Media) -> Dictionary<String, Any> {
        var properties = [String: Any]()
        properties[MediaProperties.mime] = media.mimeType()
        if let fileExtension = media.fileExtension(), !fileExtension.isEmpty {
            properties[MediaProperties.fileExtension] = fileExtension
        }
        if media.mediaType == .image {
            let megaPixels = round((media.width.floatValue * media.height.floatValue) / 1000000)
            properties[MediaProperties.megapixels] = Int(megaPixels)
        } else if media.mediaType == .video {
            properties[MediaProperties.durationSeconds] = media.length
        }
        properties[MediaProperties.bytes] = media.filesize.intValue * 1024
        return properties
    }

    fileprivate struct MediaProperties {
        static let mime = "mime"
        static let fileExtension = "ext"
        static let megapixels = "megapixels"
        static let durationSeconds = "duration_secs"
        static let bytes = "bytes"
    }
}
