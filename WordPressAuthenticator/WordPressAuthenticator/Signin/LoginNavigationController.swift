import UIKit
import WordPressShared
import WordPressUI


class LoginNavigationController: RotationAwareNavigationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.barTintColor = WPStyleGuide.wordPressBlue()
    }
}
