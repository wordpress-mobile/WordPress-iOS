import UIKit

class SiteStatsDetailTableHeaderView: UITableViewHeaderFooterView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var countryMapView: UIView!
    @IBOutlet weak var mapSeparatorLine: UIView!
    @IBOutlet weak var filterTabBar: FilterTabBar!

    static let identifier = "SiteStatsDetailTableHeaderView"
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(statSection: StatSection) {
        setViewVisibilityFor(statSection)
        applyStyles()
    }

}

private extension SiteStatsDetailTableHeaderView {

    func applyStyles() {
        Style.configureViewAsSeperator(mapSeparatorLine)
    }

    func setViewVisibilityFor(_ statSection: StatSection) {
        countryMapView.isHidden = statSection != .periodCountries
        let showFilterTabBar = StatSection.tabbedSections.contains(statSection)
        filterTabBar.isHidden = !showFilterTabBar

        if showFilterTabBar {
            setupFilterTabBarFor(statSection)
        }
    }
}

// MARK: - FilterTabBar Support

private extension SiteStatsDetailTableHeaderView {

    func setupFilterTabBarFor(_ statSection: StatSection) {
        WPStyleGuide.Stats.configureFilterTabBar(filterTabBar, forTabbedCard: true)
        filterTabBar.items = filterTabBarTitlesFor(statSection)
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
    }

    func filterTabBarTitlesFor(_ statSection: StatSection) -> [String] {
        return StatSection.tabbedSectionComments.contains(statSection) ?
            StatSection.tabbedSectionComments.map { $0.tabTitle } :
            StatSection.tabbedSectionFollowers.map { $0.tabTitle }
    }
}
