import UIKit

class JetpackScanStatusCell: UITableViewCell, NibReusable {
    @IBOutlet weak var iconContainerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var primaryButton: FancyButton!
    @IBOutlet weak var secondaryButton: FancyButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.primaryButton.isHidden = true
        self.secondaryButton.isHidden = true
    }

    public func configure(with model: JetpackScanStatusViewModel) {
        iconImageView.image = UIImage(named: model.imageName)
        titleLabel.text = model.title
        descriptionLabel.text = model.description

        if let primaryTitle = model.primaryButtonTitle {
            primaryButton.setTitle(primaryTitle, for: .normal)
            primaryButton.isHidden = false
        } else {
            primaryButton.isHidden = true
        }

        if let secondaryTitle = model.secondaryButtonTitle {
            secondaryButton.setTitle(secondaryTitle, for: .normal)
            secondaryButton.isHidden = false
        } else {
            secondaryButton.isHidden = true
        }
    }
}
