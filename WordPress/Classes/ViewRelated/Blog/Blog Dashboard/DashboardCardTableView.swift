import UIKit

extension NSNotification.Name {
    /// Fired when a DashboardCardTableView changes its size
    static let dashboardCardTableViewSizeChanged = NSNotification.Name("DashboardCard.IntrinsicContentSizeUpdated")
}

class DashboardCardTableView: UITableView {
    private var previousHeight: CGFloat = 0

    override var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    /// Emits a notification when the intrinsicContentSize changes
    /// This allows subscribers to update their layouts (ie.: UICollectionViews)
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        if contentSize.height != previousHeight, contentSize.height != 0 {
            previousHeight = contentSize.height
            NotificationCenter.default.post(name: .dashboardCardTableViewSizeChanged, object: nil)
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
