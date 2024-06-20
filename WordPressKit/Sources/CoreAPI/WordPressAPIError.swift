import Foundation

public enum WordPressAPIError<EndpointError>: Error where EndpointError: LocalizedError {
    static var unknownErrorMessage: String {
        NSLocalizedString(
            "wordpress-api.error.unknown",
            value: "Something went wrong, please try again later.",
            comment: "Error message that describes an unknown error had occured"
        )
    }

    /// Can't encode the request arguments into a valid HTTP request. This is a programming error.
    case requestEncodingFailure(underlyingError: Error)
    /// Error occured in the HTTP connection.
    case connection(URLError)
    /// The API call returned an error result. For example, an OAuth endpoint may return an 'incorrect username or password' error, an upload media endpoint may return an 'unsupported media type' error.
    case endpointError(EndpointError)
    /// The API call returned an status code that's unacceptable to the endpoint.
    case unacceptableStatusCode(response: HTTPURLResponse, body: Data)
    /// The API call returned an HTTP response that WordPressKit can't parse. Receiving this error could be an indicator that there is an error response that's not handled properly by WordPressKit.
    case unparsableResponse(response: HTTPURLResponse?, body: Data?, underlyingError: Error)
    /// Other error occured.
    case unknown(underlyingError: Error)

    static func unparsableResponse(response: HTTPURLResponse?, body: Data?) -> Self {
        return WordPressAPIError<EndpointError>.unparsableResponse(response: response, body: body, underlyingError: URLError(.cannotParseResponse))
    }

    var response: HTTPURLResponse? {
        switch self {
        case .requestEncodingFailure, .connection, .unknown:
            return nil
        case let .endpointError(error):
            return (error as? HTTPURLResponseProviding)?.httpResponse
        case .unacceptableStatusCode(let response, _):
            return response
        case .unparsableResponse(let response, _, _):
            return response
        }
    }
}

extension WordPressAPIError: LocalizedError {

    public var errorDescription: String? {
        // Considering `WordPressAPIError` is the error that's surfaced from this library to the apps, its instanes
        // may be displayed on UI directly. To prevent Swift's default error message (i.e. "This operation can't be
        // completed. <SwiftTypeName> (code=...)") from being displayed, we need to make sure this implementation
        // always returns a non-nil value.
        let localizedErrorMessage: String
        switch self {
        case .requestEncodingFailure, .unparsableResponse, .unacceptableStatusCode:
            // These are usually programming errors.
            localizedErrorMessage = Self.unknownErrorMessage
        case let .endpointError(error):
            localizedErrorMessage = error.errorDescription ?? Self.unknownErrorMessage
        case let .connection(error):
            localizedErrorMessage = error.localizedDescription
        case let .unknown(underlyingError):
            if let msg = (underlyingError as? LocalizedError)?.errorDescription {
                localizedErrorMessage = msg
            } else {
                localizedErrorMessage = Self.unknownErrorMessage
            }
        }
        return localizedErrorMessage
    }

}

protocol HTTPURLResponseProviding {
    var httpResponse: HTTPURLResponse? { get }
}
