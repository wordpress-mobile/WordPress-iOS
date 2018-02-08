import UIKit

extension UITableViewController {
    /// Animates the deselection of the currently selected row interactively.
    ///
    /// When the user performs a swipe from the left bezel to pop the navigation
    /// stack, this method will animate the transition so the selection fades
    /// away interactively, depending on how much the user has dragged the top
    /// view.
    ///
    /// You should call this method from your UITableViewController's
    /// viewWillAppear method.
    ///
    /// - Precondition: clearsSelectionOnViewWillAppear must be false before this is called.
    ///
    @objc public func animateDeselectionInteractively() {
        precondition(clearsSelectionOnViewWillAppear == false, "Can't take over deselection unless clearsSelectionOnViewWillAppear is false")

        if let indexPath = tableView.indexPathForSelectedRow {
            if let coordinator = transitionCoordinator {
                let animationBlock: (UIViewControllerTransitionCoordinatorContext!) -> () = { [unowned self] _ in
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
                let completionBlock: (UIViewControllerTransitionCoordinatorContext!) -> () = { [unowned self] context in
                    if context.isCancelled {
                        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                    }
                }
                coordinator.animate(alongsideTransition: animationBlock, completion: completionBlock)
            }
            else {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }

    }
}
