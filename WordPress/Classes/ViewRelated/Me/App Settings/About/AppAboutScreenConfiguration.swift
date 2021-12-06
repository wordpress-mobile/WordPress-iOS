import Foundation
import UIKit
import WordPressShared
import AutomatticAbout

struct WebViewPresenter {
    func present(for url: URL, context: AboutItemActionContext) {
        let webViewController = WebViewControllerFactory.controller(url: url, source: "about")
        let navigationController = UINavigationController(rootViewController: webViewController)
        context.viewController.present(navigationController, animated: true, completion: nil)
    }
}

class AppAboutScreenConfiguration: AboutScreenConfiguration {
    static var appInfo: AboutScreenAppInfo {
        AboutScreenAppInfo(name: (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "",
                           version: Bundle.main.detailedVersionNumber() ?? "",
                           icon: UIImage(named: AppIcon.currentOrDefaultIconName) ?? UIImage())
    }

    static let fonts = AboutScreenFonts(appName: WPStyleGuide.serifFontForTextStyle(.largeTitle, fontWeight: .semibold),
                                        appVersion: WPStyleGuide.tableviewTextFont())

    let sharePresenter: ShareAppContentPresenter
    let webViewPresenter = WebViewPresenter()
    let tracker = AboutScreenTracker()

    lazy var sections: [[AboutItem]] = {
        [
            [
                AboutItem(title: TextContent.rateUs, action: { [weak self] context in
                    WPAnalytics.track(.appReviewsRatedApp)
                    self?.tracker.buttonPressed(.rateUs)
                    AppRatingUtility.shared.ratedCurrentVersion()
                    UIApplication.shared.open(AppRatingUtility.shared.appReviewUrl)
                }),
                AboutItem(title: TextContent.share, action: { [weak self] context in
                    self?.tracker.buttonPressed(.share)
                    self?.sharePresenter.present(for: AppConstants.shareAppName, in: context.viewController, source: .about, sourceView: context.sourceView)
                }),
                AboutItem(title: TextContent.twitter, subtitle: AppConstants.productTwitterHandle, cellStyle: .value1, action: { [weak self] context in
                    self?.tracker.buttonPressed(.twitter)
                    self?.webViewPresenter.present(for: Links.twitter, context: context)
                }),
                AboutItem(title: TextContent.blog, subtitle: AppConstants.productBlogDisplayURL, cellStyle: .value1, action: { [weak self] context in
                    self?.tracker.buttonPressed(.blog)
                    self?.webViewPresenter.present(for: Links.blog, context: context)
                })
            ],
            [
                AboutItem(title: TextContent.legalAndMore, accessoryType: .disclosureIndicator, action: { [weak self] context in
                    self?.tracker.buttonPressed(.legal)
                    context.showSubmenu(title: TextContent.legalAndMore, configuration: LegalAndMoreSubmenuConfiguration())
                }),
            ],
            [
                AboutItem(title: TextContent.automatticFamily, accessoryType: .disclosureIndicator, hidesSeparator: true, action: { [weak self] context in
                    self?.tracker.buttonPressed(.automatticFamily)
                    self?.webViewPresenter.present(for: Links.automattic, context: context)
                }),
                AboutItem(title: "", cellStyle: .appLogos, accessoryType: .none)
            ],
            [
                AboutItem(title: TextContent.workWithUs, subtitle: TextContent.workWithUsSubtitle, cellStyle: .subtitle, accessoryType: .disclosureIndicator, action: { [weak self] context in
                    self?.tracker.buttonPressed(.workWithUs)
                    self?.webViewPresenter.present(for: Links.workWithUs, context: context)
                }),
            ]
        ]
    }()

    func dismissScreen(_ actionContext: AboutItemActionContext) {
        actionContext.viewController.presentingViewController?.dismiss(animated: true)
    }

    func willShow(viewController: UIViewController) {
        tracker.screenShown(.main)
    }

    func didHide(viewController: UIViewController) {
        tracker.screenDismissed(.main)
    }

    init(sharePresenter: ShareAppContentPresenter) {
        self.sharePresenter = sharePresenter
    }

    private enum TextContent {
        static let rateUs             = NSLocalizedString("Rate Us", comment: "Title for button allowing users to rate the app in the App Store")
        static let share              = NSLocalizedString("Share with Friends", comment: "Title for button allowing users to share information about the app with friends, such as via Messages")
        static let twitter            = NSLocalizedString("Twitter", comment: "Title of button that displays the app's Twitter profile")
        static let blog               = NSLocalizedString("Blog", comment: "Title of a button that displays the WordPress product blog")
        static let legalAndMore       = NSLocalizedString("Legal and More", comment: "Title of button which shows a list of legal documentation such as privacy policy and acknowledgements")
        static let automatticFamily   = NSLocalizedString("Automattic Family", comment: "Title of button that displays information about the other apps available from Automattic")
        static let workWithUs         = NSLocalizedString("Work With Us", comment: "Title of button that displays the Automattic Work With Us web page")
        static let workWithUsSubtitle = NSLocalizedString("Join From Anywhere", comment: "Subtitle for button displaying the Automattic Work With Us web page, indicating that Automattic employees can work from anywhere in the world")
    }

    private enum Links {
        static let twitter    = URL(string: AppConstants.productTwitterURL)!
        static let blog       = URL(string: AppConstants.productBlogURL)!
        static let workWithUs = URL(string: "https://automattic.com/work-with-us")!
        static let automattic = URL(string: "https://automattic.com")!
    }
}

class LegalAndMoreSubmenuConfiguration: AboutScreenConfiguration {
    let webViewPresenter = WebViewPresenter()
    let tracker = AboutScreenTracker()

