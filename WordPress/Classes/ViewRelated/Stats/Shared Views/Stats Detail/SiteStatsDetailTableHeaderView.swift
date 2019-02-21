import UIKit

class SiteStatsDetailTableHeaderView: UITableViewHeaderFooterView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var countryMapView: UIView!
    @IBOutlet weak var mapSeparatorLine: UIView!
    @IBOutlet weak var filterTabBar: FilterTabBar!

    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!

    static let identifier = "SiteStatsDetailTableHeaderView"
    private typealias Style = WPStyleGuide.Stats

    private var statSection: StatSection?
    private let tabbedSectionComments = [StatSection.insightsCommentsAuthors, .insightsCommentsPosts]
    private let tabbedSectionFollowers = [StatSection.insightsFollowersWordPress, .insightsFollowersEmail]

    // MARK: - Configure

    func configure(statSection: StatSection?) {
        self.statSection = statSection
        self.itemLabel.text = statSection?.itemSubtitle
        self.dataLabel.text = statSection?.dataSubtitle

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
        guard let statSection = statSection else {
            countryMapView.isHidden = true
            filterTabBar.isHidden = true
            return
        }

        countryMapView.isHidden = statSection != .periodCountries
        let showFilterTabBar = tabbedSectionComments.contains(statSection) || tabbedSectionFollowers.contains(statSection)
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
        return tabbedSectionComments.contains(statSection) ?
            tabbedSectionComments.map { $0.tabTitle } :
            tabbedSectionFollowers.map { $0.tabTitle }
    }
}
