import UIKit

extension UINavigationBar {
    class func standardTitleTextAttributes() -> [NSAttributedString.Key: Any] {
        if #available(iOS 13.0, *) {
            return appearance().standardAppearance.titleTextAttributes
        } else {
            return appearance().titleTextAttributes ?? [:]
        }
    }
}
