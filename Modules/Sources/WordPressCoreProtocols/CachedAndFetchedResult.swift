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
