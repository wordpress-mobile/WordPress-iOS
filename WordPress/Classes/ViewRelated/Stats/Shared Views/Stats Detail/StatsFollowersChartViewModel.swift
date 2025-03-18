import UIKit
import WordPressUI

struct StatsFollowersChartViewModel {

    let dotComFollowersCount: Int
    let emailFollowersCount: Int

    func makeFollowersChartView() -> UIView {
        // The followers chart currently shows 2 segments. If available, it will show:
        // - WordPress.com followers
        // - Email followers

        let chartView = DonutChartView()
        chartView.configure(title: "", totalCount: CGFloat(totalCount()), segments: segments())
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.chartHeight).isActive = true
        return chartView
    }

    internal func totalCount() -> Int {
        return dotComFollowersCount + emailFollowersCount
    }

    internal func segments() -> [DonutChartView.Segment] {
        var segments: [DonutChartView.Segment] = []
        segments.append(segmentWith(title: Constants.wpComGroupTitle, count: dotComFollowersCount, color: Constants.wpComColor))
        segments.append(segmentWith(title: Constants.emailGroupTitle, count: emailFollowersCount, color: Constants.emailColor))
        return segments
    }

    internal func segmentWith(title: String, count: Int, color: UIColor) -> DonutChartView.Segment {
        return DonutChartView.Segment(
                title: title,
                value: CGFloat(count),
                color: color
        )
    }

    private enum Constants {
        static let wpComGroupTitle = NSLocalizedString("WordPress", comment: "Title of Stats section that shows WordPress.com followers.")
        static let emailGroupTitle = NSLocalizedString("Email", comment: "Title of Stats section that shows email followers.")

        static let wpComColor: UIColor = UIAppColor.blue(.shade50)
        static let emailColor: UIColor = UIAppColor.blue(.shade5)

        static let chartHeight: CGFloat = 231.0
    }
}
