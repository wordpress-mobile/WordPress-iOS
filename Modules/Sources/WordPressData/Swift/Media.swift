import CocoaLumberjackSwift
import CoreData
import Foundation
import UniformTypeIdentifiers

@objc(Media)
public class Media: NSManagedObject {

    // MARK: - Managed Properties

    @NSManaged public var alt: String?
    @NSManaged public var caption: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var desc: String?
    @NSManaged public var filename: String?
    @NSManaged public var filesize: NSNumber?
    @NSManaged public var formattedSize: String?
    @NSManaged public var height: NSNumber?
    @NSManaged public var length: NSNumber?
    @NSManaged public var localThumbnailURL: String?
    @NSManaged public var localURL: String?
    @NSManaged public var mediaID: NSNumber?
    @NSManaged public var mediaTypeString: String?
    @NSManaged public var postID: NSNumber?
    @NSManaged public var remoteStatusNumber: NSNumber?
    @NSManaged public var remoteThumbnailURL: String?
    @NSManaged public var remoteURL: String?
    @NSManaged public var remoteLargeURL: String?
    @NSManaged public var remoteMediumURL: String?
    @NSManaged public var shortcode: String?
    @NSManaged public var title: String?
    @NSManaged public var videopressGUID: String?
    @NSManaged public var width: NSNumber?
    @NSManaged public var autoUploadFailureCount: NSNumber

    // MARK: - Relationships

    @NSManaged public var blog: Blog
    @NSManaged public var posts: Set<AbstractPost>?

    // MARK: - Generated Accessors

    @objc(addPostsObject:)
    @NSManaged public func addPostsObject(_ value: AbstractPost)

    @objc(removePostsObject:)
    @NSManaged public func removePostsObject(_ value: AbstractPost)

    @objc(addPosts:)
    @NSManaged public func addPosts(_ values: NSSet)

    @objc(removePosts:)
    @NSManaged public func removePosts(_ values: NSSet)

    // MARK: - Error (Custom Setter for Secure Coding)

    @objc public var error: NSError? {
        get {
            willAccessValue(forKey: "error")
            let value = primitiveValue(forKey: "error") as? NSError
            didAccessValue(forKey: "error")
            return value
        }
        set {
            var sanitizedError = newValue
            if let error = newValue {
                // Cherry pick keys that support secure coding. NSErrors thrown
                // from the OS can contain types that don't adopt NSSecureCoding,
                // leading to a Core Data exception and crash.
                let userInfo = [NSLocalizedDescriptionKey: error.localizedDescription]
                sanitizedError = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
            }
            willChangeValue(forKey: "error")
            setPrimitiveValue(sanitizedError, forKey: "error")
            didChangeValue(forKey: "error")
        }
    }

    // MARK: - Computed Properties

    /// Local file URL for the Media's asset (image, video, gif, or other file).
    @objc public var absoluteLocalURL: URL? {
        get {
            guard let localURL, !localURL.isEmpty else { return nil }
            return absoluteURL(forLocalPath: localURL, cacheDirectory: false)
        }
        set {
            localURL = newValue?.lastPathComponent
        }
    }

    /// Local file URL for a preprocessed thumbnail.
    ///
    /// - warning: Deprecated. Use ``MediaImageService`` to access thumbnails.
    @objc public var absoluteThumbnailLocalURL: URL? {
        get {
            guard let localThumbnailURL, !localThumbnailURL.isEmpty else { return nil }
            return absoluteURL(forLocalPath: localThumbnailURL, cacheDirectory: true)
        }
        set {
            localThumbnailURL = newValue?.lastPathComponent
        }
    }

    /// Returns `true` if the media object already exists on the server.
    @objc public var hasRemote: Bool {
        guard let mediaID else {
            return false
        }
        return mediaID != 0
    }

    // MARK: - Methods

    @objc public func fileExtension() -> String? {
        if let ext = (filename as NSString?)?.pathExtension, !ext.isEmpty {
            return ext
        }
        if let ext = (localURL as NSString?)?.pathExtension, !ext.isEmpty {
            return ext
        }
        return (remoteURL as NSString?)?.pathExtension
    }

    // MARK: - Core Data Lifecycle

    public override func prepareForDeletion() {
        let fileManager = FileManager.default
        if let path = absoluteLocalURL?.path, fileManager.fileExists(atPath: path) {
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                DDLogInfo("Error removing media file: \(error)")
            }
        }
        if let path = absoluteThumbnailLocalURL?.path, fileManager.fileExists(atPath: path) {
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                DDLogInfo("Error removing media file: \(error)")
            }
        }
        super.prepareForDeletion()
    }

    // MARK: - Private

    private func absoluteURL(forLocalPath localPath: String, cacheDirectory: Bool) -> URL? {
        do {
            let mediaDirectory: URL
            if cacheDirectory {
                mediaDirectory = try MediaFileManager.cache.directoryURL()
            } else {
                mediaDirectory = try MediaFileManager.uploadsDirectoryURL()
            }
            return mediaDirectory.appendingPathComponent((localPath as NSString).lastPathComponent)
        } catch {
            DDLogInfo("Error resolving Media directory: \(error)")
            return nil
        }
    }
}

// MARK: - MediaType

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

// MARK: - MediaRemoteStatus

@objc
public enum MediaRemoteStatus: UInt {
    case sync
    case failed
    case local
    case pushing
    case processing
    case stub
}

// MARK: - Media Extensions

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
    var hasAssociatedPost: Bool {
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
