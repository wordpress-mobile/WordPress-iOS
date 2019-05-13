
import UIKit

import Charts

// MARK: - StatsBarChartView

private let BarChartAnalyticsPropertyGranularityKey = "granularity"

class StatsBarChartView: BarChartView {

    // MARK: Properties

    private struct Constants {
        static let animationDuration    = TimeInterval(1)
        static let intrinsicHeight      = CGFloat(170)      // height via Zeplin
        static let highlightAlpha       = CGFloat(1)
        static let markerAlpha          = CGFloat(0.2)
        static let topOffsetSansLegend  = CGFloat(5)
        static let topOffsetWithLegend  = CGFloat(16)
        static let trailingOffset       = CGFloat(20)
    }

    /// This adapts the data set for presentation by the Charts framework.
    ///
    private let barChartData: BarChartDataConvertible

    /// This influences the visual appearance of the chart to be rendered.
    ///
    private let styling: BarChartStyling

    /// This informs the analytics event captured via user interaction.
    ///
    private let analyticsGranularity: BarChartAnalyticsPropertyGranularityValue?

    /// When set, this stock `UIView` serves as a legend for the rendered chart.
    ///
    private var legendView: UIView?

    // MARK: StatsBarChartView

    override var bounds: CGRect {
        didSet {
            redrawChartMarkersIfNeeded()
        }
    }

