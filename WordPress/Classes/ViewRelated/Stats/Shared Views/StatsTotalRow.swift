import UIKit

struct StatsTotalRowData {
    var name: String
    var data: String
    var icon: UIImage?
    var iconURL: URL?
    var nameDetail: String?
    var showDisclosure: Bool

    init(name: String,
         data: String,
         icon: UIImage? = nil,
         iconURL: URL? = nil,
         nameDetail: String? = nil,
         showDisclosure: Bool = false) {
        self.name = name
        self.data = data
        self.nameDetail = nameDetail
        self.icon = icon
        self.iconURL = iconURL
        self.showDisclosure = showDisclosure
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

    var showSeparator = true {
        didSet {
            separatorLine.isHidden = !showSeparator
        }
    }

    // MARK: - Configure

    func configure(rowData: StatsTotalRowData) {

        // Configure icon
        imageStackView.isHidden = true

        if let icon = rowData.icon {
            imageView.image = icon
            imageStackView.isHidden = false
        }

        if let iconURL = rowData.iconURL {
            downloadImageFrom(iconURL)
        }

        // Set other values
        itemLabel.text = rowData.name
        itemDetailLabel.text = rowData.nameDetail
        dataLabel.text = rowData.data

        // Toggle optionals
        disclosureStackView.isHidden = !rowData.showDisclosure
        itemDetailLabel.isHidden = (rowData.nameDetail == nil)
        separatorLine.isHidden = !showSeparator

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

    func downloadImageFrom(_ iconURL: URL) {
        WPImageSource.shared()?.downloadImage(for: iconURL, withSuccess: { image in
            self.imageView.image = image
            self.imageStackView.isHidden = false
        }, failure: { error in
            DDLogInfo("Error downloading image: \(String(describing: error?.localizedDescription)). From URL: \(iconURL).")
            self.imageStackView.isHidden = true
        })
    }

}
