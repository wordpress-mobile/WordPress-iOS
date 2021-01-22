import UIKit

class JetpackScanThreatCell: UITableViewCell, NibReusable {
    @IBOutlet weak var iconBackgroundImageView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!

    func configure(with model: JetpackScanThreatViewModel) {
        applyStyles()

        iconBackgroundImageView.backgroundColor = model.iconImageColor
        iconImageView.image = model.iconImage
        titleLabel.text = model.title

        detailLabel.text = model.description ?? ""
        detailLabel.isHidden = model.description == nil
    }

    private func applyStyles() {
        titleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
        titleLabel.textColor = .text

        detailLabel.textColor = .textSubtle
        detailLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
    }
}
