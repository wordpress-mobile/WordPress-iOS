import Foundation

typealias JetpackOverlayDismissCallback = () -> Void

/// Protocol used to configure `JetpackFullscreenOverlayViewController`
protocol JetpackFullscreenOverlayViewModel {
    var title: String { get }
    var subtitle: NSAttributedString { get }
    var animationLtr: String { get }
    var animationRtl: String { get }
    var footnote: String? { get }
    var learnMoreButtonURL: String? { get }
    var switchButtonText: String { get }
    var continueButtonText: String? { get }
    var shouldShowCloseButton: Bool { get }
    var analyticsSource: String { get }
    var onWillDismiss: JetpackOverlayDismissCallback? { get }
    var onDidDismiss: JetpackOverlayDismissCallback? { get }

    /// An optional view.
    /// If provided, the view will be added to the overlay before the learn more button
    var secondaryView: UIView? { get }

    func trackOverlayDisplayed()
    func trackLearnMoreTapped()
    func trackSwitchButtonTapped()
    func trackCloseButtonTapped()
    func trackContinueButtonTapped()
}

extension JetpackFullscreenOverlayViewModel {
    var learnMoreButtonIsHidden: Bool {
        learnMoreButtonURL == nil
    }

    var footnoteIsHidden: Bool {
        footnote == nil
    }

    var continueButtonIsHidden: Bool {
        continueButtonText == nil
    }
}
