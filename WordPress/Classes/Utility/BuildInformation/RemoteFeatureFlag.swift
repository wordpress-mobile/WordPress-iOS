import Foundation

@objc
enum RemoteFeatureFlag: Int, CaseIterable, CustomStringConvertible {
    case test

    var defaultValue: Bool {
        return true
    }

    var remoteKey: String {
        return "key"
    }

    var description: String {
        return "description"
    }

    func enabled(using store: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) -> Bool {
        // TODO: Check if overridden
        guard let remoteValue = store.value(for: remoteKey) else { // The value may not be in the cache if this is the first run
            DDLogInfo("🚩 Unable to resolve remote feature flag: \(description). Returning compile-time default.")
            return defaultValue
        }
        return remoteValue
    }
}
