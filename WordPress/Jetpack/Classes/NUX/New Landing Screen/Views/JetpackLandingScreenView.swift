import UIKit

final class JetpackLandingScreenView: UIView {

    private let prompts = JetpackPromptsConfiguration.Constants.basePrompts
    private let evenColor = JetpackPromptsConfiguration.Constants.evenColor
    private let oddColor = JetpackPromptsConfiguration.Constants.oddColor
    private let lineSpacing: CGFloat = -6
    private let interitemSpacing: CGFloat = -2
    private let font: UIFont = UIFont.systemFont(ofSize: 40, weight: .bold)
    private let insets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

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

    private func setup() {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = self.interitemSpacing
        for index in 0..<prompts.count * 2 {
            let view = self.promptView(
                text: prompts[index % prompts.count],
                color: index % 2 == 0 ? evenColor : oddColor
            )
            stackView.addArrangedSubview(view)
        }
        self.addSubview(stackView)
        self.pinSubviewToAllEdges(stackView, insets: insets)
    }

    private func promptView(text: String, color: UIColor) -> UIView {
        let textView = UITextView()
        textView.accessibilityElementsHidden = true
        textView.isSelectable = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.backgroundColor = .clear

        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color,
            .font: font
        ]
        attributedString.addAttributes(attributes, range: NSMakeRange(0, text.count))
        textView.attributedText = attributedString

        return textView
    }
}
