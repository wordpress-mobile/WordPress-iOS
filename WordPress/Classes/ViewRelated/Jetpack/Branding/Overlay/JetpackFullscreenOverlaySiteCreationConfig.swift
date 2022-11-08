import Foundation

/// Dynamic implementation of `JetpackFullscreenOverlayConfig`
/// Should be used for site creation overlays.
struct JetpackFullscreenOverlaySiteCreationConfig: JetpackFullscreenOverlayConfig {

    let phase: JetpackFeaturesRemovalCoordinator.SiteCreationPhase

    var shouldShowOverlay: Bool {
        return true
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
