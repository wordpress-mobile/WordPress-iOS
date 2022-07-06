import UIKit

class StatsRevampV2FeatureDescriptionView: UIView, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var noteAccessibilityLabel: UILabel!

    // MARK: - Init

    open override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }
}

private extension StatsRevampV2FeatureDescriptionView {

    func configureView() {
        configureCard()
        configureDescription()
        configureNote()
    }

    func configureCard() {
        cardImageView.layer.cornerRadius = Style.cardCornerRadius
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
        noteTextView.font = UIFont.preferredFont(forTextStyle: .caption1)
        noteTextView.textColor = Style.textColor
        noteTextView.text = Strings.noteText
    }

    enum Strings {
        static let featureDescription: String = NSLocalizedString("Insights help you understand how your content is performing and what’s resonating with your audience.", comment: "Description of updated Stats Insights displayed in the Feature Introduction view.")
        static let noteText: String = NSLocalizedString("Learn more in My Site > Stats > Insights.", comment: "Note displayed in the Feature Introduction view for the updated Stats Insights feature.")
    }

    enum Style {
        static let labelFont = WPStyleGuide.fontForTextStyle(.body)
        static let textColor: UIColor = .textSubtle
        static let noteInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        static let noteCornerRadius: CGFloat = 6
        static let noteBorderWidth: CGFloat = 1
        static let noteBorderColor = UIColor.textQuaternary.cgColor
        static let cardCornerRadius: CGFloat = 10
    }
}
