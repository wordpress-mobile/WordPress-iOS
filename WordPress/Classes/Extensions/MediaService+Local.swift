import Foundation
import ImageIO

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

        // Check whether or not the file path exists for the Media directory.
        // If the filepath does not exist, or if the filepath does exist but it is not a directory, try creating the directory.
        // Note: This way, if unexpectedly a file exists but it is not a dir, an error will throw when trying to create the dir.
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: media.path, isDirectory: &isDirectory) == false || isDirectory.boolValue == false {
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

    /// Returns the size of a Media image located at the path, or zero if it doesn't exist.
    ///
    /// Note: once we drop ObjC, this should be an optional that would return nil instead of zero.
    class func imageSizeForMediaAt(path: String?) -> CGSize {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard let path = path, fileManager.fileExists(atPath: path, isDirectory: &isDirectory) == true, isDirectory.boolValue == false else {
            return CGSize.zero
        }
        let url = URL(fileURLWithPath: path, isDirectory: false)
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return CGSize.zero
        }
        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? Dictionary<String, AnyObject> else {
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
}
