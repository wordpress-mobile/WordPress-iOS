import Foundation

/// Encapsulates Media functions relative to the local Media directory.
///
extension MediaService {

    fileprivate static let mediaDirectoryName = "Media"

    /// Returns filesystem URL for the local Media directory.
    ///
    class func localMediaDirectory() throws -> URL {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var media = documents.appendingPathComponent(mediaDirectoryName, isDirectory: true)
        let available = try media.checkResourceIsReachable()
        if available == false {
            try fileManager.createDirectory(at: media, withIntermediateDirectories: true, attributes: nil)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false
            try media.setResourceValues(resourceValues)
        }
        return media
    }

    /// Returns a filesystem URL for a Media filename and extension, within the local Media directory.
    ///
    class func localMediaURL(with filename: String, fileExtension: String) throws -> URL {
        let media = try localMediaDirectory()
        let basename = (filename as NSString).deletingPathExtension.lowercased()
        var url = media.appendingPathComponent(basename, isDirectory: false)
        url.appendPathExtension(fileExtension)
        // Increment the filename as needed to ensure we're not
        // providing a URL for an existing file of the same name.
        return try url.incrementedFilename()
    }

    /// Returns a string appended with the thumbnail naming convention for local Media files.
    ///
    class func mediaFilenameAppendingThumbnail(_ filename: String) -> String {
        var filename = filename as NSString
        let pathExtension = filename.pathExtension
        filename = filename.deletingPathExtension.appending("-thumbnail") as NSString
        return filename.appendingPathExtension(pathExtension)!
    }
}
