import UIKit
import WordPressShared


// MARK: - LoginEpilogueViewController
//
class LoginEpilogueViewController: UIViewController {

    /// Button's Container View.
    ///
    @IBOutlet var buttonPanel: UIView!

    /// Separator: to be displayed above the actual buttons.
    ///
    @IBOutlet var shadowView: UIView!

    /// Connect Button!
    ///
    @IBOutlet var connectButton: UIButton!

    /// Continue Button.
    ///
    @IBOutlet var continueButton: UIButton!

    /// Links to the Epilogue TableViewController
    ///
    private var tableViewController: LoginEpilogueTableViewController?

    /// Closure to be executed upon dismissal.
    ///
    var onDismiss: (() -> Void)?

    /// Site that was just connected to our awesome app.
    ///
    var credentials: WordPressCredentials? {
        didSet {
            guard isViewLoaded, let credentials = credentials else {
                return
            }

            refreshInterface(with: credentials)
        }
    }


    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let credentials = credentials else {
            fatalError()
        }

        refreshInterface(with: credentials)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.track(.loginEpilogueViewed)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        guard let epilogueTableViewController = segue.destination as? LoginEpilogueTableViewController else {
            return
        }

        guard let credentials = credentials else {
            fatalError()
        }

        epilogueTableViewController.setup(with: credentials)
        tableViewController = epilogueTableViewController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configurePanelBasedOnTableViewContents()
    }
}


// MARK: - Configuration
//
private extension LoginEpilogueViewController {

    /// Refreshes the UI so that the specified WordPressSite is displayed.
    ///
    func refreshInterface(with credentials: WordPressCredentials) {
        switch credentials {
        case .wporg:
            configureButtons()
        case .wpcom(_, _, let isJetpackLogin, _):
            configureButtons(numberOfBlogs: numberOfWordPressComBlogs, hidesConnectButton: isJetpackLogin)
        }
    }

    /// Returns the number of WordPress.com sites.
    ///
    var numberOfWordPressComBlogs: Int {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)

        return service.defaultWordPressComAccount()?.blogs.count ?? 0
    }

    /// Setup: Buttons
    ///
    func configureButtons(numberOfBlogs: Int = 1, hidesConnectButton: Bool = false) {
        let connectTitle: String
        if numberOfBlogs == 0 {
            connectTitle = NSLocalizedString("Connect a site", comment: "Button title")
        } else {
            connectTitle = NSLocalizedString("Connect another site", comment: "Button title")
        }

        continueButton.setTitle(NSLocalizedString("Continue", comment: "A button title"), for: .normal)
        continueButton.accessibilityIdentifier = "Continue"
        connectButton.setTitle(connectTitle, for: .normal)
        connectButton.isHidden = hidesConnectButton
    }

    /// Setup: Button Panel
    ///
    func configurePanelBasedOnTableViewContents() {
        guard let tableView = tableViewController?.tableView else {
            return
        }

        let contentSize = tableView.contentSize
        let screenHeight = UIScreen.main.bounds.height
        let panelHeight = buttonPanel.frame.height

        if contentSize.height > (screenHeight - panelHeight) {
            buttonPanel.backgroundColor = .white
            shadowView.isHidden = false
        } else {
            buttonPanel.backgroundColor = WPStyleGuide.lightGrey()
            shadowView.isHidden = true
        }
    }
}


// MARK: - Actions
//
extension LoginEpilogueViewController {

    @IBAction func dismissEpilogue() {
        onDismiss?()
        navigationController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func handleConnectAnotherButton() {
        onDismiss?()
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "siteAddress") as? LoginSiteAddressViewController else {
            return
        }
        navigationController?.setViewControllers([controller], animated: true)
    }
}
