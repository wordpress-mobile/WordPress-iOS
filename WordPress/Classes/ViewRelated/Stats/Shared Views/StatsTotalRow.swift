import UIKit

struct StatsTotalRowData {
    var name: String
    var data: String
    var icon: UIImage?
    var nameDetail: String?
    var showDisclosure: Bool
    var showSeparator: Bool

    init(name: String,
         data: String,
         icon: UIImage? = nil,
         nameDetail: String? = nil,
         showDisclosure: Bool = false,
         showSeparator: Bool = true) {
        self.name = name
        self.data = data
        self.nameDetail = nameDetail
        self.icon = icon
        self.showDisclosure = showDisclosure
        self.showSeparator = showSeparator
    }
}

class StatsTotalRow: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var imageStackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var itemDetailLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var disclosureStackView: UIStackView!

    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(rowData: StatsTotalRowData) {

        // Set values
        imageView.image = rowData.icon
        itemLabel.text = rowData.name
        itemDetailLabel.text = rowData.nameDetail
        dataLabel.text = rowData.data

        // Toggle optionals
        imageStackView.isHidden = (rowData.icon == nil)
        disclosureStackView.isHidden = !rowData.showDisclosure
        separatorLine.isHidden = !rowData.showSeparator
        itemDetailLabel.isHidden = (rowData.nameDetail == nil)

        applyStyles()
    }

}

private extension StatsTotalRow {

    func applyStyles() {
        Style.configureLabelAsCellRowTitle(itemLabel)
        Style.configureLabelItemDetail(itemDetailLabel)
        Style.configureLabelAsData(dataLabel)
        Style.configureViewAsSeperator(separatorLine)
    }

}
