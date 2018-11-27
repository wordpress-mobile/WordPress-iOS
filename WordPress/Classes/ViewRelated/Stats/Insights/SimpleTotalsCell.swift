import UIKit

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

    private var dataRows = [StatsTotalRowData]()
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(dataRows: [StatsTotalRowData],
                   itemSubtitle: String? = nil,
                   dataSubtitle: String? = nil) {
        self.dataRows = dataRows
        itemSubtitleLabel.text = itemSubtitle
        dataSubtitleLabel.text = dataSubtitle

        setSubtitleVisibility()
        addRows()
        applyStyles()
    }

}

private extension SimpleTotalsCell {

    func setSubtitleVisibility() {
        let showSubtitles = (itemSubtitleLabel.text != nil || dataSubtitleLabel.text != nil)
        subtitleStackView.isHidden = !showSubtitles
        rowsStackViewTopConstraint.isActive = !showSubtitles
        rowsStackViewTopConstraintWithSubtitles.isActive = showSubtitles
    }

    func addRows() {

        removeExistingRows()

        if dataRows.count == 0 {
            let row = StatsNoDataRow.loadFromNib()
            rowsStackView.addArrangedSubview(row)
            return
        }

        for (index, dataRow) in dataRows.enumerated() {
            let row = StatsTotalRow.loadFromNib()
            row.configure(rowData: dataRow)

            // Don't show the separator line on the last row.
            if index == (dataRows.count - 1) {
                row.showSeparator = false
            }

            rowsStackView.addArrangedSubview(row)
        }
    }

    func removeExistingRows() {
        rowsStackView.arrangedSubviews.forEach {
            rowsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    func applyStyles() {
        Style.configureCell(self)
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
        Style.configureViewAsSeperator(topSeparatorLine)
        Style.configureViewAsSeperator(bottomSeparatorLine)
    }

}
