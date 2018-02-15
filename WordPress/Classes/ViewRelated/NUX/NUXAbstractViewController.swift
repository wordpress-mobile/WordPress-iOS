import UIKit
import WordPressShared
import Gridicons

protocol LoginWithLogoAndHelpViewController {
    func addWordPressLogoToNavController()
    func handleHelpButtonTapped(_ sender: AnyObject)
    func displaySupportViewController(from source: WordPressSupportSourceTag)
    func handleHelpshiftUnreadCountUpdated(_ notification: Foundation.Notification)
}

extension LoginWithLogoAndHelpViewController where Self: UIViewController {
    func addWordPressLogoToNavController() {
        let image = Gridicon.iconOfType(.mySites)
        let imageView = UIImageView(image: image.imageWithTintColor(UIColor.white))
        navigationItem.titleView = imageView
    }

    /// Displays the support vc.
    ///
    func displaySupportViewController(from source: WordPressSupportSourceTag) {
        guard let supportViewController = WordPressAuthenticator.shared.delegate?.supportViewController(from: source) else {
            fatalError()
        }

        navigationController?.present(supportViewController, animated: true, completion: nil)
    }
}


/// A base class for the various NUX related related view controllers.
/// The base class sets up and configures common functionality, such as the help
/// button and badge.
/// It is assumed that NUX controllers will always be presented modally.
///
class NUXAbstractViewController: UIViewController, NUXSegueHandler, LoginWithLogoAndHelpViewController {
    @objc var helpBadge: NUXHelpBadgeLabel!
    @objc var helpButton: UIButton!
    @objc var loginFields = LoginFields()
    @objc var restrictToWPCom = false

    @objc let helpButtonMarginSpacerWidth = CGFloat(-8)
    @objc let helpBadgeSize = CGSize(width: 12, height: 12)
    @objc let helpButtonContainerFrame = CGRect(x: 0, y: 0, width: 44, height: 44)

    @objc var dismissBlock: ((_ cancelled: Bool) -> Void)?

    /// Indicates if the Help Button should be displayed, or not.
    ///
    var shouldDisplayHelpButton: Bool {
        return WordPressAuthenticator.shared.delegate?.supportActionEnabled ?? false
    }

    /// SegueIdentifier
    ///
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
        case showCreateSite
    }

    /// The Helpshift tag to track the origin of user conversations
    ///
    var sourceTag: WordPressSupportSourceTag {
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
        setupHelpButtonAndBadgeIfNeeded()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        WordPressAuthenticator.shared.delegate?.refreshHelpshiftUnreadCount()
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
    @objc func setupBackgroundTapGestureRecognizer() {
        let tgr = UITapGestureRecognizer(target: self, action: #selector(NUXAbstractViewController.handleBackgroundTapGesture(_:)))
        view.addGestureRecognizer(tgr)
    }


    /// Sets up the cancel button for the navbar if its needed.
    /// The cancel button is only shown when its appropriate to dismiss the modal view controller.
    ///
    @objc func setupCancelButtonIfNeeded() {
        if !shouldShowCancelButton() {
            return
        }

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(NUXAbstractViewController.handleCancelButtonTapped(_:)))
        navigationItem.leftBarButtonItem = cancelButton
    }

    /// Attaches the Help Button, when the WordPressAuthenticationDelegate says we should!
    ///
    @objc func setupHelpButtonAndBadgeIfNeeded() {
        guard shouldDisplayHelpButton else {
            return
        }

        setupHelpButtonAndBadge()
    }

    /// Sets up the help button and the helpshift conversation badge.
    ///
    /// - Note: this is only used in the old single-page signup screen and can be removed once that screen is gone.
    ///
    private func setupHelpButtonAndBadge() {
        NotificationCenter.default.addObserver(self, selector: #selector(NUXAbstractViewController.handleHelpshiftUnreadCountUpdated(_:)), name: NSNotification.Name.HelpshiftUnreadCountUpdated, object: nil)

        let customView = UIView(frame: helpButtonContainerFrame)

        helpButton = UIButton(type: .custom)
        helpButton.setImage(UIImage(named: "btn-help"), for: UIControlState())
        helpButton.sizeToFit()
        helpButton.accessibilityLabel = NSLocalizedString("Help", comment: "Help button")
        helpButton.on(.touchUpInside) { [weak self](control: UIControl) in
            guard let helpButton = control as? UIButton else {
                return
            }
            self?.handleHelpButtonTapped(helpButton)
        }

        customView.addSubview(helpButton)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        helpButton.leadingAnchor.constraint(equalTo: customView.leadingAnchor).isActive = true
        helpButton.trailingAnchor.constraint(equalTo: customView.trailingAnchor).isActive = true
        helpButton.topAnchor.constraint(equalTo: customView.topAnchor).isActive = true
        helpButton.bottomAnchor.constraint(equalTo: customView.bottomAnchor).isActive = true

        helpBadge = NUXHelpBadgeLabel()
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
    @objc func shouldShowCancelButton() -> Bool {
        return isCancellable() && navigationController?.viewControllers.first == self
    }


    /// Checks if the signin vc modal should be cancellable. The controller is
    /// cancellable when there is a default wpcom account, or at least one
    /// self-hosted blog.
    ///
    /// - Returns: True if cancellable. False otherwise.
    ///
    @objc func isCancellable() -> Bool {
        // if there is an existing blog, or an existing account return true.
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        return AccountHelper.isDotcomAvailable() || blogService.blogCountForAllAccounts() > 0
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
    func displayErrorAlert(_ message: String, sourceTag: WordPressSupportSourceTag) {
        let presentingController = navigationController ?? self
        let controller = FancyAlertViewController.alertForGenericErrorMessageWithHelpshiftButton(message, loginFields: loginFields, sourceTag: sourceTag)
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self
        presentingController.present(controller, animated: true, completion: nil)
    }

    /// It is assumed that NUX view controllers are always presented modally.
    ///
    @objc func dismiss() {
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
    @objc func handleHelpshiftUnreadCountUpdated(_ notification: Foundation.Notification) {
        let count = WordPressAuthenticator.shared.delegate?.helpshiftUnreadCount ?? 0
        helpBadge.text = "\(count)"
        helpBadge.isHidden = (count == 0)
    }


    // MARK: - Actions


    @objc func handleBackgroundTapGesture(_ tgr: UITapGestureRecognizer) {
        view.endEditing(true)
    }


    @objc func handleCancelButtonTapped(_ sender: UIButton) {
        dismiss(cancelled: true)
        NotificationCenter.default.post(name: .wordpressLoginCancelled, object: nil)
    }

    // Handle the help button being tapped
    //
    func handleHelpButtonTapped(_ sender: AnyObject) {
        displaySupportViewController(from: sourceTag)
    }
}

extension NUXAbstractViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
