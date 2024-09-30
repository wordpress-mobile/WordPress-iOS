import UIKit

extension UIViewController {
    /// Add a view controller as child view controller
    ///
    /// - Parameter child: The child view controller
    public func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    /// Remove a specific child view controller
    ///
    /// - Parameter child: The child view controller
    public func remove(_ child: UIViewController) {
        child.remove()
    }

    /// Remove the child view controller
    public func remove() {
        guard parent != nil else {
            return
        }

        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }
}
