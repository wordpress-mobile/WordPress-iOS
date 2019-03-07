
import UIKit

import Charts

// MARK: - StatsBarChartView

class StatsBarChartView: BarChartView {

    // MARK: Properties

    private struct Constants {
        static let animationDuration    = TimeInterval(1)
        static let intrinsicHeight      = CGFloat(170)      // height via Zeplin
        static let highlightAlpha       = CGFloat(0.75)
        static let markerAlpha          = CGFloat(0.2)
        static let offset               = CGFloat(20)
    }

    private let barChartData: BarChartDataConvertible

    private let styling: BarChartStyling

    // MARK: StatsBarChartView

    override var bounds: CGRect {
        didSet {
            redrawChartMarkersIfNeeded()
        }
    }

    init(data: BarChartDataConvertible, styling: BarChartStyling) {
        self.barChartData = data
        self.styling = styling

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
    private func calculateHighlightFrameAndOffset(for entry: ChartDataEntry) -> (CGRect, CGPoint) {
        guard let barChartDataEntry = entry as? BarChartDataEntry else {
            return (.zero, .zero)
        }

        let barBounds = getBarBounds(entry: barChartDataEntry)

        let highlightX = barBounds.origin.x
        let highlightY = CGFloat(0)
        let highlightOrigin = CGPoint(x: highlightX, y: highlightY)

        let highlightWidth = barBounds.width
        let highlightHeight = bounds.height - barBounds.height
        let highlightSize = CGSize(width: highlightWidth, height: highlightHeight)

        let rect = CGRect(origin: highlightOrigin, size: highlightSize)

        let offsetWidth = -(barBounds.width / 2)
        let offsetHeight = -highlightHeight
        let offset = CGPoint(x: offsetWidth, y: offsetHeight)

        return (rect, offset)
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

        rightAxis.enabled = false

        drawBordersEnabled = false
        drawGridBackgroundEnabled = false

        minOffset = CGFloat(0)

        scaleXEnabled = false
        scaleYEnabled = false
    }

    private func configureChartViewBaseProperties() {
        dragDecelerationEnabled = false

        extraRightOffset = Constants.offset

        animate(yAxisDuration: Constants.animationDuration)
    }

    private func configureLegendIfNeeded() {
        guard let legendTitle = styling.legendTitle, let legendColor = styling.secondaryBarColor else {
            return
        }

        legend.enabled = true
        legend.verticalAlignment = .top

        let entry = LegendEntry()
        entry.label = legendTitle
        entry.formColor = legendColor

        legend.setCustom(entries: [entry])
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

        xAxis.axisLineColor = styling.lineColor
        yAxis.gridColor = styling.lineColor
        yAxis.drawAxisLineEnabled = false
        yAxis.drawLabelsEnabled = true
        yAxis.drawZeroLineEnabled = true
        yAxis.labelTextColor = styling.labelColor
        yAxis.valueFormatter = styling.yAxisValueFormatter
    }

    private func configureDataSet(dataSet: BarChartDataSet, with color: NSUIColor, enableHighlight: Bool) {
        dataSet.colors = [ color ]

        dataSet.drawValuesEnabled = false

        guard let barHighlightColor = styling.highlightColor else {
            highlightPerTapEnabled = false
            return
        }

        dataSet.highlightAlpha = (styling.secondaryBarColor != nil) ? Constants.highlightAlpha : CGFloat(1)
        dataSet.highlightColor = barHighlightColor
        dataSet.highlightEnabled = enableHighlight
    }

    private func configureAndPopulateData() {
        let barChartData = self.barChartData.barChartData

        guard let dataSets = barChartData.dataSets as? [BarChartDataSet], let initialDataSet = dataSets.first else {
            return
        }
        configureDataSet(dataSet: initialDataSet, with: styling.primaryBarColor, enableHighlight: true)

        if dataSets.count > 1, let secondaryBarColor = styling.secondaryBarColor {
            let secondaryDataSet = dataSets[1]
            configureDataSet(dataSet: secondaryDataSet, with: secondaryBarColor, enableHighlight: false)
        }

        configureLegendIfNeeded()

        data = barChartData
    }

    private func drawChartMarker(for entry: ChartDataEntry, triggerRedraw: Bool = false) {
        let (markerRect, markerOffset) = calculateHighlightFrameAndOffset(for: entry)
        let marker = StatsBarChartMarker(frame: markerRect)
        marker.offset = markerOffset

        let markerColor = (styling.highlightColor ?? UIColor.clear).withAlphaComponent(Constants.markerAlpha)
        marker.backgroundColor = markerColor

        self.marker = marker

        if triggerRedraw {
            setNeedsDisplay()
        }
    }

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        delegate = self

        applyStyling()
        configureAndPopulateData()
    }

    private func redrawChartMarkersIfNeeded() {
        guard marker != nil, let highlight = lastHighlighted, let entry = barData?.entryForHighlight(highlight) else {
            return
        }

        notifyDataSetChanged()

        let postRotationDelay = DispatchTime.now() + TimeInterval(0.3)
        DispatchQueue.main.asyncAfter(deadline: postRotationDelay) {
            self.drawChartMarker(for: entry, triggerRedraw: true)
        }
    }
}

// MARK: - ChartViewDelegate

private typealias StatsBarChartMarker = MarkerView

extension StatsBarChartView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        drawChartMarker(for: entry)
    }
}
