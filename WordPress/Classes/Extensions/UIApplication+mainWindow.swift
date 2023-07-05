import UIKit

extension UIApplication {
    @objc var mainWindow: UIWindow? {
        connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
    }

    @objc var currentStatusBarFrame: CGRect {
        return mainWindow?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero
    }

    @objc var currentStatusBarOrientation: UIInterfaceOrientation {
        return mainWindow?.windowScene?.interfaceOrientation ?? .unknown
    }

    var leafViewController: UIViewController? {
        guard let rootViewController = mainWindow?.rootViewController else {
            return nil
        }
        var leafViewController = rootViewController
        while leafViewController.presentedViewController != nil && !leafViewController.presentedViewController!.isBeingDismissed {
            leafViewController = leafViewController.presentedViewController!
        }
        return leafViewController
    }
}
