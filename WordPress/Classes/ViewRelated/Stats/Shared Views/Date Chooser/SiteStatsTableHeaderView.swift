import UIKit
import WordPressKit
import WordPressShared

protocol SiteStatsTableHeaderDelegate: AnyObject {
    func dateChangedTo(_ newDate: Date?)
}

protocol SiteStatsTableHeaderDateButtonDelegate: SiteStatsTableHeaderDelegate {
    func didTouchHeaderButton(forward: Bool)
}

class SiteStatsTableHeaderView: UIView, Accessible {

    // MARK: - Properties

    static let estimatedHeight: CGFloat = 60

    let dateLabel = UILabel.makeStatsLabel(text: "Date", textStyle: .headline)
    // The xib's initial text colour is replaced by `applyStyles()`.
    let timezoneLabel = UILabel.makeStatsLabel(text: "Site timezone (UTC + 10)", textStyle: .callout)

    let bottomSeparatorLine: UIView = {
        let view = UIView.makeStatsSeparator()
        view.backgroundColor = UIColor(white: 0.667, alpha: 1)
        view.isGhostableDisabled = true
        return view
    }()

    let backButton = makeNavigationButton()
    let forwardButton = makeNavigationButton()

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isGhostableDisabled = true
        return view
    }()

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
        -(expectedPeriodCount - 1)
    }

    private var isRunningGhostAnimation: Bool = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyStatsXibRootDefaults(size: CGSize(width: 375, height: 60))

        setUpViews()
        applyStyles()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        let dateStackView = UIStackView(arrangedSubviews: [dateLabel, timezoneLabel])
        dateStackView.translatesAutoresizingMaskIntoConstraints = false
        dateStackView.axis = .vertical
        dateStackView.distribution = .fillProportionally
        dateStackView.spacing = 1

        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(didTapForwardButton), for: .touchUpInside)

        [containerView, dateStackView, backButton, forwardButton, bottomSeparatorLine].forEach(addSubview)

        let guide = safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: guide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            guide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            dateStackView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 9),
            dateStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),

            backButton.topAnchor.constraint(equalTo: guide.topAnchor),
            guide.bottomAnchor.constraint(equalTo: backButton.bottomAnchor),
            backButton.leadingAnchor.constraint(greaterThanOrEqualTo: dateStackView.trailingAnchor, constant: 8),

            forwardButton.topAnchor.constraint(equalTo: guide.topAnchor),
            guide.bottomAnchor.constraint(equalTo: forwardButton.bottomAnchor),
            forwardButton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor),
            guide.trailingAnchor.constraint(equalTo: forwardButton.trailingAnchor, constant: 8),

            bottomSeparatorLine.topAnchor.constraint(equalTo: dateStackView.bottomAnchor, constant: 9),
            bottomSeparatorLine.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: bottomSeparatorLine.trailingAnchor),
            guide.bottomAnchor.constraint(equalTo: bottomSeparatorLine.bottomAnchor)
        ])
    }

    private static func makeNavigationButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.isGhostableDisabled = true
        return button
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        // Restart animation when toggling light/dark mode so colors are updated.
        restartGhostAnimation(style: GhostCellStyle.muriel)
    }

    func configure(
        date: Date?,
        period: StatsPeriodUnit?,
        delegate: SiteStatsTableHeaderDelegate,
        expectedPeriodCount: Int = SiteStatsTableHeaderView.defaultPeriodCount,
        mostRecentDate: Date? = nil
    ) {

        self.date = {
            if let date,
                let mostRecentDate,
                mostRecentDate < date
            {
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
        dateLabel.accessibilityLabel = displayDateAccessibilityLabel()

        backButton.accessibilityLabel = NSLocalizedString("Previous period", comment: "Accessibility label")
        backButton.accessibilityHint = NSLocalizedString(
            "Tap to select the previous period",
            comment: "Accessibility hint"
        )
        backButton.accessibilityTraits = backButton.isEnabled ? [.button] : [.button, .notEnabled]

        forwardButton.accessibilityLabel = NSLocalizedString("Next period", comment: "Accessibility label")
        forwardButton.accessibilityHint = NSLocalizedString(
            "Tap to select the next period",
            comment: "Accessibility hint"
        )
        forwardButton.accessibilityTraits = forwardButton.isEnabled ? [.button] : [.button, .notEnabled]

        accessibilityElements = [
            dateLabel,
            timezoneLabel,
            backButton,
            forwardButton
        ]
        .compactMap { $0 }
    }

    func animateGhostLayers(_ animate: Bool) {
        if animate {
            isRunningGhostAnimation = true
            startGhostAnimation(style: GhostCellStyle.muriel)
        } else {
            isRunningGhostAnimation = false
            stopGhostAnimation()
        }

        updateButtonStates()
    }
}

private extension SiteStatsTableHeaderView {

    func applyStyles() {
        backgroundColor = .secondarySystemGroupedBackground

        backButton.configuration = makeNavigationButtonConfiguraiton(systemImage: "chevron.backward")
        forwardButton.configuration = makeNavigationButtonConfiguraiton(systemImage: "chevron.forward")

        Style.configureLabelAsCellRowTitle(dateLabel)
        dateLabel.font = Metrics.dateLabelFont
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.minimumScaleFactor = Metrics.minimumScaleFactor

        Style.configureLabelAsChildRowTitle(timezoneLabel)
        timezoneLabel.font = Metrics.timezoneFont
        timezoneLabel.adjustsFontForContentSizeCategory = true
        timezoneLabel.minimumScaleFactor = Metrics.minimumScaleFactor

        Style.configureViewAsSeparator(bottomSeparatorLine)

        // Required as the Style separator configure method clears all
        // separators for the Stats Revamp in Insights.
        bottomSeparatorLine.backgroundColor = .separator
    }

    private func makeNavigationButtonConfiguraiton(systemImage: String) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.buttonSize = .small
        configuration.baseForegroundColor = .label
        configuration.image = UIImage(systemName: systemImage)
        return configuration
    }

    func displayDate() -> String? {
        guard let components = displayDateComponents() else {
            return nil
        }

        let (fromDate, toDate) = components

        if let toDate {
            return "\(fromDate) - \(toDate)"
        } else {
            return "\(fromDate)"
        }
    }

    func displayDateAccessibilityLabel() -> String? {
        guard let components = displayDateComponents() else {
            return nil
        }

        let (fromDate, toDate) = components

        if let toDate {
            let format = NSLocalizedString(
                "Current period: %@ to %@",
                comment:
                    "Week Period Accessibility label. Prefix the current selected period. Ex. Current period: Jan 6 to Jan 12."
            )
            return .localizedStringWithFormat(format, fromDate, toDate)
        } else {
            let format = NSLocalizedString(
                "Current period: %@",
                comment: "Period Accessibility label. Prefix the current selected period. Ex. Current period: 2019"
            )
            return .localizedStringWithFormat(format, fromDate)
        }
    }

    /// Returns the formatted dates for the current period.
    func displayDateComponents() -> (fromDate: String, toDate: String?)? {
        guard let date, let period else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate(period.dateFormatTemplate)

        switch period {
        case .hour:
            wpAssertionFailure("StatsPeriodHelper.hour period is unsupported in the legacy stats")
            return (dateFormatter.string(from: date), nil)
        case .day, .month, .year:
            return (dateFormatter.string(from: date), nil)
        case .week:
            let week = StatsPeriodHelper().weekIncludingDate(date)
            guard let weekStart = week?.weekStart, let weekEnd = week?.weekEnd else {
                return nil
            }

            return (dateFormatter.string(from: weekStart), dateFormatter.string(from: weekEnd))
        }
    }

    func displayTimezone() {
        guard !SiteStatsInformation.sharedInstance.timeZoneMatchesDevice(),
            let siteTimeZone = SiteStatsInformation.sharedInstance.siteTimeZone
        else {
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

    @objc func didTapBackButton(_ sender: UIButton) {
        captureAnalyticsEvent(.statsDateTappedBackward)
        updateDate(forward: false)
    }

    @objc func didTapForwardButton(_ sender: UIButton) {
        captureAnalyticsEvent(.statsDateTappedForward)
        updateDate(forward: true)
    }

    func updateDate(forward: Bool) {
        if let delegate = delegate as? SiteStatsTableHeaderDateButtonDelegate {
            delegate.didTouchHeaderButton(forward: forward)
            return
        }

        guard let date, let period else {
            return
        }

        let value = forward ? 1 : -1

        self.date = StatsPeriodHelper().calculateEndDate(from: date, offsetBy: value, unit: period)

        delegate?.dateChangedTo(self.date)
        reloadView()
    }

    func updateButtonStates() {
        guard !isRunningGhostAnimation else {
            forwardButton.isEnabled = false
            backButton.isEnabled = false
            return
        }

        guard let date, let period else {
            forwardButton.isEnabled = false
            backButton.isEnabled = false
            return
        }

        let helper = StatsPeriodHelper()
        forwardButton.isEnabled = helper.dateAvailableAfterDate(date, period: period, mostRecentDate: mostRecentDate)
        backButton.isEnabled = helper.dateAvailableBeforeDate(
            date,
            period: period,
            backLimit: backLimit,
            mostRecentDate: mostRecentDate
        )
        prepareForVoiceOver()
    }

    func postAccessibilityPeriodLabel() {
        UIAccessibility.post(notification: .screenChanged, argument: dateLabel)
    }

    // MARK: - Analytics support

    func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        let properties: [String: Any] = [StatsPeriodUnit.analyticsPeriodKey: period?.description as Any]

        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, properties: properties, blogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event, withProperties: properties)
        }
    }
}

