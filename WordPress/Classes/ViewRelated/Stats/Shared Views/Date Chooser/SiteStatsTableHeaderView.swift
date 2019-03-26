import UIKit

class SiteStatsTableHeaderView: UITableViewHeaderFooterView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var backArrow: UIImageView!
    @IBOutlet weak var forwardArrow: UIImageView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    static let height: CGFloat = 44
    private typealias Style = WPStyleGuide.Stats


    // MARK: - View

    override func awakeFromNib() {
        applyStyles()
    }

    func configure(date: Date?, period: StatsPeriodUnit?) {

        guard let date = date, let period = period else {
            return
        }

        dateLabel.text = displayDateFor(date: date, period: period)
    }

}

private extension SiteStatsTableHeaderView {

    func applyStyles() {
        Style.configureLabelAsCellRowTitle(dateLabel)
        Style.configureViewAsSeparator(bottomSeparatorLine)
        backArrow.image = Style.imageForGridiconType(.chevronLeft, withTint: .darkGrey)
        forwardArrow.image = Style.imageForGridiconType(.chevronRight)
    }

    func displayDateFor(date: Date, period: StatsPeriodUnit) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate(period.dateFormatTemplate)

        switch period {
        case .day, .month, .year:
            return dateFormatter.string(from: date)
        case .week:
            // Week is Monday - Sunday
            var calendar = Calendar(identifier: .iso8601)
            calendar.timeZone = .autoupdatingCurrent

            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)

            let startDate = dateFormatter.string(from: weekStart)
            let endDate = (weekEnd != nil) ? dateFormatter.string(from: weekEnd!) : ""

            let weekFormat = NSLocalizedString("%@ - %@", comment: "Stats label for week date range. Ex: Mar 25 - Mar 31")
            return String.localizedStringWithFormat(weekFormat, startDate, endDate)
        }
    }

}

private extension StatsPeriodUnit {

    var dateFormatTemplate: String {
        switch self {
        case .day:
            return "MMM d, yyyy"
        case .week:
            return "MMM d"
        case .month:
            return "MMM yyyy"
        case .year:
            return "yyyy"
        }
    }

}
