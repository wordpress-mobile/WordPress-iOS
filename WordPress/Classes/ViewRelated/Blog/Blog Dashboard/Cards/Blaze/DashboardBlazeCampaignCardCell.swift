import UIKit
import SwiftUI
import WordPressKit

final class DashboardBlazeCampaignCardCell: DashboardCollectionViewCell {
    private let frameView = BlogDashboardCardFrameView()
    private let campaignView = DashboardBlazeCampaignView()

    private lazy var buttonShowMoreCampaigns: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        button.setTitleColor(UIColor.primary, for: .normal)
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(buttonShowMoreTapped), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
        stackView.spacing = 4
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup

    private func setupView() {
        contentView.addSubview(frameView)
        frameView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(frameView, priority: UILayoutPriority(999))

        frameView.add(subview: contentStackView)
        contentStackView.addArrangedSubview(campaignView)
        contentStackView.addArrangedSubview(buttonShowMoreCampaigns)
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController


        frameView.setTitle(Strings.cardTitle)

        let viewModel = DashboardBlazeCampaignCardCellViewModel(response: mockResponse)!
        campaignView.configure(with: viewModel.campaign, blog: blog)
        buttonShowMoreCampaigns.isHidden = viewModel.isButtonShowMoreHidden
        buttonShowMoreCampaigns.setTitle(String(format: "+ \(Strings.showMoreCampaigns)", viewModel.totalCampaignCount), for: .normal)
    }

    // MARK: - Actions

    @objc private func buttonShowMoreTapped() {
        // TODO: Show campaign list
    }
}

private extension DashboardBlazeCampaignCardCell {
    enum Strings {
        static let cardTitle = NSLocalizedString("my-sites.blazeCampaigns.title", value: "Blaze campaign", comment: "Title for the card displaying blaze campaigns.")
        static let showMoreCampaigns = NSLocalizedString("my-sites.blazeCampaigns.showMoreCampaigns", value: "%d active campaigns", comment: "Title for button that shows more campaigns. Takes the number of campaigns as a parameter.")
    }
}

final class DashboardBlazeCampaignCardCellViewModel {
    let campaign: DashboardBlazeCampaignViewModel
    let totalCampaignCount: Int
    var isButtonShowMoreHidden: Bool { totalCampaignCount < 2 }

    init?(response: BlazeCampaignsSearchResponse) {
        guard let campaign = response.campaigns?.first else {
            return nil
        }
        self.campaign = DashboardBlazeCampaignViewModel(campaign: campaign)
        self.totalCampaignCount = response.totalItems ?? 1
    }
}

private let mockResponse: BlazeCampaignsSearchResponse = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(BlazeCampaignsSearchResponse.self, from: """
    {
        "totalItems": 3,
        "campaigns": [
            {
                "campaign_id": 26916,
                "name": "Test Post - don't approve",
                "start_date": "2023-06-13T00:00:00Z",
                "end_date": "2023-06-01T19:15:45Z",
                "status": "finished",
                "avatar_url": "https://0.gravatar.com/avatar/614d27bcc21db12e7c49b516b4750387?s=96&amp;d=identicon&amp;r=G",
                "budget_cents": 500,
                "target_url": "https://alextest9123.wordpress.com/2023/06/01/test-post/",
                "content_config": {
                    "title": "Test Post - don't approve",
                    "snippet": "Test Post Empty Empty",
                    "clickUrl": "https://alextest9123.wordpress.com/2023/06/01/test-post/",
                    "imageUrl": "https://i0.wp.com/public-api.wordpress.com/wpcom/v2/wordads/dsp/api/v1/dsp/creatives/56259/image?w=600&zoom=2"
                },
                "campaign_stats": {
                    "impressions_total": 1000,
                    "clicks_total": 235
                }
            }
        ]
    }
    """.data(using: .utf8)!)
}()
