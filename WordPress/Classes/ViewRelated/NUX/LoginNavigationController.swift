import UIKit
import WordPressShared

class LoginNavigationController: RotationAwareNavigationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.barTintColor = WPStyleGuide.wordPressBlue()
    }
}
