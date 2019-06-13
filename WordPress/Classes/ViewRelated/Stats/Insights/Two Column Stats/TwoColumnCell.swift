import UIKit

class TwoColumnCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var viewMoreView: UIView!
    @IBOutlet weak var viewMoreLabel: UILabel!
    @IBOutlet weak var bottomSeparatorLine: UIView!
    @IBOutlet weak var rowsStackViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewMoreHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSeparatorLineHeightConstraint: NSLayoutConstraint!

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

    func configure(dataRows: [StatsTwoColumnRowData], statSection: StatSection) {
        addRows(dataRows)
        toggleViewMore(forSection: statSection)
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

    func addRows(_ dataRows: [StatsTwoColumnRowData]) {
        for dataRow in dataRows {
            let row = StatsTwoColumnRow.loadFromNib()
            row.configure(rowData: dataRow)
            rowsStackView.addArrangedSubview(row)
        }
    }

    func toggleViewMore(forSection statSection: StatSection) {
        let showViewMore = statSection == .insightsAnnualSiteStats
        viewMoreView.isHidden = !showViewMore
        rowsStackViewBottomConstraint.constant = showViewMore ? viewMoreHeightConstraint.constant :
                                                                bottomSeparatorLineHeightConstraint.constant
    }

}