    lazy var sections: [[AboutItem]] = {
        [
            [
                linkItem(title: Titles.termsOfService, link: Links.termsOfService, button: .termsOfService),
                linkItem(title: Titles.privacyPolicy, link: Links.privacyPolicy, button: .privacyPolicy),
                linkItem(title: Titles.sourceCode, link: Links.sourceCode, button: .sourceCode),
                linkItem(title: Titles.acknowledgements, link: Links.acknowledgements, button: .acknowledgements),
            ]
        ]
    }()

    private func linkItem(title: String, link: URL, button: AboutScreenTracker.Event.Button) -> AboutItem {
        AboutItem(title: title, action: { [weak self] context in
            self?.buttonPressed(link: link, context: context, button: button)
        })
    }

    private func buttonPressed(link: URL, context: AboutItemActionContext, button: AboutScreenTracker.Event.Button) {
        tracker.buttonPressed(button)
        webViewPresenter.present(for: link, context: context)
    }

    func dismissScreen(_ actionContext: AboutItemActionContext) {
        actionContext.viewController.presentingViewController?.dismiss(animated: true)
    }

    func willShow(viewController: UIViewController) {
        tracker.screenShown(.legalAndMore)
    }

    func didHide(viewController: UIViewController) {
        tracker.screenDismissed(.legalAndMore)
    }

    private enum Titles {
        static let termsOfService     = NSLocalizedString("Terms of Service", comment: "Title of button that displays the App's terms of service")
        static let privacyPolicy      = NSLocalizedString("Privacy Policy", comment: "Title of button that displays the App's privacy policy")
        static let sourceCode         = NSLocalizedString("Source Code", comment: "Title of button that displays the App's source code information")
        static let acknowledgements   = NSLocalizedString("Acknowledgements", comment: "Title of button that displays the App's acknoledgements")
    }

    private enum Links {
        static let termsOfService = URL(string: WPAutomatticTermsOfServiceURL)!
        static let privacyPolicy = URL(string: WPAutomatticPrivacyURL)!
        static let sourceCode = URL(string: WPGithubMainURL)!
        static let acknowledgements: URL = URL(string: Bundle.main.url(forResource: "acknowledgements", withExtension: "html")?.absoluteString ?? "")!
    }
}
