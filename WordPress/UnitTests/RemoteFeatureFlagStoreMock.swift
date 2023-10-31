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

    override func value(for flagKey: String) -> Bool? {
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
        default:
            return super.value(for: flagKey)
        }
    }
}
