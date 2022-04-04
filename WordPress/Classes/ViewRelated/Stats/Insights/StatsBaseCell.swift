import UIKit

class StatsBaseCell: UITableViewCell {
    let headingLabel: UILabel = UILabel()

    var statSection: StatSection? {
        didSet {
            headingLabel.text = statSection?.title
        }
    }

    func configureHeadingLabel(with topConstraint: NSLayoutConstraint) {
        guard FeatureFlag.statsNewAppearance.enabled,
            topConstraint.isActive else {
            return
        }

        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headingLabel)
        headingLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        NSLayoutConstraint.activate([
            headingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.padding),
            headingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.padding),
            headingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metrics.padding)
        ])

        if let anchor = topConstraint.firstItem?.topAnchor {
            topConstraint.isActive = false

            headingLabel.bottomAnchor.constraint(equalTo: anchor, constant: -Metrics.padding).isActive = true
        }
    }

    private enum Metrics {
        static let padding: CGFloat = 16.0
    }
}
