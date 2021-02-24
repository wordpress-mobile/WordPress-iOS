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
    @IBOutlet private weak var hintLabel: UILabel!

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

        progressValueLabel.font = WPStyleGuide.fontForTextStyle(.body)
        progressValueLabel.textColor = .text

        progressTitleLabel.font = WPStyleGuide.fontForTextStyle(.body)
        progressTitleLabel.textColor = .text
        if effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next inverse_text_alignment
            progressTitleLabel.textAlignment = .right
        } else {
            // swiftlint:disable:next natural_text_alignment
            progressTitleLabel.textAlignment = .left
        }

        progressView.layer.cornerRadius = Constants.progressViewCornerRadius
        progressView.clipsToBounds = true

        progressDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        progressDescriptionLabel.textColor = .textSubtle

        hintLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        hintLabel.textColor = .textSubtle
        hintLabel.numberOfLines = 0
    }

    // MARK: - Configuration

    func configure(iconImage: UIImage, title: String, description: String, hint: String) {
        icon.image = iconImage
        titleLabel.text = title
        descriptionLabel.text = description
        hintLabel.text = hint
    }

    func update(progress: Int, progressTitle: String? = nil, progressDescription: String? = nil) {

        progressValueLabel.text = "\(progress)%"
        progressView.progress = Float(progress) / 100

        if let progressTitle = progressTitle {
            progressTitleLabel.text = progressTitle
            progressTitleLabel.isHidden = false
        } else {
            progressTitleLabel.isHidden = true
        }

        if let progressDescription = progressDescription {
            progressDescriptionLabel.text = progressDescription
            progressDescriptionLabel.isHidden = false
        } else {
            progressDescriptionLabel.isHidden = true
        }
    }

    // MARK: - IBAction
    private enum Constants {
        static let progressViewCornerRadius: CGFloat = 4
    }
}
