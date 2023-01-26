import Foundation

/// Dynamic implementation of `JetpackFullscreenOverlayViewModel` based on the general phase
/// Should be used for feature-specific and feature-collection overlays.
struct JetpackFullscreenOverlayGeneralViewModel: JetpackFullscreenOverlayViewModel {

    let phase: JetpackFeaturesRemovalCoordinator.GeneralPhase
    let source: JetpackFeaturesRemovalCoordinator.OverlaySource
    let blog: Blog?

    var shouldShowOverlay: Bool {
        switch (phase, source) {

        // Phase One: Only show feature-specific overlays
        case (.one, .stats):
            fallthrough
        case (.one, .notifications):
            fallthrough
        case (.one, .reader):
            return true

        // Phase Two: Only show feature-specific overlays
        case (.two, .stats):
            fallthrough
        case (.two, .notifications):
            fallthrough
        case (.two, .reader):
            return true

        // Phase Three: Show all overlays
        case (.three, _):
            return true

        // Do not show feature overlays in phases where they are removed.
        case (_, .stats):
            fallthrough
        case (_, .reader):
            fallthrough
        case (_, .notifications):
            return false

        // Phase Four: Show feature-collection overlays.
        case (.four, _):
            return true

        // New Users Phase: Show feature-collection overlays.
        case (.newUsers, _):
            return true

        // Self-Hosted Users Phase: Show feature-collection overlays.
        case (.selfHosted, _):
            return blog?.jetpackIsConnected ?? false

        default:
            return false
        }
    }

    var title: String {
        switch (phase, source) {
        // Phase One
        case (.one, .stats):
            return Strings.PhaseOne.Stats.title
        case (.one, .notifications):
            return Strings.PhaseOne.Notifications.title
        case (.one, .reader):
            return Strings.PhaseOne.Reader.title

        // Phase Two
        case (.two, .stats):
            return Strings.PhaseTwoAndThree.statsTitle
        case (.two, .notifications):
            return Strings.PhaseTwoAndThree.notificationsTitle
        case (.two, .reader):
            return Strings.PhaseTwoAndThree.readerTitle

        // Phase Three
        case (.three, .stats):
            return Strings.PhaseTwoAndThree.statsTitle
        case (.three, .notifications):
            return Strings.PhaseTwoAndThree.notificationsTitle
        case (.three, .reader):
            return Strings.PhaseTwoAndThree.readerTitle
        case (.three, _):
            return Strings.PhaseThree.generalTitle

        // Phase Four
        case (.four, _):
            return Strings.PhaseFour.generalTitle

        // New Users
        case (.newUsers, _):
            return Strings.NewUsers.generalTitle

        // Self-Hosted
        case (.selfHosted, _):
            return Strings.SelfHosted.generalTitle
        default:
            return ""
        }
    }

    var subtitle: NSAttributedString {
        switch (phase, source) {
        // Phase One
        case (.one, .stats):
            return attributedSubtitle(with: Strings.PhaseOne.Stats.subtitle)
        case (.one, .notifications):
            return attributedSubtitle(with: Strings.PhaseOne.Notifications.subtitle)
        case (.one, .reader):
            return attributedSubtitle(with: Strings.PhaseOne.Reader.subtitle)

        // Phase Two
        case (.two, _):
            fallthrough

        // Phase Three
        case (.three, _):
            return phaseTwoAndThreeSubtitle()

        // Phase Four
        case (.four, _):
            return attributedSubtitle(with: Strings.PhaseFour.subtitle)

        // New Users
        case (.newUsers, _):
            return attributedSubtitle(with: Strings.NewUsers.subtitle)

        // Self-Hosted
        case (.selfHosted, _):
            return attributedSubtitle(with: Strings.SelfHosted.subtitle)

        default:
            return attributedSubtitle(with: "")
        }
    }

    var animationLtr: String {
        switch (source, phase) {
        case (.stats, _):
            return Constants.statsLogoAnimationLtr
        case (.notifications, _):
            return Constants.notificationsLogoAnimationLtr
        case (.reader, _):
            return Constants.readerLogoAnimationLtr
        case (_, .newUsers):
            fallthrough
        case (_, .selfHosted):
            return Constants.wpJetpackLogoAnimationLtr
        case (.card, _):
            fallthrough
        case (.login, _):
            fallthrough
        case (.appOpen, _):
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
        case (_, .newUsers):
            fallthrough
        case (_, .selfHosted):
            return Constants.wpJetpackLogoAnimationRtl
        case (.card, _):
            fallthrough
        case (.login, _):
            fallthrough
        case (.appOpen, _):
            return Constants.allFeaturesLogosAnimationRtl
        }
    }

    var footnote: String? {
        switch phase {
        case .one:
            return nil
        case .two:
            return nil
        case .three:
            fallthrough
        case .four:
            fallthrough
        case .newUsers:
            fallthrough
        case .selfHosted:
            return Strings.General.footnote
        default:
            return nil
        }
    }

