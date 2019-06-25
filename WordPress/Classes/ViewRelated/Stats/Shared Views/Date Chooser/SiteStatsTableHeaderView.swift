import UIKit

protocol SiteStatsTableHeaderDelegate: class {
    func dateChangedTo(_ newDate: Date?)
}

class SiteStatsTableHeaderView: UITableViewHeaderFooterView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var backArrow: UIImageView!
    @IBOutlet weak var forwardArrow: UIImageView!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!

    static let height: CGFloat = 44
    private typealias Style = WPStyleGuide.Stats
    private weak var delegate: SiteStatsTableHeaderDelegate?
    private var date: Date?
    private var period: StatsPeriodUnit?

    // Limits how far back the date chooser can go.
    // Corresponds to the number of bars shown on the Overview chart.
    static let defaultPeriodCount = 14
    private var expectedPeriodCount = SiteStatsTableHeaderView.defaultPeriodCount
    private var backLimit: Int {
        return -(expectedPeriodCount - 1)
    }

    private lazy var calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .autoupdatingCurrent
        return cal
    }()

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(date: Date?, period: StatsPeriodUnit?, delegate: SiteStatsTableHeaderDelegate, expectedPeriodCount: Int = SiteStatsTableHeaderView.defaultPeriodCount) {
        self.date = date
        self.period = period
        self.delegate = delegate
        self.expectedPeriodCount = expectedPeriodCount
        dateLabel.text = displayDate()
        updateButtonStates()
    }

}

private extension SiteStatsTableHeaderView {

    func applyStyles() {
        Style.configureLabelAsCellRowTitle(dateLabel)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

    func displayDate() -> String? {
        guard let date = date, let period = period else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate(period.dateFormatTemplate)

        switch period {
        case .day, .month, .year:
            return dateFormatter.string(from: date)
        case .week:
            let week = StatsPeriodHelper().weekIncludingDate(date)
            guard let weekStart = week?.weekStart, let weekEnd = week?.weekEnd else {
                return nil
            }

            return "\(dateFormatter.string(from: weekStart)) – \(dateFormatter.string(from: weekEnd))"
        }
    }

    @IBAction func didTapBackButton(_ sender: UIButton) {
        updateDate(forward: false)
    }

    @IBAction func didTapForwardButton(_ sender: UIButton) {
        updateDate(forward: true)
    }

    func updateDate(forward: Bool) {
        guard let date = date, let period = period else {
            return
        }

        let value = forward ? 1 : -1

        self.date = StatsPeriodHelper().calculateEndDate(startDate: date, offsetBy: value, unit: period)

        delegate?.dateChangedTo(self.date)
        dateLabel.text = displayDate()
        updateButtonStates()
    }

    func updateButtonStates() {
        guard let date = date, let period = period else {
            forwardButton.isEnabled = false
            backButton.isEnabled = false
            updateArrowStates()
            return
        }
        
        let helper = StatsPeriodHelper()
        forwardButton.isEnabled = helper.dateAvailableAfterDate(date, period: period)
        backButton.isEnabled = helper.dateAvailableBeforeDate(date, period: period, backLimit: backLimit)
        updateArrowStates()
    }

    func updateArrowStates() {
        forwardArrow.image = Style.imageForGridiconType(.chevronRight, withTint: (forwardButton.isEnabled ? .darkGrey : .grey))
        backArrow.image = Style.imageForGridiconType(.chevronLeft, withTint: (backButton.isEnabled ? .darkGrey : .grey))
    }
}

extension SiteStatsTableHeaderView: StatsBarChartViewDelegate {
    func statsBarChartValueSelected(_ statsBarChartView: StatsBarChartView, entryIndex: Int, entryCount: Int) {
        guard let period = period, entryCount > 0, entryCount <= SiteStatsTableHeaderView.defaultPeriodCount else {
            return
        }

        let periodShift = -((entryCount - 1) - entryIndex)

        self.date = StatsPeriodHelper().calculateEndDate(startDate: Date().normalizedDate(), offsetBy: periodShift, unit: period)

        delegate?.dateChangedTo(self.date)
        dateLabel.text = displayDate()
        updateButtonStates()
    }
}
