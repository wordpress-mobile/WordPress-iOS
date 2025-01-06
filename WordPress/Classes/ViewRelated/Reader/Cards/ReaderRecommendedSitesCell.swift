import SwiftUI
import UIKit
import WordPressUI
import Combine

protocol ReaderRecommendationsCellDelegate: AnyObject {
    func didSelect(topic: ReaderAbstractTopic)
}

final class ReaderRecommendedSitesCell: UITableViewCell {
    private let sitesStackView = UIStackView(axis: .vertical, spacing: 16, [])

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        for view in sitesStackView.subviews {
            view.removeFromSuperview()
        }
    }

    private func setupView() {
        selectionStyle = .none

        let backgroundView = UIView()
        backgroundView.backgroundColor = .secondarySystemBackground
        backgroundView.layer.cornerRadius = 8

        contentView.addSubview(backgroundView)
        backgroundView.pinEdges(to: contentView.readableContentGuide)

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.textColor = .secondaryLabel
        titleLabel.text = Strings.title

        let stackView = UIStackView(axis: .vertical, spacing: 16, [titleLabel, sitesStackView])

        backgroundView.addSubview(stackView)
        stackView.pinEdges(insets: {
            var insets = UIEdgeInsets(.all, 16)
            insets.right = 6 // Buttons insets take care of it
            return insets
        }())
    }

    func configure(with sites: [ReaderSiteTopic], delegate: ReaderRecommendationsCellDelegate) {
        for site in sites {
            let siteView = ReaderRecommendedSitesCellView()
            siteView.configure(with: site)
            siteView.delegate = delegate
            sitesStackView.addArrangedSubview(siteView)
        }
    }
}

/// Presentation-agnostic view for displaying post cells.
private final class ReaderRecommendedSitesCellView: UIView {
    let siteIconView = SiteIconHostingView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let buttonShowDetails = UIButton(type: .system)
    let buttonSubscribe = UIButton(configuration: {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "plus.circle")
        configuration.baseForegroundColor = UIAppColor.primary
        configuration.contentInsets = .zero
        return configuration
    }())

    weak var delegate: ReaderRecommendationsCellDelegate?

    private let iconSize: SiteIconViewModel.Size = .regular
    private var site: ReaderSiteTopic?
    private var cancellable: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: .zero)

        titleLabel.font = .preferredFont(forTextStyle: .callout).withWeight(.medium)
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .secondaryLabel

        NSLayoutConstraint.activate([
            siteIconView.widthAnchor.constraint(equalToConstant: iconSize.width),
            siteIconView.heightAnchor.constraint(equalToConstant: iconSize.width),
        ])

        NSLayoutConstraint.activate([
            buttonSubscribe.widthAnchor.constraint(equalToConstant: 40),
            buttonSubscribe.heightAnchor.constraint(equalToConstant: 40),
        ])

        buttonSubscribe.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stackView = UIStackView(alignment: .center, spacing: 6, [
            siteIconView,
            UIStackView(axis: .vertical, alignment: .leading, spacing: 2, [
                titleLabel, subtitleLabel,
            ]),
            buttonSubscribe
        ])
        stackView.setCustomSpacing(14, after: siteIconView)
        addSubview(stackView)
        stackView.pinEdges()

        stackView.addSubview(buttonShowDetails)
        buttonShowDetails.pinEdges(insets: UIEdgeInsets(.trailing, 40))

        buttonShowDetails.addTarget(self, action: #selector(buttonShowDetailsTapped), for: .touchUpInside)

        buttonSubscribe.addTarget(self, action: #selector(buttonSubscribeTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with site: ReaderSiteTopic) {
        self.site = site

        siteIconView.setIcon(with: .init(readerSiteTopic: site, size: iconSize))
        titleLabel.text = site.title
        subtitleLabel.text = site.siteDescription

        cancellable = site.publisher(for: \.following, options: [.initial, .new])
            .sink { [weak self] isFollowing in
                self?.buttonSubscribe.configuration?.image = UIImage(systemName: isFollowing ? "checkmark.circle.fill" : "plus.circle")
            }
    }

    @objc private func buttonShowDetailsTapped() {
        guard let site else {
            return wpAssertionFailure("site missing")
        }
        delegate?.didSelect(topic: site)
    }

    @objc private func buttonSubscribeTapped() {
        guard let site else {
            return wpAssertionFailure("site missing")
        }

        var properties = [String: Any]()
        properties[WPAppAnalyticsKeyFollowAction] = !site.following
        properties[WPAppAnalyticsKeyBlogID] = site.siteID

        WPAnalytics.trackReader(.readerSuggestedSiteToggleFollow, properties: properties)

        buttonSubscribe.configuration?.showsActivityIndicator = true
        buttonSubscribe.configuration?.baseForegroundColor = .secondaryLabel
        ReaderSubscriptionHelper().toggleFollowingForSite(site) { [weak self] _ in
            self?.buttonSubscribe.configuration?.showsActivityIndicator = false
            self?.buttonSubscribe.configuration?.baseForegroundColor = UIAppColor.primary
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("reader.suggested.blogs.title", value: "Blogs to subscribe to", comment: "A suggestion of topics the user might want to subscribe to")
}
