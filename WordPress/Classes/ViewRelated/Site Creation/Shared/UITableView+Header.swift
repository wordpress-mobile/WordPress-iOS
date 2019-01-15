
import UIKit

extension UITableView {

    // via https://collindonnell.com/2015/09/29/dynamically-sized-table-view-header-or-footer-using-auto-layout/
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
}
