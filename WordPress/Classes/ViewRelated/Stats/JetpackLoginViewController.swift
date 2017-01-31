import Foundation
import UIKit
import SVProgressHUD
import WordPressShared
import WordPressComAnalytics

/// A view controller that presents a Jetpack login form
///
class JetpackLoginViewController: UIViewController {

    // MARK: - Constants

    fileprivate let jetpackInstallRelativePath = "plugin-install.php?tab=plugin-information&plugin=jetpack"
    fileprivate let jetpackMoreInformationURL = "https://apps.wordpress.com/support/#faq-ios-15"

    // MARK: - Properties

    typealias CompletionBlock = (Bool) -> Void
    /// This completion handler closure is executed when the authentication process handled
    /// by this VC is completed.
    ///
    open var completionBlock: CompletionBlock?

    @IBOutlet fileprivate weak var jetpackImage: UIImageView!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    @IBOutlet fileprivate weak var usernameTextField: WPWalkthroughTextField!
    @IBOutlet fileprivate weak var passwordTextField: WPWalkthroughTextField!
    @IBOutlet fileprivate weak var verificationCodeTextField: WPWalkthroughTextField!
    @IBOutlet fileprivate weak var scrollView: UIScrollView!
    @IBOutlet fileprivate weak var signinButton: WPNUXMainButton!
    @IBOutlet fileprivate weak var sendSMSCodeButton: UIButton!
    @IBOutlet fileprivate weak var installJetpackButton: WPNUXMainButton!
    @IBOutlet fileprivate weak var moreInformationButton: UIButton!

    fileprivate var blog: Blog!
    fileprivate var activeField: UITextField?
    fileprivate var shouldDisplayMultifactor: Bool = false
    fileprivate var loginFields = LoginFields()

    fileprivate lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()

    /// Returns true if this VC is currently authenticating with the server.
    /// After setting, the UI controls will be updated accordingly
    ///
    fileprivate var isAuthenticating: Bool = false {
        didSet {
            self.usernameTextField.isEnabled = !self.isAuthenticating
            self.passwordTextField.isEnabled = !self.isAuthenticating
            self.verificationCodeTextField.isEnabled = !self.isAuthenticating
            self.signinButton.showActivityIndicator(self.isAuthenticating)
        }
    }

    /// Returns true if the blog has the proper version of Jetpack installed,
    /// otherwise false
    ///
    fileprivate var hasJetpack: Bool {
        guard let jetpack = self.blog.jetpack else {
            return false
        }
        return (jetpack.isInstalled() && jetpack.isUpdatedToRequiredVersion())
    }

    // MARK: - Initializers

    /// Preferred initializer for JetpackLoginViewController
    ///
    /// - Parameter blog: The current blog
    ///
    convenience init(blog: Blog) {
        self.init()
        self.blog = blog
    }

    // MARK: - LifeCycle Methods

    override func viewDidLoad() {
        assert(self.blog != nil)
        super.viewDidLoad()
        self.view.backgroundColor = WPStyleGuide.itsEverywhereGrey()
        setupControls()
        setupKeyboard()
    }

