import UIKit

class PostingActivityMonth: UIView, NibLoadable {

    @IBOutlet weak var week1StackView: UIStackView!
    @IBOutlet weak var week2StackView: UIStackView!
    @IBOutlet weak var week3StackView: UIStackView!
    @IBOutlet weak var week4StackView: UIStackView!
    @IBOutlet weak var week5StackView: UIStackView!
    @IBOutlet weak var monthLabel: UILabel!

    private var monthData: [PostingActivityDayData]?

    func configure(monthData: [PostingActivityDayData]) {
        self.monthData = monthData
        setMonthLabel()
        addDays()
    }

}

private extension PostingActivityMonth {

    func setMonthLabel() {
        guard let firstDay = monthData?.first else {
            monthLabel.text = ""
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLL"
        monthLabel.text = dateFormatter.string(from: firstDay.date)
    }

    func addDays() {
        addDaysToStackView(week1StackView)
        addDaysToStackView(week2StackView)
        addDaysToStackView(week3StackView)
        addDaysToStackView(week4StackView)
        addDaysToStackView(week5StackView)
    }

    func addDaysToStackView(_ stackView: UIStackView) {
        for _ in 1...7 {
            let dayView = PostingActivityDay.loadFromNib()
            stackView.addArrangedSubview(dayView)
        }
    }

}
