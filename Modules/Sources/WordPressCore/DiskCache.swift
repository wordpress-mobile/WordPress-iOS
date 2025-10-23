import Foundation
import WordPressCoreProtocols

/// A super-basic on-disk cache for `Codable` objects.
///
public actor DiskCache: DiskCacheProtocol {

    public static let shared = DiskCache()

    private let cacheRoot: URL = URL.cachesDirectory

    public func read<T>(
        _ type: T.Type,
        forKey key: String,
        notOlderThan interval: TimeInterval? = nil
    ) throws -> T? where T: Decodable {
        let path = self.path(forKey: key)

        guard FileManager.default.fileExists(at: path) else {
            return nil
        }

        if let interval {
            let attributes = try FileManager.default.attributesOfItem(atPath: path.absoluteString)

            // If we can't get a modification date, assume it's invalid
            guard let lastModifiedAt = attributes[.modificationDate] as? Date else {
                return nil
            }

            if Date.now.addingTimeInterval(interval * -1) < lastModifiedAt {
                return nil
            }
        }

        let data = try Data(contentsOf: path)

        // We can ignore decoding failures here because the data format may change over time. Treating it as a cache
        // miss is preferable to returning an error because the cache will simply be updated on the next remote fetch.
        return try? JSONDecoder().decode(T.self, from: data)
    }

    public func store<T>(_ value: T, forKey key: String) throws where T: Encodable {
        let data = try JSONEncoder().encode(value)
        try data.write(to: self.path(forKey: key))
    }

    public func remove(key: String) throws {
        let path = self.path(forKey: key)
        guard FileManager.default.fileExists(at: path) else {
            return
        }
        try FileManager.default.removeItem(at: self.path(forKey: key))
    }

    public func removeAll(progress: (@Sendable (CacheDeletionProgress) async throws -> Void)? = nil) async throws {
        let files = try await fetchCacheEntries()

        let count = files.count

        try await progress?(CacheDeletionProgress(filesDeleted: 0, totalFileCount: count))

        for file in files.enumerated() {
            try FileManager.default.removeItem(at: file.element)
            try await progress?(CacheDeletionProgress(filesDeleted: file.offset + 1, totalFileCount: count))
        }
    }

    // The number of entries stored in this cache
    public func count() async throws -> Int {
        try await fetchCacheEntries().count
    }

    public func diskUsage() async throws -> DiskCacheUsage {
        let files = try await fetchCacheEntries()

        return DiskCacheUsage(
            fileCount: files.count,
            byteCount: files.reduce(into: Int64(0)) { $0 += $1.fileSize ?? 0 }
        )
    }

    private func fetchCacheEntries() async throws -> [URL] {
        try FileManager.default
            .contentsOfDirectory(at: cacheRoot, includingPropertiesForKeys: [.fileSizeKey])
            .filter { $0.lastPathComponent.hasSuffix(".cache.json") }
    }

    private func path(forKey key: String) -> URL {
        cacheRoot.appendingPathComponent("\(key).cache.json")
    }
}
