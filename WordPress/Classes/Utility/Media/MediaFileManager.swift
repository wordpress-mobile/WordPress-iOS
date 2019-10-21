import Foundation
import CocoaLumberjack

/// Type of the local Media directory URL in implementation.
///
enum MediaDirectory {
    /// Default, system Documents directory, for persisting media files for upload.
    case uploads
    /// System Caches directory, for creating discardable media files, such as thumbnails.
    case cache
    /// System temporary directory, used for unit testing or temporary media files.
    case temporary

    /// Returns the directory URL for the directory type.
    ///
    fileprivate var url: URL {
        let fileManager = FileManager.default
        // Get a parent directory, based on the type.
        let parentDirectory: URL
        switch self {
        case .uploads:
            parentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        case .cache:
            parentDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        case .temporary:
            parentDirectory = fileManager.temporaryDirectory
        }
        return parentDirectory.appendingPathComponent(MediaFileManager.mediaDirectoryName, isDirectory: true)
    }
}

/// Encapsulates Media functions relative to the local Media directory.
///
class MediaFileManager: NSObject {

    fileprivate static let mediaDirectoryName = "Media"

    let directory: MediaDirectory

    // MARK: - Class init

    /// The default instance of a MediaFileManager.
    ///
    @objc (defaultManager)
    static let `default`: MediaFileManager = {
        return MediaFileManager()
    }()

    /// Helper method for getting a MediaFileManager for the .cache directory.
    ///
    @objc (cacheManager)
    class var cache: MediaFileManager {
        return MediaFileManager(directory: .cache)
    }

    // MARK: - Init

    /// Init with default directory of .uploads.
    ///
    /// - Note: This is particularly because the original Media directory was in the NSFileManager's documents directory.
    ///   We shouldn't change this default directory lightly as older versions of the app may rely on Media files being in
    ///   the documents directory for upload.
    ///
    init(directory: MediaDirectory = .uploads) {
        self.directory = directory
    }

    // MARK: - Instance methods

    /// Returns filesystem URL for the local Media directory.
    ///
    @objc func directoryURL() throws -> URL {
        let fileManager = FileManager.default
        let mediaDirectory = directory.url
        // Check whether or not the file path exists for the Media directory.
        // If the filepath does not exist, or if the filepath does exist but it is not a directory, try creating the directory.
        // Note: This way, if unexpectedly a file exists but it is not a dir, an error will throw when trying to create the dir.
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: mediaDirectory.path, isDirectory: &isDirectory) == false || isDirectory.boolValue == false {
            try fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return mediaDirectory
    }

    /// Returns a unique filesystem URL for a Media filename and extension, within the local Media directory.
    ///
    /// - Note: if a file already exists with the same name, the file name is appended with a number
    ///   and incremented until a unique filename is found.
    ///
    @objc func makeLocalMediaURL(withFilename filename: String, fileExtension: String?, incremented: Bool = true) throws -> URL {
        let baseURL = try directoryURL()
        var url: URL
        if let fileExtension = fileExtension {
            let basename = (filename as NSString).deletingPathExtension.lowercased()
            url = baseURL.appendingPathComponent(basename, isDirectory: false)
            url.appendPathExtension(fileExtension)
        } else {
            url = baseURL.appendingPathComponent(filename, isDirectory: false)
        }
        // Increment the filename as needed to ensure we're not
        // providing a URL for an existing file of the same name.
        return incremented ? url.incrementalFilename() : url
    }

    /// Objc friendly signature without specifying the `incremented` parameter.
    ///
    @objc func makeLocalMediaURL(withFilename filename: String, fileExtension: String?) throws -> URL {
        return try makeLocalMediaURL(withFilename: filename, fileExtension: fileExtension, incremented: true)
    }

    /// Returns a string appended with the thumbnail naming convention for local Media files.
    ///
    @objc func mediaFilenameAppendingThumbnail(_ filename: String) -> String {
        var filename = filename as NSString
        let pathExtension = filename.pathExtension
        filename = filename.deletingPathExtension.appending("-thumbnail") as NSString
        return filename.appendingPathExtension(pathExtension)!
    }

