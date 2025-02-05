import Foundation
@preconcurrency import Combine
import WordPressShared
import WordPressAPI
import WordPressAPIInternal

public protocol PluginDirectoryDataStore: DataStore where T == PluginInformation, Query == PluginDirectoryDataStoreQuery {
}

public enum PluginDirectoryDataStoreQuery: Hashable, Sendable {
    case slug(PluginWpOrgDirectorySlug)
}

extension PluginDirectoryDataStore {
    public func get(_ slug: PluginWpOrgDirectorySlug) async throws -> PluginInformation? {
        try await list(query: .slug(slug)).first
    }
}

public actor InMemoryPluginDirectoryDataStore: PluginDirectoryDataStore, InMemoryDataStore {
    public var storage: [T.ID: T] = [:]
    public let updates: PassthroughSubject<Set<T.ID>, Never> = .init()

    deinit {
        updates.send(completion: .finished)
    }

    public init() {}

    public func list(query: Query) throws -> [T] {
        let plugins: any Sequence<T>
        switch query {
        case let .slug(slug):
            plugins = storage[slug].flatMap { [$0] } ?? []
        }

        return plugins.sorted(using: KeyPathComparator(\.name))
    }
}

extension PluginInformation: @retroactive Identifiable {
    public var id: PluginWpOrgDirectorySlug {
        PluginWpOrgDirectorySlug(slug: slug)
    }
}
