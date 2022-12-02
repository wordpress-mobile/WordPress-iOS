import Foundation

enum AppScheme: String {
    case wordpress = "wordpress://"
    case wordpressMigrationV1 = "wordpressmigration+v1://"
}

extension UIApplication {
    func canOpen(app: AppScheme) -> Bool {
        guard let url = URL(string: app.rawValue) else {
            return false
        }
        return canOpenURL(url)
    }
}
