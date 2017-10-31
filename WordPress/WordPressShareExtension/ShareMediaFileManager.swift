import Foundation

/// Encapsulates media file operations relative to the shared container's Media directory.
///
@objc class ShareMediaFileManager: NSObject {

    /// Directory name for media uploads
    ///
    fileprivate let mediaDirectoryName = "Media"

    /// URL for the Media upload directory in the shared container. Can return nil.
    ///
    var mediaUploadDirectoryURL: URL? {
        let fileManager = FileManager.default
        guard let sharedContainerRootURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName) else {
            return nil
        }
        let mediaDirectoryURL =  sharedContainerRootURL.appendingPathComponent(mediaDirectoryName, isDirectory: true)

        // Check whether or not the file path exists for the Media directory. If the filepath does not exist, or
        // if the filepath does exist but it is not a directory, try creating the directory.
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: mediaDirectoryURL.path, isDirectory: &isDirectory) == false || isDirectory.boolValue == false {
            do {
                try fileManager.createDirectory(at: mediaDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                DDLogError("Error creating local media directory: \(error)")
            }
        }
        return mediaDirectoryURL
    }

    // MARK: - Singleton

    static let shared: ShareMediaFileManager = ShareMediaFileManager()
    private override init() {}

    // MARK: - Instance methods

    /// Removes all files from the Media upload directory.
    ///
    func purgeUploadDirectory() {
        guard let mediaDirectory = mediaUploadDirectoryURL else {
            return
        }
        let fileManager = FileManager.default
        let contents: [URL]
        do {
            try contents = fileManager.contentsOfDirectory(at: mediaDirectory,
                                                           includingPropertiesForKeys: nil,
                                                           options: .skipsHiddenFiles)
        } catch {
            DDLogError("Error retrieving contents of shared container media directory: \(error)")
            return
        }

        var removedCount = 0
        for url in contents {
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
            DDLogInfo("Shared container media: removed \(removedCount) file(s) during cleanup.")
        }
    }
}
