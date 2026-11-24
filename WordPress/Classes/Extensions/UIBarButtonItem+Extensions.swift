import UIKit

extension UIBarButtonItem {
    static func makeCloseButton(target: Any?, action: Selector) -> UIBarButtonItem {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: target, action: action)
        closeButton.accessibilityIdentifier = "close-button"
        return closeButton
    }

    /// Returns a bar button item with a spinner activity indicator.
    @objc public class var activityIndicator: UIBarButtonItem {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.sizeToFit()
        activityIndicator.startAnimating()
        return UIBarButtonItem(customView: activityIndicator)
    }

    /// If there is one action, set it as a primary action. Otherwise, show a menu.
    func setAdaptiveActions(_ actions: [UIAction]) {
        menu = nil
        primaryAction = nil

        if actions.count == 1 {
            primaryAction = actions[0]
        } else {
            menu = UIMenu(children: actions)
        }
    }
}
