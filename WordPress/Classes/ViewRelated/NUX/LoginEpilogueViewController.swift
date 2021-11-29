import UIKit
import WordPressShared
import WordPressAuthenticator


// MARK: - LoginEpilogueViewController
//
class LoginEpilogueViewController: UIViewController {

    /// Button Container View.
    ///
    @IBOutlet var buttonPanel: UIView!
    @IBOutlet var blurEffectView: UIVisualEffectView!

    /// Line displayed atop the buttonPanel when the table is scrollable.
    ///
    @IBOutlet var topLine: UIView!
    @IBOutlet var topLineHeightConstraint: NSLayoutConstraint!

    /// Create a new site button.
    ///
    @IBOutlet var createANewSiteButton: UIButton!

    /// Constraints on the table view container.
    /// Used to adjust the width on iPad.
    @IBOutlet var tableViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomContraint: NSLayoutConstraint!

    private var defaultTableViewMargin: CGFloat = 0

    /// Blur effect on button panel
    ///
    private var blurEffect: UIBlurEffect.Style {
        return .systemChromeMaterial
    }

    private var dividerView: LoginEpilogueDividerView?

    /// Links to the Epilogue TableViewController
    ///
    private var tableViewController: LoginEpilogueTableViewController?

    /// Analytics Tracker
    ///
    private let tracker = AuthenticatorAnalyticsTracker.shared

    /// Closure to be executed upon blog selection.
    ///
    var onBlogSelected: ((Blog) -> Void)?

    /// Closure to be executed upon a new site creation.
    ///
    var onCreateNewSite: (() -> Void)?

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

        // If the user just signed in, refresh the A/B assignments
        ABTest.start()
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

        epilogueTableViewController.setup(with: credentials)
        tableViewController = epilogueTableViewController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureButtonPanel()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setTableViewMargins(forWidth: size.width)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setTableViewMargins(forWidth: view.frame.width)
    }

    func hideButtonPanel() {
        buttonPanel.isHidden = true
        createANewSiteButton.isHidden = true
        tableViewBottomContraint.constant = 0
    }

    // MARK: - Actions

    func createNewSite() {
        onCreateNewSite?()
        WPAnalytics.track(.loginEpilogueCreateNewSiteTapped)
    }

    func blogSelected(_ blog: Blog) {
        onBlogSelected?(blog)
        WPAnalytics.track(.loginEpilogueChooseSiteTapped, properties: [:], blog: blog)
    }
}

// MARK: - Private Extension
//
private extension LoginEpilogueViewController {

    /// Refreshes the UI so that the specified WordPressSite is displayed.
    ///
    func refreshInterface(with credentials: AuthenticatorCredentials) {
        configureCreateANewSiteButton()
    }

    /// Setup: Buttons
    ///
    func configureCreateANewSiteButton() {
        createANewSiteButton.setTitle(NSLocalizedString("Create a new site", comment: "A button title"), for: .normal)
        createANewSiteButton.accessibilityIdentifier = "Create a new site"
    }

    /// Setup: Button Panel
    ///
    func configureButtonPanel() {
        topLineHeightConstraint.constant = .hairlineBorderWidth
        buttonPanel.backgroundColor = .quaternaryBackground
        topLine.isHidden = false
        blurEffectView.effect = UIBlurEffect(style: blurEffect)
        blurEffectView.isHidden = false
        setupDividerLineIfNeeded()
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

    func setupDividerLineIfNeeded() {
        guard dividerView == nil else { return }
        dividerView = LoginEpilogueDividerView()
        guard let dividerView = dividerView else { return }
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(dividerView)
        NSLayoutConstraint.activate([
            dividerView.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
            dividerView.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: Constants.dividerViewHeight)
        ])
    }

    enum TableViewMarginMultipliers {
        static let ipadPortrait: CGFloat = 0.1667
        static let ipadLandscape: CGFloat = 0.25
    }

    private enum Constants {
        static let dividerViewHeight: CGFloat = 40.0
    }

    // MARK: - Actions

    @IBAction func createANewSite() {
        createNewSite()
    }
}
