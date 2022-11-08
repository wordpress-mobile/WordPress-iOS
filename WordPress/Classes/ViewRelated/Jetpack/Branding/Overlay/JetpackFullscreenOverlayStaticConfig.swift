import Foundation

/// Static implementation of `JetpackFullscreenOverlayConfig`
/// Should be used when the overlay doesn't relate to a dynamic phase
struct JetpackFullscreenOverlayStaticConfig: JetpackFullscreenOverlayConfig {
    let title: String
    let subtitle: String
    let animationLtr: String
    let animationRtl: String
    let footnote: String?
    let shouldShowLearnMoreButton: Bool
    let switchButtonText: String
    let continueButtonText: String?
    let shouldShowCloseButton: Bool
    let analyticsSource: String
}
