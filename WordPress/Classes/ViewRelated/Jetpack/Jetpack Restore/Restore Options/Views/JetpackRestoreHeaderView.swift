import Foundation
import Gridicons
import WordPressUI

class JetpackRestoreHeaderView: UIView, NibReusable {

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var actionButton: FancyButton!

    var actionButtonHandler: (() -> Void)?

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
    }

    // MARK: - Configuration

    func configure(iconImage: UIImage, title: String, description: String, buttonTitle: String) {
        icon.image = iconImage
        titleLabel.text = title
        descriptionLabel.text = description
        actionButton.setTitle(buttonTitle, for: .normal)
    }

    // MARK: - Public

    func toggleActionButton(isEnabled: Bool) {
        actionButton.isEnabled = isEnabled
    }

    // MARK: - IBActions

    @IBAction private func actionButtonTapped(_ sender: UIButton) {
        actionButtonHandler?()
    }
}
