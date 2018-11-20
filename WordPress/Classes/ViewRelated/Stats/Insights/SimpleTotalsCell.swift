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
        for (index, dataRow) in dataRows.enumerated() {
            let row = StatsTotalRow.loadFromNib()
            row.imageView.image = dataRow.icon
            row.itemLabel.text = dataRow.name

            if let nameDetail = dataRow.nameDetail {
                row.itemDetailLabel.text = nameDetail
                row.showItemDetailLabel = true
            }

            row.dataLabel.text = dataRow.data
            row.showDisclosure = dataRow.showDisclosure

            if index == 0 {
                row.showSeparator = false
            }

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
