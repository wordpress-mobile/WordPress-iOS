import UIKit

public extension UIApplication {
    @objc var mainWindow: UIWindow? {
        // The delegate-window fallback covers the moments when no scene key window
        // exists: early in scene connection (before makeKeyAndVisible) and in the unit
        // test host, which never connects a window scene.
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
