import Foundation

extension UIApplication {
    @objc var mainWindow: UIWindow? {
        return UIApplication.shared.windows.filter {$0.isKeyWindow}.first
    }
}
