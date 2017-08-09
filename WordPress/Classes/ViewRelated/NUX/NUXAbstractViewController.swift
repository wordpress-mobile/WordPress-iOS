import UIKit
import WordPressShared

/// A base class for the various NUX related related view controllers.
/// The base class sets up and configures common functionality, such as the help
/// button and badge.
/// It is assumed that NUX controllers will always be presented modally.
///
class NUXAbstractViewController: UIViewController, LoginSegueHandler {
    var helpBadge: WPNUXHelpBadgeLabel!
    var helpButton: UIButton!
    var loginFields = LoginFields()
    var restrictToWPCom = false

    let helpButtonMarginSpacerWidth = CGFloat(-8)
    let helpBadgeSize = CGSize(width: 12, height: 10)
    let helpButtonContainerFrame = CGRect(x: 0, y: 0, width: 44, height: 44)

    var dismissBlock: ((_ cancelled: Bool) -> Void)?

    enum SegueIdentifier: String {
        case showURLUsernamePassword
        case showSelfHostedLogin
        case showWPComLogin
        case startMagicLinkFlow
        case showMagicLink
        case showLinkMailView
        case show2FA
        case showEpilogue
    }

    /// The Helpshift tag to track the origin of user conversations
    ///
    var sourceTag: SupportSourceTag {
        get {
            return .generalLogin
        }
    }

    // MARK: - Lifecycle Methods


    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackgroundTapGestureRecognizer()
        setupCancelButtonIfNeeded()
        setupHelpButtonAndBadge()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        HelpshiftUtils.refreshUnreadNotificationCount()
    }


    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }


    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }


    // MARK: Setup and Configuration

    /// Sets up a gesture recognizer to detect taps on the view, but not its content.
    ///
    func setupBackgroundTapGestureRecognizer() {
        let tgr = UITapGestureRecognizer(target: self, action: #selector(NUXAbstractViewController.handleBackgroundTapGesture(_:)))
        view.addGestureRecognizer(tgr)
    }


    /// Sets up the cancel button for the navbar if its needed.
    /// The cancel button is only shown when its appropriate to dismiss the modal view controller.
    ///
    func setupCancelButtonIfNeeded() {
        if !shouldShowCancelButton() {
            return
        }

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(NUXAbstractViewController.handleCancelButtonTapped(_:)))
        navigationItem.leftBarButtonItem = cancelButton
    }


    /// Sets up the help button and the helpshift conversation badge.
    ///
    func setupHelpButtonAndBadge() {
        NotificationCenter.default.addObserver(self, selector: #selector(NUXAbstractViewController.handleHelpshiftUnreadCountUpdated(_:)), name: NSNotification.Name.HelpshiftUnreadCountUpdated, object: nil)

        let customView = UIView(frame: helpButtonContainerFrame)

        helpButton = UIButton(type: .custom)
        helpButton.setImage(UIImage(named: "btn-help"), for: UIControlState())
        helpButton.sizeToFit()
        helpButton.accessibilityLabel = NSLocalizedString("Help", comment: "Help button")
        helpButton.addTarget(self, action: #selector(NUXAbstractViewController.handleHelpButtonTapped(_:)), for: .touchUpInside)

        customView.addSubview(helpButton)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        helpButton.trailingAnchor.constraint(equalTo: customView.trailingAnchor).isActive = true
        helpButton.centerYAnchor.constraint(equalTo: customView.centerYAnchor).isActive = true

        helpBadge = WPNUXHelpBadgeLabel()
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


    // MARK: - Instance Methods


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
    }


    func handleHelpButtonTapped(_ sender: UIButton) {
        displaySupportViewController(sourceTag: sourceTag)
    }
}

extension NUXAbstractViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presented is FancyAlertViewController {
            return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
        }

        return nil
    }
}