    var learnMoreButtonURL: String? {
        switch phase {
        case .one:
            return nil
        case .two:
            return RemoteConfig().phaseTwoBlogPostUrl.value
        case .three:
            return RemoteConfig().phaseThreeBlogPostUrl.value
        case .four:
            return RemoteConfig().phaseFourBlogPostUrl.value
        default:
            return nil
        }
    }

    var switchButtonText: String {
        switch phase {
        case .one:
            fallthrough
        case .two:
            return Strings.General.earlyPhasesSwitchButtonTitle
        case .three:
            fallthrough
        case .four:
            fallthrough
        case .newUsers:
            fallthrough
        case .selfHosted:
            return Strings.General.latePhasesSwitchButtonTitle
        default:
            return ""
        }
    }

    var continueButtonText: String? {
        switch (source, phase) {
        case (.stats, _):
            return Strings.General.statsContinueButtonTitle
        case (.notifications, _):
            return Strings.General.notificationsContinueButtonTitle
        case (.reader, _):
            return Strings.General.readerContinueButtonTitle
        case (_, .four):
            return Strings.PhaseFour.generalContinueButtonTitle
        default:
            return Strings.General.continueButtonTitle
        }
    }

    var shouldShowCloseButton: Bool {
        switch phase {
        case .one:
            fallthrough
        case .two:
            return true // Only show close button in phases 1 & 2
        default:
            return false
        }
    }

    var analyticsSource: String {
        return source.rawValue
    }

    var onWillDismiss: JetpackOverlayDismissCallback?

    var onDidDismiss: JetpackOverlayDismissCallback?

    var secondaryView: UIView? {
        switch phase {
        case .newUsers:
            return JetpackNewUsersOverlaySecondaryView()
        default:
            return nil
        }
    }

    var isCompact: Bool {
        return phase == .newUsers
    }
}

// MARK: Helpers

private extension JetpackFullscreenOverlayGeneralViewModel {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    func attributedSubtitle(with string: String) -> NSAttributedString {
        let font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        return NSAttributedString(string: string, attributes: [.font: font])
    }

    func phaseTwoAndThreeSubtitle() -> NSAttributedString {
        guard let deadline = JetpackFeaturesRemovalCoordinator.removalDeadline() else {
            return attributedSubtitle(with: Strings.PhaseTwoAndThree.fallbackSubtitle)
        }

        let formattedDate = Self.dateFormatter.string(from: deadline)
        let subtitle = String.localizedStringWithFormat(Strings.PhaseTwoAndThree.subtitle, formattedDate)

        let rangeOfDate = (subtitle as NSString).range(of: formattedDate)
        let plainFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        let boldFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .bold)
        let attributedSubtitle = NSMutableAttributedString(string: subtitle, attributes: [.font: plainFont])
        attributedSubtitle.addAttribute(.font, value: boldFont, range: rangeOfDate)

