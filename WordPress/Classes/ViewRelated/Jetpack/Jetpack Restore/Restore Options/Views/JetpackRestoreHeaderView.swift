import Foundation
import Gridicons
import WordPressUI

class JetpackRestoreHeaderView: UIView, NibReusable {

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var actionButton: FancyButton!
    @IBOutlet private weak var detailActionButton: UIButton!

    var actionButtonHandler: (() -> Void)?
    var detailActionButtonHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    // MARK: - Styling

    private func applyStyles() {
        icon.tintColor = .success

        titleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        titleLabel.textColor = .text

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        descriptionLabel.textColor = .textSubtle
        descriptionLabel.numberOfLines = 0
        descriptionLabel.preferredMaxLayoutWidth = descriptionLabel.bounds.width

        actionButton.isPrimary = true

        detailActionButton.titleLabel?.lineBreakMode = .byWordWrapping
    }

    // MARK: - Configuration

    func configure(iconImage: UIImage, title: String, description: String, buttonTitle: String, detailButtonTitle: String?) {
        icon.image = iconImage
        titleLabel.text = title
        descriptionLabel.text = description
        actionButton.setTitle(buttonTitle, for: .normal)

        if let detailButtonTitle = detailButtonTitle {
            detailActionButton.setTitle(detailButtonTitle, for: .normal)
            detailActionButton.isHidden = false
        } else {
            detailActionButton.isHidden = true
        }

        toggleActionButton(isEnabled: detailActionButton.isHidden)
    }

    // MARK: - Public

    func toggleActionButton(isEnabled: Bool) {
        actionButton.isEnabled = isEnabled
    }

    // MARK: - IBActions

    @IBAction private func actionButtonTapped(_ sender: UIButton) {
        actionButtonHandler?()
    }

    @IBAction private func detailActionButtonTapped(_ sender: UIButton) {
        detailActionButtonHandler?()
    }
}
