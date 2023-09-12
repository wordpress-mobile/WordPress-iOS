import UIKit

@objc
class MigrationSuccessCardView: UIView {

    private var onTap: (() -> Void)?

    private var iconImage: UIImage? {
        traitCollection.layoutDirection == .leftToRight
            ? UIImage(named: Appearance.iconImageNameLtr)
            : UIImage(named: Appearance.iconImageNameRtl)
    }

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: iconImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = Appearance.descriptionText
        label.font = Appearance.descriptionFont
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var learnMoreLabel: UILabel = {
        let label = UILabel()
        label.text = Appearance.learnMoreText
        label.font = Appearance.learnMoreFont
        label.textColor = Appearance.learnMoreTextColor
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [descriptionLabel, learnMoreLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        return stackView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [iconImageView, labelStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = 16
        return stackView
    }()

    @objc
    private func viewTapped() {
        onTap?()
    }

    init(onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        super.init(frame: .zero)
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView, insets: UIEdgeInsets(allEdges: 16))
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            iconImageView.widthAnchor.constraint(equalToConstant: 56)
        ])
        backgroundColor = .listForeground
        layer.cornerRadius = 10
        clipsToBounds = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Appearance {
        static var iconImageNameLtr = "wp-migration-success-card-icon-ltr"
        static var iconImageNameRtl = "wp-migration-success-card-icon-rtl"
        static let descriptionText = NSLocalizedString("wp.migration.successCard.description",
                                                       value: "Welcome to the Jetpack app. You can uninstall the WordPress app.",
                                                       comment: "Description of the jetpack migration success card, used in My site.")
        static let descriptionFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        static let learnMoreText = NSLocalizedString("wp.migration.successCard.learnMore",
                                                     value: "Learn more",
                                                     comment: "Title of a button that displays a blog post in a web view.")
        static let learnMoreFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        static let learnMoreTextColor = UIColor.muriel(color: .jetpackGreen, .shade40)
    }
}

// Ideally, this logic should be handled elsewhere. But since the whole migration feature is temporary
// Perhaps that's not worth the trouble.
//
// TODO: Remove `shouldShowMigrationSuccessCard` when the migration feature is no longer needed
extension MigrationSuccessCardView {

    private static var cachedShouldShowMigrationSuccessCard = false

    @objc static var shouldShowMigrationSuccessCard: Bool {
        guard AppConfiguration.isJetpack else {
            return false
        }

        let isWordPressInstalled = MigrationAppDetection.getWordPressInstallationState().isWordPressInstalled
        let isMigrationCompleted = UserPersistentStoreFactory.instance().jetpackContentMigrationState == .completed
        let newValue = isWordPressInstalled && isMigrationCompleted

        if newValue != Self.cachedShouldShowMigrationSuccessCard {
            let tracker = MigrationAnalyticsTracker()
            let event: MigrationEvent = newValue ? .pleaseDeleteWordPressCardShown : .pleaseDeleteWordPressCardHidden
            tracker.track(event)
            Self.cachedShouldShowMigrationSuccessCard = newValue
        }

        return newValue
    }
}
