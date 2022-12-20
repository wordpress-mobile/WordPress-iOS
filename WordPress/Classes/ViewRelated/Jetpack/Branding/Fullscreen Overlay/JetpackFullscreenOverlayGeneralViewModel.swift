import Foundation

/// Dynamic implementation of `JetpackFullscreenOverlayViewModel` based on the general phase
/// Should be used for feature-specific and feature-collection overlays.
struct JetpackFullscreenOverlayGeneralViewModel: JetpackFullscreenOverlayViewModel {

    let phase: JetpackFeaturesRemovalCoordinator.GeneralPhase
    let source: JetpackFeaturesRemovalCoordinator.OverlaySource

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

        // Phase Four: Show feature-collection overlays. Features are removed by this point so they are irrelevant.
        case (.four, _):
            return false // TODO: Change this to true when other phase 4 tasks are ready

        // New Users Phase: Show feature-collection overlays. Do not show on app-open. Features are removed by this point so they are irrelevant.
        case (.newUsers, .appOpen):
            return false
        case (.newUsers, _):
            return false // TODO: Change this to true when other new users phase tasks are ready

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
        default:
            return ""
        }
    }

    var subtitle: NSAttributedString {
        switch (phase, source) {
        // Phase One
        case (.one, .stats):
            return .init(string: Strings.PhaseOne.Stats.subtitle)
        case (.one, .notifications):
            return .init(string: Strings.PhaseOne.Notifications.subtitle)
        case (.one, .reader):
            return .init(string: Strings.PhaseOne.Reader.subtitle)

        // Phase Two
        case (.two, _):
            fallthrough

        // Phase Three
        case (.three, _):
            return phaseTwoAndThreeSubtitle()
        default:
            return .init(string: "")
        }
    }

    var animationLtr: String {
        switch source {
        case .stats:
            return Constants.statsLogoAnimationLtr
        case .notifications:
            return Constants.notificationsLogoAnimationLtr
        case .reader:
            return Constants.readerLogoAnimationLtr
        case .card:
            fallthrough
        case .login:
            fallthrough
        case .appOpen:
            return Constants.allFeaturesLogosAnimationLtr
        }
    }

    var animationRtl: String {
        switch source {
        case .stats:
            return Constants.statsLogoAnimationRtl
        case .notifications:
            return Constants.notificationsLogoAnimationRtl
        case .reader:
            return Constants.readerLogoAnimationRtl
        case .card:
            fallthrough
        case .login:
            fallthrough
        case .appOpen:
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
            return Strings.PhaseTwoAndThree.footnote
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
        case .newUsers:
            return RemoteConfig().phaseNewUsersBlogPostUrl.value
        default:
            return nil
        }
    }

    var switchButtonText: String {
        switch phase {
        case .one:
            return Strings.General.earlyPhasesSwitchButtonTitle
        case .two:
            return Strings.General.earlyPhasesSwitchButtonTitle
        case .three:
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
        case (_, .three):
            return Strings.PhaseThree.generalContinueButtonTitle
        default:
            return nil
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

    var onDismiss: JetpackOverlayDismissCallback?
}

// MARK: Helpers

private extension JetpackFullscreenOverlayGeneralViewModel {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    func phaseTwoAndThreeSubtitle() -> NSAttributedString {
        guard let deadline = JetpackFeaturesRemovalCoordinator.removalDeadline() else {
            return NSAttributedString(string: Strings.PhaseTwoAndThree.fallbackSubtitle)
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
                                                     value: "Switch to the Jetpack app to keep recieving real-time notifications on your device.",
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
            static let footnote = NSLocalizedString("jetpack.fullscreen.overlay.phaseThree.footnote",
                                                    value: "Switching is free and only takes a minute.",
                                                    comment: "A footnote in a screen displayed when the user accesses a Jetpack powered feature from the WordPress app. The screen showcases the Jetpack app.")
        }

        enum PhaseThree {
            static let generalTitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseThree.general.title",
                                                                  value: "Jetpack features are moving soon.",
                                                                  comment: "Title of a screen that showcases the Jetpack app.")

            static let generalContinueButtonTitle = NSLocalizedString("jetpack.fullscreen.overlay.phaseThree.general.continue.title",
                                                                            value: "Continue without Jetpack",
                                                                            comment: "Title of a button that dismisses an overlay that showcases the Jetpack app.")
        }
    }
}
