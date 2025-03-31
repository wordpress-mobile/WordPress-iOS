import UIKit

class GoogleSignupConfirmationViewController: LoginViewController {

    // MARK: - Properties

    @IBOutlet private weak var tableView: UITableView!
    private var rows = [Row]()
    private var errorMessage: String?
    private var shouldChangeVoiceOverFocus: Bool = false

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComAuthGoogleSignupConfirmation
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        removeGoogleWaitingView()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.signUpTitle
        styleNavigationBar(forUnified: true)

        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
        configureForAccessibility()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tracker.set(flow: .signupWithGoogle)

        if isBeingPresentedInAnyWay {
            tracker.track(step: .start)
        } else {
            tracker.set(step: .start)
        }
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

    /// Style individual ViewController status bars.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }

    /// Override the title on 'submit' button
    ///
    override func localizePrimaryButton() {
        submitButton?.setTitle(WordPressAuthenticator.shared.displayStrings.createAccountButtonTitle, for: .normal)
    }

    override func displayError(message: String, moveVoiceOverFocus: Bool = false) {
        if errorMessage != message {
            errorMessage = message
            shouldChangeVoiceOverFocus = moveVoiceOverFocus
            loadRows()
            tableView.reloadData()
        }
    }

}

// MARK: - UITableViewDataSource

extension GoogleSignupConfirmationViewController: UITableViewDataSource {

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

// MARK: - Private Extension

private extension GoogleSignupConfirmationViewController {

    // MARK: - Button Handling

    @IBAction func handleSubmit() {
        tracker.track(click: .submit)
        tracker.track(click: .createAccount)

        configureSubmitButton(animating: true)
        GoogleAuthenticator.sharedInstance.delegate = self
        GoogleAuthenticator.sharedInstance.createGoogleAccount(loginFields: loginFields)
    }

    // MARK: - Table Management

    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            GravatarEmailTableViewCell.reuseIdentifier: GravatarEmailTableViewCell.loadNib(),
            TextLabelTableViewCell.reuseIdentifier: TextLabelTableViewCell.loadNib()
        ]

        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    /// Describes how the tableView rows should be rendered.
    ///
    func loadRows() {
        rows = [.gravatarEmail, .instructions]

        if let errorText = errorMessage, !errorText.isEmpty {
            rows.append(.errorMessage)
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
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        default:
            WPAuthenticatorLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the gravatar + email cell.
    ///
    func configureGravatarEmail(_ cell: GravatarEmailTableViewCell) {
        cell.configure(withEmail: loginFields.username)
    }

    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.googleSignupInstructions, style: .body)
    }

    /// Configure the error message cell.
    ///
    func configureErrorLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: errorMessage, style: .error)
        if shouldChangeVoiceOverFocus {
            UIAccessibility.post(notification: .layoutChanged, argument: cell)
        }
    }

    /// Sets up accessibility elements in the order which they should be read aloud
    /// and chooses which element to focus on at the beginning.
    ///
    func configureForAccessibility() {
        view.accessibilityElements = [
            tableView as Any,
            submitButton as Any
        ]

        UIAccessibility.post(notification: .screenChanged, argument: tableView)
    }

    // MARK: - Private Constants

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case gravatarEmail
        case instructions
        case errorMessage

        var reuseIdentifier: String {
            switch self {
            case .gravatarEmail:
                return GravatarEmailTableViewCell.reuseIdentifier
            case .instructions, .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }

}

// MARK: - GoogleAuthenticatorDelegate

extension GoogleSignupConfirmationViewController: GoogleAuthenticatorDelegate {

    // MARK: - Signup

    func googleFinishedSignup(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        self.loginFields = loginFields
        showSignupEpilogue(for: credentials)
    }

    func googleLoggedInInstead(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        self.loginFields = loginFields
        showLoginEpilogue(for: credentials)
    }

    func googleSignupFailed(error: Error, loginFields: LoginFields) {
        configureSubmitButton(animating: false)
        self.loginFields = loginFields
        displayError(message: error.localizedDescription, moveVoiceOverFocus: true)
    }

    // MARK: - Login

    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        // Here for protocol compliance.
    }

    func googleNeedsMultifactorCode(loginFields: LoginFields) {
        // Here for protocol compliance.
    }

    func googleExistingUserNeedsConnection(loginFields: LoginFields) {
        // Here for protocol compliance.
    }

    func googleLoginFailed(errorTitle: String, errorDescription: String, loginFields: LoginFields, unknownUser: Bool) {
        // Here for protocol compliance.
    }

    func googleAuthCancelled() {
        // Here for protocol compliance.
    }

}
