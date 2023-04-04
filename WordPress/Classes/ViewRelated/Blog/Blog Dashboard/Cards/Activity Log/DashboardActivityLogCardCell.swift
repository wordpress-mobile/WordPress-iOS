import UIKit

final class DashboardActivityLogCardCell: DashboardCollectionViewCell {

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?

    // MARK: - Views

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.title = Strings.title
        frameView.onEllipsisButtonTap = {
            // FIXME: Track event
        }
        return frameView
    }()

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup

    private func setupView() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: .defaultHigh)
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController

        // FIXME: configure card using api response
        // Expecting a list of type [Activity]
    }
}

extension DashboardActivityLogCardCell {

    static func shouldShowCard(for blog: Blog) -> Bool {
        guard RemoteFeatureFlag.activityLogDashboardCard.enabled(),
              blog.supports(.activity),
              !blog.isWPForTeams() else {
            return false
        }

        return true
    }
}

extension DashboardActivityLogCardCell {

    private enum Strings {
        static let title = NSLocalizedString("activityLog.dashboard.card.title",
                                             value: "Recent activity",
                                             comment: "Title for the Activity Log dashboard card.")
    }
}
