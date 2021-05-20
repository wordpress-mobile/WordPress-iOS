import Foundation

extension ReaderPostService {

    /**
     Fetches related posts for a specific post.
     
     @param post The reader post to fetch related posts for.
     @param success block called on a successful fetch.
     @param failure block called if there is any error. `error` can be any underlying network error.
     */
    func fetchRelatedPosts(for post: ReaderPost,
                           success: @escaping ([RemoteReaderSimplePost]) -> Void,
                           failure: @escaping (Error?) -> Void) {

        let remoteService = ReaderPostServiceRemote.withDefaultApi()

        guard let postID = post.postID?.intValue else {
            failure(ReaderPostServiceError.invalidPostID)
            return
        }

        guard let siteID = post.siteID?.intValue else {
            failure(ReaderPostServiceError.invalidSiteID)
            return
        }

        remoteService.fetchRelatedPosts(for: postID, from: siteID, success: success, failure: failure)
    }

    // MARK: - Helpers

    enum ReaderPostServiceError: Error {
        case invalidPostID
        case invalidSiteID
    }
}
