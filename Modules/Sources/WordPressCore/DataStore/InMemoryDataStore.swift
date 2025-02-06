import Foundation
@preconcurrency import Combine

/// A `DataStore` type that stores data in memory.
public actor InMemoryDataStore<T: Sendable & Identifiable>: DataStore {

    public struct Query: Sendable {
        // TODO: Replace this with `Predicate` once iOS 17 becomes the minimal deployment target.
        let filter: @Sendable (T) -> Bool
        let sortBy: any SortComparator<T>

        public init(sortBy: any SortComparator<T>, filter: @escaping @Sendable (T) -> Bool) {
            self.sortBy = sortBy
            self.filter = filter
        }
    }

    /// A `Dictionary` to store the data in memory.
    private var storage: [T.ID: T] = [:]

    /// A publisher for sending and subscribing data changes.
    ///
    /// The publisher emits events when data changes, with identifiers of changed models.
    ///
    /// The publisher does not complete as long as the `InMemoryDataStore` remains alive and valid.
    private let updates: PassthroughSubject<Set<T.ID>, Never> = .init()

    public init() {}

    deinit {
        updates.send(completion: .finished)
    }

    public func list(query: Query) async throws -> [T] {
        storage.values
            .filter(query.filter)
            .sorted(using: query.sortBy)
    }

    public func delete(query: Query) async throws {
        let result = try await list(query: query)
        var updated = Set<T.ID>()
        for item in result {
            if storage.removeValue(forKey: item.id) != nil {
                updated.insert(item.id)
            }
        }

        if !updated.isEmpty {
            updates.send(updated)
        }
    }

    public func store(_ data: [T]) async throws {
        var updated = Set<T.ID>()
        for item in data {
            updated.insert(item.id)
            self.storage[item.id] = item
        }

        if !updated.isEmpty {
            updates.send(updated)
        }
    }

    public func listStream(query: Query) -> AsyncStream<Result<[T], Error>> {
        let stream = AsyncStream<Result<[T], Error>>.makeStream()

        let updatingTask = Task { [weak self] in
            var iter = await self?.updates.values.makeAsyncIterator()
            repeat {
                guard let self else { break }
                do {
                    let result = try await self.list(query: query)
                    stream.continuation.yield(.success(result))
                } catch {
                    stream.continuation.yield(.failure(error))
                }
            } while await iter?.next() != nil && !Task.isCancelled

            stream.continuation.finish()
        }

        stream.continuation.onTermination = {
            if case .cancelled = $0 {
                updatingTask.cancel()
            }
        }

        return stream.stream
    }
}
