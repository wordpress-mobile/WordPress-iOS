import Foundation

extension UIViewController {
    /// iOS's `isBeingDismissed` can return `false` if the VC is being dismissed indirectly, by one of its ancestors
    /// being dismissed.  This method returns `true` if the VC is being dismissed directly, or if one of its ancestors is being
    /// dismissed.
    ///
    func isBeingDismissedDirectlyOrByAncestor() -> Bool {
        guard !isBeingDismissed else {
            return true
        }

        var current: UIViewController = self

        while let ancestor = current.parent {
            guard !ancestor.isBeingDismissed else {
                return true
            }

            current = ancestor
        }

        return false
    }
}
