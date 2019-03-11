import UIKit

/// This cell type simply displays all data rows provided for a Stat type.
/// The cell and rows have no functionality; the cell is simply a list, with optional subtitles.
/// Ex: Insights All Time Stats, Insights Follower Totals.
///

class SimpleTotalsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!

    // If the subtitles are not shown, this is active.
    @IBOutlet weak var rowsStackViewTopConstraint: NSLayoutConstraint!
    // If the subtitles are shown, this is active.
    @IBOutlet weak var rowsStackViewTopConstraintWithSubtitles: NSLayoutConstraint!

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(dataRows: [StatsTotalRowData],
                   itemSubtitle: String? = nil,
                   dataSubtitle: String? = nil) {
        itemSubtitleLabel.text = itemSubtitle
        dataSubtitleLabel.text = dataSubtitle

        setSubtitleVisibility()
        addRows(dataRows, toStackView: rowsStackView, forType: .insights, limitRowsDisplayed: false)
        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeRowsFromStackView(rowsStackView)
    }

}

private extension SimpleTotalsCell {

    func setSubtitleVisibility() {
        let showSubtitles = (itemSubtitleLabel.text != nil || dataSubtitleLabel.text != nil)
        subtitleStackView.isHidden = !showSubtitles
        rowsStackViewTopConstraint.isActive = !showSubtitles
        rowsStackViewTopConstraintWithSubtitles.isActive = showSubtitles
    }

    func applyStyles() {
        Style.configureCell(self)
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

}
