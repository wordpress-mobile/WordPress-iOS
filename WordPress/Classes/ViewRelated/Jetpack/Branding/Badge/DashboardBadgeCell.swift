import UIKit

/// A collection view cell with a "Jetpack powered" badge
class DashboardBadgeCell: UICollectionViewCell, Reusable {

    private lazy var jetpackButton: JetpackButton = {
        let button = JetpackButton(style: .badge)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.backgroundColor = .listBackground
        contentView.addSubview(jetpackButton)
        NSLayoutConstraint.activate([
            jetpackButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            jetpackButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.badgeTopInset),
            jetpackButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // takes into account the collection view cell spacing, which is 20
    // to obtain an overall distance of 30.
    private static let badgeTopInset: CGFloat = 10
}

extension DashboardBadgeCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let viewController = viewController else {
            return
        }

        jetpackButton.setAction {
            JetpackBrandingCoordinator.presentOverlay(from: viewController)
        }
    }
}
