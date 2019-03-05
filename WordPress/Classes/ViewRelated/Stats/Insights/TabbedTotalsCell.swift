import UIKit

struct TabData: FilterTabBarItem {
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

    var title: String {
        return self.tabTitle
    }

    var accessibilityIdentifier: String {
        return self.tabTitle.localizedLowercase
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
    @IBOutlet weak var bottomSeparatorLine: UIView!
    @IBOutlet weak var noResultsView: UIView!

    private lazy var noResultsViewController: NoResultsViewController = {
       let controller = NoResultsViewController.controller()
        controller.configure(title: NSLocalizedString("No data yet", comment: "Text shown when there is no data to display in the stats list view."))
        controller.hideImageView(true)
        return controller
    }()

    private var tabsData = [TabData]()
    private typealias Style = WPStyleGuide.Stats
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private weak var siteStatsDetailsDelegate: SiteStatsDetailsDelegate?
    private var showTotalCount = false
    private var limitRowsDisplayed = true

    // MARK: - Configure

    func configure(tabsData: [TabData],
                   siteStatsInsightsDelegate: SiteStatsInsightsDelegate? = nil,
                   siteStatsDetailsDelegate: SiteStatsDetailsDelegate? = nil,
                   showTotalCount: Bool,
                   selectedIndex: Int = 0,
                   limitRowsDisplayed: Bool = true) {
        self.tabsData = tabsData
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.siteStatsDetailsDelegate = siteStatsDetailsDelegate
        self.showTotalCount = showTotalCount
        self.limitRowsDisplayed = limitRowsDisplayed
        bottomSeparatorLine.isHidden = !limitRowsDisplayed
        setupFilterBar(selectedIndex: selectedIndex)
        addRowsForSelectedFilter()
        configureSubtitles()
        applyStyles()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeRowsFromStackView(rowsStackView)
    }
}

// MARK: - FilterTabBar Support

private extension TabbedTotalsCell {

    func setupFilterBar(selectedIndex: Int) {
        WPStyleGuide.Stats.configureFilterTabBar(filterTabBar, forTabbedCard: true)
        filterTabBar.items = tabsData
        filterTabBar.setSelectedIndex(selectedIndex)
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
        toggleFilterTabBar()
    }

    func toggleFilterTabBar() {
        // If none of the tabs have data, hide the FilterTabBar.
        let noTabsData = (tabsData.first { $0.dataRows.count > 0 }) == nil
        filterTabBar.isHidden = noTabsData
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        removeRowsFromStackView(rowsStackView)
        addRowsForSelectedFilter()
        configureSubtitles()
        siteStatsInsightsDelegate?.tabbedTotalsCellUpdated?()
        siteStatsDetailsDelegate?.tabbedTotalsCellUpdated?()
    }

    func toggleNoResults() {
        noResultsViewController.removeFromView()

        let showNoResults = tabsData[filterTabBar.selectedIndex].dataRows.isEmpty && !limitRowsDisplayed
        noResultsView.isHidden = !showNoResults

        guard showNoResults,
            let superview = superview else {
                return
        }

        noResultsViewController.view.frame = noResultsView.frame
        noResultsViewController.view.frame.origin.y = 0
        noResultsViewController.view.frame.size.height = superview.frame.height - filterTabBar.frame.height
        noResultsView.addSubview(noResultsViewController.view)
    }

    func addRowsForSelectedFilter() {
        toggleNoResults()

        guard noResultsView.isHidden else {
            return
        }

        addRows(tabsData[filterTabBar.selectedIndex].dataRows,
                toStackView: rowsStackView,
                forType: .insights,
                limitRowsDisplayed: limitRowsDisplayed,
                forDetailsList: true,
                rowDelegate: self,
                viewMoreDelegate: self)
    }

}

// MARK: - Private Methods

private extension TabbedTotalsCell {

    func applyStyles() {
        Style.configureCell(self)
        Style.configureLabelAsTotalCount(totalCountLabel)
        Style.configureViewAsSeparator(bottomSeparatorLine)
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

}

// MARK: - StatsTotalRowDelegate

extension TabbedTotalsCell: StatsTotalRowDelegate {

    func displayWebViewWithURL(_ url: URL) {
        siteStatsInsightsDelegate?.displayWebViewWithURL?(url)
        siteStatsDetailsDelegate?.displayWebViewWithURL?(url)
    }

}

// MARK: - ViewMoreRowDelegate

extension TabbedTotalsCell: ViewMoreRowDelegate {

    func viewMoreSelectedForStatSection(_ statSection: StatSection) {
        siteStatsInsightsDelegate?.viewMoreSelectedForStatSection?(statSection)
    }

}
