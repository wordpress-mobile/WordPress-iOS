import WordPressKit
import CoreData

class JetpackSocialService {

    // MARK: Properties

    private let coreDataStack: CoreDataStackSwift

    private lazy var remote: JetpackSocialServiceRemote = {
        let api = coreDataStack.performQuery { context in
            return WordPressComRestApi.defaultV2Api(in: context)
        }
        return .init(wordPressComRestApi: api)
    }()

    // MARK: Methods

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.coreDataStack = coreDataStack
    }

    /// Fetches and updates the Publicize information for the site associated with the `blogID`.
    /// The method returns a value type that contains the remaining usage of Social auto-sharing and the maximum limit for the associated site.
    ///
    /// - Note: If the returned result is a success with nil sharing limit, it's likely that the blog is hosted on WP.com, and has no Social sharing limitations.
    ///
    /// Furthermore, even if the sharing limit exists, it may not be applicable for the blog since the user might have purchased a product that ignores this limitation.
    ///
    /// - Parameters:
    ///   - blogID: The ID of the blog.
    ///   - completion: Closure that's called after the sync process completes.
    func syncSharingLimit(for blogID: Int, completion: @escaping (Result<PublicizeInfo.SharingLimit?, Error>) -> Void) {
        remote.fetchPublicizeInfo(for: blogID) { [weak self] result in
            switch result {
            case .success(let remotePublicizeInfo):
                self?.coreDataStack.performAndSave({ context -> PublicizeInfo.SharingLimit? in
                    guard let blog = try Blog.lookup(withID: blogID, in: context) else {
                        throw ServiceError.blogNotFound(id: blogID)
                    }

                    if let remotePublicizeInfo,
                       let newOrExistingInfo = blog.publicizeInfo ?? PublicizeInfo.newObject(in: context) {
                        // add or update the publicizeInfo for the blog.
                        newOrExistingInfo.configure(with: remotePublicizeInfo)
                        blog.publicizeInfo = newOrExistingInfo

                    } else if let existingPublicizeInfo = blog.publicizeInfo {
                        // if the remote object is nil, delete the blog's publicizeInfo if it exists.
                        context.delete(existingPublicizeInfo)
                        blog.publicizeInfo = nil
                    }

                    return blog.publicizeInfo?.sharingLimit

                }, completion: { completion($0) }, on: .main)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: Errors

    enum ServiceError: LocalizedError {
        case blogNotFound(id: Int)

        var errorDescription: String? {
            switch self {
            case .blogNotFound(let id):
                return "Blog with id: \(id) was unexpectedly not found."
            }
        }
    }
}
