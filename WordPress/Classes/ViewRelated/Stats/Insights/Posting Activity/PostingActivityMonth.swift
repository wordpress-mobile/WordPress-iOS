import UIKit

class PostingActivityMonth: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var weeksStackView: UIStackView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var viewWidthConstraint: NSLayoutConstraint!

    private var month: Date?
    private var monthData: [PostingStreakEvent]?
    private weak var postingActivityDayDelegate: PostingActivityDayDelegate?

    // 14 = day width (12) + column margin (2).
    // Used to adjust the view width when hiding the last stack view.
    private let lastStackViewWidth = CGFloat(14)

    /// The only accessibility element for self.
    ///
    /// This is only loaded if accessibility features are turned on.
    ///
    /// - SeeAlso: accessibilityElements
    ///
    private var accessibilityElement: PostingActivityMonthAccessibilityElement?

    override var accessibilityElements: [Any]? {
        get {
            if let elementForSelf = accessibilityElement {
                return [elementForSelf]
            }

            let elementForSelf = PostingActivityMonthAccessibilityElement(accessibilityContainer: self)
            elementForSelf.configure(month: month, events: monthData)

            accessibilityElement = elementForSelf

            return [elementForSelf]
        }
        set { }
    }

    // MARK: - Configure

    func configure(monthData: [PostingStreakEvent], postingActivityDayDelegate: PostingActivityDayDelegate? = nil) {
        self.monthData = monthData
        self.postingActivityDayDelegate = postingActivityDayDelegate
        getMonth()
        addDays()

        accessibilityElement?.configure(month: month, events: monthData)
    }

    func configureGhost(monthData: [PostingStreakEvent]) {
        self.monthData = monthData
        monthLabel.text = ""
        addDays()

        accessibilityElement?.configure(month: month, events: monthData)
    }
}

// MARK: - Private Extension

private extension PostingActivityMonth {

    func getMonth() {
        guard let firstDay = monthData?.first else {
            return
        }

        let dateComponents = Calendar.current.dateComponents([.year, .month], from: firstDay.date)
        month = Calendar.current.date(from: dateComponents)

        setMonthLabel()
    }

    func setMonthLabel() {
        guard let month = month else {
            monthLabel.text = ""
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLL"
        monthLabel.text = dateFormatter.string(from: month)
        WPStyleGuide.Stats.configureLabelAsPostingMonth(monthLabel)
    }

    func addDays() {
        guard let monthData = monthData,
        let firstDay = monthData.first,
        let lastDay = monthData.last else {
            return
        }

        // Since our week starts on Monday, adjust the dayOfWeek by 2 (Monday is the 2nd day of the week).
        // i.e. move every day up by 2 positions in the vertical week.
        let firstDayOfWeek = Calendar.current.component(.weekday, from: firstDay.date)
        let firstDayPosition = firstDayOfWeek - 2

        let lastDayOfWeek = Calendar.current.component(.weekday, from: lastDay.date)
        let lastDayPosition = lastDayOfWeek - 2

        var dayIndex = 0
        var weekIndex = 0

        while dayIndex < monthData.count {
            guard weekIndex < weeksStackView.arrangedSubviews.count,
                let weekStackView = weeksStackView.arrangedSubviews[weekIndex] as? UIStackView else {
                    break
            }

            for dayPosition in 0...6 {
                // For the first and last weeks, add placeholder days so the stack view is spaced properly.
                if (weekIndex == 0 && dayPosition < firstDayPosition) ||
                    (dayIndex >= monthData.count && dayPosition > lastDayPosition) {
                    addDayToStackView(stackView: weekStackView)
                } else {
                    guard dayIndex < monthData.count else {
                        continue
                    }
                    addDayToStackView(stackView: weekStackView, dayData: monthData[dayIndex])
                    dayIndex += 1
                }
            }
            weekIndex += 1
        }

        toggleLastStackView(lastStackViewUsed: weekIndex - 1)
    }

    func addDayToStackView(stackView: UIStackView, dayData: PostingStreakEvent? = nil) {
        let dayView = PostingActivityDay.loadFromNib()
        dayView.configure(dayData: dayData, delegate: postingActivityDayDelegate)
        stackView.addArrangedSubview(dayView)
    }

    func toggleLastStackView(lastStackViewUsed: Int) {
        // Hide the last stack view if it was not used.
        // Adjust the Month view width accordingly.

        let lastStackViewIndex = weeksStackView.arrangedSubviews.count - 1
        let hideLastStackView = lastStackViewUsed < lastStackViewIndex

        weeksStackView.arrangedSubviews.last?.isHidden = hideLastStackView
        let viewWidthAdjustment = hideLastStackView ? lastStackViewWidth : 0
        viewWidthConstraint.constant -= viewWidthAdjustment
    }

}

// MARK: - Accessibility

/// An accessibility element for the whole `PostingActivityMonth` UI tree.
///
private class PostingActivityMonthAccessibilityElement: UIAccessibilityElement {

