import Foundation
import WordPressKit

protocol BlazeServiceProtocol {
    func getRecentCampaigns(for blog: Blog, page: Int, completion: @escaping (Result<BlazeCampaignsSearchResponse, Error>) -> Void)
}

@objc final class BlazeService: NSObject, BlazeServiceProtocol {
    private let contextManager: CoreDataStackSwift
    private let remote: BlazeServiceRemote

    // MARK: - Init

    required init(contextManager: CoreDataStackSwift = ContextManager.shared,
                   remote: BlazeServiceRemote? = nil) {
        self.contextManager = contextManager
        self.remote = remote ?? BlazeServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: contextManager.mainContext, localeKey: WordPressComRestApi.LocaleKeyV2))
    }

    @objc class func createService() -> BlazeService? {
        self.init()
    }

    // MARK: - Methods

    func getRecentCampaigns(for blog: Blog,
                            page: Int = 1,
                            completion: @escaping (Result<BlazeCampaignsSearchResponse, Error>) -> Void) {
        guard blog.canBlaze else {
            completion(.failure(BlazeServiceError.notEligibleForBlaze))
            return
        }
        guard let siteId = blog.dotComID?.intValue else {
            DDLogError("Invalid site ID for Blaze")
            completion(.failure(BlazeServiceError.missingBlogId))
            return
        }
        remote.searchCampaigns(forSiteId: siteId, page: page, callback: completion)
    }
}

enum BlazeServiceError: Error {
    case notEligibleForBlaze
    case missingBlogId
}
