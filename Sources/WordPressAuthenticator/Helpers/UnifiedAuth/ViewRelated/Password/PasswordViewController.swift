import UIKit
import WordPressKit

/// PasswordViewController: view to enter WP account password.
///
class PasswordViewController: LoginViewController {

    // MARK: - Properties

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet private weak var secondaryButton: NUXButton!

    private weak var passwordField: UITextField?
    private var rows = [Row]()
    private var errorMessage: String?
    private var shouldChangeVoiceOverFocus: Bool = false
    private var loginLinkCell: TextLinkButtonTableViewCell?

    private let isMagicLinkShownAsSecondaryAction: Bool = WordPressAuthenticator.shared.configuration.isWPComMagicLinkShownAsSecondaryActionOnPasswordScreen

    private let configuration = WordPressAuthenticator.shared.configuration

    /// Depending on where we're coming from, this screen needs to track a password challenge
    /// (if logging on with a Social account) or not (if logging in through WP.com).
    ///
    var trackAsPasswordChallenge = true

    var source: SignInSource?

    override var loginFields: LoginFields {
        didSet {
            loginFields.password = ""
        }
    }

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginWPComPassword
        }
    }

    // Required for `NUXKeyboardResponder` but unused here.
    var verticalCenterConstraint: NSLayoutConstraint?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        removeGoogleWaitingView()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)

        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        configureLoginWithMagicLinkButton()
        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
        configureForAccessibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loginFields.meta.userIsDotCom = true
        configureSubmitButton(animating: false)
        loginLinkCell?.enableButton(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if trackAsPasswordChallenge {
            if isMovingToParent {
                tracker.track(step: .passwordChallenge)
            } else {
                tracker.set(step: .passwordChallenge)
            }
        } else {
            tracker.set(flow: isMagicLinkShownAsSecondaryAction ? .loginWithPasswordWithMagicLinkEmphasis : .loginWithPassword)

            if isMovingToParent {
                tracker.track(step: .start)
            } else {
                tracker.set(step: .start)
            }
        }

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        configureViewForEditingIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }

    // MARK: - Overrides

    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ??
            WordPressAuthenticator.shared.style.statusBarStyle
    }

    override func configureViewLoading(_ loading: Bool) {
        super.configureViewLoading(loading)
        passwordField?.isEnabled = !loading
    }

    override func displayRemoteError(_ error: Error) {
        configureViewLoading(false)

        if let source, loginFields.meta.userIsDotCom {
            let passwordError = SignInError.invalidWPComPassword(source: source)
            if authenticationDelegate.shouldHandleError(passwordError) {
                authenticationDelegate.handleError(passwordError) { _ in
                    // No custom navigation is expected in this case.
                }
            }
        }

        if let oauthError = error as? WordPressComOAuthError, case let .endpointError(failure) = oauthError, failure.kind == .invalidRequest {
            // The only difference between an incorrect password error and exceeded login limit error
            // is the actual error string. So check for "password" in the error string, and show the custom
            // error message. Otherwise, show the actual response error.
            var displayMessage: String {
                // swiftlint:disable localization_comment
                if let msg = failure.localizedErrorMessage, msg.contains(NSLocalizedString("password", comment: "")) {
                // swiftlint:enable localization_comment
                    return NSLocalizedString("It seems like you've entered an incorrect password. Want to give it another try?", comment: "An error message shown when a wpcom user provides the wrong password.")
                }
                if let msg = failure.localizedErrorMessage {
                    return msg
                }
                return oauthError.localizedDescription
            }
            displayError(message: displayMessage, moveVoiceOverFocus: true)
        } else {
            displayError(error, sourceTag: sourceTag)
        }
    }

    override func displayError(message: String, moveVoiceOverFocus: Bool = false) {
        // The reason why this check is necessary is that we're calling this method
        // with an empty error message when setting up the VC.  We don't want to track
        // an empty error when that happens.
        if !message.isEmpty {
            tracker.track(failure: message)
        }

        configureViewLoading(false)

        if errorMessage != message {
            errorMessage = message
            shouldChangeVoiceOverFocus = moveVoiceOverFocus
            loadRows()
            tableView.reloadData()
        }
    }

    override func validateFormAndLogin() {
        view.endEditing(true)
        displayError(message: "", moveVoiceOverFocus: true)

        // Is everything filled out?
        if !loginFields.validateFieldsPopulatedForSignin() {
            let errorMsg = Localization.missingInfoError
            displayError(message: errorMsg, moveVoiceOverFocus: true)

            return
        }

        configureViewLoading(true)

        loginFacade.signIn(with: loginFields)
    }
}

// MARK: - LoginFacadeDelegate

extension PasswordViewController {
    // Used when the account has support for security keys.
    //
    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        configureViewLoading(false)
        socialNeedsMultifactorCode(forUserID: userID, andNonceInfo: nonceInfo)
    }
}

// MARK: - Validation and Continue

