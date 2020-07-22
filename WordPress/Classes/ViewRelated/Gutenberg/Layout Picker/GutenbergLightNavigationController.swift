import UIKit

class GutenbergLightNavigationController: UINavigationController {

    var separatorColor: UIColor {
        if #available(iOS 13.0, *) {
            return .separator
        } else {
            return .lightGray
        }
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
        let font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold)
        let tintColor = UIColor(light: .black, dark: .white)

        let titleTextAttributes = [
            NSAttributedString.Key.font: font.withSize(17),
            NSAttributedString.Key.foregroundColor: tintColor
        ]

        let largeTitleTextAttributes = [
            NSAttributedString.Key.font: font.withSize(34),
            NSAttributedString.Key.foregroundColor: tintColor
        ]

        if #available(iOS 13.0, *) {

            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = separatorColor
            appearance.titleTextAttributes = titleTextAttributes
            appearance.largeTitleTextAttributes = largeTitleTextAttributes

            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.standardAppearance = appearance
        } else {
            navigationBar.backgroundColor = .white
            navigationBar.titleTextAttributes = titleTextAttributes
            navigationBar.largeTitleTextAttributes = largeTitleTextAttributes
        }

        navigationBar.barStyle = .default
        navigationBar.barTintColor = .white
    }
}