    /// Returns the size of a Media image located at the file URL, or zero if it doesn't exist.
    ///
    /// - Note: once we drop ObjC, this should be an optional that would return nil instead of zero.
    ///
    @objc func imageSizeForMediaAt(fileURL: URL?) -> CGSize {
        guard let fileURL = fileURL else {
            return CGSize.zero
        }
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) == true, isDirectory.boolValue == false else {
            return CGSize.zero
        }
        guard
            let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? Dictionary<String, AnyObject>
            else {
                return CGSize.zero
        }
        var width = CGFloat(0), height = CGFloat(0)
        if let widthProperty = imageProperties[kCGImagePropertyPixelWidth as String] as? CGFloat {
            width = widthProperty
        }
        if let heightProperty = imageProperties[kCGImagePropertyPixelHeight as String] as? CGFloat {
            height = heightProperty
        }
        return CGSize(width: width, height: height)
    }

    /// Calculates the allocated size of the Media directory, in bytes, or nil if an error was thrown.
    ///
    func calculateSizeOfDirectory(onCompletion: @escaping (Int64?) -> Void) {
        DispatchQueue.global(qos: .default).async {
            let fileManager = FileManager.default
            let allocatedSize = try? fileManager.allocatedSizeOf(directoryURL: self.directoryURL())
            DispatchQueue.main.async {
                onCompletion(allocatedSize)
            }
        }
    }

    /// Clear the local Media directory of any files that are no longer in use or can be fetched again,
    /// such as Media without a blog or with a remote URL.
    ///
    /// - Note: These files can show up because of the app being killed while a media object
    ///   was being created or when a CoreData migration fails and the database is recreated.
    ///
    @objc func clearUnusedFilesFromDirectory(onCompletion: (() -> Void)?, onError: ((Error) -> Void)?) {
        purgeMediaFiles(exceptMedia: NSPredicate(format: "blog != NULL && remoteURL == NULL"),
                        onCompletion: onCompletion,
                        onError: onError)
    }

    /// Clear the local Media directory of any cached media files that are available remotely.
    ///
    @objc func clearFilesFromDirectory(onCompletion: (() -> Void)?, onError: ((Error) -> Void)?) {
        do {
            try purgeDirectory(exceptFiles: [])
            onCompletion?()
        } catch {
            onError?(error)
        }
    }

    // MARK: - Class methods

    /// Helper method for clearing unused Media upload files.
    ///
    @objc class func clearUnusedMediaUploadFiles(onCompletion: (() -> Void)?, onError: ((Error) -> Void)?) {
        MediaFileManager.default.clearUnusedFilesFromDirectory(onCompletion: onCompletion, onError: onError)
    }

    /// Helper method for calculating the size of the Media directories.
    ///
    class func calculateSizeOfMediaDirectories(onCompletion: @escaping (Int64?) -> Void) {
        let cacheManager = MediaFileManager(directory: .cache)
        cacheManager.calculateSizeOfDirectory { (cacheSize) in
            let defaultManager = MediaFileManager.default
            defaultManager.calculateSizeOfDirectory { (mediaSize) in
                onCompletion( (mediaSize ?? 0) + (cacheSize ?? 0) )
            }
        }
    }

    /// Helper method for clearing the Media cache directory.
    ///
    @objc class func clearAllMediaCacheFiles(onCompletion: (() -> Void)?, onError: ((Error) -> Void)?) {
        let cacheManager = MediaFileManager(directory: .cache)
        cacheManager.clearFilesFromDirectory(onCompletion: {
            MediaFileManager.clearUnusedMediaUploadFiles(onCompletion: onCompletion, onError: onError)
        }, onError: onError)
    }

    /// Helper method for getting the default upload directory URL.
    ///
    @objc class func uploadsDirectoryURL() throws -> URL {
        return try MediaFileManager.default.directoryURL()
    }

    // MARK: - Private

    /// Removes any local Media files, except any Media matching the predicate.
    ///
    fileprivate func purgeMediaFiles(exceptMedia predicate: NSPredicate, onCompletion: (() -> Void)?, onError: ((Error) -> Void)?) {
        let context = ContextManager.sharedInstance().newDerivedContext()
        context.perform {
            let fetch = NSFetchRequest<NSDictionary>(entityName: Media.classNameWithoutNamespaces())
            fetch.predicate = predicate
            fetch.resultType = .dictionaryResultType
            let localURLProperty = #selector(getter: Media.localURL).description
            let localThumbnailURLProperty = #selector(getter: Media.localThumbnailURL).description
            fetch.propertiesToFetch = [localURLProperty,
                                       localThumbnailURLProperty]
            do {
                let mediaToKeep = try context.fetch(fetch)
                var filesToKeep: Set<String> = []
                for dictionary in mediaToKeep {
                    if let localPath = dictionary[localURLProperty] as? String,
                        let localURL = URL(string: localPath) {
                        filesToKeep.insert(localURL.lastPathComponent)
                    }
                    if let localThumbnailPath = dictionary[localThumbnailURLProperty] as? String,
                        let localThumbnailURL = URL(string: localThumbnailPath) {
                        filesToKeep.insert(localThumbnailURL.lastPathComponent)
                    }
                }
                try self.purgeDirectory(exceptFiles: filesToKeep)
                if let onCompletion = onCompletion {
                    DispatchQueue.main.async {
                        onCompletion()
                    }
                }
            } catch {
                DDLogError("Error while attempting to clean local media: \(error.localizedDescription)")
                if let onError = onError {
                    DispatchQueue.main.async {
                        onError(error)
                    }
                }
            }
        }
    }

    /// Removes files in the Media directory, except any files found in the set.
    ///
    fileprivate func purgeDirectory(exceptFiles: Set<String>) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: try directoryURL(),
                                                           includingPropertiesForKeys: nil,
                                                           options: .skipsHiddenFiles)
        var removedCount = 0
        for url in contents {
            if exceptFiles.contains(url.lastPathComponent) {
                continue
            }
            if fileManager.fileExists(atPath: url.path) {
                do {
                    try fileManager.removeItem(at: url)
                    removedCount += 1
                } catch {
                    DDLogError("Error while removing unused Media at path: \(error.localizedDescription) - \(url.path)")
                }
            }
        }
        if removedCount > 0 {
            DDLogInfo("Media: removed \(removedCount) file(s) during cleanup.")
        }
    }
}
