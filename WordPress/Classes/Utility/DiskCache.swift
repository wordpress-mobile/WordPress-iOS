import Foundation
import CryptoKit

/// An LRU disk cache that stores data in files on disk.
///
/// ``DataCache`` uses LRU cleanup policy (least recently used items are removed
/// first). The elements stored in the cache are automatically discarded if
/// either *cost* or *count* limit is reached. The sweeps are performed periodically.
///
/// DataCache always writes and removes data asynchronously. It also allows for
/// reading and writing data in parallel. This is implemented using a "staging"
/// area which stores changes until they are flushed to disk:
///
/// ```swift
/// // Schedules data to be written asynchronously and returns immediately
/// cache[key] = data
///
/// // The data is returned from the staging area
/// let data = cache[key]
///
/// // Schedules data to be removed asynchronously and returns immediately
/// cache[key] = nil
///
/// // Data is nil
/// let data = cache[key]
/// ```
///
/// - important: It's possible to have more than one instance of ``DataCache`` with
/// the same path but it is not recommended.
public actor DiskCache {
    /// The path for the directory managed by the cache.
    public let rootURL: URL

    /// The cache configuration.
    public var configuration: Configuration

    public struct Configuration {
        /// Size limit in bytes. `100 Mb` by default.
        ///
        /// Changes to the size limit will take effect when the next LRU sweep is run.
        public var sizeLimit: Int = 1024 * 1024 * 100

        /// When performing a sweep, the cache will remote entries until the size of
        /// the remaining items is lower than or equal to `sizeLimit * trimRatio` and
        /// the total count is lower than or equal to `countLimit * trimRatio`. `0.7`
        /// by default.
        var trimRatio = 0.7

        /// The number of seconds between each LRU sweep. 30 by default.
        /// The first sweep is performed right after the cache is initialized.
        ///
        /// Sweeps are performed in a background and can be performed in parallel
        /// with reading.
        public var sweepInterval: TimeInterval = 30

        /// The delay after which the initial sweep is performed. 10 by default.
        /// The initial sweep is performed after a delay to avoid competing with
        /// other subsystems for the resources.
        var initialSweepDelay: TimeInterval = 10

        /// Initializes the configuration.
        ///
        /// - parameter sizeLimit: Size limit in bytes. `100 Mb` by default.
        public init(sizeLimit: Int = 1024 * 1024 * 100) {
            self.sizeLimit = sizeLimit
        }
    }

    /// Creates a cache instance with a given `name`. The cache creates a directory
    /// with the given `name` in a `.cachesDirectory` in `.userDomainMask`.
    public init(name: String, configuration: Configuration = .init()) {
        let cachesURL = DiskCache.getCachesURL()
        self.init(url: cachesURL.appendingPathComponent(name, isDirectory: true), configuration: configuration)
    }

    private static func getCachesURL() -> URL {
        guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            DDLogError("Failed to instantiate cache. Caches directory not available")
            return URL(fileURLWithPath: "/dev/null") // This should never happen
        }
        return cachesURL
    }

    /// Creates a cache instance with a given root URL..
    public init(url: URL, configuration: Configuration) {
        self.rootURL = url
        self.configuration = configuration

        do {
            try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            DDLogError("Failed to creates cache root directory at: \(url) with error: \(error)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.initialSweepDelay) { [weak self] in
            Task {
                await self?.performAndScheduleSweep()
            }
        }
    }

    // MARK: Accessing Cached Data

    /// Accesses the data associated with the given key for reading and writing.
    ///
    /// When you assign a new data for a key and the key already exists, the cache
    /// overwrites the existing data.
    ///
    /// When assigning or removing data, the subscript adds a requested operation
    /// in a staging area and returns immediately. The staging area allows for
    /// reading and writing data in parallel.
    ///
    /// ```swift
    /// // Schedules data to be written asynchronously and returns immediately
    /// cache[key] = data
    ///
    /// // The data is returned from the staging area
    /// let data = cache[key]
    ///
    /// // Schedules data to be removed asynchronously and returns immediately
    /// cache[key] = nil
    ///
    /// // Data is nil
    /// let data = cache[key]
    /// ```
    public subscript(key: String) -> Data? {
        get {
            guard let url = fileURL(for: key) else { return nil }
            return try? Data(contentsOf: url)
        }
        set {
            guard let url = fileURL(for: key) else { return }
            if let data = newValue {
                do {
                    try data.write(to: url)
                } catch let error as NSError {
                    guard error.code == CocoaError.fileNoSuchFile.rawValue && error.domain == CocoaError.errorDomain else { return }
                    try? FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)
                    try? data.write(to: url) // re-create a directory and try again
                }
            } else {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    /// Removes all items. The method returns instantly, the data is removed
    /// asynchronously.
    public func removeAll() {
        do {
            try FileManager.default.removeItem(at: rootURL)
            try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            DDLogError("Failed to clear cache with error: \(error)")
        }
    }

    /// Returns `url` for the given cache key.
    public func fileURL(for key: String) -> URL? {
        guard let filename = key.sha1 else { return nil }
        return rootURL.appendingPathComponent(filename, isDirectory: false)
    }

    // MARK: Sweep

    private func performAndScheduleSweep() {
        sweep()
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.sweepInterval) { [weak self] in
            Task {
                await self?.performAndScheduleSweep()
            }
        }
    }

    /// Performs cache sweep and removes the least recently items which no longer fit.
    public func sweep() {
        var items = contents(keys: [.contentAccessDateKey, .totalFileAllocatedSizeKey])
        guard !items.isEmpty else {
            return
        }
        var size = items.reduce(0) { $0 + ($1.meta.totalFileAllocatedSize ?? 0) }

        guard size > configuration.sizeLimit else {
            return // All good, no need to perform any work.
        }

        let targetSizeLimit = Int(Double(configuration.sizeLimit) * configuration.trimRatio)

        // Most recently accessed items first
        let past = Date.distantPast
        items.sort { // Sort in place
            ($0.meta.contentAccessDate ?? past) > ($1.meta.contentAccessDate ?? past)
        }

        // Remove the items until it satisfies both size and count limits.
        while size > targetSizeLimit, let item = items.popLast() {
            size -= (item.meta.totalFileAllocatedSize ?? 0)
            try? FileManager.default.removeItem(at: item.url)
        }
    }

    // MARK: Contents

    struct Entry {
        let url: URL
        let meta: URLResourceValues
    }

    func contents(keys: [URLResourceKey] = []) -> [Entry] {
        guard let urls = try? FileManager.default.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: keys, options: .skipsHiddenFiles) else {
            return []
        }
        let keys = Set(keys)
        return urls.compactMap {
            guard let meta = try? $0.resourceValues(forKeys: keys) else {
                return nil
            }
            return Entry(url: $0, meta: meta)
        }
    }

    // MARK: Inspection

    /// The total number of items in the cache.
    ///
    /// - important: Requires disk IO, avoid using from the main thread.
    public var totalCount: Int {
        contents().count
    }

    /// The total file size of items written on disk.
    ///
    /// Uses `URLResourceKey.fileSizeKey` to calculate the size of each entry.
    /// The total allocated size (see `totalAllocatedSize`. on disk might
    /// actually be bigger.
    ///
    /// - important: Requires disk IO, avoid using from the main thread.
    public var totalSize: Int {
        contents(keys: [.fileSizeKey]).reduce(0) {
            $0 + ($1.meta.fileSize ?? 0)
        }
    }

    /// The total file allocated size of all the items written on disk.
    ///
    /// Uses `URLResourceKey.totalFileAllocatedSizeKey`.
    ///
    /// - important: Requires disk IO, avoid using from the main thread.
    public var totalAllocatedSize: Int {
        contents(keys: [.totalFileAllocatedSizeKey]).reduce(0) {
            $0 + ($1.meta.totalFileAllocatedSize ?? 0)
        }
    }
}

private extension String {
    var sha1: String? {
        guard !isEmpty, let data = self.data(using: .utf8) else {
            return nil
        }
        // SHA1 offers a good balance between performance and size. Git uses
        // SHA1 for commit hashes and other purposes.
        return Insecure.SHA1.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
