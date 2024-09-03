import UIKit

final class MigrationHeaderView: UIView {

    // MARK: - Views

    let imageView = UIImageView()

    private let configuration: MigrationHeaderConfiguration

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
        label.textColor = Constants.secondaryTextColor
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    // MARK: - Init

    init(configuration: MigrationHeaderConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        // Set subviews
        let labelsStackView = verticalStackView(arrangedSubviews: [titleLabel, primaryDescriptionLabel, secondaryDescriptionLabel])
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.spacing = Constants.labelsSpacing
        let mainStackView = verticalStackView(arrangedSubviews: [imageView, labelsStackView])
        mainStackView.setCustomSpacing(Constants.spacing, after: imageView)
        mainStackView.alignment = .leading
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(mainStackView)
        NSLayoutConstraint.activate([
            labelsStackView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor),
            mainStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
        configureAppearance()
    }

    // MARK: - Views Factory

    private func verticalStackView(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        return stackView
    }

    private func configureAppearance() {
        // Set image and labels
        imageView.image = configuration.image
        titleLabel.text = configuration.title
        primaryDescriptionLabel.text = configuration.primaryDescription
        secondaryDescriptionLabel.text = configuration.secondaryDescription

        // Hide image and labels if they're empty
        imageView.isHidden = imageView.image == nil
        [titleLabel, primaryDescriptionLabel, secondaryDescriptionLabel].forEach { label in
            label.isHidden = label.text?.isEmpty ?? true
        }
    }

    // MARK: - Types

    private struct Constants {
        /// Spacing of the top most stack view
        static let spacing: CGFloat = 30

        /// Spacing of the labels stack view
        static let labelsSpacing: CGFloat = 20

        static let titleFont: UIFont = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .bold)
        static let primaryDescriptionFont: UIFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let secondaryDescriptionFont: UIFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let secondaryTextColor = UIColor(light: AppStyleGuide.gray(.shade50), dark: AppStyleGuide.gray(.shade10))
    }
}
