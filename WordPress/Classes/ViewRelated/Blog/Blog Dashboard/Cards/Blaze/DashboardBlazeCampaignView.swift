import Foundation
import UIKit
import WordPressKit

final class DashboardBlazeCampaignView: UIView {
    private let statusView = BlazeCampaignStatusView()
    private let titleLabel = UILabel()
    private let imageView = CachedAnimatedImageView()

    private lazy var statsView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var imageLoader = ImageLoader(imageView: imageView)

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 2
        titleLabel.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 4

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 44),
            imageView.heightAnchor.constraint(equalToConstant: 44),
        ])

        let headerView = UIStackView(arrangedSubviews: [titleLabel, imageView])
        headerView.alignment = .top
        headerView.spacing = 12

        let contentView = UIStackView(arrangedSubviews: [
            UIStackView(arrangedSubviews: [statusView, UIView()]), // Leading alignment
            headerView,
            statsView
        ])
        contentView.axis = .vertical
        contentView.spacing = 8
        contentView.setCustomSpacing(12, after: headerView)

        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: BlazeCampaignViewModel, blog: Blog) {
        statusView.configure(with: viewModel.status)

        titleLabel.text = viewModel.title

        imageLoader.prepareForReuse()
        imageView.isHidden = viewModel.imageURL == nil
        if let imageURL = viewModel.imageURL {
            let host = MediaHost(with: blog, failure: { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            })
            imageLoader.loadImage(with: imageURL, from: host, preferredSize: Constants.imageSize)
        }

        statsView.isHidden = !viewModel.isShowingStats
            statsView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if viewModel.isShowingStats {
            makeStatsViews(for: viewModel).forEach(statsView.addArrangedSubview)
        }

        enableVoiceOver(with: viewModel)
    }

    private func makeStatsViews(for viewModel: BlazeCampaignViewModel) -> [UIView] {
        let impressionsView = DashboardSingleStatView(title: Strings.impressions)
        impressionsView.countString = "\(viewModel.impressions)"

        let clicksView = DashboardSingleStatView(title: Strings.clicks)
        clicksView.countString = "\(viewModel.clicks)"

        return [impressionsView, clicksView]
    }

    private func enableVoiceOver(with viewModel: BlazeCampaignViewModel) {
        var accessibilityLabel = "\(viewModel.title), \(viewModel.status.title)"
        if viewModel.isShowingStats {
            accessibilityLabel += ", \(Strings.impressions) \(viewModel.impressions), \(Strings.clicks) \(viewModel.clicks)"
        }
        self.isAccessibilityElement = true
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityTraits = .allowsDirectInteraction
    }
}

private extension DashboardBlazeCampaignView {
    enum Strings {
        static let impressions = NSLocalizedString("dashboardCard.blazeCampaigns.impressions", value: "Impressions", comment: "Title for impressions stats view")
        static let clicks = NSLocalizedString("dashboardCard.blazeCampaigns.clicks", value: "Clicks", comment: "Title for impressions stats view")
    }

    enum Constants {
        static let imageSize = CGSize(width: 44, height: 44)
    }
}

struct BlazeCampaignViewModel {
    let title: String
    let imageURL: URL?
    let impressions: String
    let clicks: String
    let budget: String
    var status: BlazeCampaignStatusViewModel { .init(campaign: campaign) }

    var isShowingStats: Bool {
        switch campaign.uiStatus {
        case .created, .processing, .canceled, .approved, .rejected, .scheduled, .unknown:
            return false
        case .active, .finished:
            return true
        }
    }

    private let campaign: BlazeCampaign

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    init(campaign: BlazeCampaign) {
        self.campaign = campaign
        self.title = campaign.name ?? "–"
        self.imageURL = campaign.contentConfig?.imageURL.flatMap(URL.init)
        self.impressions = campaign.stats?.impressionsTotal?.abbreviatedString() ?? "0"
        self.clicks = campaign.stats?.clicksTotal?.abbreviatedString() ?? "0"
        self.budget = currencyFormatter.string(from: ((campaign.budgetCents ?? 0) / 100) as NSNumber) ?? "-"
    }
}