        return attributedSubtitle
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
            static let earlyPhasesSwitchButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.early.switch.title",
                                                                        value: "Switch to the new Jetpack app",
                                                                        comment: "Title of a button that navigates the user to the Jetpack app if installed, or to the app store.")
            static let latePhasesSwitchButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.late.switch.title",
                                                                        value: "Switch to the Jetpack app",
                                                                        comment: "Title of a button that navigates the user to the Jetpack app if installed, or to the app store.")
            static let statsContinueButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.stats.continue.title",
                                                                    value: "Continue to Stats",
                                                                    comment: "Title of a button that dismisses an overlay and displays the Stats screen.")
            static let readerContinueButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.reader.continue.title",
                                                                     value: "Continue to Reader",
                                                                     comment: "Title of a button that dismisses an overlay and displays the Reader screen.")
            static let notificationsContinueButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.notifications.continue.title",
                                                                            value: "Continue to Notifications",
                                                                            comment: "Title of a button that dismisses an overlay and displays the Notifications screen.")
            static let continueButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseThree.general.continue.title",
                                                               value: "Continue without Jetpack",
                                                               comment: "Title of a button that dismisses an overlay that showcases the Jetpack app.")
            static let footnote = NSLocalizedString("jetpack.fullscreen.overlay.phaseThree.footnote",
                                                    value: "Switching is free and only takes a minute.",
                                                    comment: "A footnote in a screen displayed when the user accesses a Jetpack powered feature from the WordPress app. The screen showcases the Jetpack app.")
        }

        enum PhaseOne {

            enum Stats {
                static let title = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.stats.title",
                                                     value: "Get your stats using the new Jetpack app",
                                                     comment: "Title of a screen displayed when the user accesses the Stats screen from the WordPress app. The screen showcases the Jetpack app.")
                static let subtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.stats.subtitle",
                                                     value: "Switch to the Jetpack app to watch your site’s traffic grow with stats and insights.",
                                                     comment: "Subtitle of a screen displayed when the user accesses the Stats screen from the WordPress app. The screen showcases the Jetpack app.")
            }

            enum Reader {
                static let title = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.reader.title",
                                                     value: "Follow any site with the Jetpack app",
                                                     comment: "Title of a screen displayed when the user accesses the Reader screen from the WordPress app. The screen showcases the Jetpack app.")
                static let subtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.reader.subtitle",
                                                     value: "Switch to the Jetpack app to find, follow, and like all your favorite sites and posts with Reader.",
                                                     comment: "Subtitle of a screen displayed when the user accesses the Reader screen from the WordPress app. The screen showcases the Jetpack app.")
            }

            enum Notifications {
                static let title = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.notifications.title",
                                                     value: "Get your notifications with the Jetpack app",
                                                     comment: "Title of a screen displayed when the user accesses the Notifications screen from the WordPress app. The screen showcases the Jetpack app.")
                static let subtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseOne.notifications.subtitle",
                                                     value: "Switch to the Jetpack app to keep receiving real-time notifications on your device.",
                                                     comment: "Subtitle of a screen displayed when the user accesses the Notifications screen from the WordPress app. The screen showcases the Jetpack app.")
            }
        }

        enum PhaseTwoAndThree {
            static let statsTitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseTwoAndThree.stats.title",
                                                      value: "Stats are moving to the Jetpack app",
                                                      comment: "Title of a screen displayed when the user accesses the Stats screen from the WordPress app. The screen showcases the Jetpack app.")
            static let readerTitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseTwoAndThree.reader.title",
                                                       value: "Reader is moving to the Jetpack app",
                                                       comment: "Title of a screen displayed when the user accesses the Reader screen from the WordPress app. The screen showcases the Jetpack app.")
            static let notificationsTitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseTwoAndThree.notifications.title",
                                                              value: "Notifications are moving to Jetpack",
                                                              comment: "Title of a screen displayed when the user accesses the Notifications screen from the WordPress app. The screen showcases the Jetpack app.")
            static let subtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseTwoAndThree.subtitle",
                                                    value: "Stats, Reader, Notifications and other Jetpack powered features will be removed from the WordPress app on %@.",
                                                    comment: "Subtitle of a screen displayed when the user accesses a Jetpack-powered feature from the WordPress app. The '%@' characters are a placeholder for the date the features will be removed.")
            static let fallbackSubtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseTwoAndThree.fallbackSubtitle",
                                                    value: "Stats, Reader, Notifications and other Jetpack powered features will be removed from the WordPress app soon.",
                                                    comment: "Subtitle of a screen displayed when the user accesses a Jetpack-powered feature from the WordPress app.")
        }

        enum PhaseThree {
            static let generalTitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseThree.general.title",
                                                        value: "Jetpack features are moving soon.",
                                                        comment: "Title of a screen that showcases the Jetpack app.")
        }

        enum PhaseFour {
            static let generalTitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseFour.title",
                                                        value: "Jetpack features have moved.",
                                                        comment: "Title of a screen that prompts the user to switch the Jetpack app.")

            static let subtitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseFour.subtitle",
                                                    value: "Stats, Reader, Notifications and other Jetpack powered features have been removed from the WordPress app.",
                                                    comment: "Title of a screen that prompts the user to switch the Jetpack app.")

            static let generalContinueButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseFour.general.continue.title",
                                                                      value: "Do this later",
                                                                      comment: "Title of a button that dismisses an overlay that prompts the user to switch the Jetpack app.")
        }

        enum NewUsers {
            static let generalTitle = NSLocalizedString("jetpack.fullscreen.overlay.newUsers.title",
                                                        value: "Give WordPress a boost with Jetpack",
                                                        comment: "Title of a screen that prompts the user to switch the Jetpack app.")

            static let subtitle = NSLocalizedString("jetpack.fullscreen.overlay.newUsers.subtitle",
                                                    value: "Jetpack lets you do more with your WordPress site. Switching is free and only takes a minute.",
                                                    comment: "Title of a screen that prompts the user to switch the Jetpack app.")
        }

        enum SelfHosted {
            static let generalTitle = NSLocalizedString("jetpack.fullscreen.overlay.selfHosted.title",
                                                        value: "Your site has the Jetpack plugin",
                                                        comment: "Title of a screen that prompts the user to switch the Jetpack app.")

            static let subtitle = NSLocalizedString("jetpack.fullscreen.overlay.selfHosted.subtitle",
                                                    value: "The Jetpack mobile app is designed to work in companion with the Jetpack plugin. Switch now to get access to Stats, Reader, Notifications and more.",
                                                    comment: "Title of a screen that prompts the user to switch the Jetpack app.")
        }
    }
}
