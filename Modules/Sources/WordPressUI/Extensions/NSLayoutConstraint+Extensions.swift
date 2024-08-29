import UIKit

extension NSLayoutConstraint {
    public func withPriority(_ priotity: Float) -> NSLayoutConstraint {
        self.priority = UILayoutPriority(priotity)
        return self
    }

    public func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
