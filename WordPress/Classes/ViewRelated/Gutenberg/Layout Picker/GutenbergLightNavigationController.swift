import UIKit

class GutenbergLightNavigationController: LightNavigationController {

    var separatorColor: UIColor {
        if #available(iOS 13.0, *) {
            return .separator
        } else {
            return UIColor.muriel(color: .divider)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = separatorColor
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.standardAppearance = appearance
        } else {
            navigationBar.backgroundColor = .white
        }

        navigationBar.barStyle = .default
        navigationBar.barTintColor = .white

        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [GutenbergLightNavigationController.self])
        barButtonItemAppearance.tintColor = UIColor(light: .brand, dark: .white)

        setNeedsStatusBarAppearanceUpdate()
    }
}
