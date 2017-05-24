import UIKit
import WordPressShared

class LoginNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.barTintColor = WPStyleGuide.wordPressBlue()
    }
}
