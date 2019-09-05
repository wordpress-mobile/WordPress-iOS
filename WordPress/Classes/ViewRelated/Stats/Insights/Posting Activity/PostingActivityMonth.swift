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

    // MARK: - Configure

    func configure(monthData: [PostingStreakEvent], postingActivityDayDelegate: PostingActivityDayDelegate? = nil) {
        self.monthData = monthData
        self.postingActivityDayDelegate = postingActivityDayDelegate
        getMonth()
        addDays()
    }

    func configureGhost(monthData: [PostingStreakEvent]) {
        self.monthData = monthData
        monthLabel.text = ""
        addDays()
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
