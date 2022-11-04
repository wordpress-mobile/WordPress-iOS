import UIKit

final class MigrationHeaderView: UIView {

    // MARK: - Views

    let imageView = UIImageView()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.titleFont
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    let primaryDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.primaryDescriptionFont
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    let secondaryDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.secondaryDescriptionFont
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

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

    private func setup() {
        // Set subviews
        let labelsStackView = Self.verticalStackView(arrangedSubviews: [titleLabel, primaryDescriptionLabel, secondaryDescriptionLabel])
        labelsStackView.spacing = Constants.labelsSpacing
        let mainStackView = Self.verticalStackView(arrangedSubviews: [imageView, labelsStackView])
        mainStackView.spacing = Constants.spacing
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(mainStackView)

        // Set constraints
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    // MARK: - Views Factory

    private static func verticalStackView(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        return stackView
    }

    // MARK: - Types

    private struct Constants {
        /// Spacing of the top most stack view
        static let spacing: CGFloat = 30

        /// Spacing of the labels stack view
        static let labelsSpacing: CGFloat = 20

        static let titleFont: UIFont = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .bold)
        static let primaryDescriptionFont: UIFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .regular)
        static let secondaryDescriptionFont: UIFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
    }
}
