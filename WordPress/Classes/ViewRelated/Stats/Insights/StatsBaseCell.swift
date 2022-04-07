import UIKit

class StatsBaseCell: UITableViewCell {
    let headingLabel: UILabel = UILabel()

    @IBOutlet var topConstraint: NSLayoutConstraint!

    private var headingBottomConstraint: NSLayoutConstraint!

    /// Finds the item from the top constraint that's not the content view itself.
    /// - Returns: `topConstraint`'s `firstItem` or `secondItem`, whichever is not this cell's content view.
    private var topConstraintTargetView: UIView? {
        if let firstItem = topConstraint.firstItem as? UIView,
           firstItem != contentView {
            return firstItem
        }

        return topConstraint.secondItem as? UIView
    }

    var statSection: StatSection? {
        didSet {
            let title = statSection?.title ?? ""
            updateHeadingLabel(with: title)
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
        headingLabel.font = UIFont.preferredFont(forTextStyle: .headline)

        contentView.addSubview(headingLabel)
        NSLayoutConstraint.activate([
            headingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.padding),
            headingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.padding),
            headingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metrics.padding)
        ])

        if let anchor = topConstraintTargetView?.topAnchor {
            // Deactivate the existing top constraint of the cell
            let constant = topConstraint.constant
            topConstraint.isActive = false

            // Create a new constraint between the heading label and the first item of the existing top constraint
            headingBottomConstraint = headingLabel.bottomAnchor.constraint(equalTo: anchor, constant: -(Metrics.padding + constant))
            headingBottomConstraint.isActive = true
        }
    }

    private func updateHeadingLabel(with title: String) {
        guard FeatureFlag.statsNewAppearance.enabled else {
            return
        }

        headingLabel.text = title

        let hasTitle = !title.isEmpty

        headingBottomConstraint.isActive = hasTitle
        topConstraint.isActive = !hasTitle
    }

    private enum Metrics {
        static let padding: CGFloat = 16.0
    }
}
