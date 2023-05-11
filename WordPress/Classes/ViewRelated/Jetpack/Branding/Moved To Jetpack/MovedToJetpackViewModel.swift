import Foundation

@objc enum MovedToJetpackSource: Int {
    case stats
    case reader
    case notifications

    var description: String {
        switch self {
        case .stats:
            return "stats"
        case .reader:
            return "reader"
        case .notifications:
            return "notifications"
        }
    }
}

struct MovedToJetpackViewModel {

    let source: MovedToJetpackSource

    let animationLtr: String = Constants.wpJetpackLogoAnimationLtr

    let animationRtl: String = Constants.wpJetpackLogoAnimationRtl

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
        static let wpJetpackLogoAnimationLtr = "JetpackWordPressLogoAnimation_ltr"
        static let wpJetpackLogoAnimationRtl = "JetpackWordPressLogoAnimation_rtl"
    }

    private enum Strings {

        static let statsTitle = NSLocalizedString(
            "movedToJetpack.stats.title",
            value: "Use WordPress with Stats in the Jetpack app.",
            comment: "Title for the static screen displayed in the Stats screen prompting users to switch to the Jetpack app."
        )

        static let readerTitle = NSLocalizedString(
            "movedToJetpack.reader.title",
            value: "Use WordPress with Reader in the Jetpack app.",
            comment: "Title for the static screen displayed in the Reader screen prompting users to switch to the Jetpack app."
        )

        static let notificationsTitle = NSLocalizedString(
            "movedToJetpack.notifications.title",
            value: "Use WordPress with Notifications in the Jetpack app.",
            comment: "Title for the static screen displayed in the Stats screen prompting users to switch to the Jetpack app."
        )

        static let description = NSLocalizedString(
            "movedToJetpack.description",
            value: "The Jetpack app has all the WordPress app’s functionality, and now exclusive access to Stats, Reader, Notifications and more.",
            comment: "Description for the static screen displayed prompting users to switch the Jetpack app."
        )

        static let hint = NSLocalizedString(
            "movedToJetpack.hint",
            value: "Switching is free and only takes a minute.",
            comment: "Hint for the static screen displayed prompting users to switch the Jetpack app."
        )

        static let jetpackButtonTitle = NSLocalizedString(
            "movedToJetpack.jetpackButtonTitle",
            value: "Switch to the Jetpack app",
            comment: "Title for a button that prompts users to switch to the Jetpack app."
        )

        static let learnMoreButtonTitle = NSLocalizedString(
            "movedToJetpack.learnMoreButtonTitle",
            value: "Learn more at jetpack.com",
            comment: "Title for a button that displays a blog post in a web view."
        )

    }
}