    override func viewDidLayoutSubviews() {
        reloadInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardNotifications()
        registerForTextFieldNotifications()
        prefillJetPackUsernameIfAvailible()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterFromKeyboardNotifications()
        deregisterFromTextFieldNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Configuration

    /// One time setup of the form textfields and buttons
    ///
    fileprivate func setupControls() {
        self.descriptionLabel.font = WPNUXUtility.descriptionTextFont()
        self.descriptionLabel.textColor = WPStyleGuide.allTAllShadeGrey()

        self.usernameTextField.delegate = self
        self.usernameTextField.font = WPNUXUtility.textFieldFont()
        self.usernameTextField.placeholder = NSLocalizedString("WordPress.com username",
                                                               comment: "Username placeholder")

        self.passwordTextField.delegate = self
        self.passwordTextField.font = WPNUXUtility.textFieldFont()
        self.passwordTextField.placeholder = NSLocalizedString("WordPress.com password",
                                                               comment: "Password placeholder")

        self.verificationCodeTextField.delegate = self
        self.verificationCodeTextField.font = WPNUXUtility.textFieldFont()
        self.verificationCodeTextField.isHidden = true // Hidden by default
        self.verificationCodeTextField.placeholder = NSLocalizedString("Verification Code",
                                                                       comment: "Two factor code placeholder")
        self.signinButton.isEnabled = false

        setupSendSMSCodeButtonText()
        self.sendSMSCodeButton.isHidden = true // Hidden by default

        setupMoreInformationButtonText()
        self.moreInformationButton.isHidden = true // Hidden by default

        let title = NSLocalizedString("Install Jetpack", comment: "Title of a button for Jetpack Installation. The text " +
                "should be uppercase.").localizedUppercase
        self.installJetpackButton.setTitle(title, for: .normal)
        self.installJetpackButton.isHidden = true // Hidden by default
    }

    /// Configures the button text that requests a 2fa code be sent via SMS.
    ///
    fileprivate func setupSendSMSCodeButtonText() {
        let string = NSLocalizedString("Enter the code on your authenticator app or <u>send the code via text message</u>.",
                                       comment: "Message displayed when a verification code is needed")

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: StyledHTMLAttributes = [ .BodyAttribute: [ NSFontAttributeName: UIFont.systemFont(ofSize: 14),
                                                                   NSForegroundColorAttributeName: WPStyleGuide.allTAllShadeGrey(),
                                                                   NSParagraphStyleAttributeName: paragraphStyle ]]

        let attributedCode = NSAttributedString.attributedStringWithHTML(string, attributes: attributes)
        let attributedCodeHighlighted = attributedCode.mutableCopy() as! NSMutableAttributedString
        attributedCodeHighlighted.applyForegroundColor(WPNUXUtility.confirmationLabelColor())

        if let titleLabel = self.sendSMSCodeButton.titleLabel {
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 3
        }

        self.sendSMSCodeButton.setAttributedTitle(attributedCode, for: UIControlState())
        self.sendSMSCodeButton.setAttributedTitle(attributedCodeHighlighted, for: .highlighted)
    }

    /// Configures the button text for requesting more information about jetpack.
    ///
    fileprivate func setupMoreInformationButtonText() {
        let string = NSLocalizedString("<u>More information</u>",
                                       comment: "Text used for a button to request more information.")

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: StyledHTMLAttributes = [ .BodyAttribute: [ NSFontAttributeName: UIFont.systemFont(ofSize: 14),
                                                                   NSForegroundColorAttributeName: WPStyleGuide.allTAllShadeGrey(),
                                                                   NSParagraphStyleAttributeName: paragraphStyle ]]

        let attributedCode = NSAttributedString.attributedStringWithHTML(string, attributes: attributes)
        let attributedCodeHighlighted = attributedCode.mutableCopy() as! NSMutableAttributedString
        attributedCodeHighlighted.applyForegroundColor(WPNUXUtility.confirmationLabelColor())

        if let titleLabel = self.sendSMSCodeButton.titleLabel {
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 3
        }

        self.moreInformationButton.setAttributedTitle(attributedCode, for: UIControlState())
        self.moreInformationButton.setAttributedTitle(attributedCodeHighlighted, for: .highlighted)
    }

    fileprivate func setupKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(hideKeyboard))

