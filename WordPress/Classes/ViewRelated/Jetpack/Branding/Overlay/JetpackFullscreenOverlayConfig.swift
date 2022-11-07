import Foundation

struct JetpackFullscreenOverlayConfig {
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

extension JetpackFullscreenOverlayConfig {
    var learnMoreButtonIsHidden: Bool {
        !shouldShowLearnMoreButton
    }

    var footnoteIsHidden: Bool {
        footnote == nil
    }

    var continueButtonIsHidden: Bool {
        continueButtonText == nil
    }
}
