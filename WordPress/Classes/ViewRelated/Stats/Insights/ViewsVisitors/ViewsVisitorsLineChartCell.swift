import UIKit

struct StatsSegmentedControlData: Equatable {
    var segmentTitle: String
    var segmentData: Int
    var segmentPrevData: Int
    var segmentDataStub: String?
    var difference: Int
    var differenceText: String
    var differencePercent: Int
    var date: Date?
    var period: StatsPeriodUnit?
    var analyticsStat: WPAnalyticsStat?

    enum Segment: Int {
        case views
        case visitors
    }

    private(set) var accessibilityHint: String?

    init(segmentTitle: String, segmentData: Int, segmentPrevData: Int, difference: Int, differenceText: String, segmentDataStub: String? = nil, date: Date? = nil, period: StatsPeriodUnit? = nil, analyticsStat: WPAnalyticsStat? = nil, accessibilityHint: String? = nil, differencePercent: Int) {
        self.segmentTitle = segmentTitle
        self.segmentData = segmentData
        self.segmentPrevData = segmentPrevData
        self.segmentDataStub = segmentDataStub
        self.difference = difference
        self.differenceText = differenceText
        self.differencePercent = differencePercent
        self.date = date
        self.period = period
        self.analyticsStat = analyticsStat
        self.accessibilityHint = accessibilityHint
    }

    var attributedDifferenceText: NSAttributedString? {
        guard difference != 0 || segmentData > 0 else {
            // No comparison shown if there's no change and 0 data
            return nil
        }

        let defaultAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline), NSAttributedString.Key.foregroundColor: UIColor.textSubtle]

        if difference == 0 && segmentData != 0 {
            return NSAttributedString(string: differenceText, attributes: defaultAttributes)
        }

        let differenceText = String(format: differenceText, differenceLabel)
        let attributedString = NSMutableAttributedString(string: differenceText, attributes: defaultAttributes)

        let str = attributedString.string as NSString
        let range = str.range(of: differenceLabel)

        attributedString.addAttributes([.foregroundColor: differenceTextColor,
                                        .font: UIFont.preferredFont(forTextStyle: .subheadline).bold()],
                range: NSRange(location: range.location, length: differenceLabel.count))

        return attributedString
    }

    var differenceLabel: String {
        // We want to show something like "+10.2K (+5%)" if we have a percentage difference and "1.2K" if we don't.
        //
        // Negative cases automatically appear with a negative sign "-10.2K (-5%)" by using `abbreviatedString()`.
        // `abbreviatedString()` also handles formatting big numbers, i.e. 10,200 will become 10.2K.
        let formatter = NumberFormatter()
        formatter.locale = .current
        let plusSign = difference <= 0 ? "" : "\(formatter.plusSign ?? "")"

        if differencePercent != 0 {
            let stringFormat = NSLocalizedString(
                "insights.visitorsLineChartCell.differenceLabelWithPercentage",
                value: "%1$@%2$@ (%3$@%%)",
                comment: "Text for the Insights Overview stat difference label. Shows the change from the previous period, including the percentage value. E.g.: +12.3K (5%). %1$@ is the placeholder for the change sign ('-', '+', or none). %2$@ is the placeholder for the change numerical value. %3$@ is the placeholder for the change percentage value, excluding the % sign."
            )
            return String.localizedStringWithFormat(
                stringFormat,
                plusSign,
                difference.abbreviatedString(),
                differencePercent.abbreviatedString()
            )
        } else {
            let stringFormat = NSLocalizedString(
                "insights.visitorsLineChartCell.differenceLabelWithoutPercentage",
                value: "%1$@%2$@",
                comment: "Text for the Insights Overview stat difference label. Shows the change from the previous period. E.g.: +12.3K. %1$@ is the placeholder for the change sign ('-', '+', or none). %2$@ is the placeholder for the change numerical value."
            )
            return String.localizedStringWithFormat(
                stringFormat,
                plusSign,
                difference.abbreviatedString()
            )
        }
    }

    var differenceTextColor: UIColor {
        return difference < 0 ? WPStyleGuide.Stats.negativeColor : WPStyleGuide.Stats.positiveColor
    }

    var title: String {
        return self.segmentTitle
    }

    var accessibilityIdentifier: String {
        return self.segmentTitle.localizedLowercase
    }

    var accessibilityLabel: String? {
        segmentTitle
    }

    var accessibilityValue: String? {
        return segmentDataStub != nil ? "" : "\(segmentData)"
    }
}

