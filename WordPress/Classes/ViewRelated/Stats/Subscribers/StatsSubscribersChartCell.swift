import UIKit
import WordPressShared

class StatsSubscribersChartCell: StatsBaseCell {
    private typealias Style = WPStyleGuide.Stats

    private let chartView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private var chartData: LineChartDataConvertible!
    private var chartStyling: LineChartStyling!
    private var xAxisDates: [Date]!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        Style.configureCell(self)

        contentView.addSubview(chartView)
        let topConstraint = chartView.topAnchor.constraint(equalTo: contentView.topAnchor)
        NSLayoutConstraint.activate([
            topConstraint,
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.padding),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.padding),
            chartView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Metrics.padding)
        ])
        self.topConstraint = topConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        let configuration = StatsLineChartConfiguration(
            type: .subscribers,
            data: chartData,
            styling: chartStyling,
            analyticsGranularity: .days,
            xAxisDates: xAxisDates
        )
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
