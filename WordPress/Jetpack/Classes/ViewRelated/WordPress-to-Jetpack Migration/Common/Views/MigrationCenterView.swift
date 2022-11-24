import UIKit

/// A view with an injected content and a description withl highlighted words
class MigrationCenterView: UIView {

    private let contentView: UIView

    private let configuration: MigrationCenterViewConfiguration?

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        if let configuration {
            label.attributedText = configuration.attributedText
        }
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

    private enum Appearance {

        static let fakeAlertToDescriptionSpacing: CGFloat = 20

        static let descriptionTextColor = UIColor(light: .muriel(color: .gray, .shade50), dark: .muriel(color: .gray, .shade10))
    }
}
