import UIKit

extension UIBarButtonItem {
    /// Returns a bar button item with a spinner activity indicator.
    static var activityIndicator: UIBarButtonItem {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.sizeToFit()
        activityIndicator.startAnimating()
        return UIBarButtonItem(customView: activityIndicator)
    }
}
