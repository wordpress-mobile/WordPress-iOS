import UIKit

protocol DashboardBadgeCellDelegate {
    func didTapJetpackButton()
}

/// A collection view cell with a "Jetpack powered" badge
class DashboardBadgeCell: UICollectionViewCell, Reusable {
    // takes into account the collection view cell spacing, which is 20
    // to obtain an overall distance of 30.
    private static let badgeTopInset: CGFloat = 10

    var delegate: DashboardBadgeCellDelegate?

    private lazy var jetpackButton: JetpackButton = {
        let button = JetpackButton(style: .badge)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapJetpackButton), for: .touchUpInside)
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

    @objc private func didTapJetpackButton() {
        delegate?.didTapJetpackButton()
    }
}

extension DashboardBadgeCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        delegate = viewController
    }
}
