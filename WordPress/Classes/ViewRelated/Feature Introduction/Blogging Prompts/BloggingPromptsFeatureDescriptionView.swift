import UIKit

class BloggingPromptsFeatureDescriptionView: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet private weak var promptCardView: UIView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var noteTextView: UITextView!
    @IBOutlet private weak var noteAccessibilityLabel: UILabel!

    // MARK: - Init

    open override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

}

private extension BloggingPromptsFeatureDescriptionView {

    func configureView() {
        configurePromptCard()
        configureDescription()
        configureNote()
    }

    func configurePromptCard() {
        let promptCard = DashboardPromptsCardCell()
        promptCard.configureForExampleDisplay()

        // The DashboardPromptsCardCell doesn't resize dynamically when used in this context.
        // So use its cardFrameView instead.
        promptCard.cardFrameView.translatesAutoresizingMaskIntoConstraints = false
        promptCard.cardFrameView.layer.cornerRadius = Style.cardCornerRadius
        promptCard.cardFrameView.layer.shadowOffset = Style.cardShadowOffset
        promptCard.cardFrameView.layer.shadowOpacity = Style.cardShadowOpacity
        promptCard.cardFrameView.layer.shadowRadius = Style.cardShadowRadius

        promptCardView.accessibilityElementsHidden = true
        promptCardView.addSubview(promptCard.cardFrameView)
        promptCardView.pinSubviewToAllEdges(promptCard.cardFrameView)
    }

    func configureDescription() {
        descriptionLabel.font = Style.labelFont
        descriptionLabel.textColor = Style.textColor
        descriptionLabel.text = Strings.featureDescription
    }

    func configureNote() {
        noteTextView.layer.borderWidth = Style.noteBorderWidth
        noteTextView.layer.cornerRadius = Style.noteCornerRadius
        noteTextView.layer.borderColor = Style.noteBorderColor
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

        noteTextView.accessibilityElementsHidden = true
        noteAccessibilityLabel.accessibilityLabel = Strings.noteTextAccessibilityLabel
    }

    enum Strings {
        static let featureDescription: String = NSLocalizedString("We’ll show you a new prompt each day on your dashboard to help get those creative juices flowing!", comment: "Description of Blogging Prompts displayed in the Feature Introduction view.")
        static let noteLabel: String = NSLocalizedString("Note:", comment: "Label for the note displayed in the Feature Introduction view.")
        static let noteText: String = NSLocalizedString("You can learn more and set up reminders at any time in My Site > Settings > Blogging Reminders.", comment: "Note displayed in the Feature Introduction view.")
        static let noteTextAccessibilityLabel: String = NSLocalizedString("You can learn more and set up reminders at any time in My Site, Settings, Blogging Reminders.", comment: "Accessibility hint for Note displayed in the Feature Introduction view.")
    }

    enum Style {
        static let labelFont = WPStyleGuide.fontForTextStyle(.body)
        static let textColor: UIColor = .textSubtle
        static let noteInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        static let noteCornerRadius: CGFloat = 6
        static let noteBorderWidth: CGFloat = 1
        static let noteBorderColor = UIColor.textQuaternary.cgColor
        static let cardCornerRadius: CGFloat = 10
        static let cardShadowRadius: CGFloat = 14
        static let cardShadowOpacity: Float = 0.1
        static let cardShadowOffset = CGSize(width: 0, height: 10.0)
    }
}
