import UIKit

class SimpleTotalsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!
    @IBOutlet weak var rowsStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitlesStackViewTopConstraint: NSLayoutConstraint!
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

        if showSubtitles {
            let subtitleBottom = subtitleStackView.frame.origin.y + subtitleStackView.frame.size.height
            // The top and bottom subtitle margins are the same, so whatever the top constraint
            // is, add that to the bottom margin.
            rowsStackViewTopConstraint.constant = subtitleBottom + subtitlesStackViewTopConstraint.constant
        }
    }

    func addRows() {

        if dataRows.count == 0 {
            let row = StatsNoDataRow.loadFromNib()
            rowsStackView.addArrangedSubview(row)
            return
        }

        for dataRow in dataRows {
            let row = StatsTotalRow.loadFromNib()
            row.configure(rowData: dataRow)
            rowsStackView.addArrangedSubview(row)
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
