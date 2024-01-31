import Foundation
@testable import WordPress

class RemoteFeatureFlagStoreMock: RemoteFeatureFlagStore {

    var removalPhaseOne = false
    var removalPhaseTwo = false
    var removalPhaseThree = false
    var removalPhaseFour = false
    var removalPhaseNewUsers = false
    var removalPhaseSelfHosted = false
    var removalPhaseStaticScreens = false
    var inAppRating = false

    var enabledFeatureFlags = Set<String>()
    var disabledFeatureFlag = Set<String>()

    override var deviceID: String {
        return "Test"
    }

    override func value(for flagKey: String) -> Bool? {
        if enabledFeatureFlags.contains(flagKey) {
            return true
        } else if disabledFeatureFlag.contains(flagKey) {
            return false
        }
        switch flagKey {
        case RemoteFeatureFlag.jetpackFeaturesRemovalPhaseOne.remoteKey:
            return removalPhaseOne
        case RemoteFeatureFlag.jetpackFeaturesRemovalPhaseTwo.remoteKey:
            return removalPhaseTwo
        case RemoteFeatureFlag.jetpackFeaturesRemovalPhaseThree.remoteKey:
            return removalPhaseThree
        case RemoteFeatureFlag.jetpackFeaturesRemovalPhaseFour.remoteKey:
            return removalPhaseFour
        case RemoteFeatureFlag.jetpackFeaturesRemovalPhaseNewUsers.remoteKey:
            return removalPhaseNewUsers
        case RemoteFeatureFlag.jetpackFeaturesRemovalPhaseSelfHosted.remoteKey:
            return removalPhaseSelfHosted
        case RemoteFeatureFlag.jetpackFeaturesRemovalStaticPosters.remoteKey:
            return removalPhaseStaticScreens
        case RemoteFeatureFlag.inAppRating.remoteKey:
            return inAppRating
        default:
            return super.value(for: flagKey)
        }
    }
}
