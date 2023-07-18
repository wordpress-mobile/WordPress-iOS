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
        button.configuration = {
            var configuration = UIButton.Configuration.plain()
            configuration.attributedTitle = {
                var string = AttributedString(Strings.createCampaignButton)
                string.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .bold)
                string.foregroundColor = UIColor.primary
                return string
            }()
            configuration.contentInsets = Constants.createCampaignInsets
            return configuration
        }()
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(buttonCreateCampaignTapped), for: .touchUpInside)
        return button
    }()

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?
    private var campaign: BlazeCampaign?

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

        campaignView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(campainViewTapped)))
    }

    private func showCampaignList() {
        guard let presentingViewController, let blog else { return }
        BlazeFlowCoordinator.presentBlazeCampaigns(in: presentingViewController, source: .dashboardCard, blog: blog)
    }

    private func makeShowCampaignsMenuAction() -> UIAction {
        UIAction(title: Strings.viewAllCampaigns, image: UIImage(systemName: "ellipsis.circle")) { [weak self] _ in
            self?.showCampaignList()
        }
    }

    private func showBlazeOverlay() {
        guard let presentingViewController, let blog else { return }
        BlazeEventsTracker.trackLearnMoreTapped(for: .dashboardCard)
        BlazeFlowCoordinator.presentBlazeOverlay(in: presentingViewController, source: .dashboardCard, blog: blog)
    }

    private func makeLearnMoreMenuAction() -> UIAction {
        UIAction(title: Strings.learnMore, image: UIImage(systemName: "info.circle")) { [weak self] _ in
            self?.showBlazeOverlay()
        }
    }

    @objc private func campainViewTapped() {
        guard let presentingViewController, let blog, let campaign else { return }
        BlazeFlowCoordinator.presentBlazeCampaignDetails(in: presentingViewController, source: .dashboardCard, blog: blog, campaignID: campaign.campaignID)
    }

    @objc private func buttonCreateCampaignTapped() {
        guard let presentingViewController, let blog else { return }
        BlazeEventsTracker.trackEntryPointTapped(for: .dashboardCard)
        BlazeFlowCoordinator.presentBlaze(in: presentingViewController, source: .dashboardCard, blog: blog)
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, campaign: BlazeCampaign) {
        self.blog = blog
        self.presentingViewController = viewController
        self.campaign = campaign

        frameView.addMoreMenu(items: [
            UIMenu(options: .displayInline, children: [
                makeShowCampaignsMenuAction()
            ]),
            UIMenu(options: .displayInline, children: [
                makeLearnMoreMenuAction()
            ]),
            UIMenu(options: .displayInline, children: [
                BlogDashboardHelpers.makeHideCardAction(for: .blaze, blog: blog)
            ])
        ], card: .blaze)

        let viewModel = BlazeCampaignViewModel(campaign: campaign)
        campaignView.configure(with: viewModel, blog: blog)
    }
}

private extension DashboardBlazeCampaignsCardView {
    enum Strings {
        static let cardTitle = NSLocalizedString("dashboardCard.blazeCampaigns.title", value: "Blaze campaign", comment: "Title for the card displaying blaze campaigns.")
        static let viewAllCampaigns = NSLocalizedString("dashboardCard.blazeCampaigns.viewAllCampaigns", value: "View all campaigns", comment: "Title for the View All Campaigns button in the More menu")
        static let learnMore = NSLocalizedString("dashboardCard.blazeCampaigns.learnMore", value: "Learn more", comment: "Title for the Learn more button in the More menu.")
        static let createCampaignButton = NSLocalizedString("dashboardCard.blazeCampaigns.createCampaignButton", value: "Create campaign", comment: "Title of a button that starts the campaign creation flow.")
    }

    enum Constants {
        static let campaignViewInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static let createCampaignInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
    }
}
