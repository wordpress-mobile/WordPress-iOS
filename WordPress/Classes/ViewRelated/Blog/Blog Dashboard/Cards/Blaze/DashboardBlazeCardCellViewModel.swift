import Foundation
import WordPressKit

final class DashboardBlazeCardCellViewModel {
    private(set) var state: State = .promo

    private var blog: Blog
    private let service: BlazeServiceProtocol
    private let store: DashboardBlazeStoreProtocol
    private var isRefreshing = false
    private let isBlazeCampaignsFlagEnabled: () -> Bool

    enum State {
        /// Showing "Promote you content with Blaze" promo card.
        case promo
        /// Showing the latest Blaze campaign.
        case campaign(BlazeCampaign)
    }

    var onRefresh: ((DashboardBlazeCardCellViewModel) -> Void)?

    init(blog: Blog,
         service: BlazeServiceProtocol = BlazeService(),
         store: DashboardBlazeStoreProtocol = BlogDashboardPersistence(),
         isBlazeCampaignsFlagEnabled: @escaping () -> Bool = { RemoteFeatureFlag.blazeManageCampaigns.enabled() }) {
        self.blog = blog
        self.service = service
        self.store = store
        self.isBlazeCampaignsFlagEnabled = isBlazeCampaignsFlagEnabled

        if isBlazeCampaignsFlagEnabled(),
           let blogID = blog.dotComID?.intValue,
           let campaign = store.getBlazeCampaign(forBlogID: blogID) {
            self.state = .campaign(campaign)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .blazeCampaignCreated, object: nil)
    }

    @objc func refresh() {
        guard isBlazeCampaignsFlagEnabled() else {
            return // Continue showing the default `Promo` card
        }

        guard !isRefreshing else { return }
        isRefreshing = true

        service.getRecentCampaigns(for: blog, page: 1) { [weak self] in
            self?.didRefresh(with: $0)
        }
    }

    private func didRefresh(with result: Result<BlazeCampaignsSearchResponse, Error>) {
        if case .success(let response) = result {
            let campaign = response.campaigns?.first
            if let blogID = blog.dotComID?.intValue {
                store.setBlazeCampaign(campaign, forBlogID: blogID)
            }
            if let campaign {
                state = .campaign(campaign)
            } else {
                state = .promo
            }
        }

        isRefreshing = false
        onRefresh?(self)
    }
}

protocol DashboardBlazeStoreProtocol {
    func getBlazeCampaign(forBlogID blogID: Int) -> BlazeCampaign?
    func setBlazeCampaign(_ campaign: BlazeCampaign?, forBlogID blogID: Int)
}
