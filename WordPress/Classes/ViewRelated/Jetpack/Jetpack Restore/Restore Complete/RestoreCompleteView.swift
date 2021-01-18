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
    var secondaryButtonHandler: (() -> Void)?

    // MARK: - Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    // MARK: - Styling

    private func applyStyles() {
        backgroundColor = .basicBackground

        icon.tintColor = .success

        titleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        titleLabel.textColor = .text
        titleLabel.numberOfLines = 0

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        descriptionLabel.textColor = .text
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
                   title: String,
                   description: String,
                   hint: String,
                   primaryButtonTitle: String,
                   secondaryButtonTitle: String?) {

        icon.image = iconImage
        titleLabel.text = title
        descriptionLabel.text = description
        hintLabel.text = hint

        primaryButton.setTitle(primaryButtonTitle, for: .normal)

        if let secondaryButtonTitle = secondaryButtonTitle {
            secondaryButton.setTitle(secondaryButtonTitle, for: .normal)
            secondaryButton.isHidden = false
        } else {
            secondaryButton.isHidden = true
        }
    }

    // MARK: - IBAction

    @IBAction func primaryButtonTapped(_ sender: Any) {
        primaryButtonHandler?()
    }

    @IBAction func secondaryButtonTapped(_ sender: Any) {
        secondaryButtonHandler?()
    }
}
