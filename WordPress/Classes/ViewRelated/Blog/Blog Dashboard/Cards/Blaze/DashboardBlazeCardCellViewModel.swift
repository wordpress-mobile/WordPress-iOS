import Foundation
import WordPressKit

final class DashboardBlazeCardCellViewModel {
    private(set) var lastestCampaign: BlazeCampaign?

    private let blog: Blog
    private let service = BlazeService()
    private var isRefreshing = false

    var onRefreshNeeded: ((DashboardBlazeCardCellViewModel) -> Void)?

    init(blog: Blog) {
        self.blog = blog

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
        }
        onRefreshNeeded?(self)
    }
}
