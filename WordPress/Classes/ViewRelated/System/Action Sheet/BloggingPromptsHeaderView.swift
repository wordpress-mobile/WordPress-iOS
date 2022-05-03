import UIKit

class BloggingPromptsHeaderView: UIView, NibLoadable {
    @IBOutlet private weak var containerStackView: UIStackView!
    @IBOutlet private weak var titleStackView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var promptLabel: UILabel!
    @IBOutlet private weak var answerPromptButton: UIButton!
    @IBOutlet private weak var answeredStackView: UIStackView!
    @IBOutlet private weak var answeredLabel: UILabel!
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var dividerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

    @IBAction private func answerPromptTapped(_ sender: Any) {
        // TODO
    }

    @IBAction private func shareTapped(_ sender: Any) {
        // TODO
    }
}

// MARK: - Private methods

private extension BloggingPromptsHeaderView {

    func configureView() {
        // TODO: Hide correct UI based on if prompt is answered
        answerPromptButton.isHidden = true
        configureSpacing()
        configureStrings()
        configureStyles()
        configureConstraints()
    }

    func configureSpacing() {
        containerStackView.setCustomSpacing(Constants.titleSpacing, after: titleStackView)
        containerStackView.setCustomSpacing(Constants.answeredViewSpacing, after: answeredStackView)
        containerStackView.setCustomSpacing(Constants.answerPromptButtonSpacing, after: answerPromptButton)
    }

    func configureStrings() {
        titleLabel.text = Strings.title
        // TODO: Use prompt from backend
        promptLabel.text = Strings.examplePrompt
        answerPromptButton.titleLabel?.text = Strings.answerButtonTitle
        answeredLabel.text = Strings.answeredLabelTitle
        shareButton.titleLabel?.text = Strings.shareButtonTitle
    }

    func configureStyles() {
        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        promptLabel.font = WPStyleGuide.BloggingPrompts.promptContentFont
        answerPromptButton.titleLabel?.font = WPStyleGuide.BloggingPrompts.buttonTitleFont
        answerPromptButton.titleLabel?.adjustsFontForContentSizeCategory = true
        answerPromptButton.setTitleColor(WPStyleGuide.BloggingPrompts.buttonTitleColor, for: .normal)
        answeredLabel.font = WPStyleGuide.BloggingPrompts.buttonTitleFont
        answeredLabel.textColor = WPStyleGuide.BloggingPrompts.answeredLabelColor
        shareButton.titleLabel?.font = WPStyleGuide.BloggingPrompts.buttonTitleFont
        shareButton.titleLabel?.adjustsFontForContentSizeCategory = true
        shareButton.titleLabel?.adjustsFontSizeToFitWidth = true
        shareButton.setTitleColor(WPStyleGuide.BloggingPrompts.buttonTitleColor, for: .normal)
    }

    func configureConstraints() {
        NSLayoutConstraint.activate([
            dividerView.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth),
        ])
    }

    // MARK: - Constants

    struct Constants {
        static let titleSpacing: CGFloat = 8.0
        static let answeredViewSpacing: CGFloat = 9.0
        static let answerPromptButtonSpacing: CGFloat = 9.0
    }

    struct Strings {
        static let examplePrompt = NSLocalizedString("Cast the movie of your life.", comment: "Example prompt for blogging prompts in the create new bottom action sheet.")
        static let title = NSLocalizedString("Prompts", comment: "Title label for blogging prompts in the create new bottom action sheet.")
        static let answerButtonTitle = NSLocalizedString("Answer Prompt", comment: "Title for a call-to-action button in the create new bottom action sheet.")
        static let answeredLabelTitle = NSLocalizedString("✓ Answered", comment: "Title label that indicates the prompt has been answered.")
        static let shareButtonTitle = NSLocalizedString("Share", comment: "Title for a button that allows the user to share their answer to the prompt.")
    }

}
