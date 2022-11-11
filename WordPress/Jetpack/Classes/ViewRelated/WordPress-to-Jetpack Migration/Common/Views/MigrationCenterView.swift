import UIKit

/// A view with an injected content and a description withl highlighted words
class MigrationCenterView: UIView {

    private let contentView: UIView

    private let descriptionText: String

    private let highlightedDescriptionText: String

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        label.attributedText = Appearance.highlightString(highlightedDescriptionText, inString: descriptionText)
        label.textColor = Appearance.descriptionTextColor
        label.numberOfLines = 0
        return label
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [contentView, descriptionLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.setCustomSpacing(Appearance.fakeAlertToDescriptionSpacing, after: contentView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init(contentView: UIView, descriptionText: String, highlightedDescriptionText: String) {
        self.contentView = contentView
        self.descriptionText = descriptionText
        self.highlightedDescriptionText = highlightedDescriptionText
        super.init(frame: .zero)
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Appearance {

        static func highlightString(_ subString: String, inString: String) -> NSAttributedString {
            let attributedString = NSMutableAttributedString(string: inString)

            guard let subStringRange = inString.nsRange(of: subString) else {
                return attributedString
            }

            attributedString.addAttributes([.font: WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .bold)],
                                           range: subStringRange)
            return attributedString
        }

        static let fakeAlertToDescriptionSpacing: CGFloat = 20

        static let descriptionTextColor = UIColor(light: .muriel(color: .gray, .shade50), dark: .muriel(color: .gray, .shade10))
    }
}
