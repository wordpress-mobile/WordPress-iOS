import Foundation
import WordPressAPI
import WordPressAPIInternal

public typealias PluginDirectoryDataStoreQuery = InMemoryDataStore<PluginInformation>.Query
public typealias InMemoryPluginDirectoryDataStore = InMemoryDataStore<PluginInformation>

extension PluginDirectoryDataStoreQuery {
    public static func slug(_ slug: PluginWpOrgDirectorySlug) -> PluginDirectoryDataStoreQuery {
        .init(sortBy: KeyPathComparator(\.name)) { $0.slug == slug.slug }
    }
}

extension PluginInformation: @retroactive Identifiable {
    public var id: PluginWpOrgDirectorySlug {
        PluginWpOrgDirectorySlug(slug: slug)
    }
}

extension InMemoryPluginDirectoryDataStore {
    func get(_ slug: PluginWpOrgDirectorySlug) async throws -> PluginInformation? {
        try await list(query: .slug(slug)).first
    }
}
