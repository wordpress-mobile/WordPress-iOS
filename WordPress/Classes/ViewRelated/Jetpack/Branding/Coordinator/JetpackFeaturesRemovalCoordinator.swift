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

        if featureFlagStore.value(for: FeatureFlag.jetpackBrandingPhaseNewUsers) {
            return .newUsers
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackBrandingPhaseFour) {
            return .four
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackBrandingPhaseThree) {
            return .three
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackBrandingPhaseTwo) {
            return .two
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackBrandingPhaseOne) {
            return .one
        }

        return .normal
    }

    static func siteCreationPhase(featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) -> SiteCreationPhase {
        if AppConfiguration.isJetpack {
            return .normal // Always return normal for Jetpack
        }

        if featureFlagStore.value(for: FeatureFlag.jetpackBrandingPhaseNewUsers)
            || featureFlagStore.value(for: FeatureFlag.jetpackBrandingPhaseFour) {
            return .two
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackBrandingPhaseThree)
            || featureFlagStore.value(for: FeatureFlag.jetpackBrandingPhaseTwo)
            || featureFlagStore.value(for: FeatureFlag.jetpackBrandingPhaseOne) {
            return .one
        }

        return .normal
    }
}
