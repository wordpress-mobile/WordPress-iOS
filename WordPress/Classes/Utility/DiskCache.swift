import Foundation
import CryptoKit

/// An LRU disk cache that stores data in files on disk.
///
/// ``DiskCache`` uses an LRU cleanup policy where the least recently used items
/// are removed first). The elements stored in the cache are automatically
/// discarded if either *cost* or *count* limit is exceeded.
///
/// ``DiskCache`` is thread-safe; both reads and writes can be executed in parallel.
///
/// - important: It's not recommended to have more than one instance of ``DiskCache``
/// managing the same path.
final class DiskCache {
    static let shared = DiskCache(
        url: URL.getCachesURL().appendingPathComponent("WPCache", isDirectory: true)
    )

    private let rootURL: URL
    private let sizeLimit: Int

    private let queue = DispatchQueue(label: "org.wordpress.diskCache")

    /// Creates a cache instance with a given root URL.
    ///
    /// - parameters:
    ///   - url: The directory URL where cached files will be stored. The
    ///     directory will be automatically created by ``DiskCache``.
    ///   - sizeLimit: The size limit in bytes. By default, 100 MB.
    init(url: URL, sizeLimit: Int = 1024 * 1024 * 100) {
        self.rootURL = url
        self.sizeLimit = sizeLimit

        do {
            try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            DDLogError("Failed to creates cache root directory at: \(url) with error: \(error)")
        }
        queue.asyncAfter(deadline: .now() + .seconds(10)) { [weak self] in
            self?.performAndScheduleNextSweep()
        }
    }

    // MARK: - Codable

    public func getValue<T: Decodable>(
        _ type: T.Type,
        forKey key: String,
        decoder: JSONDecoder = JSONDecoder()
    ) -> T? {
        guard let data = getData(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    public func setValue<T: Encodable>(
        _ value: T,
        forKey key: String,
        encoder: JSONEncoder = JSONEncoder()
    ) {
        guard let data = try? encoder.encode(value) else { return }
        setData(data, forKey: key)
    }

    public func removeValue(forKey key: String) {
        removeData(forKey: key)
    }

    // MARK: - Codable (Async)

    public func getValue<T: Decodable>(
        _ type: T.Type,
        forKey key: String,
        decoder: JSONDecoder = JSONDecoder()
    ) async -> T? {
        await withUnsafeContinuation { continuation in
            queue.async {
                let value = self.getValue(type, forKey: key, decoder: decoder)
                continuation.resume(returning: value)
            }
        }
    }

    public func setValue<T: Encodable>(
        _ value: T,
        forKey key: String,
        encoder: JSONEncoder = JSONEncoder()
    ) async {
        await withUnsafeContinuation { continuation in
            queue.async {
                self.setValue(value, forKey: key, encoder: encoder)
                continuation.resume()
            }
        }
    }

    public func removeValue(forKey key: String) async {
        await withUnsafeContinuation { continuation in
            queue.async {
                self.removeData(forKey: key)
                continuation.resume()
            }
        }
    }

    // MARK: - Data

    public func getData(forKey key: String) -> Data? {
        guard let url = fileURL(for: key) else { return nil }
        return try? Data(contentsOf: url)
    }

    public func setData(_ data: Data, forKey key: String) {
        guard let url = fileURL(for: key) else { return }
        do {
            try data.write(to: url)
        } catch let error as NSError {
            guard error.code == CocoaError.fileNoSuchFile.rawValue && error.domain == CocoaError.errorDomain else { return }
            try? FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)
            try? data.write(to: url) // re-create a directory and try again
        }
    }

    public func removeData(forKey key: String) {
        guard let url = fileURL(for: key) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Removes all cached entries.
    public func removeAll() throws {
        try FileManager.default.removeItem(at: rootURL)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)
    }

    private func fileURL(for key: String) -> URL? {
        guard let filename = key.sha1 else { return nil }
        return rootURL.appendingPathComponent(filename, isDirectory: false)
    }

    // MARK: - Sweep

    private func performAndScheduleNextSweep() {
        sweep()
        queue.asyncAfter(deadline: .now() + .seconds(10)) { [weak self] in
            self?.performAndScheduleNextSweep()
        }
    }

    /// Performs cache sweep and removes the least recently items which no longer fit.
    public func sweep() {
        var items = contents(keys: [.contentAccessDateKey, .totalFileAllocatedSizeKey])
        guard !items.isEmpty else {
            return
        }
        var size = items.reduce(0) { $0 + ($1.meta.totalFileAllocatedSize ?? 0) }

        guard size > sizeLimit else {
            return // All good, no need to perform any work.
        }

        // Removes most entities, but not all (keep 50% of the size limit).
        let targetSizeLimit = Int(Double(sizeLimit) * 0.5)

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

    // MARK: - Contents

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

    // MARK: - Inspection

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

private extension URL {
    static func getCachesURL() -> URL {
        if #available(iOS 16, *) {
            return URL.cachesDirectory
        } else {
            guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                DDLogError("Failed to instantiate cache. Caches directory not available")
                return URL(fileURLWithPath: "/dev/null") // This should never happen
            }
            return cachesURL
        }
    }
}
