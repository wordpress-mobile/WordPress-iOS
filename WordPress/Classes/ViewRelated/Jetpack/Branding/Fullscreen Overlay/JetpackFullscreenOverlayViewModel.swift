import Foundation

typealias JetpackOverlayDismissCallback = () -> Void

/// Protocol used to configure `JetpackFullscreenOverlayViewController`
protocol JetpackFullscreenOverlayViewModel {
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
    var titleLabelMaxNumberOfLines: Int { get }
    var onDismiss: JetpackOverlayDismissCallback? { get }

    func trackOverlayDisplayed()
    func trackLearnMoreTapped()
    func trackSwitchButtonTapped()
    func trackCloseButtonTapped()
    func trackContinueButtonTapped()
}

extension JetpackFullscreenOverlayViewModel {
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
