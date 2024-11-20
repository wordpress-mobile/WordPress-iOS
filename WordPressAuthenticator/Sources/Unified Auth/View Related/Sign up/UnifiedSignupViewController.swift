import UIKit

/// UnifiedSignupViewController: sign up to .com with an email address.
///
class UnifiedSignupViewController: LoginViewController {

    /// Private properties.
    ///
    @IBOutlet private weak var tableView: UITableView!

    private var rows = [Row]()
    private var errorMessage: String?
    private var shouldChangeVoiceOverFocus: Bool = false

    // MARK: - Actions
    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {
        tracker.track(click: .requestMagicLink)
        requestAuthenticationLink()
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.signUpTitle
        styleNavigationBar(forUnified: true)

        // Store default margin, and size table for the view.
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tracker.set(flow: .signup)

        if isMovingToParent {
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
        submitButton?.setTitle(WordPressAuthenticator.shared.displayStrings.magicLinkButtonTitle, for: .normal)
    }

    /// Reload the tableview and show errors, if any.
    ///
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
extension UnifiedSignupViewController: UITableViewDataSource {

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
extension UnifiedSignupViewController: UITableViewDelegate { }

// MARK: - Private methods
private extension UnifiedSignupViewController {

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
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.magicLinkSignupInstructions, style: .body)
    }

    /// Configure the error message cell.
    ///
    func configureErrorLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: errorMessage, style: .error)
        if shouldChangeVoiceOverFocus {
            UIAccessibility.post(notification: .layoutChanged, argument: cell)
        }
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
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }

    enum ErrorMessage: String {
        case availabilityCheckFail = "availability_check_fail"
        case magicLinkRequestFail = "magic_link_request_fail"

        func description() -> String {
            switch self {
            case .availabilityCheckFail:
                return NSLocalizedString("Unable to verify the email address. Please try again later.", comment: "Error message displayed when an error occurred checking for email availability.")
            case .magicLinkRequestFail:
                return NSLocalizedString("We were unable to send you an email at this time. Please try again later.", comment: "Error message displayed when an error occurred sending the magic link email.")
            }
        }
    }

}

// MARK: - Instance Methods
/// Implementation methods imported from SignupEmailViewController.
///
extension UnifiedSignupViewController {
    // MARK: - Send email

    /// Makes the call to request a magic signup link be emailed to the user.
    ///
    func requestAuthenticationLink() {
        loginFields.meta.emailMagicLinkSource = .signup

        configureSubmitButton(animating: true)

        let service = WordPressComAccountService()
        service.requestSignupLink(for: loginFields.username,
                                  success: { [weak self] in
                                    self?.didRequestSignupLink()
                                    self?.configureSubmitButton(animating: false)

            }, failure: { [weak self] (error: Error) in
                WPAuthenticatorLogError("Request for signup link email failed.")

                guard let self else {
                    return
                }

                self.tracker.track(failure: error.localizedDescription)
                self.displayError(message: ErrorMessage.magicLinkRequestFail.description())
                self.configureSubmitButton(animating: false)
        })
    }

    func didRequestSignupLink() {
        guard let vc = SignupMagicLinkViewController.instantiate(from: .unifiedSignup) else {
            WPAuthenticatorLogError("Failed to navigate from UnifiedSignupViewController to SignupMagicLinkViewController")
            return
        }

        vc.loginFields = loginFields
        vc.loginFields.restrictToWPCom = true

        navigationController?.pushViewController(vc, animated: true)
    }
}
