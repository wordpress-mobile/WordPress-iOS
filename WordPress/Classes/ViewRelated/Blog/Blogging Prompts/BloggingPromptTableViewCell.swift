class BloggingPromptTableViewCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var dateToAnswersSeparatorDot: UILabel!
    @IBOutlet private weak var answerCountLabel: UILabel!

    @IBOutlet private weak var answeredStateView: UIView!
    @IBOutlet private weak var answersToStateSeparatorDot: UILabel!
    @IBOutlet private weak var answeredStateLabel: UILabel!

    private var prompt: BloggingPrompt?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return formatter
    }()


    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

    // TODO: remove answered param. Add BloggingPrompt, configure with its properties.
    func configure(answered: Bool) {
        titleLabel.text = "Cast the movie of your life."
        dateLabel.text = dateFormatter.string(from: Date())
        answerCountLabel.text = answerInfoText
        answeredStateView.isHidden = !answered
    }
}

private extension BloggingPromptTableViewCell {

    func configureView() {
        titleLabel.textColor = .text
        titleLabel.font = WPStyleGuide.notoBoldFontForTextStyle(.headline)

        dateLabel.textColor = .text
        dateToAnswersSeparatorDot.textColor = .text
        answerCountLabel.textColor = .text
        answersToStateSeparatorDot.textColor = .text

        answeredStateLabel.text = Strings.answeredLabel
        answeredStateLabel.textColor = WPStyleGuide.BloggingPrompts.answeredLabelColor
    }

    var answerInfoText: String {
        // TODO: remove when we have a prompt.
        guard let answerCount = prompt?.answerCount else {
            return "99 answers"
        }

        let stringFormat = (answerCount == 1 ? Strings.answerInfoSingularFormat : Strings.answerInfoPluralFormat)
        return String(format: stringFormat, answerCount)
    }

    enum Strings {
        static let answeredLabel = NSLocalizedString("✓ Answered", comment: "Label that indicates a blogging prompt has been answered.")
        static let answerInfoSingularFormat = NSLocalizedString("%1$d answer", comment: "Singular format string for displaying the number of users that answered the blogging prompt.")
        static let answerInfoPluralFormat = NSLocalizedString("%1$d answers", comment: "Plural format string for displaying the number of users that answered the blogging prompt.")
    }
}
