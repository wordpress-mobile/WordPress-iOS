import Foundation

class JetpackPluginOverlayViewModel: JetpackFullscreenOverlayViewModel {
    private enum Constants {
        static let lottieLTRFileName = "JetpackInstallPluginLogoAnimation_ltr"
        static let lottieRTLFileName = "JetpackInstallPluginLogoAnimation_rtl"
        static let termsURL = URL(string: "https://wordpress.com/tos")
        static let webViewSource = "jetpack_plugin_install_overlay"
    }

    // MARK: View Model Properties

    var title: String { strings.title }
    var subtitle: NSAttributedString { subtitle(withSiteName: siteName, plugin: plugin) }
    let animationLtr: String = Constants.lottieLTRFileName
    let animationRtl: String = Constants.lottieRTLFileName
    let footnote: String? = nil
    var actionInfoText: NSAttributedString? { actionInfoString() }
    let learnMoreButtonURL: String? = nil
    var switchButtonText: String { strings.primaryButtonTitle }
    var continueButtonText: String? { strings.secondaryButtonTitle }
    let shouldShowCloseButton = true
    let shouldDismissOnSecondaryButtonTap = false
    let analyticsSource: String = ""
    var onWillDismiss: JetpackOverlayDismissCallback?
    var onDidDismiss: JetpackOverlayDismissCallback?
    var secondaryView: UIView? = nil
    let isCompact = false // compact layout is not supported for this overlay.

    // MARK: Dependencies

    var coordinator: JetpackOverlayCoordinator?

    // MARK: Private Properties

    private let siteName: String
    private let plugin: JetpackPlugin
    private let strings: JetpackPluginOverlayStrings

    // MARK: Methods

    init(siteName: String, plugin: JetpackPlugin) {
        self.siteName = siteName
        self.plugin = plugin
        self.strings = AppConfiguration.isWordPress ? WordPressStrings() : JetpackStrings()
    }

    func didDisplayOverlay() {
        WPAnalytics.track(.jetpackInstallPluginModalViewed)
    }

    func didTapLink() {
        // TODO: coordinator?.navigateToLinkRoute
    }

    func didTapPrimary() {
        coordinator?.navigateToPrimaryRoute()
        WPAnalytics.track(.jetpackInstallPluginModalInstallTapped)
    }

    func didTapClose() {
        // TODO: Dismiss the overlay.
        WPAnalytics.track(.jetpackInstallPluginModalDismissed)
    }

    func didTapSecondary() {
        coordinator?.navigateToSecondaryRoute()
    }

    func didTapActionInfo() {
        guard let termsURL = Constants.termsURL else {
            return
        }
        coordinator?.navigateToLinkRoute(url: termsURL, source: Constants.webViewSource)
    }

}

// MARK: - Private Helpers

private extension JetpackPluginOverlayViewModel {

    func subtitle(withSiteName siteName: String, plugin: JetpackPlugin) -> NSAttributedString {
        switch plugin {
        case .multiple:
            return subtitleForPluralPlugins(withSiteName: siteName)
        default:
            return subtitleForSinglePlugin(withSiteName: siteName, pluginName: plugin.displayName)
        }
    }

    func subtitleForPluralPlugins(withSiteName siteName: String) -> NSAttributedString {
        let siteNameAttributedText = attributedSubtitle(
            with: siteName,
            fontWeight: .bold
        )

        if let jetpackPluginText = strings.jetpackPluginText {
            let jetpackPluginAttributedText = attributedSubtitle(
                with: jetpackPluginText,
                fontWeight: .bold
            )
            return NSAttributedString(
                format: attributedSubtitle(with: strings.subtitlePlural, fontWeight: .regular),
                args: ("%1$@", siteNameAttributedText), ("%2$@", jetpackPluginAttributedText)
            )
        }

        return NSAttributedString(
            format: attributedSubtitle(with: strings.subtitlePlural, fontWeight: .regular),
            args: ("%1$@", siteNameAttributedText)
        )
    }

    func subtitleForSinglePlugin(withSiteName siteName: String, pluginName: String) -> NSAttributedString {
        let siteNameAttributedText = attributedSubtitle(with: siteName, fontWeight: .bold)
        let jetpackBackupAttributedText = attributedSubtitle(with: pluginName,
            fontWeight: .bold
        )

        if let jetpackPluginText = strings.jetpackPluginText {
            let jetpackPluginAttributedText = attributedSubtitle(
                with: jetpackPluginText,
                fontWeight: .bold
            )
            return NSAttributedString(
                format: attributedSubtitle(
                    with: strings.subtitleSingular,
                    fontWeight: .regular),
                args: ("%1$@", siteNameAttributedText), ("%2$@", jetpackBackupAttributedText), ("%3$@", jetpackPluginAttributedText)
            )
        }

        return NSAttributedString(
            format: attributedSubtitle(
                with: strings.subtitleSingular,
                fontWeight: .regular),
            args: ("%1$@", siteNameAttributedText), ("%2$@", jetpackBackupAttributedText)
        )
    }

