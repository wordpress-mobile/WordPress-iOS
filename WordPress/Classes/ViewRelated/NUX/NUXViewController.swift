import Gridicons

/// Segue identifiers to avoid using strings
enum NUXSegueIdentifier: String {
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


/// Base class to use for NUX view controllers that aren't a table view
class NUXViewController: UIViewController, NUXViewControllerBase, UIViewControllerTransitioningDelegate {
    var helpBadge: WPNUXHelpBadgeLabel = WPNUXHelpBadgeLabel()
    var helpButton: UIButton = UIButton(type: .custom)
    var dismissBlock: ((_ cancelled: Bool) -> Void)?
    var loginFields = LoginFields()
}

/// Base class to use for NUX view controllers that are also a table view controller
class NUXTableViewController: UITableViewController, NUXViewControllerBase, UIViewControllerTransitioningDelegate {
    var helpBadge: WPNUXHelpBadgeLabel = WPNUXHelpBadgeLabel()
    var helpButton: UIButton = UIButton(type: .custom)
    var dismissBlock: ((_ cancelled: Bool) -> Void)?
    var loginFields = LoginFields()
}

/// View Controller for login-specific screens
class LoginNewViewController: NUXViewController, SigninWPComSyncHandler, LoginFacadeDelegate { // temporary name until it can totally replace LoginViewController
    func configureViewLoading(_ loading: Bool) {
        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

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
    @objc func updateSafariCredentialsIfNeeded() {
        SigninHelpers.updateSafariCredentialsIfNeeded(loginFields)
    }
}
