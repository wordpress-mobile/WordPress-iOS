import Foundation

public protocol CachedAndFetchedResult<T>: Sendable {
    associatedtype T

    var cachedResult: @Sendable () async throws -> T? { get }
    var fetchedResult: @Sendable () async throws -> T { get }
}

/// A type that isn't actually cached (like Preview data providers)
public struct UncachedResult<T>: CachedAndFetchedResult {
    public let cachedResult: @Sendable () async throws -> T?
    public let fetchedResult: @Sendable () async throws -> T

    public init(
        fetchedResult: @Sendable @escaping () async throws -> T
    ) {
        self.cachedResult = { nil }
        self.fetchedResult = fetchedResult
    }
}

/// Represents a double-returning promise – initially for a cached result that may be empty, and eventually for an expensive fetched result (usually from a server).
///
/// This variant uses the `Caches` directory on-disk as its backing store
///
public struct DiskCachedAndFetchedResult<T>: CachedAndFetchedResult where T: Codable & Sendable {
    public var cachedResult: @Sendable () async throws -> T? {
        return self.readFromCache
    }

    public var fetchedResult: @Sendable () async throws -> T {
        return self.fetchAndCache
    }

    private let userProvidedFetchBlock: @Sendable () async throws -> T

    private let cacheKey: String

    public init(
        fetchedResult: @escaping @Sendable () async throws -> T,
        cacheKey: String
    ) {
        self.userProvidedFetchBlock = fetchedResult
        self.cacheKey = cacheKey
    }

    public func fetchAndCache() async throws -> T {
        let result = try await userProvidedFetchBlock()
        try await DiskCache().store(result, forKey: self.cacheKey)
        return result
    }

    // We can ignore decoding failures here because the data format may change over time. Treating it as a cache
    // miss is preferable to returning an error because the cache will simply be updated on the next remote fetch.
    private func readFromCache() async throws -> T? {
        try await DiskCache().read(T.self, forKey: self.cacheKey)
    }
}

public struct UserDefaultsCachedAndFetchedResult<T>: CachedAndFetchedResult where T: Codable & Sendable {
    public var cachedResult: @Sendable () async throws -> T? {
        return self.readFromCache
    }

    public var fetchedResult: @Sendable () async throws -> T {
        return self.fetchAndCache
    }

    private let userProvidedFetchBlock: @Sendable () async throws -> T

    private let cacheKey: String

    public init(
        fetchedResult: @escaping @Sendable () async throws -> T,
        cacheKey: String
    ) {
        self.userProvidedFetchBlock = fetchedResult
        self.cacheKey = cacheKey
    }

    public func fetchAndCache() async throws -> T {
        let result = try await userProvidedFetchBlock()
        try UserDefaults.standard.setValue(PropertyListEncoder().encode(result), forKey: self.cacheKey)
        return result
    }

    private func readFromCache() async throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: self.cacheKey) else {
            return nil
        }

        // We can ignore decoding failures here because the data format may change over time. Treating it as a cache
        // miss is preferable to returning an error because the cache will simply be updated on the next remote fetch.
        return try? PropertyListDecoder().decode(T.self, from: data)
    }
}
