import UIKit

class WidgetDifferenceCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetDifferenceCell"

    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var dataLabel: UILabel!
    @IBOutlet private var differenceView: UIView!
    @IBOutlet private var differenceLabel: UILabel!
    @IBOutlet private var separatorLine: UIView!

    private var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return formatter
    }()

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureColors()
    }

    func configure(day: ThisWeekWidgetDay? = nil, isToday: Bool = false, hideSeparator: Bool = false) {
        configureLabels(day: day, isToday: isToday)
        separatorLine.isHidden = hideSeparator
    }

}

// MARK: - Private Extension

private extension WidgetDifferenceCell {

    func configureColors() {
        dateLabel.textColor = .text
        dataLabel.textColor = .text
        differenceLabel.textColor = .white
        separatorLine.backgroundColor = UIColor(light: .divider, dark: .textSubtle)
        differenceView.layer.cornerRadius = Constants.cornerRadius
    }

    func configureLabels(day: ThisWeekWidgetDay?, isToday: Bool) {
        guard let day = day else {
            dateLabel.text = Constants.noDataLabel
            dataLabel.text = Constants.noDataLabel
            differenceLabel.text = Constants.noDataLabel
            return
        }

        dataLabel.text = numberFormatter.string(from: NSNumber(value: day.viewsCount)) ?? String(day.viewsCount)

        differenceLabel.text = String.localizedStringWithFormat(Constants.percentFormat,
                                                                day.dailyChangePercent < 0 ? "" : "+",
                                                                String(day.dailyChangePercent))

        guard !isToday else {
            dateLabel.text = Constants.today
            differenceView.backgroundColor = Constants.neutralColor
            return
        }

        dateLabel.text = dateFormatter.string(from: day.date)
        differenceView.backgroundColor = day.dailyChangePercent < 0 ? Constants.negativeColor : Constants.positiveColor
    }

    enum Constants {
        static let noDataLabel = "-"
        static let cornerRadius: CGFloat = 4.0
        static let percentFormat = NSLocalizedString("%@%@%%", comment: "Difference label indicating change from previous day. Ex: +5%")
        static let today = NSLocalizedString("Today", comment: "Label for most recent stat row.")
        static let positiveColor = UIColor.success
        static let negativeColor = UIColor.error
        static let neutralColor = UIColor.neutral(.shade40)
    }

}
