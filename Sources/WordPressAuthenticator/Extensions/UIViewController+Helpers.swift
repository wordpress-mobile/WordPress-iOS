import UIKit

// MARK: - UIViewController Helpers
extension UIViewController {

    /// Convenience method to instantiate a view controller from a storyboard.
    ///
    static func instantiate(from storyboard: Storyboard, creator: ((NSCoder) -> UIViewController?)? = nil) -> Self? {
        return storyboard.instantiateViewController(ofClass: self, creator: creator)
    }
}
