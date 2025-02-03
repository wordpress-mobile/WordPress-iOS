import Foundation
@preconcurrency import Combine
import WordPressShared
import WordPressAPI

public protocol InstalledPluginDataStore: DataStore where T == InstalledPlugin, Query == PluginDataStoreQuery {
}

public enum PluginDataStoreQuery: Hashable, Sendable {
    case all
    case active
    case inactive
    case slug(PluginSlug)
}

public actor InMemoryInstalledPluginDataStore: InstalledPluginDataStore, InMemoryDataStore {
    public typealias T = InstalledPlugin

    public var storage: [T.ID: T] = [:]
    public let updates: PassthroughSubject<Set<T.ID>, Never> = .init()

    deinit {
        updates.send(completion: .finished)
    }

    public init() {}

    public func list(query: Query) throws -> [T] {
        let plugins: any Sequence<T>
        switch query {
        case .all:
            plugins = storage.values
        case .active:
            plugins = storage.values.filter { $0.isActive }
        case .inactive:
            plugins = storage.values.filter { !$0.isActive }
        case let .slug(slug):
            plugins = storage.values.first { $0.slug == slug }.flatMap { [$0] } ?? []
        }

        return plugins.sorted(using: KeyPathComparator(\.slug.slug))
    }
}
