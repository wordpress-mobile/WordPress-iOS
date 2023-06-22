import UIKit
import WordPressKit

final class DashboardBlazeCampaignsCardView: UIView {
    private let frameView = BlogDashboardCardFrameView()
    private let campaignView = DashboardBlazeCampaignView()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var createCampaignButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .leading
        button.setTitle(Strings.createCampaignButton, for: .normal)
        button.addTarget(self, action: #selector(buttonCreateCampaignTapped), for: .touchUpInside)
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .bold)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitleColor(UIColor.primary, for: .normal)
        button.contentEdgeInsets = Constants.createCampaignInsets
        return button
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
        addSubview(frameView)
        frameView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(frameView, priority: UILayoutPriority(999))

        frameView.add(subview: contentStackView)
        contentStackView.addArrangedSubview({
            let container = UIStackView(arrangedSubviews: [campaignView])
            container.layoutMargins = Constants.campaignViewInsets
            container.isLayoutMarginsRelativeArrangement = true
            return container
        }())
        contentStackView.addArrangedSubview({
            let separator = UIView()
            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            separator.backgroundColor = UIColor.separator

            let container = UIView()
            container.addSubview(separator)
            container.pinSubviewToAllEdges(separator, insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
            return container
        }())
        contentStackView.addArrangedSubview(createCampaignButton)

        frameView.setTitle(Strings.cardTitle)
        frameView.onHeaderTap = { [weak self] in
            self?.showCampaignList()
        }
    }

    private func showCampaignList() {
        guard let presentingViewController, let blog else { return }
        BlazeFlowCoordinator.presentBlazeCampaigns(in: presentingViewController, blog: blog)
    }

    private func makeShowCampaignsMenuAction() -> UIAction {
        UIAction(title: Strings.viewAllCampaigns, image: UIImage(systemName: "ellipsis.circle")) { [weak self] _ in
            self?.showCampaignList()
        }
    }

    @objc private func buttonCreateCampaignTapped() {
        guard let presentingViewController, let blog else { return }
        BlazeEventsTracker.trackEntryPointTapped(for: .dashboardCard)
        BlazeFlowCoordinator.presentBlaze(in: presentingViewController, source: .dashboardCard, blog: blog)
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?) {
        self.blog = blog
        self.presentingViewController = viewController

        frameView.addMoreMenu(items: [
            UIMenu(options: .displayInline, children: [
                makeShowCampaignsMenuAction()
            ]),
            UIMenu(options: .displayInline, children: [
                BlogDashboardHelpers.makeHideCardAction(for: .blaze, blog: blog)
            ])
        ], card: .blaze)

        let viewModel = BlazeCampaignViewModel(campaign: mockResponse.campaigns!.first!)
        campaignView.configure(with: viewModel, blog: blog)
    }
}

private extension DashboardBlazeCampaignsCardView {
    enum Strings {
        static let cardTitle = NSLocalizedString("dashboardCard.blazeCampaigns.title", value: "Blaze campaign", comment: "Title for the card displaying blaze campaigns.")
        static let viewAllCampaigns = NSLocalizedString("dashboardCard.blazeCampaigns.viewAllCampaigns", value: "View all campaigns", comment: "Title for the View All Campaigns button in the More menu")
        static let createCampaignButton = NSLocalizedString("dashboardCard.blazeCampaigns.createCampaignButton", value: "Create campaign", comment: "Title of a button that starts the campaign creation flow.")
    }

    enum Constants {
        static let campaignViewInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static let createCampaignInsets = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)
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
                "ui_status": "finished",
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
