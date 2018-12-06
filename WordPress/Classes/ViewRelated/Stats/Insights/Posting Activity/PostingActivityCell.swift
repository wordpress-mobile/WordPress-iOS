import UIKit

class PostingActivityCell: UITableViewCell, NibLoadable {

    @IBOutlet weak var monthsStackView: UIStackView!
    @IBOutlet weak var viewMoreLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    func configure(monthsData: [[PostingActivityDayData]]) {
        addMonths(monthsData: monthsData)
    }

}

private extension PostingActivityCell {

    func applyStyles() {
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more posting activity.")
        viewMoreLabel.textColor = WPStyleGuide.Stats.actionTextColor
    }

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

    @IBAction func didTapViewMoreButton(_ sender: UIButton) {
        // TODO: show Posting Activity details
        let alertController =  UIAlertController(title: "Posting Activity will be shown here.",
                                                 message: nil,
                                                 preferredStyle: .alert)
        alertController.addCancelActionWithTitle("OK")
        alertController.presentFromRootViewController()
    }

}
