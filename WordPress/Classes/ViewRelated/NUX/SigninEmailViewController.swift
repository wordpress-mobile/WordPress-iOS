import UIKit
import WordPressComAnalytics
import WordPressShared

/// This vc is the entry point for the normal sign in flow.
///
///
class SigninEmailViewController : SigninAbstractViewController
{

    @IBOutlet var onePasswordButton: UIButton!
    @IBOutlet var emailTextField: WPWalkthroughTextField!
    @IBOutlet var submitButton: WPNUXMainButton!
    @IBOutlet var selfHostedButton: WPNUXSecondaryButton!
    @IBOutlet var createSiteButton: WPNUXSecondaryButton!
    @IBOutlet var safariPasswordButton: WPNUXSecondaryButton!

    var didFindSafariSharedCredentials = false
    var didRequestSafariSharedCredentials = false

    lazy var accountServiceRemote = AccountServiceRemoteREST()


    /// A convenience method for obtaining an instance of the controller from a storyboard.
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

        // Update special case login fields.
        loginFields.userIsDotCom = false

        configureEmailField()
        configureSubmitButton()
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if !didRequestSafariSharedCredentials {
            fetchSharedWebCredentialsIfAvailable()
        }
    }


    // MARK: - Setup and Configuration


    ///
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(emailTextField,
                                                            target: self,
                                                            selector: #selector(SigninEmailViewController.handleOnePasswordButtonTapped(_:)))
    }


    ///
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


    ///
    ///
    func configureEmailField() {
        emailTextField.text = loginFields.username
    }


    ///
    ///
    func configureSubmitButton() {
        submitButton.enabled = !loginFields.username.isEmpty

        submitButton.alpha = submitButton.enabled ? 1.0 : 5.0;
    }


    // MARK: - Instance Methods


    ///
    ///
    func fetchSharedWebCredentialsIfAvailable() {
        didRequestSafariSharedCredentials = true
        SigninHelpers.requestSharedWebCredentials { [unowned self] (found, username, password) in
            self.handleFetchedWebCredentials(found, username: username, password: password)
        }
    }


    ///
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
        loginFields.safariStoredUsernameHash = UInt(username.hash)
        loginFields.safariStoredPasswordHash = UInt(password.hash)

        signinWithUsernamePassword(false)

        WPAppAnalytics.track(WPAnalyticsStat.SafariCredentialsLoginFilled)
    }


    ///
    ///
    func signinWithUsernamePassword(immediateSignin: Bool = false) {
        let controller = SigninWPComViewController.controller(loginFields, immediateSignin: immediateSignin)
        navigationController?.pushViewController(controller, animated: true)
    }


    ///
    ///
    func signinToSelfHostedSite() {
        let controller = SigninSelfHostedViewController.controller(loginFields);
        navigationController?.pushViewController(controller, animated: true)
    }


    ///
    ///
    func requestLink() {
        let controller = SigninLinkRequestViewController.controller(loginFields)
        navigationController?.pushViewController(controller, animated: true)
    }


    ///
    ///
    func validateForm() {
        let emailOrUsername = loginFields.username

        guard !emailOrUsername.isEmpty else {
            return
        }

        guard SigninHelpers.resemblesEmailAddress(emailOrUsername) else {
            // A username was entered, not an email address.
            // Proceed to the password form.
            signinWithUsernamePassword()
            return
        }

        setLoading(true)

        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.findExistingAccountByEmail(emailOrUsername,
           success: { [weak self] (found: Bool) in
                self?.setLoading(false)
                if (found) {
                    self?.requestLink()
                } else {
                    self?.signinToSelfHostedSite()
                }

            }, failure: { [weak self] (error: NSError!) in
                DDLogSwift.logError(error.localizedDescription)
                self?.setLoading(false)
                self?.displayError(error)
            })
    }


    ///
    ///
    func setLoading(loading: Bool) {
        emailTextField.enabled = !loading
        submitButton.enabled = !loading
        submitButton.showActivityIndicator(loading)
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
}
