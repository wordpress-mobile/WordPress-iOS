import Foundation
import WordPressKit

final class DashboardBlazeCardCellViewModel {
    private(set) var state: State = .promo

    private let blog: Blog
    private let service: BlazeServiceProtocol?
    private let store: DashboardBlazeStoreProtocol
    private var isRefreshing = false
    private let isBlazeCampaignsFlagEnabled: Bool

    enum State {
        /// Showing "Promote you content with Blaze" promo card.
        case promo
        /// Showing the latest Blaze campaign.
        case campaign(BlazeCampaignViewModel)
    }

    var onRefresh: ((DashboardBlazeCardCellViewModel) -> Void)?

    init(blog: Blog,
         service: BlazeServiceProtocol? = BlazeService(),
         store: DashboardBlazeStoreProtocol = BlogDashboardPersistence(),
         isBlazeCampaignsFlagEnabled: Bool = RemoteFeatureFlag.blazeManageCampaigns.enabled()) {
        self.blog = blog
        self.service = service
        self.store = store
        self.isBlazeCampaignsFlagEnabled = isBlazeCampaignsFlagEnabled

        if isBlazeCampaignsFlagEnabled,
           let blogID = blog.dotComID?.intValue,
           let campaign = store.getBlazeCampaign(forBlogID: blogID) {
            self.state = .campaign(BlazeCampaignViewModel(campaign: campaign))
        }

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .blazeCampaignCreated, object: nil)
    }

    @objc func refresh() {
        guard isBlazeCampaignsFlagEnabled else {
            return // Continue showing the default `Promo` card
        }

        guard !isRefreshing, let service else { return }
        isRefreshing = true

        service.getRecentCampaigns(for: blog) { [weak self] in
            self?.didRefresh(with: $0)
        }
    }

    private func didRefresh(with result: Result<BlazeCampaignsSearchResponse, Error>) {
        isRefreshing = false
        if case .success(let response) = result {
            if let campaign = response.campaigns?.first {
                self.state = .campaign(BlazeCampaignViewModel(campaign: campaign))
                if let blogID = blog.dotComID?.intValue {
                    store.setBlazeCampaign(campaign, forBlogID: blogID)
                }
            } else {
                if let blogID = blog.dotComID?.intValue {
                    store.setBlazeCampaign(nil, forBlogID: blogID)
                }
                self.state = .promo
            }
        }
        onRefresh?(self)
    }
}

protocol DashboardBlazeStoreProtocol {
    func getBlazeCampaign(forBlogID blogID: Int) -> BlazeCampaign?
    func setBlazeCampaign(_ campaign: BlazeCampaign?, forBlogID blogID: Int)
}