private extension PasswordViewController {

    // MARK: - Button Actions

    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {
        tracker.track(click: .submit)

        configureViewLoading(true)
        validateForm()
    }

    func validateForm() {
        validateFormAndLogin()
    }
}

// MARK: - UITextFieldDelegate

extension PasswordViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if enableSubmit(animating: false) {
            validateForm()
        }
        return true
    }

}

// MARK: - UITableViewDataSource

extension PasswordViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }

}

// MARK: - Keyboard Notifications

extension PasswordViewController: NUXKeyboardResponder {

    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }

}

// MARK: - Magic Link

private extension PasswordViewController {
    func configureLoginWithMagicLinkButton() {
        if isMagicLinkShownAsSecondaryAction {
            secondaryButton.setTitle(Localization.loginWithMagicLink, for: .normal)
            secondaryButton.accessibilityIdentifier = AccessibilityIdentifier.loginWithMagicLink
            secondaryButton.on(.touchUpInside) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.secondaryButton.isEnabled = false
                    await self.loginWithMagicLink()
                    self.secondaryButton.isEnabled = true
                }
            }
        } else {
            secondaryButton.isHidden = true
        }
    }

    func loginWithMagicLink() async {
        tracker.track(click: .requestMagicLink)
        loginFields.meta.emailMagicLinkSource = .login

        updateLoadingUI(isRequestingMagicLink: true)
        let result = await MagicLinkRequester().requestMagicLink(email: loginFields.username, jetpackLogin: loginFields.meta.jetpackLogin)
        switch result {
        case .success:
            didRequestAuthenticationLink()
        case .failure(let error):
            switch error {
            case MagicLinkRequester.MagicLinkRequestError.invalidEmail:
                WPAuthenticatorLogError("Attempted to request authentication link, but the email address did not appear valid.")
                let alert = buildInvalidEmailAlert()
                present(alert, animated: true, completion: nil)
            default:
                tracker.track(failure: error.localizedDescription)
                displayError(error, sourceTag: sourceTag)
            }
        }
        updateLoadingUI(isRequestingMagicLink: false)
    }

    func updateLoadingUI(isRequestingMagicLink: Bool) {
        if isRequestingMagicLink {
            if isMagicLinkShownAsSecondaryAction {
                submitButton?.isEnabled = false
                secondaryButton.showActivityIndicator(true)
            } else {
                configureViewLoading(true)
            }
        } else {
            if isMagicLinkShownAsSecondaryAction {
                submitButton?.isEnabled = true
                secondaryButton.showActivityIndicator(false)
            } else {
                configureViewLoading(false)
            }
        }
    }
}

// MARK: - Table Management

private extension PasswordViewController {

    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            GravatarEmailTableViewCell.reuseIdentifier: GravatarEmailTableViewCell.loadNib(),
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
        rows = [.gravatarEmail]

        // Instructions only for social accounts and simplified WPCom login flow
        if loginFields.meta.socialService != nil ||
            configuration.wpcomPasswordInstructions != nil {
            rows.append(.instructions)
        }

        rows.append(.password)

        if let errorText = errorMessage, !errorText.isEmpty {
            rows.append(.errorMessage)
        }

        rows.append(.forgotPassword)

