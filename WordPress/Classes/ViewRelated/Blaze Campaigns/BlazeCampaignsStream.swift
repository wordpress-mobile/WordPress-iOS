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
    private var hasMore = true
    private let blog: Blog

    init(blog: Blog) {
        self.blog = blog
    }

    /// Loads the next page. Does nothing if it's already loading or has no more items to load.
    func load(_ completion: ((Result<BlazeCampaignsSearchResponse, Error>) -> Void)? = nil) {
        guard let service = BlazeService() else {
            return assertionFailure("Failed to create BlazeService")
        }
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
            let newCampaigns = response.campaigns ?? []
            pages.append(response)
            hasMore = (response.totalPages ?? 0) > pages.count && !newCampaigns.isEmpty

            campaigns += newCampaigns
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
