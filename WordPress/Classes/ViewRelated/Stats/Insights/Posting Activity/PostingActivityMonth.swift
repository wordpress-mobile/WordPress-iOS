import UIKit

class PostingActivityMonth: UIView, NibLoadable {

    @IBOutlet weak var week1StackView: UIStackView!
    @IBOutlet weak var week2StackView: UIStackView!
    @IBOutlet weak var week3StackView: UIStackView!
    @IBOutlet weak var week4StackView: UIStackView!
    @IBOutlet weak var week5StackView: UIStackView!
    @IBOutlet weak var monthLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        addDays()
    }

}

private extension PostingActivityMonth {

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