    private var events = [PostingStreakEvent]()

    /// The currently selected index for `event`
    ///
    /// This starts at -1 so that when `rotatedIndex(forward:)` is called with `true`, it will
    /// return with `0`, which is what we want.
    ///
    /// - SeeAlso: rotatedIndex(forward:)
    ///
    private var selectedIndex: Int = -1

    private lazy var monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }()

    override var accessibilityFrameInContainerSpace: CGRect {
        get {
            (accessibilityContainer as? UIView)?.bounds ?? CGRect.zero
        }
        set { }
    }

    override init(accessibilityContainer container: Any) {
        super.init(accessibilityContainer: container)

        accessibilityTraits = .adjustable
        isAccessibilityElement = false
    }

    func configure(month: Date?, events: [PostingStreakEvent]?) {
        isAccessibilityElement = month != nil

        if let month = month {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            accessibilityLabel = formatter.string(from: month)
        } else {
            accessibilityLabel = nil
        }

        self.events = (events ?? [PostingStreakEvent]()).filter { $0.postCount > 0 }
    }

    override func accessibilityDecrement() {
        rotateAccessibilityValue(forward: false)
    }

    override func accessibilityIncrement() {
        rotateAccessibilityValue(forward: true)
    }

    private func rotateAccessibilityValue(forward: Bool) {
        selectedIndex = rotatedIndex(forward: forward)

        guard events.isEmpty == false else {
            accessibilityValue = Strings.noPosts
            return
        }

        guard let event = events[safe: selectedIndex] else {
            accessibilityValue = nil
            return
        }

        if event.postCount == 1 {
            accessibilityValue = String(format: Strings.dayAndPostsSingular,
                                        monthDayFormatter.string(from: event.date))
        } else {
            accessibilityValue = String(format: Strings.dayAndPostsPlural,
                                        monthDayFormatter.string(from: event.date),
                                        event.postCount)
        }
    }

    /// Returns the rotated index value of `selectedIndex`.
    ///
    private func rotatedIndex(forward: Bool) -> Int {
        if forward {
            var index = selectedIndex + 1
            if index >= events.count {
                index = 0
            }
            return index
        } else {
            var index = selectedIndex - 1
            if index < 0 {
                index = events.count - 1
            }
            return index
        }
    }

    private enum Strings {
        static let noPosts =
            NSLocalizedString("No posts.",
                              comment: "Accessibility value for a Stats' Posting Activity Month if there are no posts.")
        static let dayAndPostsSingular =
            NSLocalizedString("%@. 1 post.",
                              comment: "Accessibility value for a Stats' Posting Activity Month if the user selected a day with posts."
                                + " The first parameter is day (e.g. November 2019).")
        static let dayAndPostsPlural =
            NSLocalizedString("%@. %d posts.",
                              comment: "Accessibility value for a Stats' Posting Activity Month if the user selected a day with posts."
                                + " The first parameter is day (e.g. November 2019). The second parameter is the number of posts.")
    }
}
