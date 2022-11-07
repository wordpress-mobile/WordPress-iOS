import Foundation

/// A class containing convenience methods for the the Jetpack features removal experience
class JetpackFeaturesRemovalCoordinator {

    /// Enum descibing the current phase of the Jetpack features removal
    enum GeneralPhase {
        case normal
        case one
        case two
        case three
        case four
        case newUsers
    }

    /// Enum descibing the current phase of the site creation flow removal
    enum SiteCreationPhase {
        case normal
        case one
        case two
    }

    static func generalPhase(featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) -> GeneralPhase {
        if AppConfiguration.isJetpack {
            return .normal // Always return normal for Jetpack
        }

        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseNewUsers) {
            return .newUsers
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseFour) {
            return .four
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseThree) {
            return .three
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseTwo) {
            return .two
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseOne) {
            return .one
        }

        return .normal
    }

    static func siteCreationPhase(featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) -> SiteCreationPhase {
        if AppConfiguration.isJetpack {
            return .normal // Always return normal for Jetpack
        }

        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseNewUsers)
            || featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseFour) {
            return .two
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseThree)
            || featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseTwo)
            || featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseOne) {
            return .one
        }

        return .normal
    }
}
