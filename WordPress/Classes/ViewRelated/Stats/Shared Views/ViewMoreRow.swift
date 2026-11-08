import UIKit
import WordPressShared

protocol ViewMoreRowDelegate: AnyObject {
    func viewMoreSelectedForStatSection(_ statSection: StatSection)
}

class ViewMoreRow: UIView, Accessible {

    // MARK: - Properties

    let viewMoreLabel = UILabel.makeStatsLabel(text: "View more", textStyle: .body, textAlignment: .left)

    let disclosureImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.forward"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return imageView
    }()

    private var statSection: StatSection?
    private weak var delegate: ViewMoreRowDelegate?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        applyStatsXibRootDefaults(size: CGSize(width: 375, height: 44))

        backgroundColor = .white

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        contentView.addSubview(viewMoreLabel)
        contentView.addSubview(disclosureImageView)

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(didTapViewMoreButton), for: .touchUpInside)

        addSubview(contentView)
        addSubview(button)

        let labelTopConstraint = viewMoreLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12)
        labelTopConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            labelTopConstraint,
            viewMoreLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: viewMoreLabel.bottomAnchor, constant: 12),

            disclosureImageView.leadingAnchor.constraint(equalTo: viewMoreLabel.trailingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: disclosureImageView.trailingAnchor, constant: 16),
            disclosureImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            disclosureImageView.widthAnchor.constraint(equalToConstant: 9),
            disclosureImageView.heightAnchor.constraint(equalToConstant: 15),

            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(statSection: StatSection?, delegate: ViewMoreRowDelegate?) {
        self.statSection = statSection
        self.delegate = delegate
        applyStyles()
        prepareForVoiceOver()
    }

    func prepareForVoiceOver() {
        isAccessibilityElement = true

        accessibilityLabel = viewMoreLabel.text
        accessibilityHint = NSLocalizedString(
            "Tap to view more details.",
            comment: "Accessibility hint for a button that opens a new view with more details."
        )
        accessibilityTraits = .button
    }
}

// MARK: - Private Methods

private extension ViewMoreRow {

    func applyStyles() {
        backgroundColor = .secondarySystemGroupedBackground
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more stats.")
        viewMoreLabel.textColor = WPStyleGuide.Stats.actionTextColor
        viewMoreLabel.maximumContentSizeCategory = .extraExtraExtraLarge
        if statSection == .insightsFollowersWordPress || statSection == .insightsFollowersEmail
            || statSection == .subscribersList || statSection == .subscribersEmailsSummary
        {
            disclosureImageView.isHidden = true
        }
    }

    @objc func didTapViewMoreButton(_ sender: UIButton) {
        guard let statSection else {
            return
        }

        captureAnalyticsEventsFor(statSection)
        delegate?.viewMoreSelectedForStatSection(statSection)
    }

    func captureAnalyticsEventsFor(_ statSection: StatSection) {
        let legacyEvent: WPAnalyticsStat = .statsViewAllAccessed
        captureAnalyticsEvent(legacyEvent)

        if let modernEvent = statSection.analyticsViewMoreEvent {
            captureAnalyticsEvent(modernEvent)
        }
    }

    func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, blogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event)
        }
    }
}
