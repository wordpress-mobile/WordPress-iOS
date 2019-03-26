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

        let attributedTitle = NSMutableAttributedString(string: tabTitle.localizedUppercase)
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

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var selectedData: UILabel!
    @IBOutlet weak var differenceLabel: UILabel!
    @IBOutlet weak var chartContainerView: UIView!
    @IBOutlet weak var chartBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private typealias Style = WPStyleGuide.Stats
    private var tabsData = [OverviewTabData]()

    private(set) var chartData: [BarChartDataConvertible] = []
    private(set) var chartStyling: [BarChartStyling] = []

    // MARK: - Configure

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(tabsData: [OverviewTabData], barChartData: [BarChartDataConvertible] = [], barChartStyling: [BarChartStyling] = []) {
        self.tabsData = tabsData
        self.chartData = barChartData
        self.chartStyling = barChartStyling

        setupFilterBar()
        updateLabels()
        configureChartViewIfNeeded()
    }
}

// MARK: - Private Extension

private extension OverviewCell {

    func applyStyles() {
        Style.configureLabelForOverview(selectedLabel)
        Style.configureLabelForOverview(selectedData)
        Style.configureViewAsSeparator(topSeparatorLine)
        Style.configureViewAsSeparator(bottomSeparatorLine)
        configureFonts()
    }

    /// This method squelches two Xcode warnings that I encountered:
    /// 1. Attribute Unavailable: Large Title font text style before iOS 11.0
    /// 2. Automatically Adjusts Font requires using a Dynamic Type text style
    /// The second emerged as part of my attempt to resolve the first.
    ///
    func configureFonts() {

        let prevailingFont: UIFont
        if #available(iOS 11.0, *) {
            prevailingFont = WPStyleGuide.fontForTextStyle(UIFont.TextStyle.largeTitle)
        } else {
            let fontSize = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1).pointSize
            prevailingFont = WPFontManager.systemRegularFont(ofSize: fontSize)
        }
        selectedData.font = prevailingFont

        selectedData.adjustsFontForContentSizeCategory = true   // iOS 10
    }

    func setupFilterBar() {

        // If there is only one tab data, this is being displayed on the
        // Post Stats view, which does not have a filterTabBar.
        filterTabBar.isHidden = tabsData.count == 1

        chartBottomConstraint.constant = filterTabBar.isHidden ?
            ChartBottomMargin.filterTabBarHidden :
            ChartBottomMargin.filterTabBarShown

        Style.configureFilterTabBar(filterTabBar, forOverviewCard: true)
        filterTabBar.items = tabsData
        filterTabBar.tabBarHeight = 60.0
        filterTabBar.equalWidthFill = .fillProportionally
        filterTabBar.equalWidthSpacing = 12
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        // TODO: update chart - configureChartView() - via #11064
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

    func configureChartViewIfNeeded() {
        guard chartContainerView.subviews.isEmpty, let barChartData = chartData.first, let barChartStyling = chartStyling.first else {
            return
        }

        let chartView = StatsBarChartView(data: barChartData, styling: barChartStyling)
        chartContainerView.addSubview(chartView)

        NSLayoutConstraint.activate([
            chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            chartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
        ])
    }

    enum ChartBottomMargin {
        static let filterTabBarShown = CGFloat(16)
        static let filterTabBarHidden = CGFloat(24)
    }

}
