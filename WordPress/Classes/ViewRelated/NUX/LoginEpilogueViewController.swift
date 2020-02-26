import UIKit
import WordPressShared
import WordPressAuthenticator


// MARK: - LoginEpilogueViewController
//
class LoginEpilogueViewController: UIViewController {

    /// Button's Container View.
    ///
    @IBOutlet var buttonPanel: UIView!

    /// Separator: to be displayed above the actual buttons.
    ///
    @IBOutlet var shadowView: UIView!

    /// Done Button.
    ///
    @IBOutlet var doneButton: UIButton!

    /// Links to the Epilogue TableViewController
    ///
    private var tableViewController: LoginEpilogueTableViewController?

    /// Closure to be executed upon dismissal.
    ///
    var onDismiss: (() -> Void)?

    /// Site that was just connected to our awesome app.
    ///
    var credentials: AuthenticatorCredentials? {
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

        view.backgroundColor = .basicBackground
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

        epilogueTableViewController.setup(with: credentials, onConnectSite: { [weak self] in
            self?.handleConnectAnotherButton()

        })
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
    func refreshInterface(with credentials: AuthenticatorCredentials) {
        configureDoneButton()
    }

    /// Setup: Buttons
    ///
    func configureDoneButton() {
        doneButton.setTitle(NSLocalizedString("Done", comment: "A button title"), for: .normal)
        doneButton.accessibilityIdentifier = "Done"
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
            buttonPanel.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
            shadowView.isHidden = false
        } else {
            buttonPanel.backgroundColor = .listBackground
            shadowView.isHidden = true
        }
    }
}


// MARK: - Actions
//
extension LoginEpilogueViewController {

    @IBAction func dismissEpilogue() {
        onDismiss?()
        navigationController?.dismiss(animated: true)
    }

    func handleConnectAnotherButton() {
        onDismiss?()
        let controller = WordPressAuthenticator.signinForWPOrg()
        navigationController?.setViewControllers([controller], animated: true)
    }
}
