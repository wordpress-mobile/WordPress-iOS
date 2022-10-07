import WordPressAuthenticator
import UIKit

struct JetpackAuthenticationManager: AuthenticationHandler {
    let statusBarStyle: UIStatusBarStyle = FeatureFlag.newLandingScreen.enabled ? .default : .lightContent
    let prologueViewController: UIViewController? = JetpackPrologueViewController()
    let buttonViewTopShadowImage: UIImage? = UIImage()
    let prologueButtonsBackgroundColor: UIColor? = JetpackPrologueStyleGuide.backgroundColor
    let prologueButtonsBlurEffect: UIBlurEffect? = JetpackPrologueStyleGuide.prologueButtonsBlurEffect
    let prologuePrimaryButtonStyle: NUXButtonStyle? = JetpackPrologueStyleGuide.continueButtonStyle
    let prologueSecondaryButtonStyle: NUXButtonStyle? = JetpackPrologueStyleGuide.siteAddressButtonStyle
    let prologueBackgroundImage = JetpackPrologueStyleGuide.prologueBackgroundImage
}
