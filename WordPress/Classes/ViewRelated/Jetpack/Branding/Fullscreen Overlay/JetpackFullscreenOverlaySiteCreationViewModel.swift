import UIKit

/// Dynamic implementation of `JetpackFullscreenOverlayViewModel` based on the site creation phase
/// Should be used for Site Creation overlays.
final class JetpackFullscreenOverlaySiteCreationViewModel: JetpackFullscreenOverlayViewModel {
    let phase: JetpackFeaturesRemovalCoordinator.SiteCreationPhase
    let source: String
    let actionInfoText: NSAttributedString?
    let footnote: String?
    let learnMoreButtonURL: String?

    let coordinator: JetpackDefaultOverlayCoordinator?

    init(
        phase: JetpackFeaturesRemovalCoordinator.SiteCreationPhase,
        source: String,
        actionInfoText: NSAttributedString? = nil,
        learnMoreButtonURL: String? = nil,
        footnote: String? = nil,
        coordinator: JetpackDefaultOverlayCoordinator
    ) {
        self.phase = phase
        self.source = source
        self.footnote = footnote
        self.actionInfoText = actionInfoText
        self.learnMoreButtonURL = learnMoreButtonURL
        self.coordinator = coordinator
    }

    var shouldShowOverlay: Bool {
        phase == .two
    }

    var title: String {
        Strings.title
    }

    var subtitle: NSAttributedString {
        switch phase {
        case .two:
            return .init(string: Strings.phaseTwoSubtitle)
        case .normal:
            return .init(string: "")
        }
    }

    var animationLtr: String {
        Constants.wpJetpackLogoAnimationLtr
    }

    var animationRtl: String {
        Constants.wpJetpackLogoAnimationRtl
    }

    var switchButtonText: String {
        Strings.switchButtonTitle
    }

    var continueButtonText: String? {
        nil
    }

    var shouldShowCloseButton: Bool {
        true
    }

    var shouldDismissOnSecondaryButtonTap: Bool {
        true
    }

    var analyticsSource: String {
        Constants.analyticsSource
    }

    var onWillDismiss: JetpackOverlayDismissCallback?

    var onDidDismiss: JetpackOverlayDismissCallback?

    var secondaryView: UIView? {
        nil
    }

    var isCompact: Bool {
        false
    }

    func didTapActionInfo() {
        // No op
    }
}

private extension JetpackFullscreenOverlaySiteCreationViewModel {
    enum Constants {
        static let wpJetpackLogoAnimationLtr = "JetpackWordPressLogoAnimation_ltr"
        static let wpJetpackLogoAnimationRtl = "JetpackWordPressLogoAnimation_rtl"
        static let analyticsSource = "site_creation"
    }

    enum Strings {
        static let title = NSLocalizedString(
            "jetpack.fullscreen.overlay.siteCreation.title",
            value: "Create a new WordPress site with the Jetpack app",
            comment:
                "Title of a screen displayed when the user trys creating a new site from the WordPress app. The screen showcases the Jetpack app."
        )
        static let phaseTwoSubtitle = NSLocalizedString(
            "jetpack.fullscreen.overlay.phaseTwo.siteCreation.subtitle",
            value:
                "Jetpack provides stats, notifications and more to help you build and grow the WordPress site of your dreams.\n\nThe WordPress app no longer supports creating a new site.",
            comment:
                "Subtitle of a screen displayed when the user trys creating a new site from the WordPress app. The screen showcases the Jetpack app."
        )
        static let switchButtonTitle = NSLocalizedString(
            "jetpack.fullscreen.overlay.siteCreation.switch.title",
            value: "Try the new Jetpack app",
            comment: "Title of a button that navigates the user to the Jetpack app if installed, or to the app store."
        )
    }
}
