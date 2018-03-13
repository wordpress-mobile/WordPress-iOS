/// Utility extension to track specific data for passing to on to WPAppAnalytics.
public extension WPAppAnalytics {

    /// Get a dictionary of tracking properties for a Media object with the media selection method.
    ///
    /// - Parameters:
    ///     - media: The Media object.
    ///     - selectionMethod: The Media's method of selection.
    /// - Returns: Dictionary
    ///
    public class func properties(for media: Media, selectionMethod: MediaSelectionMethod) -> [String: Any] {
        var properties = WPAppAnalytics.properties(for: media)
        properties[MediaOriginKey] = String(describing: selectionMethod)
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

public struct MediaAnalyticsInfo {
    let origin: MediaUploadOrigin
    let selectionMethod: MediaSelectionMethod?

    init(origin: MediaUploadOrigin, selectionMethod: MediaSelectionMethod? = nil) {
        self.origin = origin
        self.selectionMethod = selectionMethod
    }

    func eventForMediaType(_ mediaType: MediaType) -> WPAnalyticsStat? {
        return origin.eventForMediaType(mediaType)
    }

    var retryEvent: WPAnalyticsStat? {
        switch origin {
        case .mediaLibrary:
            return .mediaLibraryUploadMediaRetried
        case .editor:
            return .editorUploadMediaRetried
        }
    }

    func properties(for media: Media) -> [String: Any] {
        guard let selectionMethod = selectionMethod else {
            return WPAppAnalytics.properties(for: media)
        }

        return WPAppAnalytics.properties(for: media, selectionMethod: selectionMethod)
    }
}

/// Used for analytics to identify how the media was selected by the user.
///
public enum MediaSelectionMethod: CustomStringConvertible {
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

/// Used for analytics to track where an upload was started within the app.
///
enum MediaUploadOrigin {
    case mediaLibrary
    case editor(MediaSource)

    func eventForMediaType(_ mediaType: MediaType) -> WPAnalyticsStat? {
        switch (self, mediaType) {
        case (.mediaLibrary, .image):
            return .mediaLibraryAddedPhoto
        case (.mediaLibrary, .video):
            return .mediaLibraryAddedVideo
        case (.editor(let source), .image) where source == .deviceLibrary:
            return .editorAddedPhotoViaLocalLibrary
        case (.editor(let source), .image) where source == .wpMediaLibrary:
            return .editorAddedPhotoViaWPMediaLibrary
        case (.editor(let source), .image) where source == .otherApps:
            return .editorAddedPhotoViaOtherApps
        case (.editor(let source), .video) where source == .deviceLibrary:
            return .editorAddedVideoViaLocalLibrary
        case (.editor(let source), .video) where source == .wpMediaLibrary:
            return .editorAddedVideoViaWPMediaLibrary
        case (.editor(let source), .video) where source == .otherApps:
            return .editorAddedVideoViaOtherApps
        default: return nil
        }
    }
}

/// Used for analytics to track the source of a media item
///
enum MediaSource {
    case none
    case deviceLibrary
    case otherApps
    case wpMediaLibrary
}