    init(data: BarChartDataConvertible, styling: BarChartStyling, analyticsGranularity: BarChartAnalyticsPropertyGranularityValue? = nil) {
        self.barChartData = data
        self.styling = styling
        self.analyticsGranularity = analyticsGranularity

        super.init(frame: .zero)

        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Constants.intrinsicHeight)
    }

    // MARK: Private behavior

    private func applyStyling() {
        configureBarChartViewProperties()
        configureBarLineChartViewBaseProperties()
        configureChartViewBaseProperties()

        configureXAxis()
        configureYAxis()
    }

    /// Unfortunately the framework doesn't offer much in the way of Auto Layout support,
    /// so here we manually calculate geometry.
    ///
    /// - Parameter entry: the selected entry for which to determine highlight information
    /// - Returns: the frame & offset from the bar that should be used to render the marker
    ///
    private func calculateMarkerFrameAndOffset(for entry: ChartDataEntry) -> (frame: CGRect, offset: CGPoint) {
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

    private func captureAnalyticsEvent() {
        var properties = [String: String]()

        if let specifiedAnalyticsGranularity = analyticsGranularity {
            properties[BarChartAnalyticsPropertyGranularityKey] = specifiedAnalyticsGranularity.rawValue
        }

        WPAnalytics.track(.statsOverviewBarChartTapped, withProperties: properties)
    }

    private func configureAndPopulateData() {
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
    }

    private func configureBarChartViewProperties() {
        drawBarShadowEnabled = false
        drawValueAboveBarEnabled = false
        fitBars = true
    }

    private func configureBarLineChartViewBaseProperties() {
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

    private func configureChartForMultipleDataSets(_ dataSets: [BarChartDataSet]) {
        // Primary
        guard let primaryDataSet = dataSets.first else {
            return
        }
        primaryDataSet.colors = [ styling.primaryBarColor ]
        primaryDataSet.drawValuesEnabled = false

        primaryDataSet.highlightAlpha = Constants.highlightAlpha
        if let initialHighlightColor = styling.primaryHighlightColor {
            primaryDataSet.highlightColor = initialHighlightColor
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

    private func configureChartForSingleDataSet(_ dataSet: BarChartDataSet) {
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

    private func configureChartViewBaseProperties() {
        dragDecelerationEnabled = false
        extraRightOffset = Constants.trailingOffset

        animate(yAxisDuration: Constants.animationDuration)
    }

    private func configureLegendIfNeeded() {
        legend.enabled = false

        guard let legendColor = styling.secondaryBarColor, let legendTitle = styling.legendTitle, legendView == nil else {
            return
        }

        let chartLegend = StatsChartLegendView(color: legendColor, title: legendTitle)
        addSubview(chartLegend)

        NSLayoutConstraint.activate([
            chartLegend.widthAnchor.constraint(equalTo: widthAnchor)
        ])
        extraTopOffset = chartLegend.intrinsicContentSize.height + Constants.topOffsetWithLegend

        self.legendView = chartLegend
    }

    private func configureXAxis() {
        xAxis.axisLineColor = styling.lineColor
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = styling.labelColor
        xAxis.setLabelCount(2, force: true)
        xAxis.valueFormatter = styling.xAxisValueFormatter
    }

    private func configureYAxis() {
        let yAxis = leftAxis

        yAxis.axisLineColor = styling.lineColor
        yAxis.axisMinimum = 0.0
        yAxis.drawAxisLineEnabled = false
        yAxis.drawLabelsEnabled = true
        yAxis.drawZeroLineEnabled = true
        yAxis.gridColor = styling.lineColor
        yAxis.labelTextColor = styling.labelColor
        yAxis.setLabelCount(6, force: true)
        yAxis.valueFormatter = styling.yAxisValueFormatter
        yAxis.zeroLineColor = styling.lineColor

        // This adjustment is intended to prevent clipping observed with some labels
        // Potentially relevant : https://github.com/danielgindi/Charts/issues/992
        extraTopOffset = Constants.topOffsetSansLegend
    }

    private func drawChartMarker(for entry: ChartDataEntry) {
        let (markerRect, markerOffset) = calculateMarkerFrameAndOffset(for: entry)
        let marker = StatsBarChartMarker(frame: markerRect)
        marker.offset = markerOffset

        let markerColor: NSUIColor
        if let primaryHighlightColor = styling.primaryHighlightColor {
            markerColor = primaryHighlightColor
        } else {
            markerColor = WPStyleGuide.jazzyOrange()
        }
        marker.backgroundColor = markerColor.withAlphaComponent(Constants.markerAlpha)

        self.marker = marker
    }

    private func drawSecondaryHighlightIfNeeded(for primaryEntry: ChartDataEntry, with primaryHighlight: Highlight) {
        guard let chartData = data, chartData.dataSets.count > 1 else {
            highlightValues([primaryHighlight])
            return
        }

        let primaryDataSet = chartData.dataSets[0]
        let primaryIndex = primaryDataSet.entryIndex(entry: primaryEntry)

        let secondaryIndex = 1
        let secondaryDataSet = chartData.dataSets[secondaryIndex]
        guard let secondaryEntry = secondaryDataSet.entryForIndex(primaryIndex) as? BarChartDataEntry else {
            return
        }

        let secondaryHighlight = Highlight(x: secondaryEntry.x, y: secondaryEntry.y, dataSetIndex: secondaryIndex)
        let values: [Highlight] = [primaryHighlight, secondaryHighlight]

        highlightValues(values)
    }

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        delegate = self

        applyStyling()
        prepareForVoiceOver()
        configureAndPopulateData()
    }

    private func redrawChartMarkersIfNeeded() {
        guard marker != nil, let highlight = lastHighlighted, let entry = barData?.entryForHighlight(highlight) else {
            return
        }

        notifyDataSetChanged()

        let postRotationDelay = DispatchTime.now() + TimeInterval(0.35)
        DispatchQueue.main.asyncAfter(deadline: postRotationDelay) {
            self.drawSecondaryHighlightIfNeeded(for: entry, with: highlight)
            self.drawChartMarker(for: entry)
        }
    }
}

// MARK: - ChartViewDelegate

private typealias StatsBarChartMarker = MarkerView

extension StatsBarChartView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        captureAnalyticsEvent()
        drawSecondaryHighlightIfNeeded(for: entry, with: highlight)
        drawChartMarker(for: entry)
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
