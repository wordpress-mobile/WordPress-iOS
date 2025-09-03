import WordPressKitObjC
import NSObject_SafeExpectations

extension PostServiceRemoteREST {

    /// Requests a list of users that liked the post with the specified ID.
    ///
    /// Due to the API limitation, up to 90 users will be returned from the endpoint.
    ///
    /// - Parameters:
    ///   - postID: The ID for the post. Cannot be nil.
    ///   - count: Number of records to retrieve. Cannot be nil. If 0, will default to endpoint max.
    ///   - before: Filter results to Likes before this date/time string. Can be nil.
    ///   - excludeUserIDs: Array of user IDs to exclude from response. Can be nil.
    ///   - success: The block that will be executed on success. Can be nil.
    ///   - failure: The block that will be executed on failure. Can be nil.
    @objc(getLikesForPostID:count:before:excludeUserIDs:success:failure:)
    public func getLikesForPostID(
        _ postID: NSNumber,
        count: NSNumber,
        before: String?,
        excludeUserIDs: [NSNumber]?,
        success: (([RemoteLikeUser], NSNumber) -> Void)?,
        failure: ((Error?) -> Void)?
    ) {
        let path = "sites/\(siteID)/posts/\(postID)/likes"
        let requestUrl = self.path(forEndpoint: path, withVersion: ._1_2)
        let siteID = self.siteID

        // If no count provided, default to endpoint max.
        var parameters: [String: Any] = ["number": count == 0 ? 90 : count]

        if let before {
            parameters["before"] = before
        }

        if let excludeUserIDs {
            parameters["exclude"] = excludeUserIDs
        }

        wordPressComRESTAPI.get(requestUrl,
                               parameters: parameters,
                               success: { (responseObject, httpResponse) in
            if let success {
                let responseDict = responseObject as? [String: Any] ?? [:]
                let jsonUsers = responseDict["likes"] as? [[String: Any]] ?? []
                let users = jsonUsers.map { RemoteLikeUser(dictionary: $0, postID: postID, siteID: siteID) }
                let found = responseDict["found"] as? NSNumber ?? 0
                success(users, found)
            }
        }, failure: { (error, _) in
            failure?(error)
        })
    }

}
