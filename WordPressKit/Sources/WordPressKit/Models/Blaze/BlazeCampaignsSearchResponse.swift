import Foundation

public final class BlazeCampaignsSearchResponse: Decodable {
    public let campaigns: [BlazeCampaign]?
    public let totalItems: Int?
    public let totalPages: Int?
    public let page: Int?

    public init(totalItems: Int?, campaigns: [BlazeCampaign]?, totalPages: Int?, page: Int?) {
        self.totalItems = totalItems
        self.campaigns = campaigns
        self.totalPages = totalPages
        self.page = page
    }
}
