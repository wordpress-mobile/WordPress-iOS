import Foundation

/// A struct that holds all remote config parameters.
struct RemoteConfig {
    static let jetpackDeadline = RemoteConfigParameter<String>(key: "jp-deadline", defaultValue: nil)
}
