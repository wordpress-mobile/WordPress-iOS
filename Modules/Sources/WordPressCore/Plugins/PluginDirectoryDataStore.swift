import Foundation
import WordPressAPI
import WordPressAPIInternal

// MARK: - DataStore for full plugin deatils

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

// MARK: - DataStore for plugin browser (featured, recommended plugins), which contains shortened `PluginInformation`

public typealias CategorizedPluginInformationDataStoreQuery = InMemoryDataStore<CategorizedPluginInformation>.Query
public typealias CategorizedPluginInformationDataStore = InMemoryDataStore<CategorizedPluginInformation>

public struct CategorizedPluginInformation: Identifiable, Sendable {
    public var category: WordPressOrgApiPluginDirectoryCategory
    public var plugins: [PluginInformation]

    public var id: WordPressOrgApiPluginDirectoryCategory { category }
}

extension CategorizedPluginInformationDataStore.Query {
    public static func category(_ category: WordPressOrgApiPluginDirectoryCategory) -> CategorizedPluginInformationDataStore.Query {
        .init(sortBy: nil) { $0.category == category }
    }

    public static func category(_ categories: Set<WordPressOrgApiPluginDirectoryCategory>) -> CategorizedPluginInformationDataStore.Query {
        .init(sortBy: nil) { categories.contains($0.category) }
    }
}
