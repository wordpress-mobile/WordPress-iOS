import UIKit

class PostingActivityCell: UITableViewCell, NibLoadable {

    @IBOutlet weak var monthsStackView: UIStackView!

    func configure(monthsData: [[PostingActivityDayData]]) {
        addMonths(monthsData: monthsData)
    }

}

private extension PostingActivityCell {

    func addMonths(monthsData: [[PostingActivityDayData]]) {

        removeExistingMonths()

        for monthData in monthsData {
            let monthView = PostingActivityMonth.loadFromNib()
            monthView.configure(monthData: monthData)
            monthsStackView.addArrangedSubview(monthView)
        }
    }

    func removeExistingMonths() {
        monthsStackView.arrangedSubviews.forEach {
            monthsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

}
