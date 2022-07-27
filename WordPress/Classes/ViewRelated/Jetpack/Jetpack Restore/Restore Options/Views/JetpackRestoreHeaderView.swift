import Foundation
import Gridicons
import WordPressUI

class JetpackRestoreHeaderView: UIView, NibReusable {

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var actionButton: FancyButton!
    @IBOutlet private weak var warningButton: MultilineButton!

    var actionButtonHandler: (() -> Void)?
    var warningButtonHandler: (() -> Void)?

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

        warningButton.setTitleColor(.text, for: .normal)
        warningButton.titleLabel?.lineBreakMode = .byWordWrapping
        warningButton.titleLabel?.numberOfLines = 0
    }

    // MARK: - Configuration

    func configure(iconImage: UIImage,
                   title: String,
                   description: String,
                   buttonTitle: String,
                   warningButtonTitle: HighlightedText?) {
        icon.image = iconImage
        titleLabel.text = title
        descriptionLabel.text = description
        actionButton.setTitle(buttonTitle, for: .normal)

        if let warningButtonTitle = warningButtonTitle {
            let attributedTitle = WPStyleGuide.Jetpack.highlightString(warningButtonTitle.substring,
                                                                       inString: warningButtonTitle.string)
            warningButton.setAttributedTitle(attributedTitle, for: .normal)

            warningButton.setImage(.gridicon(.plusSmall), for: .normal)

            warningButton.isHidden = false
        } else {
            warningButton.isHidden = true
        }
    }

    // MARK: - Public

    func toggleActionButton(isEnabled: Bool) {
        actionButton.isEnabled = isEnabled
    }

    // MARK: - IBActions

    @IBAction private func actionButtonTapped(_ sender: UIButton) {
        actionButtonHandler?()
    }

    @IBAction private func warningButtonTapped(_ sender: UIButton) {
        warningButtonHandler?()
    }
}
