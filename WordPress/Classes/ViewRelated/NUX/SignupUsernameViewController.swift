import SVProgressHUD

protocol SignupUsernameViewControllerDelegate {
    func usernameSelected(_ username: String)
}
class SignupUsernameViewController: NUXViewController {
    // MARK: - Properties
    open var currentUsername: String?
    private var newUsername: String?
    open var displayName: String?
    open var delegate: SignupUsernameViewControllerDelegate?

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComCreateSiteUsername
        }
    }

    private var usernamesTableViewController: SignupUsernameTableViewController?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func configureView() {
        _ = addHelpButtonToNavController()
        navigationItem.title = NSLocalizedString("Change Username", comment: "Change Username title.")
        WPStyleGuide.configureColors(for: view, andTableView: nil)
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
    }
}

// MARK: - SignupUsernameTableViewControllerDelegate

extension SignupUsernameViewController: SignupUsernameViewControllerDelegate {
    func usernameSelected(_ username: String) {
        newUsername = username

        delegate?.usernameSelected(username)
    }
}
