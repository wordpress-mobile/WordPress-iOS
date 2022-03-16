import Foundation
import UIKit

class DashboardGhostCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {
    private lazy var contentStackView: UIStackView = {
        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.spacing = Constants.spacing
        return contentStackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        for _ in 0..<Constants.numberOfCards {
            contentStackView.addArrangedSubview(ghostCard())
        }

        contentView.addSubview(contentStackView)
        contentView.pinSubviewToAllEdges(contentStackView, insets: Constants.insets,
                                         priority: Constants.constraintPriority)

        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        startGhostAnimation(style: GhostCellStyle.muriel)
    }

    private func ghostCard() -> BlogDashboardCardFrameView {
        let frameView = BlogDashboardCardFrameView()

        let content = DashboardGhostCardContent.loadFromNib()
        frameView.hideHeader()
        frameView.add(subview: content)

        return frameView
    }

    private enum Constants {
        static let spacing: CGFloat = 20
        static let numberOfCards = 5
        static let insets = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        static let constraintPriority = UILayoutPriority(999)
    }
}

class DashboardGhostCardContent: UIView, NibLoadable { }
