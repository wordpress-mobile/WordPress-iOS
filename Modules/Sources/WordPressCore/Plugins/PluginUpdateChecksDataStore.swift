import Foundation
import WordPressAPIInternal // Required for `UpdateCheckPluginInfo` Hashable conformance

extension UpdateCheckPluginInfo: @retroactive Identifiable {
    public var id: PluginSlug { plugin }
}

public typealias PluginUpdateChecksDataStoreQuery = InMemoryDataStore<UpdateCheckPluginInfo>.Query
public typealias PluginUpdateChecksDataStore = InMemoryDataStore<UpdateCheckPluginInfo>

extension PluginUpdateChecksDataStoreQuery {
    public static var all: Self {
        .init(sortBy: nil)
    }

    public static func slug(_ slug: PluginSlug) -> Self {
        .init(id: slug)
    }
}
