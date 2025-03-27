import UIKit
import WordPressUI
import WordPressShared

struct OverviewTabData: FilterTabBarItem, Hashable {
    var tabTitle: String
    var tabData: Int
    var tabDataStub: String?
    var difference: Int
    var differencePercent: Int
    var date: Date?
    var period: StatsPeriodUnit?
    var analyticsStat: WPAnalyticsStat?

    private(set) var accessibilityHint: String?

    init(tabTitle: String,
         tabData: Int,
         tabDataStub: String? = nil,
         difference: Int,
         differencePercent: Int,
         date: Date? = nil,
         period: StatsPeriodUnit? = nil,
         analyticsStat: WPAnalyticsStat? = nil,
         accessibilityHint: String? = nil) {
        self.tabTitle = tabTitle
        self.tabData = tabData
        self.tabDataStub = tabDataStub
        self.difference = difference
        self.differencePercent = differencePercent
        self.date = date
        self.period = period
        self.analyticsStat = analyticsStat
        self.accessibilityHint = accessibilityHint
    }

    var attributedTitle: NSAttributedString? {

        let attributedTitle = NSMutableAttributedString(string: tabTitle.localizedUppercase)
        attributedTitle.addAttributes([.font: WPStyleGuide.Stats.overviewCardFilterTitleFont],
                                      range: NSMakeRange(0, attributedTitle.string.count))

        let dataString: String = {
            if let tabDataStub {
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
        let stringFormat = NSLocalizedString(
            "stats.overview.differenceLabelWithNumber",
            value: "%1$@%2$@ (%3$@)",
            comment: "Text for the Stats Traffic Overview stat difference label. Shows the change from the previous period, including the percentage value. E.g.: +12.3K (5%). %1$@ is the placeholder for the change sign ('-', '+', or none). %2$@ is the placeholder for the change numerical value. %3$@ is the placeholder for the change percentage value."
        )

        return String.localizedStringWithFormat(stringFormat,
                                                difference < 0 ? "" : "+",
                                                difference.abbreviatedString(),
                                                differencePercent.percentageString())
    }

    var differenceTextColor: UIColor {
        if let date,
            let period,
            StatsPeriodHelper().dateAvailableAfterDate(date, period: period) == false {
            return UIAppColor.neutral(.shade40)
        }

        return difference < 0 ? WPStyleGuide.Stats.negativeColor : WPStyleGuide.Stats.positiveColor
    }

    var title: String {
        return self.tabTitle
    }

    var accessibilityIdentifier: String {
        return self.tabTitle.localizedLowercase
    }

    var accessibilityLabel: String? {
        tabTitle
    }

    var accessibilityValue: String? {
        return tabDataStub != nil ? "" : "\(tabData)"
    }

    // MARK: - Equatable

    static func == (lhs: OverviewTabData, rhs: OverviewTabData) -> Bool {
        return lhs.tabTitle == rhs.tabTitle &&
            lhs.tabData == rhs.tabData &&
            lhs.difference == rhs.difference &&
            lhs.differencePercent == rhs.differencePercent
    }
}

class OverviewCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var topSeparatorLine: UIView!
    @IBOutlet weak var labelsStackView: UIStackView!
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

    func configure(tabsData: [OverviewTabData],
                   barChartData: [BarChartDataConvertible] = [],
                   barChartStyling: [BarChartStyling] = [],
                   period: StatsPeriodUnit? = nil,
                   statsBarChartViewDelegate: StatsBarChartViewDelegate? = nil,
                   barChartHighlightIndex: Int? = nil,
                   tabIndex: Int) {
        self.tabsData = tabsData
        self.chartData = barChartData
        self.chartStyling = barChartStyling
        self.statsBarChartViewDelegate = statsBarChartViewDelegate
        self.chartHighlightIndex = barChartHighlightIndex
        self.period = period

        setupFilterBar(selectedIndex: tabIndex)
        configureLabelsStackView()
        configureChartView()
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
    }

    func setupFilterBar(selectedIndex: Int) {

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

        filterTabBar.dividerColor = .clear
        filterTabBar.setSelectedIndex(selectedIndex, animated: false)
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        if let event = tabsData[filterTabBar.selectedIndex].analyticsStat {
            captureAnalyticsEvent(event)
        }

        configureChartView()
        updateLabels()
        statsBarChartViewDelegate?.statsBarChartTabSelected(filterTabBar.selectedIndex)
    }

    func updateLabels() {
        let tabData = tabsData[filterTabBar.selectedIndex]
        selectedLabel.text = tabData.tabTitle
        selectedData.text = tabData.tabData.abbreviatedString(forHeroNumber: true)
        differenceLabel.text = tabData.differenceLabel
        differenceLabel.textColor = tabData.differenceTextColor
    }

    func configureLabelsStackView() {
        // If isAccessibilityCategory, display the labels vertically.
        // This makes the differenceLabel "wrap" and appear under the selectedLabel.

        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            labelsStackView.axis = .vertical
            labelsStackView.alignment = .leading
            labelsStackView.distribution = .fill
        } else {
            labelsStackView.axis = .horizontal
            labelsStackView.alignment = .firstBaseline
            labelsStackView.distribution = .equalSpacing
        }
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

        // There's a weird bug that happens when the user switches to a different tab
        // (Views, Visitors, Likes, or Comments). VoiceOver would read the previous chart's
        // accessibility label and would even not allow you to select the individual bar chart items.
        //
        // Forcing the `accessibilityElements` fixes this. ¯\_(ツ)_/¯
        chartContainerView.accessibilityElements = [chartView]

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
        let properties: [String: Any] = [StatsPeriodUnit.analyticsPeriodKey: period?.description as Any]

        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, properties: properties, blogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event, withProperties: properties)
        }
    }

}
