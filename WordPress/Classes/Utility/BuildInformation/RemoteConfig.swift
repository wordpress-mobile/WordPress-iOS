import Foundation

/// A struct that holds all remote config parameters.
struct RemoteConfig {

    // MARK: Private Variables

    private var store: RemoteConfigStore

    // MARK: Initializer

    init(store: RemoteConfigStore = RemoteConfigStore()) {
        self.store = store
    }

    // MARK: Remote Config Parameters

    var jetpackDeadline: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "jp-deadline", defaultValue: nil, store: store)
    }
}
