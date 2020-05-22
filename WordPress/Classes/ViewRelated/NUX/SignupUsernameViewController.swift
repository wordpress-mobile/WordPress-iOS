import SVProgressHUD
import WordPressAuthenticator


protocol SignupUsernameViewControllerDelegate {
    func usernameSelected(_ username: String)
}

class SignupUsernameViewController: UIViewController {

    // MARK: - Properties

    open var currentUsername: String?
    open var displayName: String?
    open var delegate: SignupUsernameViewControllerDelegate?
    private var usernamesTableViewController: SignupUsernameTableViewController?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        navigationController?.setNavigationBarHidden(false, animated: false)
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

// MARK: - Private Extension

private extension SignupUsernameViewController {

    func configureView() {
        navigationItem.title = NSLocalizedString("Change Username", comment: "Change Username title.")
        WPStyleGuide.configureColors(view: view, tableView: nil)

        let supportButton = UIBarButtonItem(title: NSLocalizedString("Help", comment: "Help button"),
                                            style: .plain,
                                            target: self,
                                            action: #selector(handleSupportButtonTapped))
        navigationItem.rightBarButtonItem = supportButton
    }

    @objc func handleSupportButtonTapped(sender: UIBarButtonItem) {
        let supportVC = SupportTableViewController()
        supportVC.sourceTag = .wpComCreateSiteUsername
        supportVC.showFromTabBar()
    }

}

// MARK: - SignupUsernameTableViewControllerDelegate

extension SignupUsernameViewController: SignupUsernameViewControllerDelegate {
    func usernameSelected(_ username: String) {
        delegate?.usernameSelected(username)
    }
}
