import UIKit
import SVProgressHUD
import WordPressComAnalytics
import WordPressShared

/// Handles the final step in the magic link auth process. At this point all the
/// necessary auth work should be done. We just need to create a WPAccount and to
/// sync account info and blog details.
/// The expectation is this controller will be momentarily visible when the app
/// is resumed/launched via the appropriate custom scheme, and quickly dismiss.
///
@objc class SigninLinkAuthViewController : NUXAbstractViewController, SigninWPComSyncHandler
{
    @IBOutlet weak var statusLabel: UILabel!

    var email: String = ""
    var token: String = ""
    var didSync: Bool = false


    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameters:
    ///     - email: The user's email address tied to their wpcom account.
    ///     - token: The user's auth token.
    ///
    class func controller(email: String, token: String) -> SigninLinkAuthViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SigninLinkAuthViewController") as! SigninLinkAuthViewController
        controller.email = email
        controller.token = token
        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        configureStatusLabel("")
    }


    override func viewDidAppear(animated: Bool) {
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
        WPAppAnalytics.track(.LoginMagicLinkSucceeded)
    }


    /// Displays the specified text in the status label.
    ///
    /// - Parameter message: The text to display in the label.
    ///
    func configureStatusLabel(message: String) {
        statusLabel.text = message
    }


    func configureViewLoading(loading: Bool) {
        // Noop
    }


    func updateSafariCredentialsIfNeeded() {
        // Noop
    }
}
