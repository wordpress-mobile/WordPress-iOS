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
    /// - precondition: clearsSelectionOnViewWillAppear must be false before this is called.
    func animateDeselectionInteractively() {
        precondition(clearsSelectionOnViewWillAppear == false, "Can't take over deselection unless clearsSelectionOnViewWillAppear is false")

        if let indexPath = tableView.indexPathForSelectedRow {
            if let coordinator = transitionCoordinator() {
                let animationBlock: (UIViewControllerTransitionCoordinatorContext!) -> () = { [unowned self] _ in
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
                let completionBlock: (UIViewControllerTransitionCoordinatorContext!) -> () = { [unowned self] context in
                    if context.isCancelled() {
                        self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
                    }
                }
                coordinator.animateAlongsideTransition(animationBlock, completion: completionBlock)
            }
            else {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }

    }
}
