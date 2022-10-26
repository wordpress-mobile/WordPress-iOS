import Foundation

struct JetpackFullscreenOverlayConfig {
    let title: String
    let subtitle: String
    let icon: UIImage
    let footnote: String?
    let showLearnMoreButton: Bool
    let switchButtonText: String
    let continueButtonText: String?
}

extension JetpackFullscreenOverlayConfig {
    var learnMoreButtonIsHidden: Bool {
        !showLearnMoreButton
    }

    var footnoteIsHidden: Bool {
        footnote == nil
    }

    var continueButtonIsHidden: Bool {
        continueButtonText == nil
    }
}
