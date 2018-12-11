import UIKit

struct TabData {
    var tabTitle: String
    var itemSubtitle: String
    var dataSubtitle: String
    var dataRows: [StatsTotalRowData]

    init(tabTitle: String,
         itemSubtitle: String,
         dataSubtitle: String,
         dataRows: [StatsTotalRowData]) {
        self.tabTitle = tabTitle
        self.itemSubtitle = itemSubtitle
        self.dataSubtitle = dataSubtitle
        self.dataRows = dataRows
    }
}

class TabbedTotalsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var itemSubtitleLabel: UILabel!
    @IBOutlet weak var dataSubtitleLabel: UILabel!

    private var tabsData = [TabData]()

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(tabsData: [TabData]) {
        self.tabsData = tabsData
        setupFilterBar()
        configureSubtitles()
        addRows()
        Style.configureCell(self)
    }

    override func prepareForReuse() {
        // TODO: clear cell
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
        // TODO: update rows per selected filter
    }

}

// MARK: - Private Methods

private extension TabbedTotalsCell {

    func configureSubtitles() {
        itemSubtitleLabel.text = tabsData[filterTabBar.selectedIndex].itemSubtitle
        dataSubtitleLabel.text = tabsData[filterTabBar.selectedIndex].dataSubtitle
        Style.configureLabelAsSubtitle(itemSubtitleLabel)
        Style.configureLabelAsSubtitle(dataSubtitleLabel)
    }

    func addRows() {
        // TODO: add rows
    }
}
