import Foundation
@testable import WordPress

class RemoteFeatureFlagStoreMock: RemoteFeatureFlagStore {

    var removalPhaseOne = false
    var removalPhaseTwo = false
    var removalPhaseThree = false
    var removalPhaseFour = false
    var removalPhaseNewUsers = false
    var removalPhaseSelfHosted = false

    override func value(for flag: OverrideableFlag) -> Bool {
        guard let flag = flag as? WordPress.FeatureFlag else {
            return false
        }
        switch flag {
        case .jetpackFeaturesRemovalPhaseOne:
            return removalPhaseOne
        case .jetpackFeaturesRemovalPhaseTwo:
            return removalPhaseTwo
        case .jetpackFeaturesRemovalPhaseThree:
            return removalPhaseThree
        case .jetpackFeaturesRemovalPhaseFour:
            return removalPhaseFour
        case .jetpackFeaturesRemovalPhaseNewUsers:
            return removalPhaseNewUsers
        case .jetpackFeaturesRemovalPhaseSelfHosted:
            return removalPhaseSelfHosted
        default:
            return super.value(for: flag)
        }
    }
}
