import Foundation

@objc enum MovedToJetpackSource: Int {
    case stats
    case reader
    case notifications
}

struct MovedToJetpackViewModel {

    let source: MovedToJetpackSource

    var animationLtr: String {
        switch source {
        case .stats:
            return Constants.statsLogoAnimationLtr
        case .reader:
            return Constants.readerLogoAnimationLtr
        case .notifications:
            return Constants.notificationsLogoAnimationLtr
        }
    }

    var animationRtl: String {
        switch source {
        case .stats:
            return Constants.statsLogoAnimationRtl
        case .reader:
            return Constants.readerLogoAnimationRtl
        case .notifications:
            return Constants.notificationsLogoAnimationRtl
        }
    }

    var title: String {
        switch source {
        case .stats:
            return Strings.statsTitle
        case .reader:
            return Strings.readerTitle
        case .notifications:
            return Strings.notificationsTitle
        }
    }

    var description: String {
        return Strings.description
    }

    var hint: String {
        return Strings.hint
    }

    var jetpackButtonTitle: String {
        return Strings.jetpackButtonTitle
    }

    var learnMoreButtonTitle: String {
        return Strings.learnMoreButtonTitle
    }

}

extension MovedToJetpackViewModel {

    private enum Constants {
        static let statsLogoAnimationLtr = "JetpackStatsLogoAnimation_ltr"
        static let statsLogoAnimationRtl = "JetpackStatsLogoAnimation_rtl"
        static let readerLogoAnimationLtr = "JetpackReaderLogoAnimation_ltr"
        static let readerLogoAnimationRtl = "JetpackReaderLogoAnimation_rtl"
        static let notificationsLogoAnimationLtr = "JetpackNotificationsLogoAnimation_ltr"
        static let notificationsLogoAnimationRtl = "JetpackNotificationsLogoAnimation_rtl"
    }

    private enum Strings {

        static let statsTitle = NSLocalizedString(
            "getJetpackApp.stats.title",
            value: "Stats have moved to the Jetpack app.",
            comment: "Title for the static screen displayed in the Stats screen prompting users to switch to the Jetpack app."
        )

        static let readerTitle = NSLocalizedString(
            "getJetpackApp.reader.title",
            value: "Reader has moved to the Jetpack app.",
            comment: "Title for the static screen displayed in the Reader screen prompting users to switch to the Jetpack app."
        )

        static let notificationsTitle = NSLocalizedString(
            "getJetpackApp.notifications.title",
            value: "Notifications have moved to the Jetpack app.",
            comment: "Title for the static screen displayed in the Stats screen prompting users to switch to the Jetpack app."
        )

        static let description = NSLocalizedString(
            "getJetpackApp.description",
            value: "Stats, Reader, Notifications and other Jetpack powered features have been removed from the WordPress app, and can now only be found in the Jetpack app.",
            comment: "Description for the static screen displayed prompting users to switch the Jetpack app."
        )

        static let hint = NSLocalizedString(
            "getJetpackApp.hint",
            value: "Switching is free and only takes a minute.",
            comment: "Hint for the static screen displayed prompting users to switch the Jetpack app."
        )

        static let jetpackButtonTitle = NSLocalizedString(
            "getJetpackApp.jetpackButtonTitle",
            value: "Switch to the Jetpack app",
            comment: "Title for a button that prompts users to switch to the Jetpack app."
        )

        static let learnMoreButtonTitle = NSLocalizedString(
            "getJetpackApp.learnMoreButtonTitle",
            value: "Learn more at jetpack.com",
            comment: "Title for a button that displays a blog post in a web view."
        )

    }
}
