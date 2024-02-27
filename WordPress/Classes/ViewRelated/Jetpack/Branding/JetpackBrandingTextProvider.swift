import Foundation

struct JetpackBrandingTextProvider {

    // MARK: Private Variables

    private let screen: JetpackBrandedScreen?
    private let featureFlagStore: RemoteFeatureFlagStore
    private let remoteConfigStore: RemoteConfigStore
    private let currentDateProvider: CurrentDateProvider

    private var phase: JetpackFeaturesRemovalCoordinator.GeneralPhase {
        return JetpackFeaturesRemovalCoordinator.generalPhase(featureFlagStore: featureFlagStore)
    }

    // MARK: Initializer

    init(screen: JetpackBrandedScreen?,
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
        case .three:
            return phaseThreeText()
        case .staticScreens:
            return staticScreensPhaseText()
        default:
            return Strings.defaultText
        }
    }

    // MARK: Helpers

    private func phaseThreeText() -> String {
        guard let screen = screen, let featureName = screen.featureName else {
            return Strings.defaultText // Screen not provided, or was opted out by defining a nil featureName
        }

        guard let deadline = JetpackFeaturesRemovalCoordinator.removalDeadline(remoteConfigStore: remoteConfigStore) else {
            return String(format: movingSoonString, featureName) // Couldn't retrieve the deadline
        }

        let now = currentDateProvider.date()
        guard now < deadline else {
            return Strings.defaultText // Deadline has passed. Avoid displaying negative values.
        }

        guard let dateString = dateString(now: now, deadline: deadline) else {
            return String(format: movingSoonString, featureName) // Deadline is more than a month away
        }

        return String(format: movingInString, featureName, dateString)
    }

    private func staticScreensPhaseText() -> String {
        guard let screen = screen, let _ = screen.featureName else {
            return Strings.defaultText // Screen not provided, or was opted out by defining a nil featureName
        }

        return Strings.phaseStaticScreensText
    }

    private func dateString(now: Date, deadline: Date) -> String? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.month], from: now, to: deadline)
        let months = components.month ?? 0
        if months > 0 {
            return nil // Fallback to moving soon text
        }

        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .full

        components = calendar.dateComponents([.weekOfMonth], from: now, to: deadline)
        let weeks = components.weekOfMonth ?? 0
        if weeks > 0 {
            formatter.allowedUnits = [.weekOfMonth]
            return formatter.string(from: components) // Deadline is x weeks away
        }

        components = calendar.dateComponents([.day], from: now, to: deadline)
        let days = max(components.day ?? 0, 1) // Avoid displaying "0 days"
        components.day = days
        formatter.allowedUnits = [.day]
        return formatter.string(from: components) // Deadline is x days away
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
        static let phaseThreePluralMovingSoonText = NSLocalizedString("jetpack.branding.badge_banner.moving_soon.plural",
                                                                      value: "%@ are moving soon",
                                                                      comment: "Title of a badge indicating that a feature in plural form will be removed soon. First argument is the feature name. Ex: Notifications are moving soon")
        static let phaseThreeSingularMovingSoonText = NSLocalizedString("jetpack.branding.badge_banner.moving_soon.singular",
                                                                      value: "%@ is moving soon",
                                                                      comment: "Title of a badge indicating that a feature in singular form will be removed soon. First argument is the feature name. Ex: Reader is moving soon")
        static let phaseThreePluralMovingInText = NSLocalizedString("jetpack.branding.badge_banner.moving_in.plural",
                                                                      value: "%@ are moving in %@",
                                                                      comment: "Title of a badge indicating when a feature in plural form will be removed. First argument is the feature name. Second argument is the number of days/weeks it will be removed in. Ex: Notifications are moving in 2 weeks")
        static let phaseThreeSingularMovingInText = NSLocalizedString("jetpack.branding.badge_banner.moving_in.singular",
                                                                      value: "%@ is moving in %@",
                                                                      comment: "Title of a badge indicating when a feature in singular form will be removed. First argument is the feature name. Second argument is the number of days/weeks it will be removed in. Ex: Reader is moving in 2 weeks")
        static let phaseStaticScreensText = defaultText
    }

    private var isPlural: Bool {
        screen?.isPlural ?? false
    }

    var movingSoonString: String {
        return isPlural ? Strings.phaseThreePluralMovingSoonText : Strings.phaseThreeSingularMovingSoonText
    }

    var movingInString: String {
        return isPlural ? Strings.phaseThreePluralMovingInText : Strings.phaseThreeSingularMovingInText
    }
}
