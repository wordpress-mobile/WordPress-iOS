import Foundation
import WordPressAPI

public typealias PluginDataStoreQuery = InMemoryDataStore<InstalledPlugin>.Query
public typealias InMemoryInstalledPluginDataStore = InMemoryDataStore<InstalledPlugin>

extension PluginDataStoreQuery {
    public static var all: PluginDataStoreQuery {
        .init(sortBy: KeyPathComparator(\.name)) { _ in true }
    }

    public static var active: PluginDataStoreQuery {
        .init(sortBy: KeyPathComparator(\.name)) { $0.isActive }
    }

    public static var inactive: PluginDataStoreQuery {
        .init(sortBy: KeyPathComparator(\.name)) { !$0.isActive }
    }

    public static func slug(_ slug: PluginSlug) -> PluginDataStoreQuery {
        .init(sortBy: KeyPathComparator(\.name)) { $0.slug == slug }
    }

    public static func slug(_ slug: PluginWpOrgDirectorySlug) -> PluginDataStoreQuery {
        .init(sortBy: KeyPathComparator(\.name)) { $0.possibleWpOrgDirectorySlug == slug }
    }
}
