import UIKit

final class VerifyEmailViewController: LoginViewController {

    // MARK: - Properties

    @IBOutlet private weak var tableView: UITableView!
    private var buttonViewController: NUXButtonViewController?
    private let rows = Row.allCases

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)

        // Store default margin, and size table for the view.
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        registerTableViewCells()
        configureButtonViewController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isBeingPresentedInAnyWay {
            tracker.track(step: .verifyEmailInstructions)
        } else {
            tracker.set(step: .verifyEmailInstructions)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
        }
    }

    // MARK: - Overrides

    override var sourceTag: WordPressSupportSourceTag {
        .verifyEmailInstructions
    }

    /// Style individual ViewController backgrounds, for now.
    ///
    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            return super.styleBackground()
        }

        view.backgroundColor = unifiedBackgroundColor
    }

    /// Style individual ViewController status bars.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }

    /// Customise loading state of view.
    ///
    override func configureViewLoading(_ loading: Bool) {
        buttonViewController?.setTopButtonState(isLoading: loading,
                                                isEnabled: !loading)
        buttonViewController?.setBottomButtonState(isLoading: false,
                                                   isEnabled: !loading)
        navigationItem.hidesBackButton = loading
    }
}

// MARK: - UITableViewDataSource
extension VerifyEmailViewController: UITableViewDataSource {
    /// Returns the number of rows in a section.
    ///
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
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

// MARK: - Private Methods
private extension VerifyEmailViewController {
    /// Configure bottom buttons.
    ///
    func configureButtonViewController() {
        guard let buttonViewController else {
            return
        }

        buttonViewController.hideShadowView()

        // Setup `Send email verification link` button
        buttonViewController.setupTopButton(title: ButtonConfiguration.SendEmailVerificationLink.title,
                                            isPrimary: true) { [weak self] in
            self?.handleSendEmailVerificationLinkButtonTapped()
        }

        // Setup `Login with account password` button
        buttonViewController.setupBottomButton(title: ButtonConfiguration.LoginWithAccountPassword.title,
                                            isPrimary: false) { [weak self] in
            self?.handleLoginWithAccountPasswordButtonTapped()
        }
    }

    // MARK: - Actions
    @objc func handleSendEmailVerificationLinkButtonTapped() {
        tracker.track(click: .requestMagicLink)
        requestAuthenticationLink()
    }

    @objc func handleLoginWithAccountPasswordButtonTapped() {
        tracker.track(click: .loginWithAccountPassword)
        presentUnifiedPassword()
    }

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

    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as GravatarEmailTableViewCell where row == .persona:
            configureGravatarEmail(cell)
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextLabelTableViewCell where row == .typePassword:
            configureTypePasswordButton(cell)
        default:
            WPAuthenticatorLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the gravatar + email cell.
    ///
    func configureGravatarEmail(_ cell: GravatarEmailTableViewCell) {
        cell.configure(withEmail: loginFields.username)
    }

    /// Configure the instructions cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.verifyMailLoginInstructions,
                            style: .body)
    }

    /// Configure the enter password instructions cell.
    ///
    func configureTypePasswordButton(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.alternativelyEnterPasswordInstructions,
                            style: .body)
    }

    /// Makes the call to request a magic authentication link be emailed to the user.
    ///
    func requestAuthenticationLink() {
        loginFields.meta.emailMagicLinkSource = .login

        let email = loginFields.username

        configureViewLoading(true)
        let service = WordPressComAccountService()
        service.requestAuthenticationLink(for: email,
                                          jetpackLogin: loginFields.meta.jetpackLogin,
                                          success: { [weak self] in
                                            self?.didRequestAuthenticationLink()
                                            self?.configureViewLoading(false)

            }, failure: { [weak self] (error: Error) in
                guard let self else { return }

                self.tracker.track(failure: error.localizedDescription)

                self.displayError(error, sourceTag: self.sourceTag)
                self.configureViewLoading(false)
        })
    }

    /// When a magic link successfully sends, navigate the user to the next step.
    ///
    func didRequestAuthenticationLink() {
        guard let vc = LoginMagicLinkViewController.instantiate(from: .unifiedLoginMagicLink) else {
            WPAuthenticatorLogError("Failed to navigate to LoginMagicLinkViewController from VerifyEmailViewController")
            return
        }

        vc.loginFields = loginFields
        vc.loginFields.restrictToWPCom = true
        navigationController?.pushViewController(vc, animated: true)
    }

    /// Presents unified password screen
    ///
    func presentUnifiedPassword() {
        guard let vc = PasswordViewController.instantiate(from: .password) else {
            WPAuthenticatorLogError("Failed to navigate to PasswordViewController from VerifyEmailViewController")
            return
        }
        vc.loginFields = loginFields
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Private Constants

    /// Rows listed in the order they were created.
    ///
    enum Row: CaseIterable {
        case persona
        case instructions
        case typePassword

        var reuseIdentifier: String {
            switch self {
            case .persona:
                return GravatarEmailTableViewCell.reuseIdentifier
            case .instructions, .typePassword:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }
}

// MARK: - Button configuration
private extension VerifyEmailViewController {
    enum ButtonConfiguration {
        enum SendEmailVerificationLink {
            static let title = WordPressAuthenticator.shared.displayStrings.sendEmailVerificationLinkButtonTitle
        }

        enum LoginWithAccountPassword {
            static let title = WordPressAuthenticator.shared.displayStrings.loginWithAccountPasswordButtonTitle
        }
    }
}
