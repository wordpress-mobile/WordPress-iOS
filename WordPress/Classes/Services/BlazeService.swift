import Foundation
import WordPressKit

@objc final class BlazeService: NSObject {

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

    @objc class func createService() -> BlazeService? {
        self.init()
    }

    // MARK: - Methods

    /// Fetches a site's blaze status from the server, and updates the blog's isBlazeApproved property.
    ///
    /// - Parameters:
    ///   - blog: A blog
    ///   - completion: Closure to be called on success
    @objc func getStatus(for blog: Blog,
                         completion: (() -> Void)? = nil) {
        guard let siteId = blog.dotComID?.intValue else {
            DDLogError("Invalid site ID for Blaze")
            completion?()
            return
        }
        
        remote.getStatus(forSiteId: siteId) { result in
            switch result {
            case .success(let approved):

                self.contextManager.performAndSave({ context in

                    guard let blog = Blog.lookup(withObjectID: blog.objectID, in: context) else {
                        DDLogError("Unable to update isBlazeApproved value for blog")
                        completion?()
                        return
                    }

                    blog.isBlazeApproved = approved
                    DDLogInfo("Successfully updated isBlazeApproved value for blog: \(approved)")

                }, completion: {
                    completion?()
                }, on: .main)

            case .failure(let error):
                DDLogError("Unable to fetch isBlazeApproved value from remote: \(error.localizedDescription)")
                completion?()
            }
        }
    }
}
