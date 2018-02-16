import UIKit

class LoginSiteAddressViewController: LoginViewController, NUXKeyboardResponder {
    @IBOutlet weak var siteURLField: WPWalkthroughTextField!
    @IBOutlet var siteAddressHelpButton: UIButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginSiteAddress
        }
    }


    override var loginFields: LoginFields {
        didSet {
            // Clear the site url and site info (if any) from LoginFields
            loginFields.siteAddress = ""
            loginFields.meta.siteInfo = nil
        }
    }


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        localizeControls()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.meta.userIsDotCom = false

        configureTextFields()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()

        navigationController?.setNavigationBarHidden(false, animated: false)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
        WordPressAuthenticator.post(event: .loginURLFormViewed)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: Setup and Configuration


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    @objc func localizeControls() {
        instructionLabel?.text = NSLocalizedString("Enter the address of your WordPress site you'd like to connect.", comment: "Instruction text on the login's site addresss screen.")

        siteURLField.placeholder = NSLocalizedString("example.wordpress.com", comment: "Site Address placeholder")

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: UIControlState())
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)
        submitButton?.accessibilityIdentifier = "Next Button"

        let siteAddressHelpTitle = NSLocalizedString("Need help finding your site address?", comment: "A button title.")
        siteAddressHelpButton.setTitle(siteAddressHelpTitle, for: UIControlState())
        siteAddressHelpButton.setTitle(siteAddressHelpTitle, for: .highlighted)
        siteAddressHelpButton.titleLabel?.numberOfLines = 0
    }


    /// Configures the content of the text fields based on what is saved in `loginFields`.
    ///
    @objc func configureTextFields() {
        siteURLField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        siteURLField.text = loginFields.siteAddress
    }


    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)

        submitButton?.isEnabled = (
            !animating && canSubmit()
        )
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        siteURLField.isEnabled = !loading

        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    @objc func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            siteURLField.becomeFirstResponder()
        }
    }


    // MARK: - Instance Methods


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    @objc func validateForm() {
        view.endEditing(true)
        displayError(message: "")
        guard WordPressAuthenticator.validateSiteForSignin(loginFields) else {
            assertionFailure("Form should not be submitted unless there is a valid looking URL entered.")
            return
        }

        configureViewLoading(true)

        let facade = WordPressXMLRPCAPIFacade()
        facade.guessXMLRPCURL(forSite: loginFields.siteAddress, success: { [weak self] (url) in
            if let url = url {
                self?.loginFields.meta.xmlrpcURL = url as NSURL
            }
            self?.fetchSiteInfo()

        }, failure: { [weak self] (error) in
            guard let error = error, let strongSelf = self else {
                return
            }
            DDLogError(error.localizedDescription)
            WordPressAuthenticator.post(event: .loginFailedToGuessXMLRPC(error: error))
            WordPressAuthenticator.post(event: .loginFailed(error: error))
            strongSelf.configureViewLoading(false)

            let err = strongSelf.originalErrorOrError(error: error as NSError)
            if strongSelf.errorDiscoveringJetpackSite(error: err) {
                strongSelf.displayError(error as NSError, sourceTag: .jetpackLogin)

            } else if (err.domain == NSURLErrorDomain && err.code == NSURLErrorCannotFindHost) ||
                (err.domain == NSURLErrorDomain && err.code == NSURLErrorNetworkConnectionLost) {
                // NSURLErrorNetworkConnectionLost can be returned when an invalid URL is entered.
                let msg = NSLocalizedString("Hmm, it doesn't look like there's a WordPress site at this URL. Double-check the spelling and try again.",
                                            comment: "Error message shown a URL does not point to an existing site.")
                strongSelf.displayError(message: msg)

            } else if err.domain == "WordPressKit.WordPressOrgXMLRPCValidatorError" && err.code == WordPressOrgXMLRPCValidatorError.invalid.rawValue {
                let msg = NSLocalizedString("We're sure this is a great site - but it's not a WordPress site, so you can't connect to it with this app.",
                                            comment: "Error message shown a URL points to a valid site but not a WordPress site.")
                strongSelf.displayError(message: msg)

            } else {
                strongSelf.displayError(error as NSError, sourceTag: strongSelf.sourceTag)
            }
        })
    }


    @objc func fetchSiteInfo() {
        let baseSiteUrl = WordPressAuthenticator.baseSiteURL(string: loginFields.siteAddress) as NSString
        if let siteAddress = baseSiteUrl.components(separatedBy: "://").last {

            let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            service.fetchSiteInfo(forAddress: siteAddress, success: { [weak self] (siteInfo) in
                self?.loginFields.meta.siteInfo = siteInfo
                self?.showSelfHostedUsernamePassword()
            }, failure: { [weak self] (error) in
                self?.showSelfHostedUsernamePassword()
            })

        } else {
            showSelfHostedUsernamePassword()
        }
    }


    @objc func originalErrorOrError(error: NSError) -> NSError {
        guard let err = error.userInfo[XMLRPCOriginalErrorKey] as? NSError else {
            return error
        }
        return err
    }


    @objc func errorDiscoveringJetpackSite(error: NSError) -> Bool {
        if let _ = error.userInfo[WordPressOrgXMLRPCValidator.UserInfoHasJetpackKey] {
            return true
        }

        return false
    }


    @objc func showSelfHostedUsernamePassword() {
        configureViewLoading(false)
        performSegue(withIdentifier: .showURLUsernamePassword, sender: self)
    }


    /// Whether the form can be submitted.
    ///
    @objc func canSubmit() -> Bool {
        return WordPressAuthenticator.validateSiteForSignin(loginFields)
    }


    // MARK: - Actions

    @IBAction func handleSubmitForm() {
        if canSubmit() {
            validateForm()
        }
    }


    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }

    @IBAction func handleSiteAddressHelpButtonTapped(_ sender: UIButton) {
        let alert = FancyAlertViewController.siteAddressHelpController(loginFields: loginFields, sourceTag: sourceTag)
        alert.modalPresentationStyle = .custom
        alert.transitioningDelegate = self
        present(alert, animated: true, completion: nil)
        WPAnalytics.track(.loginURLHelpScreenViewed)
    }

    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.siteAddress = WordPressAuthenticator.baseSiteURL(string: siteURLField.nonNilTrimmedText())
        configureSubmitButton(animating: false)
    }


    // MARK: - Keyboard Notifications


    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}
