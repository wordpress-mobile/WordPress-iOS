import UIKit
import WordPressShared
import WordPressUI
import WordPressKit

class LoginPrologueViewController: LoginViewController {

    @IBOutlet private weak var topContainerView: UIView!
    @IBOutlet private weak var buttonBlurEffectView: UIVisualEffectView!
    @IBOutlet private weak var buttonBackgroundView: UIView!
    private var buttonViewController: NUXButtonViewController?
    private var stackedButtonsViewController: NUXStackedButtonsViewController?
    var showCancel = false
    var continueWithDotComOverwrite: ((UIViewController) -> Bool)? = nil
    var selfHostedSiteLoginOverwrite: ((UIViewController) -> Bool)? = nil

    @IBOutlet private weak var buttonContainerView: UIView!
    /// Blur effect on button container view
    ///
    private var blurEffect: UIBlurEffect.Style {
        return .systemChromeMaterial
    }

    /// Constraints on the button view container.
    /// Used to adjust the button width in unified views.
    @IBOutlet private weak var buttonViewLeadingConstraint: NSLayoutConstraint?
    @IBOutlet private weak var buttonViewTrailingConstraint: NSLayoutConstraint?
    private var defaultButtonViewMargin: CGFloat = 0

    // Called when login button is tapped
    var onLoginButtonTapped: (() -> Void)?

    private let configuration = WordPressAuthenticator.shared.configuration
    private let style = WordPressAuthenticator.shared.style

    /// We can't rely on `isMovingToParent` to know if we need to track the `.prologue` step
    /// because for the root view in an App, it's always `false`.  We're relying this variiable
    /// instead, since the `.prologue` step only needs to be tracked once.
    ///
    private var prologueFlowTracked = false

    /// Return`true` to use new `NUXStackedButtonsViewController` instead of `NUXButtonViewController` to create buttons
    ///
    private var useStackedButtonsViewController: Bool {
        configuration.enableWPComLoginOnlyInPrologue ||
        configuration.enableSiteCreation ||
        configuration.enableSiteAddressLoginOnlyInPrologue ||
        configuration.enableSiteCreationGuide
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        if let topContainerChildViewController = style.prologueTopContainerChildViewController() {
            topContainerView.subviews.forEach { $0.removeFromSuperview() }
            addChild(topContainerChildViewController)
            topContainerView.addSubview(topContainerChildViewController.view)
            topContainerChildViewController.didMove(toParent: self)

            topContainerChildViewController.view.translatesAutoresizingMaskIntoConstraints = false
            topContainerView.pinSubviewToAllEdges(topContainerChildViewController.view)
        }

        createButtonViewController()

        defaultButtonViewMargin = buttonViewLeadingConstraint?.constant ?? 0
        if let backgroundImage = WordPressAuthenticator.shared.unifiedStyle?.prologueBackgroundImage {
            view.layer.contents = backgroundImage.cgImage
        }
    }

    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureButtonVC()
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // We've found some instances where the iCloud Keychain login flow was being started
        // when the device was idle and the app was logged out and in the background.  I couldn't
        // find precise reproduction steps for this issue but my guess is that some background
        // operation is triggering a call to this method while the app is in the background.
        // The proposed solution is based off this StackOverflow reply:
        //
        // https://stackoverflow.com/questions/30584356/viewdidappear-is-called-when-app-is-started-due-to-significant-location-change
        //
        guard UIApplication.shared.applicationState != .background else {
            return
        }

        WordPressAuthenticator.track(.loginPrologueViewed)

        tracker.set(flow: .prologue)

        if !prologueFlowTracked {
            tracker.track(step: .prologue)
            prologueFlowTracked = true
        } else {
            tracker.set(step: .prologue)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setButtonViewMargins(forWidth: view.frame.width)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setButtonViewMargins(forWidth: size.width)
    }

