import Gridicons
import WordPressUI

private enum Constants {
    static let helpButtonInsets = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0)
    // Button Item: Custom view wrapping the Help UIbutton
    static let helpButtonItemMarginSpace = CGFloat(-8)
    static let helpButtonItemMinimumSize = CGSize(width: 44.0, height: 44.0)

    static let notificationIndicatorCenterOffset = CGPoint(x: 5, y: 12)
    static var notificationIndicatorSize = CGSize(width: 10, height: 10)
}

/// base protocol for NUX view controllers
public protocol NUXViewControllerBase {
    var sourceTag: WordPressSupportSourceTag { get }
    var helpButton: UIButton { get }
    var loginFields: LoginFields { get }
    var dismissBlock: ((_ cancelled: Bool) -> Void)? { get }

    /// Checks if the signin vc modal should show a back button. The back button
    /// visible when there is more than one child vc presented, and there is not
    /// a case where a `SigninChildViewController.backButtonEnabled` in the stack
    /// returns false.
    ///
    /// - Returns: True if the back button should be visible. False otherwise.
    ///
    func shouldShowCancelButton() -> Bool
    func setupCancelButtonIfNeeded()

    /// Notification observers that can be tied to the lifecycle of the entities implementing the protocol
    func addNotificationObserver(_ observer: NSObjectProtocol)
}

/// extension for NUXViewControllerBase where the base class is UIViewController (and thus also NUXTableViewController)
extension NUXViewControllerBase where Self: UIViewController, Self: UIViewControllerTransitioningDelegate {

    /// Indicates if the Help Button should be displayed, or not.
    ///
    var shouldDisplayHelpButton: Bool {
        return WordPressAuthenticator.shared.delegate?.supportActionEnabled ?? false
    }

    /// Indicates if the Cancel button should be displayed, or not.
    ///
    func shouldShowCancelButtonBase() -> Bool {
        return isCancellable() && navigationController?.viewControllers.first == self
    }

    /// Sets up the cancel button for the navbar if its needed.
    /// The cancel button is only shown when its appropriate to dismiss the modal view controller.
    ///
    public func setupCancelButtonIfNeeded() {
        if !shouldShowCancelButton() {
            return
        }

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        cancelButton.on { [weak self] (_: UIBarButtonItem) in
            self?.handleCancelButtonTapped()
        }
        navigationItem.leftBarButtonItem = cancelButton
    }

    /// Returns true whenever the current ViewController can be dismissed.
    ///
    func isCancellable() -> Bool {
        return WordPressAuthenticator.shared.delegate?.dismissActionEnabled ?? true
    }

    /// Displays a login error in an attractive dialog
    ///
    func displayError(_ error: Error, sourceTag: WordPressSupportSourceTag) {
        let presentingController = navigationController ?? self
        let controller = FancyAlertViewController.alertForError(error, loginFields: loginFields, sourceTag: sourceTag)
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self
        presentingController.present(controller, animated: true, completion: nil)
    }

    /// Displays a login error message in an attractive dialog
    ///
    public func displayErrorAlert(_ message: String, sourceTag: WordPressSupportSourceTag, onDismiss: (() -> ())? = nil) {
        let presentingController = navigationController ?? self
        let controller = FancyAlertViewController.alertForGenericErrorMessageWithHelpButton(message, loginFields: loginFields, sourceTag: sourceTag, onDismiss: onDismiss)
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

    // MARK: - Actions

    func handleBackgroundTapGesture() {
        view.endEditing(true)
    }

    func setupBackgroundTapGestureRecognizer() {
        let tgr = UITapGestureRecognizer()
        tgr.on { [weak self] _ in
            self?.handleBackgroundTapGesture()
        }
        view.addGestureRecognizer(tgr)
    }

    func handleCancelButtonTapped() {
        dismiss(cancelled: true)
        NotificationCenter.default.post(name: .wordpressLoginCancelled, object: nil)
    }

    // Handle the help button being tapped
    //
    func handleHelpButtonTapped(_ sender: AnyObject) {
        AuthenticatorAnalyticsTracker.shared.track(click: .showHelp)

        displaySupportViewController(from: sourceTag)
    }

    /// Add/remove the nav bar app logo.
    ///
    func setupNavBarIcon(showIcon: Bool = true) {
        showIcon ? addAppLogoToNavController() : removeAppLogoFromNavController()
    }

    /// Adds the app logo to the nav controller
    ///
    public func addAppLogoToNavController() {
        let image = WordPressAuthenticator.shared.style.navBarImage
        let imageView = UIImageView(image: image.imageWithTintColor(UIColor.white))
        navigationItem.titleView = imageView
    }

    /// Removes the app logo from the nav controller
    ///
    public func removeAppLogoFromNavController() {
        navigationItem.titleView = nil
    }

    /// Whenever the WordPressAuthenticator Delegate returns true, when `shouldDisplayHelpButton` is queried, we'll proceed
    /// and attach the Help Button to the navigationController.
    ///
    func setupHelpButtonIfNeeded() {
        guard shouldDisplayHelpButton else {
            return
        }

        addHelpButtonToNavController()
    }

    // MARK: - Helpers

    /// Adds the Help Button to the nav controller
    ///
    private func addHelpButtonToNavController() {
        let barButtonView = createBarButtonView()
        addHelpButton(to: barButtonView)
        addRightBarButtonItem(with: barButtonView)
    }

    private func addRightBarButtonItem(with customView: UIView) {
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = Constants.helpButtonItemMarginSpace

        let barButton = UIBarButtonItem(customView: customView)
        navigationItem.rightBarButtonItems = [spacer, barButton]
    }

    private func createBarButtonView() -> UIView {
        let customView = UIView(frame: .zero)
        customView.translatesAutoresizingMaskIntoConstraints = false
        customView.heightAnchor.constraint(equalToConstant: Constants.helpButtonItemMinimumSize.height).isActive = true
        customView.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.helpButtonItemMinimumSize.width).isActive = true

        return customView
    }

    private func addHelpButton(to superView: UIView) {
        helpButton.setTitle(NSLocalizedString("Help", comment: "Help button"), for: .normal)
        helpButton.setTitleColor(.label, for: [])
        helpButton.accessibilityIdentifier = "authenticator-help-button"

        helpButton.on(.touchUpInside) { [weak self] control in
            self?.handleHelpButtonTapped(control)
        }

        superView.addSubview(helpButton)
        helpButton.translatesAutoresizingMaskIntoConstraints = false

        helpButton.leadingAnchor.constraint(equalTo: superView.leadingAnchor, constant: Constants.helpButtonInsets.left).isActive = true
        helpButton.trailingAnchor.constraint(equalTo: superView.trailingAnchor, constant: -Constants.helpButtonInsets.right).isActive = true
        helpButton.topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        helpButton.bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
    }

    // MARK: - UIViewControllerTransitioningDelegate

    /// Displays the support vc.
    ///
    func displaySupportViewController(from source: WordPressSupportSourceTag) {
        guard let navigationController else {
            fatalError()
        }

        let state = AuthenticatorAnalyticsTracker.shared.state
        WordPressAuthenticator.shared.delegate?.presentSupport(from: navigationController, sourceTag: source, lastStep: state.lastStep, lastFlow: state.lastFlow)
    }
}
