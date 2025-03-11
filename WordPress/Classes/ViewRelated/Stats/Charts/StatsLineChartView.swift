import UIKit
import DGCharts

// MARK: - StatsLineChartView

private let LineChartAnalyticsPropertyKey = "property"
private let LineChartAnalyticsPropertyGranularityKey = "granularity"

class StatsLineChartView: LineChartView {

    // MARK: Properties

    private struct Constants {
        static let intrinsicHeight = CGFloat(190)
        static let highlightLineWidth = 1.0
        static let highlightLineDashLengths = 4.4
        static let horizontalAxisLabelCount = 3
        static let rotationDelay = TimeInterval(0.35)
        static let topOffset = CGFloat(16)
        static let trailingOffset = CGFloat(8)
        static let verticalAxisLabelCount = 5
        static let xAxisWidth = 4.0
        static let xAxisTickWidth = 2.0
        static let lineWidth = 2.0
        static let numberOfXAxisTicks = 7
    }

    /// The type of stat shown on the chart i.e. subscribers, views & visitors, etc.
    ///
    private let statType: StatsLineChartConfiguration.StatType

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

    init(configuration: StatsLineChartConfiguration) {
        self.statType = configuration.type
        self.lineChartData = configuration.data
        self.styling = configuration.styling
        self.analyticsGranularity = configuration.analyticsGranularity
        self.xAxisDates = configuration.xAxisDates

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
    }

    func captureAnalyticsEvent() {
        var properties = [String: String]()

        if let specifiedAnalyticsGranularity = analyticsGranularity {
            properties[LineChartAnalyticsPropertyGranularityKey] = specifiedAnalyticsGranularity.rawValue
        }

        if case let .viewsAndVisitors(statsInsightsFilterDimension) = statType {
            properties[LineChartAnalyticsPropertyKey] = statsInsightsFilterDimension.analyticsProperty
            WPAnalytics.track(.statsLineChartTapped, properties: properties)
        } else if case .subscribers = statType {
            WPAnalytics.track(.statsSubscribersChartTapped)
        }
    }

    func configureAndPopulateData() {
        let lineChartData = self.lineChartData.lineChartData

        guard let dataSets = lineChartData.dataSets as? [LineChartDataSet] else {
            return
        }

        configureChartForMultipleDataSets(dataSets)

        configureLegendIfNeeded()

        data = lineChartData

        configureYAxis()
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

            let count = Constants.numberOfXAxisTicks
            let contentWidthMinusTicks = contentRect.width - (Constants.xAxisTickWidth * CGFloat(count))
            xAxis.axisLineDashLengths = [Constants.xAxisTickWidth, (contentWidthMinusTicks / CGFloat(count - 1))]
        }
    }

    func configureYAxis() {
        let yAxis = leftAxis

        yAxis.axisLineColor = styling.lineColor
        yAxis.drawAxisLineEnabled = false
        yAxis.drawLabelsEnabled = true
        yAxis.drawZeroLineEnabled = true
        yAxis.gridColor = styling.lineColor
        yAxis.labelTextColor = styling.labelColor
        yAxis.labelFont = WPStyleGuide.fontForTextStyle(.footnote, symbolicTraits: [], maximumPointSize: WPStyleGuide.Stats.maximumChartAxisFontPointSize)
        yAxis.valueFormatter = styling.yAxisValueFormatter
        yAxis.zeroLineColor = styling.lineColor

        // This adjustment is intended to prevent clipping observed with some labels
        // Potentially relevant : https://github.com/danielgindi/Charts/issues/992
        extraTopOffset = Constants.topOffset

        guard let data else { return }
        let yAxisMax = data.getYMax(axis: .left)

        if case .viewsAndVisitors = statType {
            yAxis.setLabelCount(Constants.verticalAxisLabelCount, force: true)

            yAxis.axisMinimum = 0

            let lowestMaxValue = Double(Constants.verticalAxisLabelCount - 1)
            let dataYMax = yAxisMax
            if dataYMax >= lowestMaxValue {
                yAxis.axisMaximum = VerticalAxisFormatter.roundUpAxisMaximum(dataYMax)
            } else {
                leftAxis.axisMaximum = lowestMaxValue
            }
        } else if case .subscribers = statType {
            let yAxisMin = data.getYMin(axis: .left)
            if yAxisMax == yAxisMin {
                yAxis.setLabelCount(Constants.verticalAxisLabelCount, force: true)

                yAxis.axisMinimum = 0
                yAxis.axisMaximum = yAxisMax * 2
            } else {

                let yAxisDelta = Int(yAxisMax) - Int(yAxisMin)
                let yAxisLabelCount = min(yAxisDelta + 1, Constants.verticalAxisLabelCount)
                yAxis.setLabelCount(yAxisLabelCount, force: true)

                // When a line appears on axis minimum or maximum it loses half of its width
                // Add/subtract little offset so line would appear full width
                let yAxisOffset = ((yAxisMax - yAxisMin) / 100)

                yAxis.axisMinimum = yAxisMin - yAxisOffset
                yAxis.axisMaximum = yAxisMax + yAxisOffset
            }
        }
    }

    func drawChartMarker(for entry: ChartDataEntry) {
        switch statType {
        case .viewsAndVisitors:
            marker = ViewsVisitorsChartMarker(dotColor: styling.primaryLineColor, name: styling.legendTitle ?? "")
        case .subscribers:
            let date = xAxisDates[Int(entry.x)]
            marker = SubscribersChartMarker(dotColor: styling.primaryLineColor, name: styling.legendTitle ?? "", date: date)
        }

        if let customMarker = self.marker as? StatsChartMarker {
            customMarker.chartView = self
        }
    }

    func highlightBar(for entry: ChartDataEntry) {
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
            self.highlightBar(for: entry)
        }
    }
}

// MARK: - ChartViewDelegate

extension StatsLineChartView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        captureAnalyticsEvent()
        highlightBar(for: entry)
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

class DateValueFormatter: NSObject, AxisValueFormatter {
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
