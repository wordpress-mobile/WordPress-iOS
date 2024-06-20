import Foundation

open class BlazeServiceRemote: ServiceRemoteWordPressComREST {

    // MARK: - Campaigns

    /// Searches the campaigns for the site with the given ID. The campaigns are returned ordered by the post date.
    ///
    /// - parameters:
    ///   - siteId: The site ID.
    ///   - page: The response page. By default, returns the first page.
    open func searchCampaigns(forSiteId siteId: Int, page: Int = 1, callback: @escaping (Result<BlazeCampaignsSearchResponse, Error>) -> Void) {
        let endpoint = "sites/\(siteId)/wordads/dsp/api/v1/search/campaigns/site/\(siteId)"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)
        Task { @MainActor in
            let result = await self.wordPressComRestApi
                .perform(
                    .get,
                    URLString: path,
                    parameters: ["page": page] as [String: AnyObject],
                    jsonDecoder: JSONDecoder.apiDecoder,
                    type: BlazeCampaignsSearchResponse.self
                )
                .map { $0.body }
                .eraseToError()
            callback(result)
        }
    }
}
