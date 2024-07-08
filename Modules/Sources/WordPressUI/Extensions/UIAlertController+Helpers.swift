import Foundation
import UIKit

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

    @objc @discardableResult public func addActionWithTitle(_ title: String?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        let action = UIAlertAction(title: title, style: style, handler: handler)
        addAction(action)

        return action
    }
}
