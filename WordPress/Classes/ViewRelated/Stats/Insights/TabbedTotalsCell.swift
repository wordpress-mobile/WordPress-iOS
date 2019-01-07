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

    @IBOutlet weak var labelsStackView: UIStackView!
    @IBOutlet weak var totalCountView: UIView!
    @IBOutlet weak var totalCountLabel: UILabel!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!

    @IBOutlet weak var rowsStackView: UIStackView!

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private var tabsData = [TabData]()
    private typealias Style = WPStyleGuide.Stats
    private let maxNumberOfDataRows = 6
    private var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private var showTotalCount = false

    // MARK: - Configure

    func configure(tabsData: [TabData], siteStatsInsightsDelegate: SiteStatsInsightsDelegate, showTotalCount: Bool = false) {
        self.tabsData = tabsData
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.showTotalCount = showTotalCount
        setupFilterBar()
        addRows()
        configureSubtitles()
        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeExistingRows()
    }
}

// MARK: - FilterTabBar Support

private extension TabbedTotalsCell {

    func setupFilterBar() {
        WPStyleGuide.Stats.configureFilterTabBar(filterTabBar, forTabbedCard: true)
        filterTabBar.items = tabsData.map { $0.tabTitle }
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
        toggleFilterTabBar()
    }

    func toggleFilterTabBar() {
        // If none of the tabs have data, hide the FilterTabBar.
        let noTabsData = (tabsData.first { $0.dataRows.count > 0 }) == nil
        filterTabBar.isHidden = noTabsData
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        removeExistingRows()
        addRows()
        configureSubtitles()
        siteStatsInsightsDelegate?.tabbedTotalsCellUpdated?()
    }

}

// MARK: - Private Methods

private extension TabbedTotalsCell {

    func applyStyles() {
        Style.configureCell(self)
        Style.configureLabelAsTotalCount(totalCountLabel)
        Style.configureViewAsSeperator(topSeparatorLine)
        Style.configureViewAsSeperator(bottomSeparatorLine)
    }

    func configureSubtitles() {
        let tabData = tabsData[filterTabBar.selectedIndex]

        totalCountLabel.text = tabData.totalCount
        itemSubtitleLabel.text = tabData.itemSubtitle
        dataSubtitleLabel.text = tabData.dataSubtitle
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)

        let noData = tabData.dataRows.count == 0
        totalCountView.isHidden = !showTotalCount || noData
        labelsStackView.isHidden = noData
    }

    func addRows() {
        let dataRows = tabsData[filterTabBar.selectedIndex].dataRows
        let numberOfDataRows = dataRows.count

        if numberOfDataRows == 0 {
            let row = StatsNoDataRow.loadFromNib()
            rowsStackView.addArrangedSubview(row)
            return
        }

        let numberOfRowsToAdd = numberOfDataRows > maxNumberOfDataRows ? maxNumberOfDataRows : numberOfDataRows

        for index in 0..<numberOfRowsToAdd {
            let dataRow = dataRows[index]
            let row = StatsTotalRow.loadFromNib()
            row.configure(rowData: dataRow, delegate: self)

            // Don't show the separator line on the last row.
            if index == (numberOfRowsToAdd - 1) {
                row.showSeparator = false
            }

            rowsStackView.addArrangedSubview(row)
        }

        // If there are more data rows, show 'View more'.
        if numberOfDataRows > maxNumberOfDataRows {
            addViewMoreRow()
        }
    }

    func addViewMoreRow() {
        let row = ViewMoreRow.loadFromNib()
        rowsStackView.addArrangedSubview(row)
    }

    func removeExistingRows() {
        rowsStackView.arrangedSubviews.forEach {
            rowsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

}

// MARK: - StatsTotalRowDelegate

extension TabbedTotalsCell: StatsTotalRowDelegate {

    func displayWebViewWithURL(_ url: URL) {
        siteStatsInsightsDelegate?.displayWebViewWithURL?(url)
    }

}
