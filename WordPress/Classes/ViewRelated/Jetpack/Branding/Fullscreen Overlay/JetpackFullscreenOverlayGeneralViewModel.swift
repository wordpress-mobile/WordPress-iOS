import Foundation
import WordPressData
import WordPressShared

/// Dynamic implementation of `JetpackFullscreenOverlayViewModel` based on the general phase
/// Should be used for feature-specific and feature-collection overlays.
final class JetpackFullscreenOverlayGeneralViewModel: JetpackFullscreenOverlayViewModel {
    let phase: JetpackFeaturesRemovalCoordinator.GeneralPhase
    let source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource
    let blog: Blog?
    let actionInfoText: NSAttributedString?

    let coordinator: JetpackDefaultOverlayCoordinator?

    init(
        phase: JetpackFeaturesRemovalCoordinator.GeneralPhase,
        source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource,
        blog: Blog?,
        actionInfoText: NSAttributedString? = nil,
        coordinator: JetpackDefaultOverlayCoordinator
    ) {
        self.phase = phase
        self.source = source
        self.blog = blog
        self.actionInfoText = actionInfoText
        self.coordinator = coordinator
    }

    var shouldShowOverlay: Bool {
        switch (phase, source) {
        // Do not show feature overlays in phases where they are removed.
        case (_, .stats), (_, .reader), (_, .notifications):
            return false

        // Self-Hosted Users Phase: Show feature-collection overlays.
        case (.selfHosted, _):
            return blog?.jetpackIsConnected ?? false

        case (.normal, _), (.staticScreens, _):
            return false
        }
    }

    var title: String {
        phase == .selfHosted ? Strings.SelfHosted.generalTitle : ""
    }

    var subtitle: NSAttributedString {
        attributedSubtitle(with: phase == .selfHosted ? Strings.SelfHosted.subtitle : "")
    }

    var animationLtr: String {
        switch (source, phase) {
        case (.stats, _):
            return Constants.statsLogoAnimationLtr
        case (.notifications, _):
            return Constants.notificationsLogoAnimationLtr
        case (.reader, _):
            return Constants.readerLogoAnimationLtr
        case (_, .selfHosted):
            return Constants.wpJetpackLogoAnimationLtr
        case (.card, _), (.login, _), (.appOpen, _), (.disabledEntryPoint, _):
            return Constants.allFeaturesLogosAnimationLtr
        }
    }

    var animationRtl: String {
        switch (source, phase) {
        case (.stats, _):
            return Constants.statsLogoAnimationRtl
        case (.notifications, _):
            return Constants.notificationsLogoAnimationRtl
        case (.reader, _):
            return Constants.readerLogoAnimationRtl
        case (_, .selfHosted):
            return Constants.wpJetpackLogoAnimationRtl
        case (.card, _), (.login, _), (.appOpen, _), (.disabledEntryPoint, _):
            return Constants.allFeaturesLogosAnimationRtl
        }
    }

    var footnote: String? {
        phase == .selfHosted ? Strings.General.footnote : nil
    }

    var learnMoreButtonURL: String? {
        nil
    }

    var switchButtonText: String {
        phase == .selfHosted ? Strings.General.switchButtonTitle : ""
    }

    var continueButtonText: String? {
        switch source {
        case .stats:
            return Strings.General.statsContinueButtonTitle
        case .notifications:
            return Strings.General.notificationsContinueButtonTitle
        case .reader:
            return Strings.General.readerContinueButtonTitle
        default:
            return Strings.General.continueButtonTitle
        }
    }

    var shouldShowCloseButton: Bool {
        false
    }

    var shouldDismissOnSecondaryButtonTap: Bool {
        true
    }

    var analyticsSource: String {
        source.rawValue
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
        // No op.
    }
}

// MARK: Helpers

private extension JetpackFullscreenOverlayGeneralViewModel {
    func attributedSubtitle(with string: String) -> NSAttributedString {
        let font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        return NSAttributedString(string: string, attributes: [.font: font])
    }
}

// MARK: Constants

private extension JetpackFullscreenOverlayGeneralViewModel {
    enum Constants {
        static let statsLogoAnimationLtr = "JetpackStatsLogoAnimation_ltr"
        static let statsLogoAnimationRtl = "JetpackStatsLogoAnimation_rtl"
        static let readerLogoAnimationLtr = "JetpackReaderLogoAnimation_ltr"
        static let readerLogoAnimationRtl = "JetpackReaderLogoAnimation_rtl"
        static let notificationsLogoAnimationLtr = "JetpackNotificationsLogoAnimation_ltr"
        static let notificationsLogoAnimationRtl = "JetpackNotificationsLogoAnimation_rtl"
        static let allFeaturesLogosAnimationLtr = "JetpackAllFeaturesLogosAnimation_ltr"
        static let allFeaturesLogosAnimationRtl = "JetpackAllFeaturesLogosAnimation_rtl"
        static let wpJetpackLogoAnimationLtr = "JetpackWordPressLogoAnimation_ltr"
        static let wpJetpackLogoAnimationRtl = "JetpackWordPressLogoAnimation_rtl"
    }

    enum Strings {

        enum General {
            static let switchButtonTitle = NSLocalizedString(
                "jetpack.fullscreen.overlay.late.switch.title",
                value: "Switch to the Jetpack app",
                comment:
                    "Title of a button that navigates the user to the Jetpack app if installed, or to the app store."
            )
            static let statsContinueButtonTitle = NSLocalizedString(
                "jetpack.fullscreen.overlay.stats.continue.title",
                value: "Continue to Stats",
                comment: "Title of a button that dismisses an overlay and displays the Stats screen."
            )
            static let readerContinueButtonTitle = NSLocalizedString(
                "jetpack.fullscreen.overlay.reader.continue.title",
                value: "Continue to Reader",
                comment: "Title of a button that dismisses an overlay and displays the Reader screen."
            )
            static let notificationsContinueButtonTitle = NSLocalizedString(
                "jetpack.fullscreen.overlay.notifications.continue.title",
                value: "Continue to Notifications",
                comment: "Title of a button that dismisses an overlay and displays the Notifications screen."
            )
            static let continueButtonTitle = NSLocalizedString(
                "jetpack.fullscreen.overlay.phaseThree.general.continue.title",
                value: "Continue without Jetpack",
                comment: "Title of a button that dismisses an overlay that showcases the Jetpack app."
            )
            static let footnote = NSLocalizedString(
                "jetpack.fullscreen.overlay.phaseThree.footnote",
                value: "Switching is free and only takes a minute.",
                comment:
                    "A footnote in a screen displayed when the user accesses a Jetpack powered feature from the WordPress app. The screen showcases the Jetpack app."
            )
        }

        enum SelfHosted {
            static let generalTitle = NSLocalizedString(
                "jetpack.fullscreen.overlay.selfHosted.title",
                value: "Your site has the Jetpack plugin",
                comment: "Title of a screen that prompts the user to switch the Jetpack app."
            )

            static let subtitle = NSLocalizedString(
                "jetpack.fullscreen.overlay.selfHosted.subtitle",
                value:
                    "The Jetpack mobile app is designed to work in companion with the Jetpack plugin. Switch now to get access to Stats, Reader, Notifications and more.",
                comment: "Title of a screen that prompts the user to switch the Jetpack app."
            )
        }
    }
}
