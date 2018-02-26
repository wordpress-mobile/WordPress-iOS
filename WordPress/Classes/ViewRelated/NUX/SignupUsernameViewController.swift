import SVProgressHUD

class SignupUsernameViewController: NUXViewController {
    // MARK: - Properties
    open var currentUsername: String?
    private var newUsername: String?
    open var displayName: String?

    // Used to hide/show the Buttom View
    @IBOutlet weak var buttonContainerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerHeightConstraint: NSLayoutConstraint!

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComCreateSiteUsername
        }
    }

    private var usernamesTableViewController: SignupUsernameTableViewController?
    private var buttonViewController: NUXButtonViewController?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addConfirmationWarning()
    }

    private func configureView() {
        _ = addHelpButtonToNavController()
        navigationItem.title = NSLocalizedString("Create New Site", comment: "Create New Site title.")
        WPStyleGuide.configureColors(for: view, andTableView: nil)
    }

    private func addConfirmationWarning() {
        let warningLabel = UILabel()
        warningLabel.text = NSLocalizedString("Once changed, your old username will no longer be avilable for use.", comment: "Warning shown before user changes their username.")
        warningLabel.numberOfLines = 0
        warningLabel.textAlignment = .center
        warningLabel.textColor = WPStyleGuide.darkGrey()
        buttonViewController?.stackView?.insertArrangedSubview(warningLabel, at: 0)
    }

    private func showButtonView(show: Bool, withAnimation: Bool) {

        let duration = withAnimation ? WPAnimationDurationDefault : 0

        UIView.animate(withDuration: duration, animations: {
            if show {
                self.buttonContainerViewBottomConstraint.constant = 0
            }
            else {
                // Move the view down double the height to ensure it's off the screen.
                // i.e. to defy iPhone X bottom gap.
                self.buttonContainerViewBottomConstraint.constant +=
                    self.buttonContainerHeightConstraint.constant * 2
            }

            // Since the Button View uses auto layout, need to call this so the animation works properly.
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    private func changeUsername() {
        guard let newUsername = newUsername, newUsername != "" else {
            navigationController?.popViewController(animated: true)
            return
        }

        SVProgressHUD.show(withStatus: NSLocalizedString("Changing username", comment: "Shown while the app waits for the username changing web service to return."))

        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        guard let account = accountService.defaultWordPressComAccount(),
            let api = account.wordPressComRestApi else {
                navigationController?.popViewController(animated: true)
                return
        }

        let settingsService = AccountSettingsService(userID: account.userID.intValue, api: api)
        settingsService.changeUsername(to: newUsername, success: { [weak self] in
            // now we refresh the account to get the new username
            accountService.updateUserDetails(for: account, success: { [weak self] in
                SVProgressHUD.dismiss()
                self?.navigationController?.popViewController(animated: true)
            }, failure: { [weak self] (error) in
                SVProgressHUD.dismiss()
                self?.navigationController?.popViewController(animated: true)
            })
        }) { [weak self] in
            SVProgressHUD.showDismissibleError(withStatus: NSLocalizedString("Username change failed", comment: "Shown when an attempt to change the username fails."))
            self?.navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? SignupUsernameTableViewController {
            usernamesTableViewController = vc
            vc.delegate = self
            vc.displayName = displayName
            vc.currentUsername = currentUsername
        }

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
            vc.setupButtomButton(title: NSLocalizedString("Change Username", comment: "Button text for changing the user's username."), isPrimary: true) { [weak self] in
                self?.changeUsername()
            }
            showButtonView(show: false, withAnimation: false)
        }
    }
}

// MARK: - SignupUsernameTableViewControllerDelegate

extension SignupUsernameViewController: SignupUsernameTableViewControllerDelegate {
    func usernameSelected(_ username: String) {
        newUsername = username
        if username == "" {
            showButtonView(show: false, withAnimation: true)
        } else {
            showButtonView(show: true, withAnimation: true)
        }
    }

    func newSearchStarted() {
        showButtonView(show: false, withAnimation: true)
    }
}
