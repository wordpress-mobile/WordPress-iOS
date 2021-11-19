import Foundation
import UIKit


struct WebViewPresenter {
    func present(for url: URL, context: AboutItemActionContext) {
        let webViewController = WebViewControllerFactory.controller(url: url)
        let navigationController = UINavigationController(rootViewController: webViewController)
        context.viewController.present(navigationController, animated: true, completion: nil)
    }
}

class WordPressAboutScreenConfiguration: AboutScreenConfiguration {
    let sharePresenter: ShareAppContentPresenter
    let webViewPresenter = WebViewPresenter()

    lazy var sections: [[AboutItem]] = {
        [
            [
                AboutItem(title: TextContent.share, accessoryType: .none, action: { [weak self] context in
                    self?.sharePresenter.present(for: .wordpress, in: context.viewController, source: .about, sourceView: context.sourceView)
                }),
                AboutItem(title: TextContent.twitter, subtitle: "@WordPressiOS", cellStyle: .value1, accessoryType: .none, action: { [weak self] context in
                    self?.webViewPresenter.present(for: Links.twitter, context: context)
                }),
            ],
            [
                AboutItem(title: TextContent.legalAndMore, action: { [weak self] context in
                    context.showSubmenu(title: TextContent.legalAndMore, configuration: LegalAndMoreSubmenuConfiguration())
                }),
            ],
            [
                AboutItem(title: TextContent.automatticFamily, hidesSeparator: true),
                AboutItem(title: "", cellStyle: .appLogos, accessoryType: .none)
            ],
            [
                AboutItem(title: TextContent.workWithUs, subtitle: TextContent.workWithUsSubtitle, cellStyle: .subtitle, action: { [weak self] context in
                    self?.webViewPresenter.present(for: Links.workWithUs, context: context)
                }),
            ]
        ]
    }()

    let dismissBlock: ((AboutItemActionContext) -> Void) = { context in
        context.viewController.presentingViewController?.dismiss(animated: true)
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
        static let workWithUs         = NSLocalizedString("Work With Us", comment: "Title of button that displays the Automattic Work With Us web page")
        static let workWithUsSubtitle = NSLocalizedString("Join From Anywhere", comment: "Subtitle for button displaying the Automattic Work With Us web page, indicating that Automattic employees can work from anywhere in the world")
    }

    private enum Links {
        static let twitter    = URL(string: "https://twitter.com/WordPressiOS")!
        static let workWithUs = URL(string: "https://automattic.com/work-with-us")!
    }
}

class LegalAndMoreSubmenuConfiguration: AboutScreenConfiguration {
    let webViewPresenter = WebViewPresenter()

    lazy var sections: [[AboutItem]] = {
        [
            [
                linkItem(title: Titles.termsOfService, link: Links.termsOfService),
                linkItem(title: Titles.privacyPolicy, link: Links.privacyPolicy),
                linkItem(title: Titles.sourceCode, link: Links.sourceCode),
                linkItem(title: Titles.acknowledgements, link: Links.acknowledgements),
            ]
        ]
    }()

    func linkItem(title: String, link: URL) -> AboutItem {
        AboutItem(title: title, accessoryType: .none, action: { [weak self] context in
            self?.webViewPresenter.present(for: link, context: context)
        })
    }

    let dismissBlock: ((AboutItemActionContext) -> Void) = { context in
        context.viewController.presentingViewController?.dismiss(animated: true)
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
