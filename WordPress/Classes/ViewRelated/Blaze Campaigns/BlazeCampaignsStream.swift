import Foundation
import SwiftUI
import WordPressKit

protocol BlazeCampaignsStreamDelegate: AnyObject {
    func stream(_ stream: BlazeCampaignsStream, didAppendItemsAt indexPaths: [IndexPath])
    func streamDidRefreshState(_ stream: BlazeCampaignsStream)
}

final class BlazeCampaignsStream {
    weak var delegate: BlazeCampaignsStreamDelegate?

    private(set) var campaigns: [BlazeCampaign] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    private var pages: [BlazeCampaignsSearchResponse] = []
    private var campaignIDs: Set<Int> = []
    private var hasMore = true
    private let service: BlazeServiceProtocol
    private let blog: Blog

    init(blog: Blog,
         service: BlazeServiceProtocol = BlazeService()) {
        self.blog = blog
        self.service = service
    }

    /// Loads the next page. Does nothing if it's already loading or has no more items to load.
    func load(_ completion: ((Result<BlazeCampaignsSearchResponse, Error>) -> Void)? = nil) {
        guard !isLoading && hasMore else {
            return
        }
        isLoading = true
        error = nil
        delegate?.streamDidRefreshState(self)

        service.getRecentCampaigns(for: blog, page: pages.count + 1) { [weak self] in
            self?.didLoad(with: $0)
            completion?($0)
        }
    }

    private func didLoad(with result: Result<BlazeCampaignsSearchResponse, Error>) {
        switch result {
        case .success(let response):
            let newCampaigns = (response.campaigns ?? [])
                .filter { !campaignIDs.contains($0.campaignID) }
            pages.append(response)
            hasMore = (response.totalPages ?? 0) > pages.count && !newCampaigns.isEmpty

            campaigns += newCampaigns
            campaignIDs.formUnion(newCampaigns.map(\.campaignID))
            let indexPaths = campaigns.indices.prefix(newCampaigns.count)
                .map { IndexPath(row: $0, section: 0) }
            delegate?.stream(self, didAppendItemsAt: indexPaths)
        case .failure(let error):
            self.error = error
        }
        isLoading = false
        delegate?.streamDidRefreshState(self)
    }
}
