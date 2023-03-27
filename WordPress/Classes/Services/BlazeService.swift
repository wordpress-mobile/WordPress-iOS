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

        guard BlazeHelper.isBlazeFlagEnabled() else {
            updateBlogWithID(blog.objectID, isBlazeApproved: false, completion: completion)
            return
        }

        guard let siteId = blog.dotComID?.intValue else {
            DDLogError("Invalid site ID for Blaze")
            updateBlogWithID(blog.objectID, isBlazeApproved: false, completion: completion)
            return
        }

        remote.getStatus(forSiteId: siteId) { result in
            switch result {
            case .success(let approved):
                self.updateBlogWithID(blog.objectID, isBlazeApproved: approved, completion: completion)
            case .failure(let error):
                DDLogError("Unable to fetch isBlazeApproved value from remote: \(error.localizedDescription)")
                self.updateBlogWithID(blog.objectID, isBlazeApproved: false, completion: completion)
            }
        }
    }

    private func updateBlogWithID(_ objectID: NSManagedObjectID,
                                  isBlazeApproved: Bool,
                                  completion: (() -> Void)? = nil) {
        contextManager.performAndSave({ context in

            guard let blog = context.object(with: objectID) as? Blog else {
                DDLogError("Unable to update isBlazeApproved value for blog")
                completion?()
                return
            }

            blog.isBlazeApproved = isBlazeApproved
            DDLogInfo("Successfully updated isBlazeApproved value for blog: \(isBlazeApproved)")

        }, completion: {
            completion?()
        }, on: .main)
    }
}
