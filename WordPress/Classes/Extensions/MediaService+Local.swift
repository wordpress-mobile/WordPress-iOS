import Foundation
import ImageIO

/// Encapsulates Media functions relative to the local Media directory.
///
extension MediaService {

    fileprivate static let mediaDirectoryName = "Media"

    // MARK: - Class methods

    /// Returns filesystem URL for the local Media directory.
    ///
    class func localMediaDirectory() throws -> URL {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var media = documents.appendingPathComponent(mediaDirectoryName, isDirectory: true)

        // Check whether or not the file path exists for the Media directory.
        // If the filepath does not exist, or if the filepath does exist but it is not a directory, try creating the directory.
        // Note: This way, if unexpectedly a file exists but it is not a dir, an error will throw when trying to create the dir.
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: media.path, isDirectory: &isDirectory) == false || isDirectory.boolValue == false {
            try fileManager.createDirectory(at: media, withIntermediateDirectories: true, attributes: nil)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try media.setResourceValues(resourceValues)
        }
        return media
    }

    /// Returns a unique filesystem URL for a Media filename and extension, within the local Media directory.
    ///
    /// - Note: if a file already exists with the same name, the file name is appended with a number
    ///   and incremented until a unique filename is found.
    class func makeLocalMediaURL(with filename: String, fileExtension: String) throws -> URL {
        let media = try localMediaDirectory()
        let basename = (filename as NSString).deletingPathExtension.lowercased()
        var url = media.appendingPathComponent(basename, isDirectory: false)
        url.appendPathExtension(fileExtension)
        // Increment the filename as needed to ensure we're not
        // providing a URL for an existing file of the same name.
        return url.incrementalFilename()
    }

    /// Returns a string appended with the thumbnail naming convention for local Media files.
    ///
    class func mediaFilenameAppendingThumbnail(_ filename: String) -> String {
        var filename = filename as NSString
        let pathExtension = filename.pathExtension
        filename = filename.deletingPathExtension.appending("-thumbnail") as NSString
        return filename.appendingPathExtension(pathExtension)!
    }

    /// Returns the size of a Media image located at the file URL, or zero if it doesn't exist.
    ///
    /// - Note: once we drop ObjC, this should be an optional that would return nil instead of zero.
    ///
    class func imageSizeForMediaAt(fileURL: URL) -> CGSize {
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
    class func calculateSizeOfLocalMediaDirectory(onCompletion: @escaping (Int64?) -> ()) {
        DispatchQueue.global(qos: .default).async {
            let fileManager = FileManager.default
            let allocatedSize = try? fileManager.allocatedSizeOf(directoryURL: localMediaDirectory())
            DispatchQueue.main.async {
                onCompletion(allocatedSize)
            }
        }
    }

    /// Clear the locala Media directory of any files that are no longer in use by any managed Media objects.
    ///
    /// - Note: These files can show up because of the app being killed while a media object
    ///   was being created or when a CoreData migration fails and the database is recreated.
    ///
    class func clearUnusedFilesFromLocalMediaDirectory(onCompletion: (() -> ())?, onError: ((Error) -> Void)?) {
        purgeLocalMediaFiles(exceptMedia: NSPredicate.init(format: "blog != NULL", argumentArray: nil),
                             onCompletion: onCompletion,
                             onError: onError)
    }

    /// Clear the local Media directory of any cached media files that are available remotely.
    ///
    class func clearCachedFilesFromLocalMediaDirectory(onCompletion: (() -> ())?, onError: ((Error) -> Void)?) {
        purgeLocalMediaFiles(exceptMedia: NSPredicate.init(format: "remoteURL == NULL", argumentArray: nil),
                             onCompletion: onCompletion,
                             onError: onError)
    }

    // MARK: - Private

    /// Removes any local Media files, except any Media matching the predicate.
    ///
    fileprivate class func purgeLocalMediaFiles(exceptMedia predicate: NSPredicate, onCompletion: (() -> ())?, onError: ((Error) -> Void)?) {
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
                try purgeLocalMediaDirectory(exceptFiles: filesToKeep)
                if let onCompletion = onCompletion {
                    DispatchQueue.main.async {
                        onCompletion()
                    }
                }
            } catch {
                DDLogSwift.logError("Error while attempting to clean local media: \(error.localizedDescription)")
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
    fileprivate class func purgeLocalMediaDirectory(exceptFiles: Set<String>) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: try localMediaDirectory(),
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
                    DDLogSwift.logError("Error while removing unused Media at path: \(error.localizedDescription) - \(url.path)")
                }
            }
        }
        if removedCount > 0 {
            DDLogSwift.logInfo("Media: removed \(removedCount) file(s) during cleanup.")
        }
    }
}
