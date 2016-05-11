import UIKit
import WordPressShared
import wpxmlrpc


/// A view controller for prompting a user about sign in related errors.
/// It provides for a title, message, and for specialized button actions.
/// It is assumed the controller will always be presented modally.
///
class SigninErrorViewController : UIViewController
{
    typealias SigninErrorCallback = (() -> Void)

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var secondaryButton: UIButton!

    var delegate: SigninErrorViewControllerDelegate?
    var loginFields: LoginFields?

    var primaryButtonCompletionBlock: SigninErrorCallback?
    var secondaryButtonCompletionBlock: SigninErrorCallback?


    // MARK: - LifeCycle Methods


    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    class func controller() -> SigninErrorViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SigninErrorViewController") as! SigninErrorViewController
        return controller
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        modalPresentationStyle = .OverFullScreen
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        view.opaque = false
        view.backgroundColor = WPStyleGuide.colorForErrorView(false)
    }


    // MARK: - Configuration


    /// Displays an instance of WPWalkthroughOverlayView configured to show an error message.
    ///
    /// - Parameters:
    ///     - message: The error message to display to the user.
    ///     - firstButtonText: Optional. The label for the bottom right button.
    ///     - firstButtonCallback: Optional. The callback block to execute when the first button is tapped.
    ///     - secondButtonText: Optional. The label for the bottom left button.
    ///     - secondButtonCallback: The callback block to execute when the second button is tapped.
    ///     - accessibilityIdentifier: Optional. Used to identify the view to accessibiity features.
    ///
    func configureView(message: String, firstButtonText: String?, firstButtonCallback: SigninErrorCallback?, secondButtonText: String?, secondButtonCallback: SigninErrorCallback, accessibilityIdentifier: String?) {
        assert(!message.isEmpty)

        titleLabel.text = NSLocalizedString("Sorry, we can't log you in.", comment: "")
        descriptionLabel.text = message
        primaryButton.setTitle(NSLocalizedString("OK", comment: ""), forState: .Normal)
        secondaryButton.setTitle(NSLocalizedString("Need Help?", comment: ""), forState: .Normal)

        secondaryButtonCompletionBlock = secondButtonCallback

        if firstButtonText != nil {
            primaryButton.setTitle(firstButtonText!, forState: .Normal)
        }

        if secondButtonText != nil {
            secondaryButton.setTitle(secondButtonText!, forState: .Normal)
        }

        if firstButtonCallback != nil {
            primaryButtonCompletionBlock = firstButtonCallback!
        }

        if let accessibilityIdentifier = accessibilityIdentifier {
            view.accessibilityIdentifier = accessibilityIdentifier
        }
    }


    // MARK: - Instance Methods


    /// The preferred method for presenting the error view controller full screen
    /// and modal.  This method takes care of configuring presentation style and
    /// context so the controller is correctly displayed full screen.
    ///
    /// - Parameter controller: The controller to use as the presenter.
    ///
    func presentFromController(controller: UIViewController) {
        controller.providesPresentationContextTransitionStyle = true
        controller.definesPresentationContext = true
        controller.presentViewController(self, animated: false, completion: nil)
    }


    /// Dismisses the modal controller.
    ///
    func dismiss() {
        dismissViewControllerAnimated(false, completion: nil)
    }


    // MARK: - Actions


    @IBAction func handlePrimaryButtonTapped(sender: UIButton) {
        guard let callback = primaryButtonCompletionBlock else {
            dismiss()
            return
        }
        callback()
    }


    @IBAction func handleSecondaryButtonTapped(sender: UIButton) {
        secondaryButtonCompletionBlock?()
    }


    @IBAction func handleTapGesture(sender: UITapGestureRecognizer) {
        dismiss()
    }


    // MARK: - Error Handling


    /// Display the specified error in a WPWalkthroughOverlayView.
    /// The view is configured differently depending on the kind of error.
    ///
    /// - Parameter error: An NSError instance
    ///
    func displayError(error: NSError, loginFields: LoginFields, delegate: SigninErrorViewControllerDelegate) {
        self.loginFields = loginFields
        self.delegate = delegate

        var message = error.localizedDescription

        DDLogSwift.logError(message)

        if error.domain != WPXMLRPCFaultErrorDomain && error.code != NSURLErrorBadURL {
            if HelpshiftUtils.isHelpshiftEnabled() {
                displayGenericErrorMessageWithHelpshiftButton(message)

            } else {
                displayGenericErrorMessage(message)
            }
            return
        }

        if error.code == 403 {
            message = NSLocalizedString("Incorrect username or password. Please try entering your login details again.", comment: "An error message shown when a user signed in with incorrect credentials.")
        }

        if message.trim().characters.count == 0 {
            message = NSLocalizedString("Sign in failed. Please try again.", comment: "A generic error message for a failed sign in.")
        }

        if error.code == 405 {
            displayErrorMessageForXMLRPC(message)
        } else  if error.code == NSURLErrorBadURL {
            displayErrorMessageForBadURL(message)
        } else {
            displayGenericErrorMessage(message)
        }
    }


    /// Shows a WPWalkthroughOverlayView for a generic error message.
    ///
    /// - Parameter message: The error message to show.
    ///
    func displayGenericErrorMessage(message: String) {
        let callback: SigninErrorCallback = { [unowned self] in
            self.dismiss()
            self.delegate?.displaySupportViewController()
        }

        configureView(message,
                           firstButtonText: nil,
                           firstButtonCallback: nil,
                           secondButtonText: nil,
                           secondButtonCallback: callback,
                           accessibilityIdentifier: "GenericErrorMessage")
    }


    /// Shows a WPWalkthroughOverlayView for a generic error message. The view
    /// is configured so the user can open Helpshift for assistance.
    ///
    /// - Parameter message: The error message to show.
    ///
    func displayGenericErrorMessageWithHelpshiftButton(message: String) {
        let callback: SigninErrorCallback = { [unowned self] in
            self.dismiss()
            self.delegate?.displayHelpshiftConversationView()
        }

        configureView(message,
                           firstButtonText: nil,
                           firstButtonCallback: nil,
                           secondButtonText: NSLocalizedString("Contact Us", comment:"The text on the button at the bottom of the error message when a user has repeated trouble logging in"),
                           secondButtonCallback: callback,
                           accessibilityIdentifier: "GenericErrorMessage")
    }


    /// Shows a WPWalkthroughOverlayView for an XML-RPC error message.
    ///
    /// - Parameter message: The error message to show.
    ///
    func displayErrorMessageForXMLRPC(message: String) {
        let firstCallback: SigninErrorCallback = { [unowned self] in
            self.dismiss()

            guard let loginFields = self.loginFields else {
                return
            }

            var path: NSString
            let regex = try! NSRegularExpression(pattern: "http\\S+writing.php", options: .CaseInsensitive)
            let rng = regex.rangeOfFirstMatchInString(message, options: .ReportCompletion, range: NSRange(location: 0, length: message.characters.count))
            if rng.location == NSNotFound {
                path = SigninHelpers.baseSiteURL(loginFields.siteUrl)
                path = path.stringByReplacingOccurrencesOfString("xmlrpc.php", withString: "")
                path = path.stringByAppendingString("/wp-admin/options-writing.php")
            } else {
                path = NSString(string: message).substringWithRange(rng)
            }

            self.delegate?.displayWebviewForURL(NSURL(string: path as String)!, username: loginFields.username, password: loginFields.password)
        }

        let secondCallback: SigninErrorCallback = { [unowned self] in
            self.dismiss()
            self.delegate?.displaySupportViewController()
        }

        configureView(message,
                           firstButtonText: NSLocalizedString("Enable Now", comment: "A call to action."),
                           firstButtonCallback: firstCallback,
                           secondButtonText: nil,
                           secondButtonCallback: secondCallback,
                           accessibilityIdentifier: nil)
    }


    /// Shows a WPWalkthroughOverlayView for a bad url error message.
    ///
    /// - Parameter message: The error message to show.
    ///
    func displayErrorMessageForBadURL(message: String) {
        let callback: SigninErrorCallback = { [unowned self] in
            self.dismiss()
            self.delegate?.displayWebviewForURL(NSURL(string: "https://apps.wordpress.org/support/#faq-ios-3")!, username: nil, password: nil)
        }

        configureView(message,
                           firstButtonText: nil,
                           firstButtonCallback: nil,
                           secondButtonText: nil,
                           secondButtonCallback: callback,
                           accessibilityIdentifier: nil)
    }

}


/// Defines responsibilities for the delegate of a SigninErrorViewController.
///
protocol SigninErrorViewControllerDelegate
{
    /// Delegates should implement this method and display the support view controller when called.
    ///
    func displaySupportViewController()


    /// Delegates should implement this method and display the helpshift conversation when called.
    ///
    func displayHelpshiftConversationView()


    /// Delegates should implement this method and display the in-app web browser when called.
    ///
    func displayWebviewForURL(url: NSURL, username: String?, password: String?)
}
