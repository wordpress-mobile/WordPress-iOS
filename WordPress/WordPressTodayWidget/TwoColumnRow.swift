import UIKit

class TwoColumnRow: UIView {

    // MARK: - Properties

    @IBOutlet private weak var leftItemLabel: UILabel!
    @IBOutlet private weak var leftDataLabel: UILabel!
    @IBOutlet private weak var rightItemLabel: UILabel!
    @IBOutlet private weak var rightDataLabel: UILabel!

    // MARK: - Configure

    func configure(leftColumnName: String, leftColumnData: String, rightColumnName: String, rightColumnData: String) {
        leftItemLabel.text = leftColumnName
        leftDataLabel.text = leftColumnData
        rightItemLabel.text = rightColumnName
        rightDataLabel.text = rightColumnData

        configureColors()
    }

    func updateData(leftColumnData: String, rightColumnData: String) {
        leftDataLabel.text = leftColumnData
        rightDataLabel.text = rightColumnData
    }
}

// MARK: - Private Extension

private extension TwoColumnRow {
    func configureColors() {
        leftItemLabel.textColor = .text
        leftDataLabel.textColor = .text
        rightItemLabel.textColor = .text
        rightDataLabel.textColor = .text
    }
}
