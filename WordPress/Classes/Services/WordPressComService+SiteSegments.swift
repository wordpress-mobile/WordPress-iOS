import WordPressKit

// MARK: - WordPressComServiceRemote (Site Segments)

/// Describes the errors that could arise when searching for site verticals.
///
/// - requestEncodingFailure:   unable to encode the request parameters.
/// - responseDecodingFailure:  unable to decode the server response.
/// - serviceFailure:           the service returned an unexpected error.
///
enum SiteSegmentsError: Error {
    case responseDecodingFailure
    case serviceFailure
}

enum SiteSegmentsResult {
    case success([SiteSegment])
    case failure(SiteSegmentsError)
}

/// Advises the caller of results related to requests for site verticals.
///
/// - success: the site verticals request succeeded with the accompanying result.
/// - failure: the site verticals request failed due to the accompanying error.
///
//enum SiteSegmentsResult {
//    case success([SiteSegment])
//    case failure(SiteSegmentsError)
//}
//typealias SiteSegmentsServiceCompletion = ((SiteVerticalsResult) -> ())

extension WordPressComServiceRemote {
    func retrieveSegments(completion: @escaping SiteSegmentsServiceCompletion) {
        let endpoint = "segments"
        let remotePath = path(forEndpoint: endpoint, withVersion: ._2_0)

        wordPressComRestApi.GET(
            remotePath,
            parameters: nil,
            success: { [weak self] responseObject, httpResponse in
                DDLogInfo("\(responseObject) | \(String(describing: httpResponse))")

                guard let self = self else {
                    return
                }

                do {
                    print("response Object ", responseObject)
                    let response = try self.decodeResponse(responseObject: responseObject)
                    completion(.success(response))
                } catch {
                    DDLogError("Failed to decode \([SiteVertical].self) : \(error.localizedDescription)")
                    completion(.failure(SiteSegmentsError.responseDecodingFailure))
                }
            },
            failure: { error, httpResponse in
                DDLogError("\(error) | \(String(describing: httpResponse))")
                completion(.failure(SiteSegmentsError.serviceFailure))
        })
    }

    private func decodeResponse(responseObject: AnyObject) throws -> [SiteSegment] {
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])
        let response = try decoder.decode([SiteSegment].self, from: data)

        return response
    }
}
