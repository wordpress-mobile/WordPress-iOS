// MARK: - NUXViewController
/// Base class to use for NUX view controllers that aren't a table view
/// Note: shares most of its code with NUXTableViewController and NUXCollectionViewController. Look to make
///       most changes in either the base protocol NUXViewControllerBase or further subclasses like LoginViewController
class NUXViewController: UIViewController, NUXViewControllerBase, UIViewControllerTransitioningDelegate, NUXSegueHandler {
    // MARK: NUXViewControllerBase properties
    /// these properties comply with NUXViewControllerBase and are duplicated with NUXTableViewController
    var helpBadge: NUXHelpBadgeLabel = NUXHelpBadgeLabel()
    var helpButton: UIButton = UIButton(type: .custom)
    var dismissBlock: ((_ cancelled: Bool) -> Void)?
    var loginFields = LoginFields()
    var sourceTag: WordPressSupportSourceTag {
        get {
            return .generalLogin
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    // MARK: associated type for NUXSegueHandler
    /// Segue identifiers to avoid using strings
    enum SegueIdentifier: String {
        case showEmailLogin
        case showSignupMethod
        case showSigninV2
        case showGoogle
        case showURLUsernamePassword
        case showSelfHostedLogin
        case showWPComLogin
        case startMagicLinkFlow
        case showMagicLink
        case showLinkMailView
        case show2FA
        case showDomains
        case showCreateSite
        case showSignupEmail
        case showUsernames
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHelpButtonIfNeeded()
        setupCancelButtonIfNeeded()
        setupBackgroundTapGestureRecognizer()
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

extension NUXViewController {
    // Required so that any FancyAlertViewControllers presented within the NUX
    // use the correct dimmed backing view.
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presented is FancyAlertViewController || presented is LoginPrologueSignupMethodViewController {
            return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
        }

        return nil
    }
}
