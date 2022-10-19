import Foundation

/// Represents a single remote parameter. Each parameter has a default value and a server value.
/// We fallback to the default value if the server value cannot be retrieved.
/// All remote parameters should be added to ``RemoteConfig``
struct RemoteConfigParameter<T> {

    // MARK: Private Variables

    private let key: String
    private let defaultValue: T?
    private let store: RemoteConfigStore

    private var serverValue: T? {
        return store.cache[key] as? T
    }

    // MARK: Initializer

    init(key: String, defaultValue: T?, store: RemoteConfigStore = .shared) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    // MARK: Public Variables

    var value: T? {
        if let serverValue = serverValue {
            return serverValue
        }
        return defaultValue
    }
}
