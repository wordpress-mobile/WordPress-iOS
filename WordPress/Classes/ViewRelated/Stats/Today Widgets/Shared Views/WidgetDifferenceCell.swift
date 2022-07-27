import UIKit

class WidgetDifferenceCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetDifferenceCell"
    static let defaultHeight: CGFloat = 56.5

    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var dataLabel: UILabel!
    @IBOutlet private var differenceView: UIView!
    @IBOutlet private var differenceLabel: UILabel!

    private var percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.positivePrefix = "+"
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
        initializeLabels()
    }

    func configure(day: ThisWeekWidgetDay? = nil, isToday: Bool = false) {
        configureLabels(day: day, isToday: isToday)
    }

}

// MARK: - Private Extension

private extension WidgetDifferenceCell {

    func configureColors() {
        dateLabel.textColor = WidgetStyles.primaryTextColor
        dataLabel.textColor = WidgetStyles.primaryTextColor
        differenceLabel.textColor = Constants.differenceTextColor
        differenceView.layer.cornerRadius = Constants.cornerRadius
    }

    func initializeLabels() {
        dateLabel.text = Constants.noDataLabel
        dataLabel.text = Constants.noDataLabel
        differenceLabel.text = Constants.noDataLabel
    }

    func configureLabels(day: ThisWeekWidgetDay?, isToday: Bool) {
        guard let day = day else {
            return
        }

        dataLabel.text = day.viewsCount.abbreviatedString()
        differenceLabel.text = percentFormatter.string(for: day.dailyChangePercent)

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
        static let today = AppLocalizedString("Today", comment: "Label for most recent stat row.")
        static let positiveColor: UIColor = .success
        static let negativeColor: UIColor = .error
        static let neutralColor: UIColor = .neutral(.shade40)
        static let differenceTextColor: UIColor = .white
    }

}
