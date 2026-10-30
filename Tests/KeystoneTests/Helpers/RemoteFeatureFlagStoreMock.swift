import Foundation
@testable import WordPress

class RemoteFeatureFlagStoreMock: RemoteFeatureFlagStore {

    var inAppRating = false

    var enabledFeatureFlags = Set<String>()
    var disabledFeatureFlag = Set<String>()

    override var deviceID: String {
        "Test"
    }

    override func value(for flagKey: String) -> Bool? {
        if enabledFeatureFlags.contains(flagKey) {
            return true
        } else if disabledFeatureFlag.contains(flagKey) {
            return false
        }
        switch flagKey {
        case RemoteFeatureFlag.inAppRating.remoteKey:
            return inAppRating
        default:
            return super.value(for: flagKey)
        }
    }
}
