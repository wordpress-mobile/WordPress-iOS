import UIKit
import WordPressComAnalytics
import WordPressShared

/// This vc is the entry point for the normal sign in flow.
///
/// - Note: The sign in flow should be managed b ya NUXNavigationController for
/// appearance reasons. 
/// By convention the NUXNavigationController should be presented
/// from UIApplication.sharedApplication.keyWindow.rootViewController to ensure 
/// that the final step in the magic link auth flow can be performed correctly.
///
@objc class SigninEmailViewController: NUXAbstractViewController, SigninKeyboardResponder
{

    @IBOutlet var onePasswordButton: UIButton!
    @IBOutlet var emailTextField: WPWalkthroughTextField!
    @IBOutlet var submitButton: NUXSubmitButton!
    @IBOutlet var safariPasswordButton: WPNUXSecondaryButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint!
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint!

    var didFindSafariSharedCredentials = false
    var didRequestSafariSharedCredentials = false


    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameters:
    ///     - loginFields: Optional. A LoginFields instance containing any prefilled credentials.
    ///
    class func controller(loginFields: LoginFields? = nil) -> SigninEmailViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SigninEmailViewController") as! SigninEmailViewController
        controller.loginFields = loginFields == nil ? LoginFields() : loginFields!
        return controller
    }


    // MARK: Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        setupOnePasswordButtonIfNeeded()
        configureSafariPasswordButton(false)
    }


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // The old create account vc hides the nav bar, so make sure its always visible.
        navigationController?.setNavigationBarHidden(false, animated: false)

        // Update special case login fields.
        loginFields.userIsDotCom = true

        configureEmailField()
        configureSubmitButton()
        configureViewForEditingIfNeeded()
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        assert(SigninHelpers.controllerWasPresentedFromRootViewController(self),
               "Only present parts of the magic link signin flow from the application's root vc.")

        registerForKeyboardEvents(#selector(SigninEmailViewController.handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(SigninEmailViewController.handleKeyboardWillHide(_:)))


        if !didRequestSafariSharedCredentials {
            fetchSharedWebCredentialsIfAvailable()
        }
    }


    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: - Setup and Configuration


    /// Sets up a 1Password button if 1Password is available.
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(emailTextField,
                                                            target: self,
                                                            selector: #selector(SigninEmailViewController.handleOnePasswordButtonTapped(_:)))
    }


    /// Configures the button for requesting Safari stored credentials.
    /// The button should only be visible if Safari stored credentials are available.
    ///
    func configureSafariPasswordButton(animated: Bool) {
        if safariPasswordButton.hidden != didFindSafariSharedCredentials {
            return
        }

        if !animated {
            safariPasswordButton.hidden = !didFindSafariSharedCredentials
            return
        }

        UIView.animateWithDuration(0.2,
                                   delay: 0.0,
                                   options: .BeginFromCurrentState,
                                   animations: { 
                                        self.safariPasswordButton.hidden = !self.didFindSafariSharedCredentials
                                    },
                                   completion: nil)
    }


    /// Configures the email text field, updating its text based on what's stored
    /// in `loginFields`.
    ///
    func configureEmailField() {
        emailTextField.text = loginFields.username
    }


    /// Configures whether appearance of the submit button.
    ///
    func configureSubmitButton() {
        submitButton.enabled = !loginFields.username.isEmpty
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameters:
    ///     - loading: True if the form should be configured to a "loading" state.
    ///
    func configureViewLoading(loading: Bool) {
        emailTextField.enabled = !loading
        submitButton.enabled = !loading
        submitButton.showActivityIndicator(loading)
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            emailTextField.becomeFirstResponder()
        }
    }


    // MARK: - Instance Methods


    /// Makes the call to retrieve Safari shared credentials if they exist.
    ///
    func fetchSharedWebCredentialsIfAvailable() {
        didRequestSafariSharedCredentials = true
        SigninHelpers.requestSharedWebCredentials { [unowned self] (found, username, password) in
            self.handleFetchedWebCredentials(found, username: username, password: password)
        }
    }


    /// Handles Safari shared credentials if any where found.
    ///
    /// - Parameters:
    ///     - found: True if credentails were found. 
    ///     - username: The selected username or nil.
    ///     - password: The selected password or nil.
    ///
    func handleFetchedWebCredentials(found: Bool, username: String?, password: String?) {
        didFindSafariSharedCredentials = found
        configureSafariPasswordButton(true)

        guard let username = username, password = password else {
            return
        }

        // Update the login fields
        loginFields.username = username
        loginFields.password = password

        // Persist credentials as autofilled credentials so we can update them later if needed.
        loginFields.safariStoredUsernameHash = username.hash
        loginFields.safariStoredPasswordHash = password.hash

        signinWithUsernamePassword(false)

        WPAppAnalytics.track(.LoginAutoFillCredentialsFilled)
    }


    /// Displays the wpcom sign in form, optionally telling it to immedately make
    /// the call to authenticate with the available credentials.
    ///
    /// - Parameters:
    ///     - immediateSignin: True if the newly loaded controller should immedately attempt
    /// to authenticate the user with the available credentails.  Default is `false`.
    ///
    func signinWithUsernamePassword(immediateSignin: Bool = false) {
        let controller = SigninWPComViewController.controller(loginFields, immediateSignin: immediateSignin)
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Displays the self-hosted sign in form.
    ///
    func signinToSelfHostedSite() {
        let controller = SigninSelfHostedViewController.controller(loginFields);
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Proceeds along the "magic link" sign-in flow, showing a form that let's 
    /// the user request a magic link.
    ///
    func requestLink() {
        let controller = SigninLinkRequestViewController.controller(loginFields)
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Validates what is entered in the various form fields and, if valid, 
    /// proceeds with the submit action.
    ///
    func validateForm() {
        let emailOrUsername = loginFields.username

        guard !emailOrUsername.isEmpty else {
            return
        }

        guard emailOrUsername.isValidEmail() else {
            // A username was entered, not an email address.
            // Proceed to the next form:
            if SigninHelpers.isUsernameReserved(emailOrUsername) {
                signinToSelfHostedSite()
            } else {
                signinWithUsernamePassword()
            }
            return
        }

        configureViewLoading(true)

        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.isEmailAvailable(emailOrUsername,
            success: { [weak self] (available: Bool) in
                self?.configureViewLoading(false)
                if (available) {
                    // No matching email address found so treat this as a 
                    // self-hosted sign in.
                    self?.signinToSelfHostedSite()
                } else {
                    self?.requestLink()
                }
            },
            failure: { [weak self] (error: NSError!) in
                DDLogSwift.logError(error.localizedDescription)
                self?.configureViewLoading(false)
                self?.displayError(error)
            })
    }


    // MARK: - Actions


    @IBAction func handleSubmitForm() {
        validateForm()
    }


    @IBAction func handleSubmitButtonTapped(sender: UIButton) {
        validateForm()
    }


    func handleOnePasswordButtonTapped(sender: UIButton) {
        view.endEditing(true)

        SigninHelpers.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [unowned self] (loginFields) in
            self.signinWithUsernamePassword(true)
        }
    }
    

    @IBAction func handleSelfHostedButtonTapped(sender: UIButton) {
        signinToSelfHostedSite()
    }


    @IBAction func handleCreateSiteButtonTapped(sender: UIButton) {
        let controller = CreateAccountAndBlogViewController()
        navigationController?.pushViewController(controller, animated: true)
    }


    @IBAction func handleSafariPasswordButtonTapped(sender: UIButton) {
        fetchSharedWebCredentialsIfAvailable()
    }


    @IBAction func handleTextFieldDidChange(sender: UITextField) {
        loginFields.username = emailTextField.nonNilTrimmedText()
        configureSubmitButton()
    }


    // MARK: - Keyboard Notifications


    func handleKeyboardWillShow(notification: NSNotification) {
        keyboardWillShow(notification)
    }


    func handleKeyboardWillHide(notification: NSNotification) {
        keyboardWillHide(notification)
    }
}
