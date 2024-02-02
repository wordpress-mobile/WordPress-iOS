class BloggingPromptTableViewCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var dateToAnswersSeparatorDot: UILabel!
    @IBOutlet private weak var answerCountLabel: UILabel!

    @IBOutlet private weak var answeredStateView: UIView!
    @IBOutlet private weak var answersToStateSeparatorDot: UILabel!
    @IBOutlet private weak var answeredStateLabel: UILabel!

    private(set) var prompt: BloggingPrompt?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return formatter
    }()

    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

    func configure(_ prompt: BloggingPrompt) {
        self.prompt = prompt
        titleLabel.text = prompt.textForDisplay()
        dateLabel.text = dateFormatter.string(from: prompt.date)
        answerCountLabel.text = answerInfoText
        answeredStateView.isHidden = !prompt.answered
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
        let answerCount = prompt?.answerCount ?? 0
        let stringFormat = (answerCount == 1 ? Strings.answerInfoSingularFormat : Strings.answerInfoPluralFormat)
        return String(format: stringFormat, answerCount)
    }

    enum Strings {
        static let answeredLabel = NSLocalizedString("✓ Answered", comment: "Label that indicates a blogging prompt has been answered.")
        static let answerInfoSingularFormat = NSLocalizedString("%1$d answer", comment: "Singular format string for displaying the number of users that answered the blogging prompt.")
        static let answerInfoPluralFormat = NSLocalizedString("%1$d answers", comment: "Plural format string for displaying the number of users that answered the blogging prompt.")
    }
}
