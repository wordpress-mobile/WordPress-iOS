import WordPressKit

// MARK: - WordPressComServiceRemote (Site Segments)

/// Describes the errors that could arise when searching for site verticals.
///
/// - requestEncodingFailure:   unable to encode the request parameters.
/// - responseDecodingFailure:  unable to decode the server response.
/// - serviceFailure:           the service returned an unexpected error.
///
enum SiteSegmentsError: Error {
    case requestEncodingFailure
    case responseDecodingFailure
    case serviceFailure
}

enum SiteSegmentsResult {
    case success([SiteSegment])
    case failure(SiteSegmentsError)
}

struct SiteSegmentsRequest: Encodable {
    let locale: String
}

extension WordPressComServiceRemote {
    func retrieveSegments(request: SiteSegmentsRequest, completion: @escaping SiteSegmentsServiceCompletion) {
        let endpoint = "segments"
        let remotePath = path(forEndpoint: endpoint, withVersion: ._2_0)

        let requestParameters: [String: AnyObject]
        do {
            requestParameters = try encodeRequestParameters(request: request)
        } catch {
            DDLogError("Failed to encode \(SiteSegmentsRequest.self) : \(error)")

            completion(.failure(SiteSegmentsError.requestEncodingFailure))
            return
        }

        wordPressComRestApi.GET(
            remotePath,
            parameters: requestParameters,
            success: { [weak self] responseObject, httpResponse in
                DDLogInfo("\(responseObject) | \(String(describing: httpResponse))")

                guard let self = self else {
                    return
                }

                do {
                    print("response Object ", responseObject)
                    let response = try self.decodeResponse(responseObject: responseObject)
                    let validContent = self.validSegments(response)
                    completion(.success(validContent))
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
}

private extension WordPressComServiceRemote {
    private func encodeRequestParameters(request: SiteSegmentsRequest) throws -> [String: AnyObject] {

        let encoder = JSONEncoder()

        let jsonData = try encoder.encode(request)
        let serializedJSON = try JSONSerialization.jsonObject(with: jsonData, options: [])

        let requestParameters: [String: AnyObject]
        if let jsonDictionary = serializedJSON as? [String: AnyObject] {
            requestParameters = jsonDictionary
        } else {
            requestParameters = [:]
        }

        return requestParameters
    }

    private func decodeResponse(responseObject: AnyObject) throws -> [SiteSegment] {
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])
        let response = try decoder.decode([SiteSegment].self, from: data)

        return response
    }

    private func validSegments(_ allSegments: [SiteSegment]) -> [SiteSegment] {
        return allSegments.filter {
            return $0.mobile == true
        }
    }
}
