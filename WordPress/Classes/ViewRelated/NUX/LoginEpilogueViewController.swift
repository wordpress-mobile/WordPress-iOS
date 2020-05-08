import UIKit
import WordPressShared
import WordPressAuthenticator


// MARK: - LoginEpilogueViewController
//
class LoginEpilogueViewController: UIViewController {

    /// Button Container View.
    ///
    @IBOutlet var buttonPanel: UIView!

    /// Line displayed atop the buttonPanel when the table is scrollable.
    ///
    @IBOutlet var topLine: UIView!
    @IBOutlet var topLineHeightConstraint: NSLayoutConstraint!

    /// Done Button.
    ///
    @IBOutlet var doneButton: UIButton!

    /// Constraints on the table view container.
    /// Used to adjust the width on iPad.
    @IBOutlet var tableViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewTrailingConstraint: NSLayoutConstraint!
    private var defaultTableViewMargin: CGFloat = 0

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
        topLine.backgroundColor = .divider
        defaultTableViewMargin = tableViewLeadingConstraint.constant
        setTableViewMargins(forWidth: view.frame.width)
        refreshInterface(with: credentials)
        WordPressAuthenticator.track(.loginEpilogueViewed)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
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

        tableViewController = epilogueTableViewController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configurePanelBasedOnTableViewContents()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setTableViewMargins(forWidth: size.width)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setTableViewMargins(forWidth: view.frame.width)
    }

}

// MARK: - Private Extension
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

        topLineHeightConstraint.constant = .hairlineBorderWidth

        let contentSize = tableView.contentSize
        let screenHeight = UIScreen.main.bounds.height
        let panelHeight = buttonPanel.frame.height

        if contentSize.height >= (screenHeight - panelHeight) {
            buttonPanel.backgroundColor = .listBackground
            topLine.isHidden = false
        } else {
            buttonPanel.backgroundColor = .basicBackground
            topLine.isHidden = true
        }
    }

    func setTableViewMargins(forWidth viewWidth: CGFloat) {
        guard traitCollection.horizontalSizeClass == .regular &&
            traitCollection.verticalSizeClass == .regular else {
                tableViewLeadingConstraint.constant = defaultTableViewMargin
                tableViewTrailingConstraint.constant = defaultTableViewMargin
                return
        }

        let marginMultiplier = UIDevice.current.orientation.isLandscape ?
            TableViewMarginMultipliers.ipadLandscape :
            TableViewMarginMultipliers.ipadPortrait

        let margin = viewWidth * marginMultiplier

        tableViewLeadingConstraint.constant = margin
        tableViewTrailingConstraint.constant = margin
    }

    enum TableViewMarginMultipliers {
        static let ipadPortrait: CGFloat = 0.1667
        static let ipadLandscape: CGFloat = 0.25
    }

    // MARK: - Actions

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
