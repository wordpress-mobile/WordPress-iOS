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

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = separatorColor
            navigationBarAppearanceProxy.standardAppearance = appearance
        }

        let tintColor = UIColor(light: .brand, dark: .white)

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [LightNavigationController.self]).tintColor = tintColor
        UIButton.appearance(whenContainedInInstancesOf: [LightNavigationController.self]).tintColor = tintColor
    }
}
