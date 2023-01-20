import UIKit

/// A view with an injected content and a description withl highlighted words
class MigrationCenterView: UIView {

    private let configuration: MigrationCenterViewConfiguration?

    // MARK: - Views

    private let contentView: UIView

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        if let configuration {
            label.attributedText = configuration.attributedText
        }
        label.textAlignment = .center
        label.textColor = Appearance.descriptionTextColor
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
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

    // MARK: - Init

    init(contentView: UIView, configuration: MigrationCenterViewConfiguration?) {
        self.contentView = contentView
        self.configuration = configuration
        super.init(frame: .zero)
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func deleteWordPress(with configuration: MigrationCenterViewConfiguration?) -> MigrationCenterView {
        let imageView = UIImageView(image: UIImage(named: "wp-migration-icon-with-badge"))
        imageView.contentMode = .scaleAspectFit
        return .init(contentView: imageView, configuration: configuration)
    }

    // MARK: - Types

    private enum Appearance {
        static let fakeAlertToDescriptionSpacing: CGFloat = 20
        static let descriptionTextColor = UIColor(light: .muriel(color: .gray, .shade50), dark: .muriel(color: .gray, .shade10))
    }
}
