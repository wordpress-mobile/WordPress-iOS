import UIKit
import Charts

// MARK: - StatsBarChartViewDelegate

protocol StatsBarChartViewDelegate: AnyObject {
    func statsBarChartValueSelected(_ statsBarChartView: StatsBarChartView, entryIndex: Int, entryCount: Int)
}

// MARK: - StatsBarChartView

private let BarChartAnalyticsPropertyGranularityKey = "granularity"

class StatsBarChartView: BarChartView {

    // MARK: Properties

    private struct Constants {
        static let intrinsicHeight          = CGFloat(150)
        static let highlightAlpha           = CGFloat(1)
        static let horizontalAxisLabelCount = 2
        static let markerAlpha              = CGFloat(0.1)
        static let presentationDelay        = TimeInterval(0.01)
        static let primaryDataSetIndex      = 0
        static let rotationDelay            = TimeInterval(0.35)
        static let secondaryDataSetIndex    = 1
        static let topOffsetSansLegend      = CGFloat(5)
        static let topOffsetWithLegend      = CGFloat(16)
        static let trailingOffset           = CGFloat(20)
        static let verticalAxisLabelCount   = 5
    }

    /// Height for "stub" bars when a chart is empty, which is the height of the default chart.
    /// The value is just shy of the default height to prevent the chart height from automatically expanding.
    ///
    static let emptyChartBarHeight = Double(Constants.verticalAxisLabelCount - 1) - 0.01

    /// This adapts the data set for presentation by the Charts framework.
    ///
    private let barChartData: BarChartDataConvertible

    /// This influences the visual appearance of the chart to be rendered.
    ///
    private let styling: BarChartStyling

    /// This informs the analytics event captured via user interaction.
    ///
    private let analyticsGranularity: BarChartAnalyticsPropertyGranularityValue?

    /// Highlights the bar for the specified index; unspecified, the last bar is highlighted
    ///
    private var highlightIndex: Int?

    /// When set, the delegate is advised of user-initiated bar selections
    ///
    private weak var statsBarChartViewDelegate: StatsBarChartViewDelegate?

    /// When set, this stock `UIView` serves as a legend for the rendered chart.
    ///
    private var legendView: UIView?

    private var isHighlightNeeded: Bool {
        guard let primaryDataSet = primaryDataSet, primaryDataSet.isHighlightEnabled else {
            return false
        }
        return styling.primaryHighlightColor != nil
    }

    private var prevailingHighlightIndex: Int {
        if let specifiedHighlightIndex = highlightIndex {
            return specifiedHighlightIndex
        }

        let lastEntryIndex: Int
        if let barCount = primaryDataSet?.entryCount, barCount > 1 {
            lastEntryIndex = barCount - 1
        } else {
            lastEntryIndex = 0
        }

        return lastEntryIndex
    }

    private var primaryDataSet: IChartDataSet? {
        return data?.dataSets.first
    }

    // MARK: StatsBarChartView

    override var bounds: CGRect {
        didSet {
            redrawChartMarkersIfNeeded()
        }
    }

    init(configuration: StatsBarChartConfiguration, delegate: StatsBarChartViewDelegate? = nil) {
        self.barChartData = configuration.data
        self.styling = configuration.styling
        self.analyticsGranularity = configuration.analyticsGranularity
        self.statsBarChartViewDelegate = delegate
        self.highlightIndex = configuration.indexToHighlight

        super.init(frame: .zero)

        initialize()
        setupGestures()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Constants.intrinsicHeight)
    }
}

// MARK: - Private behavior

