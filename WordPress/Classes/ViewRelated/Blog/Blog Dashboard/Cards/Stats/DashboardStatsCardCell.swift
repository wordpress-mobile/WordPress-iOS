import UIKit

class DashboardStatsCardCell: UICollectionViewCell, Reusable {

    // MARK: Private Variables

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Constants.spacing
        return stackView
    }()

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: BlogDashboardCardConfigurable

extension DashboardStatsCardCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let viewController = viewController else {
            return
        }

        // TODO: Use apiResponse to create a View Model and use it to populate the cell

        clearFrames()
        addTodayStatsCard(for: blog, in: viewController)

        // TODO: Add grow your audience card if needed
    }

    /// Remove any card frame, if present
    private func clearFrames() {
        stackView.removeAllSubviews()
    }

    private func addTodayStatsCard(for blog: Blog, in viewController: UIViewController) {
        let frameView = BlogDashboardCardFrameView()
        frameView.title = Strings.statsTitle
        frameView.icon = UIImage.gridicon(.statsAlt, size: Constants.iconSize)
        frameView.onViewTap = { [weak self] in
            self?.showStats(for: blog, from: viewController)
        }

        let views = statsViews()
        let statsStackview = createStatsStackView(arrangedSubviews: views)
        frameView.add(subview: statsStackview)

        stackView.addArrangedSubview(frameView)
    }

    private func createStatsStackView(arrangedSubviews: [UIView]) -> UIStackView {
        let stackview = UIStackView(arrangedSubviews: arrangedSubviews)
        stackview.axis = .horizontal
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.distribution = .fillEqually
        stackview.isLayoutMarginsRelativeArrangement = true
        stackview.directionalLayoutMargins = Constants.statsStackViewMargins
        return stackview
    }

    // TODO: Data is now static. It should be brought in from the view model.
    // View model should also return data for comments in the case of an iPad.
    private func statsViews() -> [UIView] {
        let viewsStatsView = DashboardSingleStatView(countString: "1,492", title: Strings.viewsTitle)
        let visitorsStatsView = DashboardSingleStatView(countString: "885", title: Strings.visitorsTitle)
        let likesStatsView = DashboardSingleStatView(countString: "112", title: Strings.likesTitle)
        return [viewsStatsView, visitorsStatsView, likesStatsView]
    }

    private func showStats(for blog: Blog, from sourceController: UIViewController) {
        StatsViewController.show(for: blog, from: sourceController)
    }
}

// MARK: Constants

private extension DashboardStatsCardCell {

    enum Strings {
        static let statsTitle = NSLocalizedString("Today's Stats", comment: "Title for the card displaying today's stats.")
        static let viewsTitle = NSLocalizedString("Views", comment: "Today's Stats 'Views' label")
        static let visitorsTitle = NSLocalizedString("Visitors", comment: "Today's Stats 'Visitors' label")
        static let likesTitle = NSLocalizedString("Likes", comment: "Today's Stats 'Likes' label")
        static let commentsTitle = NSLocalizedString("Comments", comment: "Today's Stats 'Comments' label")
    }

    enum Constants {
        static let spacing: CGFloat = 20
        static let iconSize = CGSize(width: 18, height: 18)
        static let statsStackViewMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    }
}
