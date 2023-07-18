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
    private let sweepInterval: TimeInterval = 86400 // Around 1 day

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

        performSweepIfNeeded()
    }

    /// Returns the total number of cached entities by enumerating the files.
    func getTotalCount() throws -> Int {
        try contents().count
    }

    // MARK: - Data

    func getData(forKey key: String) -> Data? {
        guard let url = fileURL(for: key) else { return nil }
        return try? Data(contentsOf: url)
    }

    func setData(_ data: Data, forKey key: String) {
        guard let url = fileURL(for: key) else { return }
        do {
            try data.write(to: url)
        } catch let error as NSError {
            guard error.code == CocoaError.fileNoSuchFile.rawValue && error.domain == CocoaError.errorDomain else { return }
            try? FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)
            try? data.write(to: url) // re-create a directory and try again
        }
    }

    func removeData(forKey key: String) {
        guard let url = fileURL(for: key) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    func removeAll() throws {
        try FileManager.default.removeItem(at: rootURL)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)
    }

    private func fileURL(for key: String) -> URL? {
        guard !key.isEmpty else {
            assertionFailure("The cache key can not be empty")
            return nil
        }
        guard let filename = key.sha256 else {
            assertionFailure("Failed to generate sha256 has for a key: \(key)")
            return nil
        }
        return rootURL.appendingPathComponent(filename, isDirectory: false)
    }

    // MARK: - Sweep

    private func performSweepIfNeeded() {
        let sweepDateKey = "disk-cache-last-sweep-date-\(rootURL)"
        if let sweepDate = UserDefaults.standard.value(forKey: sweepDateKey) as? Date,
           Date().timeIntervalSince(sweepDate) < sweepInterval {
            return // The last sweep was completed recently
        }
        // Perform the sweep after a brief delay to reduce the pressure on the system
        // during the app launch
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
            guard let self = self else { return }
            do {
                try self.sweep()
                UserDefaults.standard.set(Date(), forKey: sweepDateKey)
            } catch {
                DDLogError("Failed to perform cache sweep with error: \(error)")
            }
        }
    }

    func sweep() throws {
        var entries = try contents(withKeys: [.contentAccessDateKey, .totalFileAllocatedSizeKey])
        guard !entries.isEmpty else { return }
        var totalSize = entries.reduce(0) {
            $0 + ($1.attributes.totalFileAllocatedSize ?? 0)
        }
        guard totalSize > sizeLimit else {
            return // The size is OK
        }
        // Removes most entities, but not all (keep 50% of the size limit).
        let targetSizeLimit = Int(Double(sizeLimit) * 0.5)
        let distantPath = Date.distantPast // Should never be needed
        entries.sort { // Most recently accessed items first
            ($0.attributes.contentAccessDate ?? distantPath) > ($1.attributes.contentAccessDate ?? distantPath)
        }
        while totalSize > targetSizeLimit, let entry = entries.popLast() {
            totalSize -= (entry.attributes.totalFileAllocatedSize ?? 0)
            try FileManager.default.removeItem(at: entry.url)
        }
    }

    private struct FileEntry {
        let url: URL
        let attributes: URLResourceValues
    }

    private func contents(withKeys keys: Set<URLResourceKey> = []) throws -> [FileEntry] {
        let keys = keys.union([.isRegularFileKey])
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }
        var files: [FileEntry] = []
        for case let fileURL as URL in enumerator {
            do {
                let attributes = try fileURL.resourceValues(forKeys: keys)
                if attributes.isRegularFile ?? false {
                    files.append(FileEntry(url: fileURL, attributes: attributes))
                }
            } catch { print(error, fileURL) }
        }
        return files
    }
}

private extension String {
    var sha256: String? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        return SHA256.hash(data: data)
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
