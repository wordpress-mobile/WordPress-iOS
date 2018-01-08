import Gridicons

/// base protocol for NUX view controllers
protocol NUXViewControllerBase {
    var sourceTag: SupportSourceTag { get }
    var helpBadge: WPNUXHelpBadgeLabel { get }
    var helpButton: UIButton { get }
    var loginFields: LoginFields { get }
    var dismissBlock: ((_ cancelled: Bool) -> Void)? { get }
}

/// default implementations for NUXViewControllerBase where the base class doesn't matter
extension NUXViewControllerBase {
    var sourceTag: SupportSourceTag {
        get {
            return .generalLogin
        }
    }
}

/// extension for NUXViewControllerBase where the base class is UIViewController (and thus also NUXTableViewController)
extension NUXViewControllerBase where Self: UIViewController, Self: UIViewControllerTransitioningDelegate {

    /// Checks if the signin vc modal should show a back button. The back button
    /// visible when there is more than one child vc presented, and there is not
    /// a case where a `SigninChildViewController.backButtonEnabled` in the stack
    /// returns false.
    ///
    /// - Returns: True if the back button should be visible. False otherwise.
    ///
    func shouldShowCancelButton() -> Bool {
        return isCancellable() && navigationController?.viewControllers.first == self
    }

    /// Checks if the signin vc modal should be cancellable. The controller is
    /// cancellable when there is a default wpcom account, or at least one
    /// self-hosted blog.
    ///
    /// - Returns: True if cancellable. False otherwise.
    ///
    func isCancellable() -> Bool {
        // if there is an existing blog, or an existing account return true.
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        return AccountHelper.isDotcomAvailable() || blogService.blogCountForAllAccounts() > 0
    }

    /// Displays a login error in an attractive dialog
    ///
    func displayError(_ error: NSError, sourceTag: SupportSourceTag) {
        let presentingController = navigationController ?? self
        let controller = FancyAlertViewController.alertForError(error as NSError, loginFields: loginFields, sourceTag: sourceTag)
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self
        presentingController.present(controller, animated: true, completion: nil)
    }

    /// Displays a login error message in an attractive dialog
    ///
    func displayErrorAlert(_ message: String, sourceTag: SupportSourceTag) {
        let presentingController = navigationController ?? self
        let controller = FancyAlertViewController.alertForGenericErrorMessageWithHelpshiftButton(message, loginFields: loginFields, sourceTag: sourceTag)
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self
        presentingController.present(controller, animated: true, completion: nil)
    }

    /// It is assumed that NUX view controllers are always presented modally.
    ///
    func dismiss() {
        dismiss(cancelled: false)
    }

