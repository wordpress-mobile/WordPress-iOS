import UIKit
import AsyncImageKit
import WordPressShared

final class BlazeCampaignTableViewCell: UITableViewCell, Reusable {

    // MARK: - Views

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.mainStackViewSpacing
        stackView.directionalLayoutMargins = Metrics.defaultMainStackViewLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubviews([headerStackView, detailsOuterStackView])
        return stackView
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.addArrangedSubviews([statusView, UIView()])
        return stackView
    }()

    private lazy var statusView: BlazeCampaignStatusView = {
        let statusView = BlazeCampaignStatusView()
        statusView.translatesAutoresizingMaskIntoConstraints = false
        return statusView
    }()

    private lazy var detailsOuterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Metrics.detailsOuterStackViewSpacing
        stackView.addArrangedSubviews([detailsInnerStackView, featuredImageView, chevronView])
        return stackView
    }()

    private lazy var detailsInnerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.detailsInnerStackViewSpacing
        stackView.addArrangedSubviews([titleLabel, statsStackView])
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .label
        return label
    }()

    private lazy var statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Metrics.statsStackViewSpacing
        return stackView
    }()

    private lazy var featuredImageView: AsyncImageView = {
        let imageView = AsyncImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Metrics.featuredImageCornerRadius
        return imageView
    }()

    private lazy var chevronView: UIImageView = {
        let image = UIImage(systemName: "chevron.forward")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .separator
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return imageView
    }()

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: - Public

    func configure(with viewModel: BlazeCampaignViewModel, blog: Blog) {
        statusView.configure(with: viewModel.status)

        titleLabel.text = viewModel.title

        featuredImageView.prepareForReuse()
        featuredImageView.isHidden = viewModel.imageURL == nil
        if let imageURL = viewModel.imageURL {
            let host = MediaHost(blog)
            let preferredSize = ImageSize(scaling: CGSize(width: Metrics.featuredImageSize, height: Metrics.featuredImageSize), in: self)
            featuredImageView.setImage(with: imageURL, host: host, size: preferredSize)
        }

        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        makeStatsViews(with: viewModel).forEach(statsStackView.addArrangedSubview)

        configureVoiceOver(with: viewModel)
    }

    // MARK: - Helpers

    private func commonInit() {
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(mainStackView)
        contentView.pinSubviewToAllEdges(mainStackView)
        mainStackView.addBottomBorder(withColor: .separator,
                                      leadingMargin: Metrics.defaultMainStackViewLayoutMargins.leading,
                                      trailingMargin: -Metrics.defaultMainStackViewLayoutMargins.trailing)

        NSLayoutConstraint.activate([
            featuredImageView.widthAnchor.constraint(equalToConstant: Metrics.featuredImageSize),
            featuredImageView.heightAnchor.constraint(equalTo: featuredImageView.widthAnchor)
        ])
    }

    private func makeStatsViews(with viewModel: BlazeCampaignViewModel) -> [UIView] {

        var subviews: [UIView] = []

        if viewModel.isShowingStats {
            let impressionsView = BlazeCampaignSingleStatView(title: Strings.impressions)
            impressionsView.valueString = "\(viewModel.impressions)"

            let clicksView = BlazeCampaignSingleStatView(title: Strings.clicks)
            clicksView.valueString = "\(viewModel.clicks)"

            subviews += [impressionsView, clicksView]
        }

        let budgetView = BlazeCampaignSingleStatView(title: Strings.budget)
        budgetView.valueString = "\(viewModel.budget)"
        subviews += [budgetView, UIView()]

        return subviews
    }

    private func configureVoiceOver(with viewModel: BlazeCampaignViewModel) {

        var statsAccessibilityLabel = ""

        if viewModel.isShowingStats {
            statsAccessibilityLabel += "\(Strings.impressions) \(viewModel.impressions), \(Strings.clicks) \(viewModel.clicks), "
        }

        statsAccessibilityLabel += "\(Strings.budget) \(viewModel.budget)"

        statsStackView.isAccessibilityElement = true
        statsStackView.accessibilityLabel = statsAccessibilityLabel
    }
}

private extension BlazeCampaignTableViewCell {

    enum Metrics {
        static let mainStackViewSpacing: CGFloat = 8
        static let detailsOuterStackViewSpacing: CGFloat = 16
        static let detailsInnerStackViewSpacing: CGFloat = 8
        static let statsStackViewSpacing: CGFloat = 16
        static let defaultMainStackViewLayoutMargins: NSDirectionalEdgeInsets = .init(top: 14, leading: 16, bottom: 14, trailing: 16)
        static let featuredImageSize: CGFloat = 72
        static let featuredImageCornerRadius: CGFloat = 4
    }

    enum Strings {
        static let impressions = NSLocalizedString("blazeCampaigns.impressions", value: "Impressions", comment: "Title for impressions stats view")
        static let clicks = NSLocalizedString("blazeCampaigns.clicks", value: "Clicks", comment: "Title for impressions stats view")
        static let budget = NSLocalizedString("blazeCampaigns.budget", value: "Budget", comment: "Title for budget stats view")
    }
}
