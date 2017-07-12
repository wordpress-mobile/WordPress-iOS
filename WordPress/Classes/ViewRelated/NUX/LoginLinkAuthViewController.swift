import UIKit
import SVProgressHUD
import WordPressShared

/// Handles the final step in the magic link auth process. At this point all the
/// necessary auth work should be done. We just need to create a WPAccount and to
/// sync account info and blog details.
/// The expectation is this controller will be momentarily visible when the app
/// is resumed/launched via the appropriate custom scheme, and quickly dismiss.
///
class LoginLinkAuthViewController: LoginViewController {
    @IBOutlet weak var statusLabel: UILabel?
    var email: String = ""
    var token: String = ""
    var didSync: Bool = false

    // let the storyboard's style stay
    override func setupStyles() {}

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Gotta have email and token to use this vc
        assert(!email.isEmpty && !token.isEmpty)

        if didSync {
            return
        }

        didSync = true // Make sure we don't call this twice by accident
        syncWPCom(email, authToken: token, requiredMultifactor: false)

        // Count this as success since we're authed. Even if there is a glitch
        // while syncing the user has valid credentials.
        WPAppAnalytics.track(.loginMagicLinkSucceeded)
    }

    /// Displays the specified text in the status label.
    ///
    /// - Parameter message: The text to display in the label.
    ///
    override func configureStatusLabel(_ message: String) {
        statusLabel?.text = message
    }

    override func updateSafariCredentialsIfNeeded() {
        // Noop
    }

    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }
}
