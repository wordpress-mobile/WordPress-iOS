import Foundation

// MARK: - SiteVerticalsRequest

/// Allows the construction of a request for site verticals.
///
/// NB: The default limit (5) applies to the number of results returned by the service. If a search with limit n evinces no exact match, (n - 1) server-unique results are returned.
///
public struct SiteVerticalsRequest: Encodable {
    public let search: String
    public let limit: Int

    public init(search: String, limit: Int = 5) {
        self.search = search
        self.limit = limit
    }
}

// MARK: - SiteVertical(s) : Response

/// Models a Site Vertical
///
public struct SiteVertical: Decodable, Equatable {
    public let identifier: String   // vertical IDs mix parent/child taxonomy (String)
    public let title: String
    public let isNew: Bool

    public init(identifier: String,
                title: String,
                isNew: Bool) {

        self.identifier = identifier
        self.title = title
        self.isNew = isNew
    }

    private enum CodingKeys: String, CodingKey {
        case identifier = "vertical_id"
        case title      = "vertical_name"
        case isNew      = "is_user_input_vertical"
    }
}

// MARK: - WordPressComServiceRemote (Site Verticals)

/// Describes the errors that could arise when searching for site verticals.
///
/// - requestEncodingFailure:   unable to encode the request parameters.
/// - responseDecodingFailure:  unable to decode the server response.
/// - serviceFailure:           the service returned an unexpected error.
///
public enum SiteVerticalsError: Error {
    case requestEncodingFailure
    case responseDecodingFailure
    case serviceFailure
}

/// Advises the caller of results related to requests for site verticals.
///
/// - success: the site verticals request succeeded with the accompanying result.
/// - failure: the site verticals request failed due to the accompanying error.
///
public enum SiteVerticalsResult {
    case success([SiteVertical])
    case failure(SiteVerticalsError)
}

public typealias SiteVerticalsServiceCompletion = ((SiteVerticalsResult) -> Void)

/// Site verticals services, exclusive to WordPress.com.
///
public extension WordPressComServiceRemote {

    /// Retrieves Verticals matching the specified criteria.
    ///
    /// - Parameters:
    ///   - request:    the value object with which to compose the request.
    ///   - completion: a closure including the result of the request for site verticals.
    ///
    func retrieveVerticals(request: SiteVerticalsRequest, completion: @escaping SiteVerticalsServiceCompletion) {

        let endpoint = "verticals"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)

        let requestParameters: [String: AnyObject]
        do {
            requestParameters = try encodeRequestParameters(request: request)
        } catch {
            WPKitLogError("Failed to encode \(SiteCreationRequest.self) : \(error)")

            completion(.failure(SiteVerticalsError.requestEncodingFailure))
            return
        }

        wordPressComRESTAPI.get(
            path,
            parameters: requestParameters,
            success: { [weak self] responseObject, httpResponse in
                WPKitLogInfo("\(responseObject) | \(String(describing: httpResponse))")

                guard let self = self else {
                    return
                }

                do {
                    let response = try self.decodeResponse(responseObject: responseObject)
                    completion(.success(response))
                } catch {
                    WPKitLogError("Failed to decode \([SiteVertical].self) : \(error.localizedDescription)")
                    completion(.failure(SiteVerticalsError.responseDecodingFailure))
                }
            },
            failure: { error, httpResponse in
                WPKitLogError("\(error) | \(String(describing: httpResponse))")
                completion(.failure(SiteVerticalsError.serviceFailure))
        })
    }
}

// MARK: - Serialization support

private extension WordPressComServiceRemote {

    func encodeRequestParameters(request: SiteVerticalsRequest) throws -> [String: AnyObject] {

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

    func decodeResponse(responseObject: Any) throws -> [SiteVertical] {

        let decoder = JSONDecoder()

        let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])
        let response = try decoder.decode([SiteVertical].self, from: data)

        return response
    }
}
