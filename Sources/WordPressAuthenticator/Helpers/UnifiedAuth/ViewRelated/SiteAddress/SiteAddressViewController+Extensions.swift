import UIKit
import SwiftUI
import WordPressUI

extension SiteAddressViewController {
    static func showSiteAddressHelpAlert(
        from presentingViewController: UIViewController,
        sourceTag: WordPressSupportSourceTag,
        moreHelpTapped: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        let alert = AlertView {
            AlertHeaderView(
                title: Strings.title,
                description: Strings.description
            )
        } content: {
            Image("site-address-illustration", bundle: WordPressAuthenticator.bundle)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        } actions: {
            AlertDismissButton(onDismiss: onDismiss)

            Button(Strings.moreHelp) {
                presentingViewController.presentedViewController?.dismiss(animated: true) {
                    guard WordPressAuthenticator.shared.delegate?.supportEnabled == true,
                          let viewController = UIApplication.shared.delegate?.window??.topmostPresentedViewController
                    else {
                        return
                    }

                    moreHelpTapped?()
                    WordPressAuthenticator.shared.delegate?.presentSupportRequest(from: viewController, sourceTag: sourceTag)
                }
            }
        }

        alert.present(in: presentingViewController)
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "login.siteAddressHelp.title",
        value: "What's my site address?",
        comment: "Title of alert helping users understand their site address during login"
    )
    static let description = NSLocalizedString(
        "login.siteAddressHelp.description",
        value: "Your site address appears in the bar at the top of the screen when you visit your site in Safari.",
        comment: "Description text explaining where to find site address during login"
    )
    static let moreHelp = NSLocalizedString(
        "login.siteAddressHelp.moreHelpButton",
        value: "Need more help?",
        comment: "Button title to get additional help finding site address during login"
    )
}
