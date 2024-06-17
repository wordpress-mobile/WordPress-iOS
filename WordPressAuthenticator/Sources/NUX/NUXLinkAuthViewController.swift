import UIKit
import WordPressShared

/// Handles the final step in the magic link auth process. At this point all the
/// necessary auth work should be done. We just need to create a WPAccount and to
/// sync account info and blog details.
/// The expectation is this controller will be momentarily visible when the app
/// is resumed/launched via the appropriate custom scheme, and quickly dismiss.
///
class NUXLinkAuthViewController: LoginViewController {
    @IBOutlet weak var statusLabel: UILabel?

    enum Flow {
        case signup
        case login
    }

    /// Displays the specified text in the status label.
    ///
    /// - Parameter message: The text to display in the label.
    ///
    override func configureStatusLabel(_ message: String) {
        statusLabel?.text = message
    }

    func syncAndContinue(authToken: String, flow: Flow, isJetpackConnect: Bool) {
        let wpcom = WordPressComCredentials(authToken: authToken, isJetpackLogin: isJetpackConnect, multifactor: false, siteURL: "https://wordpress.com")
        let credentials = AuthenticatorCredentials(wpcom: wpcom)

        syncWPComAndPresentEpilogue(credentials: credentials) {
            self.tracker.track(step: .success)

            switch flow {
            case .signup:
                // This stat is part of a funnel that provides critical information.  Before
                // making ANY modification to this stat please refer to: p4qSXL-35X-p2
                WordPressAuthenticator.track(.createdAccount, properties: ["source": "email"])
                WordPressAuthenticator.track(.signupMagicLinkSucceeded)
            case .login:
                WordPressAuthenticator.track(.loginMagicLinkSucceeded)
            }
        }
    }
}
