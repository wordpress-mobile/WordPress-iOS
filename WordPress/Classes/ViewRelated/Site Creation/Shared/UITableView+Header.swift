
import UIKit

extension UITableView {

    // via https://collindonnell.com/2015/09/29/dynamically-sized-table-view-header-or-footer-using-auto-layout/
    //
    // This method didn't work as expected in `MigrationWelcomeViewController`.
    //
    // WIP: Remove this method and use `UITableView.sizeToFitHeaderView` instead.
    func layoutHeaderView() {
        guard let headerView = tableHeaderView else {
            return
        }

        let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var headerFrame = headerView.frame

        if height != headerFrame.size.height {
            headerFrame.size.height = height
            headerView.frame = headerFrame
            tableHeaderView = headerView
        }
    }

    /// Resizes the `tableHeaderView` to fit its content.
    ///
    /// The `tableHeaderView` doesn't adjust its size automatically like a `UITableViewCell`, so this method
    /// should be called whenever the `tableView`'s bounds changes or when the `tableHeaderView` content changes.
    ///
    /// This method should typically be called in `UIViewController.viewDidLayoutSubviews`.
    ///
    /// Source: https://gist.github.com/smileyborg/50de5da1c921b73bbccf7f76b3694f6a
    ///
    func sizeToFitHeaderView() {
        guard let tableHeaderView else {
            return
        }
        let fittingSize = CGSize(width: bounds.width - (safeAreaInsets.left + safeAreaInsets.right), height: 0)
        let size = tableHeaderView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let newFrame = CGRect(origin: .zero, size: size)
        if tableHeaderView.frame.height != newFrame.height {
            tableHeaderView.frame = newFrame
            self.tableHeaderView = tableHeaderView
        }
    }
}
