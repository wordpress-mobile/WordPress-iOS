import UIKit

protocol SiteStatsTableHeaderDelegate: class {
    func dateChangedTo(_ newDate: Date?)
}

protocol SiteStatsTableHeaderUpdateDateDelegate: SiteStatsTableHeaderDelegate {
    func updateDate(forward: Bool)
}

class SiteStatsTableHeaderView: UITableViewHeaderFooterView, NibLoadable, Accessible {

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

    // Allow the date bar to only go up to the most recent year available.
    // Used by Insights 'This Year' details view.
    private var mostRecentDate: Date?

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

    func configure(date: Date?,
                   period: StatsPeriodUnit?,
                   delegate: SiteStatsTableHeaderDelegate,
                   expectedPeriodCount: Int = SiteStatsTableHeaderView.defaultPeriodCount,
                   mostRecentDate: Date? = nil) {
        self.date = date
        self.period = period
        self.delegate = delegate
        self.expectedPeriodCount = expectedPeriodCount
        self.mostRecentDate = mostRecentDate
        dateLabel.text = displayDate()
        updateButtonStates()
        prepareForVoiceOver()
    }

    func prepareForVoiceOver() {
        if let period = dateLabel.text {
            let localizedLabel = NSLocalizedString("Current period: %@", comment: "Period Accessibility label. Prefix the current selected period. Ex. Current period: 2019")
            dateLabel.accessibilityLabel = .localizedStringWithFormat(localizedLabel, period)
        }

        backButton.accessibilityLabel = NSLocalizedString("Previous period", comment: "Accessibility label")
        backButton.accessibilityHint = NSLocalizedString("Tap to select the previous period", comment: "Accessibility hint")

        forwardButton.accessibilityLabel = NSLocalizedString("Next period", comment: "Accessibility label")
        forwardButton.accessibilityHint = NSLocalizedString("Tap to select the next period", comment: "Accessibility hint")
    }

    func update(date: Date) {
        guard let period = period else {
            return
        }

        self.date = StatsPeriodHelper().endDate(from: date, period: period)

        delegate?.dateChangedTo(self.date)
        dateLabel.text = displayDate()
        updateButtonStates()
        prepareForVoiceOver()
        postAccessibilityPeriodLabel()
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
        captureAnalyticsEvent(.statsDateTappedBackward)
        updateDate(forward: false)
    }

    @IBAction func didTapForwardButton(_ sender: UIButton) {
        captureAnalyticsEvent(.statsDateTappedForward)
        updateDate(forward: true)
    }

    func updateDate(forward: Bool) {
        if let delegate = delegate as? SiteStatsTableHeaderUpdateDateDelegate {
            delegate.updateDate(forward: forward)
            return
        }

        guard let date = date, let period = period else {
            return
        }

        let value = forward ? 1 : -1

        self.date = StatsPeriodHelper().calculateEndDate(from: date, offsetBy: value, unit: period)

        delegate?.dateChangedTo(self.date)
        dateLabel.text = displayDate()
        updateButtonStates()
        prepareForVoiceOver()
        postAccessibilityPeriodLabel()
    }

    func updateButtonStates() {
        guard let date = date, let period = period else {
            forwardButton.isEnabled = false
            backButton.isEnabled = false
            updateArrowStates()
            return
        }

        let helper = StatsPeriodHelper()
        forwardButton.isEnabled = helper.dateAvailableAfterDate(date, period: period, mostRecentDate: mostRecentDate)
        backButton.isEnabled = helper.dateAvailableBeforeDate(date, period: period, backLimit: backLimit, mostRecentDate: mostRecentDate)
        updateArrowStates()
        prepareForVoiceOver()
    }

    func updateArrowStates() {
        forwardArrow.image = Style.imageForGridiconType(.chevronRight, withTint: (forwardButton.isEnabled ? .darkGrey : .grey))
        backArrow.image = Style.imageForGridiconType(.chevronLeft, withTint: (backButton.isEnabled ? .darkGrey : .grey))
    }

    func postAccessibilityPeriodLabel() {
        UIAccessibility.post(notification: .screenChanged, argument: dateLabel)
    }

    // MARK: - Analytics support

    func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        let properties: [AnyHashable: Any] = [StatsPeriodUnit.analyticsPeriodKey: period?.description as Any]

        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, withProperties: properties, withBlogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event, withProperties: properties)
        }
    }
}

extension SiteStatsTableHeaderView: StatsBarChartViewDelegate {
    func statsBarChartValueSelected(_ statsBarChartView: StatsBarChartView, entryIndex: Int, entryCount: Int) {
        guard let period = period, entryCount > 0, entryCount <= SiteStatsTableHeaderView.defaultPeriodCount else {
            return
        }

        let periodShift = -((entryCount - 1) - entryIndex)

        self.date = StatsPeriodHelper().calculateEndDate(from: Date().normalizedDate(), offsetBy: periodShift, unit: period)

        delegate?.dateChangedTo(self.date)
        dateLabel.text = displayDate()
        updateButtonStates()
        prepareForVoiceOver()
        postAccessibilityPeriodLabel()
    }
}
