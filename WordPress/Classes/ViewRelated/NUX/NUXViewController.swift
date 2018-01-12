// MARK: - NUXViewController
/// Base class to use for NUX view controllers that aren't a table view
/// Note: shares most of its code with NUXTableViewController and NUXCollectionViewController. Look to make
///       most changes in either the base protocol NUXViewControllerBase or further subclasses like LoginViewController
class NUXViewController: UIViewController, NUXViewControllerBase, UIViewControllerTransitioningDelegate, LoginSegueHandler {
    // MARK: NUXViewControllerBase properties
    /// these properties comply with NUXViewControllerBase and are duplicated with NUXTableViewController
    var helpBadge: WPNUXHelpBadgeLabel = WPNUXHelpBadgeLabel()
    var helpButton: UIButton = UIButton(type: .custom)
    var dismissBlock: ((_ cancelled: Bool) -> Void)?
    var loginFields = LoginFields()
    var sourceTag: SupportSourceTag {
        get {
            return .generalLogin
        }
    }

    // MARK: associated type for LoginSegueHandler
    /// Segue identifiers to avoid using strings
    enum SegueIdentifier: String {
        case showURLUsernamePassword
        case showSelfHostedLogin
        case showWPComLogin
        case startMagicLinkFlow
        case showMagicLink
        case showLinkMailView
        case show2FA
        case showEpilogue
        case showDomains
    }

    override func viewDidLoad() {
        addHelpButtonToNavController()
        setupCancelButtonIfNeeded()
    }

    // properties specific to NUXViewController
    @IBOutlet var submitButton: NUXSubmitButton?
    @IBOutlet var errorLabel: UILabel?

    func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)
        submitButton?.isEnabled = enableSubmit(animating: animating)
    }

    open func enableSubmit(animating: Bool) -> Bool {
        return !animating
    }

    func shouldShowCancelButton() -> Bool {
        return shouldShowCancelButtonBase()
    }
}
