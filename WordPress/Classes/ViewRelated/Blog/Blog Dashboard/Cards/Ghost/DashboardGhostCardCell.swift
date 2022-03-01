import Foundation
import UIKit

class DashboardGhostCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let frameView = BlogDashboardCardFrameView()

        let content = DashboardGhostCardContent.loadFromNib()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.hideHeader()
        frameView.add(subview: content)

        contentView.addSubview(frameView)
        contentView.pinSubviewToAllEdges(frameView)

        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        startGhostAnimation(style: GhostCellStyle.muriel)
    }
}

class DashboardGhostCardContent: UIView, NibLoadable { }
