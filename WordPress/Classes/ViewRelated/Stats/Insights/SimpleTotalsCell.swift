import UIKit

class SimpleTotalsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var borderedView: UIView!
    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!

    private var dataRows = [StatsTotalRowData]()
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(dataRows: [StatsTotalRowData],
                   itemSubtitle: String? = nil,
                   dataSubtitle: String? = nil) {
        self.dataRows = dataRows
        itemSubtitleLabel.text = itemSubtitle
        dataSubtitleLabel.text = dataSubtitle
        subtitleStackView.isHidden = (itemSubtitle != nil || dataSubtitle != nil)
        addRows()
        applyStyles()
    }

}

private extension SimpleTotalsCell {

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
        Style.configureBorderForView(borderedView)
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
    }

}
