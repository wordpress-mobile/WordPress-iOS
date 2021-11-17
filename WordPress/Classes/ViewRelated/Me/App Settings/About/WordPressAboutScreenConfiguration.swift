import Foundation
import UIKit

class WordPressAboutScreenConfiguration: AboutScreenConfiguration {
    let sharePresenter: ShareAppContentPresenter

    lazy var sections: [[AboutItem]] = {
        [
            [
                AboutItem(title: TextContent.rateUs, accessoryType: .none),
                AboutItem(title: TextContent.share, accessoryType: .none, action: { [weak self] context in
                    self?.sharePresenter.present(for: .wordpress, in: context.viewController, source: .about, sourceView: context.sourceView)
                }),
                AboutItem(title: TextContent.twitter, subtitle: "@WordPressiOS", cellStyle: .value1, accessoryType: .none, links: Links.twitter),
            ],
            [
                AboutItem(title: TextContent.legalAndMore, links: Links.legalAndMore),
            ],
            [
                AboutItem(title: TextContent.automatticFamily, hidesSeparator: true),
                AboutItem(title: "", cellStyle: .appLogos)
            ],
            [
                AboutItem(title: TextContent.workWithUs, subtitle: TextContent.workWithUsSubtitle, cellStyle: .subtitle, links: Links.workWithUs)
            ]
        ]
    }()

    let presentURLBlock: AboutScreenURLPresenterBlock? = { url, context in
        let webViewController = WebViewControllerFactory.controller(url: url)
        let navigationController = UINavigationController(rootViewController: webViewController)
        context.viewController.present(navigationController, animated: true, completion: nil)
    }

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
        static let legalAndMore = [
            AboutScreenLink("Terms of Service", url: WPAutomatticTermsOfServiceURL),
            AboutScreenLink("Privacy Policy", url: WPAutomatticPrivacyURL),
            AboutScreenLink("Source Code", url: WPGithubMainURL),
            AboutScreenLink("Acknowledgements", url: Bundle.main.url(forResource: "acknowledgements", withExtension: "html")?.absoluteString ?? "")
        ]
        static let twitter      = [AboutScreenLink(url: "https://twitter.com/WordPressiOS")]
        static let workWithUs   = [AboutScreenLink(url: "https://automattic.com/work-with-us")]
    }
}