    func actionInfoString() -> NSAttributedString? {
        guard let footnote = strings.footnote,
              let termsAndConditions = strings.termsAndConditions else {
            return nil
        }
        let actionInfoBaseFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        let actionInfoBaseText = NSAttributedString(string: footnote, attributes: [.font: actionInfoBaseFont])

        let actionInfoTermsText = NSAttributedString(
            string: termsAndConditions,
            attributes: [
                .font: actionInfoBaseFont,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )

        return NSAttributedString(
            format: actionInfoBaseText,
            args: ("%@", actionInfoTermsText)
        )
    }

    func attributedSubtitle(with string: String, fontWeight: UIFont.Weight) -> NSAttributedString {
        let font = WPStyleGuide.fontForTextStyle(.body, fontWeight: fontWeight)
        return NSAttributedString(string: string, attributes: [.font: font])
    }
}

private extension NSAttributedString {
    convenience init(format: NSAttributedString, args: (String, NSAttributedString)...) {
        let mutableNSAttributedString = NSMutableAttributedString(attributedString: format)

        args.forEach { (key, attributedString) in
            let range = NSString(string: mutableNSAttributedString.string).range(of: key)
            mutableNSAttributedString.replaceCharacters(in: range, with: attributedString)
        }
        self.init(attributedString: mutableNSAttributedString)
    }
}

// MARK: - Strings

private protocol JetpackPluginOverlayStrings {
    var title: String { get }
    var subtitleSingular: String { get }
    var subtitlePlural: String { get }
    var jetpackPluginText: String? { get }
    var footnote: String? { get }
    var termsAndConditions: String? { get }
    var primaryButtonTitle: String { get }
    var secondaryButtonTitle: String { get }
}

extension JetpackPluginOverlayStrings {
    var jetpackPluginText: String? { nil }
    var footnote: String? { nil }
    var termsAndConditions: String? { nil }
}

private struct JetpackStrings: JetpackPluginOverlayStrings {
    let title = NSLocalizedString(
        "jetpack.plugin.modal.title",
        value: "Please install the full Jetpack plugin",
        comment: "Jetpack Plugin Modal title"
    )

    let subtitleSingular = NSLocalizedString(
        "jetpack.plugin.modal.subtitle.singular",
        value: """
            %1$@ is using the %2$@ plugin, which doesn't support all features of the app yet.

            Please install the %3$@ to use the app with this site.
            """,
        comment: """
            Jetpack Plugin Modal (single plugin) subtitle with formatted texts.
            %1$@ is for the site name, %2$@ for the specific plugin name,
            and %3$@ is for 'full Jetpack plugin' in bold style.
            """
    )

    let subtitlePlural = NSLocalizedString(
        "jetpack.plugin.modal.subtitle.plural",
        value: """
            %1$@ is using individual Jetpack plugins, which don't support all features of the app yet.

            Please install the %2$@ to use the app with this site.
            """,
        comment: """
            Jetpack Plugin Modal (multiple plugins) subtitle with formatted texts.
            %1$@ is for the site name, and %2$@ for 'full Jetpack plugin' in bold style.
            """
    )

    let jetpackPluginText: String? = NSLocalizedString(
        "jetpack.plugin.modal.subtitle.jetpack.plugin",
        value: "full Jetpack plugin",
        comment: "The 'full Jetpack plugin' string in the subtitle"
    )

    let footnote: String? = NSLocalizedString(
        "jetpack.plugin.modal.footnote",
        value: "By setting up Jetpack you agree to our %@",
        comment: "Jetpack Plugin Modal footnote"
    )

    let termsAndConditions: String? = NSLocalizedString(
        "jetpack.plugin.modal.terms",
        value: "Terms and Conditions",
        comment: "Jetpack Plugin Modal footnote terms and conditions"
    )

    let primaryButtonTitle = NSLocalizedString(
        "jetpack.plugin.modal.primary.button.title",
        value: "Install the full plugin",
        comment: "Jetpack Plugin Modal primary button title"
    )

    let secondaryButtonTitle = NSLocalizedString(
        "jetpack.plugin.modal.secondary.button.title",
        value: "Contact Support",
        comment: "Jetpack Plugin Modal secondary button title"
    )
}

private struct WordPressStrings: JetpackPluginOverlayStrings {
    let title = NSLocalizedString(
        "wordpress.jetpack.plugin.modal.title",
        value: "Sorry, this site isn't supported by the WordPress app",
        comment: "Jetpack Plugin Modal title in WordPress"
    )

    var subtitleSingular: String {
        let singularFormat = NSLocalizedString(
            "wordpress.jetpack.plugin.modal.subtitle.singular",
            value: "%1$@ is using the %2$@ plugin, which isn't supported by the WordPress App.",
            comment: "Jetpack Plugin Modal on WordPress (single plugin) subtitle with formatted texts. " +
            "%1$@ is for the site name and %2$@ is for the specific plugin name."
        )
        return singularFormat + "\n\n" + switchToJetpack
    }

    var subtitlePlural: String {
        let pluralFormat = NSLocalizedString(
            "wordpress.jetpack.plugin.modal.subtitle.plural",
            value: "%1$@ is using individual Jetpack plugins, which isn't supported by the WordPress App.",
            comment: "Jetpack Plugin Modal (multiple plugins) on WordPress subtitle with formatted texts. %1$@ is for the site name."
        )
        return pluralFormat + "\n\n" + switchToJetpack
    }

    let switchToJetpack = NSLocalizedString(
        "wordpress.jetpack.plugin.modal.subtitle.switch",
        value: "Please switch to the Jetpack app where we'll guide you through connecting the full " +
        "Jetpack plugin so that you can use all the apps features for this site.",
        comment: "Second paragraph of the Jetpack Plugin Modal on WordPress asking the user to switch to Jetpack."
    )

    let primaryButtonTitle = NSLocalizedString(
        "wordpress.jetpack.plugin.modal.primary.button.title",
        value: "Switch to the Jetpack app",
        comment: "Jetpack Plugin Modal on WordPress primary button title"
    )

    let secondaryButtonTitle = NSLocalizedString(
        "wordpress.jetpack.plugin.modal.secondary.button.title",
        value: "Continue without Jetpack",
        comment: "Jetpack Plugin Modal on WordPress secondary button title"
    )
}
