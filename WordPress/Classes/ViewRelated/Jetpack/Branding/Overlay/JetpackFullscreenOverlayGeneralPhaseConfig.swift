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
        return ""
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
