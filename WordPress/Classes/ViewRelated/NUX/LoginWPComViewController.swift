import UIKit

class LoginWPComViewController: SigninWPComViewController, LoginViewController {
    @IBOutlet var emailLabel: UILabel?

    // let the storyboard's style stay
    override func setupStyles() {}

    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarIcon()
        usernameField.isHidden = true
        selfHostedButton.isHidden = true
    }
    
    override func configureTextFields() {
        super.configureTextFields()
        passwordField.textInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        emailLabel?.text = usernameField.text
    }

    override func needsMultifactorCode() {
        configureStatusLabel("")
        configureViewLoading(false)

        WPAppAnalytics.track(.twoFactorCodeRequested)
        self.performSegue(withIdentifier: .show2FA, sender: self)
    }

    override func localizeControls() {
        passwordField.placeholder = NSLocalizedString("Password", comment: "Password placeholder")
        passwordField.accessibilityIdentifier = "Password"
        
        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton.setTitle(submitButtonTitle, for: UIControlState())
        submitButton.setTitle(submitButtonTitle, for: .highlighted)
        submitButton.accessibilityIdentifier = "Log In Button"
        
        let forgotPasswordTitle = NSLocalizedString("Lost your password?", comment: "Title of a button. ")
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: UIControlState())
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: .highlighted)
    }
}
