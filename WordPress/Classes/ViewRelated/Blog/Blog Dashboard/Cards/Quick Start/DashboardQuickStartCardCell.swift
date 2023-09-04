import UIKit

final class DashboardQuickStartCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {

    private weak var viewController: BlogDashboardViewController?
    private var blog: Blog?

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
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

        configureCardFrameView(for: blog)

        let checklistTappedTracker: QuickStartChecklistTappedTracker = (event: .dashboardCardItemTapped, properties: ["type": DashboardCard.quickStart.rawValue])

        tourStateView.configure(blog: blog, sourceController: viewController, checklistTappedTracker: checklistTappedTracker)

        BlogDashboardAnalytics.shared.track(.dashboardCardShown,
                          properties: ["type": DashboardCard.quickStart.rawValue],
                          blog: blog)
    }

    private func configureCardFrameView(for blog: Blog) {
        switch blog.quickStartType {

        case .undefined:
            fallthrough

        case .newSite:
            configureOnEllipsisButtonTap(sourceRect: cardFrameView.ellipsisButton.frame, blog: blog)
            cardFrameView.showHeader()

        case .existingSite:
            cardFrameView.configureButtonContainerStackView()
            configureOnEllipsisButtonTap(sourceRect: cardFrameView.buttonContainerStackView.frame, blog: blog)
            cardFrameView.hideHeader()

        }

        cardFrameView.setTitle(Strings.title(for: blog.quickStartType))
    }

    private func configureOnEllipsisButtonTap(sourceRect: CGRect, blog: Blog) {
        if FeatureFlag.personalizeHomeTab.enabled {
            cardFrameView.addMoreMenu(items: [
                BlogDashboardHelpers.makeHideCardAction(for: .quickStart, blog: blog)
            ], card: .quickStart)
        } else {
            cardFrameView.onEllipsisButtonTap = { [weak self] in
                guard let self = self,
                      let viewController = self.viewController,
                      let blog = self.blog else {
                    return
                }
                viewController.removeQuickStart(from: blog, sourceView: self.cardFrameView, sourceRect: sourceRect)
            }
        }
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

        static func title(for quickStartType: QuickStartType) -> String? {
            switch quickStartType {
            case .undefined:
                fallthrough
            case .newSite:
                return nextSteps
            case .existingSite:
                return nil
            }
        }
    }

    private enum Metrics {
        static let iconSize = CGSize(width: 18, height: 18)
        static let constraintPriority = UILayoutPriority(999)
    }
}
