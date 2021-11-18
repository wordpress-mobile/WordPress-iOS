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
                    return .noDefaultAction
                }),
                AboutItem(title: TextContent.twitter, subtitle: "@WordPressiOS", cellStyle: .value1, accessoryType: .none, action: { [weak self] context in

                    self?.presentWebView(for: Links.twitter, context: context)
                    return .noDefaultAction
                }),
            ],
            [
                AboutItem(title: TextContent.legalAndMore),
            ],
            [
                AboutItem(title: TextContent.automatticFamily, hidesSeparator: true),
                AboutItem(title: "", cellStyle: .appLogos, accessoryType: .none)
            ],
            [
                AboutItem(title: TextContent.workWithUs, subtitle: TextContent.workWithUsSubtitle, cellStyle: .subtitle, action: { [weak self] context in

                    self?.presentWebView(for: Links.workWithUs, context: context)
                    return .noDefaultAction
                }),
            ]
        ]
    }()

    func presentWebView(for url: URL, context: AboutItemActionContext) {
        let webViewController = WebViewControllerFactory.controller(url: url)
        let navigationController = UINavigationController(rootViewController: webViewController)
        context.viewController.present(navigationController, animated: true, completion: nil)
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
