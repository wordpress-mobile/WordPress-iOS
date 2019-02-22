
import UIKit

import Charts

// MARK: - StatsBarChartView

class StatsBarChartView: BarChartView {

    // MARK: Properties

    private struct Metrics {
        static let intrinsicHeight = CGFloat(170)   // height via Zeplin
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
        return CGSize(width: UIView.noIntrinsicMetric, height: Metrics.intrinsicHeight)
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
        drawMarkers = false
        highlightPerTapEnabled = false

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
                dataSet.drawValuesEnabled = false
                dataSet.highlightEnabled = false

                dataSet.colors = [ styling.barColor ]
            }
        }

        data = barChartData
    }

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        applyStyling()
        configureAndPopulateData()
    }
}
