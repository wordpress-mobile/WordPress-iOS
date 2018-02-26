import UIKit
import Gridicons
import WordPressShared
import WordPressUI

let AztecAnnouncementWhatsNewURL = URL(string: "https://make.wordpress.org/mobile/whats-new-in-beta-ios-editor/")!

// MARK: - What's New Web View

extension WordPressUI.FancyAlertViewController {
    @objc static func presentWhatsNewWebView(from viewController: UIViewController) {
        // Replace the web view's options button with our own bug reporting button
        let bugButton = UIBarButtonItem(image: Gridicon.iconOfType(.bug), style: .plain, target: self, action: #selector(bugButtonTapped))
        bugButton.accessibilityLabel = NSLocalizedString("Report a bug", comment: "Button allowing the user to report a bug with the beta Aztec editor")

        let configuration = WebViewControllerConfiguration(url: AztecAnnouncementWhatsNewURL)
        if HelpshiftUtils.isHelpshiftEnabled() {
            configuration.optionsButton = bugButton
        }
        let webViewController = WebViewControllerFactory.controller(configuration: configuration)

        let navigationController = UINavigationController(rootViewController: webViewController)

        viewController.present(navigationController, animated: true, completion: nil)
    }

    @objc static private func bugButtonTapped() {
        // Find the topmost view controller that we can present from
        guard let delegate = UIApplication.shared.delegate,
            let window = delegate.window,
            let viewController = window?.topmostPresentedViewController else { return }

        guard HelpshiftUtils.isHelpshiftEnabled() else { return }

        let presenter = HelpshiftPresenter()
        presenter.sourceTag = SupportSourceTag.aztecFeedback
        presenter.presentHelpshiftConversationWindowFromViewController(viewController,
                                                                       refreshUserDetails: true,
                                                                       completion: nil)
    }
}