    /// It is assumed that NUX view controllers are always presented modally.
    /// This method dismisses the view controller
    ///
    /// - Parameters:
    ///     - cancelled: Should be passed true only when dismissed by a tap on the cancel button.
    ///
    fileprivate func dismiss(cancelled: Bool) {
        dismissBlock?(cancelled)
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Notifications

    /// Updates the badge count and its visibility.
    ///
    func handleHelpshiftUnreadCountUpdated(_ notification: Foundation.Notification) {
        let count = HelpshiftUtils.unreadNotificationCount()
        helpBadge.text = "\(count)"
        helpBadge.isHidden = (count == 0)
    }


    // MARK: - Actions

    func handleBackgroundTapGesture(_ tgr: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    func handleCancelButtonTapped(_ sender: UIButton) {
        dismiss(cancelled: true)
        NotificationCenter.default.post(name: .WPLoginCancelled, object: nil)
    }

    // Handle the help button being tapped
    //
    func handleHelpButtonTapped(_ sender: AnyObject) {
        displaySupportViewController(sourceTag: sourceTag)
    }


    // MARK: - Navbar Help and WP Logo methods
    
    /// Adds the WP logo to the nav controller
    func addWordPressLogoToNavController() {
        let image = Gridicon.iconOfType(.mySites)
        let imageView = UIImageView(image: image.imageWithTintColor(UIColor.white))
        navigationItem.titleView = imageView
    }

    func addHelpButtonToNavController() {
        let helpButtonMarginSpacerWidth = CGFloat(-8)
        let helpBadgeSize = CGSize(width: 12, height: 10)
        let helpButtonContainerFrame = CGRect(x: 0, y: 0, width: 44, height: 44)

        NotificationCenter.default.addObserver(forName: .HelpshiftUnreadCountUpdated, object: nil, queue: nil) { [weak self](notification) in
            self?.handleHelpshiftUnreadCountUpdated(notification)
        }

        let customView = UIView(frame: helpButtonContainerFrame)

        helpButton.setTitle(NSLocalizedString("Help", comment: "Help button"), for: .normal)
        helpButton.setTitleColor(UIColor(white: 1.0, alpha: 0.4), for: .highlighted)
        helpButton.on(.touchUpInside) { [weak self] control in
            guard let strongSelf = self else {
                return
            }
            strongSelf.handleHelpButtonTapped(strongSelf.helpButton)
        }

        customView.addSubview(helpButton)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        helpButton.leadingAnchor.constraint(equalTo: customView.leadingAnchor).isActive = true
        helpButton.trailingAnchor.constraint(equalTo: customView.trailingAnchor).isActive = true
        helpButton.topAnchor.constraint(equalTo: customView.topAnchor).isActive = true
        helpButton.bottomAnchor.constraint(equalTo: customView.bottomAnchor).isActive = true

        helpBadge.translatesAutoresizingMaskIntoConstraints = false
        helpBadge.isHidden = true
        customView.addSubview(helpBadge)
        helpBadge.centerXAnchor.constraint(equalTo: helpButton.trailingAnchor).isActive = true
        helpBadge.centerYAnchor.constraint(equalTo: helpButton.topAnchor).isActive = true
        helpBadge.widthAnchor.constraint(equalToConstant: helpBadgeSize.width).isActive = true
        helpBadge.heightAnchor.constraint(equalToConstant: helpBadgeSize.height).isActive = true

        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = helpButtonMarginSpacerWidth

        let barButton = UIBarButtonItem(customView: customView)
        navigationItem.rightBarButtonItems = [spacer, barButton]
    }

    // MARK: - UIViewControllerTransitioningDelegate

    /// Displays the support vc.
    ///
    func displaySupportViewController(sourceTag: SupportSourceTag) {
        let controller = SupportViewController()
        controller.sourceTag = sourceTag

        let navController = UINavigationController(rootViewController: controller)
        navController.navigationBar.isTranslucent = false
        navController.modalPresentationStyle = .formSheet

        navigationController?.present(navController, animated: true, completion: nil)
    }
}

// MARK: - NUXViewController
/// Base class to use for NUX view controllers that aren't a table view
class NUXViewController: UIViewController, NUXViewControllerBase, UIViewControllerTransitioningDelegate, LoginSegueHandler {
    // MARK: NUXViewControllerBase properties
    /// these properties comply with NUXViewControllerBase and are duplicated with NUXTableViewController
    var helpBadge: WPNUXHelpBadgeLabel = WPNUXHelpBadgeLabel()
    var helpButton: UIButton = UIButton(type: .custom)
    var dismissBlock: ((_ cancelled: Bool) -> Void)?
    var loginFields = LoginFields()

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
}

// MARK: - NUXTableViewController
/// Base class to use for NUX view controllers that are also a table view controller
class NUXTableViewController: UITableViewController, NUXViewControllerBase, UIViewControllerTransitioningDelegate {
    // MARK: NUXViewControllerBase properties
    /// these properties comply with NUXViewControllerBase and are duplicated with NUXTableViewController
    var helpBadge: WPNUXHelpBadgeLabel = WPNUXHelpBadgeLabel()
    var helpButton: UIButton = UIButton(type: .custom)
    var dismissBlock: ((_ cancelled: Bool) -> Void)?
    var loginFields = LoginFields()

    override func viewDidLoad() {
        addHelpButtonToNavController()
    }
}

/// View Controller for login-specific screens
class LoginNewViewController: NUXViewController, SigninWPComSyncHandler, LoginFacadeDelegate {
    @IBOutlet var instructionLabel: UILabel?
    @objc var errorToPresent: Error?

    lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()

    // MARK: Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        displayError(message: "")
        setupNavBarIcon()
        styleInstructions()

        if let error = errorToPresent {
            displayRemoteError(error)
        }
    }


    // MARK: - Setup and Configuration

    /// Places the WordPress logo in the navbar
    ///
    @objc func setupNavBarIcon() {
        addWordPressLogoToNavController()
    }

    /// Configures instruction label font
    ///
    @objc func styleInstructions() {
        instructionLabel?.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
    }

    func configureViewLoading(_ loading: Bool) {
        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

    /// Sets the text of the error label.
    func displayError(message: String) {
        guard message.count > 0 else {
            errorLabel?.isHidden = true
            return
        }
        errorLabel?.isHidden = false
        errorLabel?.text = message
    }

    fileprivate func shouldShowEpilogue() -> Bool {
        if !isJetpackLogin() {
            return true
        }
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        guard
            let objectID = loginFields.meta.jetpackBlogID,
            let blog = context.object(with: objectID) as? Blog,
            let account = blog.account
            else {
                return false
        }
        return accountService.isDefaultWordPressComAccount(account)
    }

    func dismiss() {
        if shouldShowEpilogue() {
            self.performSegue(withIdentifier: .showEpilogue, sender: self)
            return
        }
        dismissBlock?(false)
        navigationController?.dismiss(animated: true, completion: nil)
    }

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with login.
    ///
    func validateFormAndLogin() {
        view.endEditing(true)
        displayError(message: "")

        // Is everything filled out?
        if !SigninHelpers.validateFieldsPopulatedForSignin(loginFields) {
            let errorMsg = NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields.")
            displayError(message: errorMsg)

            return
        }

        configureViewLoading(true)

        loginFacade.signIn(with: loginFields)
    }

    /// Manages data transfer when seguing to a new VC
    ///
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let source = segue.source as? LoginViewController else {
            return
        }

        if let destination = segue.destination as? LoginEpilogueViewController {
            destination.dismissBlock = source.dismissBlock
            destination.jetpackLogin = source.loginFields.meta.jetpackLogin
        } else if let destination = segue.destination as? LoginViewController {
            destination.loginFields = source.loginFields
            destination.restrictToWPCom = source.restrictToWPCom
            destination.dismissBlock = source.dismissBlock
            destination.errorToPresent = source.errorToPresent
        }
    }

    // MARK: SigninWPComSyncHandler methods
    func finishedLogin(withUsername username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        syncWPCom(username, authToken: authToken, requiredMultifactor: requiredMultifactorCode)
        guard let service = loginFields.meta.socialService, service == SocialServiceName.google,
            let token = loginFields.meta.socialServiceIDToken else {
                return
        }

        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        accountService.connectToSocialService(service, serviceIDToken: token, success: {
            WPAppAnalytics.track(.loginSocialConnectSuccess)
            WPAppAnalytics.track(.loginSocialSuccess)
        }, failure: { error in
            DDLogError(error.description)
            WPAppAnalytics.track(.loginSocialConnectFailure, error: error)
            // We're opting to let this call fail silently.
            // Our user has already successfully authenticated and can use the app --
            // connecting the social service isn't critical.  There's little to
            // be gained by displaying an error that can not currently be resolved
            // in the app and doing so might tarnish an otherwise satisfying login
            // experience.
            // If/when we add support for manually connecting/disconnecting services
            // we can revisit.
        })
    }

    func isJetpackLogin() -> Bool {
        return loginFields.meta.jetpackLogin
    }

    func configureStatusLabel(_ message: String) {
        // this is now a no-op, unless status labels return
    }

    /// Overridden here to direct these errors to the login screen's error label
    func displayRemoteError(_ error: Error!) {
        configureViewLoading(false)

        let err = error as NSError
        guard err.code != 403 else {
            let message = NSLocalizedString("Whoops, something went wrong and we couldn't log you in. Please try again!", comment: "An error message shown when a wpcom user provides the wrong password.")
            displayError(message: message)
            return
        }

        displayError(err, sourceTag: sourceTag)
    }

    func needsMultifactorCode() {
        displayError(message: "")
        configureViewLoading(false)

        WPAppAnalytics.track(.twoFactorCodeRequested)
        self.performSegue(withIdentifier: .show2FA, sender: self)
    }

    // Update safari stored credentials. Call after a successful sign in.
    ///
    func updateSafariCredentialsIfNeeded() {
        SigninHelpers.updateSafariCredentialsIfNeeded(loginFields)
    }
}
