import UIKit

class Login2FAViewController: Signin2FAViewController, LoginViewController {
    // let the storyboard's style stay
    override func setupStyles() {}

    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarIcon()
    }
    
    /// Configures the appearance of the button to request a 2fa code be sent via SMS.
    ///
    override func configureSendCodeButtonText() {
        // Text: Verification Code SMS
        let string = NSLocalizedString("Enter the code on your authenticator app or <u>send the code via text message</u>.",
                                       comment: "Message displayed when a verification code is needed")
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let attributes: StyledHTMLAttributes = [ .BodyAttribute: [ NSFontAttributeName: UIFont.systemFont(ofSize: 14),
                                                                   //                                                                   NSForegroundColorAttributeName: UIColor.white,
            NSParagraphStyleAttributeName: paragraphStyle ]]
        
        let attributedCode = NSAttributedString.attributedStringWithHTML(string, attributes: attributes)
        let attributedCodeHighlighted = attributedCode.mutableCopy() as! NSMutableAttributedString
        //        attributedCodeHighlighted.applyForegroundColor(WPNUXUtility.confirmationLabelColor())
        
        if let titleLabel = sendCodeButton.titleLabel {
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 3
        }
        
        sendCodeButton.setAttributedTitle(attributedCode, for: UIControlState())
        sendCodeButton.setAttributedTitle(attributedCodeHighlighted, for: .highlighted)
    }
}
