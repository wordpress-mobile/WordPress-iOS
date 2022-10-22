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
        let label = UILabel()
        label.accessibilityElementsHidden = true
        label.numberOfLines = 0

        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = Constants.lineHeightMultiple
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color,
            .font: Constants.font
        ]
        attributedString.addAttributes(attributes, range: NSMakeRange(0, text.utf16.count))
        label.attributedText = attributedString

        return label
    }

    // MARK: - Constants

    private struct Constants {
        static let prompts = JetpackPromptsConfiguration.Constants.basePrompts
        static let evenColor = JetpackPromptsConfiguration.Constants.evenColor
        static let oddColor = JetpackPromptsConfiguration.Constants.oddColor
        static let lineHeightMultiple: CGFloat = 0.8
        static let interitemSpacing: CGFloat = 8
        static let font: UIFont = UIFont.systemFont(ofSize: 40, weight: .bold)
        static let insets = UIEdgeInsets(top: Self.interitemSpacing, left: 16, bottom: 0, right: 16)
    }
}
