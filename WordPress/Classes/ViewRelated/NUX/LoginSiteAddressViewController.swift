import UIKit

class LoginSiteAddressViewController: NUXAbstractViewController, SigninKeyboardResponder, LoginViewController {
    @IBOutlet var instructionLabel: UILabel!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet weak var siteURLField: WPWalkthroughTextField!
    @IBOutlet weak var submitButton: NUXSubmitButton!
    @IBOutlet var siteAddressHelpButton: UIButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?

    override var sourceTag: SupportSourceTag {
        get {
            return .wpOrgLogin
        }
    }


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarIcon()

        localizeControls()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.userIsDotCom = false

        configureTextFields()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()

        WPAppAnalytics.track(.loginURLFormViewed)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: Setup and Configuration


    /// Let the storyboard's style stay
    /// TODO: Nuke this and the super implementation once the old signin controllers
    /// go away. 2017.06.13 - Aerych
    override func setupStyles() {}


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        instructionLabel.text = NSLocalizedString("Enter the address of your WordPress site you'd like to connect.", comment: "Instruction text on the login's site addresss screen.")

        siteURLField.placeholder = NSLocalizedString("example.wordress.com", comment: "Site Address placeholder")

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton.setTitle(submitButtonTitle, for: UIControlState())
        submitButton.setTitle(submitButtonTitle, for: .highlighted)
        submitButton.accessibilityIdentifier = "Next Button"

        let siteAddressHelpTitle = NSLocalizedString("Need help finding your site address?", comment: "A button title.")
        siteAddressHelpButton.setTitle(siteAddressHelpTitle, for: UIControlState())
        siteAddressHelpButton.setTitle(siteAddressHelpTitle, for: .highlighted)
        siteAddressHelpButton.titleLabel?.numberOfLines = 0
    }


    /// Configures the content of the text fields based on what is saved in `loginFields`.
    ///
    func configureTextFields() {
        siteURLField.textInsets = UIEdgeInsetsMake(7, 20, 7, 20)
        siteURLField.text = loginFields.siteUrl
    }


    /// Configures the appearance and state of the submit button.
    ///
    func configureSubmitButton(animating: Bool) {
        submitButton.showActivityIndicator(animating)

        submitButton.isEnabled = (
            !animating && SigninHelpers.validateSiteForSignin(loginFields)
        )
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    func configureViewLoading(_ loading: Bool) {
        siteURLField.isEnabled = !loading

        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            siteURLField.becomeFirstResponder()
        }
    }


    // MARK: - Instance Methods


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        view.endEditing(true)
        displayError(message: "")
        guard SigninHelpers.validateSiteForSignin(loginFields) else {
            assertionFailure("Form should not be submitted unless there is a valid looking URL entered.")
            return
        }

        configureViewLoading(true)

        let facade = WordPressXMLRPCAPIFacade()
        facade.guessXMLRPCURL(forSite: loginFields.siteUrl, success: { [weak self] (url) in
            self?.configureViewLoading(false)
            self?.showSelfHostedUsernamePassword()

        }, failure: { [weak self] (error) in
            guard let error = error, let strongSelf = self else {
                return
            }
            DDLogSwift.logError(error.localizedDescription)
            WPAppAnalytics.track(.loginFailed, error: error)
            strongSelf.configureViewLoading(false)

            let err = strongSelf.originalErrorOrError(error: error as NSError)
            if strongSelf.errorDiscoveringJetpackSite(error: err) {
                strongSelf.displayError(error as NSError, sourceTag: .jetpackLogin)

            } else if err.domain == NSURLErrorDomain && err.code == NSURLErrorNetworkConnectionLost {
                // NSURLErrorNetworkConnectionLost is returned when an invalid URL is entered.
                let msg = NSLocalizedString("Hmm, it doesn't look like there's a WordPress site at this URL. Double-check the spelling and try again.",
                                            comment: "Error message shown a URL does not point to an existing site.")
                strongSelf.displayError(message: msg)

            } else if err.domain == "WordPressKit.WordPressOrgXMLRPCValidatorError" && err.code == WordPressOrgXMLRPCValidatorError.invalid.rawValue {
                let msg = NSLocalizedString("We're sure this is a great site -- but it's not a WordPress site, so you can't connect it to with this app.",
                                            comment: "Error message shown a URL points to a valid site but not a WordPress site.")
                strongSelf.displayError(message: msg)

            } else {
                strongSelf.displayError(error as NSError, sourceTag: strongSelf.sourceTag)
            }
        })
    }


    func originalErrorOrError(error: NSError) -> NSError {
        guard let err = error.userInfo[XMLRPCOriginalErrorKey] as? NSError else {
            return error
        }
        return err
    }


    func errorDiscoveringJetpackSite(error: NSError) -> Bool {
        if let _ = error.userInfo[WordPressOrgXMLRPCValidator.UserInfoHasJetpackKey] {
            return true
        }

        return false
    }


    func showSelfHostedUsernamePassword() {
        performSegue(withIdentifier: .showURLUsernamePassword, sender: self)
    }


    func displayError(message: String) {
        errorLabel.text = message
    }


    // MARK: - Actions

    @IBAction func handleSubmitForm() {
        validateForm()
    }


    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }


    @IBAction func handleSiteAddressHelpButtonTapped(_ sender: UIButton) {
        // TODO: Wire up when the new help screen is implemented.
    }

    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.siteUrl = SigninHelpers.baseSiteURL(string: siteURLField.nonNilTrimmedText())
        configureSubmitButton(animating: false)
    }


    // MARK: - Keyboard Notifications


    func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}
