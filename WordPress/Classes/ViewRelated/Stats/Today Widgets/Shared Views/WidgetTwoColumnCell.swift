import UIKit

class WidgetTwoColumnCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "WidgetTwoColumnCell"
    static let defaultHeight: CGFloat = 78

    @IBOutlet private var leftItemLabel: UILabel!
    @IBOutlet private var leftDataLabel: UILabel!
    @IBOutlet private var rightItemLabel: UILabel!
    @IBOutlet private var rightDataLabel: UILabel!

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

        leftDataLabel.accessibilityLabel = leftItemData.accessibilityLabel
        rightDataLabel.accessibilityLabel = rightItemData.accessibilityLabel
    }

}

// MARK: - Private Extension

private extension WidgetTwoColumnCell {
    func configureColors() {
        leftItemLabel.textColor = WidgetStyles.primaryTextColor
        leftDataLabel.textColor = WidgetStyles.primaryTextColor
        rightItemLabel.textColor = WidgetStyles.primaryTextColor
        rightDataLabel.textColor = WidgetStyles.primaryTextColor
    }
}
