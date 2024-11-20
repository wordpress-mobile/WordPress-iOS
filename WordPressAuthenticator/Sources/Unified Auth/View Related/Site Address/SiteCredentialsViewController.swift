import UIKit

/// Part two of the self-hosted sign in flow: username + password. Used by WPiOS and NiOS.
/// A valid site address should be acquired before presenting this view controller.
///
final class SiteCredentialsViewController: LoginViewController {

    /// Private properties.
    ///
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?

    private weak var usernameField: UITextField?
    private weak var passwordField: UITextField?
    private var rows = [Row]()
    private var errorMessage: String?
    private var shouldChangeVoiceOverFocus: Bool = false

    private let isDismissible: Bool
    private let completionHandler: ((WordPressOrgCredentials) -> Void)?
    private let configuration = WordPressAuthenticator.shared.configuration

    init?(coder: NSCoder, isDismissible: Bool, onCompletion: @escaping (WordPressOrgCredentials) -> Void) {
        self.isDismissible = isDismissible
        self.completionHandler = onCompletion
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        self.isDismissible = false
        self.completionHandler = nil
        super.init(coder: coder)
    }

    // Required for `NUXKeyboardResponder` but unused here.
    var verticalCenterConstraint: NSLayoutConstraint?

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginUsernamePassword
        }
    }

    override var loginFields: LoginFields {
        didSet {
            // Clear the password (if any) from LoginFields
            loginFields.password = ""
        }
    }

    // MARK: - Actions
    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {
        tracker.track(click: .submit)

        validateForm()
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        loginFields.meta.userIsDotCom = false

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        if isDismissible {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissView))
        }
        styleNavigationBar(forUnified: true)

        // Store default margin, and size table for the view.
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
        configureForAccessibility()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isMovingToParent {
            tracker.track(step: .usernamePassword)
        } else {
            tracker.set(step: .usernamePassword)
        }

        configureSubmitButton(animating: false)
        configureViewLoading(false)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
        configureViewForEditingIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }

    // MARK: - Overrides

    /// Style individual ViewController backgrounds, for now.
    ///
    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }

    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)

        submitButton?.isEnabled = (
            !animating &&
                !loginFields.username.isEmpty &&
                !loginFields.password.isEmpty
        )
    }

    /// Sets up accessibility elements in the order which they should be read aloud
    /// and chooses which element to focus on at the beginning.
    ///
    private func configureForAccessibility() {
        view.accessibilityElements = [
            usernameField as Any,
            tableView as Any,
            submitButton as Any
        ]

        UIAccessibility.post(notification: .screenChanged, argument: usernameField)
    }

    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        usernameField?.isEnabled = !loading
        passwordField?.isEnabled = !loading

        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

    /// Set error messages and reload the table to display them.
    ///
    override func displayError(message: String, moveVoiceOverFocus: Bool = false) {
        if errorMessage != message {
            if !message.isEmpty {
                tracker.track(failure: message)
            }

            errorMessage = message
            shouldChangeVoiceOverFocus = moveVoiceOverFocus
            loadRows()
            tableView.reloadData()
        }
    }

    /// No-op. Required by LoginFacade.
    func displayLoginMessage(_ message: String) {}
}

// MARK: - UITableViewDataSource
extension SiteCredentialsViewController: UITableViewDataSource {
    /// Returns the number of rows in a section.
    ///
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    /// Configure cells delegate method.
    ///
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate conformance
extension SiteCredentialsViewController: UITableViewDelegate {
    /// After a textfield cell is done displaying, remove the textfield reference.
    ///
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let row = rows[safe: indexPath.row] else {
            return
        }

        if row == .username {
            usernameField = nil
        } else if row == .password {
            passwordField = nil
        }
    }
}

// MARK: - Keyboard Notifications
extension SiteCredentialsViewController: NUXKeyboardResponder {
    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}

// MARK: - TextField Delegate conformance
extension SiteCredentialsViewController: UITextFieldDelegate {

    /// Handle the keyboard `return` button action.
    ///
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            if UIAccessibility.isVoiceOverRunning {
                passwordField?.placeholder = nil
            }
            passwordField?.becomeFirstResponder()
        } else if textField == passwordField {
            validateForm()
        }
        return true
    }
}

// MARK: - Private Methods
private extension SiteCredentialsViewController {

