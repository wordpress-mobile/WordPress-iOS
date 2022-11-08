import Foundation

/// Dynamic implementation of `JetpackFullscreenOverlayConfig`
/// Should be used for feature-specific and feature-collection overlays.
struct JetpackFullscreenOverlayGeneralConfig: JetpackFullscreenOverlayConfig {

    let phase: JetpackFeaturesRemovalCoordinator.GeneralPhase
    let source: JetpackFeaturesRemovalCoordinator.OverlaySource

    var shouldShowOverlay: Bool {
        switch (phase, source) {

        // Phase One: Only show feature-specific overlays
        case (.one, .stats):
            fallthrough
        case (.one, .notifications):
            fallthrough
        case (.one, .reader):
            return true

        // Phase Two: Only show feature-specific overlays
        case (.two, .stats):
            fallthrough
        case (.two, .notifications):
            fallthrough
        case (.two, .reader):
            return false // TODO: Change this to true when other phase 2 tasks are ready

        // Phase Three: Show all overlays
        case (.three, _):
            return false // TODO: Change this to true when other phase 3 tasks are ready

        // Phase Four: Show feature-collection overlays. Features are removed by this point so they are irrelevant.
        case (.four, _):
            return false // TODO: Change this to true when other phase 4 tasks are ready

        // New Users Phase: Show feature-collection overlays. Do not show on app-open. Features are removed by this point so they are irrelevant.
        case (.newUsers, .appOpen):
            return false
        case (.newUsers, _):
            return false // TODO: Change this to true when other new users phase tasks are ready

        default:
            return false
        }
    }

    var title: String {
        switch (phase, source) {
        // Phase One
        case (.one, .stats):
            return Strings.PhaseOne.Stats.title
        case (.one, .notifications):
            return Strings.PhaseOne.Notifications.title
        case (.one, .reader):
            return Strings.PhaseOne.Reader.title
        default:
            return ""
        }
    }

    var subtitle: String {
        return ""
    }

    var animationLtr: String {
        return ""
    }

    var animationRtl: String {
        return ""
    }

    var footnote: String? {
        return ""
    }

    var shouldShowLearnMoreButton: Bool {
        return true
    }

    var switchButtonText: String {
        return ""
    }

    var continueButtonText: String? {
        return ""
    }

    var shouldShowCloseButton: Bool {
        return true
    }

    var analyticsSource: String {
        return ""
    }
}

private extension JetpackFullscreenOverlayGeneralConfig {
    enum Strings {

        enum PhaseOne {

            enum Stats {
                static let title = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.stats.title",
                                                     value: "Get your stats using the new Jetpack app",
                                                     comment: "Title of a screen displayed when the user accesses the Stats screen from the WordPress app. The screen showcases the Jetpack app.")
            }

            enum Reader {
                static let title = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.reader.title",
                                                     value: "Follow any site with the Jetpack app",
                                                     comment: "Title of a screen displayed when the user accesses the Reader screen from the WordPress app. The screen showcases the Jetpack app.")
            }

            enum Notifications {
                static let title = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.notifications.title",
                                                     value: "Get your notifications with the Jetpack app",
                                                     comment: "Title of a screen displayed when the user accesses the Notifications screen from the WordPress app. The screen showcases the Jetpack app.")
            }
        }
    }
}
