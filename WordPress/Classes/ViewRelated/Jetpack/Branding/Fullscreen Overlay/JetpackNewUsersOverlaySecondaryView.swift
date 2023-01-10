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
        let icon = UIImage(named: Constants.statsIcon)
        let view = FeatureDetailsView(image: icon, title: Strings.statsTitle, subtitle: Strings.statsSubtitle)
        view.heightAnchor.constraint(equalToConstant: Metrics.rowHeight).isActive = true
        return view
    }()

    private lazy var readerDetails: FeatureDetailsView = {
        let icon = UIImage(named: Constants.readerIcon)
        let view = FeatureDetailsView(image: icon, title: Strings.readerTitle, subtitle: Strings.readerSubtitle)
        view.heightAnchor.constraint(equalToConstant: Metrics.rowHeight).isActive = true
        return view
    }()

    private lazy var notificationsDetails: FeatureDetailsView = {
        let icon = UIImage(named: Constants.notificationsIcon)
        let view = FeatureDetailsView(image: icon, title: Strings.notificationsTitle, subtitle: Strings.notificationsSubtitle)
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

    enum Constants {
        static let statsIcon = "jp-stats-icon"
        static let readerIcon = "jp-reader-icon"
        static let notificationsIcon = "jp-notif-icon"
    }

    enum Strings {
        static let statsTitle = NSLocalizedString("jetpack.fullscreen.overlay.newUsers.stats.title",
                                                  value: "Stats & Insights",
                                                  comment: "Name of the Statistics feature.")
        static let readerTitle = NSLocalizedString("Reader",
                                                   comment: "Name of the Reader feature.")
        static let notificationsTitle = NSLocalizedString("Notifications",
                                                          comment: "Name of the Notifications feature.")
        static let statsSubtitle = NSLocalizedString("jetpack.fullscreen.overlay.newUsers.stats.subtitle",
                                                  value: "Watch your traffic grow with helpful insights and comprehensive stats.",
                                                  comment: "Description of the Statistics feature.")
        static let readerSubtitle = NSLocalizedString("jetpack.fullscreen.overlay.newUsers.stats.subtitle",
                                                      value: "Find and follow your favorite sites and communities, and share you content.",
                                                      comment: "Description of the Reader feature.")
        static let notificationsSubtitle = NSLocalizedString("jetpack.fullscreen.overlay.newUsers.stats.subtitle",
                                                             value: "Get notifications for new comments, likes, views, and more.",
                                                             comment: "Description of the Notifications feature.")
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
            label.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
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

        init(image: UIImage?, title: String, subtitle: String) {
            super.init(frame: .zero)
            configureView(image: image, title: title, subtitle: subtitle)
        }

        required init?(coder: NSCoder) {
            fatalError("Storyboard instantiation not supported.")
        }

        // MARK: Helpers

        private func configureView(image: UIImage?, title: String, subtitle: String) {
            setupContent(image: image, title: title, subtitle: subtitle)
            setupConstraints()
        }

        private func setupContent(image: UIImage?, title: String, subtitle: String) {
            iconImageView.image = image
            titleLabel.text = title
            subtitleLabel.text = subtitle
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
