import UIKit

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

class StatsTwoColumnRow: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var leftItemLabel: UILabel!
    @IBOutlet weak var leftDataLabel: UILabel!
    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var rightItemLabel: UILabel!
    @IBOutlet weak var rightDataLabel: UILabel!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure() {
        applyStyles()
    }

}

// MARK: - Private Extension

private extension StatsTwoColumnRow {

    func applyStyles() {
        Style.configureLabelAsCellRowTitle(leftItemLabel)
        Style.configureLabelAsCellRowTitle(leftDataLabel)
        Style.configureLabelAsCellRowTitle(rightItemLabel)
        Style.configureLabelAsCellRowTitle(rightDataLabel)
        Style.configureViewAsVerticalSeparator(separatorLine)
    }

}
