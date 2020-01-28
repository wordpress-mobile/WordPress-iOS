import Foundation

// A Navigation Controller with a light navigation bar style
class LightNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
