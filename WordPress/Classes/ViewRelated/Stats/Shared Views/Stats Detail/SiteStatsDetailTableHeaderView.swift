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
    private let tabbedSections = [StatSection.insightsCommentsAuthors,
                                  .insightsCommentsPosts,
                                  .insightsFollowersWordPress,
                                  .insightsFollowersEmail]

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
        let showFilterTabBar = tabbedSections.contains(statSection)
        filterTabBar.isHidden = !showFilterTabBar

        if showFilterTabBar {
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
