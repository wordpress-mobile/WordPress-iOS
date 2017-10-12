import Foundation


extension FileManager {

    /// This method calculates the accumulated size of a directory on the volume in bytes.
    ///
    /// As there's no simple way to get this information from the file system it has to crawl the entire hierarchy,
    /// accumulating the overall sum on the way. The resulting value is roughly equivalent with the amount of bytes
    /// that would become available on the volume if the directory would be deleted.
    ///
    /// - note: There are a couple of oddities that are not taken into account (like symbolic links, meta data of
    /// directories, hard links, ...). Original code can be found here: https://gist.github.com/NikolaiRuhe/eeb135d20c84a7097516
    ///
    func allocatedSizeOf(directoryURL: URL) throws -> Int64 {

        // We'll sum up content size here:
        var accumulatedSize = Int64(0)

        // prefetching some properties during traversal will speed up things a bit.
        let prefetchedProperties = [
            URLResourceKey.isRegularFileKey,
            URLResourceKey.fileAllocatedSizeKey,
            URLResourceKey.totalFileAllocatedSizeKey,
            ]

        // The error handler simply signals errors to outside code.
        var errorDidOccur: Error?
        let errorHandler: (URL, Error) -> Bool = { _, error in
            errorDidOccur = error
            return false
        }


        // We have to enumerate all directory contents, including subdirectories.
        guard let enumerator = enumerator(at: directoryURL,
                                         includingPropertiesForKeys: prefetchedProperties,
                                         options: DirectoryEnumerationOptions(),
                                         errorHandler: errorHandler) else {
                                            throw NSError(domain: "", code: 0, userInfo: nil)
        }

        // Start the traversal:
        for item in enumerator {
            let contentItemURL = item as! NSURL
            // Bail out on errors from the errorHandler.
            if let error = errorDidOccur { throw error }

            let resourceValueForKey: (String) throws -> NSNumber? = { key in
                var value: AnyObject?
                try contentItemURL.getResourceValue(&value, forKey: URLResourceKey(rawValue: key))
                return value as? NSNumber
            }

            // Get the type of this item, making sure we only sum up sizes of regular files.
            guard let isRegularFile = try resourceValueForKey(URLResourceKey.isRegularFileKey.rawValue) else {
                preconditionFailure()
            }

            guard isRegularFile.boolValue else {
                continue
            }

            // To get the file's size we first try the most comprehensive value in terms of what the file may use on disk.
            // This includes metadata, compression (on file system level) and block size.
            var fileSize = try resourceValueForKey(URLResourceKey.totalFileAllocatedSizeKey.rawValue)

            // In case the value is unavailable we use the fallback value (excluding meta data and compression)
            // This value should always be available.
            fileSize = try fileSize ?? resourceValueForKey(URLResourceKey.fileAllocatedSizeKey.rawValue)

            guard let size = fileSize else {
                preconditionFailure("huh? NSURLFileAllocatedSizeKey should always return a value")
            }

            // We're good, add up the value.
            accumulatedSize += size.int64Value
        }

        // Bail out on errors from the errorHandler.
        if let error = errorDidOccur { throw error }

        // We finally got it.
        return accumulatedSize
    }
}
