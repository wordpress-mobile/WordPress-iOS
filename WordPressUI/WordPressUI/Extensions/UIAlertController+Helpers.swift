import Foundation


extension UIAlertController {
    @objc @discardableResult public func addCancelActionWithTitle(_ title: String?, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return addActionWithTitle(title, style: .cancel, handler: handler)
    }

    @objc @discardableResult public func addDestructiveActionWithTitle(_ title: String?, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return addActionWithTitle(title, style: .destructive, handler: handler)
    }

    @objc @discardableResult public func addDefaultActionWithTitle(_ title: String?, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return addActionWithTitle(title, style: .default, handler: handler)
    }

    @objc @discardableResult public func addActionWithTitle(_ title: String?, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        let action = UIAlertAction(title: title, style: style, handler: handler)
        addAction(action)

        return action
    }

    @objc public func presentFromRootViewController() {
        // Note:
        // This method is required because the presenter ViewController must be visible, and we've got several
        // flows in which the VC that triggers the alert, might not be visible anymore.
        //
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            print("Error loading the rootViewController")
            return
        }

        var leafViewController = rootViewController
        while leafViewController.presentedViewController != nil && !leafViewController.presentedViewController!.isBeingDismissed {
            leafViewController = leafViewController.presentedViewController!
        }

        leafViewController.present(self, animated: true, completion: nil)
    }
}