        if !isMagicLinkShownAsSecondaryAction {
            rows.append(.sendMagicLink)
        }
    }

    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as GravatarEmailTableViewCell:
            configureGravatarEmail(cell)
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextFieldTableViewCell where row == .password:
            configurePasswordTextField(cell)
        case let cell as TextLinkButtonTableViewCell where row == .forgotPassword:
            configureForgotPasswordButton(cell)
        case let cell as TextLinkButtonTableViewCell where row == .sendMagicLink:
            configureSendMagicLinkButton(cell)
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        default:
            WPAuthenticatorLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the gravatar + email cell.
    ///
    func configureGravatarEmail(_ cell: GravatarEmailTableViewCell) {
        cell.configure(withEmail: loginFields.username, hasBorders: configuration.emphasizeEmailForWPComPassword)

        cell.onChangeSelectionHandler = { [weak self] textfield in
            // The email can only be changed via a password manager.
            // In this case, don't update username for social accounts.
            // This prevents inadvertent account linking.
            if self?.loginFields.meta.socialService != nil {
                cell.updateEmailAddress(self?.loginFields.username)
            } else {
                self?.loginFields.username = textfield.nonNilTrimmedText()
                self?.loginFields.emailAddress = textfield.nonNilTrimmedText()
            }

            self?.configureSubmitButton(animating: false)
        }
    }

    /// Configure the instruction cell for social accounts or simplified login.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        let displayStrings = WordPressAuthenticator.shared.displayStrings
        let instructions: String? = {
            if let service = loginFields.meta.socialService {
                return (service == .google) ? displayStrings.googlePasswordInstructions :
                displayStrings.applePasswordInstructions
            }
            return configuration.wpcomPasswordInstructions
        }()

        guard let instructions else {
            return
        }

        cell.configureLabel(text: instructions)
    }

    /// Configure the password textfield cell.
    ///
    func configurePasswordTextField(_ cell: TextFieldTableViewCell) {
        cell.configure(withStyle: .password,
                       placeholder: WordPressAuthenticator.shared.displayStrings.passwordPlaceholder)

        // Save a reference to the first textField so it can becomeFirstResponder.
        passwordField = cell.textField
        cell.textField.delegate = self

        cell.onChangeSelectionHandler = { [weak self] textfield in
            self?.loginFields.password = textfield.nonNilTrimmedText()
            self?.configureSubmitButton(animating: false)
        }

        SigninEditingState.signinEditingStateActive = true

        if UIAccessibility.isVoiceOverRunning {
            // Quiet repetitive VoiceOver elements.
            passwordField?.placeholder = nil
        }
    }

    /// Configure the forgot password link cell.
    ///
    func configureForgotPasswordButton(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.resetPasswordButtonTitle,
                             accessibilityTrait: .link,
                             showBorder: true)
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

    /// Configure the "send magic link" cell.
    ///
    func configureSendMagicLinkButton(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.getLoginLinkButtonTitle,
                             accessibilityTrait: .link,
                             showBorder: true)
        cell.accessibilityIdentifier = AccessibilityIdentifier.loginWithMagicLink

        // Save reference to the login link cell so it can be enabled/disabled.
        loginLinkCell = cell

        cell.actionHandler = { [weak self] in
            guard let self else {
                return
            }

            cell.enableButton(false)

            Task { @MainActor [weak self] in
                await self?.loginWithMagicLink()
            }
        }
    }

    /// Configure the error message cell.
    ///
    func configureErrorLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: errorMessage, style: .error)
        cell.accessibilityIdentifier = "Password Error"
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
            passwordField?.becomeFirstResponder()
        }
    }

    /// Sets up accessibility elements in the order which they should be read aloud
    /// and chooses which element to focus on at the beginning.
    ///
    func configureForAccessibility() {
        view.accessibilityElements = [
            passwordField as Any,
            tableView as Any,
            submitButton as Any
        ]

        if isMagicLinkShownAsSecondaryAction {
            view.accessibilityElements?.append(secondaryButton as Any)
        }

        UIAccessibility.post(notification: .screenChanged, argument: passwordField)
    }

    /// When a magic link successfully sends, navigate the user to the next step.
    ///
    func didRequestAuthenticationLink() {
        guard let vc = LoginMagicLinkViewController.instantiate(from: .unifiedLoginMagicLink) else {
            WPAuthenticatorLogError("Failed to navigate to LoginMagicLinkViewController")
            return
        }

        vc.loginFields = self.loginFields
        vc.loginFields.restrictToWPCom = true
        navigationController?.pushViewController(vc, animated: true)
    }

    /// Build the alert message when the email address is invalid.
    ///
    func buildInvalidEmailAlert() -> UIAlertController {
        let title = NSLocalizedString("Can Not Request Link",
                                      comment: "Title of an alert letting the user know")
        let message = NSLocalizedString("A valid email address is needed to mail an authentication link. Please return to the previous screen and provide a valid email address.",
                                        comment: "An error message.")
        let helpActionTitle = NSLocalizedString("Need help?",
                                                comment: "Takes the user to get help")
        let okActionTitle = NSLocalizedString("OK",
                                              comment: "Dismisses the alert")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addActionWithTitle(helpActionTitle,
                                 style: .cancel,
                                 handler: { _ in
                                    WordPressAuthenticator.shared.delegate?.presentSupportRequest(from: self, sourceTag: .loginEmail)
        })

        alert.addActionWithTitle(okActionTitle, style: .default, handler: nil)

        return alert
    }

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case gravatarEmail
        case instructions
        case password
        case forgotPassword
        case sendMagicLink
        case errorMessage

        var reuseIdentifier: String {
            switch self {
            case .gravatarEmail:
                return GravatarEmailTableViewCell.reuseIdentifier
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .password:
                return TextFieldTableViewCell.reuseIdentifier
            case .sendMagicLink:
                return TextLinkButtonTableViewCell.reuseIdentifier
            case .forgotPassword:
                return TextLinkButtonTableViewCell.reuseIdentifier
            case .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }
}

private extension PasswordViewController {
    /// Localization constants
    ///
    enum Localization {
        static let missingInfoError = NSLocalizedString("Please fill out all the fields",
                                                        comment: "A short prompt asking the user to properly fill out all login fields.")
        static let loginWithMagicLink = NSLocalizedString("Or log in with magic link",
                                                          comment: "The button title for a secondary call-to-action button on the password screen. When the user wants to try sending a magic link instead of entering a password.")
    }

    enum AccessibilityIdentifier {
        static let loginWithMagicLink = "Get Login Link Button"
    }
}
