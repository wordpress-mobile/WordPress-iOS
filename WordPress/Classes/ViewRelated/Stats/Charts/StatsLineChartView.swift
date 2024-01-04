import UIKit
import DGCharts

// MARK: - StatsLineChartViewDelegate

protocol StatsLineChartViewDelegate: AnyObject {
    func statsLineChartValueSelected(_ statsLineChartView: StatsLineChartView, entryIndex: Int, entryCount: Int)
}

// MARK: - StatsLineChartView

private let LineChartAnalyticsPropertyKey = "property"
private let LineChartAnalyticsPropertyGranularityKey = "granularity"

class StatsLineChartView: LineChartView {

    // MARK: Properties

    private struct Constants {
        static let intrinsicHeight          = CGFloat(190)
        static let highlightAlpha           = CGFloat(1)
        static let highlightLineWidth       = 1.0
        static let highlightLineDashLengths = 4.4
        static let horizontalAxisLabelCount = 3
        static let presentationDelay        = TimeInterval(0.5)
        static let rotationDelay            = TimeInterval(0.35)
        static let secondaryDataSetIndex    = 1
        static let topOffset                = CGFloat(16)
        static let trailingOffset           = CGFloat(8)
        static let verticalAxisLabelCount   = 5
        static let xAxisWidth               = 4.0
        static let xAxisTickWidth           = 2.0
        static let lineWidth                = 2.0
        static let numberDaysInWeek         = 7
    }

    /// This adapts the data set for presentation by the Charts framework.
    ///
    private let lineChartData: LineChartDataConvertible

    /// This influences the visual appearance of the chart to be rendered.
    ///
    private let styling: LineChartStyling

    /// This informs the analytics event captured via user interaction.
    ///
    private let analyticsGranularity: LineChartAnalyticsPropertyGranularityValue?

    /// Dates to populate the x-axis
    ///
    private var xAxisDates: [Date]

    /// When set, the delegate is advised of user-initiated line selections
    ///
    private weak var statsLineChartViewDelegate: StatsLineChartViewDelegate?

    private var statsInsightsFilterDimension: StatsInsightsFilterDimension

    private var isHighlightNeeded: Bool {
        guard let primaryDataSet = primaryDataSet, primaryDataSet.isHighlightEnabled else {
            return false
        }
        return styling.primaryHighlightColor != nil
    }

    private var primaryDataSet: ChartDataSetProtocol? {
        return data?.dataSets.first
    }


    // MARK: StatsLineChartView

    override var bounds: CGRect {
        didSet {
            redrawChartMarkersIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateXAxisTicks()
    }

    init(configuration: StatsLineChartConfiguration, delegate: StatsLineChartViewDelegate? = nil, statsInsightsFilterDimension: StatsInsightsFilterDimension = .views) {
        self.lineChartData = configuration.data
        self.styling = configuration.styling
        self.analyticsGranularity = configuration.analyticsGranularity
        self.statsLineChartViewDelegate = delegate
        self.xAxisDates = configuration.xAxisDates
        self.statsInsightsFilterDimension = statsInsightsFilterDimension

        super.init(frame: .zero)

        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Constants.intrinsicHeight)
    }
}

// MARK: - Private behavior

private extension StatsLineChartView {

    func applyStyling() {
        configureLineChartViewBaseProperties()
        configureChartViewBaseProperties()

        configureXAxis()
        configureYAxis()
    }

    func captureAnalyticsEvent() {
        var properties = [String: String]()

        if let specifiedAnalyticsGranularity = analyticsGranularity {
            properties[LineChartAnalyticsPropertyGranularityKey] = specifiedAnalyticsGranularity.rawValue
        }

        properties[LineChartAnalyticsPropertyKey] = statsInsightsFilterDimension.analyticsProperty

        WPAnalytics.track(.statsLineChartTapped, properties: properties)
    }

    func configureAndPopulateData() {
        let lineChartData = self.lineChartData.lineChartData

        guard let dataSets = lineChartData.dataSets as? [LineChartDataSet] else {
            return
        }

        configureChartForMultipleDataSets(dataSets)

        configureLegendIfNeeded()

        data = lineChartData

        configureYAxisMaximum()
    }

    func configureLineChartViewBaseProperties() {
        doubleTapToZoomEnabled = false
        dragXEnabled = false
        dragYEnabled = false
        pinchZoomEnabled = false

        drawBordersEnabled = false
        drawGridBackgroundEnabled = false

        minOffset = CGFloat(0)

        rightAxis.enabled = false

        scaleXEnabled = false
        scaleYEnabled = false
    }

    func configureChartForMultipleDataSets(_ dataSets: [LineChartDataSet]) {
        // Primary
        guard let primaryDataSet = dataSets.first else {
            return
        }
        primaryDataSet.colors = [ styling.primaryLineColor ]
        primaryDataSet.drawValuesEnabled = false
        primaryDataSet.drawCirclesEnabled = false
        primaryDataSet.lineWidth = Constants.lineWidth
        primaryDataSet.mode = .horizontalBezier

        let gradientColors = [styling.primaryLineColor.withAlphaComponent(1).cgColor,
                              styling.primaryLineColor.withAlphaComponent(0).cgColor]
        if let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil) {
            primaryDataSet.fillAlpha = 0.1
            primaryDataSet.fill = LinearGradientFill(gradient: gradient, angle: 0)
            primaryDataSet.drawFilledEnabled = true
        }

