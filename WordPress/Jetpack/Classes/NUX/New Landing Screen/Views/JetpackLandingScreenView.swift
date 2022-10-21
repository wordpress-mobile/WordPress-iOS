import UIKit

final class JetpackLandingScreenView: UIView {

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        let prompts = Constants.prompts
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = Constants.interitemSpacing
        for index in 0..<prompts.count * 2 {
            let view = Self.promptView(
                text: prompts[index % prompts.count],
                color: index % 2 == 0 ? Constants.evenColor : Constants.oddColor
            )
            stackView.addArrangedSubview(view)
        }
        self.addSubview(stackView)
        self.pinSubviewToAllEdges(stackView, insets: Constants.insets)
    }

    // MARK: - Subviews Factory

    private static func promptView(text: String, color: UIColor) -> UIView {
        let textView = UITextView()
        textView.accessibilityElementsHidden = true
        textView.isSelectable = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear

        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Constants.lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color,
            .font: Constants.font
        ]
        attributedString.addAttributes(attributes, range: NSMakeRange(0, text.count))
        textView.attributedText = attributedString

        return textView
    }

    // MARK: - Constants

    private struct Constants {
        static let prompts = JetpackPromptsConfiguration.Constants.basePrompts
        static let evenColor = JetpackPromptsConfiguration.Constants.evenColor
        static let oddColor = JetpackPromptsConfiguration.Constants.oddColor
        static let lineSpacing: CGFloat = -6
        static let interitemSpacing: CGFloat = -2
        static let font: UIFont = UIFont.systemFont(ofSize: 40, weight: .bold)
        static let insets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}
