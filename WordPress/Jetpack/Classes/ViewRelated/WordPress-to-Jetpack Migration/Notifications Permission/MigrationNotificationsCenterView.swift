import UIKit

class MigrationNotificationsCenterView: UIView {

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        label.attributedText = Appearance.highlightString(Appearance.highlightedWord, inString: Appearance.description)
        label.textColor = .muriel(color: .gray, .shade50)
        label.numberOfLines = 0
        return label
    }()

    private lazy var fakeAlertImageView: UIImageView = {
        let imageView = UIImageView(image: Appearance.fakeAlertImage(for: traitCollection.layoutDirection))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return imageView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [fakeAlertImageView, descriptionLabel, makeSpacer()])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.setCustomSpacing(Appearance.fakeAlertToDescriptionSpacing, after: fakeAlertImageView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private func makeSpacer() -> UIView {
        let spacer = UIView()
        return spacer
    }

    init() {
        super.init(frame: .zero)
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection.layoutDirection != previousTraitCollection?.layoutDirection else {
            return
        }
        // probably an edge case, but if users change language direction, then update the fake alert
        fakeAlertImageView.image = Appearance.fakeAlertImage(for: traitCollection.layoutDirection)
    }

    private enum Appearance {

        static func fakeAlertImage(for textDirection: UITraitEnvironmentLayoutDirection) -> UIImage? {
            let imageName = textDirection == .rightToLeft ? "wp-migration-fake-alert-rtl" : "wp-migration-fake-alert-ltr"
            return UIImage(named: imageName)
        }

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

            attributedString.addAttributes([.font: WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .bold)],
                                           range: subStringRange)
            return attributedString
        }

        static let fakeAlertToDescriptionSpacing: CGFloat = 20
    }
}
