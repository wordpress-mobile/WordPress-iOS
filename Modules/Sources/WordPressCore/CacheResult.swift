import Foundation

public struct DiskCachedResult<T: Codable & Sendable> {

    public typealias Computation = @Sendable () async throws -> T where T: Codable & Sendable

    private let computationBlock: Computation
    private let cacheKey: String

    public init(
        computedResult: @escaping @Sendable () async throws -> T,
        cacheKey: String
    ) {
        self.computationBlock = computedResult
        self.cacheKey = cacheKey
    }

    public func get() async throws -> T {
        if let cachedValue = try await DiskCache.shared.read(T.self, forKey: self.cacheKey) {
            return cachedValue
        }

        let computedValue = try await computationBlock()
        try await DiskCache.shared.store(computedValue, forKey: self.cacheKey)

        return computedValue
    }
}

public func cacheOnDisk<T>(
    key: String,
    computation: @escaping DiskCachedResult<T>.Computation
) async throws -> T where T: Codable & Sendable {
    try await DiskCachedResult(computedResult: computation, cacheKey: key).get()
}
