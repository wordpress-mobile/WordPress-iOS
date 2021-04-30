import UIKit

extension UINavigationBar {
    class func standardTitleTextAttributes() -> [NSAttributedString.Key: Any] {
        return appearance().standardAppearance.titleTextAttributes
    }
}