protocol StatsInsightsViewsAndVisitorsDelegate: AnyObject {
    func viewsAndVisitorsSegmendChanged(to selectedSegmentIndex: Int)
}

class ViewsVisitorsLineChartCell: StatsBaseCell, NibLoadable {

    @IBOutlet weak var labelsStackView: UIStackView!
    @IBOutlet weak var legendLatestView: UIView!
    @IBOutlet weak var legendLatestLabel: UILabel!
    @IBOutlet weak var latestLabel: UILabel!
    @IBOutlet weak var latestData: UILabel!
    @IBOutlet weak var legendPreviousView: UIView!
    @IBOutlet weak var legendPreviousLabel: UILabel!
    @IBOutlet weak var previousLabel: UILabel!
    @IBOutlet weak var previousData: UILabel!
    @IBOutlet var differenceLabel: UILabel!
    @IBOutlet weak var chartContainerView: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var bottomStackView: UIStackView!

    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private weak var viewsAndVisitorsDelegate: StatsInsightsViewsAndVisitorsDelegate?

    private typealias Style = WPStyleGuide.Stats
    private var segmentsData = [StatsSegmentedControlData]()

    private var chartData: [LineChartDataConvertible] = []
    private var chartStyling: [LineChartStyling] = []
    private weak var statsLineChartViewDelegate: StatsLineChartViewDelegate?
    private var chartHighlightIndex: Int?

    private var period: StatsPeriodUnit?
    private var xAxisDates: [Date] = []

    fileprivate lazy var tipView: DashboardStatsNudgeView = {
        let tipView = DashboardStatsNudgeView(title: Constants.topTipsText, hint: nil, insets: .zero)
        tipView.onTap = { [weak self] in
            if let url = URL(string: Constants.topTipsURLString) {
                self?.siteStatsInsightsDelegate?.displayWebViewWithURL?(url)
            }
        }
        return tipView
    }()

    // MARK: - Configure

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(row: ViewsVisitorsRow) {
        siteStatsInsightsDelegate = row.siteStatsInsightsDelegate
        siteStatsInsightDetailsDelegate = row.siteStatsInsightsDelegate
        statSection = .insightsViewsVisitors

        self.segmentsData = row.segmentsData
        self.chartData = row.chartData
        self.chartStyling = row.chartStyling
        self.statsLineChartViewDelegate = row.statsLineChartViewDelegate
        self.viewsAndVisitorsDelegate = row.viewsAndVisitorsDelegate
        self.period = row.period
        self.xAxisDates = row.xAxisDates

        setupSegmentedControl(selectedSegment: row.selectedSegment)
        configureChartView()
        updateLabels()
    }

    @IBAction func selectedSegmentDidChange(_ sender: Any) {
        let selectedSegmentIndex = segmentedControl.selectedSegmentIndex
        captureAnalyticsEvent(selectedSegmentIndex)

        configureChartView()
        updateLabels()

        viewsAndVisitorsDelegate?.viewsAndVisitorsSegmendChanged(to: selectedSegmentIndex)
    }
}

// MARK: - Private Extension

private extension ViewsVisitorsLineChartCell {

    func applyStyles() {
        Style.configureCell(self)
        styleLabels()
    }

