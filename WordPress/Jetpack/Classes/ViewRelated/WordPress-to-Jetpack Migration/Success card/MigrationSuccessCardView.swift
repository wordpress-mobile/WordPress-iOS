import UIKit

@objc
class MigrationSuccessCardView: UIView {

    private var onTap: (() -> Void)?

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: Appearance.iconImageName))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 8
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var iconView: UIView = {
        let view = UIView()
        view.addSubview(iconImageView)
        return view
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = Appearance.descriptionText
        label.font = Appearance.descriptionFont
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [iconView, descriptionLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
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
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconView.widthAnchor.constraint(equalTo: iconImageView.widthAnchor)
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
        static let iconImageName = "wp-migration-success-card-icon"
        static let descriptionText = NSLocalizedString("wp.migration.successcard.description",
                                                       value: "Please delete the WordPress app",
                                                       comment: "Description of the jetpack migration success card, used in My site.")
        static let descriptionFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
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

        let isFeatureFlagEnabled = FeatureFlag.contentMigration.enabled
        let isWordPressInstalled = MigrationAppDetection.getWordPressInstallationState().isWordPressInstalled
        let isMigrationCompleted = UserPersistentStoreFactory.instance().isJPMigrationFlowComplete
        let newValue = isFeatureFlagEnabled && isWordPressInstalled && isMigrationCompleted

        if newValue != Self.cachedShouldShowMigrationSuccessCard {
            let tracker = MigrationAnalyticsTracker()
            let event: MigrationEvent = newValue ? .pleaseDeleteWordPressCardShown : .pleaseDeleteWordPressCardHidden
            tracker.track(event)
            Self.cachedShouldShowMigrationSuccessCard = newValue
        }

        return newValue
    }
}
