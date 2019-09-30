import UIKit

struct OverviewTabData: FilterTabBarItem {
    var tabTitle: String
    var tabData: Int
    var tabDataStub: String?
    var difference: Int
    var differencePercent: Int
    var date: Date?
    var period: StatsPeriodUnit?
    var analyticsStat: WPAnalyticsStat?

    init(tabTitle: String,
         tabData: Int,
         tabDataStub: String? = nil,
         difference: Int,
         differencePercent: Int,
         date: Date? = nil,
         period: StatsPeriodUnit? = nil,
         analyticsStat: WPAnalyticsStat? = nil) {
        self.tabTitle = tabTitle
        self.tabData = tabData
        self.tabDataStub = tabDataStub
        self.difference = difference
        self.differencePercent = differencePercent
        self.date = date
        self.period = period
        self.analyticsStat = analyticsStat
    }

    var attributedTitle: NSAttributedString? {

        let attributedTitle = NSMutableAttributedString(string: tabTitle.localizedUppercase)
        attributedTitle.addAttributes([.font: WPStyleGuide.Stats.overviewCardFilterTitleFont],
                                      range: NSMakeRange(0, attributedTitle.string.count))

        let dataString: String = {
            if let tabDataStub = tabDataStub {
                return tabDataStub
            }
            return tabData.abbreviatedString()
        }()

        let attributedData = NSMutableAttributedString(string: dataString)
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
        if let date = date,
            let period = period,
            StatsPeriodHelper().dateAvailableAfterDate(date, period: period) == false {
            return .neutral(.shade40)
        }

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

    private var chartData: [BarChartDataConvertible] = []
    private var chartStyling: [BarChartStyling] = []
    private weak var statsBarChartViewDelegate: StatsBarChartViewDelegate?
    private var chartHighlightIndex: Int?

    private var period: StatsPeriodUnit?

    // MARK: - Configure

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(tabsData: [OverviewTabData], barChartData: [BarChartDataConvertible] = [], barChartStyling: [BarChartStyling] = [], period: StatsPeriodUnit? = nil, statsBarChartViewDelegate: StatsBarChartViewDelegate? = nil, barChartHighlightIndex: Int? = nil) {
        self.tabsData = tabsData
        self.chartData = barChartData
        self.chartStyling = barChartStyling
        self.statsBarChartViewDelegate = statsBarChartViewDelegate
        self.chartHighlightIndex = barChartHighlightIndex
        self.period = period

        configureChartView()
        setupFilterBar()
        updateLabels()
    }
}

// MARK: - Private Extension

private extension OverviewCell {

    func applyStyles() {
        Style.configureCell(self)
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

        let prevailingFont = WPStyleGuide.fontForTextStyle(UIFont.TextStyle.largeTitle)
        selectedData.font = prevailingFont

        selectedData.adjustsFontForContentSizeCategory = true   // iOS 10
    }

    func setupFilterBar() {

        // If there is only one tab data, this is being displayed on the
        // Post Stats view, which does not have a filterTabBar.
        filterTabBar.isHidden = tabsData.count == 1

        // The filterTabBar has a bottom line, so hide the bottom line on the cell if the filterTabBar is showing.
        bottomSeparatorLine.isHidden = !filterTabBar.isHidden

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
        if let event = tabsData[filterTabBar.selectedIndex].analyticsStat {
            captureAnalyticsEvent(event)
        }

        configureChartView()
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

    func configureChartView() {
        let filterSelectedIndex = filterTabBar.selectedIndex

        guard chartData.count > filterSelectedIndex, chartStyling.count > filterSelectedIndex else {
            return
        }

        let configuration = StatsBarChartConfiguration(data: chartData[filterSelectedIndex],
                                                       styling: chartStyling[filterSelectedIndex],
                                                       analyticsGranularity: period?.analyticsGranularity,
                                                       indexToHighlight: chartHighlightIndex)
        let chartView = StatsBarChartView(configuration: configuration, delegate: statsBarChartViewDelegate)

        resetChartContainerView()
        chartContainerView.addSubview(chartView)

        NSLayoutConstraint.activate([
            chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            chartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
            ])
    }

    func resetChartContainerView() {
        for subview in chartContainerView.subviews {
            subview.removeFromSuperview()
        }
    }

    enum ChartBottomMargin {
        static let filterTabBarShown = CGFloat(16)
        static let filterTabBarHidden = CGFloat(24)
    }

    // MARK: - Analytics support

    func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        let properties: [AnyHashable: Any] = [StatsPeriodUnit.analyticsPeriodKey: period?.description as Any]

        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, withProperties: properties, withBlogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event, withProperties: properties)
        }
    }

}
