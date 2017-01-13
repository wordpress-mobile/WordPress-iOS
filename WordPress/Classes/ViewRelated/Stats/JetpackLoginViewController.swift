import Foundation
import UIKit
import WordPressShared
import WordPressComAnalytics

/// A view controller that presents a Jetpack login form
///
class JetpackLoginViewController: UIViewController {
    @IBOutlet weak var jetpackImage: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var usernameTextField: WPWalkthroughTextField!
    @IBOutlet weak var passwordTextField: WPWalkthroughTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = WPStyleGuide.itsEverywhereGrey()
        setupControls()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    func setupControls() {
        //TODO: Complete the NSLocalized string comments
        self.descriptionLabel.text = NSLocalizedString("Looks like you have Jetpack set up on your site. Congrats!\nSign in with your WordPress.com credentials below to enable Stats and Notifications.", comment: "")
        self.passwordTextField.font = WPNUXUtility.descriptionTextFont()
        self.descriptionLabel.textColor = WPStyleGuide.allTAllShadeGrey()
        self.descriptionLabel.backgroundColor = UIColor.clear

        self.usernameTextField.backgroundColor = UIColor.white
        self.usernameTextField.placeholder = NSLocalizedString("WordPress.com username", comment: "")
        self.usernameTextField.font = WPNUXUtility.textFieldFont()
        self.usernameTextField.adjustsFontSizeToFitWidth = true
        self.usernameTextField.autocorrectionType = .no
        self.usernameTextField.autocapitalizationType = .none
        self.usernameTextField.clearButtonMode = .whileEditing

        self.passwordTextField.backgroundColor = UIColor.white
        self.passwordTextField.placeholder = NSLocalizedString("WordPress.com password", comment: "")
        self.passwordTextField.font = WPNUXUtility.textFieldFont()
        self.passwordTextField.isSecureTextEntry = true
        self.passwordTextField.showSecureTextEntryToggle = true
        self.passwordTextField.clearsOnBeginEditing = true
        self.passwordTextField.showTopLineSeparator = true
    }
}
