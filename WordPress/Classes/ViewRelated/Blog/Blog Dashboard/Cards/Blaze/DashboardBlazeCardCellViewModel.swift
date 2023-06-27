import Foundation
import WordPressKit

final class DashboardBlazeCardCellViewModel {
    private(set) var lastestCampaign: BlazeCampaign?

    private let blog: Blog
    private let store: DashboardBlazeStoreProtocol
    private let service = BlazeService()
    private var isRefreshing = false

    var onRefresh: ((DashboardBlazeCardCellViewModel) -> Void)?

    init(blog: Blog,
         store: DashboardBlazeStoreProtocol = BlogDashboardPersistence()) {
        self.blog = blog
        self.store = store

        if RemoteFeatureFlag.blazeManageCampaigns.enabled() {
            self.lastestCampaign = blog.dotComID.flatMap {
                store.getBlazeCampaign(forBlogID: $0.intValue)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .blazeCampaignCreated, object: nil)
    }

    @objc func refresh() {
        guard RemoteFeatureFlag.blazeManageCampaigns.enabled() else {
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
            lastestCampaign = response.campaigns?.first
            if let campaign = response.campaigns?.first, let blogID = blog.dotComID?.intValue {
                store.storeBlazeCampaign(campaign, forBlogID: blogID)
            }
        }
        onRefresh?(self)
    }
}

protocol DashboardBlazeStoreProtocol {
    func getBlazeCampaign(forBlogID blogID: Int) -> BlazeCampaign?
    func storeBlazeCampaign(_ campaign: BlazeCampaign, forBlogID blogID: Int)
}
