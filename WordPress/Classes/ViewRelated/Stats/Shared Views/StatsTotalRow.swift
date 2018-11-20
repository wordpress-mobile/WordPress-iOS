import UIKit

struct StatsTotalRowData {
    var name: String
    var data: String
    var icon: UIImage?
    var nameDetail: String?
    var showDisclosure: Bool

    init(name: String, data: String, nameDetail: String? = nil, icon: UIImage? = nil, showDisclosure: Bool = false) {
        self.name = name
        self.data = data
        self.nameDetail = nameDetail
        self.icon = icon
        self.showDisclosure = showDisclosure
    }
}

class StatsTotalRow: UIView, NibLoadable {

    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var imageStackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var itemDetailLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var disclosureStackView: UIStackView!

    private typealias Style = WPStyleGuide.Stats

    var showImage = true {
        didSet {
            imageStackView.isHidden = !showImage
        }
    }

    var showDisclosure = false {
        didSet {
            disclosureStackView.isHidden = !showDisclosure
        }
    }

    var showSeparator = true {
        didSet {
            separatorLine.isHidden = !showSeparator
        }
    }

    var showItemDetailLabel = false {
        didSet {
            itemDetailLabel.isHidden = !showItemDetailLabel
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
        imageStackView.isHidden = !showImage
        disclosureStackView.isHidden = !showDisclosure
        separatorLine.isHidden = !showSeparator
        itemDetailLabel.isHidden = !showItemDetailLabel
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
