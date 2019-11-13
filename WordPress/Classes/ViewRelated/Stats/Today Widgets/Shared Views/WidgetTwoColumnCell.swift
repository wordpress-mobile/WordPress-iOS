import UIKit

class WidgetTwoColumnCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetTwoColumnCell"

    @IBOutlet private weak var leftItemLabel: UILabel!
    @IBOutlet private weak var leftDataLabel: UILabel!
    @IBOutlet private weak var rightItemLabel: UILabel!
    @IBOutlet private weak var rightDataLabel: UILabel!

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureColors()
    }

    // MARK: - Configure

    func configure(leftItemName: String, leftItemData: String, rightItemName: String, rightItemData: String) {
        leftItemLabel.text = leftItemName
        leftDataLabel.text = leftItemData
        rightItemLabel.text = rightItemName
        rightDataLabel.text = rightItemData
    }

}

// MARK: - Private Extension

private extension WidgetTwoColumnCell {
    func configureColors() {
        leftItemLabel.textColor = .text
        leftDataLabel.textColor = .text
        rightItemLabel.textColor = .text
        rightDataLabel.textColor = .text
    }
}