        self.scrollView.addGestureRecognizer(tap)
    }

    // MARK: - Textfield

    func registerForTextFieldNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldChanged(_ :)),
                                               name: .UITextFieldTextDidChange, object: self.usernameTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldChanged(_ :)),
                                               name: .UITextFieldTextDidChange, object: self.passwordTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldChanged(_ :)),
                                               name: .UITextFieldTextDidChange, object: self.verificationCodeTextField)
    }

    func deregisterFromTextFieldNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidChange, object: self.usernameTextField)
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidChange, object: self.passwordTextField)
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidChange, object: self.verificationCodeTextField)
    }

    func textFieldChanged(_ notification: Foundation.Notification) {
        updateSignInButton()
    }

    // MARK: - Keyboard

    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_ :)),
                                               name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_ :)),
                                               name: .UIKeyboardWillHide, object: nil)
    }

    func deregisterFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

    func keyboardWillShow(_ notification: Foundation.Notification) {
        self.scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize!.height, right: 0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets

        guard let activeField = self.activeField else {
            return
        }
        var aRect: CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if !aRect.contains(activeField.frame.origin) {
            self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
        }
    }

    func keyboardWillBeHidden(_ notification: Foundation.Notification) {
        self.scrollView.contentInset = UIEdgeInsets.zero
        self.scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
        self.scrollView.isScrollEnabled = false
    }

    // MARK: - UI Helpers

    fileprivate func reloadInterface() {
        updateMessage()
        updateControls()
    }

    fileprivate func updateMessage() {
        guard let jetPack = self.blog.jetpack else {
            return
        }

        var message: String

        if jetPack.isInstalled() {
            if jetPack.isUpdatedToRequiredVersion() {
                message = NSLocalizedString("Looks like you have Jetpack set up on your site.\nCongrats!\n" +
                                            "Sign in with your WordPress.com credentials below to enable " +
                                            "Stats and Notifications.", comment: "")
            } else {
                message = NSLocalizedString("Jetpack \(JetpackVersionMinimumRequired) or later is required " +
                                            "for stats. Do you want to update Jetpack?", comment: "")
            }
        } else {
            message = NSLocalizedString("Jetpack is required for stats. Do you want to install Jetpack?", comment: "")
        }
        self.descriptionLabel.text = message
        self.descriptionLabel.sizeToFit()
    }

    fileprivate func updateControls() {
        self.usernameTextField.alpha = self.shouldDisplayMultifactor ? 0.5 : 1.0
        self.passwordTextField.alpha = self.shouldDisplayMultifactor ? 0.5 : 1.0
        self.verificationCodeTextField.alpha = self.shouldDisplayMultifactor ? 1.0 : 0.5

        self.usernameTextField.isEnabled = !self.shouldDisplayMultifactor
        self.passwordTextField.isEnabled = !self.shouldDisplayMultifactor
        self.verificationCodeTextField.isEnabled = self.shouldDisplayMultifactor

        self.usernameTextField.isHidden = !self.hasJetpack
        self.passwordTextField.isHidden = !self.hasJetpack

        self.installJetpackButton.isHidden = self.hasJetpack
        self.moreInformationButton.isHidden = self.hasJetpack

        if self.hasJetpack && self.shouldDisplayMultifactor {
            self.passwordTextField.returnKeyType = .next
            self.verificationCodeTextField.isHidden = false
            self.sendSMSCodeButton.isHidden = false
        } else {
            self.passwordTextField.returnKeyType = .done
            self.verificationCodeTextField.isHidden = true
            self.sendSMSCodeButton.isHidden = true
        }

        updateSignInButton()
    }

    fileprivate func updateSignInButton() {
        guard self.hasJetpack else {
            self.signinButton.isHidden = true
            return
        }

        var title = NSLocalizedString("Sign In", comment: "Title of a button for signing in. " +
                                                          "The text should be uppercase.").localizedUppercase
        if self.shouldDisplayMultifactor {
            title = NSLocalizedString("Verify", comment: "Title of a button for 2FA verification. The text " +
                                                         "should be uppercase.").localizedUppercase
        }
        self.signinButton.setTitle(title, for: .normal)

        if self.shouldDisplayMultifactor {
            guard let verifcationCodeText = self.verificationCodeTextField.text, !verifcationCodeText.isEmpty else {
                self.signinButton.isEnabled = false
                return
            }
        } else {
            guard let usernameText = self.usernameTextField.text, !usernameText.isEmpty else {
                self.signinButton.isEnabled = false
                return
            }
            guard let passwordText = self.passwordTextField.text, !passwordText.isEmpty else {
                self.signinButton.isEnabled = false
                return
            }
        }
        self.signinButton.isHidden = false
        self.signinButton.isEnabled = true
    }

    fileprivate func handleMultifactorCodeRequest() {
        shouldDisplayMultifactor = true
        UIView.animate(withDuration: WPAnimationDurationDefault, animations: { () -> Void in
            self.updateControls()
        },
        completion: { (_) -> Void in
            //noop
        })
    }

    func hideKeyboard() {
        self.view.endEditing(true)
    }

    // MARK: - Private Helpers

    fileprivate func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    fileprivate func handleSignInError(_ error: Error) {
        let error = error as NSError
        WPError.showNetworkingAlertWithError(error)
        updateControls()
    }

    fileprivate func prefillJetPackUsernameIfAvailible() {
        let blogService = BlogService(managedObjectContext: managedObjectContext())
        blogService.syncBlog(self.blog, success: {[weak self] () -> Void in
                              guard let strongSelf = self, let jetpack = strongSelf.blog.jetpack else {
                                  return
                              }
                              if jetpack.isInstalled() && jetpack.isConnected() {
                                  strongSelf.usernameTextField.text = jetpack.connectedUsername
                              }
                              strongSelf.reloadInterface()
                          },
                          failure: { (error: Error) in
                              WPError.showNetworkingAlertWithError(error)
                          })
    }

    fileprivate func signIn() {
        self.isAuthenticating = true
        hideKeyboard()
        loginFields.userIsDotCom = true
        loginFields.username = self.usernameTextField.nonNilTrimmedText()
        loginFields.password = self.passwordTextField.nonNilTrimmedText()
        loginFields.multifactorCode = self.verificationCodeTextField.nonNilTrimmedText()
        self.loginFacade.signIn(with: self.loginFields)
    }

    fileprivate func sendSMSCode() {
        let message = NSLocalizedString("SMS Sent", comment: "One Time Code has been sent via SMS")
        loginFields.userIsDotCom = true
        loginFields.username = self.usernameTextField.nonNilTrimmedText()
        loginFields.password = self.passwordTextField.nonNilTrimmedText()
        loginFacade.requestOneTimeCode(with: loginFields)
        SVProgressHUD.showSuccess(withStatus: message)
    }

    fileprivate func completeLogin() {
        self.isAuthenticating = false
        guard let completionBlock = self.completionBlock else {
            return
        }
        completionBlock(true)
    }

    // MARK: - Browser

    fileprivate func openInstallJetpackURL() {
        WPAppAnalytics.track(.selectedInstallJetpack)
        let targetURL = self.blog.adminUrl(withPath: self.jetpackInstallRelativePath)
        self.displayWebView(url: targetURL,
                            username: self.blog.usernameForSite!,
                            password: self.blog.password!,
                            wpLoginURL: URL(string: self.blog.loginUrl()))
    }

    fileprivate func openMoreInformationURL() {
        WPAppAnalytics.track(.selectedLearnMoreInConnectToJetpackScreen)
        self.displayWebView(url: self.jetpackMoreInformationURL, username: nil, password: nil, wpLoginURL: nil)
    }

    fileprivate func displayWebView(url: String, username: String?, password: String?, wpLoginURL: URL?) {
        guard let url =  URL(string: url) else {
            return
        }
        guard let webViewController = WPWebViewController(url: url) else {
            return
        }

        webViewController.username = username
        webViewController.password = password
        webViewController.wpLoginURL = wpLoginURL

        if presentingViewController != nil {
            navigationController?.pushViewController(webViewController, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: webViewController)
            navController.modalPresentationStyle = .pageSheet
            present(navController, animated: true, completion: nil)
        }
    }

    // MARK: - Actions

    @IBAction func didTouchSignInButton(_ sender: Any) {
        signIn()
    }

    @IBAction func didTouchSendSMSCodeButton(_ sender: Any) {
        sendSMSCode()
    }

    @IBAction func didTouchInstallJetpackButton(_ sender: Any) {
        openInstallJetpackURL()
    }

    @IBAction func didTouchMoreInformationButton(_ sender: Any) {
        openMoreInformationURL()
    }
}

