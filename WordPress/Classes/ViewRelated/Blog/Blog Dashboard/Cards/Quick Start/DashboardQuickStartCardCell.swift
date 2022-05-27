import UIKit

final class DashboardQuickStartCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {

    private weak var viewController: BlogDashboardViewController?
    private var blog: Blog?

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.onEllipsisButtonTap = { [weak self] in
            guard let viewController = self?.viewController,
                  let blog = self?.blog else {
                return
            }
            viewController.removeQuickStart(from: blog, sourceView: frameView, sourceRect: frameView.buttonContainerStackView.frame)
        }
        return frameView
    }()

    private lazy var tourStateView: QuickStartTourStateView = {
        let view = QuickStartTourStateView()
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
        self.viewController = viewController
        self.blog = blog

        cardFrameView.title = Strings.title(for: blog.quickStartType)

        let checklistTappedTracker: QuickStartChecklistTappedTracker = (event: .dashboardCardItemTapped, properties:["type": DashboardCard.quickStart.rawValue])

        tourStateView.configure(blog: blog, sourceController: viewController, checklistTappedTracker: checklistTappedTracker)

        BlogDashboardAnalytics.shared.track(.dashboardCardShown,
                          properties: ["type": DashboardCard.quickStart.rawValue],
                          blog: blog)
    }
}

// MARK: - Setup

extension DashboardQuickStartCardCell {

    private func setupViews() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: Metrics.constraintPriority)

        cardFrameView.add(subview: tourStateView)
        cardFrameView.hideHeader()
    }
}

// MARK: - Constants

extension DashboardQuickStartCardCell {

    private enum Strings {
        static let nextSteps = NSLocalizedString("Next Steps", comment: "Title for the Quick Start dashboard card.")

        static func title(for quickStartType: QuickStartType) -> String? {
            switch quickStartType {
            case .newSite:
                return nextSteps
            default:
                return nil
            }
        }
    }

    private enum Metrics {
        static let iconSize = CGSize(width: 18, height: 18)
        static let constraintPriority = UILayoutPriority(999)
    }
}