    func setupSegmentedControl(selectedSegment: StatsSegmentedControlData.Segment) {
        segmentedControl.selectedSegmentTintColor = UIColor.white
        segmentedControl.setTitleTextAttributes([.font: UIFont.preferredFont(forTextStyle: .subheadline).bold()], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        segmentedControl.setTitle(segmentsData[0].segmentTitle, forSegmentAt: 0)
        segmentedControl.setTitle(segmentsData[1].segmentTitle, forSegmentAt: 1)
        segmentedControl.selectedSegmentIndex = selectedSegment.rawValue
    }

    func styleLabels() {
        latestData.font = UIFont.preferredFont(forTextStyle: .title2).bold()
        latestData.adjustsFontSizeToFitWidth = true
        latestLabel.adjustsFontSizeToFitWidth = true

        previousData.font = UIFont.preferredFont(forTextStyle: .title2).bold()
        previousData.adjustsFontSizeToFitWidth = true
        previousLabel.adjustsFontSizeToFitWidth = true

        legendLatestLabel.text = NSLocalizedString("stats.insights.label.viewsVisitorsLastDays", value: "Last 7-days", comment: "Last 7-days legend label")
        legendLatestLabel.adjustsFontSizeToFitWidth = true
        legendPreviousLabel.text = NSLocalizedString("stats.insights.label.viewsVisitorsPreviousDays", value: "Previous 7-days", comment: "Previous 7-days legend label")
        legendPreviousLabel.adjustsFontSizeToFitWidth = true
    }

    func updateLabels() {
        let selectedSegmentIndex = segmentedControl.selectedSegmentIndex

        guard chartStyling.count > selectedSegmentIndex, segmentsData.count > selectedSegmentIndex else {
            return
        }

        let chartStyle = chartStyling[selectedSegmentIndex]
        legendLatestView.backgroundColor = chartStyle.primaryLineColor
        legendLatestLabel.textColor = chartStyle.primaryLineColor
        latestData.textColor = chartStyle.primaryLineColor
        latestLabel.textColor = chartStyle.primaryLineColor

        let segmentData = segmentsData[selectedSegmentIndex]
        latestLabel.text = segmentData.segmentTitle
        previousLabel.text = segmentData.segmentTitle

        latestData.text = segmentData.segmentData.abbreviatedString(forHeroNumber: true)
        previousData.text = segmentData.segmentPrevData.abbreviatedString(forHeroNumber: true)

        differenceLabel.attributedText = segmentData.attributedDifferenceText

        if segmentData.segmentData == 0 && segmentData.segmentPrevData == 0 {
            differenceLabel.removeFromSuperview()
            bottomStackView.addArrangedSubview(tipView)
        } else {
            tipView.removeFromSuperview()
            bottomStackView.addArrangedSubview(differenceLabel)
        }
    }

    // MARK: Chart support

    func configureChartView() {
        let selectedSegmentIndex = segmentedControl.selectedSegmentIndex

        guard chartData.count > selectedSegmentIndex, chartStyling.count > selectedSegmentIndex else {
            return
        }

        let configuration = StatsLineChartConfiguration(data: chartData[selectedSegmentIndex],
                                                       styling: chartStyling[selectedSegmentIndex],
                                                       analyticsGranularity: period?.analyticsGranularityLine,
                                                       indexToHighlight: 0,
                                                       xAxisDates: xAxisDates)

        let statsInsightsFilterDimension: StatsInsightsFilterDimension = selectedSegmentIndex == 0 ? .views : .visitors

        let chartView = StatsLineChartView(configuration: configuration, delegate: statsLineChartViewDelegate, statsInsightsFilterDimension: statsInsightsFilterDimension)

        resetChartContainerView()
        chartContainerView.addSubview(chartView)
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

    // MARK: - Analytics support

    func captureAnalyticsEvent(_ selectedSegmentIndex: Int) {
        let statsInsightsFilterDimension: StatsInsightsFilterDimension = selectedSegmentIndex == 0 ? .views : .visitors

        let properties: [String: String] = ["value": statsInsightsFilterDimension.analyticsProperty]

        if let blogId = SiteStatsInformation.sharedInstance.siteID,
           let blog = Blog.lookup(withID: blogId, in: ContextManager.sharedInstance().mainContext) {
            WPAnalytics.track(.statsInsightsViewsVisitorsToggled, properties: properties, blog: blog)
        } else {
            WPAnalytics.track(.statsInsightsViewsVisitorsToggled, properties: properties)
        }
    }

    enum Constants {
        static let topTipsText = NSLocalizedString("Check out our top tips to increase your views and traffic", comment: "Title for a button that opens up the 'Getting More Views and Traffic' support page when tapped.")
        static let topTipsURLString = "https://wordpress.com/support/getting-more-views-and-traffic/"
    }
}
