import UIKit

protocol SiteStatsTableHeaderDelegate: class {
    func dateChangedTo(_ newDate: Date?)
}

protocol SiteStatsTableHeaderDateButtonDelegate: SiteStatsTableHeaderDelegate {
    func didTouchHeaderButton(forward: Bool)
}

class SiteStatsTableHeaderView: UITableViewHeaderFooterView, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timezoneLabel: UILabel!
    @IBOutlet weak var backArrow: UIImageView!
    @IBOutlet weak var forwardArrow: UIImageView!
    @IBOutlet weak var bottomSeparatorLine: UIView! {
        didSet {
            bottomSeparatorLine.isGhostableDisabled = true
        }
    }

    @IBOutlet weak var backButton: UIButton! {
        didSet {
            backButton.isGhostableDisabled = true
        }
    }
    @IBOutlet weak var forwardButton: UIButton! {
        didSet {
            forwardButton.isGhostableDisabled = true
        }
    }
    @IBOutlet private var containerView: UIView! {
        didSet {
            containerView.isGhostableDisabled = true
        }
    }

    private typealias Style = WPStyleGuide.Stats
    private weak var delegate: SiteStatsTableHeaderDelegate?
    private var date: Date?
    private var period: StatsPeriodUnit?

    // Allow the date bar to only go up to the most recent date available.
    // Used by Insights 'This Year' details view and Post Stats.
    private var mostRecentDate: Date?

    // Limits how far back the date chooser can go.
    // Corresponds to the number of bars shown on the Overview chart.
    static let defaultPeriodCount = 14
    private var expectedPeriodCount = SiteStatsTableHeaderView.defaultPeriodCount
    private var backLimit: Int {
        return -(expectedPeriodCount - 1)
    }

    // MARK: - Class Methods

    class func headerHeight() -> CGFloat {
        return SiteStatsInformation.sharedInstance.timeZoneMatchesDevice() ? Heights.default : Heights.withTimezone
    }

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

        self.date = {
            if let date = date,
                let mostRecentDate = mostRecentDate,
                mostRecentDate < date {
                return mostRecentDate
            }
            return date
        }()

        self.period = period
        self.delegate = delegate
        self.expectedPeriodCount = expectedPeriodCount
        self.mostRecentDate = mostRecentDate
        dateLabel.text = displayDate()
        displayTimezone()
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

    func updateDate(with intervalDate: Date) {
        guard let period = period else {
            return
        }

        self.date = StatsPeriodHelper().endDate(from: intervalDate, period: period)

        delegate?.dateChangedTo(self.date)
        reloadView()
    }

    func animateGhostLayers(_ animate: Bool) {
        forwardButton.isEnabled = !animate
        backButton.isEnabled = !animate

        if animate {
            startGhostAnimation(style: GhostCellStyle.muriel)
            return
        }
        stopGhostAnimation()
    }
}

private extension SiteStatsTableHeaderView {

    func applyStyles() {
        contentView.backgroundColor = .listForeground
        Style.configureLabelAsCellRowTitle(dateLabel)
        Style.configureLabelAsChildRowTitle(timezoneLabel)
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

    func displayTimezone() {
        guard !SiteStatsInformation.sharedInstance.timeZoneMatchesDevice(),
        let siteTimeZone = SiteStatsInformation.sharedInstance.siteTimeZone else {
            timezoneLabel.isHidden = true
            timezoneLabel.accessibilityLabel = nil
            return
        }

        timezoneLabel.text = siteTimeZone.displayForStats()
        timezoneLabel.accessibilityLabel = siteTimeZone.displayForStats()
        timezoneLabel.isHidden = false
    }

    func reloadView() {
        dateLabel.text = displayDate()
        updateButtonStates()
        prepareForVoiceOver()
        postAccessibilityPeriodLabel()
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
        if let delegate = delegate as? SiteStatsTableHeaderDateButtonDelegate {
            delegate.didTouchHeaderButton(forward: forward)
            return
        }

        guard let date = date, let period = period else {
            return
        }

        let value = forward ? 1 : -1

        self.date = StatsPeriodHelper().calculateEndDate(from: date, offsetBy: value, unit: period)

        delegate?.dateChangedTo(self.date)
        reloadView()
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

    // MARK: - Header Heights

    private struct Heights {
        static let `default`: CGFloat = 44
        static let withTimezone: CGFloat = 60
    }
}

extension SiteStatsTableHeaderView: StatsBarChartViewDelegate {
    func statsBarChartValueSelected(_ statsBarChartView: StatsBarChartView, entryIndex: Int, entryCount: Int) {
        guard let period = period, entryCount > 0, entryCount <= SiteStatsTableHeaderView.defaultPeriodCount else {
            return
        }

        let periodShift = -((entryCount - 1) - entryIndex)
        let fromDate = mostRecentDate?.normalizedDate() ?? StatsDataHelper.currentDateForSite().normalizedDate()
        self.date = StatsPeriodHelper().calculateEndDate(from: fromDate, offsetBy: periodShift, unit: period)

        delegate?.dateChangedTo(self.date)
        reloadView()
    }
}
