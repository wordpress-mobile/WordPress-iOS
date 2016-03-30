import UIKit

/// Step one in the auth link flow. This VC displays a form to request a "magic"
/// authentication link be emailed to the user.  Allows the user to signin via
/// email instead of their password.
///
class SigninLinkRequestViewController : NUXAbstractViewController
{

    @IBOutlet var label: UILabel!
    @IBOutlet var sendLinkButton: UIButton!


    ///
    ///
    class func controller(loginFields: LoginFields) -> SigninLinkRequestViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SigninLinkRequestViewController") as! SigninLinkRequestViewController
        controller.loginFields = loginFields
        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        if let email = loginFields.username {
            let format = NSLocalizedString("Get a link sent to %@ to sign in instantly.", comment: "Short instructional text. The %@ is a placeholder for the user's email address.")
            label.text = NSString(format: format, email) as String
        }
    }


    // MARK: - Instance Methods


    /// Makes the call to request a magic authentication link be emailed to the user.
    ///
    func requestAuthenticationLink() {
        guard let email = loginFields.username else {
            return
        }

        sendLinkButton.enabled = false
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.requestAuthenticationLink(email,
            success: { [weak self] in
                self?.didRequestAuthenticationLink()

            }, failure: { [weak self] (error: NSError!) in
                DDLogSwift.logError(error.description)
                self?.sendLinkButton.enabled = true
            })
    }


    /// Displays the next step in the magic links sign in flow. 
    ///
    func didRequestAuthenticationLink() {
        let controller = SigninLinkMailViewController.controller(loginFields)
        navigationController?.pushViewController(controller, animated: true)
    }


    // MARK: - Actions


    @IBAction func handleSendLinkTapped(sender: UIButton) {
        requestAuthenticationLink()
    }


    @IBAction func handleUsePasswordTapped(sender: UIButton) {
        let controller = SigninWPComViewController.controller(loginFields)
        navigationController?.pushViewController(controller, animated: true)
    }

}
