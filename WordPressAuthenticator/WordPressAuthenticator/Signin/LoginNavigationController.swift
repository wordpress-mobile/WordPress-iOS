import UIKit
import WordPressShared
import WordPressUI


public class LoginNavigationController: RotationAwareNavigationViewController {
    override public func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.barTintColor = WPStyleGuide.wordPressBlue()
    }
}
