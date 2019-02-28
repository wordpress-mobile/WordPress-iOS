
import UIKit

import Charts

// MARK: - StatsBarChartView

class StatsBarChartView: BarChartView {

    // MARK: Properties

    private struct Constants {
        static let intrinsicHeight  = CGFloat(170)   // height via Zeplin
        static let highlightAlpha   = CGFloat(0.1)
    }

    private let barChartData: BarChartDataConvertible

    private let styling: BarChartStyling

    // MARK: StatsBarChartView

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

        extraRightOffset = CGFloat(20)

        legend.enabled = false

        let animationDuration = TimeInterval(1)
        animate(yAxisDuration: animationDuration)
    }

    private func configureXAxis() {
        xAxis.axisLineColor = styling.adornmentColor
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = styling.adornmentColor
        xAxis.setLabelCount(2, force: true)
        xAxis.valueFormatter = styling.xAxisValueFormatter
    }

    private func configureYAxis() {
        let yAxis = leftAxis

        yAxis.gridColor = styling.adornmentColor
        yAxis.drawAxisLineEnabled = false
        yAxis.drawLabelsEnabled = true
        yAxis.drawZeroLineEnabled = true
        yAxis.labelTextColor = styling.adornmentColor
        yAxis.valueFormatter = styling.yAxisValueFormatter
    }

    private func configureAndPopulateData() {
        let barChartData = self.barChartData.barChartData

        if let dataSets = barChartData.dataSets as? [BarChartDataSet] {
            for dataSet in dataSets {
                dataSet.colors = [ styling.barColor ]

                dataSet.drawValuesEnabled = false

                if let barHilightColor = styling.highlightColor {
                    dataSet.highlightColor = barHilightColor
                    dataSet.highlightEnabled = true
                    dataSet.highlightAlpha = CGFloat(1)
                } else {
                    highlightPerTapEnabled = false
                }
            }
        }

        data = barChartData
    }

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        delegate = self

        applyStyling()
        configureAndPopulateData()
    }
}

// MARK: - ChartViewDelegate

private typealias StatsBarChartMarker = MarkerView

extension StatsBarChartView: ChartViewDelegate {

    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let (markerRect, markerOffset) = calculateHighlightFrameAndOffset(for: entry)
        let marker = StatsBarChartMarker(frame: markerRect)
        marker.offset = markerOffset

        let markerColor = (styling.highlightColor ?? UIColor.clear).withAlphaComponent(Constants.highlightAlpha)
        marker.backgroundColor = markerColor

        self.marker = marker
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
        let highlightOrigin = CGPoint(x: barBounds.origin.x, y: 0)
        let rect = CGRect(origin: highlightOrigin, size: barBounds.size)

        let offsetWidth = -(barBounds.width / 2)
        let offsetHeight = -barBounds.height
        let offset = CGPoint(x: offsetWidth, y: offsetHeight)

        return (rect, offset)
    }
}
