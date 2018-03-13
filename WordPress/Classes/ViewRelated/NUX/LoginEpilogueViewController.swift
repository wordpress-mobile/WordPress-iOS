import UIKit
import WordPressShared

class LoginEpilogueViewController: UIViewController {
    @objc var originalPresentingVC: UIViewController?
    @objc var dismissBlock: ((_ cancelled: Bool) -> Void)?
    @IBOutlet var buttonPanel: UIView?
    @IBOutlet var shadowView: UIView?
    @IBOutlet var connectButton: UIButton?
    @IBOutlet var continueButton: UIButton?
    @objc var tableViewController: LoginEpilogueTableView?
    var epilogueUserInfo: LoginEpilogueUserInfo?
    var jetpackLogin = false

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        var numberOfBlogs = 0
        if let info = epilogueUserInfo {
            tableViewController?.epilogueUserInfo = info
            if info.blog != nil {
                numberOfBlogs = 1
            }
        } else {
            // The self-hosted flow sets user info,  If no user info is set, assume
            // a wpcom flow and try the default wp account.
            let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            if let account = service.defaultWordPressComAccount() {
                tableViewController?.epilogueUserInfo = LoginEpilogueUserInfo(account: account)
                numberOfBlogs = account.blogs.count
            }
        }

        configureButtons(numberOfBlogs: numberOfBlogs)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.post(event: .loginEpilogueViewed)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? LoginEpilogueTableView {
            tableViewController = vc
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        colorPanelBasedOnTableViewContents()
    }

    // MARK: - Configuration

    @objc func configureButtons(numberOfBlogs: Int) {
        var connectTitle: String
        if numberOfBlogs == 0 {
            connectTitle = NSLocalizedString("Connect a site", comment: "Button title")
        } else {
            connectTitle = NSLocalizedString("Connect another site", comment: "Button title")
        }
        continueButton?.setTitle(NSLocalizedString("Continue", comment: "A button title"),
                                 for: .normal)
        continueButton?.accessibilityIdentifier = "Continue"
        connectButton?.setTitle(connectTitle, for: .normal)

        if jetpackLogin {
            connectButton?.isHidden = true
        }
    }

    @objc func colorPanelBasedOnTableViewContents() {
        guard let tableView = tableViewController?.tableView,
            let buttonPanel = buttonPanel else {
                return
        }

        let contentSize = tableView.contentSize
        let screenHeight = UIScreen.main.bounds.size.height
        let panelHeight = buttonPanel.frame.size.height

        if contentSize.height > (screenHeight - panelHeight) {
            buttonPanel.backgroundColor = UIColor.white
            shadowView?.isHidden = false
        } else {
            buttonPanel.backgroundColor = WPStyleGuide.lightGrey()
            shadowView?.isHidden = true
        }
    }


    // MARK: - Actions

    @IBAction func dismissEpilogue() {
        dismissBlock?(false)
        navigationController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func handleConnectAnotherButton() {
        dismissBlock?(false)
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "siteAddress") as? LoginSiteAddressViewController else {
            return
        }
        navigationController?.setViewControllers([controller], animated: true)
    }
}
