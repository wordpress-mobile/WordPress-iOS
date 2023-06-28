import Foundation
import SwiftUI
import WordPressKit

@MainActor
final class BlazeCampaignsStream {
    private(set) var state = State() {
        didSet { didChangeState?(state) }
    }
    var didChangeState: ((State) -> Void)?

    private var pages: [BlazeCampaignsSearchResponse] = []
    private var hasMore = true
    private let blog: Blog

    init(blog: Blog) {
        self.blog = blog
    }

    func load() {
        guard let siteID = blog.dotComID?.intValue else {
            return assertionFailure("Missing site ID")
        }
        guard let service = BlazeService() else {
            return assertionFailure("Failed to create BlazeService")
        }

        guard !state.isLoading && hasMore else {
            return
        }
        Task {
            await load(service: service, siteID: siteID)
        }
    }

    #warning("fix this being called form background")
    private func load(service: BlazeService, siteID: Int) async {
        state.isLoading = true
        do {
            let response = try await service.recentCampaigns(for: siteID, page: pages.count + 1)
            let campaigns = response.campaigns ?? []
            if #available(iOS 16, *) {
                try? await Task.sleep(for: .seconds(5))
            }
            pages.append(response)
            state.campaigns += campaigns
            hasMore = (response.totalPages ?? 0) > pages.count && !campaigns.isEmpty
        } catch {
            state.error = error
        }
        state.isLoading = false
    }

    struct State {
        var campaigns: [BlazeCampaign] = []
        var isLoading = false
        var error: Error?
        var isLoadingMore: Bool { isLoading && !campaigns.isEmpty }
    }
}
