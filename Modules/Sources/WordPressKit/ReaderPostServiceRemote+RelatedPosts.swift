import Foundation

extension ReaderPostServiceRemote {

    /// Returns a collection of RemoteReaderSimplePost
    /// This method returns related posts for a source post.
    ///
    /// - Parameter postID: The source post's ID
    /// - Parameter siteID: The source site's ID
    /// - Parameter count: The number of related posts to retrieve for each post type
    /// - Parameter success: Called when the request succeeds and the data returned is valid
    /// - Parameter failure: Called if the request fails for any reason, or the response data is invalid
    public func fetchRelatedPosts(for postID: Int,
                                  from siteID: Int,
                                  count: Int? = 2,
                                  success: @escaping ([RemoteReaderSimplePost]) -> Void,
                                  failure: @escaping (Error?) -> Void) {

        let endpoint = "read/site/\(siteID)/post/\(postID)/related"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_2)

        let parameters = [
            "size_local": count,
            "size_global": count
        ] as [String: AnyObject]

        wordPressComRESTAPI.get(
            path,
            parameters: parameters,
            success: { (response, _) in
                do {
                    let decoder = JSONDecoder()
                    let data = try JSONSerialization.data(withJSONObject: response, options: [])
                    let envelope = try decoder.decode(RemoteReaderSimplePostEnvelope.self, from: data)

                    success(envelope.posts)
                } catch {
                    WPKitLogError("Error parsing the reader related posts response: \(error)")
                    failure(error)
                }
            },
            failure: { (error, _) in
                WPKitLogError("Error fetching reader related posts: \(error)")
                failure(error)
            }
        )
    }
}
