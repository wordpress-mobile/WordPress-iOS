import UIKit

class MigrationNotificationsCenterView: UIView {

    private lazy var spacer: UIView = {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .vertical)
        return spacer
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        label.attributedText = Appearance.highlightString(Appearance.highlightedWord, inString: Appearance.description)
        label.textColor = .muriel(color: .gray, .shade50)
        label.numberOfLines = 0
        return label
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [spacer, descriptionLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init() {
        super.init(frame: .zero)
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Appearance {

        static let description = NSLocalizedString("migration.notifications.footer",
                                                   value: "When the alert apears tap Allow to continue receiving all your WordPress notifications.",
                                                   comment: "Footer for the migration notifications screen.")
        static let highlightedWord = NSLocalizedString("migration.notifications.footer.allow",
                                                       value: "Allow",
                                                       comment: "Allow keyword in the footer of the migration notifications screen.")

        static func highlightString(_ subString: String, inString: String) -> NSAttributedString {
            let attributedString = NSMutableAttributedString(string: inString)

            guard let subStringRange = inString.nsRange(of: subString) else {
                return attributedString
            }

            attributedString.addAttributes([.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .bold)],
                                           range: subStringRange)
            return attributedString
        }
    }
}
