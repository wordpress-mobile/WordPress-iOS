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
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .autoupdatingCurrent
            let endDate = calendar.date(byAdding: .day, value: 6, to: date)

            let startDateFormatted = dateFormatter.string(from: date)
            let endDateFormatted = (endDate != nil) ? dateFormatter.string(from: endDate!) : ""

            let weekFormat = NSLocalizedString("%@ - %@", comment: "Stats label for week date range. Ex: Mar 27 - Apr 2")
            return String.localizedStringWithFormat(weekFormat, startDateFormatted, endDateFormatted)
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
