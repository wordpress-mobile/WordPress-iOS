import UIKit

struct TabData {
    var tabTitle: String
    var itemSubtitle: String
    var dataSubtitle: String
    var totalCount: String?
    var dataRows: [StatsTotalRowData]

    init(tabTitle: String,
         itemSubtitle: String,
         dataSubtitle: String,
         totalCount: String? = nil,
         dataRows: [StatsTotalRowData]) {
        self.tabTitle = tabTitle
        self.itemSubtitle = itemSubtitle
        self.dataSubtitle = dataSubtitle
        self.totalCount = totalCount
        self.dataRows = dataRows
    }
}

class TabbedTotalsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var totalCountLabel: UILabel!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!
    @IBOutlet weak var rowsStackView: UIStackView!
    @IBOutlet weak var viewMoreLabel: UILabel!

    private var tabsData = [TabData]()
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(tabsData: [TabData]) {
        self.tabsData = tabsData
        setupFilterBar()
        configureSubtitles()
        addRows()
        applyStyles()
    }

    override func prepareForReuse() {
        removeExistingRows()
    }
}

// MARK: - FilterTabBar Support

private extension TabbedTotalsCell {

    func setupFilterBar() {
        WPStyleGuide.Stats.configureFilterTabBar(filterTabBar)
        filterTabBar.items = tabsData.map { $0.tabTitle }
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        configureSubtitles()
        removeExistingRows()
        addRows()
    }

}

// MARK: - Private Methods

private extension TabbedTotalsCell {

    func applyStyles() {
        Style.configureCell(self)
        Style.configureLabelAsTotalCount(totalCountLabel)
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more stats.")
        viewMoreLabel.textColor = WPStyleGuide.Stats.actionTextColor
    }

    func configureSubtitles() {
        totalCountLabel.text = tabsData[filterTabBar.selectedIndex].totalCount
        itemSubtitleLabel.text = tabsData[filterTabBar.selectedIndex].itemSubtitle
        dataSubtitleLabel.text = tabsData[filterTabBar.selectedIndex].dataSubtitle
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
    }

    func addRows() {
        let dataRows = tabsData[filterTabBar.selectedIndex].dataRows

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

    @IBAction func didTapViewMoreButton(_ sender: UIButton) {
        let alertController =  UIAlertController(title: "More will be shown here.",
                                                 message: nil,
                                                 preferredStyle: .alert)
        alertController.addCancelActionWithTitle("OK")
        alertController.presentFromRootViewController()
    }

}
