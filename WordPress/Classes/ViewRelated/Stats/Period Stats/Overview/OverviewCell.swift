import UIKit

struct OverviewTabData: FilterTabBarItem {
    var tabTitle: String
    var tabData: Int
    var difference: Int
    var differencePercent: Int

    init(tabTitle: String, tabData: Int, difference: Int, differencePercent: Int) {
        self.tabTitle = tabTitle
        self.tabData = tabData
        self.difference = difference
        self.differencePercent = differencePercent
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

    var differenceLabel: String {
        let stringFormat = NSLocalizedString("%@%@ (%@%%)", comment: "Difference label for Period Overview stat, indicating change from previous period. Ex: +99.9K (5%)")
        return String.localizedStringWithFormat(stringFormat,
                                                difference < 0 ? "" : "+",
                                                difference.abbreviatedString(),
                                                differencePercent.abbreviatedString())
    }

    var differenceTextColor: UIColor {
        return difference < 0 ? WPStyleGuide.Stats.negativeColor : WPStyleGuide.Stats.positiveColor
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
    @IBOutlet weak var differenceLabel: UILabel!
    @IBOutlet weak var chartContainerView: UIView!

    private var tabsData = [OverviewTabData]()

    // Introduced via #11063, to be replaced with real data via #11069
    private lazy var periodDataStub: (data: BarChartDataConvertible, styling: BarChartStyling) = {
        let stubbedData = PeriodDataStub()
        let firstStubbedDateInterval = stubbedData.periodData.first?.date.timeIntervalSince1970 ?? 0
        let styling = PeriodPerformanceStyling(initialDateInterval: firstStubbedDateInterval)

        return (stubbedData, styling)
    }()

    // MARK: - Configure

    func configure(tabsData: [OverviewTabData]) {
        self.tabsData = tabsData
        setupFilterBar()
        updateLabels()
        configureChartViewIfNeeded()
    }
}

// MARK: - Private Extension

private extension OverviewCell {

    func setupFilterBar() {
        WPStyleGuide.Stats.configureFilterTabBar(filterTabBar, forOverviewCard: true)
        filterTabBar.items = tabsData
        filterTabBar.tabBarHeight = 60.0
        filterTabBar.equalWidthFill = .fillProportionally
        filterTabBar.equalWidthSpacing = 12
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        // TODO: update chart - configureChartViewIfNeeded() - via #11064
        updateLabels()
    }

    func updateLabels() {
        let tabData = tabsData[filterTabBar.selectedIndex]
        selectedLabel.text = tabData.tabTitle
        selectedData.text = tabData.tabData.abbreviatedString(forHeroNumber: true)
        differenceLabel.text = tabData.differenceLabel
        differenceLabel.textColor = tabData.differenceTextColor
    }

    // MARK: Chart support

    func resetChartView() {
        for subview in chartContainerView.subviews {
            subview.removeFromSuperview()
        }
    }

    func configureChartViewIfNeeded() {
        resetChartView()

        let chartView = StatsBarChartView(data: periodDataStub.data, styling: periodDataStub.styling)
        chartContainerView.addSubview(chartView)

        NSLayoutConstraint.activate([
            chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            chartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
        ])
    }
}