private extension StatsBarChartView {
    func setupGestures() {
        gestureRecognizers = gestureRecognizers?.filter { gesture in
            if let gesture = gesture as? UITapGestureRecognizer {
                return gesture.numberOfTapsRequired != 1
            }
            return true
        }
        let tapGestureRecognizer = NSUITapGestureRecognizer(target: self, action: #selector(barTapGestureRecognized(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func barTapGestureRecognized(_ recognizer: NSUITapGestureRecognizer) {
        if data != nil, recognizer.state == .ended,
            let highlight = getHighlightByTouchPoint(recognizer.location(in: self)),
            highlight != lastHighlighted {
            lastHighlighted = highlight
            highlightValue(highlight, callDelegate: true)
        }
    }

    func applyStyling() {
        configureBarChartViewProperties()
        configureBarLineChartViewBaseProperties()
        configureChartViewBaseProperties()

        configureXAxis()
        configureYAxis()
    }

    func broadcastBarHighlightIfNeeded(for entry: ChartDataEntry) {
        guard let delegate = statsBarChartViewDelegate, let dataSet = primaryDataSet else {
            return
        }

        let entryIndex = dataSet.entryIndex(entry: entry)
        let entryCount = dataSet.entryCount

        delegate.statsBarChartValueSelected(self, entryIndex: entryIndex, entryCount: entryCount)
    }

    /// Unfortunately the framework doesn't offer much in the way of Auto Layout support,
    /// so here we manually calculate geometry.
    ///
    /// - Parameter entry: the selected entry for which to determine highlight information
    /// - Returns: the frame & offset from the bar that should be used to render the marker
    ///
    func calculateMarkerFrameAndOffset(for entry: ChartDataEntry) -> (frame: CGRect, offset: CGPoint) {
        guard let barChartDataEntry = entry as? BarChartDataEntry else {
            return (.zero, .zero)
        }

        let barBounds = getBarBounds(entry: barChartDataEntry)

        let markerWidth = barBounds.width
        let markerHeight = viewPortHandler.contentRect.height * 2   // 2x addresses a visual glitch with two data sets
        let markerSize = CGSize(width: markerWidth, height: markerHeight)

        let rect = CGRect(origin: barBounds.origin, size: markerSize)

        let offsetWidth = -(barBounds.width / 2)
        let offsetHeight = -markerHeight
        let offset = CGPoint(x: offsetWidth, y: offsetHeight)

        return (rect, offset)
    }

    func captureAnalyticsEvent() {
        var properties = [String: String]()

        if let specifiedAnalyticsGranularity = analyticsGranularity {
            properties[BarChartAnalyticsPropertyGranularityKey] = specifiedAnalyticsGranularity.rawValue
        }

        WPAnalytics.track(.statsOverviewBarChartTapped, withProperties: properties)
    }

    func configureAndPopulateData() {
        let barChartData = self.barChartData.barChartData

        guard let dataSets = barChartData.dataSets as? [BarChartDataSet], let initialDataSet = dataSets.first else {
            return
        }

        if dataSets.count > 1 {
            configureChartForMultipleDataSets(dataSets)
        } else {
            configureChartForSingleDataSet(initialDataSet)
        }

        configureLegendIfNeeded()
        data = barChartData

        configureYAxisMaximum()
    }

    func configureBarChartViewProperties() {
        drawBarShadowEnabled = false
        drawValueAboveBarEnabled = false
        clipValuesToContentEnabled = false
        fitBars = true
    }

    func configureBarLineChartViewBaseProperties() {
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

    func configureChartForMultipleDataSets(_ dataSets: [BarChartDataSet]) {
        // Primary
        guard let primaryDataSet = dataSets.first else {
            return
        }
        primaryDataSet.colors = [ styling.primaryBarColor ]
        primaryDataSet.drawValuesEnabled = false

        if let initialHighlightColor = styling.primaryHighlightColor {
            primaryDataSet.highlightAlpha = Constants.highlightAlpha
            primaryDataSet.highlightColor = initialHighlightColor
            primaryDataSet.highlightEnabled = true
        } else {
            primaryDataSet.highlightEnabled = false
            highlightPerTapEnabled = false
        }

        // Secondary
        guard dataSets.count > 1, let secondaryBarColor = styling.secondaryBarColor else {
            return
        }
        let secondaryDataSet = dataSets[1]

        secondaryDataSet.colors = [ secondaryBarColor ]
        secondaryDataSet.drawValuesEnabled = false

        secondaryDataSet.highlightAlpha = Constants.highlightAlpha
        if let secondaryHighlightColor = styling.secondaryHighlightColor {
            secondaryDataSet.highlightColor = secondaryHighlightColor
        }
    }

    func configureChartForSingleDataSet(_ dataSet: BarChartDataSet) {
        dataSet.colors = [ styling.primaryBarColor ]
        dataSet.drawValuesEnabled = false

        if let barHighlightColor = styling.primaryHighlightColor {
            dataSet.highlightAlpha = Constants.highlightAlpha
            dataSet.highlightColor = barHighlightColor
            dataSet.highlightEnabled = true
        } else {
            dataSet.highlightEnabled = false
            highlightPerTapEnabled = false
        }
    }

    func configureChartViewBaseProperties() {
        dragDecelerationEnabled = false
        extraRightOffset = Constants.trailingOffset
    }

    func configureLegendIfNeeded() {
        legend.enabled = false

        guard let legendColor = styling.legendColor, let legendTitle = styling.legendTitle, legendView == nil else {
            return
        }

        let chartLegend = StatsChartLegendView(color: legendColor, title: legendTitle)
        addSubview(chartLegend)

        NSLayoutConstraint.activate([
            chartLegend.widthAnchor.constraint(equalTo: widthAnchor),
            chartLegend.leadingAnchor.constraint(equalTo: leadingAnchor),
            chartLegend.topAnchor.constraint(equalTo: topAnchor)
        ])

        extraTopOffset = chartLegend.intrinsicContentSize.height + Constants.topOffsetWithLegend
        self.legendView = chartLegend
    }

    func configureXAxis() {
        xAxis.axisLineColor = styling.lineColor
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = styling.labelColor
        xAxis.setLabelCount(Constants.horizontalAxisLabelCount, force: true)
        xAxis.valueFormatter = styling.xAxisValueFormatter
        xAxis.avoidFirstLastClippingEnabled = true
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
        yAxis.setLabelCount(Constants.verticalAxisLabelCount, force: true)
        yAxis.valueFormatter = styling.yAxisValueFormatter
        yAxis.zeroLineColor = styling.lineColor

        // This adjustment is intended to prevent clipping observed with some labels
        // Potentially relevant : https://github.com/danielgindi/Charts/issues/992
        extraTopOffset = Constants.topOffsetSansLegend
    }

    func configureYAxisMaximum() {
        let lowestMaxValue = Double(Constants.verticalAxisLabelCount - 1)

        if let maxY = data?.getYMax(),
            maxY >= lowestMaxValue {
            leftAxis.axisMaximum = VerticalAxisFormatter.roundUpAxisMaximum(maxY)
        } else {
            leftAxis.axisMaximum = lowestMaxValue
        }
    }

    func drawChartMarker(for entry: ChartDataEntry) {
        let (markerRect, markerOffset) = calculateMarkerFrameAndOffset(for: entry)
        let marker = StatsBarChartMarker(frame: markerRect)
        marker.offset = markerOffset

        let markerColor: NSUIColor
        if let primaryHighlightColor = styling.primaryHighlightColor {
            markerColor = primaryHighlightColor
        } else {
            markerColor = .accent
        }
        marker.backgroundColor = markerColor.withAlphaComponent(Constants.markerAlpha)

        self.marker = marker
    }

    func drawSecondaryHighlightIfNeeded(for primaryEntry: ChartDataEntry, with primaryHighlight: Highlight) {
        guard let chartData = data, chartData.dataSets.count > 1 else {
            highlightValues([primaryHighlight])
            return
        }

        let primaryDataSet = chartData.dataSets[Constants.primaryDataSetIndex]
        let primaryIndex = primaryDataSet.entryIndex(entry: primaryEntry)

        let secondaryDataSet = chartData.dataSets[Constants.secondaryDataSetIndex]
        guard let secondaryEntry = secondaryDataSet.entryForIndex(primaryIndex) as? BarChartDataEntry else {
            return
        }

        let secondaryHighlight = Highlight(x: secondaryEntry.x, y: secondaryEntry.y, dataSetIndex: Constants.secondaryDataSetIndex)
        let values: [Highlight] = [primaryHighlight, secondaryHighlight]

        highlightValues(values)
    }

    func highlightEntry(at index: Int) {
        guard let entry = primaryDataSet?.entryForIndex(index) else {
            return
        }

        let highlight = Highlight(x: entry.x, y: entry.y, dataSetIndex: Constants.primaryDataSetIndex)
        highlightBar(for: entry, with: highlight)
    }

    func highlightBar(for entry: ChartDataEntry, with highlight: Highlight) {
        drawSecondaryHighlightIfNeeded(for: entry, with: highlight)
        drawChartMarker(for: entry)
    }

    func highlightBarIfNeeded() {
        guard isHighlightNeeded else {
            return
        }

        // This delay mitigates a visual artifact observed drawing the highlight
        let postPresentationDelay = DispatchTime.now() + Constants.presentationDelay
        DispatchQueue.main.asyncAfter(deadline: postPresentationDelay) {
            self.highlightEntry(at: self.prevailingHighlightIndex)
        }
    }

    func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        delegate = self

        applyStyling()
        prepareForVoiceOver()
        configureAndPopulateData()
        highlightBarIfNeeded()
    }

    func redrawChartMarkersIfNeeded() {
        guard marker != nil, let highlight = lastHighlighted, let entry = barData?.entryForHighlight(highlight) else {
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

private typealias StatsBarChartMarker = MarkerView

extension StatsBarChartView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        captureAnalyticsEvent()
        highlightBar(for: entry, with: highlight)
        broadcastBarHighlightIfNeeded(for: entry)
    }
}

// MARK: - Accessible

extension StatsBarChartView: Accessible {
    func prepareForVoiceOver() {
        // ChartDataRendererBase creates a meaningful a11y description, relying on the chart description
        guard let chartDescription = chartDescription else {
            return
        }
        chartDescription.text = barChartData.accessibilityDescription
        chartDescription.enabled = false    // disabling the description hides a corresponding label
    }
}
