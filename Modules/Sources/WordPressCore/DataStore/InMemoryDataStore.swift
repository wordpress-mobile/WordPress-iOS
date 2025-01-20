import Foundation
@preconcurrency import Combine

/// A `DataStore` type that stores data in memory.
public protocol InMemoryDataStore: DataStore {
    /// A `Dictionary` to store the data in memory.
    var storage: [T.ID: T] { get set }

    /// A publisher for sending and subscribing data changes.
    ///
    /// The publisher emits events when data changes, with identifiers of changed models.
    ///
    /// The publisher does not complete as long as the `InMemoryDataStore` remains alive and valid.
    var updates: PassthroughSubject<Set<T.ID>, Never> { get }
}

public extension InMemoryDataStore {
    func delete(query: Query) async throws {
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

    func store(_ data: [T]) async throws {
        var updated = Set<T.ID>()
        for item in data {
            updated.insert(item.id)
            self.storage[item.id] = item
        }

        if !updated.isEmpty {
            updates.send(updated)
        }
    }

    func listStream(query: Query) -> AsyncStream<Result<[T], Error>> {
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
