import Foundation

// A Navigation Controller with a light navigation bar style
class LightNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBarAppearance()
    }

    private func setupBarAppearance() {

        let separatorColor: UIColor

        if #available(iOS 13.0, *) {
            separatorColor = .systemGray4
        } else {
            separatorColor = .lightGray
        }

        let navigationBarAppearanceProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [LightNavigationController.self])
        navigationBarAppearanceProxy.backgroundColor = .white // Only used on iOS 12 so doesn't need dark mode support
        navigationBarAppearanceProxy.barStyle = .default
        navigationBarAppearanceProxy.barTintColor = .white

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = separatorColor
            navigationBarAppearanceProxy.standardAppearance = appearance
        }

        let tintColor = UIColor(light: .brand, dark: .white)

        let buttonBarAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [LightNavigationController.self])
        buttonBarAppearance.tintColor = tintColor
        buttonBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                    NSAttributedString.Key.foregroundColor: tintColor],
                                                   for: .normal)
        buttonBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: WPFontManager.systemRegularFont(ofSize: 17.0),
                                                    NSAttributedString.Key.foregroundColor: tintColor.withAlphaComponent(0.25)],
                                                   for: .disabled)
    }
}