    private func configureButtonVC() {
        guard configuration.enableUnifiedAuth else {
            buildPrologueButtons()
            return
        }

        if useStackedButtonsViewController {
            buildPrologueButtonsUsingStackedButtonsViewController()
        } else {
            buildUnifiedPrologueButtons()
        }

        if let buttonViewController {
            buttonViewController.shadowLayoutGuide = view.safeAreaLayoutGuide
            buttonViewController.topButtonStyle = WordPressAuthenticator.shared.style.prologuePrimaryButtonStyle
            buttonViewController.bottomButtonStyle = WordPressAuthenticator.shared.style.prologueSecondaryButtonStyle
            buttonViewController.tertiaryButtonStyle = WordPressAuthenticator.shared.style.prologueSecondaryButtonStyle
        } else if let stackedButtonsViewController {
            stackedButtonsViewController.shadowLayoutGuide = view.safeAreaLayoutGuide
        }
    }

    /// Displays the old UI prologue buttons.
    ///
    private func buildPrologueButtons() {
        guard let buttonViewController else {
            return
        }

        let loginTitle = NSLocalizedString("Log In", comment: "Button title.  Tapping takes the user to the login form.")
        let createTitle = NSLocalizedString("Sign up for WordPress.com", comment: "Button title. Tapping begins the process of creating a WordPress.com account.")

        buttonViewController.setupTopButton(title: loginTitle, isPrimary: false, accessibilityIdentifier: "Prologue Log In Button") { [weak self] in
            self?.onLoginButtonTapped?()
            self?.loginTapped()
        }

        if configuration.enableSignUp {
            buttonViewController.setupBottomButton(title: createTitle, isPrimary: true, accessibilityIdentifier: "Prologue Signup Button") { [weak self] in
                self?.signupTapped()
            }
        }

        if showCancel {
            let cancelTitle = NSLocalizedString("Cancel", comment: "Button title. Tapping it cancels the login flow.")
            buttonViewController.setupTertiaryButton(title: cancelTitle, isPrimary: false) { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }

        buttonViewController.backgroundColor = style.buttonViewBackgroundColor
        buttonBlurEffectView.isHidden = true
    }

    /// Displays the Unified prologue buttons.
    ///
    private func buildUnifiedPrologueButtons() {
        guard let buttonViewController else {
            return
        }

        let displayStrings = WordPressAuthenticator.shared.displayStrings
        let loginTitle = displayStrings.continueWithWPButtonTitle
        let siteAddressTitle = displayStrings.enterYourSiteAddressButtonTitle

        if configuration.continueWithSiteAddressFirst {
            buildUnifiedPrologueButtonsWithSiteAddressFirst(buttonViewController, loginTitle: loginTitle, siteAddressTitle: siteAddressTitle)
            return
        }

        buildDefaultUnifiedPrologueButtons(buttonViewController, loginTitle: loginTitle, siteAddressTitle: siteAddressTitle)
    }

    private func buildDefaultUnifiedPrologueButtons(_ buttonViewController: NUXButtonViewController, loginTitle: String, siteAddressTitle: String) {

        setButtonViewMargins(forWidth: view.frame.width)

        buttonViewController.setupTopButton(title: loginTitle, isPrimary: true, configureBodyFontForTitle: true, accessibilityIdentifier: "Prologue Continue Button", onTap: loginTapCallback())

        if configuration.enableUnifiedAuth {
            buttonViewController.setupBottomButton(title: siteAddressTitle, isPrimary: false, configureBodyFontForTitle: true, accessibilityIdentifier: "Prologue Self Hosted Button", onTap: siteAddressTapCallback())
        }

        showCancelIfNeccessary(buttonViewController)

        setButtonViewControllerBackground()
    }

    private func buildUnifiedPrologueButtonsWithSiteAddressFirst(_ buttonViewController: NUXButtonViewController, loginTitle: String, siteAddressTitle: String) {
        guard configuration.enableUnifiedAuth == true else {
            return
        }

        setButtonViewMargins(forWidth: view.frame.width)

        buttonViewController.setupTopButton(title: siteAddressTitle, isPrimary: true, accessibilityIdentifier: "Prologue Self Hosted Button", onTap: siteAddressTapCallback())

        buttonViewController.setupBottomButton(title: loginTitle, isPrimary: false, accessibilityIdentifier: "Prologue Continue Button", onTap: loginTapCallback())

        showCancelIfNeccessary(buttonViewController)

        setButtonViewControllerBackground()
    }

    private func buildPrologueButtonsUsingStackedButtonsViewController() {
        guard let stackedButtonsViewController else {
            return
        }

        let primaryButtonStyle = WordPressAuthenticator.shared.style.prologuePrimaryButtonStyle
        let secondaryButtonStyle = WordPressAuthenticator.shared.style.prologueSecondaryButtonStyle

        setButtonViewMargins(forWidth: view.frame.width)
        let displayStrings = WordPressAuthenticator.shared.displayStrings
        let buttons: [StackedButton]

        let continueWithWPButton: StackedButton? = {
            guard !configuration.enableSiteAddressLoginOnlyInPrologue else {
                return nil
            }
            return StackedButton(title: displayStrings.continueWithWPButtonTitle,
                                 isPrimary: true,
                                 configureBodyFontForTitle: true,
                                 accessibilityIdentifier: "Prologue Continue Button",
                                 style: primaryButtonStyle,
                                 onTap: loginTapCallback())
        }()

        let enterYourSiteAddressButton: StackedButton? = {
            guard !configuration.enableWPComLoginOnlyInPrologue else {
                return nil
            }
            let isPrimary = configuration.enableSiteAddressLoginOnlyInPrologue && !configuration.enableSiteCreation
            return StackedButton(title: displayStrings.enterYourSiteAddressButtonTitle,
                                 isPrimary: isPrimary,
                                 configureBodyFontForTitle: true,
                                 accessibilityIdentifier: "Prologue Self Hosted Button",
                                 style: secondaryButtonStyle,
                                 onTap: siteAddressTapCallback())
        }()

        let createSiteButton: StackedButton? = {
            guard configuration.enableSiteCreation else {
                return nil
            }
            let isPrimary = configuration.enableSiteAddressLoginOnlyInPrologue
            return StackedButton(title: displayStrings.siteCreationButtonTitle,
                                 isPrimary: isPrimary,
                                 configureBodyFontForTitle: true,
                                 accessibilityIdentifier: "Prologue Create Site Button",
                                 style: secondaryButtonStyle,
                                 onTap: simplifiedLoginSiteCreationCallback())
        }()

        let createSiteButtonForBottomStackView: StackedButton? = {
            guard let createSiteButton else {
                return nil
            }
            return StackedButton(using: createSiteButton, stackView: .bottom)
        }()

        let siteCreationGuideButton: StackedButton? = {
            guard configuration.enableSiteCreationGuide else {
                return nil
            }
            return StackedButton(title: displayStrings.siteCreationGuideButtonTitle,
                                 isPrimary: false,
                                 configureBodyFontForTitle: true,
                                 accessibilityIdentifier: "Prologue Site Creation Guide button",
                                 style: NUXButtonStyle.linkButtonStyle,
                                 onTap: siteCreationGuideCallback())
        }()

        let showBothLoginOptions = continueWithWPButton != nil && enterYourSiteAddressButton != nil
        buttons = [
            continueWithWPButton,
            !showBothLoginOptions ? createSiteButton : nil,
            enterYourSiteAddressButton,
            showBothLoginOptions ? createSiteButtonForBottomStackView : nil,
            siteCreationGuideButton
        ].compactMap { $0 }

        let showDivider = configuration.enableWPComLoginOnlyInPrologue == false &&
            configuration.enableSiteCreation == true &&
            configuration.enableSiteAddressLoginOnlyInPrologue == false
        stackedButtonsViewController.setUpButtons(using: buttons, showDivider: showDivider)
        setButtonViewControllerBackground()
    }

    private func siteAddressTapCallback() -> NUXButtonViewController.CallBackType {
        return { [weak self] in
            self?.siteAddressTapped()
        }
    }

    private func loginTapCallback() -> NUXButtonViewController.CallBackType {
        return { [weak self] in
            guard let self else {
                return
            }

            self.tracker.track(click: .continueWithWordPressCom)
            self.continueWithDotCom()
        }
    }

    private func simplifiedLoginSiteCreationCallback() -> NUXButtonViewController.CallBackType {
        { [weak self] in
            guard let self, let navigationController = self.navigationController else { return }
            // triggers the delegate to ask the host app to handle site creation
            WordPressAuthenticator.shared.delegate?.showSiteCreation(in: navigationController)
        }
    }

    private func siteCreationGuideCallback() -> NUXButtonViewController.CallBackType {
        { [weak self] in
            guard let self, let navigationController else { return }
            // triggers the delegate to ask the host app to handle site creation guide
            WordPressAuthenticator.shared.delegate?.showSiteCreationGuide(in: navigationController)
        }
    }

    private func showCancelIfNeccessary(_ buttonViewController: NUXButtonViewController) {
        if showCancel {
            let cancelTitle = NSLocalizedString("Cancel", comment: "Button title. Tapping it cancels the login flow.")
            buttonViewController.setupTertiaryButton(title: cancelTitle, isPrimary: false) { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }

    private func setButtonViewControllerBackground() {
        // Fallback to setting the button background color to clear so the blur effect blurs the Prologue background color.
        let buttonsBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.prologueButtonsBackgroundColor ?? .clear
        buttonViewController?.backgroundColor = buttonsBackgroundColor
        buttonBackgroundView?.backgroundColor = buttonsBackgroundColor
        stackedButtonsViewController?.backgroundColor = buttonsBackgroundColor

        /// If host apps provide a background color for the prologue buttons:
        /// 1. Hide the blur effect
        /// 2. Set the background color of the view controller to prologueViewBackgroundColor
        let prologueViewBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.prologueViewBackgroundColor ?? .clear

        guard prologueViewBackgroundColor.cgColor == buttonsBackgroundColor.cgColor else {
            buttonBlurEffectView.effect = UIBlurEffect(style: blurEffect)
            return
        }
        // do not set background color if we've set a background image earlier
        if WordPressAuthenticator.shared.unifiedStyle?.prologueBackgroundImage == nil {
            view.backgroundColor = prologueViewBackgroundColor
        }
        // if a blur effect for the buttons was passed, use it; otherwise hide the view.
        guard let blurEffect = WordPressAuthenticator.shared.unifiedStyle?.prologueButtonsBlurEffect else {
            buttonBlurEffectView.isHidden = true
            return
        }
        buttonBlurEffectView.effect = blurEffect
    }

    // MARK: - Actions

    /// Old UI. "Log In" button action.
    ///
    private func loginTapped() {
        tracker.set(source: .default)

        guard let vc = LoginPrologueLoginMethodViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate to LoginPrologueLoginMethodViewController from LoginPrologueViewController")
            return
        }

        vc.transitioningDelegate = self

        // Continue with WordPress.com button action
        vc.emailTapped = { [weak self] in
            guard let self else {
                return
            }

            self.presentLoginEmailView()
        }

        // Continue with Google button action
        vc.googleTapped = { [weak self] in
            self?.googleTapped()
        }

        // Site address text link button action
        vc.selfHostedTapped = { [weak self] in
            self?.loginToSelfHostedSite()
        }

        // Sign In With Apple (SIWA) button action
        vc.appleTapped = { [weak self] in
            self?.appleTapped()
        }

        vc.modalPresentationStyle = .custom
        navigationController?.present(vc, animated: true, completion: nil)
    }

    /// Old UI. "Sign up with WordPress.com" button action.
    ///
    private func signupTapped() {
        tracker.set(source: .default)

        // This stat is part of a funnel that provides critical information.
        // Before making ANY modification to this stat please refer to: p4qSXL-35X-p2
        WordPressAuthenticator.track(.signupButtonTapped)

        guard let vc = LoginPrologueSignupMethodViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate to LoginPrologueSignupMethodViewController")
            return
        }

        vc.loginFields = self.loginFields
        vc.dismissBlock = dismissBlock
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .custom

        vc.emailTapped = { [weak self] in
            guard let self else {
                return
            }

            guard self.configuration.enableUnifiedAuth else {
                self.presentSignUpEmailView()
                return
            }

            self.presentUnifiedSignupView()
        }

        vc.googleTapped = { [weak self] in
            guard let self else {
                return
            }

            guard self.configuration.enableUnifiedAuth else {
                self.presentGoogleSignupView()
                return
            }

            self.presentUnifiedGoogleView()
        }

        vc.appleTapped = { [weak self] in
            self?.appleTapped()
        }

        navigationController?.present(vc, animated: true, completion: nil)
    }

    private func appleTapped() {
        AppleAuthenticator.sharedInstance.delegate = self
        AppleAuthenticator.sharedInstance.showFrom(viewController: self)
    }

    private func googleTapped() {
        guard configuration.enableUnifiedAuth else {
            GoogleAuthenticator.sharedInstance.loginDelegate = self
            GoogleAuthenticator.sharedInstance.showFrom(viewController: self, loginFields: loginFields, for: .login)
            return
        }

        presentUnifiedGoogleView()
    }

    /// Unified "Continue with WordPress.com" prologue button action.
    ///
    private func continueWithDotCom() {
        if let continueWithDotComOverwrite, continueWithDotComOverwrite(self) {
            return
        }

        guard let vc = GetStartedViewController.instantiate(from: .getStarted) else {
            WPAuthenticatorLogError("Failed to navigate from LoginPrologueViewController to GetStartedViewController")
            return
        }
        vc.source = .wpCom

        navigationController?.pushViewController(vc, animated: true)
    }

    /// Unified "Enter your existing site address" prologue button action.
    ///
    private func siteAddressTapped() {
        tracker.track(click: .loginWithSiteAddress)

        if let selfHostedSiteLoginOverwrite, selfHostedSiteLoginOverwrite(self) {
            return
        }

        loginToSelfHostedSite()
    }

    private func presentSignUpEmailView() {
        guard let toVC = SignupEmailViewController.instantiate(from: .signup) else {
            WPAuthenticatorLogError("Failed to navigate to SignupEmailViewController")
            return
        }

        navigationController?.pushViewController(toVC, animated: true)
    }

    private func presentUnifiedSignupView() {
        guard let toVC = UnifiedSignupViewController.instantiate(from: .unifiedSignup) else {
            WPAuthenticatorLogError("Failed to navigate to UnifiedSignupViewController")
            return
        }

        navigationController?.pushViewController(toVC, animated: true)
    }

    private func presentLoginEmailView() {
        guard let toVC = LoginEmailViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate to LoginEmailVC from LoginPrologueVC")
            return
        }

        navigationController?.pushViewController(toVC, animated: true)
    }

