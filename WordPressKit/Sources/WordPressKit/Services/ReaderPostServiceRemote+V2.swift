extension ReaderPostServiceRemote {
    /// Returns a collection of RemoteReaderPost
    /// This method returns the best available content for the given topics.
    ///
    /// - Parameter topics: an array of String representing the topics
    /// - Parameter page: a String that represents a page handle
    /// - Parameter success: Called when the request succeeds and the data returned is valid
    /// - Parameter failure: Called if the request fails for any reason, or the response data is invalid
    public func fetchPosts(for topics: [String],
                           page: String? = nil,
                           refreshCount: Int? = nil,
                           success: @escaping ([RemoteReaderPost], String?) -> Void,
                           failure: @escaping (Error) -> Void) {
        guard let requestUrl = postsEndpoint(for: topics, page: page) else {
            return
        }

        wordPressComRESTAPI.get(requestUrl,
                                parameters: nil,
                                success: { response, _ in
                                    let responseDict = response as? [String: Any]
                                    let nextPageHandle = responseDict?["next_page_handle"] as? String
                                    let postsDictionary = responseDict?["posts"] as? [[String: Any]]
                                    let posts = postsDictionary?.compactMap { RemoteReaderPost(dictionary: $0) } ?? []
                                    success(posts, nextPageHandle)
        }, failure: { error, _ in
            WPKitLogError("Error fetching reader posts: \(error)")
            failure(error)
        })
    }

    private func postsEndpoint(for topics: [String], page: String? = nil) -> String? {
        var path = URLComponents(string: "read/tags/posts")

        path?.queryItems = topics.map { URLQueryItem(name: "tags[]", value: $0) }

        if let page = page {
            path?.queryItems?.append(URLQueryItem(name: "page_handle", value: page))
        }

        guard let endpoint = path?.string else {
            return nil
        }

        return self.path(forEndpoint: endpoint, withVersion: ._2_0)
    }

    /// Sets the `is_seen` status for a given feed post.
    ///
    /// - Parameter seen: the post is to be marked seen or not (unseen)
    /// - Parameter feedID: feedID of the ReaderPost
    /// - Parameter feedItemID: feedItemID of the ReaderPost
    /// - Parameter success: Called when the request succeeds
    /// - Parameter failure: Called when the request fails
    @objc
    public func markFeedPostSeen(seen: Bool,
                                 feedID: NSNumber,
                                 feedItemID: NSNumber,
                                 success: @escaping (() -> Void),
                                 failure: @escaping ((Error) -> Void)) {
        let endpoint = seen ? SeenEndpoints.feedSeen : SeenEndpoints.feedUnseen

        let params = [
            "feed_id": feedID,
            "feed_item_ids": [feedItemID],
            "source": "reader-ios"
        ] as [String: AnyObject]

        updateSeenStatus(endpoint: endpoint, params: params, success: success, failure: failure)
    }

    /// Sets the `is_seen` status for a given blog post.
    ///
    /// - Parameter seen: the post is to be marked seen or not (unseen)
    /// - Parameter blogID: blogID of the ReaderPost
    /// - Parameter postID: postID of the ReaderPost
    /// - Parameter success: Called when the request succeeds
    /// - Parameter failure: Called when the request fails
    @objc
    public func markBlogPostSeen(seen: Bool,
                                 blogID: NSNumber,
                                 postID: NSNumber,
                                 success: @escaping (() -> Void),
                                 failure: @escaping ((Error) -> Void)) {
        let endpoint = seen ? SeenEndpoints.blogSeen : SeenEndpoints.blogUnseen

        let params = [
            "blog_id": blogID,
            "post_ids": [postID],
            "source": "reader-ios"
        ] as [String: AnyObject]

        updateSeenStatus(endpoint: endpoint, params: params, success: success, failure: failure)
    }

    private func updateSeenStatus(endpoint: String,
                                  params: [String: AnyObject],
                                  success: @escaping (() -> Void),
                                  failure: @escaping ((Error) -> Void)) {

        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)

        wordPressComRESTAPI.post(path, parameters: params, success: { (responseObject, _) in
            guard let response = responseObject as? [String: AnyObject],
                  let status = response["status"] as? Bool,
                  status == true else {
                failure(MarkSeenError.failed)
                return
            }
            success()
        }, failure: { (error, _) in
            failure(error)
        })
    }

    private struct SeenEndpoints {
        // Creates a new `seen` entry (i.e. mark as seen)
        static let feedSeen = "seen-posts/seen/new"
        static let blogSeen = "seen-posts/seen/blog/new"
        // Removes the `seen` entry (i.e. mark as unseen)
        static let feedUnseen = "seen-posts/seen/delete"
        static let blogUnseen = "seen-posts/seen/blog/delete"
    }

    private enum MarkSeenError: Error {
        case failed
    }

}
