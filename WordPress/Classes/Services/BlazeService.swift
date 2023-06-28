import Foundation
import WordPressKit

protocol BlazeServiceProtocol {
    func getRecentCampaigns(for blog: Blog, completion: @escaping (Result<BlazeCampaignsSearchResponse, Error>) -> Void)
}

@objc final class BlazeService: NSObject, BlazeServiceProtocol {
    private let contextManager: CoreDataStackSwift
    private let remote: BlazeServiceRemote

    // MARK: - Init

    required init?(contextManager: CoreDataStackSwift = ContextManager.shared,
                   remote: BlazeServiceRemote? = nil) {
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext) else {
            return nil
        }

        self.contextManager = contextManager
        self.remote = remote ?? .init(wordPressComRestApi: account.wordPressComRestV2Api)
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

    func recentCampaigns(for blog: Blog, page: Int) async throws -> BlazeCampaignsSearchResponse {
        try await withUnsafeThrowingContinuation {
            getRecentCampaigns(for: blog, page: page, completion: $0.resume)
        }
    }
}

enum BlazeServiceError: Error {
    case notEligibleForBlaze
    case missingBlogId
}
