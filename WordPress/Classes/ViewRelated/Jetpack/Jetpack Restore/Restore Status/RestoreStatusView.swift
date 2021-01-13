import Foundation
import Gridicons
import WordPressUI

class RestoreStatusView: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var progressTitleLabel: UILabel!
    @IBOutlet private weak var progressValueLabel: UILabel!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var progressDescriptionLabel: UILabel!
    @IBOutlet private weak var primaryButton: FancyButton!
    @IBOutlet private weak var hintLabel: UILabel!

    var primaryButtonHandler: (() -> Void)?

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
        descriptionLabel.textColor = .textSubtle
        descriptionLabel.numberOfLines = 0

        progressTitleLabel.font = WPStyleGuide.fontForTextStyle(.body)
        progressTitleLabel.textColor = .text

        progressValueLabel.font = WPStyleGuide.fontForTextStyle(.body)
        progressValueLabel.textColor = .text

        progressDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        progressDescriptionLabel.textColor = .textSubtle

        hintLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        hintLabel.textColor = .textSubtle
        hintLabel.numberOfLines = 0

        primaryButton.isPrimary = true
    }

    // MARK: - Configuration

    func configure(iconImage: UIImage, title: String, description: String, primaryButtonTitle: String, hint: String) {
        icon.image = iconImage
        titleLabel.text = title
        descriptionLabel.text = description
        primaryButton.setTitle(primaryButtonTitle, for: .normal)
        hintLabel.text = hint
    }

    // MARK: - IBAction

    @IBAction private func primaryButtonTapped(_ sender: Any) {
        primaryButtonHandler?()
    }

}
