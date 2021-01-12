import Foundation
import Gridicons
import WordPressUI

class RestoreWarningView: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var body: UILabel!
    @IBOutlet private weak var confirmButton: FancyButton!
    @IBOutlet private weak var cancelButton: FancyButton!

    var confirmHandler: (() -> Void)?
    var cancelHandler: (() -> Void)?

    // MARK: - Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        configure()
    }

    // MARK: - Styling

    private func applyStyles() {
        backgroundColor = .basicBackground

        icon.tintColor = .error

        title.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        title.textColor = .text

        body.font = WPStyleGuide.fontForTextStyle(.body)
        body.textColor = .text
        body.numberOfLines = 0

        confirmButton.isPrimary = true

        cancelButton.isPrimary = false
    }

    // MARK: - Configuration

    func configure() {
        icon.image = .gridicon(.notice)
        title.text = Strings.title
        body.text = String(format: Strings.bodyFormat, "placeholder date")
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
        static let bodyFormat = NSLocalizedString("Are you sure you want to rewind your site back to %1$@? This will remove all content and options created or changed since then.", comment: "Description for the confirm restore action. %1$@ is a placeholder for the selected date.")
        static let confirmButtonTitle = NSLocalizedString("Confirm", comment: "Verb. Title for Jetpack Restore confirm button.")
        static let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Verb. Title for Jetpack Restore cancel button.")
    }
}
