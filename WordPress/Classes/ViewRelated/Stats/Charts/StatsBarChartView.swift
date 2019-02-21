
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
        debugPrint(#function)
    }

    private func populateData() {
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
        populateData()
    }
}
