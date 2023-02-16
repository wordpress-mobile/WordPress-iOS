import Foundation

class JetpackPluginOverlayViewModel: JetpackFullscreenOverlayViewModel {
    private enum Constants {
        static let lottieLTRFileName = "JetpackInstallPluginLogoAnimation_ltr"
        static let lottieRTLFileName = "JetpackInstallPluginLogoAnimation_rtl"
    }

    enum Plugin {
        case single(name: String)
        case multiple
    }

    // MARK: View Model Properties

    let title: String = Strings.title
    let subtitle: NSAttributedString
    let animationLtr: String = Constants.lottieLTRFileName
    let animationRtl: String = Constants.lottieRTLFileName
    let footnote: String? = nil
    let actionInfoText: NSAttributedString? = JetpackPluginOverlayViewModel.actionInfoString()
    let learnMoreButtonURL: String? = nil
    let switchButtonText = Strings.primaryButtonTitle
    let continueButtonText: String? = Strings.secondaryButtonTitle
    let shouldShowCloseButton = true
    let analyticsSource: String = ""
    var onWillDismiss: JetpackOverlayDismissCallback?
    var onDidDismiss: JetpackOverlayDismissCallback?
    var secondaryView: UIView? = nil
    let isCompact = false // compact layout is not supported for this overlay.

    // MARK: Dependencies

    var coordinator: JetpackOverlayCoordinator?

    // MARK: Methods

    init(siteName: String, plugin: Plugin) {
        self.subtitle = Self.subtitle(withSiteName: siteName, plugin: plugin)
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
        // TODO: Make the auto-dismiss logic optional in the view controller's `continueButtonPressed`.
        coordinator?.navigateToSecondaryRoute()
    }

    private static func subtitle(withSiteName siteName: String, plugin: Plugin) -> NSAttributedString {
        switch plugin {
        case .single(let name):
            return subtitleSinglePlugin(withSiteName: siteName, pluginName: name)
        case .multiple:
            return subtitlePluralPlugins(withSiteName: siteName)
        }

    }

    private static func subtitlePluralPlugins(withSiteName siteName: String) -> NSAttributedString {
        let siteNameAttributedText = attributedSubtitle(
            with: siteName,
            fontWeight: .bold
        )
        let jetpackPluginAttributedText = attributedSubtitle(
            with: Strings.jetpackPluginText,
            fontWeight: .bold
        )

        return NSAttributedString(
            format: attributedSubtitle(with: Strings.subtitlePlural, fontWeight: .regular),
            args: ("%1$@", siteNameAttributedText), ("%2$@", jetpackPluginAttributedText)
        )
    }

    private static func subtitleSinglePlugin(withSiteName siteName: String, pluginName: String) -> NSAttributedString {
        let siteNameAttributedText = attributedSubtitle(with: siteName, fontWeight: .bold)
        let jetpackBackupAttributedText = attributedSubtitle(with: pluginName,
            fontWeight: .bold
        )
        let jetpackPluginAttributedText = attributedSubtitle(
            with: Strings.jetpackPluginText,
            fontWeight: .bold
        )

        return NSAttributedString(
            format: attributedSubtitle(
                with: Strings.subtitleSingular,
                fontWeight: .regular),
            args: ("%1$@", siteNameAttributedText), ("%2$@", jetpackBackupAttributedText), ("%3$@", jetpackPluginAttributedText)
        )
    }

    private static func actionInfoString() -> NSAttributedString {
        let actionInfoBaseFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        let actionInfoBaseText = NSAttributedString(string: Strings.footnote, attributes: [.font: actionInfoBaseFont])

        let actionInfoTermsText = NSAttributedString(
            string: Strings.termsAndConditions,
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

    private static func attributedSubtitle(with string: String, fontWeight: UIFont.Weight) -> NSAttributedString {
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
private extension JetpackPluginOverlayViewModel {
    enum Strings {
        static let title = NSLocalizedString(
            "jetpack.plugin.modal.title",
            value: "Please install the full Jetpack plugin",
            comment: "Jetpack Plugin Modal title"
        )

        static let subtitleSingular = NSLocalizedString(
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

        static let subtitlePlural = NSLocalizedString(
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

        static let jetpackPluginText = NSLocalizedString(
            "jetpack.plugin.modal.subtitle.jetpack.plugin",
            value: "full Jetpack plugin",
            comment: "The 'full Jetpack plugin' string in the subtitle"
        )

        static let footnote = NSLocalizedString(
            "jetpack.plugin.modal.footnote",
            value: "By setting up Jetpack you agree to our %@",
            comment: "Jetpack Plugin Modal footnote"
        )

        static let termsAndConditions = NSLocalizedString(
            "jetpack.plugin.modal.terms",
            value: "Terms and Conditions",
            comment: "Jetpack Plugin Modal footnote terms and conditions"
        )

        static let primaryButtonTitle = NSLocalizedString(
            "jetpack.plugin.modal.primary.button.title",
            value: "Install the full plugin",
            comment: "Jetpack Plugin Modal primary button title"
        )

        static let secondaryButtonTitle = NSLocalizedString(
            "jetpack.plugin.modal.secondary.button.title",
            value: "Contact Support",
            comment: "Jetpack Plugin Modal secondary button title"
        )
    }
}
