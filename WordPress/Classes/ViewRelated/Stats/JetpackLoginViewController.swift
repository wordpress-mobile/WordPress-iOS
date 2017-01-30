import Foundation
import UIKit
import WordPressShared
import WordPressComAnalytics

/// A view controller that presents a Jetpack login form
///
class JetpackLoginViewController: UIViewController {

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

    func setupControls() {
        self.passwordTextField.font = WPNUXUtility.descriptionTextFont()
        self.descriptionLabel.textColor = WPStyleGuide.allTAllShadeGrey()
        self.descriptionLabel.backgroundColor = UIColor.clear

        self.usernameTextField.delegate = self
        self.usernameTextField.backgroundColor = UIColor.white
        self.usernameTextField.placeholder = NSLocalizedString("WordPress.com username", comment: "Username placeholder")
        self.usernameTextField.font = WPNUXUtility.textFieldFont()
        self.usernameTextField.adjustsFontSizeToFitWidth = true
        self.usernameTextField.autocorrectionType = .no
        self.usernameTextField.autocapitalizationType = .none
        self.usernameTextField.clearButtonMode = .whileEditing
        self.verificationCodeTextField.returnKeyType = .next

        self.passwordTextField.delegate = self
        self.passwordTextField.backgroundColor = UIColor.white
        self.passwordTextField.placeholder = NSLocalizedString("WordPress.com password", comment: "Password placeholder")
        self.passwordTextField.font = WPNUXUtility.textFieldFont()
        self.passwordTextField.isSecureTextEntry = true
        self.passwordTextField.showSecureTextEntryToggle = true
        self.passwordTextField.showTopLineSeparator = true
        self.passwordTextField.returnKeyType = .done

        self.verificationCodeTextField.delegate = self
        self.verificationCodeTextField.backgroundColor = UIColor.white
        self.verificationCodeTextField.placeholder = NSLocalizedString("Verification Code", comment: "Two factor code placeholder")
        self.verificationCodeTextField.font = WPNUXUtility.textFieldFont()
        self.verificationCodeTextField.textAlignment = .center
        self.verificationCodeTextField.adjustsFontSizeToFitWidth = true
        self.verificationCodeTextField.keyboardType = .numberPad
        self.verificationCodeTextField.returnKeyType = .done
        self.verificationCodeTextField.showTopLineSeparator = true
        self.verificationCodeTextField.isHidden = true // Hidden by default

        self.signinButton.isEnabled = false
    }

    func setupKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(hideKeyboard))

        self.scrollView.addGestureRecognizer(tap)
    }


    // MARK: - Textfield

    func registerForTextFieldNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldChanged(_ :)), name: .UITextFieldTextDidChange, object: self.usernameTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldChanged(_ :)), name: .UITextFieldTextDidChange, object: self.passwordTextField)
    }

    func deregisterFromTextFieldNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidChange, object: self.usernameTextField)
        NotificationCenter.default.removeObserver(self, name: .UITextFieldTextDidChange, object: self.passwordTextField)
    }

    func textFieldChanged(_ notification: Foundation.Notification) {
        updateSignInButton()
    }


    // MARK: - Keyboard

    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_ :)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_ :)), name: .UIKeyboardWillHide, object: nil)
    }

    func deregisterFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

    func keyboardWillShow(_ notification: Foundation.Notification) {
        self.scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)
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
                message = NSLocalizedString("Looks like you have Jetpack set up on your site.\nCongrats!\nSign in with your WordPress.com credentials below to enable Stats and Notifications.", comment: "")
            } else {
                message = NSLocalizedString("Jetpack \(JetpackVersionMinimumRequired) or later is required for stats. Do you want to update Jetpack?", comment: "")
                //TODO: Enable upgrade Jetpack button?
            }
        } else {
            message = NSLocalizedString("Jetpack is required for stats. Do you want to install Jetpack?", comment: "")
            //TODO: Enable install Jetpack button?
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

        if self.hasJetpack && self.shouldDisplayMultifactor {
            self.passwordTextField.returnKeyType = .next
            self.verificationCodeTextField.isHidden = false
        } else {
            self.passwordTextField.returnKeyType = .done
            self.verificationCodeTextField.isHidden = true
        }

        updateSignInButton()
    }

    fileprivate func updateSignInButton() {
        var title = NSLocalizedString("Sign In", comment: "Title of a button for signing in. The text should be uppercase.").localizedUppercase

        if self.shouldDisplayMultifactor {
            title = NSLocalizedString("Verify", comment: "Title of a button for 2FA verification. The text should be uppercase.").localizedUppercase
        }
        self.signinButton.setTitle(title, for: .normal)

        guard let usernameText = self.usernameTextField.text, !usernameText.isEmpty else {
            self.signinButton.isEnabled = false
            return
        }
        guard let passwordText = self.passwordTextField.text, !passwordText.isEmpty else {
            self.signinButton.isEnabled = false
            return
        }
        self.signinButton.isEnabled = true
    }

    fileprivate func handleMultifactorCodeRequest() {
        shouldDisplayMultifactor = true
        UIView.animate(withDuration: WPAnimationDurationDefault, animations: { () -> Void in
            self.updateControls()
        },
        completion: { (success: Bool) -> Void in
            //noop
        })
    }

    func hideKeyboard() {
        self.view.endEditing(true)
    }


    // MARK: - Helpers

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
        guard let bService = blogService else {
            return
        }

        bService.syncBlog(self.blog, success: {[weak self] () -> () in
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

    fileprivate func completeLogin() {
        self.isAuthenticating = false
        guard let completionBlock = self.completionBlock else {
            return
        }
        completionBlock(true)
    }


    // MARK: - Actions

    @IBAction func didTouchSignInButton(_ sender: Any) {
        signIn()
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

            }, failure: { [weak self] (error: Error?) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.completeLogin()
            })

            }, failure: { [weak self] (error: Error?) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.completeLogin()
        })
    }
}
