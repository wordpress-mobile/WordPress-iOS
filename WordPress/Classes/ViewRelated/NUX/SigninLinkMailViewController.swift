import UIKit

/// Step two in the auth link flow. This VC prompts the user to open their email
/// app to look for the emailed authentication link.
///
class SigninLinkMailViewController : NUXAbstractViewController
{

    @IBOutlet var label: UILabel!


    ///
    ///
    class func controller(loginFields: LoginFields) -> SigninLinkMailViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SigninLinkMailViewController") as! SigninLinkMailViewController
        controller.loginFields = loginFields
        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        if let email = loginFields.username {
            let format = NSLocalizedString("We've sent your link to %@.", comment: "Short instructional text. The %@ is a placeholder for the user's email address.")
            label.text = NSString(format: format, email) as String
        }
    }


    // MARK: - Actions


    @IBAction func handleOpenMailTapped(sender: UIButton) {
        let url = NSURL(string: "message://")!
        UIApplication.sharedApplication().openURL(url)
    }


    @IBAction func handleUsePasswordTapped(sender: UIButton) {
        WPAppAnalytics.track(.LoginMagicLinkExited)
        let controller = SigninWPComViewController.controller(loginFields)
        navigationController?.pushViewController(controller, animated: true)
    }
}
