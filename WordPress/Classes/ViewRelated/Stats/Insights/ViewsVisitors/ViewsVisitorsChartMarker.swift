import Foundation
import DGCharts
import UIKit

class ViewsVisitorsChartMarker: StatsChartMarker {
    override func text(for entry: ChartDataEntry) -> NSMutableAttributedString? {
        let yValue = Int(entry.y).description

        guard let data = chartView?.data, data.dataSetCount > 1, let lineChartDataSetPrevWeek = data.dataSet(at: 1) as? LineChartDataSet else {
            return nil
        }

        let entryPrevWeek = lineChartDataSetPrevWeek.entries[Int(entry.x)]
        let difference = Int(entry.y - entryPrevWeek.y)
        let differenceStr = difference < 0 ? "\(difference)" : "+\(difference)"

        var roundedPercentage = 0
        if entryPrevWeek.y > 0 {
            let percentage = (Float(difference) / Float(entryPrevWeek.y)) * 100
            roundedPercentage = Int(round(percentage))
        }

        let topRowAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote),
                                                               .paragraphStyle: paragraphStyle,
                                                               .foregroundColor: UIColor.white.withAlphaComponent(0.8)]
        let bottomRowAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                                  .paragraphStyle: paragraphStyle,
                                                                  .foregroundColor: UIColor.white]

        let topRowStr = NSMutableAttributedString(string: "\(differenceStr) (\(roundedPercentage.percentageString()))\n", attributes: topRowAttributes)
        let bottomRowStr = NSAttributedString(string: "\(yValue) \(name)", attributes: bottomRowAttributes)

        topRowStr.append(bottomRowStr)

        return topRowStr
    }
}
