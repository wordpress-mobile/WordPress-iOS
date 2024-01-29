import WordPressKit
import CoreData

@objc class JetpackSocialService: NSObject {

    // MARK: Properties

    private let coreDataStack: CoreDataStackSwift

    private lazy var remote: JetpackSocialServiceRemote = {
        let api = coreDataStack.performQuery { context in
            return WordPressComRestApi.defaultV2Api(in: context)
        }
        return .init(wordPressComRestApi: api)
    }()

    // MARK: Methods

    /// Init method for Objective-C.
    ///
    @objc init(contextManager: ContextManager) {
        self.coreDataStack = contextManager
    }

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
        // allow `self` to be retained inside this closure so the completion block will always be executed.
        remote.fetchPublicizeInfo(for: blogID) { result in
            switch result {
            case .success(let remotePublicizeInfo):
                self.coreDataStack.performAndSave({ context -> PublicizeInfo.SharingLimit? in
                    guard let blog = try Blog.lookup(withID: blogID, in: context) else {
                        // unexpected to fall into this case, since the API should return an error response.
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

    /// Sync method for Objective-C.
    /// Fetches the latest state of the blog's Publicize auto-sharing limits and stores them locally.
    ///
    /// - Parameters:
    ///   - dotComID: The WP.com ID of the blog.
    ///   - success: Closure called when the sync process succeeds.
    ///   - failure: Closure called when the sync process fails.
    @objc func syncSharingLimit(dotComID: NSNumber?,
                                success: (() -> Void)?,
                                failure: ((NSError?) -> Void)?) {
        guard let blogID = dotComID?.intValue else {
            failure?(ServiceError.nilBlogID as NSError)
            return
        }

        syncSharingLimit(for: blogID, completion: { result in
            switch result {
            case .success:
                success?()
            case .failure(let error):
                failure?(error as NSError)
            }
        })
    }

    // MARK: Errors

    enum ServiceError: LocalizedError {
        case blogNotFound(id: Int)
        case nilBlogID

        var errorDescription: String? {
            switch self {
            case .blogNotFound(let id):
                return "Blog with id: \(id) was unexpectedly not found."
            case .nilBlogID:
                return "Blog ID is unexpectedly nil."
            }
        }
    }
}
