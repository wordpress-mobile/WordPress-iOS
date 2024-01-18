import UIKit
import DGCharts
import DesignSystem

// MARK: - StatsTrafficBarChartView

private let BarChartAnalyticsPropertyGranularityKey = "granularity"

class StatsTrafficBarChartView: BarChartView {

    // MARK: Properties

    private struct Constants {
        static let intrinsicHeight          = CGFloat(175)
        static let presentationDelay        = TimeInterval(0.01)
        static let topOffsetSansLegend      = Length.Padding.single
        static let extraRightOffset         = Length.Padding.single
        static let trailingOffset           = CGFloat(20)
        static let verticalAxisLabelCount   = 5
        static let barWidth                 = 0.9 // Proportional to full width
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
    private let styling: TrafficBarChartStyling

    /// This informs the analytics event captured via user interaction.
    ///
    private let analyticsGranularity: BarChartAnalyticsPropertyGranularityValue?

    private var primaryDataSet: ChartDataSetProtocol? {
        return data?.dataSets.first
    }

    // MARK: StatsTrafficBarChartView

    init(configuration: StatsTrafficBarChartConfiguration) {
        self.barChartData = configuration.data
        self.styling = configuration.styling
        self.analyticsGranularity = configuration.analyticsGranularity

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

private extension StatsTrafficBarChartView {
    func applyStyling() {
        configureBarChartViewProperties()
        configureBarLineChartViewBaseProperties()
        configureChartViewBaseProperties()

        configureXAxis()
        configureYAxis()
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

        drawBordersEnabled = true
        borderColor = .init(color: styling.lineColor)
        borderLineWidth = 0.5
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
        barChartData.barChartData.barWidth = Constants.barWidth
        xAxis.setLabelCount(dataSet.count, force: false)
    }

    func configureChartViewBaseProperties() {
        dragDecelerationEnabled = false
        extraRightOffset = Constants.extraRightOffset
    }

    func configureXAxis() {
        xAxis.axisLineColor = .init(color: styling.lineColor)
        xAxis.axisLineWidth = 0.5
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = .init(color: styling.labelColor)
        xAxis.valueFormatter = styling.xAxisValueFormatter
        xAxis.avoidFirstLastClippingEnabled = true
    }

    func configureYAxis() {
        rightAxis.axisLineColor = .init(color: styling.lineColor)
        rightAxis.axisMinimum = 0.0
        rightAxis.drawAxisLineEnabled = false
        rightAxis.drawLabelsEnabled = true
        rightAxis.drawZeroLineEnabled = false
        rightAxis.gridColor = .init(color: styling.lineColor)
        rightAxis.labelTextColor = .init(color: styling.labelColor)
        rightAxis.setLabelCount(Constants.verticalAxisLabelCount, force: true)
        rightAxis.valueFormatter = styling.yAxisValueFormatter
        extraTopOffset = Constants.topOffsetSansLegend
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
}

// MARK: - Accessible

extension StatsTrafficBarChartView: Accessible {
    func prepareForVoiceOver() {
        // ChartDataRendererBase creates a meaningful a11y description, relying on the chart description
        chartDescription.text = barChartData.accessibilityDescription
        chartDescription.enabled = false    // disabling the description hides a corresponding label
    }
}
