import UIKit
import WordPressComAnalytics
import WordPressShared
import wpxmlrpc

class SigninAbstractViewController : UIViewController, SigninErrorViewControllerDelegate
{
    var helpBadge: WPNUXHelpBadgeLabel!
    var helpButton: UIButton!
    var loginFields = LoginFields()


    // MARK: - Lifecycle Methods


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad();

        WPStyleGuide.configureColorsForSigninView(view)

        setupBackgroundTapGestureRecognizer()
        setupCancelButtonIfNeeded()
        setupHelpButtonAndBadge()
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        HelpshiftUtils.refreshUnreadNotificationCount()
    }


    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }


    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .All : .Portrait
    }


    // MARK: Setup and Configuration


    ///
    ///
    func setupBackgroundTapGestureRecognizer() {
        let tgr = UITapGestureRecognizer(target: self, action: #selector(SigninAbstractViewController.handleBackgroundTapGesture(_:)))
        view.addGestureRecognizer(tgr)
    }


    ///
    ///
    func setupCancelButtonIfNeeded() {
        if !shouldShowCancelButton() {
            return
        }

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(SigninAbstractViewController.handleCancelButtonTapped(_:)))
        navigationItem.leftBarButtonItem = cancelButton
    }


    ///
    ///
    func setupHelpButtonAndBadge() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SigninAbstractViewController.handleHelpshiftUnreadCountUpdated(_:)), name: HelpshiftUnreadCountUpdatedNotification, object: nil)

        let buttonView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))

        helpButton = UIButton(type: .Custom)
        helpButton.setImage(UIImage(named: "btn-help"), forState: .Normal)
        helpButton.sizeToFit()
        helpButton.accessibilityLabel = NSLocalizedString("Help", comment: "Help button")
        helpButton.addTarget(self, action: #selector(SigninAbstractViewController.handleHelpButtonTapped(_:)), forControlEvents: .TouchUpInside)
        var frame = helpButton.frame
        frame.origin.x = buttonView.frame.width - frame.width
        frame.origin.y = (buttonView.frame.height - frame.height) / 2
        helpButton.frame = frame
        buttonView.addSubview(helpButton)

        helpBadge = WPNUXHelpBadgeLabel(frame: CGRect(x: (frame.origin.x + frame.width) - 6, y: frame.origin.y - 5, width: 12, height: 10))
        helpBadge.hidden = true
        buttonView.addSubview(helpBadge)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonView)
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
        let accountService = AccountService(managedObjectContext: context)

        return accountService.defaultWordPressComAccount() != nil || blogService.blogCountForAllAccounts() > 0
    }


    /// Display the specified error in a modal.
    ///
    /// - Parameters:
    ///     - error: An NSError instance
    ///
    func displayError(error: NSError) {
        let controller = SigninErrorViewController.controller()
        controller.presentFromController(self)
        controller.displayError(error, loginFields: loginFields, delegate: self)
    }


    ///
    ///
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }


    ///
    ///
    func openForgotPasswordURL() {
        let baseURL = loginFields.userIsDotCom ? "https://wordpress.com" : SigninHelpers.baseSiteURL(loginFields.siteUrl)
        let forgotPasswordURL = NSURL(string: baseURL + "/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F")!
        UIApplication.sharedApplication().openURL(forgotPasswordURL)
    }


    // MARK: - SigninErrorViewController Delegate Methods


    /// Displays the support vc.
    ///
    func displaySupportViewController() {
        let controller = SupportViewController()
        let navController = UINavigationController(rootViewController: controller)
        navController.navigationBar.translucent = false
        navController.modalPresentationStyle = .FormSheet

        navigationController?.presentViewController(navController, animated: true, completion: nil)
    }


    /// Displays the Helpshift conversation feature.
    ///
    func displayHelpshiftConversationView() {
        let metaData = [
            "Source": "Failed login",
            "Username": loginFields.username,
            "SiteURL": loginFields.siteUrl
        ]
        HelpshiftSupport.showConversation(self, withOptions: [HelpshiftSupportCustomMetadataKey: metaData])
        WPAppAnalytics.track(.SupportOpenedHelpshiftScreen)
    }


    /// Presents an instance of WPWebViewController set to the specified URl.
    /// Accepts a username and password if authentication is needed.
    ///
    /// - Parameters:
    ///     - url: The URL to view.
    ///     - username: Optional. A username if authentication is needed.
    ///     - password: Optional. A password if authentication is needed.
    ///
    func displayWebviewForURL(url: NSURL, username: String?, password: String?) {
        let controller = WPWebViewController(URL: url)

        if let username = username,
            password = password
        {
            controller.username = username
            controller.password = password
        }
        let navController = UINavigationController(rootViewController: controller)
        navigationController?.presentViewController(navController, animated: true, completion: nil)
    }


    // MARK: - Notifications


    /// Updates the badge count and its visibility.
    ///
    func handleHelpshiftUnreadCountUpdated(notification: NSNotification) {
        let count = HelpshiftUtils.unreadNotificationCount()
        helpBadge.text = "\(count)"
        helpBadge.hidden = (count == 0)
    }


    // MARK: - Actions


    func handleBackgroundTapGesture(tgr: UITapGestureRecognizer) {
        view.endEditing(true)
    }


    func handleCancelButtonTapped(sender: UIButton) {
        dismiss()
    }


    func handleHelpButtonTapped(sender: UIButton) {
        displaySupportViewController()
    }

}
