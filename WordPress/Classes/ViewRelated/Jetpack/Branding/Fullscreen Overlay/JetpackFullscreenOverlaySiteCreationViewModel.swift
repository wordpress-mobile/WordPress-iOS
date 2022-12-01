import Foundation

/// Dynamic implementation of `JetpackFullscreenOverlayViewModel` based on the site creation phase
/// Should be used for Site Creation overlays.
struct JetpackFullscreenOverlaySiteCreationViewModel: JetpackFullscreenOverlayViewModel {

    let phase: JetpackFeaturesRemovalCoordinator.SiteCreationPhase
    let source: String

    var shouldShowOverlay: Bool {
        switch phase {
        case .normal:
            return false
        case .one:
            fallthrough
        case .two:
            return true
        }
    }

    var title: String {
        return Strings.title
    }

    var subtitle: NSAttributedString {
        switch phase {
        case .one:
            return .init(string: Strings.phaseOneSubtitle)
        case .two:
            return .init(string: Strings.phaseTwoSubtitle)
        default:
            return .init(string: "")
        }
    }

    var animationLtr: String {
        return Constants.wpJetpackLogoAnimationLtr
    }

    var animationRtl: String {
        return Constants.wpJetpackLogoAnimationRtl
    }

    var footnote: String? {
        return nil
    }

    var learnMoreButtonURL: String? {
        return nil
    }

    var switchButtonText: String {
        return Strings.switchButtonTitle
    }

    var continueButtonText: String? {
        switch phase {
        // Show only in phase one
        case .one:
            return Strings.continueButtonTitle
        default:
            return nil
        }
    }

    var shouldShowCloseButton: Bool {
        return true
    }

    var analyticsSource: String {
        return Constants.analyticsSource
    }

    var onDismiss: JetpackOverlayDismissCallback?
}

private extension JetpackFullscreenOverlaySiteCreationViewModel {
    enum Constants {
        static let wpJetpackLogoAnimationLtr = "JetpackWordPressLogoAnimation_ltr"
        static let wpJetpackLogoAnimationRtl = "JetpackWordPressLogoAnimation_rtl"
        static let analyticsSource = "site_creation"
    }

    enum Strings {
        static let title = NSLocalizedString("jetpack.fullscreen.overlay.siteCreation.title",
                                             value: "Create a new WordPress site with the Jetpack app",
                                             comment: "Title of a screen displayed when the user trys creating a new site from the WordPress app. The screen showcases the Jetpack app.")
        static let phaseOneSubtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.siteCreation.subtitle",
                                             value: "Jetpack provides stats, notifications and more to help you build and grow the WordPress site of your dreams.",
                                             comment: "Subtitle of a screen displayed when the user trys creating a new site from the WordPress app. The screen showcases the Jetpack app.")
        static let phaseTwoSubtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseTwo.siteCreation.subtitle",
                                             value: "Jetpack provides stats, notifications and more to help you build and grow the WordPress site of your dreams.\n\nThe WordPress app no longer supports creating a new site.",
                                             comment: "Subtitle of a screen displayed when the user trys creating a new site from the WordPress app. The screen showcases the Jetpack app.")
        static let switchButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.siteCreation.switch.title",
                                                                    value: "Try the new Jetpack app",
                                                                    comment: "Title of a button that navigates the user to the Jetpack app if installed, or to the app store.")
        static let continueButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.siteCreation.continue.title",
                                                                    value: "Continue without Jetpack",
                                                                    comment: "Title of a button that navigates the user to the Jetpack app if installed, or to the app store.")
    }
}