    @objc func dismissView() {
        dismissBlock?(true)
    }
    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            TextLabelTableViewCell.reuseIdentifier: TextLabelTableViewCell.loadNib(),
            TextFieldTableViewCell.reuseIdentifier: TextFieldTableViewCell.loadNib(),
            TextLinkButtonTableViewCell.reuseIdentifier: TextLinkButtonTableViewCell.loadNib()
        ]

        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    /// Describes how the tableView rows should be rendered.
    ///
    func loadRows() {
        rows = [.instructions, .username, .password]

        if let errorText = errorMessage, !errorText.isEmpty {
            rows.append(.errorMessage)
        }

        if configuration.displayHintButtons {
            rows.append(.forgotPassword)
        }
    }

    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextFieldTableViewCell where row == .username:
            configureUsernameTextField(cell)
        case let cell as TextFieldTableViewCell where row == .password:
            configurePasswordTextField(cell)
        case let cell as TextLinkButtonTableViewCell:
            configureForgotPassword(cell)
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        default:
            WPAuthenticatorLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        let displayURL = sanitizedSiteAddress(siteAddress: loginFields.siteAddress)
        let text = String.localizedStringWithFormat(WordPressAuthenticator.shared.displayStrings.siteCredentialInstructions, displayURL)
        cell.configureLabel(text: text, style: .body)
    }

    /// Configure the username textfield cell.
    ///
    func configureUsernameTextField(_ cell: TextFieldTableViewCell) {
        cell.configure(withStyle: .username,
                       placeholder: WordPressAuthenticator.shared.displayStrings.usernamePlaceholder,
                       text: loginFields.username)

        // Save a reference to the textField so it can becomeFirstResponder.
        usernameField = cell.textField
        cell.textField.delegate = self

        cell.onChangeSelectionHandler = { [weak self] textfield in
            self?.loginFields.username = textfield.nonNilTrimmedText()
            self?.configureSubmitButton(animating: false)
        }

        SigninEditingState.signinEditingStateActive = true
        if UIAccessibility.isVoiceOverRunning {
            // Quiet repetitive elements in VoiceOver.
            usernameField?.placeholder = nil
        }
    }

    /// Configure the password textfield cell.
    ///
    func configurePasswordTextField(_ cell: TextFieldTableViewCell) {
        cell.configure(withStyle: .password,
                       placeholder: WordPressAuthenticator.shared.displayStrings.passwordPlaceholder,
                       text: loginFields.password)
        passwordField = cell.textField
        cell.textField.delegate = self
        cell.onChangeSelectionHandler = { [weak self] textfield in
            self?.loginFields.password = textfield.nonNilTrimmedText()
            self?.configureSubmitButton(animating: false)
        }

        if UIAccessibility.isVoiceOverRunning {
            // Quiet repetitive elements in VoiceOver.
            passwordField?.placeholder = nil
        }
    }

    /// Configure the forgot password cell.
    ///
    func configureForgotPassword(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.resetPasswordButtonTitle, accessibilityTrait: .link)
        cell.actionHandler = { [weak self] in
            guard let self else {
                return
            }

            self.tracker.track(click: .forgottenPassword)

            // If information is currently processing, ignore button tap.
            guard self.enableSubmit(animating: false) else {
                return
            }

            WordPressAuthenticator.openForgotPasswordURL(self.loginFields)
        }
    }

    /// Configure the error message cell.
    ///
    func configureErrorLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: errorMessage, style: .error)
        if shouldChangeVoiceOverFocus {
            UIAccessibility.post(notification: .layoutChanged, argument: cell)
        }
    }

    /// Configure the view for an editing state.
    ///
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            usernameField?.becomeFirstResponder()
        }
    }

    /// Presents verify email instructions screen
    ///
    /// - Parameters:
    ///   - loginFields: `LoginFields` instance created using `makeLoginFieldsUsing` helper method
    ///
    func presentVerifyEmail(loginFields: LoginFields) {
        guard let vc = VerifyEmailViewController.instantiate(from: .verifyEmail) else {
            WPAuthenticatorLogError("Failed to navigate from SiteCredentialsViewController to VerifyEmailViewController")
            return
        }

        vc.loginFields = loginFields
        navigationController?.pushViewController(vc, animated: true)
    }

    /// Used for creating `LoginFields`
    ///
    /// - Parameters:
    ///   - xmlrpc: XML-RPC URL as a String
    ///   - options: Dictionary received from .org site credential authentication response. (Containing `jetpack_user_email` and `home_url` values)
    ///
    /// - Returns: A valid `LoginFields` instance or `nil`
    ///
    func makeLoginFieldsUsing(xmlrpc: String, options: [AnyHashable: Any]) -> LoginFields? {
        guard let xmlrpcURL = URL(string: xmlrpc) else {
            WPAuthenticatorLogError("Failed to initiate XML-RPC URL from \(xmlrpc)")
            return nil
        }

        // `jetpack_user_email` to be used for WPCOM login
        guard let email = options["jetpack_user_email"] as? [String: Any],
              let userName = email["value"] as? String else {
            WPAuthenticatorLogError("Failed to find jetpack_user_email value.")
            return nil
        }

        // Site address
        guard let home_url = options["home_url"] as? [String: Any],
              let siteAddress = home_url["value"] as? String else {
            WPAuthenticatorLogError("Failed to find home_url value.")
            return nil
        }

        let loginFields = LoginFields()
        loginFields.meta.xmlrpcURL = xmlrpcURL as NSURL
        loginFields.username = userName
        loginFields.siteAddress = siteAddress
        return loginFields
    }

    func validateFormAndTriggerDelegate() {
        view.endEditing(true)
        displayError(message: "")

        // Is everything filled out?
        if !loginFields.validateFieldsPopulatedForSignin() {
            let errorMsg = NSLocalizedString("Please fill out all the fields",
                                             comment: "A short prompt asking the user to properly fill out all login fields.")
            displayError(message: errorMsg)

            return
        }

        configureViewLoading(true)

        guard let delegate = WordPressAuthenticator.shared.delegate else {
            fatalError("Error: Where did the delegate go?")
        }
        // manually construct the XMLRPC since this is needed to get the site address later
        let xmlrpc = loginFields.siteAddress + "/xmlrpc.php"
        let wporg = WordPressOrgCredentials(username: loginFields.username,
                                            password: loginFields.password,
                                            xmlrpc: xmlrpc,
                                            options: [:])
        delegate.handleSiteCredentialLogin(credentials: wporg, onLoading: { [weak self] shouldShowLoading in
            self?.configureViewLoading(shouldShowLoading)
        }, onSuccess: { [weak self] in
            self?.finishedLogin(withUsername: wporg.username,
                                password: wporg.password,
                                xmlrpc: wporg.xmlrpc,
                                options: wporg.options)
        }, onFailure: { [weak self] error, incorrectCredentials in
            self?.handleLoginFailure(error: error, incorrectCredentials: incorrectCredentials)
        })
    }

    func handleLoginFailure(error: Error, incorrectCredentials: Bool) {
        configureViewLoading(false)
        guard configuration.enableManualErrorHandlingForSiteCredentialLogin == false else {
            WordPressAuthenticator.shared.delegate?.handleSiteCredentialLoginFailure(error: error, for: loginFields.siteAddress, in: self)
            return
        }
        if incorrectCredentials {
            let message = NSLocalizedString("It looks like this username/password isn't associated with this site.",
                                            comment: "An error message shown during log in when the username or password is incorrect.")
            displayError(message: message, moveVoiceOverFocus: true)
        } else {
            displayError(error, sourceTag: sourceTag)
        }
    }

    func syncDataOrPresentWPComLogin(with wporgCredentials: WordPressOrgCredentials) {
        if configuration.isWPComLoginRequiredForSiteCredentialsLogin {
            presentWPComLogin(wporgCredentials: wporgCredentials)
            return
        }
        // Client didn't explicitly ask for WPCOM credentials. (`isWPComLoginRequiredForSiteCredentialsLogin` is false)
        // So, sync the available credentials and finish sign in.
        //
        let credentials = AuthenticatorCredentials(wporg: wporgCredentials)
        WordPressAuthenticator.shared.delegate?.sync(credentials: credentials) { [weak self] in
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)
            self?.showLoginEpilogue(for: credentials)
        }
    }

    func presentWPComLogin(wporgCredentials: WordPressOrgCredentials) {
        // Try to get the jetpack email from XML-RPC response dictionary.
        //
        guard let loginFields = makeLoginFieldsUsing(xmlrpc: wporgCredentials.xmlrpc,
                                                     options: wporgCredentials.options) else {
            WPAuthenticatorLogError("Unexpected response from .org site credentials sign in using XMLRPC.")
            let credentials = AuthenticatorCredentials(wporg: wporgCredentials)
            showLoginEpilogue(for: credentials)
            return
        }

        // Present verify email instructions screen. Passing loginFields will prefill the jetpack email in `VerifyEmailViewController`
        //
        presentVerifyEmail(loginFields: loginFields)
    }

    // MARK: - Private Constants

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions
        case username
        case password
        case forgotPassword
        case errorMessage

        var reuseIdentifier: String {
            switch self {
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .username:
                return TextFieldTableViewCell.reuseIdentifier
            case .password:
                return TextFieldTableViewCell.reuseIdentifier
            case .forgotPassword:
                return TextLinkButtonTableViewCell.reuseIdentifier
            case .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }
}

