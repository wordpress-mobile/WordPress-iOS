import UIKit

class PostingActivityMonth: UIView, NibLoadable {

    @IBOutlet weak var weeksStackView: UIStackView!
    @IBOutlet weak var monthLabel: UILabel!

    private var month: Date?
    private var monthData: [PostingActivityDayData]?

    func configure(monthData: [PostingActivityDayData]) {
        self.monthData = monthData
        getMonth()
        addDays()
    }

}

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
        let lastWeekIndex = weeksStackView.arrangedSubviews.count - 1

        while dayIndex < monthData.count {
            guard weekIndex < weeksStackView.arrangedSubviews.count,
                let weekStackView = weeksStackView.arrangedSubviews[weekIndex] as? UIStackView else {
                    break
            }

            for dayPosition in 0...6 {
                // For the first and last weeks, add placeholder days so the stack view is spaced properly.
                if (weekIndex == 0 && dayPosition < firstDayPosition) ||
                    (weekIndex == lastWeekIndex && dayPosition > lastDayPosition) {
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
    }

    func addDayToStackView(stackView: UIStackView, dayData: PostingActivityDayData? = nil) {
        let dayView = PostingActivityDay.loadFromNib()
        dayView.configure(dayData: dayData)
        stackView.addArrangedSubview(dayView)
    }
}
