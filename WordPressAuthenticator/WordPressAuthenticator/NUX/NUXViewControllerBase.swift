import Gridicons
import WordPressUI


/// base protocol for NUX view controllers
public protocol NUXViewControllerBase {
    var sourceTag: WordPressSupportSourceTag { get }
    var helpBadge: NUXHelpBadgeLabel { get }
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
    }

    /// Adds the Help Button to the nav controller
    ///
    public func addHelpButtonToNavController() {
        let helpButtonMarginSpacerWidth = CGFloat(-8)
        let helpBadgeSize = CGSize(width: 12, height: 12)
        let helpButtonContainerFrame = CGRect(x: 0, y: 0, width: 44, height: 44)

        NotificationCenter.default.addObserver(forName: .wordpressSupportBadgeUpdated, object: nil, queue: nil) { [weak self] _ in
            self?.refreshSupportBadge()
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
    func displaySupportViewController(from source: WordPressSupportSourceTag) {
        guard let navigationController = navigationController else {
            fatalError()
        }

        WordPressAuthenticator.shared.delegate?.presentSupport(from: navigationController, sourceTag: source, options: [:])
    }
}
