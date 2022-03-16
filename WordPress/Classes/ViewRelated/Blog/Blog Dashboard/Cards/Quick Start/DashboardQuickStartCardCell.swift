import UIKit

final class DashboardQuickStartCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.title = Strings.nextSteps
        frameView.icon = UIImage.gridicon(.listOrdered, size: Metrics.iconSize)
        frameView.translatesAutoresizingMaskIntoConstraints = false
        return frameView
    }()

    private lazy var tourStateView: QuickStarTourStateView = {
        let view = QuickStarTourStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let viewController = viewController else {
            return
        }

        tourStateView.configure(blog: blog, sourceController: viewController)
    }
}

// MARK: - Setup

extension DashboardQuickStartCardCell {

    private func setupViews() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: Metrics.constraintPriority)

        cardFrameView.add(subview: tourStateView)
    }
}

// MARK: - Constants

extension DashboardQuickStartCardCell {

    private enum Strings {
        static let nextSteps = NSLocalizedString("Next Steps", comment: "Title for the Quick Start dashboard card.")
    }

    private enum Metrics {
        static let iconSize = CGSize(width: 18, height: 18)
        static let constraintPriority = UILayoutPriority(999)
    }
}