        if let initialHighlightColor = styling.primaryHighlightColor {
            primaryDataSet.highlightColor = initialHighlightColor
            primaryDataSet.highlightLineWidth = Constants.highlightLineWidth
            primaryDataSet.highlightLineDashLengths = [Constants.highlightLineDashLengths]
            primaryDataSet.drawHorizontalHighlightIndicatorEnabled = false
            primaryDataSet.highlightEnabled = true
        } else {
            primaryDataSet.highlightEnabled = false
            highlightPerTapEnabled = false
        }

        // Secondary
        guard dataSets.count > 1, let secondaryBarColor = styling.secondaryLineColor else {
            return
        }
        let secondaryDataSet = dataSets[1]
        secondaryDataSet.colors = [ secondaryBarColor ]
        secondaryDataSet.drawValuesEnabled = false
        secondaryDataSet.drawCirclesEnabled = false
        secondaryDataSet.lineWidth = Constants.lineWidth
        secondaryDataSet.mode = .horizontalBezier
        secondaryDataSet.highlightEnabled = false
    }

    func configureChartViewBaseProperties() {
        dragDecelerationEnabled = false
        extraRightOffset = Constants.trailingOffset
    }

    func configureLegendIfNeeded() {
        legend.enabled = false
    }

    func configureXAxis() {
        xAxis.axisLineColor = styling.lineColor
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = styling.labelColor
        xAxis.labelFont = WPStyleGuide.fontForTextStyle(.footnote, symbolicTraits: [], maximumPointSize: WPStyleGuide.Stats.maximumChartAxisFontPointSize)
        xAxis.setLabelCount(Constants.horizontalAxisLabelCount, force: true)

        let dateValueFormattter = DateValueFormatter()
        dateValueFormattter.xAxisDates = xAxisDates
        xAxis.valueFormatter = dateValueFormattter
        xAxis.avoidFirstLastClippingEnabled = true
    }

    func updateXAxisTicks() {
        if contentRect.width > 0 {
            xAxis.axisLineWidth = Constants.xAxisWidth

            let count = max(xAxisDates.count, Constants.numberDaysInWeek)
            let contentWidthMinusTicks = contentRect.width - (Constants.xAxisTickWidth * CGFloat(count))
            xAxis.axisLineDashLengths = [Constants.xAxisTickWidth, (contentWidthMinusTicks / CGFloat(count - 1))]
        }
    }

    func configureYAxis() {
        let yAxis = leftAxis

        yAxis.axisLineColor = styling.lineColor
        yAxis.axisMinimum = 0.0
        yAxis.drawAxisLineEnabled = false
        yAxis.drawLabelsEnabled = true
        yAxis.drawZeroLineEnabled = true
        yAxis.gridColor = styling.lineColor
        yAxis.labelTextColor = styling.labelColor
        yAxis.labelFont = WPStyleGuide.fontForTextStyle(.footnote, symbolicTraits: [], maximumPointSize: WPStyleGuide.Stats.maximumChartAxisFontPointSize)
        yAxis.setLabelCount(Constants.verticalAxisLabelCount, force: true)
        yAxis.valueFormatter = styling.yAxisValueFormatter
        yAxis.zeroLineColor = styling.lineColor

        // This adjustment is intended to prevent clipping observed with some labels
        // Potentially relevant : https://github.com/danielgindi/Charts/issues/992
        extraTopOffset = Constants.topOffset
    }

    func configureYAxisMaximum() {
        let lowestMaxValue = Double(Constants.verticalAxisLabelCount - 1)

        if let maxY = data?.getYMax(axis: .left),
           maxY >= lowestMaxValue {
            leftAxis.axisMaximum = VerticalAxisFormatter.roundUpAxisMaximum(maxY)
        } else {
            leftAxis.axisMaximum = lowestMaxValue
        }
    }

    func drawChartMarker(for entry: ChartDataEntry) {
        marker = ViewsVisitorsChartMarker.init(dotColor: styling.primaryLineColor, name: styling.legendTitle ?? "")
        if let customMarker = self.marker as? ViewsVisitorsChartMarker {
            customMarker.chartView = self
        }
    }

    func highlightBar(for entry: ChartDataEntry, with highlight: Highlight) {
        drawChartMarker(for: entry)
    }

    func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        delegate = self

        applyStyling()
        prepareForVoiceOver()
        configureAndPopulateData()
    }

    func redrawChartMarkersIfNeeded() {
        guard marker != nil, let highlight = lastHighlighted, let entry = lineData?.entry(for: highlight) else {
            return
        }

        notifyDataSetChanged()

        let postRotationDelay = DispatchTime.now() + Constants.rotationDelay
        DispatchQueue.main.asyncAfter(deadline: postRotationDelay) {
            self.highlightBar(for: entry, with: highlight)
        }
    }
}

// MARK: - ChartViewDelegate

private typealias StatsLineChartMarker = MarkerView

extension StatsLineChartView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        captureAnalyticsEvent()
        highlightBar(for: entry, with: highlight)
    }
}

// MARK: - Accessible

extension StatsLineChartView: Accessible {
    func prepareForVoiceOver() {
        // ChartDataRendererBase creates a meaningful a11y description, relying on the chart description
        chartDescription.text = lineChartData.accessibilityDescription
        chartDescription.enabled = false    // disabling the description hides a corresponding label
    }
}

private class DateValueFormatter: NSObject, AxisValueFormatter {
    var dateFormatter: DateFormatter
    var xAxisDates: [Date] = []

    public override init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
    }

    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = xAxisDates[Int(value)]
        return dateFormatter.string(from: date)
    }
}
