import UIKit

class GutenbergLightNavigationController: UINavigationController {

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
            navigationBar.titleTextAttributes = [ .foregroundColor: UIColor.text ]
        }

        navigationBar.barStyle = .default
        navigationBar.barTintColor = .white

        let tintColor = UIColor(light: .brand, dark: .white)
        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [GutenbergLightNavigationController.self])
        barButtonItemAppearance.tintColor = tintColor
        barButtonItemAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                    NSAttributedString.Key.foregroundColor: tintColor],
                                                   for: .normal)
        barButtonItemAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                    NSAttributedString.Key.foregroundColor: tintColor.withAlphaComponent(0.25)],
                                                   for: .disabled)


        setNeedsStatusBarAppearanceUpdate()
    }
}
