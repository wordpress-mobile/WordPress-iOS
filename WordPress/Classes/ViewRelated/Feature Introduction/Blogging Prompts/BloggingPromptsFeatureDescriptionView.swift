import UIKit

class BloggingPromptsFeatureDescriptionView: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet private weak var promptCardView: UIView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var noteTextView: UITextView!

    // MARK: - Init

    open override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

}

private extension BloggingPromptsFeatureDescriptionView {

    func configureView() {
        promptCardView.layer.borderWidth = Style.borderWidth
        promptCardView.layer.cornerRadius = Style.cardCornerRadius
        promptCardView.layer.borderColor = Style.borderColor

        let promptCard = DashboardPromptsCardCell()
        promptCard.configureForExampleDisplay()
        promptCard.translatesAutoresizingMaskIntoConstraints = false
        promptCardView.addSubview(promptCard)
        promptCardView.pinSubviewToSafeArea(promptCard)

        descriptionLabel.font = Style.labelFont
        descriptionLabel.textColor = Style.textColor
        descriptionLabel.text = Strings.featureDescription

        noteTextView.layer.borderWidth = Style.borderWidth
        noteTextView.layer.cornerRadius = Style.noteCornerRadius
        noteTextView.layer.borderColor = Style.borderColor
        noteTextView.textContainerInset = Style.noteInsets
        configureNoteText()
    }

    func configureNoteText() {
        let attributedString = NSMutableAttributedString()

        // These attributed string styles cannot be stored statically (i.e. in the Style enum).
        // They must be dynamic to resize correctly when the text size changes.

        attributedString.append(.init(string: Strings.noteLabel,
                                      attributes: [.foregroundColor: Style.textColor,
                                                   .font: UIFont.preferredFont(forTextStyle: .caption1).bold()]))

        attributedString.append(.init(string: " " + Strings.noteText,
                                      attributes: [.foregroundColor: Style.textColor,
                                                   .font: UIFont.preferredFont(forTextStyle: .caption1)]))

        noteTextView.attributedText = attributedString
    }

    enum Strings {
        static let featureDescription: String = NSLocalizedString("We’ll show you a new prompt each day on your dashboard to help get those creative juices flowing!", comment: "Description of Blogging Prompts displayed in the Feature Introduction view.")
        static let noteLabel: String = NSLocalizedString("Note:", comment: "Label for the note displayed in the Feature Introduction view.")
        static let noteText: String = NSLocalizedString("You can learn more and set up reminders at any time in My Site > Settings > Blogging Reminders.", comment: "Note displayed in the Feature Introduction view.")
    }

    enum Style {
        static let labelFont = WPStyleGuide.fontForTextStyle(.body)
        static let textColor: UIColor = .textSubtle
        static let noteInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        static let noteCornerRadius: CGFloat = 6
        static let cardCornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 1
        static let borderColor = UIColor.textQuaternary.cgColor
    }
}
