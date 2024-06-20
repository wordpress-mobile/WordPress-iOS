import UIKit

extension UITableView {
    /// Called in view controller's `viewDidLayoutSubviews`. If table view has a footer view, calculates the new height.
    /// If new height is different from current height, updates the footer view with the new height and reassigns the table footer view.
    /// Note: make sure the top-level footer view (`tableView.tableFooterView`) is frame based as a container of the Auto Layout based subview.
    func updateFooterHeight() {
        if let footerView = tableFooterView {
            let targetSize = CGSize(width: footerView.frame.width, height: 0)
            let newSize = footerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
            let newHeight = newSize.height
            var currentFrame = footerView.frame
            if newHeight != currentFrame.size.height {
                currentFrame.size.height = newHeight
                footerView.frame = currentFrame
                tableFooterView = footerView
            }
        }
    }
}
