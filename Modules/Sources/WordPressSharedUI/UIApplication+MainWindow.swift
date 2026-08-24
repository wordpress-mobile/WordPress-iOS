import UIKit

public extension UIApplication {
    @objc var mainWindow: UIWindow? {
        // The delegate-window fallback covers the brief moment early in scene
        // connection, before the scene's key window is made visible.
        connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
            ?? (delegate?.window).flatMap { $0 }
    }

    @objc var currentStatusBarFrame: CGRect {
        mainWindow?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero
    }

    @objc var currentStatusBarOrientation: UIInterfaceOrientation {
        mainWindow?.windowScene?.interfaceOrientation ?? .unknown
    }
}

public extension UIApplication {
    var leafViewController: UIViewController? {
        guard let rootViewController = mainWindow?.rootViewController else {
            return nil
        }
        var leafViewController = rootViewController
        while leafViewController.presentedViewController != nil
            && !leafViewController.presentedViewController!.isBeingDismissed
        {
            leafViewController = leafViewController.presentedViewController!
        }
        return leafViewController
    }
}
