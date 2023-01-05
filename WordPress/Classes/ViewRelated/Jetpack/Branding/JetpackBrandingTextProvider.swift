import Foundation

struct JetpackBrandingTextProvider {

    // MARK: Private Variables

    private let screen: JetpackBrandedScreen
    private let featureFlagStore: RemoteFeatureFlagStore
    private let remoteConfigStore: RemoteConfigStore
    private let currentDateProvider: CurrentDateProvider

    private var phase: JetpackFeaturesRemovalCoordinator.GeneralPhase {
        return JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: featureFlagStore)
    }

    // MARK: Initializer

    init(screen: JetpackBrandedScreen,
         featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
         remoteConfigStore: RemoteConfigStore = RemoteConfigStore(),
         currentDateProvider: CurrentDateProvider = DefaultCurrentDateProvider()) {
        self.screen = screen
        self.featureFlagStore = featureFlagStore
        self.remoteConfigStore = remoteConfigStore
        self.currentDateProvider = currentDateProvider
    }

    // MARK: Public Functions

    func brandingText() -> String {
        switch phase {
        case .two:
            return Strings.phaseTwoText
        default:
            return Strings.defaultText
        }
    }
}

private extension JetpackBrandingTextProvider {
    enum Strings {
        static let defaultText = NSLocalizedString("jetpack.branding.badge_banner.title",
                                                   value: "Jetpack powered",
                                                   comment: "Title of the Jetpack powered badge.")
        static let phaseTwoText = NSLocalizedString("jetpack.branding.badge_banner.title.phase2",
                                                    value: "Get the Jetpack app",
                                                    comment: "Title of the Jetpack powered badge.")
    }
}
