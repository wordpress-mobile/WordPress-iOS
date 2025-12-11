import Foundation
import UniformTypeIdentifiers

@objc
public enum MediaType: UInt {
    case image
    case video
    case document
    case powerpoint
    case audio

    public var stringValue: String {
        switch self {
        case .image:
            return "image"
        case .video:
            return "video"
        case .powerpoint:
            return "powerpoint"
        case .document:
            return "document"
        case .audio:
            return "audio"
        }
    }

    public init(string: String) {
        switch string {
        case "image":
            self = .image
        case "video":
            self = .video
        case "powerpoint":
            self = .powerpoint
        case "audio":
            self = .audio
        default:
            self = .document
        }
    }
}

@objc
public enum MediaRemoteStatus: UInt {
    case sync
    case failed
    case local
    case pushing
    case processing
    case stub
}

public extension Media {
    // MARK: - AutoUpload Failure Count

    static let maxAutoUploadFailureCount = 3

    /// Increments the AutoUpload failure count for this Media object.
    ///
    @objc
    func incrementAutoUploadFailureCount() {
        autoUploadFailureCount = NSNumber(value: autoUploadFailureCount.intValue + 1)
    }

    /// Resets the AutoUpload failure count for this Media object.
    ///
    @objc
    func resetAutoUploadFailureCount() {
        autoUploadFailureCount = 0
    }
    /// Returns true if a new attempt to upload the media will be done later.
    /// Otherwise, false.
    ///
    func willAttemptToUploadLater() -> Bool {
        return autoUploadFailureCount.intValue < Media.maxAutoUploadFailureCount
    }

    /// Returns true if media has any associated post
    ///
    func hasAssociatedPost() -> Bool {
        guard let posts else {
            return false
        }

        return !posts.isEmpty
    }

    /// If `false`, the only course of action is to cancel the upload.
    var canRetry: Bool {
        absoluteLocalURL != nil
    }

    // MARK: - Media Type

    @objc
    var mediaType: MediaType {
        get {
            mediaTypeString.flatMap(MediaType.init) ?? .document
        }
        set {
            mediaTypeString = newValue.stringValue
        }
    }

    /// Returns the MIME type, e.g. "image/png".
    @objc var mimeType: String? {
        guard let fileExtension = self.fileExtension(),
              let type = UTType(filenameExtension: fileExtension),
              let mimeType = type.preferredMIMEType else {
            return "application/octet-stream"
        }
        return mimeType
    }

    func setMediaType(forFilenameExtension filenameExtension: String) {
        let type = UTType(filenameExtension: filenameExtension)
        setMediaType(getMediaType(for: type))
    }

    func setMediaType(forMimeType mimeType: String) {
        var mimeType = mimeType
        if mimeType == "video/videopress" {
            mimeType = "video/mp4"
        }
        setMediaType(getMediaType(for: UTType(mimeType: mimeType)))
    }

    private func setMediaType(_ newType: MediaType) {
        guard self.mediaType != newType else { return }
        self.mediaType = newType
    }

    private func getMediaType(for type: UTType?) -> MediaType {
        type.map(MediaType.init) ?? .document
    }

    // MARK: - Remote Status

    @objc
    var remoteStatus: MediaRemoteStatus {
        get {
            (remoteStatusNumber?.uintValue).flatMap(MediaRemoteStatus.init(rawValue:)) ?? .local
        }
        set {
            remoteStatusNumber = NSNumber(value: newValue.rawValue)
        }
    }

    // MARK: - Media Link

    var link: String {
        get {
            guard let siteURL = self.blog.url,
                let mediaID = self.mediaID else {
                return ""
            }
            return "\(siteURL)/?p=\(mediaID)"
        }
    }
}

private extension MediaType {
    init(type: UTType) {
        if type.conforms(to: .image) {
            self = .image
        } else if type.conforms(to: .video) {
            self = .video
        } else if type.conforms(to: .movie) {
            self = .video
        } else if type.conforms(to: .mpeg4Movie) {
            self = .video
        } else if type.conforms(to: .presentation) {
            self = .powerpoint
        } else if type.conforms(to: .audio) {
            self = .audio
        } else {
            self = .document
        }
    }
}

extension Media: Identifiable {
    public var id: NSManagedObjectID {
        objectID
    }
}
