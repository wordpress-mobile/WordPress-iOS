import Foundation
@preconcurrency import Combine
import WordPressAPI
import WordPressAPIInternal

public protocol ApiCacheEntityCollection: AnyObject, Sendable {
    associatedtype Entity: ApiCacheEntity

    func loadData() async throws -> [Entity]
    func isRelevantUpdate(hook: UpdateHook) -> Bool
}

public protocol ApiCacheEntity: Identifiable, Sendable {
    static var table: DbTable { get }
}

public actor ApiCacheDataStore<C: ApiCacheEntityCollection>: DataStore {
    public typealias T = C.Entity
    public typealias Query = Void

    public let collection: C

    public init(collection: C) {
        self.collection = collection
    }

    public func list(query: Query) async throws -> [T] {
        try await collection.loadData()
    }

    public func delete(query: Query) async throws {
        fatalError("Unsupported")
    }

    public func store(_ data: [T]) async throws {
        fatalError("Unsupported")
    }

    public func listStream(query: Query) -> AsyncStream<Result<[T], Error>> {
        let (stream, continuation) = AsyncStream<Result<[T], Error>>.makeStream()
        let updates = collection.updates()
        let updatingTask = Task { [weak self] in
            var iter = updates.values.makeAsyncIterator()
            repeat {
                guard let self else { break }
                do {
                    let result: [T] = try await self.list(query: query)
                    continuation.yield(.success(result))
                } catch {
                    continuation.yield(.failure(error))
                }
            } while await iter.next() != nil && !Task.isCancelled

            continuation.finish()
        }
        continuation.onTermination = { (t: AsyncStream<Result<[T], Error>>.Continuation.Termination) in
            if case .cancelled = t {
                updatingTask.cancel()
            }
        }

        return stream
    }
}

private extension ApiCacheEntityCollection {
    func updates() -> AnyPublisher<Void, Never> {
        // TODO: This implicitly relies on `WordPressApiCache`'s default broadcast updates implementation.
        NotificationCenter.default.publisher(for: WordPressApiCache.Notifications.name(for: Entity.table))
            .filter { [weak self] notification in
                guard let update = notification.object as? UpdateHook else {
                    return false
                }
                return self?.isRelevantUpdate(hook: update) == true
            }
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

// MARK: - Posts

extension PostCollectionWithEditContext: ApiCacheEntityCollection {}

extension FullEntityAnyPostWithEditContext: @retroactive Identifiable {
    public var id: EntityId {
        entityId
    }
}

extension FullEntityAnyPostWithEditContext: ApiCacheEntity {
    public static var table: DbTable {
        DbTable.postsEditContext
    }
}
