import Foundation
import Gridicons
import WordPressUI

class RestoreStatusFailedView: UIView, NibLoadable {

    @IBOutlet private weak var messageTitleLabel: UILabel!
    @IBOutlet private weak var firstHintIcon: UIImageView!
    @IBOutlet private weak var firstHintLabel: UILabel!
    @IBOutlet private weak var secondHintIcon: UIImageView!
    @IBOutlet private weak var secondHintLabel: UILabel!
    @IBOutlet private weak var thirdHintIcon: UIImageView!
    @IBOutlet private weak var thirdHintLabel: UILabel!
    @IBOutlet private weak var doneButton: FancyButton!

    var doneButtonHandler: (() -> Void)?

    // MARK: - Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    // MARK: - Styling

    private func applyStyles() {
        backgroundColor = .systemBackground

        messageTitleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        messageTitleLabel.textColor = .label
        messageTitleLabel.numberOfLines = 0

        firstHintIcon.image = .gridicon(.history)
        firstHintIcon.tintColor = UIAppColor.warning

        secondHintIcon.image = .gridicon(.checkmarkCircle)
        secondHintIcon.tintColor = UIAppColor.success

        thirdHintIcon.image = .gridicon(.checkmarkCircle)
        thirdHintIcon.tintColor = UIAppColor.success

        let messageLabels = [firstHintLabel, secondHintLabel, thirdHintLabel]
        for label in messageLabels {
            label?.font = WPStyleGuide.fontForTextStyle(.body)
            label?.textColor = .label
            label?.numberOfLines = 0
        }

        doneButton.isPrimary = true
    }

    // MARK: - Configuration

    func configure(title: String,
                   firstHint: String,
                   secondHint: String,
                   thirdHint: String) {
        messageTitleLabel.text = title
        firstHintLabel.text = firstHint
        secondHintLabel.text = secondHint
        thirdHintLabel.text = thirdHint
        doneButton.setTitle(Strings.done, for: .normal)
    }

    // MARK: - IBAction

    @IBAction private func doneButtonTapped(_ sender: Any) {
        doneButtonHandler?()
    }

    private enum Strings {
        static let done = NSLocalizedString("Done", comment: "Title for button that will dismiss this view")
    }
}
