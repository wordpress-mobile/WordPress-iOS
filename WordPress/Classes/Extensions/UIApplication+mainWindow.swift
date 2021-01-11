import UIKit

extension UIApplication {
    @objc var mainWindow: UIWindow? {
        return UIApplication.shared.windows.filter {$0.isKeyWindow}.first
    }

    @objc var currentStatusBarFrame: CGRect {
        return mainWindow?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero
    }

    @objc var currentStatusBarOrientation: UIInterfaceOrientation {
        return mainWindow?.windowScene?.interfaceOrientation ?? .unknown
    }
}