extension SiteStatsTableHeaderView: StatsBarChartViewDelegate {
    func statsBarChartTabSelected(_ tabIndex: Int) {}

    func statsBarChartValueSelected(_ statsBarChartView: StatsBarChartView, entryIndex: Int, entryCount: Int) {
        guard let period, entryCount > 0, entryCount <= SiteStatsTableHeaderView.defaultPeriodCount else {
            return
        }

        let periodShift = -((entryCount - 1) - entryIndex)
        let fromDate = mostRecentDate?.normalizedDate() ?? StatsDataHelper.currentDateForSite().normalizedDate()
        self.date = StatsPeriodHelper().calculateEndDate(from: fromDate, offsetBy: periodShift, unit: period)

        delegate?.dateChangedTo(self.date)
        reloadView()
    }
}

private extension SiteStatsTableHeaderView {
    enum Metrics {
        static let dateLabelFontSize: CGFloat = 20
        static let maximumDateLabelFontSize: CGFloat = 32
        static let timezoneFontSize: CGFloat = 16
        static let maximumTimezoneFontSize: CGFloat = 20
        static let minimumScaleFactor: CGFloat = 0.8

        static var dateLabelFont: UIFont {
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
            let font = UIFont(descriptor: fontDescriptor, size: dateLabelFontSize)
            return UIFontMetrics.default.scaledFont(for: font, maximumPointSize: maximumDateLabelFontSize)
        }

        static var timezoneFont: UIFont {
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .callout)
            let font = UIFont(descriptor: fontDescriptor, size: timezoneFontSize)
            return UIFontMetrics.default.scaledFont(for: font, maximumPointSize: maximumTimezoneFontSize)
        }
    }
}
