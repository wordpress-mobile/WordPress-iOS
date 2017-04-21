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
    fileprivate let blog: Blog

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
            usernameTextField.isEnabled = !isAuthenticating
            passwordTextField.isEnabled = !isAuthenticating
            verificationCodeTextField.isEnabled = !isAuthenticating
            signinButton.showActivityIndicator(isAuthenticating)
        }
    }

    /// Returns true if the blog has the proper version of Jetpack installed,
    /// otherwise false
    ///
    fileprivate var hasJetpack: Bool {
        guard let jetpack = blog.jetpack else {
            return false
        }
        return (jetpack.isInstalled() && jetpack.isUpdatedToRequiredVersion())
    }

    // MARK: - Initializers

    /// Required initializer for JetpackLoginViewController
    ///
    /// - Parameter blog: The current blog
    ///
    init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        preconditionFailure("Jetpack Login View Controller must be initialized by code")
    }

    // MARK: - LifeCycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WPStyleGuide.itsEverywhereGrey()
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
        descriptionLabel.font = WPNUXUtility.descriptionTextFont()
        descriptionLabel.textColor = WPStyleGuide.allTAllShadeGrey()

        usernameTextField.delegate = self
        usernameTextField.font = WPNUXUtility.textFieldFont()
        usernameTextField.placeholder = NSLocalizedString("WordPress.com username",
                                                               comment: "Username placeholder")
        passwordTextField.delegate = self
        passwordTextField.font = WPNUXUtility.textFieldFont()
        passwordTextField.placeholder = NSLocalizedString("WordPress.com password",
                                                               comment: "Password placeholder")
        verificationCodeTextField.delegate = self
        verificationCodeTextField.font = WPNUXUtility.textFieldFont()
        verificationCodeTextField.isHidden = true // Hidden by default
        verificationCodeTextField.placeholder = NSLocalizedString("Verification Code",
                                                                       comment: "Two factor code placeholder")
        signinButton.isEnabled = false

        setupSendSMSCodeButtonText()
        sendSMSCodeButton.isHidden = true // Hidden by default

        setupMoreInformationButtonText()
        moreInformationButton.isHidden = true // Hidden by default

        let title = NSLocalizedString("Install Jetpack", comment: "Title of a button for Jetpack Installation. The text " +
                "should be uppercase.").localizedUppercase
        installJetpackButton.setTitle(title, for: .normal)
        installJetpackButton.isHidden = true // Hidden by default
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

        if let titleLabel = sendSMSCodeButton.titleLabel {
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 3
        }

        sendSMSCodeButton.setAttributedTitle(attributedCode, for: UIControlState())
        sendSMSCodeButton.setAttributedTitle(attributedCodeHighlighted, for: .highlighted)
    }

    /// Configures the button text for requesting more information about jetpack.
    ///
    fileprivate func setupMoreInformationButtonText() {
        let string = NSLocalizedString("More information",
                                       comment: "Text used for a button to request more information.")

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: StyledHTMLAttributes = [ .BodyAttribute: [ NSFontAttributeName: UIFont.systemFont(ofSize: 14),
                                                                   NSForegroundColorAttributeName: WPStyleGuide.allTAllShadeGrey(),
                                                                   NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue as AnyObject,
                                                                   NSParagraphStyleAttributeName: paragraphStyle ]]

        let attributedCode = NSAttributedString.attributedStringWithHTML(string, attributes: attributes)
        let attributedCodeHighlighted = attributedCode.mutableCopy() as! NSMutableAttributedString
        attributedCodeHighlighted.applyForegroundColor(WPNUXUtility.confirmationLabelColor())

        if let titleLabel = sendSMSCodeButton.titleLabel {
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 3
        }

        moreInformationButton.setAttributedTitle(attributedCode, for: UIControlState())
        moreInformationButton.setAttributedTitle(attributedCodeHighlighted, for: .highlighted)
    }

    fileprivate func setupKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(hideKeyboard))

        scrollView.addGestureRecognizer(tap)
    }

    // MARK: - Textfield

    func registerForTextFieldNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldChanged(_ :)),
                                               name: .UITextFieldTextDidChange, object: usernameTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldChanged(_ :)),
                                               name: .UITextFieldTextDidChange, object: passwordTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldChanged(_ :)),
                                               name: .UITextFieldTextDidChange, object: verificationCodeTextField)
    }

    func deregisterFromTextFieldNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidChange, object: usernameTextField)
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidChange, object: passwordTextField)
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidChange, object: verificationCodeTextField)
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
        scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize!.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets

        guard let activeField = self.activeField else {
            return
        }
        var aRect: CGRect = view.frame
        aRect.size.height -= keyboardSize!.height
        if !aRect.contains(activeField.frame.origin) {
            scrollView.scrollRectToVisible(activeField.frame, animated: true)
        }
    }

    func keyboardWillBeHidden(_ notification: Notification) {
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
        scrollView.isScrollEnabled = false
    }

    // MARK: - UI Helpers

    fileprivate func reloadInterface() {
        updateMessage()
        updateControls()
    }

    fileprivate func updateMessage() {
        guard let jetPack = blog.jetpack else {
            return
        }

        var message: String

        if jetPack.isInstalled() {
            if jetPack.isUpdatedToRequiredVersion() {
                message = NSLocalizedString("Looks like you have Jetpack set up on your site. Congrats! \n" +
                                            "Sign in with your WordPress.com credentials below to enable " +
                                            "Stats and Notifications.",
                                            comment: "Message asking the user to sign into Jetpack with WordPress.com credentials")
            } else {
                message = String.localizedStringWithFormat(NSLocalizedString("Jetpack %@ or later is required " +
                                                                             "for stats. Do you want to update Jetpack?",
                                                                             comment: "Message stating the minimum required " +
                                                                             "version for Jetpack and asks the user " +
                                                                             "if they want to upgrade"), JetpackVersionMinimumRequired)
            }
        } else {
            message = NSLocalizedString("Jetpack is required for stats. Do you want to install Jetpack?",
                                        comment: "Message asking the user if they want to install Jetpack")
        }
        descriptionLabel.text = message
        descriptionLabel.sizeToFit()
    }

    fileprivate func updateControls() {
        usernameTextField.alpha = shouldDisplayMultifactor ? 0.5 : 1.0
        passwordTextField.alpha = shouldDisplayMultifactor ? 0.5 : 1.0
        verificationCodeTextField.alpha = shouldDisplayMultifactor ? 1.0 : 0.5

        usernameTextField.isEnabled = !shouldDisplayMultifactor
        passwordTextField.isEnabled = !shouldDisplayMultifactor
        verificationCodeTextField.isEnabled = shouldDisplayMultifactor

        usernameTextField.isHidden = !hasJetpack
        passwordTextField.isHidden = !hasJetpack

        installJetpackButton.isHidden = hasJetpack
        moreInformationButton.isHidden = hasJetpack

        if hasJetpack && shouldDisplayMultifactor {
            passwordTextField.returnKeyType = .next
            verificationCodeTextField.isHidden = false
            sendSMSCodeButton.isHidden = false
        } else {
            passwordTextField.returnKeyType = .done
            verificationCodeTextField.isHidden = true
            sendSMSCodeButton.isHidden = true
        }

        updateSignInButton()
    }

    fileprivate func updateSignInButton() {
        guard hasJetpack else {
            signinButton.isHidden = true
            return
        }

        var title = NSLocalizedString("Sign In", comment: "Title of a button for signing in. " +
                                                          "The text should be uppercase.").localizedUppercase
        if shouldDisplayMultifactor {
            title = NSLocalizedString("Verify", comment: "Title of a button for 2FA verification. The text " +
                                                         "should be uppercase.").localizedUppercase
        }
        signinButton.setTitle(title, for: .normal)

        if shouldDisplayMultifactor {
            guard let verifcationCodeText = verificationCodeTextField.text, !verifcationCodeText.isEmpty else {
                signinButton.isEnabled = false
                return
            }
        } else {
            guard let usernameText = usernameTextField.text, !usernameText.isEmpty else {
                signinButton.isEnabled = false
                return
            }
            guard let passwordText = passwordTextField.text, !passwordText.isEmpty else {
                signinButton.isEnabled = false
                return
            }
        }
        signinButton.isHidden = false
        signinButton.isEnabled = true
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
        view.endEditing(true)
    }

    // MARK: - Private Helpers

    fileprivate func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    fileprivate func handleSignInError(_ error: Error) {
        let error = error as NSError
        var userInfo = error.userInfo
        userInfo[WPErrorSupportSourceKey] = SupportSourceTag.jetpackLogin
        let errorWithSource = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
        WPError.showNetworkingAlertWithError(errorWithSource)
        updateControls()
    }

    fileprivate func prefillJetPackUsernameIfAvailible() {
        let blogService = BlogService(managedObjectContext: managedObjectContext())
        blogService.syncBlog(blog, success: {[weak self] () -> Void in
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
        isAuthenticating = true
        hideKeyboard()
        loginFields.userIsDotCom = true
        loginFields.username = usernameTextField.nonNilTrimmedText()
        loginFields.password = passwordTextField.nonNilTrimmedText()
        loginFields.multifactorCode = verificationCodeTextField.nonNilTrimmedText()
        loginFacade.signIn(with: loginFields)
    }

    fileprivate func sendSMSCode() {
        let message = NSLocalizedString("SMS Sent", comment: "One Time Code has been sent via SMS")
        loginFields.userIsDotCom = true
        loginFields.username = usernameTextField.nonNilTrimmedText()
        loginFields.password = passwordTextField.nonNilTrimmedText()
        loginFacade.requestOneTimeCode(with: loginFields)
        SVProgressHUD.showDismissibleSuccess(withStatus: message)
    }

    fileprivate func completeLogin() {
        isAuthenticating = false
        guard let completionBlock = self.completionBlock else {
            return
        }
        completionBlock(true)
    }

    // MARK: - Browser

    fileprivate func openInstallJetpackURL() {
        WPAppAnalytics.track(.selectedInstallJetpack)
        let targetURL = blog.adminUrl(withPath: jetpackInstallRelativePath)
        displayWebView(url: targetURL,
                            username: blog.usernameForSite,
                            password: blog.password,
                            wpLoginURL: URL(string: blog.loginUrl()))
    }

    fileprivate func openMoreInformationURL() {
        WPAppAnalytics.track(.selectedLearnMoreInConnectToJetpackScreen)
        displayWebView(url: jetpackMoreInformationURL, username: nil, password: nil, wpLoginURL: nil)
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
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            if verificationCodeTextField.isHidden {
                signIn()
            } else {
                verificationCodeTextField.becomeFirstResponder()
            }
        } else if textField == verificationCodeTextField {
            signIn()
        }
        return true
    }
}

// MARK: - LoginFacadeDelegate methods

extension JetpackLoginViewController : LoginFacadeDelegate {
    func displayRemoteError(_ error: Error!) {
        isAuthenticating = false
        handleSignInError(error)
    }

    func needsMultifactorCode() {
        WPAppAnalytics.track(.twoFactorCodeRequested)
        isAuthenticating = false
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
