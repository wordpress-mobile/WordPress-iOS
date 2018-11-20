import UIKit

class SimpleTotalsCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet weak var borderedView: UIView!
    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet weak var subtitleStackView: UIStackView!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!

    private var dataRows = [StatsTotalRowData]()
    private let headerView = StatsCellHeader.loadFromNib()
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(withTitle title: String,
                   dataRows: [StatsTotalRowData],
                   showSubtitles: Bool = false,
                   itemSubtitle: String? = nil,
                   dataSubtitle: String? = nil) {
        self.dataRows = dataRows
        itemSubtitleLabel.text = itemSubtitle
        dataSubtitleLabel.text = dataSubtitle
        subtitleStackView.isHidden = !showSubtitles
        addHeader(title)
        addRows()
        applyStyles()
    }

}

private extension SimpleTotalsCell {

    func addHeader(_ title: String) {
        headerView.headerLabel.text = title
        headerStackView.insertArrangedSubview(headerView, at: 0)
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
        Style.configureBorderForView(borderedView)
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
    }

}
