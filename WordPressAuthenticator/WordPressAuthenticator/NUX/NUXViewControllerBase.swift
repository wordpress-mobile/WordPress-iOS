import Gridicons
import WordPressUI

private enum Constants {
    static let helpButtonTitleColor = UIColor(white: 1.0, alpha: 0.4)
    static let helpButtonInsets = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0)
    //Button Item: Custom view wrapping the Help UIbutton
    static let helpButtonItemMarginSpace = CGFloat(-8)
    static let helpButtonItemMinimumSize = CGSize(width: 44.0, height: 44.0)

    static let notificationIndicatorCenterOffset = CGPoint(x: 5, y: 12)
    static var notificationIndicatorSize: CGSize {
        if WordPressAuthenticator.shared.configuration.supportNotificationIndicatorFeatureFlag == true {
            return CGSize(width: 10, height: 10)
        } else {
            return CGSize(width: 12, height: 12)
        }
    }
}

/// base protocol for NUX view controllers
public protocol NUXViewControllerBase {
    var sourceTag: WordPressSupportSourceTag { get }
    var helpBadge: NUXHelpBadgeLabel { get }
    var helpNotificationIndicator: WPHelpIndicatorView { get }
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
        cancelButton.on() { [weak self] (control: UIBarButtonItem) in
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
    func displayError(_ error: NSError, sourceTag: WordPressSupportSourceTag) {
        let presentingController = navigationController ?? self
        let controller = FancyAlertViewController.alertForError(error as NSError, loginFields: loginFields, sourceTag: sourceTag)
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self
        presentingController.present(controller, animated: true, completion: nil)
    }

    /// Displays a login error message in an attractive dialog
    ///
    public func displayErrorAlert(_ message: String, sourceTag: WordPressSupportSourceTag) {
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
    func refreshSupportBadge() {
        let count = WordPressAuthenticator.shared.delegate?.supportBadgeCount ?? 0
        helpBadge.text = "\(count)"
        helpBadge.isHidden = (count == 0)
    }

    func refreshSupportNotificationIndicator() {
        let showIndicator = WordPressAuthenticator.shared.delegate?.showSupportNotificationIndicator ?? false
        helpNotificationIndicator.isHidden = !showIndicator
    }

    // MARK: - Actions

    func handleBackgroundTapGesture() {
        view.endEditing(true)
    }

    func setupBackgroundTapGestureRecognizer() {
        let tgr = UITapGestureRecognizer()
        tgr.on() { [weak self] gestureRecognizer in
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
        displaySupportViewController(from: sourceTag)
    }


    // MARK: - Navbar Help and WP Logo methods

    /// Adds the WP logo to the nav controller
    ///
    public func addWordPressLogoToNavController() {
        let image = Gridicon.iconOfType(.mySites)
        let imageView = UIImageView(image: image.imageWithTintColor(UIColor.white))
        navigationItem.titleView = imageView
    }

    /// Whenever the WordPressAuthenticator Delegate returns true, when `shouldDisplayHelpButton` is queried, we'll proceed
    /// and attach the Help Button to the navigationController.
    ///
    public func setupHelpButtonIfNeeded() {
        guard shouldDisplayHelpButton else {
            return
        }

        addHelpButtonToNavController()
        refreshSupportBadge()
        refreshSupportNotificationIndicator()
    }

    /// Adds the Help Button to the nav controller
    ///
    public func addHelpButtonToNavController() {
        let barButtonView = createBarButtonView()
        addHelpButton(to: barButtonView)
        addNotificationIndicatorView(to: barButtonView)
        addRightBarButtonItem(with: barButtonView)
    }

    // MARK: - helpers

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
        helpButton.setTitleColor(Constants.helpButtonTitleColor, for: .highlighted)
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

    // MARK: Badge settings

    private func addNotificationIndicatorView(to superView: UIView) {
        if WordPressAuthenticator.shared.configuration.supportNotificationIndicatorFeatureFlag == true {
            setupNotificationsIndicator()
            layoutNotificationIndicatorView(helpNotificationIndicator, to: superView)
        } else {
            setupBadge()
            layoutNotificationIndicatorView(helpBadge, to: superView)
        }
    }

    private func setupBadge() {
        helpBadge.isHidden = true
        NotificationCenter.default.addObserver(forName: .wordpressSupportBadgeUpdated, object: nil, queue: nil) { [weak self] _ in
            self?.refreshSupportBadge()
        }
    }

    private func setupNotificationsIndicator() {
        helpNotificationIndicator.isHidden = true

        NotificationCenter.default.addObserver(forName: .wordpressSupportNotificationReceived, object: nil, queue: nil) { [weak self] _ in
            self?.refreshSupportNotificationIndicator()
        }
        NotificationCenter.default.addObserver(forName: .wordpressSupportNotificationCleared, object: nil, queue: nil) { [weak self] _ in
            self?.refreshSupportNotificationIndicator()
        }
    }

    private func layoutNotificationIndicatorView(_ view: UIView, to superView: UIView) {
        superView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        let centerOffset = Constants.notificationIndicatorCenterOffset
        let xConstant = helpButton.contentEdgeInsets.top + centerOffset.x
        let yConstant = helpButton.contentEdgeInsets.top + centerOffset.y

        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: helpButton.trailingAnchor, constant: xConstant),
            view.centerYAnchor.constraint(equalTo: helpButton.topAnchor, constant: yConstant),
            view.widthAnchor.constraint(equalToConstant: Constants.notificationIndicatorSize.width),
            view.heightAnchor.constraint(equalToConstant: Constants.notificationIndicatorSize.height)
            ])
    }


    // MARK: - UIViewControllerTransitioningDelegate

    /// Displays the support vc.
    ///
    func displaySupportViewController(from source: WordPressSupportSourceTag) {
        guard let navigationController = navigationController else {
            fatalError()
        }

        WordPressAuthenticator.shared.delegate?.presentSupport(from: navigationController, sourceTag: source, options: [:])
    }
}
