import WordPressAuthenticator
import UIKit

struct JetpackAuthenticationManager: AuthenticationHandler {
    let statusBarStyle: UIStatusBarStyle = .default
    let prologueViewController: UIViewController? = JetpackPrologueViewController(nibName: "JetpackPrologueViewController", bundle: .keystone)
    let buttonViewTopShadowImage: UIImage? = UIImage()
    let prologueButtonsBackgroundColor: UIColor? = JetpackPrologueStyleGuide.gradientColor
    let prologueButtonsBlurEffect: UIBlurEffect? = JetpackPrologueStyleGuide.prologueButtonsBlurEffect
    let prologuePrimaryButtonStyle: NUXButtonStyle? = JetpackPrologueStyleGuide.continueButtonStyle
    let prologueSecondaryButtonStyle: NUXButtonStyle? = JetpackPrologueStyleGuide.siteAddressButtonStyle
    let prologueBackgroundImage = JetpackPrologueStyleGuide.prologueBackgroundImage
}
