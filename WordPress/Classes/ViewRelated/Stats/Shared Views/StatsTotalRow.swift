import UIKit

class StatsTotalRow: UIView, NibLoadable {

    @IBOutlet weak var seperatorLine: UIView!
    @IBOutlet weak var imageStackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var disclosureStackView: UIStackView!

    private typealias Style = WPStyleGuide.Stats

    var showImage = true {
        didSet {
            toggleImage()
        }
    }

    var showDisclosure = false {
        didSet {
            disclosureStackView.isHidden = !showDisclosure
        }
    }

    var showSeparator = true {
        didSet {
            seperatorLine.isHidden = !showSeparator
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
        toggleImage()
        disclosureStackView.isHidden = !showDisclosure
        seperatorLine.isHidden = !showSeparator
    }

}

private extension StatsTotalRow {

    func applyStyles() {
        Style.configureLabelAsCellRowTitle(itemLabel)
        Style.configureLabelAsData(dataLabel)
        Style.configureViewAsSeperator(seperatorLine)
    }

    func toggleImage() {
        if imageView.image == nil {
            imageStackView.isHidden = true
        } else {
            imageStackView.isHidden = !showImage
        }
    }
}