    // Shows the VC that handles both Google login & signup.
    private func presentUnifiedGoogleView() {
        guard let toVC = GoogleAuthViewController.instantiate(from: .googleAuth) else {
            WPAuthenticatorLogError("Failed to navigate to GoogleAuthViewController from LoginPrologueVC")
            return
        }

        navigationController?.pushViewController(toVC, animated: true)
    }

    // Shows the VC that handles only Google signup.
    private func presentGoogleSignupView() {
        guard let toVC = SignupGoogleViewController.instantiate(from: .signup) else {
            WPAuthenticatorLogError("Failed to navigate to SignupGoogleViewController from LoginPrologueVC")
            return
        }

        navigationController?.pushViewController(toVC, animated: true)
    }

    private func presentWPLogin() {
        guard let vc = LoginWPComViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate from LoginPrologueViewController to LoginWPComViewController")
            return
        }

        vc.loginFields = self.loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    private func presentUnifiedPassword() {
        guard let vc = PasswordViewController.instantiate(from: .password) else {
            WPAuthenticatorLogError("Failed to navigate from LoginPrologueViewController to PasswordViewController")
            return
        }

        vc.loginFields = loginFields
        navigationController?.pushViewController(vc, animated: true)
    }

    private func createButtonViewController() {
        if useStackedButtonsViewController {
            let stackedButtonsViewController = NUXStackedButtonsViewController.instance()
            self.stackedButtonsViewController = stackedButtonsViewController
            stackedButtonsViewController.move(to: self, into: buttonContainerView)
        } else {
            let buttonViewController = NUXButtonViewController.instance()
            self.buttonViewController = buttonViewController
            buttonViewController.move(to: self, into: buttonContainerView)
        }
        view.bringSubviewToFront(buttonContainerView)
    }
}

