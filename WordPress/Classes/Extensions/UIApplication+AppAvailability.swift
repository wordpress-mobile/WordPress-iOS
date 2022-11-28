import Foundation

enum AppScheme: String {
    case wordpress = "wordpress://"
}

extension UIApplication {
    func canOpen(app: AppScheme) -> Bool {
        guard let url = URL(string: app.rawValue) else {
            return false
        }
        return canOpenURL(url)
    }
}