// MARK: - UITextViewDelegate methods

extension JetpackLoginViewController : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.usernameTextField {
            self.passwordTextField.becomeFirstResponder()
        } else if textField == self.passwordTextField {
            if self.verificationCodeTextField.isHidden {
                signIn()
            } else {
                self.verificationCodeTextField.becomeFirstResponder()
            }
        } else if textField == self.verificationCodeTextField {
            signIn()
        }
        return true
    }
}

// MARK: - LoginFacadeDelegate methods

extension JetpackLoginViewController : LoginFacadeDelegate {
    func displayRemoteError(_ error: Error!) {
        self.isAuthenticating = false
        handleSignInError(error)
    }

    func needsMultifactorCode() {
        WPAppAnalytics.track(.twoFactorCodeRequested)
        self.isAuthenticating = false
        handleMultifactorCodeRequest()
    }

    func finishedLogin(withUsername username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        let accountFacade = AccountServiceFacade()
        let account = accountFacade.createOrUpdateWordPressComAccount(withUsername: username, authToken: authToken)
        accountFacade.setDefaultWordPressComAccount(account)
        BlogSyncFacade().syncBlogs(for: account, success: { [weak self] in
            accountFacade.updateUserDetails(for: account, success: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.completeLogin()

            }, failure: { [weak self] (_) in
                guard let strongSelf = self else { return }
                strongSelf.completeLogin()
            })

            }, failure: { [weak self] (_) in
                guard let strongSelf = self else { return }
                strongSelf.completeLogin()
        })
    }
}
