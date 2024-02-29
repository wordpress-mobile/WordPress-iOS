import UIKit
import DGCharts
import DesignSystem

// MARK: - StatsTrafficBarChartView

final class StatsTrafficBarChartView: BarChartView {

    // MARK: Properties

    private struct Constants {
        static let intrinsicHeight          = CGFloat(175)
        static let topOffsetSansLegend      = Length.Padding.single
        static let verticalAxisLabelCount   = 5
        static let barWidth                 = CGFloat(0.9) // Proportional to full width
        static let gridLineWidth            = CGFloat(0.5)
        static var labelFont                = { WPStyleGuide.fontForTextStyle(.caption2, symbolicTraits: [], maximumPointSize: 18) }
        static let tickLineHeight           = CGFloat(8)
    }

    static let emptyChartBarHeight = 0.01

    /// This adapts the data set for presentation by the Charts framework.
    ///
    private var barChartData: BarChartDataConvertible

    /// This influences the visual appearance of the chart to be rendered.
    ///
    private var styling: StatsTrafficBarChartStyling

    private var primaryDataSet: ChartDataSetProtocol? {
        return data?.dataSets.first
    }

    // MARK: StatsTrafficBarChartView

    init(barChartData: BarChartDataConvertible, styling: StatsTrafficBarChartStyling) {
        self.barChartData = barChartData
        self.styling = styling

        super.init(frame: .zero)

        initialize()
    }

    func update(barChartData: BarChartDataConvertible, styling: StatsTrafficBarChartStyling) {
        self.barChartData = barChartData
        self.styling = styling

        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Constants.intrinsicHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        addXAxisTicks()
    }
}

// MARK: - Private behavior

private extension StatsTrafficBarChartView {
    func applyStyling() {
        configureBarChartViewProperties()
        configureBarLineChartViewBaseProperties()
        configureChartViewBaseProperties()

        configureXAxis()
        configureYAxis()
        addXAxisTicks()
    }

    func configureAndPopulateData() {
        let barChartData = self.barChartData.barChartData

        guard let dataSets = barChartData.dataSets as? [BarChartDataSet], let dataSet = dataSets.first else {
            return
        }

        configureChartForSingleDataSet(dataSet)
        data = barChartData
        configureYAxisMaximum()
    }

    func configureBarChartViewProperties() {
        drawBarShadowEnabled = false
        drawValueAboveBarEnabled = false
        clipValuesToContentEnabled = false
        fitBars = true
        legend.enabled = false
    }

    func configureBarLineChartViewBaseProperties() {
        doubleTapToZoomEnabled = false
        dragXEnabled = false
        dragYEnabled = false
        pinchZoomEnabled = false
        drawBordersEnabled = false
        drawGridBackgroundEnabled = false

        minOffset = 0

        rightAxis.enabled = true
        leftAxis.enabled = false

        scaleXEnabled = false
        scaleYEnabled = false
    }

    func configureChartForSingleDataSet(_ dataSet: BarChartDataSet) {
        dataSet.setColor(.init(color: styling.primaryBarColor))
        dataSet.drawValuesEnabled = false
        dataSet.axisDependency = .right
        dataSet.highlightEnabled = false
        barChartData.barChartData.barWidth = Constants.barWidth
        xAxis.setLabelCount(labelCount(dataSet), force: false)
    }

    private func labelCount(_ dataSet: BarChartDataSet) -> Int {
        if UIApplication.shared.preferredContentSizeCategory >= .extraExtraLarge {
            return Int(ceil(Double(dataSet.count) / 2))
        }

        return dataSet.count
    }

    func configureChartViewBaseProperties() {
        dragDecelerationEnabled = false
    }

    func configureXAxis() {
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelPosition = .bottom
        xAxis.labelFont = Constants.labelFont()
        xAxis.labelTextColor = .init(color: styling.labelColor)
        xAxis.valueFormatter = styling.xAxisValueFormatter
        xAxis.avoidFirstLastClippingEnabled = false
        xAxis.axisLineWidth = Constants.tickLineHeight
        xAxis.axisLineColor = styling.lineColor
    }

    func configureYAxis() {
        rightAxis.drawAxisLineEnabled = true
        rightAxis.axisLineColor = .init(color: styling.lineColor)
        rightAxis.axisLineWidth = Constants.gridLineWidth
        rightAxis.gridColor = .init(color: styling.lineColor)
        rightAxis.gridLineWidth = Constants.gridLineWidth
        rightAxis.axisMinimum = 0.0
        rightAxis.drawLabelsEnabled = true
        rightAxis.labelFont = Constants.labelFont()
        rightAxis.labelPosition = .outsideChart
        rightAxis.labelAlignment = .left
        rightAxis.labelTextColor = .init(color: styling.labelColor)
        rightAxis.setLabelCount(Constants.verticalAxisLabelCount, force: true)
        rightAxis.valueFormatter = styling.yAxisValueFormatter
        extraTopOffset = Constants.topOffsetSansLegend
        rightAxis.minWidth = trailingOffset()
        rightAxis.maxWidth = trailingOffset()
    }

    private func trailingOffset() -> CGFloat {
        if UIApplication.shared.preferredContentSizeCategory >= .extraExtraLarge {
            return Length.Padding.max
        } else {
            return Length.Padding.large
        }
    }

    func configureYAxisMaximum() {
        let lowestMaxValue = Double(Constants.verticalAxisLabelCount - 1)

        if let maxY = data?.getYMax(axis: .right),
            maxY >= lowestMaxValue {
            rightAxis.axisMaximum = StatsTrafficVerticalAxisFormatter.roundUpAxisMaximum(maxY)
        } else {
            rightAxis.axisMaximum = lowestMaxValue
        }
    }

    func initialize() {
        translatesAutoresizingMaskIntoConstraints = false

        applyStyling()
        prepareForVoiceOver()
        configureAndPopulateData()
    }

    /// Adds X axis ticks below each bar
    func addXAxisTicks() {
        guard
            let dataSets = barChartData.barChartData.dataSets as? [BarChartDataSet],
            let dataSet = dataSets.first
        else {
            return
        }

        // valueToPixelMatrix allows to convert relative x-axis bar position into pixels
        guard let valueToPixelMatrix = xAxisRenderer.transformer?.valueToPixelMatrix else { return }

        // Axis line dash lengths array describes
        // line length in px in odd array position and
        // spacing in px after the line in even array position
        var axisLineDashLengths: [CGFloat] = []

        var previousValue: CGFloat?
        for i in 0...dataSet.count {
            // Position in px of chart bar of provided index
            let position = CGPoint(x: CGFloat(i), y: 0)
                .applying(valueToPixelMatrix)

            if i == 0 {
                // Do not show any tick at the start of x axis and shift to the first chart bar position
                axisLineDashLengths.append(contentsOf: [0, position.x])
            } else if let previousValue {
                // Add a tick and shift to the next position
                axisLineDashLengths.append(contentsOf: [Constants.gridLineWidth, position.x - previousValue - Constants.gridLineWidth])
            }

            previousValue = position.x
        }

        xAxis.axisLineDashLengths = axisLineDashLengths
    }
}

// MARK: - Accessible

extension StatsTrafficBarChartView: Accessible {
    func prepareForVoiceOver() {
        // ChartDataRendererBase creates a meaningful a11y description, relying on the chart description
        chartDescription.text = barChartData.accessibilityDescription
        chartDescription.enabled = false    // disabling the description hides a corresponding label
    }
}
