import Foundation
import WordPressUI
import UIKit
import WordPressShared
import AutomatticAbout
import SwiftUI

struct WebViewPresenter {
    func present(for url: URL, context: AboutItemActionContext) {
        let webViewController = WebViewControllerFactory.controller(url: url, source: "about")
        context.viewController.navigationController?.pushViewController(webViewController, animated: true)
    }

    func presentInNavigationControlller(url: URL, context: AboutItemActionContext) {
        let webViewController = WebViewControllerFactory.controller(url: url, source: "about")
        context.viewController.present(UINavigationController(rootViewController: webViewController), animated: true)
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
                    self?.webViewPresenter.presentInNavigationControlller(url: Links.twitter, context: context)
                }),
                AboutItem(title: AppConstants.AboutScreen.blogName, subtitle: AppConstants.productBlogDisplayURL, cellStyle: .value1, action: { [weak self] context in
                    self?.tracker.buttonPressed(.blog)
                    self?.webViewPresenter.presentInNavigationControlller(url: Links.blog, context: context)
                })
            ],
            [
                AboutItem(title: TextContent.legalAndMore, accessoryType: .disclosureIndicator, action: { [weak self] context in
                    self?.tracker.buttonPressed(.legal)
                    context.showSubmenu(title: TextContent.legalAndMore, configuration: LegalAndMoreSubmenuConfiguration())
                }),
            ],
            AppConfiguration.isJetpack ?
            [
                AboutItem(title: TextContent.automatticFamily, accessoryType: .disclosureIndicator, hidesSeparator: true, action: { [weak self] context in
                    self?.tracker.buttonPressed(.automatticFamily)
                    self?.webViewPresenter.presentInNavigationControlller(url: Links.automattic, context: context)
                }),
                AboutItem(title: "", cellStyle: .appLogos, accessoryType: .none)
            ] : nil,
            [
                AboutItem(title: AppConstants.AboutScreen.workWithUs, subtitle: TextContent.workWithUsSubtitle, cellStyle: .subtitle, accessoryType: .disclosureIndicator, action: { [weak self] context in
                    self?.tracker.buttonPressed(.workWithUs)
                    self?.webViewPresenter.presentInNavigationControlller(url: Links.workWithUs, context: context)
                }),
            ]
        ].compactMap { $0 }
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
        static let legalAndMore       = NSLocalizedString("Legal and More", comment: "Title of button which shows a list of legal documentation such as privacy policy and acknowledgements")
        static let automatticFamily   = NSLocalizedString("Automattic Family", comment: "Title of button that displays information about the other apps available from Automattic")
        static var workWithUsSubtitle = AppConfiguration.isJetpack ? NSLocalizedString("Join From Anywhere", comment: "Subtitle for button displaying the Automattic Work With Us web page, indicating that Automattic employees can work from anywhere in the world") : nil
    }

    private enum Links {
        static let twitter    = URL(string: AppConstants.productTwitterURL)!
        static let blog       = URL(string: AppConstants.productBlogURL)!
        static let workWithUs = URL(string: AppConstants.AboutScreen.workWithUsURL)!
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
                AboutItem(title: Titles.acknowledgements, action: { context in
                    let rootView = AcknowledgementsListView(viewModel: AcknowledgementsListViewModel(dataProvider: AcknowledgementsService()))
                    context.viewController.navigationController?.pushViewController(
                        UIHostingController(rootView: rootView),
                        animated: true
                    )
                })
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
        static let acknowledgements   = NSLocalizedString("Acknowledgements", comment: "Title of button that displays the App's acknowledgements")
    }

    private enum Links {
        static let termsOfService = URL(string: WPAutomatticTermsOfServiceURL)!
        static let privacyPolicy = URL(string: WPAutomatticPrivacyURL)!
        static let sourceCode = URL(string: WPGithubMainURL)!
    }
}
