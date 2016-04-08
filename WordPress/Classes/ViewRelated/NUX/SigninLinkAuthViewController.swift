import UIKit
import SVProgressHUD
import WordPressComAnalytics
import WordPressShared

/// Handles the final step in the magic link auth proces.
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
    ///     - token: A string containing .

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

        configureStatusMessage("")
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if didSync {
            return
        }

        didSync = true // Make sure we don't call this twice by accident
        syncWPCom(email, authToken: token, requiredMultifactor: false)
    }


    /// Displays the specified text in the status label.
    ///
    /// - Parameters:
    ///     - message: The text to display in the label.
    ///
    func configureStatusMessage(message: String) {
        statusLabel.text = message
    }


    func configureLoading(loading: Bool) {
        // Noop
    }


    func updateSafariCredentialsIfNeeded() {
        // Noop
    }

}