// MARK: - Instance Methods
/// Implementation methods copied from LoginSelfHostedViewController.
///
extension SiteCredentialsViewController {
    /// Sanitize and format the site address we show to users.
    ///
    @objc func sanitizedSiteAddress(siteAddress: String) -> String {
        let baseSiteUrl = WordPressAuthenticator.baseSiteURL(string: siteAddress) as NSString
        if let str = baseSiteUrl.components(separatedBy: "://").last {
            return str
        }
        return siteAddress
    }

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    @objc func validateForm() {
        guard configuration.enableManualSiteCredentialLogin else {
            return validateFormAndLogin() // handles login with XMLRPC normally
        }

        // asks the delegate to handle the login
        validateFormAndTriggerDelegate()
    }

    func finishedLogin(withUsername username: String, password: String, xmlrpc: String, options: [AnyHashable: Any]) {
        let wporg = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)
        /// If `completionHandler` is available, return early with the credentials.
        if let completionHandler {
            completionHandler(wporg)
        } else {
            syncDataOrPresentWPComLogin(with: wporg)
        }
    }

    override func displayRemoteError(_ error: Error) {
        configureViewLoading(false)
        let err = error as NSError
        if err.code == 403 {
            let message = NSLocalizedString("It looks like this username/password isn't associated with this site.",
                                            comment: "An error message shown during log in when the username or password is incorrect.")
            displayError(message: message, moveVoiceOverFocus: true)
        } else {
            displayError(error, sourceTag: sourceTag)
        }
    }
}
