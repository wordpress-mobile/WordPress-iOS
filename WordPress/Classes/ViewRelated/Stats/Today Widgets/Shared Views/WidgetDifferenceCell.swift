import UIKit

class WidgetDifferenceCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetDifferenceCell"

    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var dataLabel: UILabel!
    @IBOutlet private var differenceView: UIView!
    @IBOutlet private var differenceLabel: UILabel!
    @IBOutlet private var separatorLine: UIView!

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureColors()
    }

}

// MARK: - Private Extension

private extension WidgetDifferenceCell {
    func configureColors() {
        dateLabel.textColor = .text
        dataLabel.textColor = .text
        differenceLabel.textColor = .white
        separatorLine.backgroundColor = UIColor(light: .divider, dark: .textSubtle)
        differenceView.layer.cornerRadius = 4.0
    }
}
