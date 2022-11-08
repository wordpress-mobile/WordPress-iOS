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
        switch (phase, source) {
        // Phase One
        case (.one, .stats):
            return Strings.PhaseOne.Stats.subtitle
        case (.one, .notifications):
            return Strings.PhaseOne.Notifications.subtitle
        case (.one, .reader):
            return Strings.PhaseOne.Reader.subtitle
        default:
            return ""
        }
    }

    var animationLtr: String {
        switch source {
        case .stats:
            return "JetpackStatsLogoAnimation_ltr"
        case .notifications:
            return "JetpackNotificationsLogoAnimation_ltr"
        case .reader:
            return "JetpackReaderLogoAnimation_ltr"
        case .card:
            fallthrough
        case .login:
            fallthrough
        case .appOpen:
            return "" // TODO: Add new animation when ready
        }
    }

    var animationRtl: String {
        switch source {
        case .stats:
            return "JetpackStatsLogoAnimation_rtl"
        case .notifications:
            return "JetpackNotificationsLogoAnimation_rtl"
        case .reader:
            return "JetpackReaderLogoAnimation_rtl"
        case .card:
            fallthrough
        case .login:
            fallthrough
        case .appOpen:
            return "" // TODO: Add new animation when ready
        }
    }

    var footnote: String? {
        switch phase {
        case .one:
            return nil
        default:
            return nil
        }
    }

    var shouldShowLearnMoreButton: Bool {
        switch phase {
        case .one:
            return false
        default:
            return false
        }
    }

    var switchButtonText: String {
        switch phase {
        case .one:
            return Strings.earlyPhasesSwitchButtonTitle
        default:
            return ""
        }
    }

    var continueButtonText: String? {
        return ""
    }

    var shouldShowCloseButton: Bool {
        return true
    }

    var analyticsSource: String {
        return source.rawValue
    }
}

private extension JetpackFullscreenOverlayGeneralConfig {
    enum Strings {

        static let earlyPhasesSwitchButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.early.switch.title",
                                                                    value: "Switch to the new Jetpack app",
                                                                    comment: "Title of a button that navigates the user to the Jetpack app if installed, or to the app store.")

        enum PhaseOne {

            enum Stats {
                static let title = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.stats.title",
                                                     value: "Get your stats using the new Jetpack app",
                                                     comment: "Title of a screen displayed when the user accesses the Stats screen from the WordPress app. The screen showcases the Jetpack app.")
                static let subtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.stats.subtitle",
                                                     value: "Switch to the Jetpack app to watch your site’s traffic grow with stats and insights.",
                                                     comment: "Subtitle of a screen displayed when the user accesses the Stats screen from the WordPress app. The screen showcases the Jetpack app.")
            }

            enum Reader {
                static let title = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.reader.title",
                                                     value: "Follow any site with the Jetpack app",
                                                     comment: "Title of a screen displayed when the user accesses the Reader screen from the WordPress app. The screen showcases the Jetpack app.")
                static let subtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.reader.subtitle",
                                                     value: "Switch to the Jetpack app to find, fillow, and like all your favorite sites and posts with Reader.",
                                                     comment: "Subtitle of a screen displayed when the user accesses the Reader screen from the WordPress app. The screen showcases the Jetpack app.")
            }

            enum Notifications {
                static let title = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.notifications.title",
                                                     value: "Get your notifications with the Jetpack app",
                                                     comment: "Title of a screen displayed when the user accesses the Notifications screen from the WordPress app. The screen showcases the Jetpack app.")
                static let subtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.notifications.subtitle",
                                                     value: "Switch to the Jetpack app to keep recieving real-time notifications on your device.",
                                                     comment: "Subtitle of a screen displayed when the user accesses the Notifications screen from the WordPress app. The screen showcases the Jetpack app.")
            }
        }
    }
}
