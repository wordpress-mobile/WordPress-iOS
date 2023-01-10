import UIKit

class JetpackNewUsersOverlaySecondaryView: UIView {

    // MARK: Lazy Loading View

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.stackViewSpacing
        stackView.directionalLayoutMargins = Metrics.stackViewLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubviews(featureRows)
        return stackView
    }()

    private lazy var featureRows: [FeatureDetailsView] = {
        return [statsDetails, readerDetails, notificationsDetails]
    }()

    private lazy var statsDetails: FeatureDetailsView = {
        let view = FeatureDetailsView()
        view.heightAnchor.constraint(equalToConstant: Metrics.rowHeight).isActive = true
        return view
    }()

    private lazy var readerDetails: FeatureDetailsView = {
        let view = FeatureDetailsView()
        view.heightAnchor.constraint(equalToConstant: Metrics.rowHeight).isActive = true
        return view
    }()

    private lazy var notificationsDetails: FeatureDetailsView = {
        let view = FeatureDetailsView()
        view.heightAnchor.constraint(equalToConstant: Metrics.rowHeight).isActive = true
        return view
    }()

    // MARK: Initializers

    init() {
        super.init(frame: .zero)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard instantiation not supported.")
    }

    // MARK: Helpers

    private func configureView() {
        addSubview(containerStackView)
        pinSubviewToAllEdges(containerStackView)
    }
}

private extension JetpackNewUsersOverlaySecondaryView {
    enum Metrics {
        static let stackViewSpacing: CGFloat = 30
        static let stackViewLayoutMargins: NSDirectionalEdgeInsets = .init(top: 30, leading: 0, bottom: 0, trailing: 0)
        static let rowHeight: CGFloat = 60
        static let iconImageViewSize: CGFloat = 30
        static let labelsAndIconSpacing: CGFloat = 14
    }

    enum Strings {

    }
}

private extension JetpackNewUsersOverlaySecondaryView {
    class FeatureDetailsView: UIView {

        // MARK: Lazy Loading View

        private lazy var iconImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.heightAnchor.constraint(equalToConstant: Metrics.iconImageViewSize).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: Metrics.iconImageViewSize).isActive = true
            addSubview(imageView)
            return imageView
        }()

        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .bold)
            label.textColor = .label
            label.numberOfLines = 1
            label.adjustsFontForContentSizeCategory = true
            addSubview(label)
            return label
        }()

        private lazy var subtitleLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
            label.textColor = .secondaryLabel
            label.numberOfLines = 2
            label.adjustsFontForContentSizeCategory = true
            addSubview(label)
            return label
        }()

        // MARK: Initializers

        init() {
            super.init(frame: .zero)
            configureView()
        }

        required init?(coder: NSCoder) {
            fatalError("Storyboard instantiation not supported.")
        }

        // MARK: Helpers

        private func configureView() {
            setupContent()
            setupConstraints()
        }

        private func setupContent() {
            iconImageView.image = UIImage(named: "icon-jetpack")
            titleLabel.text = "Lorum Ipsum"
            subtitleLabel.text = "Lorum Ipsum Lorum Ipsum Lorum Ipsum Lorum Ipsum Lorum Ipsum"
        }

        private func setupConstraints() {
            // Icon Image View
            iconImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true

            // Title Label
            titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor,
                                                constant: Metrics.labelsAndIconSpacing).isActive = true
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

            // Subtitle Label
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
            subtitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor,
                                                constant: Metrics.labelsAndIconSpacing).isActive = true
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }
    }
}
