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

    func getStatus(for blog: Blog,
                   success: @escaping (Bool) -> Void,
                   failure: @escaping (Error) -> Void) {
        guard let siteId = blog.dotComID?.intValue else {
            failure(BlazeServiceError.invalidSiteId)
            return
        }

        remote.getStatus(forSiteId: siteId) { result in
            switch result {
            case .success(let approved):

                self.contextManager.performAndSave({ context in
                    guard let blog = Blog.lookup(withObjectID: blog.objectID, in: context) else {
                        return
                    }
                    blog.isBlazeApproved = approved
                }, completion: {
                    success(approved)
                }, on: .main)

            case .failure(let error):
                failure(error)
            }
        }
    }
}

extension BlazeService {

    enum BlazeServiceError: Error {
        case invalidSiteId
    }
}
