import CoreData

extension BasePost {
    /// The default value of `BasePost.postID` as defined in the Core Data model.
    static let defaultPostIDValue: Int = -1

    // We can't use #keyPath on a non-@objc property, and we can't expose
    // status to Objc-C since it returns an optional enum.
    // I'd prefer #keyPath over a string constant, but the enum brings way more value.
    static let statusKeyPath = "status"
    var status: Status? {
        get {
            return rawValue(forKey: BasePost.statusKeyPath)
        }
        set {
            setRawValue(newValue, forKey: BasePost.statusKeyPath)
        }
    }

    /// For Obj-C compatibility only
    @objc(status)
    var statusString: String? {
        get {
            return status?.rawValue
        }
        set {
            status = newValue.flatMap({ Status(rawValue: $0) })
        }
    }

    enum Status: String {
        case draft = "draft"
        case pending = "pending"
        case publishPrivate = "private"
        case publish = "publish"
        case scheduled = "future"
        case trash = "trash"
        case deleted = "deleted" // Returned by wpcom REST API when a post is permanently deleted.
    }

    @objc var featuredImageURL: URL? {
        guard let pathForDisplayImage = pathForDisplayImage,
            let url = URL(string: pathForDisplayImage) else {
            return nil
        }

        return fixedMediaLocalURL(url: url)
    }

    /// In case of an app migration, the UUID of local paths can change.
    /// This method returns the correct path for a given file URL.
    ///
    private func fixedMediaLocalURL(url: URL) -> URL? {
        guard url.isFileURL else {
            return url
        }

        if let mediaCache = try? MediaFileManager.cache.directoryURL().appendingPathComponent(url.lastPathComponent) {
            if FileManager.default.fileExists(atPath: mediaCache.path) {
                return mediaCache
            }
        }

        if let mediaDocument = try? MediaFileManager.default.directoryURL().appendingPathComponent(url.lastPathComponent) {
            if FileManager.default.fileExists(atPath: mediaDocument.path) {
                return mediaDocument
            }
        }

        return nil
    }
}

extension Sequence where Iterator.Element == BasePost.Status {
    var strings: [String] {
        return map({ $0.rawValue })
    }
}
