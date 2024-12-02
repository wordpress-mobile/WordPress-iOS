import Foundation

/// An abstraction of local data storage, with CRUD operations.
public protocol DataStore: Actor {
    associatedtype T: Identifiable & Sendable
    associatedtype Query

    func list(query: Query) async throws -> [T]
    func delete(query: Query) async throws
    func store(_ data: [T]) async throws

    /// An AsyncStream that produces up-to-date results for the given query.
    ///
    /// The `AsyncStream` should not finish as long as the `DataStore` remains alive and valid.
    func listStream(query: Query) -> AsyncStream<Result<[T], Error>>
}
