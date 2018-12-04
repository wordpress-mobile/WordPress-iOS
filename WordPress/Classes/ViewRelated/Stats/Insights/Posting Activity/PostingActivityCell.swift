import UIKit

class PostingActivityCell: UITableViewCell, NibLoadable {

    @IBOutlet weak var monthsStackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()
        addMonths()
    }

    func configure() {
        
    }

}

private extension PostingActivityCell {

    func addMonths() {
        for _ in 1...3 {
            let monthView = PostingActivityMonth.loadFromNib()
            monthsStackView.addArrangedSubview(monthView)
        }
    }

}
