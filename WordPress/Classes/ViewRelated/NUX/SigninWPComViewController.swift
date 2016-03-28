import UIKit
import WordPressComAnalytics
import WordPressShared

///
///
class SigninWPComViewController : SigninAbstractViewController, SigninWPComDelegate
{

    @IBOutlet weak var usernameField: WPWalkthroughTextField!
    @IBOutlet weak var passwordField: WPWalkthroughTextField!
    @IBOutlet weak var submitButton: WPNUXMainButton!
    @IBOutlet weak var statusLabel: UILabel!
    var onePasswordButton: UIButton!

    var immediateSignin = false;

    lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()


    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameters:
    ///     - loginFields: A LoginFields instance containing any prefilled credentials.
    ///     - immediateSignin: Whether the controller should attempt to signin immediately.
    ///
    class func controller(loginFields: LoginFields, immediateSignin: Bool = false) -> SigninWPComViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SigninWPComViewController") as! SigninWPComViewController
        controller.loginFields = loginFields
        controller.immediateSignin = immediateSignin
        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        setupOnePasswordButtonIfNeeded()
        displayLoginMessage("")
    }


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.userIsDotCom = true

        configureTextFields()
        configureSubmitButton(false)
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if immediateSignin {
            validateForm()
            immediateSignin = false
        }
    }


    // MARK: Setup and Configuration


    ///
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(usernameField,
                                                            target: self,
                                                            selector: #selector(SigninWPComViewController.handleOnePasswordButtonTapped(_:)))
    }


    ///
    ///
    func configureTextFields() {
        usernameField.text = loginFields.username
        passwordField.text = loginFields.password
    }


    ///
    ///
    func configureStatusMessage(message: String) {
        statusLabel.text = message
    }


    ///
    ///
    func configureSubmitButton(animating: Bool) {
        submitButton.showActivityIndicator(animating)

        submitButton.enabled = (
            !animating &&
                !loginFields.username.isEmpty &&
                !loginFields.password.isEmpty
        )
    }


    ///
    ///
    func configureLoading(loading: Bool) {
        usernameField.enabled = !loading
        passwordField.enabled = !loading
        
        configureSubmitButton(loading)
    }


    // MARK: - Instance Methods


    ///
    ///
    func validateForm() {
        view.endEditing(true)

        // is reachable?
        if !ReachabilityUtils.isInternetReachable() {
            ReachabilityUtils.showAlertNoInternetConnection()
            return
        }


        // Is everything filled out?
        if !SigninHelpers.validateFieldsPopulatedForSignin(loginFields) {
            WPError.showAlertWithTitle(NSLocalizedString("Error", comment: "Title of an error message"),
                                       message: NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields."),
                                       withSupportButton: false)

            return
        }

        configureLoading(true)

        loginFacade.signInWithLoginFields(loginFields)
    }


    /// Update safari stored credentials. Call after a successful sign in.
    ///
    func updateSafariCredentialsIfNeeded() {
        SigninHelpers.updateSafariCredentialsIfNeeded(loginFields)
    }


    // MARK: - Actions


    @IBAction func handleTextFieldDidChange(sender: UITextField) {
        loginFields.username = usernameField.nonNilTrimmedText()
        loginFields.password = passwordField.nonNilTrimmedText()

        configureSubmitButton(false)
    }


    @IBAction func handleSubmitForm() {
        validateForm()
    }


    @IBAction func handleSubmitButtonTapped(sender: UIButton) {
        validateForm()
    }


    @IBAction func handleForgotPasswordButtonTapped(sender: UIButton) {
        openForgotPasswordURL()
    }


    func handleOnePasswordButtonTapped(sender: UIButton) {
        view.endEditing(true)

        SigninHelpers.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [unowned self] (loginFields) in
            self.validateForm()
        }
    }
}


extension SigninWPComViewController: LoginFacadeDelegate {

    func finishedLoginWithUsername(username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        syncWPCom(username, authToken: authToken, requiredMultifactor: requiredMultifactorCode)
    }


    func displayLoginMessage(message: String!) {
        configureStatusMessage(message)
    }


    func displayRemoteError(error: NSError!) {
        configureSubmitButton(false)
        displayError(error)
    }


    func needsMultifactorCode() {
        WPAppAnalytics.track(.TwoFactorCodeRequested)
        // Credentials were good but a 2fa code is needed.
        loginFields.shouldDisplayMultifactor = true // technically not needed
        let controller = Signin2FAViewController.controller(loginFields)
        navigationController?.pushViewController(controller, animated: true)
    }
}


extension SigninWPComViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        }
        return true
    }
}
