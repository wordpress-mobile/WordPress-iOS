extension UITableView {
    /// Allows multiple insert/delete/reload/move calls to be animated simultaneously.
    ///
    /// - Parameters:
    ///   - update: The block that performs the relevant insert, delete, reload, or move operations.
    ///   - completion: A completion handler block to execute when all of the operations are finished. The Boolean value indicating whether the animations completed successfully. The value of this parameter is false if the animations were interrupted for any reason. On iOS 10 the value is always true.
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
