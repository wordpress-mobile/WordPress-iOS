public extension CommentServiceRemoteREST {
    /// Lists the available keys for the request parameter.
    enum RequestKeys: String {
        /// The parent comment's ID. In API v2, supplying this parameter filters the list to only contain
        /// the child/reply comments of the specified ID.
        case parent

        /// The dotcom user ID of the comment author. In API v2, supplying this parameter filters the list
        /// to only contain comments authored by the specified ID.
        case author

        /// Valid values are `view`, `edit`, or `embed`. When not specified, the default context is `view`.
        case context
    }

    /// Retrieves a list of comments in a site with the specified siteID.
    /// - Parameters:
    ///   - siteID: The ID of the site that contains the specified comment.
    ///   - parameters: Additional request parameters. Optional.
    ///   - success: A closure that will be called when the request succeeds.
    ///   - failure: A closure that will be called when the request fails.
    func getCommentsV2(for siteID: Int,
                       parameters: [RequestKeys: AnyHashable]? = nil,
                       success: @escaping ([RemoteCommentV2]) -> Void,
                       failure: @escaping (Error) -> Void) {
        let path = coreV2Path(for: "sites/\(siteID)/comments")
        let requestParameters: [String: AnyHashable] = {
            guard let someParameters = parameters else {
                return [:]
            }

            return someParameters.reduce([String: AnyHashable]()) { result, pair in
                var result = result
                result[pair.key.rawValue] = pair.value
                return result
            }
        }()

        Task { @MainActor in
            await self.wordPressComRestApi
                .perform(
                    .get,
                    URLString: path,
                    parameters: requestParameters as [String: AnyObject],
                    type: [RemoteCommentV2].self
                )
                .map { $0.body }
                .mapError { error -> Error in error.asNSError() }
                .execute(onSuccess: success, onFailure: failure)
        }
    }

}

// MARK: - Private Helpers

private extension CommentServiceRemoteREST {
    struct Constants {
        static let coreV2String = "wp/v2"
    }

    func coreV2Path(for endpoint: String) -> String {
        return "\(Constants.coreV2String)/\(endpoint)"
    }
}