// MARK: - LoginFacadeDelegate

extension LoginPrologueViewController {

    // Used by SIWA when logging with with a passwordless, 2FA account.
    //
    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        configureViewLoading(false)
        socialNeedsMultifactorCode(forUserID: userID, andNonceInfo: nonceInfo)
    }

}

// MARK: - AppleAuthenticatorDelegate

extension LoginPrologueViewController: AppleAuthenticatorDelegate {

    func showWPComLogin(loginFields: LoginFields) {
        self.loginFields = loginFields

        guard WordPressAuthenticator.shared.configuration.enableUnifiedAuth else {
            presentWPLogin()
            return
        }

        presentUnifiedPassword()
    }

    func showApple2FA(loginFields: LoginFields) {
        self.loginFields = loginFields
        signInAppleAccount()
    }

    func authFailedWithError(message: String) {
        displayErrorAlert(message, sourceTag: .loginApple)
    }

}

// MARK: - GoogleAuthenticatorLoginDelegate

extension LoginPrologueViewController: GoogleAuthenticatorLoginDelegate {

    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        self.loginFields = loginFields
        syncWPComAndPresentEpilogue(credentials: credentials)
    }

    func googleNeedsMultifactorCode(loginFields: LoginFields) {
        self.loginFields = loginFields

        guard let vc = Login2FAViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate from LoginViewController to Login2FAViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    func googleExistingUserNeedsConnection(loginFields: LoginFields) {
        self.loginFields = loginFields

        guard let vc = LoginWPComViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate from Google Login to LoginWPComViewController (password VC)")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    func googleLoginFailed(errorTitle: String, errorDescription: String, loginFields: LoginFields) {
        self.loginFields = loginFields

        let socialErrorVC = LoginSocialErrorViewController(title: errorTitle, description: errorDescription)
        let socialErrorNav = LoginNavigationController(rootViewController: socialErrorVC)
        socialErrorVC.delegate = self
        socialErrorVC.loginFields = loginFields
        socialErrorVC.modalPresentationStyle = .fullScreen
        present(socialErrorNav, animated: true)
    }

}

// MARK: - Button View Sizing

private extension LoginPrologueViewController {

    /// Resize the button view based on trait collection.
    /// Used only in unified views.
    ///
    func setButtonViewMargins(forWidth viewWidth: CGFloat) {

        guard configuration.enableUnifiedAuth else {
            return
        }

        guard traitCollection.horizontalSizeClass == .regular &&
            traitCollection.verticalSizeClass == .regular else {
                buttonViewLeadingConstraint?.constant = defaultButtonViewMargin
                buttonViewTrailingConstraint?.constant = defaultButtonViewMargin
                return
        }

        let marginMultiplier = UIDevice.current.orientation.isLandscape ?
            ButtonViewMarginMultipliers.ipadLandscape :
            ButtonViewMarginMultipliers.ipadPortrait

        let margin = viewWidth * marginMultiplier

        buttonViewLeadingConstraint?.constant = margin
        buttonViewTrailingConstraint?.constant = margin
    }

    private enum ButtonViewMarginMultipliers {
        static let ipadPortrait: CGFloat = 0.1667
        static let ipadLandscape: CGFloat = 0.25
    }

}
