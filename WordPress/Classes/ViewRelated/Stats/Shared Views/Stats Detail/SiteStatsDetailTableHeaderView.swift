import UIKit

class SiteStatsDetailTableHeaderView: UITableViewHeaderFooterView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var countryMapView: UIView!
    @IBOutlet weak var mapSeparatorLine: UIView!
    @IBOutlet weak var filterTabBar: FilterTabBar!

    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!

    static let identifier = "SiteStatsDetailTableHeaderView"
    private var showFilter = false
    private var showMap = false
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(showFilter: Bool = false, showMap: Bool = false) {
        self.showFilter = showFilter
        self.showMap = showMap

        setAccessoryVisibility()
        applyStyles()
    }

}

private extension SiteStatsDetailTableHeaderView {

    func applyStyles() {
        Style.configureViewAsSeperator(mapSeparatorLine)
        Style.configureLabelAsSubtitle(itemLabel)
        Style.configureLabelAsSubtitle(dataLabel)
    }

    func setAccessoryVisibility() {
        countryMapView.isHidden = !showMap
        filterTabBar.isHidden = !showFilter

        if showFilter {
            setupFilterTabBar()
        }
    }
}

// MARK: - FilterTabBar Support

private extension SiteStatsDetailTableHeaderView {

    func setupFilterTabBar() {
        WPStyleGuide.Stats.configureFilterTabBar(filterTabBar, forTabbedCard: true)
        filterTabBar.items = ["One", "Two"]
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
    }
}
