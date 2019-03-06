import UIKit

struct OverviewTabData: FilterTabBarItem {
    var tabTitle: String
    var tabData: Int

    init(tabTitle: String, tabData: Int) {
        self.tabTitle = tabTitle
        self.tabData = tabData
    }

    var attributedTitle: NSAttributedString? {

        let attributedTitle = NSMutableAttributedString(string: tabTitle)
        attributedTitle.addAttributes([.font: WPStyleGuide.Stats.overviewCardFilterTitleFont],
                                       range: NSMakeRange(0, attributedTitle.string.count))

        let attributedData = NSMutableAttributedString(string: tabData.abbreviatedString())
        attributedData.addAttributes([.font: WPStyleGuide.Stats.overviewCardFilterDataFont],
                                       range: NSMakeRange(0, attributedData.string.count))

        attributedTitle.append(NSAttributedString(string: "\n"))
        attributedTitle.append(attributedData)

        return attributedTitle
    }

    var title: String {
        return self.tabTitle
    }

    var accessibilityIdentifier: String {
        return self.tabTitle.localizedLowercase
    }

}

class OverviewCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var selectedData: UILabel!

    private var tabsData = [OverviewTabData]()

    // MARK: - Configure

    func configure(tabsData: [OverviewTabData]) {
        self.tabsData = tabsData
        setupFilterBar()
        setSelectedLabels()
    }

}

// MARK: - Private Extension

private extension OverviewCell {

    func setupFilterBar() {
        WPStyleGuide.Stats.configureFilterTabBar(filterTabBar, forOverviewCard: true)
        filterTabBar.items = tabsData
        filterTabBar.tabBarHeight = 60.0
        filterTabBar.equalWidthFill = .fillProportionally
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        // TODO: update chart
        setSelectedLabels()
    }

    func setSelectedLabels() {
        let tabData = tabsData[filterTabBar.selectedIndex]
        selectedLabel.text = tabData.tabTitle
        selectedData.text = tabData.tabData.abbreviatedString(forHeroNumber: true)
    }
}
