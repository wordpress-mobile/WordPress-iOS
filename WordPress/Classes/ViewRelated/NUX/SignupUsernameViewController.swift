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

    override var sourceTag: WordPressSupportSourceTag {
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
