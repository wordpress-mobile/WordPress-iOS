import UIKit

class GutenbergLightNavigationController: UINavigationController {

    var separatorColor: UIColor {
        if #available(iOS 13.0, *) {
            return .separator
        } else {
            return .lightGray
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    var shadowIsHidden: Bool = false {
        didSet {
            if shadowIsHidden {
                if #available(iOS 13.0, *) {
                    navigationBar.standardAppearance.shadowColor = UIColor.clear
                    navigationBar.scrollEdgeAppearance?.shadowColor = UIColor.clear
                } else {
                    navigationBar.shadowImage = UIImage()
                }
            } else {
                if #available(iOS 13.0, *) {
                    navigationBar.standardAppearance.shadowColor = separatorColor
                    navigationBar.scrollEdgeAppearance?.shadowColor = separatorColor
                } else {
                    navigationBar.shadowImage = UIImage(color: .lightGray)
                }
            }
        }
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

        setNeedsStatusBarAppearanceUpdate()
    }
}
