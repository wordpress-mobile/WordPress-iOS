import UIKit

class StatsBaseCell: UITableViewCell {
    let headingLabel: UILabel = UILabel()

    @IBOutlet var topConstraint: NSLayoutConstraint!

    var statSection: StatSection? {
        didSet {
            headingLabel.text = statSection?.title
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureHeadingLabel(with: topConstraint)
    }

    func configureHeadingLabel(with topConstraint: NSLayoutConstraint) {
        guard FeatureFlag.statsNewAppearance.enabled else {
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
            let constant = topConstraint.constant

            topConstraint.isActive = false

            headingLabel.bottomAnchor.constraint(equalTo: anchor, constant: -(Metrics.padding + constant)).isActive = true
        }
    }

    private enum Metrics {
        static let padding: CGFloat = 16.0
    }
}
