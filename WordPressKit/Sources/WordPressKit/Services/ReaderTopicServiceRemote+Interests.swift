import Foundation

extension ReaderTopicServiceRemote {
    /// Returns a collection of RemoteReaderInterest
    /// - Parameters:
    /// - Parameter success: Called when the request succeeds and the data returned is valid
    /// - Parameter failure: Called if the request fails for any reason, or the response data is invalid
    public func fetchInterests(_ success: @escaping ([RemoteReaderInterest]) -> Void,
                               failure: @escaping (Error) -> Void) {
        let path = self.path(forEndpoint: "read/interests", withVersion: ._2_0)

        wordPressComRESTAPI.get(path,
                                parameters: nil,
                                success: { response, _ in
                                    do {
                                        let decoder = JSONDecoder()
                                        let data = try JSONSerialization.data(withJSONObject: response, options: [])
                                        let envelope = try decoder.decode(ReaderInterestEnvelope.self, from: data)

                                        success(envelope.interests)
                                    } catch {
                                        WPKitLogError("Error parsing the reader interests response: \(error)")
                                        failure(error)
                                    }
        }, failure: { error, _ in
            WPKitLogError("Error fetching reader interests: \(error)")

            failure(error)
        })
    }

    /// Follows multiple tags/interests at once using their slugs
    public func followInterests(withSlugs: [String],
                                success: @escaping () -> Void,
                                failure: @escaping (Error) -> Void) {
        let path = self.path(forEndpoint: "read/tags/mine/new", withVersion: ._1_2)
        let parameters = ["tags": withSlugs] as [String: AnyObject]

        wordPressComRESTAPI.post(path, parameters: parameters, success: { _, _ in
            success()
        }) { error, _ in
            WPKitLogError("Error fetching reader interests: \(error)")

            failure(error)
        }
    }

    /// Returns an API path for the given tag/topic/interest slug
    /// - Returns: https://_api_/read/tags/_slug_/posts
    public func pathForTopic(slug: String) -> String {
        let endpoint = path(forEndpoint: "read/tags/\(slug)/posts", withVersion: ._1_2)

        return wordPressComRESTAPI.baseURL.appendingPathComponent(endpoint).absoluteString
    }
}
