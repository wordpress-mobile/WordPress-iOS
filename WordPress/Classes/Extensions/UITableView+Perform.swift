extension UITableView {
    func perform(update: (UITableView) -> Void, _ completion: ((UITableView, Bool) -> Void)? = nil) {
        if #available(iOS 11.0, *) {
            performBatchUpdates({
                update(self)
            }) { success in
                completion?(self, success)
            }
        } else {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                completion?(self, true)
            }
            beginUpdates()
            update(self)
            endUpdates()
            CATransaction.commit()
        }
    }
}
