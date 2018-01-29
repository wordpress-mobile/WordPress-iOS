/// Utility extension to track specific data for passing to on to WPAppAnalytics.
public extension WPAppAnalytics {

    /// Used to identify where the selected media came from
    ///
    public enum SelectedMediaOrigin: CustomStringConvertible {
        case inlinePicker
        case fullScreenPicker
        case documentPicker
        case mediaUploadWritePost
        case none

        public var description: String {
            switch self {
            case .inlinePicker: return "inline_picker"
            case .fullScreenPicker: return "full_screen_picker"
            case .documentPicker: return "document_picker"
            case .mediaUploadWritePost: return "media_write_post"
            case .none: return "not_identified"
            }
        }
    }

    /// Get a dictionary of tracking properties for a Media object with the selected media origin.
    ///
    /// - Parameters:
    ///     - media: The Media object.
    ///     - mediaOrigin: The Media's origin.
    /// - Returns: Dictionary
    ///
    public class func properties(for media: Media, mediaOrigin: SelectedMediaOrigin) -> Dictionary<String, Any> {
        var properties = WPAppAnalytics.properties(for: media)
        properties[MediaOriginKey] = String(describing: mediaOrigin)
        return properties
    }

    /**
     Get a dictionary of tracking properties for a Media object.
     - parameter media: the Media object
     - returns: Dictionary
     */
    @objc public class func properties(for media: Media) -> Dictionary<String, Any> {
        var properties = [String: Any]()
        properties[MediaProperties.mime] = media.mimeType()
        if let fileExtension = media.fileExtension(), !fileExtension.isEmpty {
            properties[MediaProperties.fileExtension] = fileExtension
        }
        if media.mediaType == .image {
            if let width = media.width, let height = media.height {
                let megaPixels = round((width.floatValue * height.floatValue) / 1000000)
                properties[MediaProperties.megapixels] = Int(megaPixels)
            }
        } else if media.mediaType == .video {
            properties[MediaProperties.durationSeconds] = media.length
        }
        if let filesize = media.filesize {
            properties[MediaProperties.bytes] = filesize.int64Value * 1024
        }
        return properties
    }

    fileprivate struct MediaProperties {
        static let mime = "mime"
        static let fileExtension = "ext"
        static let megapixels = "megapixels"
        static let durationSeconds = "duration_secs"
        static let bytes = "bytes"
    }

    fileprivate static let MediaOriginKey = "media_origin"
}
