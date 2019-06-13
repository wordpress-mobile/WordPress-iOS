import UIKit

class TwoColumnCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var viewMoreLabel: UILabel!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeRowsFromStackView(rowsStackView)
    }

    func configure() {
    }
}

// MARK: - Private Extension

private extension TwoColumnCell {

    func applyStyles() {
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more stats.")
        viewMoreLabel.textColor = Style.actionTextColor
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

}
