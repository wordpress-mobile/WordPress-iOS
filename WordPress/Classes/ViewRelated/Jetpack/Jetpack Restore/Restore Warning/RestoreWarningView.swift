import Foundation
import Gridicons
import WordPressUI

class RestoreWarningView: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet private weak var confirmButton: FancyButton!
    @IBOutlet private weak var cancelButton: FancyButton!

    var confirmHandler: (() -> Void)?
    var cancelHandler: (() -> Void)?

    // MARK: - Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    // MARK: - Styling

    private func applyStyles() {
        backgroundColor = .basicBackground

        icon.tintColor = .error

        titleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        titleLabel.textColor = .text

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        descriptionLabel.textColor = .text
        descriptionLabel.numberOfLines = 0

        confirmButton.isPrimary = true

        cancelButton.isPrimary = false
    }

    // MARK: - Configuration

    func configure(with publishedDate: String) {
        icon.image = .gridicon(.notice)
        titleLabel.text = Strings.title
        descriptionLabel.text = String(format: Strings.descriptionFormat, publishedDate)
        confirmButton.setTitle(Strings.confirmButtonTitle, for: .normal)
        cancelButton.setTitle(Strings.cancelButtonTitle, for: .normal)
    }

    // MARK: - IBAction

    @IBAction private func confirmButtonTapped(_ sender: Any) {
        confirmHandler?()
    }

    @IBAction private func cancelButtonTapped(_ sender: Any) {
        cancelHandler?()
    }

    private enum Strings {
        static let title = NSLocalizedString("Warning", comment: "Noun. Title for Jetpack Restore warning.")
        static let descriptionFormat = NSLocalizedString("Are you sure you want to restore your site back to %1$@? This will remove content and options created or changed since then.", comment: "Description for the confirm restore action. %1$@ is a placeholder for the selected date.")
        static let confirmButtonTitle = NSLocalizedString("Confirm", comment: "Verb. Title for Jetpack Restore confirm button.")
        static let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Verb. Title for Jetpack Restore cancel button.")
    }
}
