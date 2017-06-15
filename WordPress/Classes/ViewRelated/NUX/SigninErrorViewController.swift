import UIKit
import WordPressShared
import wpxmlrpc


/// A view controller for prompting a user about sign in related errors.
/// It provides for a title, message, and for specialized button actions.
/// It is assumed the controller will always be presented modally.
///
class SigninErrorViewController: UIViewController {
    typealias SigninErrorCallback = (() -> Void)

    @IBOutlet weak var icon: UIImageView!
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
        let storyboard = UIStoryboard(name: "Signin", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "SigninErrorViewController") as! SigninErrorViewController
        return controller
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        view.isOpaque = false
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
    func configureView(_ message: String, firstButtonText: String?, firstButtonCallback: SigninErrorCallback?, secondButtonText: String?, secondButtonCallback: @escaping SigninErrorCallback, accessibilityIdentifier: String?) {
        assert(!message.isEmpty)

        descriptionLabel.text = message
        primaryButton.setTitle(NSLocalizedString("OK", comment: ""), for: UIControlState())
        secondaryButton.setTitle(NSLocalizedString("Need Help?", comment: ""), for: UIControlState())

        secondaryButtonCompletionBlock = secondButtonCallback

        if firstButtonText != nil {
            primaryButton.setTitle(firstButtonText!, for: UIControlState())
        }

        if secondButtonText != nil {
            secondaryButton.setTitle(secondButtonText!, for: UIControlState())
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
    func presentFromController(_ controller: UIViewController) {
        controller.providesPresentationContextTransitionStyle = true
        controller.definesPresentationContext = true
        controller.present(self, animated: false, completion: {
            if (UIAccessibilityIsVoiceOverRunning()) {
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.descriptionLabel)
            }
        })
    }


    /// Dismisses the modal controller.
    ///
    func dismiss() {
        self.dismiss(animated: false, completion: nil)
    }


    // MARK: - Actions


    @IBAction func handlePrimaryButtonTapped(_ sender: UIButton) {
        guard let callback = primaryButtonCompletionBlock else {
            dismiss()
            return
        }
        callback()
    }


    @IBAction func handleSecondaryButtonTapped(_ sender: UIButton) {
        secondaryButtonCompletionBlock?()
    }


    @IBAction func handleTapGesture(_ sender: UITapGestureRecognizer) {
        dismiss()
    }


    // MARK: - Error Handling


    /// Display the specified error in a WPWalkthroughOverlayView.
    /// The view is configured differently depending on the kind of error.
    ///
    /// - Parameter error: An NSError instance
    ///
    func displayError(_ error: NSError, loginFields: LoginFields, delegate: SigninErrorViewControllerDelegate, sourceTag: SupportSourceTag) {
        self.loginFields = loginFields
        self.delegate = delegate

        var message = error.localizedDescription

        DDLogSwift.logError(message)

        if sourceTag == .jetpackLogin && error.domain == WordPressAppErrorDomain && error.code == NSURLErrorBadURL {
            if HelpshiftUtils.isHelpshiftEnabled() {
                // TODO: Placeholder Jetpack login error message. Needs updating with final wording. 2017-06-15 Aerych.
                message = NSLocalizedString("We're not able to connect to the Jetpack site at that URL.  Contact us for assistance.", comment: "Error message shown when having trouble connecting to a Jetpack site.")
                displayGenericErrorMessageWithHelpshiftButton(message, sourceTag: sourceTag)
                return;
            }
        }

        if error.domain != WPXMLRPCFaultErrorDomain && error.code != NSURLErrorBadURL {
            if HelpshiftUtils.isHelpshiftEnabled() {
                displayGenericErrorMessageWithHelpshiftButton(message, sourceTag: sourceTag)

            } else {
                displayGenericErrorMessage(message, sourceTag: sourceTag)
            }
            return
        }

        if error.code == 403 {
            message = NSLocalizedString("Incorrect username or password. Please try entering your login details again.", comment: "An error message shown when a user signed in with incorrect credentials.")
        }

        if message.trim().characters.count == 0 {
            message = NSLocalizedString("Log in failed. Please try again.", comment: "A generic error message for a failed log in.")
        }

        if error.code == 405 {
            displayErrorMessageForXMLRPC(message, sourceTag: sourceTag)
        } else  if error.code == NSURLErrorBadURL {
            displayErrorMessageForBadURL(message)
        } else {
            displayGenericErrorMessage(message, sourceTag: sourceTag)
        }
    }


    /// Shows a WPWalkthroughOverlayView for a generic error message.
    ///
    /// - Parameter message: The error message to show.
    ///
    func displayGenericErrorMessage(_ message: String, sourceTag: SupportSourceTag) {
        let callback: SigninErrorCallback = { [unowned self] in
            self.dismiss()
            self.delegate?.displaySupportViewController(sourceTag: sourceTag)
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
    /// - Parameter sourceTag: tag of the source of the error
    ///
    func displayGenericErrorMessageWithHelpshiftButton(_ message: String, sourceTag: SupportSourceTag) {
        let callback: SigninErrorCallback = { [unowned self] in
            self.dismiss()
            self.delegate?.displayHelpshiftConversationView(sourceTag: sourceTag)
        }

        configureView(message,
                           firstButtonText: nil,
                           firstButtonCallback: nil,
                           secondButtonText: NSLocalizedString("Contact Us", comment: "The text on the button at the bottom of the error message when a user has repeated trouble logging in"),
                           secondButtonCallback: callback,
                           accessibilityIdentifier: "GenericErrorMessage")
    }


    /// Shows a WPWalkthroughOverlayView for an XML-RPC error message.
    ///
    /// - Parameter message: The error message to show.
    ///
    func displayErrorMessageForXMLRPC(_ message: String, sourceTag: SupportSourceTag) {
        let firstCallback: SigninErrorCallback = { [unowned self] in
            self.dismiss()

            guard let loginFields = self.loginFields else {
                return
            }

            var path: NSString
            let regex = try! NSRegularExpression(pattern: "http\\S+writing.php", options: .caseInsensitive)
            let rng = regex.rangeOfFirstMatch(in: message, options: .reportCompletion, range: NSRange(location: 0, length: message.characters.count))
            if rng.location == NSNotFound {
                path = SigninHelpers.baseSiteURL(string: loginFields.siteUrl) as NSString
                path = path.replacingOccurrences(of: "xmlrpc.php", with: "") as NSString
                path = path.appending("/wp-admin/options-writing.php") as NSString
            } else {
                let message = message as NSString
                path = message.substring(with: rng) as NSString
            }

            self.delegate?.displayWebviewForURL(URL(string: path as String)!, username: loginFields.username, password: loginFields.password)
        }

        let secondCallback: SigninErrorCallback = { [unowned self] in
            self.dismiss()
            self.delegate?.displaySupportViewController(sourceTag: sourceTag)
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
    func displayErrorMessageForBadURL(_ message: String) {
        let callback: SigninErrorCallback = { [unowned self] in
            self.dismiss()
            self.delegate?.displayWebviewForURL(URL(string: "https://apps.wordpress.org/support/#faq-ios-3")!, username: nil, password: nil)
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
protocol SigninErrorViewControllerDelegate {
    /// The Helpshift tag to track the origin of user conversations
    ///
    var sourceTag: SupportSourceTag { get }

    /// Delegates should implement this method and display the support view controller when called.
    ///
    func displaySupportViewController(sourceTag: SupportSourceTag)


    /// Delegates should implement this method and display the helpshift conversation when called.
    ///
    func displayHelpshiftConversationView(sourceTag: SupportSourceTag)


    /// Delegates should implement this method and display the in-app web browser when called.
    ///
    func displayWebviewForURL(_ url: URL, username: String?, password: String?)
}
