import UIKit

class ReaderDetailLikesView: UIView, NibLoadable {

    @IBOutlet weak var avatarStackView: UIStackView!
    @IBOutlet weak var summaryLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyStyles()
    }

}

private extension ReaderDetailLikesView {

    func applyStyles() {
        // Set border on all the avatar views
        for subView in avatarStackView.subviews {
            subView.layer.borderWidth = 1
            subView.layer.borderColor = UIColor.basicBackground.cgColor
        }

        summaryLabel.textColor = .secondaryLabel
    }

}
