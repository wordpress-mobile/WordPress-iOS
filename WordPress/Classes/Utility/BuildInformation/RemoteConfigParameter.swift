import Foundation

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

extension RemoteConfigStore {
    static let jetpackDeadline = RemoteConfigParameter<String>(key: "jp-deadline", defaultValue: nil)
}
