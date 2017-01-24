import Foundation
import UIKit
import WordPressShared
import WordPressComAnalytics

/// A view controller that presents a Jetpack login form
///
class JetpackLoginViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet fileprivate weak var jetpackImage: UIImageView!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    @IBOutlet fileprivate weak var usernameTextField: WPWalkthroughTextField!
    @IBOutlet fileprivate weak var passwordTextField: WPWalkthroughTextField!
    @IBOutlet fileprivate weak var verificationCodeTextField: WPWalkthroughTextField!
    @IBOutlet fileprivate weak var scrollView: UIScrollView!
    @IBOutlet fileprivate weak var signinButton: WPNUXMainButton!

    fileprivate var blog: Blog!
    fileprivate var activeField: UITextField?
    fileprivate var shouldDisplayMultifactor = false

    /// Returns true if the blog has the proper version of Jetpack installed
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
        checkForJetpack()
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
        //TODO: Complete the NSLocalized string comments
        self.passwordTextField.font = WPNUXUtility.descriptionTextFont()
        self.descriptionLabel.textColor = WPStyleGuide.allTAllShadeGrey()
        self.descriptionLabel.backgroundColor = UIColor.clear

        self.usernameTextField.delegate = self
        self.usernameTextField.backgroundColor = UIColor.white
        self.usernameTextField.placeholder = NSLocalizedString("WordPress.com username", comment: "")
        self.usernameTextField.font = WPNUXUtility.textFieldFont()
        self.usernameTextField.adjustsFontSizeToFitWidth = true
        self.usernameTextField.autocorrectionType = .no
        self.usernameTextField.autocapitalizationType = .none
        self.usernameTextField.clearButtonMode = .whileEditing
        self.verificationCodeTextField.returnKeyType = .next

        self.passwordTextField.delegate = self
        self.passwordTextField.backgroundColor = UIColor.white
        self.passwordTextField.placeholder = NSLocalizedString("WordPress.com password", comment: "")
        self.passwordTextField.font = WPNUXUtility.textFieldFont()
        self.passwordTextField.isSecureTextEntry = true
        self.passwordTextField.showSecureTextEntryToggle = true
        self.passwordTextField.clearsOnBeginEditing = true
        self.passwordTextField.showTopLineSeparator = true
        self.passwordTextField.returnKeyType = .next

        self.verificationCodeTextField.delegate = self
        self.verificationCodeTextField.backgroundColor = UIColor.white
        self.verificationCodeTextField.placeholder = NSLocalizedString("Verification Code", comment: "")
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

    func reloadInterface() {
        updateMessage()
        updateControls()
        updateSignInButton()
    }

    func updateMessage() {
        guard let jetPack = self.blog.jetpack else {
            return
        }

        var message: String

        if jetPack.isInstalled() {
            //TODO: Complete the NSLocalized string comments
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

    func updateControls() {
        //TODO: This!
    }

    func checkForJetpack() {
        //TODO: This!
    }

    func updateSignInButton() {
        //TODO: Complete the NSLocalized string comments
        var title = NSLocalizedString("Sign In", comment: "")
        if self.shouldDisplayMultifactor {
            title = NSLocalizedString("Verify", comment:"")
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

    func hideKeyboard() {
        self.view.endEditing(true)
    }


    // MARK: - Actions

    @IBAction func didTouchSignInButton(_ sender: Any) {
        hideKeyboard()
        self.usernameTextField.isEnabled = false
        self.passwordTextField.isEnabled = false
        self.signinButton.showActivityIndicator(true)
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
            self.verificationCodeTextField.becomeFirstResponder()
        } else if textField == self.verificationCodeTextField {
            hideKeyboard()
            //TODO: Login!
        }
        return true
    }
}
