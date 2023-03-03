import Foundation
import WordPressKit

final class BlazeService {

    private let contextManager: CoreDataStack
    private let remote: BlazeServiceRemote

    // MARK: - Init

    required init?(contextManager: CoreDataStack = ContextManager.shared,
                   remote: BlazeServiceRemote? = nil) {
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext) else {
            return nil
        }

        self.contextManager = contextManager
        self.remote = remote ?? .init(wordPressComRestApi: account.wordPressComRestV2Api)
    }

    // MARK: - Methods

    /// Fetches and updates blaze status from the server.
    ///
    /// - Parameters:
    ///   - blog: A blog
    ///   - success: Closure to be called on success
    ///   - failure: Closure to be caleld on failure
    func updateStatus(for blog: Blog,
                      success: (() -> Void)? = nil,
                      failure: ((Error) -> Void)? = nil) {
        guard let siteId = blog.dotComID?.intValue else {
            failure?(BlazeServiceError.invalidSiteId)
            return
        }

        remote.getStatus(forSiteId: siteId) { result in
            switch result {
            case .success(let approved):

                self.contextManager.performAndSave({ context in

                    guard let blog = Blog.lookup(withObjectID: blog.objectID, in: context) else {
                        DDLogError("Unable to update isBlazeApproved value for blog")
                        failure?(BlazeServiceError.blogNotFound)
                        return
                    }

                    blog.isBlazeApproved = approved
                    DDLogInfo("Successfully updated isBlazeApproved value for blog: \(approved)")

                }, completion: {
                    success?()
                }, on: .main)

            case .failure(let error):
                DDLogError("Unable to fetch isBlazeApproved value from remote: \(error.localizedDescription)")
                failure?(error)
            }
        }
    }
}

extension BlazeService {

    enum BlazeServiceError: Error {
        case invalidSiteId
        case blogNotFound
    }
}
