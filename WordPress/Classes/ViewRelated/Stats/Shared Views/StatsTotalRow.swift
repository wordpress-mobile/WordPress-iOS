import UIKit

class StatsTotalRow: UIView, NibLoadable {

    @IBOutlet weak var imageStackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var itemLabel: UILabel!
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

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()

        imageStackView.isHidden = !showImage
        disclosureStackView.isHidden = !showDisclosure
    }

}

private extension StatsTotalRow {

    func applyStyles() {
        Style.configureLabelAsCellRowTitle(itemLabel)
        Style.configureLabelAsData(dataLabel)
    }

}
