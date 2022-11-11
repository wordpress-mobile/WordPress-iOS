import Foundation

/// Protocol used to configure `JetpackFullscreenOverlayViewController`
protocol JetpackFullscreenOverlayConfig {
    var title: String { get }
    var subtitle: String { get }
    var animationLtr: String { get }
    var animationRtl: String { get }
    var footnote: String? { get }
    var shouldShowLearnMoreButton: Bool { get }
    var switchButtonText: String { get }
    var continueButtonText: String? { get }
    var shouldShowCloseButton: Bool { get }
    var analyticsSource: String { get }

    func trackOverlayDisplayed()
    func trackLearnMoreTapped()
    func trackSwitchButtonTapped()
    func trackCloseButtonTapped()
    func trackOverlaySwippedDown()
    func trackContinueButtonTapped()
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
