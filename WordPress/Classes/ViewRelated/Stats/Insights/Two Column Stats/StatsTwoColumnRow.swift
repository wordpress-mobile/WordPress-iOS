import UIKit
import DesignSystem

struct StatsTwoColumnRowData {
    var leftColumnName: String
    var leftColumnData: String
    var rightColumnName: String
    var rightColumnData: String

    init(leftColumnName: String,
         leftColumnData: String,
         rightColumnName: String,
         rightColumnData: String) {
        self.leftColumnName = leftColumnName
        self.leftColumnData = leftColumnData
        self.rightColumnName = rightColumnName
        self.rightColumnData = rightColumnData
    }
}

class StatsTwoColumnRow: UIView, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet weak var leftItemLabel: UILabel!
    @IBOutlet weak var leftDataLabel: UILabel!
    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var rightItemLabel: UILabel!
    @IBOutlet weak var rightDataLabel: UILabel!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(rowData: StatsTwoColumnRowData) {
        leftItemLabel.text = rowData.leftColumnName
        leftDataLabel.text = rowData.leftColumnData
        rightItemLabel.text = rowData.rightColumnName
        rightDataLabel.text = rowData.rightColumnData

        leftDataLabel.accessibilityLabel = rowData.leftColumnData.accessibilityLabel
        rightDataLabel.accessibilityLabel = rowData.rightColumnData.accessibilityLabel

        applyStyles()
        prepareForVoiceOver()
    }

    func prepareForVoiceOver() {
        accessibilityElements = [leftItemLabel, leftDataLabel, rightItemLabel, rightDataLabel].compactMap { $0 }
    }
}

// MARK: - Private Extension

private extension StatsTwoColumnRow {

    func applyStyles() {
        Style.configureLabelAsCellValueTitle(leftItemLabel)
        Style.configureLabelAsCellValue(leftDataLabel)
        Style.configureLabelAsCellValueTitle(rightItemLabel)
        Style.configureLabelAsCellValue(rightDataLabel)
        Style.configureViewAsVerticalSeparator(separatorLine)
    }

}
