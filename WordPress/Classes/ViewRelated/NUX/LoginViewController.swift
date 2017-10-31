import Foundation
import Gridicons

protocol LoginWithLogoAndHelpViewController {
    func addWordPressLogoToNavController()
    func addHelpButtonToNavController() -> (UIButton, WPNUXHelpBadgeLabel)
}

extension LoginWithLogoAndHelpViewController where Self: UIViewController {
    func addWordPressLogoToNavController() {
        let image = Gridicon.iconOfType(.mySites)
        let imageView = UIImageView(image: image.imageWithTintColor(UIColor.white))
        navigationItem.titleView = imageView
    }
    func addHelpButtonToNavController() -> (UIButton, WPNUXHelpBadgeLabel) {
        let helpButtonMarginSpacerWidth = CGFloat(-8)
        let helpBadgeSize = CGSize(width: 12, height: 10)
        let helpButtonContainerFrame = CGRect(x: 0, y: 0, width: 44, height: 44)

        NotificationCenter.default.addObserver(self, selector: #selector(NUXAbstractViewController.handleHelpshiftUnreadCountUpdated(_:)), name: NSNotification.Name.HelpshiftUnreadCountUpdated, object: nil)

        let customView = UIView(frame: helpButtonContainerFrame)

        let helpButton = UIButton(type: .custom)
        helpButton.setTitle(NSLocalizedString("Help", comment: "Help button"), for: .normal)
        helpButton.setTitleColor(UIColor(white: 1.0, alpha: 0.4), for: .highlighted)
        helpButton.addTarget(self, action: #selector(NUXAbstractViewController.handleHelpButtonTapped(_:)), for: .touchUpInside)

        customView.addSubview(helpButton)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        helpButton.leadingAnchor.constraint(equalTo: customView.leadingAnchor).isActive = true
        helpButton.trailingAnchor.constraint(equalTo: customView.trailingAnchor).isActive = true
        helpButton.topAnchor.constraint(equalTo: customView.topAnchor).isActive = true
        helpButton.bottomAnchor.constraint(equalTo: customView.bottomAnchor).isActive = true

        let helpBadge = WPNUXHelpBadgeLabel()
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

        return (helpButton, helpBadge)
    }
}

class LoginViewController: NUXAbstractViewController, LoginWithLogoAndHelpViewController {
    @IBOutlet var instructionLabel: UILabel?
    @IBOutlet var errorLabel: UILabel?
    @IBOutlet var submitButton: NUXSubmitButton?
    var errorToPresent: Error?

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
    func setupNavBarIcon() {
        addWordPressLogoToNavController()
    }

    /// Configures instruction label font
    ///
    func styleInstructions() {
        instructionLabel?.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
    }

    /// Sets up the help button and the helpshift conversation badge.
    ///
    override func setupHelpButtonAndBadge() {
        let (helpButtonResult, helpBadgeResult) = addHelpButtonToNavController()
        helpButton = helpButtonResult
        helpBadge = helpBadgeResult
    }

    /// Sets the text of the error label.
    ///
    func displayError(message: String) {
        guard message.count > 0 else {
            errorLabel?.isHidden = true
            return
        }
        errorLabel?.isHidden = false
        errorLabel?.text = message
    }

    /// Configures the appearance and state of the submit button.
    ///
    func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)
        submitButton?.isEnabled = enableSubmit(animating: animating)
    }

    /// Determines if the submit button should be enabled. Meant to be overridden in subclasses.
    ///
    open func enableSubmit(animating: Bool) -> Bool {
        return !animating
    }

    override func dismiss() {
        loginDismissal()
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
        } else if let destination = segue.destination as? LoginViewController {
            destination.loginFields = source.loginFields
            destination.restrictToWPCom = source.restrictToWPCom
            destination.dismissBlock = source.dismissBlock
            destination.errorToPresent = source.errorToPresent
        }
    }
}

extension LoginViewController: SigninWPComSyncHandler, LoginFacadeDelegate {
    func configureStatusLabel(_ message: String) {
        // this is now a no-op, unless status labels return
    }

    /// Configure the view's loading state.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
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
    func updateSafariCredentialsIfNeeded() {
        SigninHelpers.updateSafariCredentialsIfNeeded(loginFields)
    }

    func loginDismissal() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }
}
