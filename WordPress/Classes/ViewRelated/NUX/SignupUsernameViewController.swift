class SignupUsernameViewController: NUXViewController {
    // MARK: - Properties
    open var currentUsername: String?
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
                self?.navigationController?.popViewController(animated: true)
            }
            showButtonView(show: false, withAnimation: false)
        }
    }
}

// MARK: - SignupUsernameTableViewControllerDelegate

extension SignupUsernameViewController: SignupUsernameTableViewControllerDelegate {
    func usernameSelected(_ username: String) {
//        SiteCreationFields.sharedInstance.domain = domain
        showButtonView(show: true, withAnimation: true)
    }

    func newSearchStarted() {
        showButtonView(show: false, withAnimation: true)
    }
}
