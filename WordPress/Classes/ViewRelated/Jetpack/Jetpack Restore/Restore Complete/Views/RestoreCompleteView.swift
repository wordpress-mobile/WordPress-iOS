import Foundation
import Gridicons
import WordPressUI

class RestoreCompleteView: UIView, NibLoadable {

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var buttonStackView: UIStackView!
    @IBOutlet private weak var primaryButton: FancyButton!
    @IBOutlet private weak var secondaryButton: FancyButton!
    @IBOutlet private weak var hintLabel: UILabel!

    var primaryButtonHandler: (() -> Void)?
    var secondaryButtonHandler: ((_ sender: UIButton) -> Void)?

    // MARK: - Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    // MARK: - Styling

    private func applyStyles() {
        backgroundColor = .basicBackground

        titleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        titleLabel.textColor = .text
        titleLabel.numberOfLines = 0

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        descriptionLabel.textColor = .textSubtle
        descriptionLabel.numberOfLines = 0

        primaryButton.isPrimary = true

        secondaryButton.isPrimary = false

        hintLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        hintLabel.textColor = .textSubtle
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
    }

    // MARK: - Configuration

    func configure(iconImage: UIImage,
                   iconImageColor: UIColor,
                   title: String,
                   description: String,
                   primaryButtonTitle: String?,
                   secondaryButtonTitle: String?,
                   hint: String?) {

        icon.image = iconImage
        icon.tintColor = iconImageColor

        titleLabel.text = title

        descriptionLabel.text = description

        secondaryButton.setTitle(secondaryButtonTitle, for: .normal)

        if let primaryButtonTitle = primaryButtonTitle {
            primaryButton.setTitle(primaryButtonTitle, for: .normal)
            primaryButton.isHidden = false
        } else {
            primaryButton.isHidden = true
        }

        if let secondaryButtonTitle = secondaryButtonTitle {
            secondaryButton.setTitle(secondaryButtonTitle, for: .normal)
            secondaryButton.isHidden = false
        } else {
            secondaryButton.isHidden = true
        }

        if let hint = hint {
            hintLabel.text = hint
            hintLabel.isHidden = false
        } else {
            hintLabel.isHidden = true
        }
    }

    // MARK: - IBAction

    @IBAction private func primaryButtonTapped(_ sender: Any) {
        primaryButtonHandler?()
    }

    @IBAction private func secondaryButtonTapped(_ sender: UIButton) {
        secondaryButtonHandler?(sender as UIButton)
    }
}
