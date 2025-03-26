import UIKit
import WordPressShared

class StatsSubscribersChartCell: StatsBaseCell, NibLoadable {
    private typealias Style = WPStyleGuide.Stats

    @IBOutlet weak var chartView: UIView!

    private var chartData: LineChartDataConvertible!
    private var chartStyling: LineChartStyling!
    private var xAxisDates: [Date]!

    override func awakeFromNib() {
        super.awakeFromNib()

        Style.configureCell(self)
    }

    func configure(row: SubscriberChartRow) {
        statSection = row.statSection

        self.chartData = row.chartData
        self.chartStyling = row.chartStyling
        self.xAxisDates = row.xAxisDates

        configureChartView()
    }
}

private extension StatsSubscribersChartCell {

    func configureChartView() {
        let configuration = StatsLineChartConfiguration(type: .subscribers,
                                                        data: chartData,
                                                        styling: chartStyling,
                                                        analyticsGranularity: .days,
                                                        xAxisDates: xAxisDates)
        let lineChartView = StatsLineChartView(configuration: configuration)

        resetChartContainerView()
        chartView.addSubview(lineChartView)
        chartView.accessibilityElements = [lineChartView]

        NSLayoutConstraint.activate([
            lineChartView.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            lineChartView.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),
            lineChartView.topAnchor.constraint(equalTo: chartView.topAnchor),
            lineChartView.bottomAnchor.constraint(equalTo: chartView.bottomAnchor)
        ])
    }

    func resetChartContainerView() {
        for subview in chartView.subviews {
            subview.removeFromSuperview()
        }
    }
}
