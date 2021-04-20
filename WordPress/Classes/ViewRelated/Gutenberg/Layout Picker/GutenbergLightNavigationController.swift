import UIKit

class GutenbergLightNavigationController: UINavigationController {

    var separatorColor: UIColor {
        return .separator
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = separatorColor
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.standardAppearance = appearance
        navigationBar.barStyle = .default
        navigationBar.barTintColor = .white

        let tintColor = UIColor.lightAppBarTint
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
