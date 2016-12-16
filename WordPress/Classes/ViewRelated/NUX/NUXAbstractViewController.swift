import UIKit
import WordPressComAnalytics
import WordPressShared

/// A base class for the various NUX related related view controllers.
/// The base class sets up and configures common functionality, such as the help
/// button and badge.
/// It is assumed that NUX controllers will always be presented modally.
///
class NUXAbstractViewController : UIViewController
{
    var helpBadge: WPNUXHelpBadgeLabel!
    var helpButton: UIButton!
    var loginFields = LoginFields()

    let helpButtonMarginSpacerWidth = CGFloat(-8)
    let helpBadgeSize = CGSize(width: 12, height: 10)
    let helpButtonContainerFrame = CGRect(x: 0, y: 0, width: 44, height: 44)

    var dismissBlock: ((_ cancelled: Bool) -> Void)?

    // MARK: - Lifecycle Methods


    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColorsForSigninView(view)

        setupBackgroundTapGestureRecognizer()
        setupCancelButtonIfNeeded()
        setupHelpButtonAndBadge()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        HelpshiftUtils.refreshUnreadNotificationCount()
    }


    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }


    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
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

        var frame = helpButton.frame
        frame.origin.x = helpButtonContainerFrame.width - frame.width
        frame.origin.y = (helpButtonContainerFrame.height - frame.height) / 2
        helpButton.frame = frame
        customView.addSubview(helpButton)

        let badgeFrame = CGRect(
            x: frame.maxX - (helpBadgeSize.width / 2),
            y: frame.minY - (helpBadgeSize.height / 2),
            width: helpBadgeSize.width,
            height: helpBadgeSize.height
        )
        helpBadge = WPNUXHelpBadgeLabel(frame: badgeFrame)
        helpBadge.isHidden = true
        customView.addSubview(helpBadge)

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

        return AccountHelper.isDotcomAvailable() || blogService!.blogCountForAllAccounts() > 0
    }


    /// Display the specified error in a modal.
    ///
    /// - Parameter error: An NSError instance
    ///
    func displayError(_ error: NSError) {
        let presentingController = navigationController ?? self
        let controller = SigninErrorViewController.controller()
        controller.presentFromController(presentingController)
        controller.displayError(error, loginFields: loginFields, delegate: self)
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
        displaySupportViewController()
    }

}


extension NUXAbstractViewController : SigninErrorViewControllerDelegate
{

    /// Displays the support vc.
    ///
    func displaySupportViewController() {
        let controller = SupportViewController()
        let navController = UINavigationController(rootViewController: controller)
        navController.navigationBar.isTranslucent = false
        navController.modalPresentationStyle = .formSheet

        navigationController?.present(navController, animated: true, completion: nil)
    }


    /// Displays the Helpshift conversation feature.
    ///
    func displayHelpshiftConversationView() {
        let metaData = [
            "Source": "Failed login",
            "Username": loginFields.username,
            "SiteURL": loginFields.siteUrl
        ]
        HelpshiftSupport.showConversation(self, withOptions: [HelpshiftSupportCustomMetadataKey: metaData, "showSearchOnNewConversation": "YES"])
        WPAppAnalytics.track(.supportOpenedHelpshiftScreen)
    }


    /// Presents an instance of WPWebViewController set to the specified URl.
    /// Accepts a username and password if authentication is needed.
    ///
    /// - Parameters:
    ///     - url: The URL to view.
    ///     - username: Optional. A username if authentication is needed.
    ///     - password: Optional. A password if authentication is needed.
    ///
    func displayWebviewForURL(_ url: URL, username: String?, password: String?) {
        let controller = WPWebViewController(url: url)

        if let username = username,
            let password = password
        {
            controller?.username = username
            controller?.password = password
        }
        let navController = UINavigationController(rootViewController: controller!)
        navigationController?.present(navController, animated: true, completion: nil)
    }

}
